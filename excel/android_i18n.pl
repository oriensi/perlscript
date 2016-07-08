#!/usr/bin/env perl
use File::Find;
#use XML::Simple;
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

sub find_res_dir {
    if ($File::Find::dir =~ m#^.*/res[^/]*$# && $_ =~ /^values$/) {
        opendir DIR, $File::Find::name or die "opendir err";
        my $string = grep { /^(?:mtk_)?(strings|arrays).xml$/ && -f "$File::Find::name/$_" } readdir DIR;
        push @res_dirs, $File::Find::dir if $string;
    }
}

find(\&find_res_dir, "$root"."packages/apps");
say foreach (@res_dirs);

#for (@res_dirs) {
my $file = shift @res_dirs;
$file.="/values/mtk_strings.xml";
say "FILE: ", $file;
# XML::Simple not a good choise
print Dumper $xml;
#}
