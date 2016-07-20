#!/usr/bin/env perl
use File::Find;
use XML::Simple;
use XML::LibXML;
use Data::Dumper;
use strict;
use warnings;
use 5.010;

my ($root, $outFile, @values) = @ARGV;
$root.= "/" unless substr($root, -1) eq "/";
say "project: $root";
say "values: @values";
say "write to: $outFile";

my @res_dirs;

# 搜索strings.xml 文件
sub find_res_dir {
    if ($File::Find::dir =~ m#^.*/res[^/]*$# && $_ =~ /^values$/) {
        opendir DIR, $File::Find::name or die "opendir err";
        my @files = grep { /^(?:mtk_)?(strings|arrays).xml$/ && -f "$File::Find::name/$_" } readdir DIR;
        push @res_dirs, $File::Find::name."/".$_ for @files;
    }
}

# 不解析字串中xliff tag
sub XML::LibXML::Node::innerXML{
  my ($self) = shift;
  join '', $self->childNodes();
}

# 解析xml文件
sub parse_xml {
    my $file = shift;
    my %parserxml;
    my $parser = XML::LibXML->new;
    my $doc = $parser->parse_file($file) or die "can't parse $file";
    my @nodeList = $doc->getElementsByTagName('string');
    for my $node (@nodeList) {
        my @attributelist = $node->attributes();
        my $value = $node->innerXML;
        my ($name) = map { $_->nodeValue if $_->nodeName =~ /name/ } @attributelist;
        say "name: ".$name."    value: ".$value;
        $parserxml{$name} = $value;
    }
    \%parserxml;
}

# 写入xls文件
sub write_to_xls {
}


find(\&find_res_dir, "$root"."packages/apps");

for (@res_dirs) {
    my $file = shift @res_dirs;
    say "FILE: ", $file;
    my $parserxml_ref =  parse_xml($file);
    print Dumper $parserxml_ref;
    #write_to_xls($file, $parserxml_ref);
}
