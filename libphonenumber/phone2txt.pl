#!/usr/bin/env perl
use Spreadsheet::ParseExcel;
use Data::Dumper;
use strict;
use warnings;
use utf8;
use 5.010;

my $parser   = Spreadsheet::ParseExcel->new();
my $workbook = $parser->parse('173H.xls');

my %city2en = qq(广东 => "Guangdong",  上海 => "Shanghai",
                 江苏 => Jiangsu,    浙江 => "Zhejiang",
                 福建 => "Fujian",     四川 => "Sichuan",
                 湖北 => "Hubei",      湖南 => "Hunan",
                 
);
my %city_spec = qw();
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

    #for my $row ( 3 .. $row_max ) {
    for my $row ( 3 .. 5 ) {
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
            @nums = map ($prefix_num{$col}.$_,  @nums);
            for my $num (@nums) {
                my @addr = ($province, $city);
                my @adds;
                if ($phonenumber_geo{$num}) {
                    my $addr = $phonenumber_geo{$num};
                    if ($addr) {
                        for (@$addr) {
                            die "address error: $num" unless ($_[0] =~ /$province/);
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
print Dumper %phonenumber_geo;

for my $number (keys %phonenumber_geo) {
    my $add = $phonenumber_geo{$number};
#   print Dumper $add;
#   print Dumper $phonenumber_geo{number};
    $add = getadd($add);
    say $number."|".$add;
}

sub getadd {
    my ($add) = shift;
#    print Dumper $add;
    my @adds = $add->[0];
    my $address = $adds[0][0];
    say "shen:". $address;
    $address .= "省";# unless city_spec($address);
    my @citys = map ($_->[1]."市", @adds);
    $address .= join "\x3001", @citys;
}

# my @google_geo;
# open FH, "<", "86.txt" or die "open err";

# while (<FH>) {
#     next if /^#/;
#     next if /^\s*$/;
#     push @google_geo, $_;
# }

# foreach my $number (keys %phonenumber_geo) {
#     my $match = 0;
#     for my $line (@google_geo) {
#         if ($line =~ /^86$number\|/) {
#             say $line;
#             unless ($line =~ /$phonenumber_geo{$number}[0]/ && $line =~ /$phonenumber_geo{$number}[1]/) {
#                 say $number."|".$phonenumber_geo{$number}[0]." ".$phonenumber_geo{$number}[1];
#                 last;
#             }
#             else {
#                 say "match";
#                 $match = 1;
#             }
#         }
#     }
#     if (!$match) {
#         say "no num";
#     }
