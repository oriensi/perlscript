#!/usr/bin/env perl
use warnings;
use strict;
use 5.010;
use YAML::XS;
use Data::Dumper;
use utf8;

my $yaml = Dump [ 1..4 ];
my $array = Load $yaml;
print Dumper $yaml;
print Dumper $array;

open FH, "<", "test.yaml" or die "open err";
my $yaml_content = do { local $/; <FH>};
# print $yaml_content;
close FH;
my $yaml = Load $yaml_content;
print Dumper $yaml;

my %h2p = map {my @temp = split ' '; $temp[0] => $temp[1]} @$yaml;
print Dumper %h2p;
