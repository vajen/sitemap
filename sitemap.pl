#!/usr/bin/perl
use lib "/www/lib/";

use strict;
use warnings;
use Data::Dumper;
use Felis::Lib;
use Felis::Graber::Bot;
use List::MoreUtils qw(uniq);

my @un_links;
my @uniq;
my @global_uniq_link_list;

my %uniq_hash;
my $site = "https://subscribe.ru";
my $mainsite = "subscribe.ru";
my ($fh);
my $fullpath = $ARGV[0] || './sitemap.xml';
my $now = felisDateGetDByd();
my $changefreq = "daily";
my $deep;
my $priority = 0.5;

sub writedownlink {
    my ($link) = @_;

    $deep = () = $link =~ m!/!g;
    if($deep > 2) {
        $priority = $deep >5 ? 1 : $deep*0.2;
    }
    $link =~ s!&!&amp;!g;
    $fh->print("<url>\n<loc>$link</loc>\n<lastmod>$now</lastmod>\n<changefreq>$changefreq</changefreq>\n<priority>$priority</priority>\n</url>\n");
}

sub get_links {
    if(! defined $_[0]) {
        $site = "https://subscribe.ru";
    } else {
        $site = $_[0];
    }

    my $res =  Felis::Graber::Bot::httpget($site);

     if($res && $res->{_rc} < 400) {

        %uniq_hash = map {$_ => 1} @global_uniq_link_list;

        my @links = $res->content =~ m/<a.+?href="((?:\/{1}|.*?subscribe\.ru\/)(?!\/|member|manage|feedback|stat|promo|author|rating|events)[^<>\"]+?)">*/gm;
         map {
                     if(
                     ($_ =~ m!/group! && $_ !~ m!/group/?$! && $_ !~ m!/\?cat=!) ||
                     ($_ !~ m!/faq/?$! && $_ =~ m!/faq/.{2,}!) ||
                     ($_ =~ m!advert\.subscribe! && $_ !~ m!advert\.subscribe\.ru/?$!) ||
                     ($_ =~ m!plus\.subscribe! && $_ !~ m!plus\.subscribe\.ru/?$!) ||
                     ($_ =~ m!/author/! && $_ !~ m!/author/[0-9]+/?$! && $_ !~ m!/author/$!) ||
                     ($_ =~ m!\.rss$! || $_ =~ m!catalog/rss\.[0-9]+!) ||
                     ($_ =~ m!tickets\.subscribe\.ru!) || ($_ =~ m!link\.subscribe\.ru!) ||
                     ($_ =~ m!subscribe\.ru/promo!) || ($_ =~ m!\?bronze!)
                     ) {
                         #print "link deleted: $_\n";
                     } else {
                         if($_ =~ m!\.html/$!) {
                            substr($_,-1) = "";
                            $_ = substr($_,0,rindex($_,"/")+1);
                            if($_ =~ m![0-9]/$!) {
                              substr($_,-1) = "";
                              $_ = substr($_,0,rindex($_,"/")+1);
                            }
                          }
                           elsif($_ =~ m!/thread/!) {
                             $_ = substr($_,0,rindex($_,"/thread/")+7);
                           }
                          elsif($_ !~ m!/archive/! && $_ =~ m!(\.html|\.html\#\w*?)$!)
                          {
                              $_ = substr($_,0,rindex($_,"/")+1);
                          }
                          elsif($_ =~ m!/archive/! && ($_ =~ m!(/[0-9a-z]+\.html)$! || $_ =~ m!(/[0-9a-z]+\.html#.*)$!))
                          {
                             $_ = substr($_,0,rindex($_,"/")+1);
                             substr($_,-1) = "";
                             $_ = substr($_,0,rindex($_,"/")+1);
                          }
                          elsif( $_ =~ m!\?.+! && $_ !~ m!/\?cat=! && $_ !~ m!\?gold! && $_ !~ m!/\?pos=(1|2|51|101)$! && $_ !~ m!&amp;pos=(1|2|51|101)$!)
                          {
                             $_ = substr($_,0,rindex($_,"?"));
                          }

                          $_ = $_."/"                  if($_ !~ m!\?! && $_ =~ m![^/]$!);
                          $_ = "https://".$mainsite.$_ if($_ =~ m!^/!);
                          $_ =~ s!http:!https:! if($_ =~ m!^http:!);
                       if(!exists $uniq_hash{$_}) {
                         push @un_links, $_;
                       }
                     }
                 } @links;

         @uniq = uniq(@un_links);


     }
}

get_links();

@global_uniq_link_list = @uniq;
%uniq_hash = map {$_ => 1} @global_uniq_link_list;


    foreach my $l (@uniq){

        %uniq_hash = map {$_ => 1} @global_uniq_link_list;
        #if(keys(%uniq_hash) < 500) {
        #print "--$l\n";
        if(!exists $uniq_hash{$l}) {
            push @global_uniq_link_list,$l;
        }
        get_links($l);
        #}
    }



open($fh, '>', $fullpath) or die "Can't open file '$fullpath' $!";
$fh->print('<?xml version="1.0" encoding="UTF-8"?><urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">');

foreach my $unl (@global_uniq_link_list) {
    if($unl =~ m!\?.+! && $unl !~ m!/group/\?cat=!){ next; }
    if($unl =~ m!&amp;pos=!) { next; }
    if($unl =~ m!/by-activity/! || $unl =~ m!/by-date/!) { next; }
    writedownlink($unl);
}

$fh->print("</urlset>");
$fh->close();


1;
