#!/usr/bin/env perl
use Spreadsheet::ParseExcel;
use Data::Dumper;
use strict;
use warnings;
use utf8;
use 5.010;
use Encode qw(decode encode _utf8_on _utf8_off);
use Add;

my $file = shift;
my $parser = Spreadsheet::ParseExcel->new();
my $workbook = $parser->parse($file);

if ( !defined $workbook ) {
  die $parser->error(), ".\n";
}
my @adds;
for my $worksheet ( $workbook->worksheets() ) {
  my ( $row_min, $row_max ) = $worksheet->row_range();
  my ( $col_min, $col_max ) = $worksheet->col_range();

  for my $row ( 3 .. $row_max ) {
    my $province = $worksheet->get_cell($row, 0)->value;
    my $city     = $worksheet->get_cell($row, 1)->value;
    my $exist;
    for my $add (@adds) {
      $exist = 1 if ($add->{'prov'} eq $province && $add->{'city'} eq $city);
    }
    next if $exist;
    my $new_add = Add->new('prov' => $province, 'city' => $city);
    push @adds, $new_add;
  }
}

my %all_adds_cn;
open ZH, "<", "zh.txt" or die "open err";
while (<ZH>) {
  _utf8_on $_;
  chomp;
  my ($num, $add) = split /\|/;
  $all_adds_cn{$add} = $num;
}
close ZH;

my %all_adds_en;
open EN, "<", "en.txt" or die "open err";
while (<EN>) {
  _utf8_on $_;
  chomp;
  my ($num, $add) = split /\|/;
  $all_adds_en{$add} = $num;
}
close EN;
%all_adds_en = reverse %all_adds_en;
foreach my $key (keys %all_adds_cn) {
  $all_adds_cn{$key} = $all_adds_en{$all_adds_cn{$key}};
}


for my $add (@adds) {
  my ($prov, $city) = ($add->{'prov'}, $add->{'city'});
  my ($count, $add_str);
  foreach my $key (keys %all_adds_cn) {
    if ($key =~ /$prov/ && $key =~ /$city/) {
      $count++;
      $add_str .= "${key}\t";
      $add_str .= $all_adds_cn{$key};
    }
  }
  if ($count > 1) {
    $add_str = "==========".$add_str;
  }
  say $add->{'prov'}."\t".$add->{'city'}."\t".$add_str;
}
