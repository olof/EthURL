# Copyright 2011, Olof Johansson <olof@ethup.se>
#
# Copying and distribution of this file, with or without 
# modification, are permitted in any medium without royalty 
# provided the copyright notice are preserved. This file is 
# offered as-is, without any warranty.

package EthURL;
use Dancer ':syntax';
use DBI;
use Digest::SHA qw/sha256_hex/;

our $VERSION = '0.1';

my $dbi;

sub get_uri {
	my $id = shift;

	my $sql = 'SELECT uri FROM map WHERE id=?;';
	my $sth = $dbi->prepare($sql);
	$sth->execute($id);

	my ($uri) = $sth->fetchrow_array;
	return $uri;
}

sub add_uri {
	my ($id, $uri, $user) = @_;

	my $sql = 'INSERT INTO map VALUES(?, ?, ?);';
	my $sth = $dbi->prepare($sql);
	$sth->execute($id, $uri, $user);
}

sub get_psk {
	my $user = shift;

	my $sql = 'SELECT psk FROM users WHERE id=?;';
	my $sth = $dbi->prepare($sql);
	$sth->execute($user);

	my ($psk) = $sth->fetchrow_array;
	return $psk;
}

sub gen_id {
	my $id = sprintf("%06x", int(rand(2**16-1)));

	return gen_id() if get_uri($id);
	return $id;
}

before sub {
	my $db = config->{database};
	my $host = config->{dbhost};
	my $user = config->{dbuser};
	my $pass = config->{dbpass};

	$dbi = DBI->connect(
		"DBI:mysql:database=$db;host=$host",
		$user, $pass
	);
};

get '/add' => sub {
	my $user = params->{u};
	my $sig = params->{'s'};
	my $uri = params->{uri};
	my $id = params->{id};

	if(not defined $uri) {
		status 'bad_request';
		return "No 'uri' parameter\n";
	}
	
	if(not defined $user) {
		status 'bad_request';
		return "No 'u' parameter\n";
	}
	
	if(not defined $sig) {
		status 'bad_request';
		return "No 's' parameter\n";
	}
	
	if(get_uri($id)) {
		status 'bad_request';
		return "The id '$id' is already used\n";
	}

	my $psk = get_psk($user);
	my $sign = $uri . $psk;
	$sign = $id . $sign if defined $id;
	my $refsig = sha256_hex($sign);

	if($refsig ne $sig) {
		status 'forbidden';
		return "Signature does not match\n";
	}

	$id = gen_id() unless defined $id;

	debug "uri: $uri";

	add_uri($id, $uri, $user);
	return "ok";
};

get '/:id' => sub {
	my $id = params->{id};
	
	my $uri = get_uri($id);
	if($uri) {
		redirect $uri;
		return "$uri\n";
	} else {
		status 'not_found';
		return "This short URI does not exist (anymore?).\n";
	}
};

true;
