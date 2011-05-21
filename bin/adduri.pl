#!/usr/bin/perl
use warnings;
use strict;
use Digest::SHA qw/sha256_hex/;
use LWP::Simple qw/get/;
use URI;
use URI::QueryParam;

if(@ARGV != 1 || @ARGV != 2) {
	print "USAGE: $0 <uri> [tag]\n";
	exit(1);
}

my $uri = $ARGV[0];
my $tag = $ARGV[1];
my $user = 'olof';
my $psk = 'foo';

my $sign = $uri . $psk;
$sign = $tag . $sign if defined $tag;
my $sig = sha256_hex($sign);

my $req = URI->new('http://localhost:3000/add');

$req->query_param('id', $tag) if defined $tag;
$req->query_param('uri', $uri);
$req->query_param('u', $user);
$req->query_param('s', $sig);

print $req . "\n";
