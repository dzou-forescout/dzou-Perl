#!/usr/bin/perl

use strict;
use warnings;
use IO::Socket::INET;
use FindBin;
use lib $FindBin::Bin;
use Logger;
use FindBin qw($RealBin);

# Read configuration file
my $config = read_config('inline.cnfg');

# Initialize logger
my $logger = Logger->new(
    file     => $config->{log_file},
    dir      => $config->{log_dir},
    level    => $config->{log_level},
    max_size => $config->{max_log_size},
);

$logger->info('Server', 'Echo server starting...');

# Create server socket
my $server = IO::Socket::INET->new(
    LocalPort => $config->{port},
    Type      => SOCK_STREAM,
    Reuse     => 1,
    Listen    => $config->{max_connections},
) or die "Cannot create server socket: $!\n";

$logger->info('Server', "Server listening on port $config->{port}");
print "Echo server listening on port $config->{port}...\n";

# Main server loop
while (1) {
    # Accept new connection
    my $client = $server->accept();

    unless ($client) {
        $logger->error('Server', 'Failed to accept connection');
        next;
    }

    my $client_addr = $client->peerhost();
    my $client_port = $client->peerport();
    my $client_ip = "$client_addr:$client_port";

    # Call audit function on new connection
    $logger->audit($client_ip, 'New connection established');
    $logger->info('Server', "Client connected from $client_ip");

    # Handle client in subprocess (simple single-threaded version)
    handle_client($client, $client_ip);
}

sub handle_client {
    my ($client, $client_ip) = @_;

    $logger->info('Server', "Handling client $client_ip");

    while (my $line = <$client>) {
        chomp $line;

        # Parse message
        my ($command, $message) = parse_message($line);

        unless ($command) {
            $logger->warn('Server', "Invalid message format from $client_ip: $line");
            print $client "ERROR: Invalid message format\n";
            next;
        }

        $logger->debug('Server', "Received from $client_ip: $command => $message");

        # Process commands
        if ($command eq 'Say') {
            # Echo back the message
            my $response = "Reply: $message";
            print $client "$response\n";
            $logger->info('Server', "Echoed to $client_ip: $message");

        } elsif ($command eq 'Reply') {
            # Client shouldn't send Reply, but handle it gracefully
            $logger->warn('Server', "Client $client_ip sent Reply command (unexpected)");
            print $client "ERROR: Reply command not expected from client\n";

        } elsif ($command eq 'Close') {
            # Client wants to close connection
            $logger->info('Server', "Client $client_ip requested close");
            print $client "Reply: Goodbye\n";
            last;

        } else {
            $logger->warn('Server', "Unknown command from $client_ip: $command");
            print $client "ERROR: Unknown command '$command'\n";
        }
    }

    $logger->audit($client_ip, 'Connection closed');
    $logger->info('Server', "Client $client_ip disconnected");
    close $client;
}

sub parse_message {
    my ($line) = @_;

    # Expected format: <Command> <Message>
    # Commands: Say, Reply, Close
    if ($line =~ /^(Say|Reply|Close)\s+(.*)$/i) {
        return (ucfirst(lc($1)), $2);
    } elsif ($line =~ /^(Say|Reply|Close)$/i) {
        return (ucfirst(lc($1)), '');
    }

    return (undef, undef);
}

sub read_config {
    my ($filename) = @_;

    my %config = (
        port            => 6778,
        host            => 'localhost',
        log_file        => 'echo.log',
        log_dir         => '/tmp',
        log_level       => 'INFO',
        max_log_size    => 1048576,
        max_connections => 10,
        buffer_size     => 1024,
    );

    return \%config unless -e $filename;

    open my $fh, '<', $filename or die "Cannot open config file '$filename': $!\n";

    while (my $line = <$fh>) {
        chomp $line;
        next if $line =~ /^\s*#/;  # Skip comments
        next if $line =~ /^\s*$/;   # Skip empty lines

        if ($line =~ /^\s*(\w+)\s*=\s*(.+?)\s*$/) {
            my ($key, $value) = ($1, $2);
            $config{$key} = $value;
        }
    }

    close $fh;

    return \%config;
}

__END__

=head1 NAME

echo-server.pl - Simple echo server with logging

=head1 DESCRIPTION

This server listens on a configurable port (default 6778) and echoes
back messages from clients. It uses the Logger module for comprehensive
logging and audit trails.

=head1 COMMANDS

=over 4

=item Say <message>

Echo the message back to the client.

=item Close

Close the connection gracefully.

=back

=cut