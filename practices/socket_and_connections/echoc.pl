#!/usr/bin/env perl
# echoc.pl - SSL Echo Client using IO::Socket::SSL

use strict;
use warnings;
use IO::Socket::SSL qw(SSL_VERIFY_NONE SSL_VERIFY_PEER);
use FindBin qw($Bin);
use lib $Bin;
use Logger;

##############################################
# Load configuration
##############################################
my $config = read_config("$Bin/inline.cnfg");

# Convert relative log_dir to absolute path
if ($config->{log_dir} !~ m{^/}) {
    $config->{log_dir} = "$Bin/$config->{log_dir}";
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

$logger->info('Client', 'Starting SSL echo client...');

##############################################
# SSL verification mode
##############################################
my $verify_mode =
    (!defined $config->{ssl_verify_mode} ||
        uc($config->{ssl_verify_mode}) eq 'NONE')
        ? SSL_VERIFY_NONE
        : SSL_VERIFY_PEER;

##############################################
# Create SSL client socket
##############################################
my $socket = IO::Socket::SSL->new(
    PeerHost        => $config->{host},
    PeerPort        => $config->{port},
    Proto           => 'tcp',
    SSL_verify_mode => $verify_mode,
) or die "Failed to connect to SSL server: $IO::Socket::SSL::SSL_ERROR\n";

print "Connected to SSL Echo Server at $config->{host}:$config->{port}\n";
print "Commands: Say <message>, Close\n";
print "Type 'quit' to exit.\n\n";

##############################################
# Main loop
##############################################
while (1) {
    print "You> ";
    my $input = <STDIN>;
    last unless defined $input;
    chomp $input;

    if ($input =~ /^quit$/i) {
        send_command($socket, 'Close', '');
        if (my $reply = <$socket>) {
            print "Server> $reply";
        }
        last;
    }

    next if $input =~ /^\s*$/;

    my ($cmd, $msg) = parse_input($input);

    unless ($cmd) {
        print "Invalid input. Use: Say <text> or Close\n";
        next;
    }

    send_command($socket, $cmd, $msg);

    my $response = <$socket>;
    unless ($response) {
        print "Connection closed by server.\n";
        last;
    }

    print "Server> $response";

    last if $cmd eq 'Close';
}

close $socket;
print "Disconnected.\n";

##############################################
# Helper: send command to server
##############################################
sub send_command {
    my ($socket, $cmd, $msg) = @_;
    if (length $msg) {
        print $socket "$cmd $msg\n";
    } else {
        print $socket "$cmd\n";
    }
}

##############################################
# Helper: parse user input
##############################################
sub parse_input {
    my ($input) = @_;

    if ($input =~ /^(Say)\s+(.+)$/i) {
        return (ucfirst lc $1, $2);
    }
    if ($input =~ /^(Close)$/i) {
        return (ucfirst lc $1, '');
    }
    return ('Say', $input);  # Default behavior
}

##############################################
# Config loader
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
