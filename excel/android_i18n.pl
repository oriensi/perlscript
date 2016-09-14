#!/usr/bin/env perl
use File::Find;
use XML::Simple;
use XML::LibXML;
use Spreadsheet::WriteExcel;
use Data::Dumper;
use strict;
use warnings;
use 5.010;

my ($root, $overlay_dir, $find_path, $outFile, @values) = @ARGV;
$root.= "/" unless substr($root, -1) eq "/";
$overlay_dir.= "/" unless substr($overlay_dir, -1) eq "/";
$find_path.= "/" unless substr($find_path, -1) eq "/";
@values = sort @values;
say "project: $root";
say "values: @values";
say "write to: $outFile";
say "overlay dir: $overlay_dir";
say "module path: $find_path";

my @res_files;
my $module_resdir_ref;

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
    if ($file =~ m{/(values(?:-[^/]*)?)/}) {
      $value_dir = $1;
    } else {
      say "sth is wrong!!";
    }
    my $doc = $parser->parse_file($file) or die "can't parse $file";
    my @nodeList = $doc->getElementsByTagName('string');
    my @arrayNodes = $doc->getElementsByTagName('string-array');
    for my $node (@nodeList) {
      my @attributelist = $node->attributes();
      my $value = $node->innerXML;
      my ($name) = map { $_->nodeValue if $_->nodeName =~ /name/ } @attributelist;
      # say "name: ".$name."    value_dir:".$value_dir."    value: ".$value;
      $name_value{$name}{$value_dir} = $value;
    }
    for my $node (@arrayNodes) {
      my @attributelist = $node->attributes();
      my ($name) = map { $_->nodeValue if $_->nodeName =~ /name/ } @attributelist;
      # my @childNodes = $node->childNodes;
      my $value = join "\n", map {$_->innerXML} $node->childNodes;
      $name_value{$name}{$value_dir} = $value;
    }
  }
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

sub resfiles2module {
  my $files = shift;
  # my %module_resdir;
  for my $file (@$files) {
    my $module;
    say $file;
    if ($file =~ m#$root(?:$overlay_dir)?(.*)res(?:_[^/]*)?/values#) {
      $module = $1;
    } else {
      say 'oh no!!!';
      next;
    }
    if ($module_resdir_ref->{$module}) {
      push $module_resdir_ref->{$module}, $file;
    } else {
      $module_resdir_ref->{$module} = [$file];
    }
  }
}

sub module_reslist {
  my ($root, $overlay_dir, $path) = @_;
  my @directoies = ( $root.$path, $root.$overlay_dir.$path);
  find(\&find_res_dir, @directoies);
  resfiles2module \@res_files;
}


################### MAIN ########################################
module_reslist $root, $overlay_dir, $find_path;
# print Dumper $module_resdir_ref;

die "need out file name" unless $outFile;

my %parserxml_ref;
 for my $module (keys %$module_resdir_ref) {
   $parserxml_ref{$module} = parse_xml($module, $module_resdir_ref->{$module});
   # print Dumper %parserxml_ref;
 }

$worksheet->write(0, 0, "path");
$worksheet->write(0, 1, "name");
my $col = 2;
for (@values) {
  $worksheet->write(0, $col++, $_);
}
write_to_xls($outFile, \%parserxml_ref);
#}
