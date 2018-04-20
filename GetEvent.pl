#!/usr/bin/env perl

use utf8;
use strict;
#use warnings;
use Getopt::Std;
use vars qw/ %opt /;
use JSON::RPC::Client;

init();

# Variables
my $Client = JSON::RPC::Client->new;
my $URL  = 'http://your-ip-dns-zabbix/zabbix/api_jsonrpc.php';
my $User = '';
my $Pass = '';
my $Host = $opt{s};
my $Field = $opt{f};
my $Debug = $opt{d} || 0;

# Authenticate
my $Session = Session($Client,$URL,$User,$Pass,$Debug);

# GetInventory
my $Result = GetEvent($Client,$Session,$Host,$Field,$Debug);

# Result
print "Result: $Result\n";

exit(0);

### Functions

# Function init
sub init() {
    my $opt_string = 'hdt:';
    getopts( "$opt_string", \%opt ) or usage();
    usage() if $opt{h};
    usage() if !$opt{d} && !$opt{t};

}

# Function help
sub usage() {
    print STDERR << "EOF";
usage: $0 [-hd] [-t triggerid] 
 -h          : this (help) message
 -t          : triggerid 
 -d	     : 0-1 for debug, list all fields inventory (optional)

example: $0 -t 10310300000019372
	 $0 -t 10310300000019372 -d 1
EOF

    exit;
}

# Function Session
sub Session() {
    my ($Client, $URL, $User, $Pass, $Debug) = @_;

    my $json = {
        jsonrpc => '2.0',
        method  => 'user.login',
    	params  => {
            user     => $User,
            password => $Pass,
    	},
    	id => 1,
    };

    my $Result = $Client->call($URL, $json);
    die "\nCould not authenticate.\n" unless ($Result->content->{result});

    my $Session = $Result->content->{'result'};

    if ( $Debug ) {
    	print "\nAuthentication successful, Auth ID: $Session\n\n";
    }

    return $Session;
}

# Function GetEvent
sub GetEvent() {
    my ($Client, $Session, $Host, $Field, $Debug) = @_;

    my $json = {
        jsonrpc => '2.0',
        method  => 'event.get',
        params  => {
	    output => 'extend',
	    objectids => ['10310300000019372','10310300000019601'],
	    time_from => '1462053600',
	    time_till => '1464732000',
	    sortfield => ['clock','eventid'],
	    sortorder => 'desc',
	},
        id   => 2,
        auth => $Session,
    };

    my $Result = $Client->call($URL, $json);
    die "$$json{method} failed\n" unless ($Result->content->{result});

    my $HostData = $Result->content->{'result'};

    if ( $Debug ) {
    	print "Events obtained from $Host:\n";
    }
    for my $Host ( @{ $HostData } ) {
	if ( $Debug ) {
    	    print "\t$Host:\n";
	}
    	if ( ref($Host) eq 'HASH' ) {
            my %Data = %{ $Host };
            for my $Attr ( keys(%Data) ) {
				if ( $Debug ) {
            	    print "\t\t$Attr => $Data{$Attr}\n";
				}
            }
        }
    }

    return $HostData;
}

