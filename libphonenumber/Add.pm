#!/usr/bin/env perl
use Spreadsheet::ParseExcel;
use Data::Dumper;
use strict;
use warnings;
use utf8;
use 5.010;

package Add;

sub new {
  my $type = shift;
  my %parm = @_;
  my $this = {};
  $this->{'prov'} = $parm{'prov'};
  $this->{'city'} = $parm{'city'};
  $this->{'addr_en'} = $parm{'addr_en'};
  $this->{'addr_zh'} = $parm{'addr_zh'};
  bless $this, $type;
}

1;
