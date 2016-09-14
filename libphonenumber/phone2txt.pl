#!/usr/bin/env perl
use Spreadsheet::ParseExcel;
use Data::Dumper;
use strict;
use warnings;
use utf8;
use 5.010;

my $parser   = Spreadsheet::ParseExcel->new();
my $workbook = $parser->parse('177H.xls');

my %city2en = (  广东 => "Guangdong",  上海 => "Shanghai",
                 江苏 => "Jiangsu",    浙江 => "Zhejiang",
                 福建 => "Fujian",     四川 => "Sichuan",
                 湖北 => "Hubei",      湖南 => "Hunan",
                 陕西 => "Shanxi",     云南 => "Yunnan",
                 安徽 => "Anhui",      广西 => "Guangxi",
                 新疆 => "Xinjiang",   重庆 => "Chongqing",
                 江西 => "Jiangxi",    甘肃 => "Gansu",
                 贵州 => "Guizhou",    海南 => "Hainan",
                 宁夏 => "Ningxia",    青海 => "Qinghai",
                 西藏 => "Xizang",     北京 => "Beijing",
                 天津 => "Tianjin",    山东 => "Shandong",
                 河南 => "Henan",      辽宁 => "Liaoning",
                 河北 => "Hebei",      山西 => "Shanxi",
                 内蒙古 => "Neimenggu",吉林 => "Jilin",
                 黑龙江 => "Heilongjiang",
    );
my @city_spec = qw(天津 北京 上海 重庆 内蒙古 西藏 新疆 广西 宁夏);

if ( !defined $workbook ) {
    die $parser->error(), ".\n";
}

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
            while ($value =~ m/(\d+)-(\d+)/) {
                my $temp = join ',', ($1 .. $2);
                $value =~ s/(\d+)-(\d+)/$temp/;
            }
            my @nums = split '[^\d]', $value;
            @nums = map ("86".$prefix_num{$col}.$_,  @nums);
            for my $num (@nums) {
                my @addr = ($province, $city);
                my @adds;
                if ($phonenumber_geo{$num}) {
                    my $addr = $phonenumber_geo{$num};
                    if ($addr) {
                        for (@$addr) {
                            die "address error: $num $province" unless ($_[0] =~ /$province/);
                        }
                    }
                    push @adds, @$addr;
                }
                push @adds, \@addr;
                $phonenumber_geo{$num} = \@adds;
            }
        }
    }
}
# print Dumper %phonenumber_geo;

sub write_out {
    open OUT, ">", "173.txt"  or die "open err";
    for my $number (keys %phonenumber_geo) {
        my $add = $phonenumber_geo{$number};
        #   print Dumper $add;
        #   print Dumper $phonenumber_geo{number};
        $add = getadd($add);
        say OUT $number."|".$add;
    }
    close OUT;
}

sub getadd {
    my ($add) = shift;
#    print Dumper $add;
    my @adds = $add->[0];
    my $address = $adds[0][0];
    say "shen:". $address;
    my $index ;
    for ($index = 0; $index <= $#city_spec; $index++) {
        last if ($address eq $city_spec[$index])
    }
    if ($index <= 3) {
        return $address .= "市";
    } elsif ($index <= 8) {
        $address .= "===============";
    } else {
        $address .= "省";
    }
    my @citys = map ($_->[1]."市", @adds);
    $address .= join "\x3001", @citys;
}

my @google_geo;
open FH, "<", "86zh.txt" or die "open err";

while (<FH>) {
    next if /^#/;
    next if /^\s*$/;
    push @google_geo, $_;
}
say "read ok";
close FH;

#open OUT, ">>", "177.txt"  or die "open err";
foreach my $number (keys %phonenumber_geo) {
    my $match = 0;
    for my $line (@google_geo) {
        chomp $line;
        if ($line =~ /^$number\|/) {
            say $line;
            my @adds = $phonenumber_geo{$number}->[0];
            for (@adds) {
                unless ($line =~ /$_->[0]/ && $line =~ /$_->[1]/) {
                    $match = -1;
                    last;
                }
            }
        }
        $match = 1;
    }
    if ($match == -1) {
        say "err:  $number   need modify";
    } elsif ($match == 0) {
        say "err:  $number   no this data";
    }
}
#close OUT;
