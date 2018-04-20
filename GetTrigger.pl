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
my $Debug = 1;

# Authenticate
my $Session = Session($Client,$URL,$User,$Pass,$Debug);

# Get
my $Result = Get($Client,$Session,$Debug);

# Result
print $Result;

exit(0);

### Functions

# Function init
sub init() {
    my $opt_string = 'hdt:';
    getopts( "$opt_string", \%opt ) or usage();
    usage() if $opt{h};
}

# Function help
sub usage() {
    print STDERR << "EOF";
usage: $0 [-hd] [-t triggerid] 
 -h          : this (help) message

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

# Function Get
sub Get() {
    my ($Client, $Session, $Debug) = @_;

    my $json = {
        jsonrpc => '2.0',
        method  => 'trigger.getobjects',
        params  => {
	    	description => '{$ALCANZAB_AMBITO}Inalcanzabilidad PING',
		nodeids => 0,
	},
        auth => $Session,
	id => 2,
    };

    my $Result = $Client->call($URL, $json);
    die "$$json{method} failed\n" unless ($Result->content->{result});

    my $Data = $Result->content->{'result'};
    my $Value;

    if ( $Debug ) {
    	print "Data obtained:\n";
    }
    for my $Key ( @{ $Data } ) {
		if ( $Debug ) {
    	    print "\t$Key:\n";
		}
    	if ( ref($Key) eq 'HASH' ) {
            my %Data = %{ $Key };
            for my $Attr ( keys(%Data) ) {
				if ( $Debug ) {
            	    print "\t\t$Attr => $Data{$Attr}\n";
				}
            	if ( ref($Data{$Attr}) eq 'HASH' ) {
                    my %SubData = %{ $Data{$Attr} };
                    for my $SubKey ( keys(%SubData)) {
						if ( !$Debug ) {
							$Value = $SubData{$SubKey};
						}
						if ( $Debug ) {
							print "\t\t\t$SubKey => $SubData{$SubKey}\n";
						}
                    }
                }
            }
        }
    }

    return $Value;
}

