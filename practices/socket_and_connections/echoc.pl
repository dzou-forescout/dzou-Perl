#!/usr/bin/perl
# echo-client.pl - Echo client using IO::Socket

use strict;
use warnings;
use IO::Socket::INET;
use FindBin;
use lib $FindBin::Bin;
use Logger;

# Read configuration file
my $config = read_config('inline.cnfg');

# Initialize logger
my $logger = Logger->new(
    file     => $config->{log_file},
    dir      => $config->{log_dir},
    level    => $config->{log_level},
    max_size => $config->{max_log_size},
);

$logger->info('Client', 'Echo client starting...');

# Create client socket
my $socket = IO::Socket::INET->new(
    PeerHost => $config->{host},
    PeerPort => $config->{port},
    Proto    => 'tcp',
) or die "Cannot connect to server $config->{host}:$config->{port}: $!\n";

$logger->info('Client', "Connected to server $config->{host}:$config->{port}");
print "Connected to echo server at $config->{host}:$config->{port}\n";
print "Commands: Say <message>, Close\n";
print "Type 'quit' to exit\n\n";

# Main client loop
while (1) {
    print "You> ";
    my $input = <STDIN>;

    unless (defined $input) {
        last;
    }

    chomp $input;

    # Handle local quit command
    if ($input =~ /^quit$/i) {
        $logger->info('Client', 'User initiated quit');
        send_command($socket, 'Close', '');
        my $response = <$socket>;
        if ($response) {
            chomp $response;
            print "Server> $response\n";
        }
        last;
    }

    # Skip empty lines
    next if $input =~ /^\s*$/;

    # Parse and send command
    my ($command, $message) = parse_input($input);

    unless ($command) {
        print "Invalid format. Use: Say <message> or Close\n";
        next;
    }

    $logger->debug('Client', "Sending command: $command => $message");

    # Send to server
    send_command($socket, $command, $message);

    # Get response
    my $response = <$socket>;

    unless ($response) {
        $logger->error('Client', 'No response from server or connection closed');
        print "Connection closed by server\n";
        last;
    }

    chomp $response;
    print "Server> $response\n";

    $logger->info('Client', "Received: $response");

    # Exit if we sent Close
    if ($command eq 'Close') {
        $logger->info('Client', 'Connection closed by command');
        last;
    }
}

$logger->info('Client', 'Client shutting down');
close $socket;
print "Disconnected.\n";

sub send_command {
    my ($socket, $command, $message) = @_;

    if ($message) {
        print $socket "$command $message\n";
    } else {
        print $socket "$command\n";
    }
}

sub parse_input {
    my ($input) = @_;

    # Expected format: <Command> <Message>
    # Commands: Say, Close
    if ($input =~ /^(Say)\s+(.+)$/i) {
        return (ucfirst(lc($1)), $2);
    } elsif ($input =~ /^(Close)$/i) {
        return (ucfirst(lc($1)), '');
    }

    # Also accept plain text as implicit "Say" command
    if ($input !~ /^(Say|Close)/i && $input =~ /\S/) {
        return ('Say', $input);
    }

    return (undef, undef);
}

sub read_config {
    my ($filename) = @_;

    my %config = (
        port         => 6778,
        host         => 'localhost',
        log_file     => 'echo.log',
        log_dir      => '/tmp',
        log_level    => 'INFO',
        max_log_size => 1048576,
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

echo-client.pl - Simple echo client with logging

=head1 DESCRIPTION

This client connects to the echo server and allows interactive
communication. It uses the Logger module for comprehensive logging.

=head1 COMMANDS

=over 4

=item Say <message>

Send a message to be echoed back.

=item Close

Close the connection gracefully.

=item quit

Local command to quit the client (sends Close to server).

=back

=head1 USAGE

    perl echo-client.pl

    You> Say Hello World
    Server> Reply: Hello World

    You> Close
    Server> Reply: Goodbye
    Disconnected.

=cut