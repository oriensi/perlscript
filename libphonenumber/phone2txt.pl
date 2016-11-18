#!/usr/bin/env perl
use Spreadsheet::ParseExcel;
use Data::Dumper;
use strict;
use warnings;
use utf8;
use utf8::all;
use Add;
use 5.010;
use YAML::XS;

my ($file, $prefix) = @ARGV;
$prefix = '86'.$prefix;
my $parser   = Spreadsheet::ParseExcel->new();
my $workbook = $parser->parse($file);

if ( !defined $workbook ) {
    die $parser->error(), ".\n";
}


my %all_addrs = Add->load_all_adds;

my %phonenumber_geo;
my %prefix_num;
for my $worksheet ( $workbook->worksheets() ) {
    my ( $row_min, $row_max ) = $worksheet->row_range();
    my ( $col_min, $col_max ) = $worksheet->col_range();

    for my $col ( 3 .. $col_max ) {
        my $cell = $worksheet->get_cell( 2, $col );
        next unless $cell;
        $prefix_num{$col} = $cell->value;
    }

    for my $row ( 3 .. $row_max ) {
        my $province = $worksheet->get_cell($row, 0)->value;
        my $city     = $worksheet->get_cell($row, 1)->value;
        for my $col ( 3 .. $col_max ) {
            my $cell = $worksheet->get_cell( $row, $col );
            next unless $cell;

            my $value = $cell->value();
            # $value =~ s/(\d+)-(\d+)(?{$temp = join '、', ($1 .. $2)})/$temp/g;
            my $not_null_value = $value;
            while ($value =~ m/(\d+)-(\d+)/) {
                my $temp;
                my @temp_array = ($1 .. $2);
                my @num_array;
                while (scalar @temp_array) {
                    my $len = length($temp_array[-1] - $temp_array[0] + 1) - 1;
                    if ($len >= 1 && substr($temp_array[0], -1) == 0) {
                        for my $i (reverse (1 .. $len)) {
                            if (substr($temp_array[0], 0 - $i) == 0) {
                                my $push = substr($temp_array[0], 0, 0 - $i);
                                push @num_array, $push;
                                @temp_array = grep {$_ > $temp_array[0] + 10**$i - 1} @temp_array;
                                last;
                            }
                        }
                    } else {
                        push @num_array, shift @temp_array;
                    }
                }
                $temp = join ',', @num_array;
                $value =~ s/(\d+)-(\d+)/$temp/;
            }
            my @nums = split '[^\d]', $value;
            @nums = ('') if $not_null_value && !@nums;
            @nums = map {"86".$prefix_num{$col}.$_} @nums;
            for my $num (@nums) {
                # my $new_add = Add->new('prov' => $province, 'city' => $city);
                my $new_add = $all_addrs{$province.'-'.$city};
                my @adds;
                if ($phonenumber_geo{$num}) {
                    my $addr = $phonenumber_geo{$num};
                    if ($addr) {
                        for my $add (@$addr) {
                            die "address error: $num $province - $add->{'prov'}" unless ($add->{'prov'} =~ /$province/);
                        }
                    }
                    push @adds, @$addr;
                }
                push @adds, $new_add;
                $phonenumber_geo{$num} = \@adds;
            }
        }
    }
}
# print Dumper %phonenumber_geo;

sub get_en_add {
    my $adds = shift;
    my $add_str;
    if (scalar @$adds == 1) {
        $add_str = $adds->[0]->get_addr_en;
    } elsif (scalar @$adds > 1) {
        my @temp_adds = @$adds;
        $add_str = $adds->[0]->get_addr_en;
        shift @temp_adds;
        for (@temp_adds) {
            $add_str = $_->get_city_en ."/".$add_str;
        }
    } else {
        $add_str = "===================";
    }
    $add_str;
}

sub get_zh_add {
    my ($adds) = shift;
    #    print Dumper $add;
    my $add_str;
    if (scalar @$adds == 1) {
        $add_str = $adds->[0]->get_addr_zh;
    } elsif (scalar @$adds > 1) {
        my @temp_adds = @$adds;
        $add_str = $temp_adds[0]->get_addr_zh;
        shift @temp_adds;
        for (@temp_adds) {
            $add_str .= "\x{3001}".$_->get_city_cn;
        }
    } else {
        $add_str = "=============";
    }
    $add_str;
}


sub get_google_data_cn {
    if (-f $prefix.'_zh.txt') {
        open FH, "<", $prefix.'_zh.txt' or die "open err";
    } else {
        open FH, "<", "86zh.txt" or die "open err";
    }
    my @google_data;
    while (<FH>) {
        chomp;
        next if /^#/;
        next if /^\s*$/;
        next if ! /^$prefix/;
        push @google_data, $_;
    }
    close FH;
    map {$_ =~ /^(\d+)\|(.*)$/; $1 => $2 } @google_data;
}

sub get_google_data_en {
    if (-f $prefix.'_en.txt') {
        open FH, "<", $prefix.'_en.txt' or die "open err";
    } else {
        open FH, "<", "86en.txt" or die "open err";
    }
    my @google_data;
    while (<FH>) {
        chomp;
        next if /^#/;
        next if /^\s*$/;
        next if ! /^$prefix/;
        push @google_data, $_;
    }
    close FH;
    map {$_ =~ /^(\d+)\|(.*)$/; $1 => $2 } @google_data;
}

sub update_google_data {
  my %google_geo = @_;
  my @remove;
  foreach my $number (keys %phonenumber_geo) {
    # push @remove, $number and next if ($google_geo{$number});
    if ($google_geo{$number}) { push @remove, $number; delete $google_geo{$number};}
    my @key = grep {index($number, $_) > -1} keys %google_geo;
    # push @remove, @key and next if @key;
    if (@key) { push @remove, @key; delete $google_geo{$_} for @key}
    @key = grep {index($_, $number) > -1} keys %google_geo;
    # push @remove, @key and next if @key;
    if (@key) { push @remove, @key; delete $google_geo{$_} for @key}
  }

  say "remove:";
  say "--: ".$_ for sort @remove;
  @remove;
}

my @remove;
say STDERR "match...";
&write_out_file("zh");
say STDERR "zh write OK!";
&write_out_file("en");
say STDERR "en write OK!";

sub write_out_file {
  my $local = shift;
  my $is_zh = $local eq "zh";
  my %google_geo = $is_zh ? get_google_data_cn : get_google_data_en;
  @remove = update_google_data %google_geo if !@remove;
  delete $google_geo{$_} for @remove;
  say "add:" if $is_zh;
  open FH, ">", $prefix."_".$local.".txt" or die "open err";
  for my $number (sort keys %phonenumber_geo) {
    my $add = $phonenumber_geo{$number};
    my $local_addr = $is_zh ? get_zh_add($add) : get_en_add($add);
    $google_geo{$number} = $local_addr;
    say '++: '.$number.'|'.$local_addr if $is_zh;
  }
  say FH $_.'|'.$google_geo{$_} for (sort keys %google_geo);
  close FH;
}

# sub write_out_zh {
#   my %google_geo = get_google_data_zh;
#   @remove = update_google_data %google_geo if !@remove;
#   delete $google_geo{$_} for @remove;
#   open FH, ">", $prefix."_zh.txt" or die "open err";
#   for my $number (keys %phonenumber_geo) {
#     my $add = $phonenumber_geo{$number};
#     my $local_addr = get_zh_add($add);
#     $google_geo{$number} = $local_addr;
#   }
#   say FH $_.'|'.$google_geo{$_} for (sort keys %google_geo);
#   close FH;
# }
