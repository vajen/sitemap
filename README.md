# sitemap
To building sitemap without recursion.

Строится карта сайта (subscribe.ru),
некоторые ссылки удаляются из обхода дерева сайта, некоторые модифицируются.
Можно задать путь для выходного файла, если не задан, то все пишется в
./sitemap.xml
Используются внутренние пакеты Felis::Lib (получение даты в необходимом формате) 
и Felis::Graber::Bot (возвращает информацию о странице), можно заменить на
  my @t = localtime;
  $t[5] += 1900;
  $t[4]++;
  my $now = sprintf("%04d-%02d-%02d", @t[5,4,3]);
и 
  my $site = "subscribe.ru";
  my @content = split(/\n/,`wget -qO- $site`);
  my @links = grep(/<a.*href=.*>/,@content);
соответственно.
Вызов (с указанием пути к результирующему файлу):
  perl ./sitemap.pl ./path_to_sitemap_xml_file/file_name.xml
  
