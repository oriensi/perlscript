#!/usr/bin/env perl
use Spreadsheet::ParseExcel;
use Data::Dumper;
use strict;
use warnings;
use utf8;
use Add;
use 5.010;
use YAML::XS;

my $parser   = Spreadsheet::ParseExcel->new();
my $workbook = $parser->parse('177H.xls');

if ( !defined $workbook ) {
    die $parser->error(), ".\n";
}


my %all_addrs = &load_all_adds;

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
                # my $new_add = Add->new('prov' => $province, 'city' => $city);
                my $new_add = $all_addrs{$province.'-'.$city};
                my @adds;
                if ($phonenumber_geo{$num}) {
                    my $addr = $phonenumber_geo{$num};
                    if ($addr) {
                        for my $add (@$addr) {
                            die "address error: $num $province" unless ($add->{'prov'} =~ /$province/);
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
print Dumper %phonenumber_geo;

sub write_out {
    open ZH, ">", "86_zh.txt"  or die "open err";
    open EN, ">", "86_en.txt" or die "open err";
    for my $number (keys %phonenumber_geo) {
        my $add = $phonenumber_geo{$number};
        #   print Dumper $add;
        #   print Dumper $phonenumber_geo{number};
        my $zh_add = get_zh_add($add);
        say ZH $number."|".$zh_add;
        my $en_add = get_en_add($add);
        say EN $number."|".$en_add;
    }
    close ZH;
    close EN;
}

sub get_en_add {

    for my $number (keys %phonenumber_geo) {
        my $add = $phonenumber_geo{$number};
        $add = get_en_add($add);
        say EN $number."|".$add;
    }
    close EN;
}

sub get_zh_add {
    my ($add) = shift;
    #    print Dumper $add;
    my @adds = $add->[0];
    my $address = $adds[0][0];
    say "shen:". $address;
    for (@adds) {
        die "spec province: $address" unless $address eq $_->[0];
    }
    my $index;
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

sub load_all_adds {
    open FH, "<", "all_addrs.yaml" or die "open err";
    my $yaml_content = do {local $/; <FH>};
    close FH;
    my @load_addrs = Load $yaml_content;
    my %all_addrs = map {$_->{'prov'}.'-'.$_->{'city'} => $_ } @load_addrs;
}

my @google_geo;
open FH, "<", "86zh.txt" or die "open err";

while (<FH>) {
    chomp;
    next if /^#/;
    next if /^\s*$/;
    push @google_geo, $_;
}
say "read ok";
close FH;

@google_geo = grep { $_ =~ /^(\d{5})/ && $1 == 86177 } @google_geo;

#open OUT, ">>", "177.txt"  or die "open err";
foreach my $number (keys %phonenumber_geo) {
    my $match = 0;
    for my $line (@google_geo) {
        if ($line =~ /^$number\|/) {
            say $line;
            my @adds = $phonenumber_geo{$number}->[0];
            for (@adds) {
                unless ($line =~ /$_->[0]/ && $line =~ /$_->[1]/) {
                    $match = -1;
                    last;
                }
            }
            $match = 1 unless $match == -1;
        }
    }
    if ($match == -1) {
        say "err:  $number   need modify";
    } elsif ($match == 0) {
        say "err:  $number   no this data";
    }
}
#close OUT;
