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
my $Result = GetInventory($Client,$Session,$Host,$Field,$Debug);

# Result
print $Result;

exit(0);

### Functions

# Function init
sub init() {
    my $opt_string = 'hf:ds:';
    getopts( "$opt_string", \%opt ) or usage();
    usage() if $opt{h};
    usage() if !$opt{s};
    usage() if !$opt{d} && !$opt{f};

}

# Function help
sub usage() {
    print STDERR << "EOF";
usage: $0 [-hf] [-s hostname]
 -h          : this (help) message
 -f          : get field inventory ['name','alias','os',...] 
 -s hostname : hostname, must match what is in Zabbix.  Zabbix uses FQDN.
 -d	     : 0-1 for debug, list all fields inventory (optional)

example: $0 -s Zabbix-Server -f alias
	 $0 -s Zabbix-Server -d 1
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

# Function GetInventory
sub GetInventory() {
    my ($Client, $Session, $Host, $Field, $Debug) = @_;

    my $json;
    if ( $Field ) {
	$json = {
            jsonrpc => '2.0',
            method  => 'host.get',
            params  => {
            	filter          => {
                    host        => $Host,
                },
                selectInventory => [$Field],
            },
            id   => 2,
            auth => $Session,
        };
    }
    if ( $Debug ) {
	$json = {
            jsonrpc => '2.0',
            method  => 'host.get',
            params  => {
                filter          => {
                    host        => $Host,
                },
                selectInventory => 1,
            },
            id   => 2,
            auth => $Session,
        };
    }

    my $Result = $Client->call($URL, $json);
    die "$$json{method} failed\n" unless ($Result->content->{result});

    my $HostData = $Result->content->{'result'};
    my $Value;

    if ( $Debug ) {
    	print "Inventory obtained from $Host:\n";
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
            	if ( ref($Data{$Attr}) eq 'HASH' ) {
                    my %Inventory = %{ $Data{$Attr} };
                    for my $InventoryID ( keys(%Inventory)) {
						if ( $InventoryID eq $Field && !$Debug ) {
							$Value = $Inventory{$InventoryID};
						}
						if ( $Debug ) {
                    	    print "\t\t\t$InventoryID => $Inventory{$InventoryID}\n";
						}
                    }
                }
            }
        }
    }

    return $Value;
}

