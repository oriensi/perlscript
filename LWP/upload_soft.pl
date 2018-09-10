#!/usr/bin/perl -w

############################################################
#                   MAIN
############################################################
package main;
use strict;
use warnings;
use HTTP::Cookies;
use LWP::UserAgent;
use File::Find;
use HTML::TableExtract;
use Data::Dumper;
use File::Spec::Functions qw/rel2abs/;
use 5.010;

require MRequest;
use MRequest;

my ($soft_ver, $UserName, $UserPassword) = @ARGV;
if (! -e $soft_ver || $#ARGV < 1) {
print <<EOF
./upload_soft <SOFTWARE_PATH> <UserName>
EOF
;
exit 
}
$UserPassword = '123456' unless $UserPassword;
chop $soft_ver if $soft_ver =~ /\/$/;
say $soft_ver;
my $url_prex = "http://192.168.11.8:8088/";
my %login_form = (
    UserName => $UserName,
    UserPassword => $UserPassword,
);

my $ua = LWP::UserAgent->new();
open FILE, ">", "response.html" or die "file error!";

$ua->default_header(
        'Accept' => "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8",
        'Accept-Encoding' => "gzip, deflate",
        'Accept-Language' => "zh-CN,zh;q=0.8,en;q=0.6",
        'Cache-Control' => "max-age=0",
        'Connection' => "keep-alive",
        'Content-Type' => "application/x-www-form-urlencoded",
        'User-Agent' => "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/39.0.2171.95 Safari/537.36",
);

############################################################
# login
############################################################
$ua->cookie_jar({});
# $ua->show_progress(1);
my $res = $ua->post( $url_prex."login.php", \%login_form);
die "login error!\n" unless $res->header('location') eq "index.php" ;
print "\nlogin successful!\n";

############################################################
# search soft
############################################################
my $search_soft_url = $url_prex."soft_list.php?search_soft_ver=".$soft_ver;
say $search_soft_url;
$res = $ua->get($search_soft_url);
my $html = $res->content;
die "software already exists ..." if $html =~ /<a href="(soft_info.php[^"]+)"/;
my  $search_by_soft;
$soft_ver =~ /^(.*)(_[vV])(\d+)(?:[-_0-9a-zA-Z]*?)?$/ or die "wrong format of soft version";
$search_soft_url = do {
    if ($3 > 1) {
        $search_by_soft = 1;
        sprintf $url_prex."soft_list.php?search_soft_ver=".$1.$2."%02d", $3-1;
    } else {
        $url_prex."pro_manage.php?search_pro_name=".$1;
    }
};
say $search_soft_url;
$res = $ua->get($search_soft_url);
$html = $res->content;
my $te;
if ($search_by_soft) {
    die "can't find the software info ..." unless $html =~ /<a href="(soft_info.php[^"]+)"/;
    say $1;
    $res = $ua->get($url_prex.$1);
    $html = $res->content;
    $te = HTML::TableExtract->new(depth => 0, count => 0);
} else {
    $te = HTML::TableExtract->new(depth => 0, count => 2);
}

$html =~ s/&nbsp;//g;

my ($playform_name, $pre_pro_name, $customer_name, $pro_name);
$te->parse($html);
foreach my $ts ($te->tables) {
    print "start table.\n";
    print "Table (", join(',', $ts->coords), "):\n";
    my @items = $search_by_soft ? $ts->rows : $ts->columns;
    foreach my $row (@items) {
        shift @$row unless $search_by_soft;
        # print Dumper $row;
        given($$row[0]) {
            when (/所属平台/) {
                $playform_name = $$row[1];
                $playform_name =~ s/\s+//g;
                say "所属平台:", $playform_name;
            }
            when (/一级项目/) {
                $pre_pro_name = $$row[1];
                $pre_pro_name =~ s/\s+//g;
                say "一级项目:", $pre_pro_name;
            }
            when (/所属客户/) {
                $customer_name = $$row[1];
                $customer_name =~ s/\s+//g;
                say "所属客户:", $customer_name;
            }
            when (/所属项目/ || /项目名称/) {
                $pro_name = $$row[1];
                $pro_name =~ s/\s+//g;
                say "所属项目:", $pro_name;
            }
        }
    }
}

############################################################
# release pre
############################################################
$res = $ua->get($url_prex."soft_release_pre.php");
$html = $res->content;
die "$playform_name" unless $html =~ m/^\s*+<option value="(soft_release_pre.php[^"]++)">$playform_name<\/option>/m;

$res = $ua->get($url_prex.$1);
$html = $res->content;
die "$pre_pro_name" unless $html =~ m/^\s*+<option value="(soft_release_pre.php[^"]++)">$pre_pro_name<\/option>/m;

$res = $ua->get($url_prex.$1);
$html = $res->content;
die "$customer_name" unless $html =~ m/^\s*+<option value="(soft_release_pre.php[^"]++)">$customer_name<\/option>/m;

$res = $ua->get($url_prex.$1);
$html = $res->content;
die "$pro_name" unless $html =~ m/^\s*+<option value="(soft_release.php[^"]++)">$pro_name<\/option>/m;
$res = $ua->get($url_prex.$1);
my ($pro_id) = $1 =~ /(\d+)/;
#print FILE $res->content;

############################################################
# release
############################################################

################# get build time ##########################
# my $build_prop;
# find( sub {
          # if ($File::Find::dir =~ m#^out/target/product/[^/]+/system$#) {
              # $build_prop = $File::Find::name if $_ eq "build.prop";
          # }
      # },
      # "out/target/product/"
# );
my $build_prop = `ls out/target/product/*/system/build.prop`;
#$build_prop =~ s/^(.*build\.prop).*?$/$1/ms;
chomp $build_prop;
say $build_prop;
my $builed_time;
do {
    open my $prop, "<", $build_prop or die "open build.prop err!!";
    while(<$prop>) {
        $builed_time = $1 and last if /ro.build.date.utc=(\d+)/;
    }
    close $prop;
};

my ($sec,$min,$hour,$day,$mon,$year,$wday,$yday,$isdst) = localtime($builed_time);
$year += 1900;
$mon++;
$builed_time = sprintf "%4d-%02d-%02d %02d:%02d", $year,$mon,$day,$hour,$min;
say $builed_time;

############## get modify note #################
my $soft_conten = do {
    local $/;
    if ( -e "modify.log") {
        open my $file_in, "<", "modify.log" or die "open err... can't open modify.log!";
        <$file_in>;
    } else {
        say "修改点：";
        <STDIN> ;
    }
};
$soft_conten = "修改点:\n".$soft_conten unless $soft_conten =~ /^修改点/;
say $soft_conten;
die "modify is null..." if length $soft_conten < 10;
################# end ##########################

$html = $res->content;
my $soft_bulider;
die "shouldn't happen. cannot find builder..." unless ($html =~ /<option value="(\d+)"SELECTED>/);
$soft_bulider = $1;
my ($release_post_url) = $html =~ /^\s*<form method="post" id="form1" action="([^"]+)"/m;
die "can't find the post url..." unless $release_post_url;
my ($soft_bin_path, $soft_other_path, $soft_ota_path);
# my @list = glob("$path_of_soft/*.zip");
# print Dumper @list;
# for (@list) {
while (glob("$soft_ver/*.zip")) {
    if ( /$soft_ver\.zip/ ) {
        $soft_bin_path =  $_;
        say "soft_bin_path $soft_bin_path";
    }
    elsif ( /full[^\/]+\.zip/ ) {
        $soft_other_path =  $_;
        say "other: $soft_other_path";
    }
    elsif ( /target_file[^\/]+\.zip/ ) {
        $soft_ota_path =  $_;
        say "FOTA: $soft_ota_path";
    }
    else {
        say "what is this ... : $_";
    }
}
die "no soft bin file! " unless $soft_bin_path;

my %release_form = (
    soft_ver           => $soft_ver,
    soft_conten        => $soft_conten,
    soft_bulider       => $soft_bulider,
    format             => 1,
    soft_bulide_time   => $builed_time,
    soft_bin_path      => [$soft_bin_path],     # soft version
    pro_id             => $pro_id,
    KT_Insert1         => "发布软件",
);

my $empty_file = [
    undef,
    "",
    'Content_Type' => "application/octet-stream",
];

$release_form{soft_other_path} = $soft_other_path ? [$soft_other_path] : $empty_file;
$release_form{soft_ota_path} = $soft_ota_path ? [$soft_ota_path] : $empty_file;

print Dumper \%release_form;
my $req = MRequest::POST ($release_post_url,
    \%release_form,
    'Content-Type' => 'multipart/form-data',
    );
 # print FILE $req->as_string;
 # exit;
say "uploading ... please wait";
$res = $ua->request($req);
# $res = $ua->post(
#     $release_post_url,
#     \%release_form,
#     'Content-Type' => 'multipart/form-data',
#     );
print FILE $res->as_string and die "soft release ERROR!!!!!\n" unless $res->header('location') =~ /soft_list\.php/ ;
say "soft release SUCCESS";
close FILE;
unlink qw/response.html modify.log/;
