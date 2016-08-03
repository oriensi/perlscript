#!/usr/bin/env perl
use File::Find;
use XML::Simple;
use XML::LibXML;
use Spreadsheet::WriteExcel;
use Data::Dumper;
use strict;
use warnings;
use 5.010;

my ($root, $outFile, @values) = @ARGV;
$root.= "/" unless substr($root, -1) eq "/";
@values = sort @values;
say "project: $root";
say "values: @values";
say "write to: $outFile";

my @res_files;

my $workbook = Spreadsheet::WriteExcel->new($outFile);
my $worksheet = $workbook->add_worksheet();

# 搜索strings.xml 文件
sub find_res_dir {
  if ($File::Find::dir =~ m#^.*/res[^/]*$#) {
    my $v_d = $_;
    if (grep /^$v_d$/, @values) {
      opendir DIR, $File::Find::name or die "opendir err";
      my @files = grep { /^(?:mtk_)?(strings|arrays).xml$/ && -f "$File::Find::name/$_" } readdir DIR;
      push @res_files, $File::Find::name."/".$_ for @files;
    }
  }
}

# 不解析字串中xliff tag
sub XML::LibXML::Node::innerXML{
  my ($self) = shift;
  join '', $self->childNodes();
}

# 解析xml文件
sub parse_xml {
  my ($module, $files) = @_;
  my %name_value;
  my $parser = XML::LibXML->new;
  for my $file (@$files) {
    my $value_dir;
    if ($file =~ m#/(values(?:-[^/]*)?)/#) {
      $value_dir = $1;
    } else {
      say "sth is wrong!!";
    }
    my $doc = $parser->parse_file($file) or die "can't parse $file";
    my @nodeList = $doc->getElementsByTagName('string');
    for my $node (@nodeList) {
      my @attributelist = $node->attributes();
      my $value = $node->innerXML;
      my ($name) = map { $_->nodeValue if $_->nodeName =~ /name/ } @attributelist;
      say "name: ".$name."    value: ".$value;
      $name_value{$name}{$value_dir} = $value;
    }
  }
  # print Dumper %name_value;
  \%name_value;
}

# 写入xls文件
sub write_to_xls {
  my ($file_name, $content) = @_;
  my $row = 1;
  while (my ($module, $name_value) = each (%$content)) {
    while (my ($name, $v_v) = each (%$name_value)) {
      my $count = 1;
      $worksheet->write($row, 0, $module);
      $worksheet->write($row, $count++, $name);
      for (@values) {
        $worksheet->write($row, $count++, $v_v->{$_});
      }
      $row++;
    }
  }
}

sub resdir2module {
  my $files = shift;
  my %module_resdir;
  for my $file (@$files) {
    my $module;
    say $file;
    if ($file =~ m#$root(.*)/res(?:_[^/]*)?/values#) {
      $module = $1;
      # say 'module: '.$module.'    file:'.$file;
    } else {
      say 'oh no!!!';
      next;
    }
    my @path = $module_resdir{$module} ? $module_resdir{$module} : ();
    if (@path) {
      push $module_resdir{$module}, $file;
    } else {
      $module_resdir{$module} = [$file];
    }
  }
  # print Dumper %module_resdir;
  \%module_resdir;
}

find(\&find_res_dir, "$root"."packages/apps");

@res_files = sort @res_files;
# exit;
my $module_resdir_ref;
$module_resdir_ref = resdir2module \@res_files;
#exit;

die "need out file name" unless $outFile;

my %parserxml_ref;
 for my $module (keys %$module_resdir_ref) {
   $parserxml_ref{$module} = parse_xml($module, $module_resdir_ref->{$module});
   print Dumper %parserxml_ref;
   last;
 }

$worksheet->write(0, 0, "path");
$worksheet->write(0, 1, "name");
my $col = 2;
for (@values) {
  $worksheet->write(0, $col++, $_);
}
write_to_xls($outFile, \%parserxml_ref);
#}
