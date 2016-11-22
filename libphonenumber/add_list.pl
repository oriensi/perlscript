#!/usr/bin/env perl
use Spreadsheet::ParseExcel;
use Data::Dumper;
use strict;
use warnings;
use utf8;
use 5.010;
use Encode qw/decode encode _utf8_on _utf8_off/;
#use utf8::all;
use Add;

my @files = @ARGV;

my @municipality = qw/上海市 重庆市 北京市 天津市/;
# my %spec_city = ();
my %all_addrs = Add->load_all_adds;
my @adds;
for my $file (@files) {
my $parser = Spreadsheet::ParseExcel->new();
my $workbook = $parser->parse($file);

if ( !defined $workbook ) {
  die $parser->error(), ".\n";
}

for my $worksheet ( $workbook->worksheets() ) {
  my ( $row_min, $row_max ) = $worksheet->row_range();
  my ( $col_min, $col_max ) = $worksheet->col_range();

  for my $row ( 3 .. $row_max ) {
    my $province = $worksheet->get_cell($row, 0)->value;
    my $city     = $worksheet->get_cell($row, 1)->value;
    my $exist;
    for my $add (@adds) {
      $exist = 1 and last if ($add->{'prov'} eq $province && $add->{'city'} eq $city);
    }
    next if $exist || $all_addrs{$province.'-'.$city};
    my $new_add = Add->new('prov' => $province, 'city' => $city);
    push @adds, $new_add;
  }
}
}

my %all_adds_cn;
open ZH, "<", "86zh.txt" or die "open err";
while (<ZH>) {
  _utf8_on $_;
  chomp;
  next if /^#/;
  next if /^\s*$/;
  my ($num, $add) = split /\|/;
  $all_adds_cn{$add} = $num unless $all_adds_cn{$add};
}
close ZH;

my %all_adds_en;
open EN, "<", "86en.txt" or die "open err";
while (<EN>) {
  _utf8_on $_;
  chomp;
  next if /^#/;
  next if /^\s*$/;
  my ($num, $add) = split /\|/;
  $all_adds_en{$add} = $num unless $all_adds_en{$add};
}
close EN;

%all_adds_en = reverse %all_adds_en;
foreach my $key (keys %all_adds_cn) {
  $all_adds_cn{$key} = $all_adds_en{$all_adds_cn{$key}};
}


for my $add (@adds) {
  my ($prov, $city) = ($add->{'prov'}, $add->{'city'});
  my ($add_str, @temp_add);
  foreach my $key (keys %all_adds_cn) {
    if ($key =~ /${prov}.*${city}/) {
      push @temp_add , $key;
    }
  }

  if (scalar @temp_add == 1) {
    $add->{'addr_zh'} = $temp_add[0];
    $add->{'addr_en'} = $all_adds_cn{$temp_add[0]};
  } elsif (scalar @temp_add == 0) {
    for (@municipality) {
      if (/$prov/) {
        $add->{'addr_zh'} = $_;
        $add->{'addr_en'} = $all_adds_cn{$_};
      }
    }
  } else {
    my @t_add = grep { !/\x{3001}/ } @temp_add;
    if (scalar @t_add == 1) {
      $add->{'addr_zh'} = $t_add[0];
      $add->{'addr_en'} = $all_adds_cn{$t_add[0]};
    } else {
      $add->{'addr_zh'} = "===".$temp_add[0];
      $add->{'addr_en'} = $all_adds_cn{$temp_add[0]};
    }
  }
  # say $add->{'prov'}."\t".$add->{'city'}."\t".$add_str;
}

use YAML::XS;
open ALL, '>>', 'all_addrs.yaml' or die 'open err';
print ALL (Dump @adds);
close ALL;
