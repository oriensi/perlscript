#!/usr/bin/env perl
use File::Find;
use strict;
use warnings;
use 5.010;

my ($root, $outFile, @values) = @ARGV;

say "project: $root";
say "values: @values";
say "write to: $outFile";

my @android_dirs;
sub find_android_dir {
  push @android_dirs, $File::Find::dir if $_ eq "Android.mk";
}

sub find_res_dir {
  my $an_dir = shift;
  my $an_mk_file = $an_dir."/Android.mk";
  open AMF, "<", $an_mk_file or die "open failed!";
  my @args = stat($an_mk_file);
  my $content = do { local $/; <AMF> };
  my @an_res_dirs;
  while ($content =~ /^\s*LOCAL_RESOURCE_DIR \+?=\s*?(.*?[^\\])\s*$/gms) {
    my $tmp = $1;
    $tmp =~ s/\Q$(LOCAL_PATH)\E/$an_dir/g;
    say "TMP: $tmp";
    push @an_res_dirs, (split /[\s\\]+/, $tmp);
  }
  @an_res_dirs;
}

find (\&find_android_dir, "$root"."packages/apps");

for (@android_dirs) {
  my @res_dirs = find_res_dir($_);
  if (@res_dirs > 0) {
    say "#############print res dirs#############";
    say foreach (@res_dirs);
  }
}
