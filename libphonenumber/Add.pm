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

sub get_addr_zh {
    my ($self) = @_;
    $self->{'addr_zh'} or $self->{'prov'}.'-'.$self->{'city'};
}

sub get_addr_en {
    my ($self) = @_;
    $self->{'addr_en'} or $self->{'prov'}.'-'.$self->{'city'};
}

sub get_prov_cn {
    my ($self) = @_;
    if ($self->{'addr_zh'} =~ /^(.*)$self->{'city'}.*$/) {
        $1;
    } else {
        $self->{'prov'};
    }
}

sub get_prov_en {
    my ($self) = @_;
    if ($self->{'addr_en'} =~ /^[^,]*,\s*(.*)$/) {
        $1;
    } else {
        $self->{'prov'};
    }
}

sub get_city_cn {
    my ($self) = @_;
    if ($self->{'addr_zh'} =~ /^.*($self->{'city'}.*)$/) {
        $1
    } else {
        $self->{'city'};
    }
}

sub get_city_en {
    my ($self) = @_;
    if ($self->{'addr_en'} =~ /^([^,])*,\s*.*$/) {
        $1;
    } else {
        $self->{'city'};
    }
}

sub load_all_adds {
    use YAML::XS;
    open FH, "<", "all_addrs.yaml" or return ;
    my $yaml_content = do {local $/; <FH>};
    close FH;
    my @load_addrs = Load $yaml_content;
    my %all_addrs = map {$_->{'prov'}.'-'.$_->{'city'} => $_ } @load_addrs;
}

1;
