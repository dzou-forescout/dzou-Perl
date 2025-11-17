#!/usr/bin/env perl
# echop.pl - SSL Echo Server using IO::Socket::SSL

use strict;
use warnings;
use IO::Socket::SSL;
use FindBin qw($Bin);
use lib $Bin;
use Logger;

##############################################
# Load configuration
##############################################
my $config_file = -e 'inline.cnfg' ? 'inline.cnfg' : "$Bin/inline.cnfg";
my $config      = read_config($config_file);

# Convert relative paths to absolute paths based on script directory
for my $key (qw(log_dir ssl_cert_file ssl_key_file)) {
    next unless defined $config->{$key} && length $config->{$key};
    unless ($config->{$key} =~ m{^/}) {
        $config->{$key} = "$Bin/$config->{$key}";
    }
}

##############################################
# Initialize logger
##############################################
my $logger = Logger->new(
    file     => $config->{log_file},
    dir      => $config->{log_dir},
    level    => $config->{log_level},
    max_size => $config->{max_log_size},
);

$logger->info('Server', 'Starting SSL echo server...');

##############################################
# Create SSL server socket
##############################################
my $server = IO::Socket::SSL->new(
    LocalPort     => $config->{port},
    Listen        => $config->{max_connections},
    Reuse         => 1,
    Proto         => 'tcp',

    SSL_server    => 1,
    SSL_cert_file => $config->{ssl_cert_file},
    SSL_key_file  => $config->{ssl_key_file},
) or die "Failed to create SSL server socket: $IO::Socket::SSL::SSL_ERROR\n";

print "SSL Echo Server running on port $config->{port}\n";
$logger->info('Server', "Listening on port $config->{port}");

##############################################
# Main accept loop
##############################################
while (1) {
    my $client = $server->accept();

    unless ($client) {
        $logger->error('Server', "Accept error: $IO::Socket::SSL::SSL_ERROR");
        next;
    }

    my $client_ip =
        $client->peerhost() . ":" . $client->peerport();

    $logger->audit($client_ip, 'New SSL connection established');
    $logger->info('Server', "Client connected from $client_ip");

    handle_client($client, $client_ip);
}

##############################################
# Client handler
##############################################
sub handle_client {
    my ($client, $client_ip) = @_;

    while (my $line = <$client>) {
        chomp $line;

        my ($command, $message) = parse_message($line);

        unless ($command) {
            print $client "ERROR: Invalid command format\n";
            $logger->warn('Server', "Invalid message from $client_ip: $line");
            next;
        }

        if ($command eq 'Say') {
            my $response = "Reply: $message";
            print $client "$response\n";
            $logger->info('Server', "Echoed to $client_ip: $message");

        } elsif ($command eq 'Close') {
            $logger->info('Server', "Client requested close: $client_ip");
            print $client "Reply: Goodbye\n";
            last;

        } else {
            print $client "ERROR: Unknown command\n";
            $logger->warn('Server', "Unknown command from $client_ip: $command");
        }
    }

    $logger->audit($client_ip, 'Connection closed');
    close $client;
}

##############################################
# Command parsing
##############################################
sub parse_message {
    my ($line) = @_;

    if ($line =~ /^(Say|Reply|Close)\s+(.*)$/i) {
        return (ucfirst lc $1, $2);
    } elsif ($line =~ /^(Say|Reply|Close)$/i) {
        return (ucfirst lc $1, '');
    }
    return (undef, undef);
}

##############################################
# Configuration loader
##############################################
sub read_config {
    my ($filename) = @_;

    my %config = (
        port            => 6778,
        host            => 'localhost',
        log_file        => 'echo.log',
        log_dir         => $Bin,
        log_level       => 'INFO',
        max_log_size    => 1_048_576,
        max_connections => 10,

        ssl_cert_file   => 'server.crt',
        ssl_key_file    => 'server.key',
        ssl_verify_mode => 'NONE',
    );

    return \%config unless -e $filename;

    open my $fh, '<', $filename or die "Cannot open config: $!\n";
    while (my $line = <$fh>) {
        next if $line =~ /^\s*#/ || $line =~ /^\s*$/;
        chomp $line;
        if ($line =~ /^(\w+)\s*=\s*(.+)$/) {
            $config{$1} = $2;
        }
    }
    close $fh;

    return \%config;
}

1;
