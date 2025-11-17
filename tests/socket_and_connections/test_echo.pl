#!/usr/bin/env perl
use strict;
use warnings;
use v5.16;

use Test::More;
use IO::Socket::INET;
use File::Temp qw(tempdir);
use File::Spec;
use Cwd qw(getcwd chdir);
use FindBin qw($RealBin);

# -----------------------------
# Paths (adjust if needed)
# -----------------------------
my $server_script = "$RealBin/../../practices/socket_and_connections/echop.pl";

unless (-f $server_script) {
    plan skip_all => "Cannot find echo server script at $server_script";
}

# -----------------------------
# Test setup: temp dir + config
# -----------------------------
my $original_dir = getcwd();
my $tmp_dir      = tempdir( CLEANUP => 1 );
chdir $tmp_dir or die "Cannot chdir to $tmp_dir: $!";

my $port     = 6778;                     # you can randomize if you like
my $log_file = 'test-echo.log';
my $log_dir  = $tmp_dir;

# Write a local inline.cnfg used by server & client
{
    open my $cfg, '>', 'inline.cnfg'
        or die "Cannot create inline.cnfg in $tmp_dir: $!";
    print $cfg <<"CFG";
# Test config
port=$port
host=localhost

log_file=$log_file
log_dir=$log_dir
log_level=DEBUG
max_log_size=1048576

max_connections=10
buffer_size=1024
CFG
    close $cfg;
}

# -----------------------------
# Start server in background
# -----------------------------
my $pid = fork();
die "Cannot fork: $!" unless defined $pid;

if ($pid == 0) {
    # Child: run server
    exec $^X, $server_script
        or die "Failed to exec echo server: $!";
    exit 0;
}

# Parent: give server a moment to start
sleep 1;

# -----------------------------
# Connect to server
# -----------------------------
my $sock = IO::Socket::INET->new(
    PeerHost => '127.0.0.1',
    PeerPort => $port,
    Proto    => 'tcp',
);

ok($sock, "Client connected to echo server on port $port")
    or BAIL_OUT("Cannot connect to server: $!");

# -----------------------------
# Test 1: Say <message> -> Reply: <message>
# -----------------------------
{
    my $msg = "Hello Perl Echo";
    print $sock "Say $msg\n";

    my $response = <$sock>;
    ok(defined $response, "Server responded to Say");
    chomp $response if defined $response;

    is($response, "Reply: $msg", "Echo response matches expected text");
}

# -----------------------------
# Test 2: Close -> Reply: Goodbye and connection closes
# -----------------------------
{
    print $sock "Close\n";

    my $response = <$sock>;
    ok(defined $response, "Server responded to Close");
    chomp $response if defined $response;

    is($response, "Reply: Goodbye", "Close command returns 'Reply: Goodbye'");
}

close $sock;

# -----------------------------
# Stop server & cleanup
# -----------------------------
kill 'TERM', $pid;
waitpid($pid, 0);

# -----------------------------
# Verify logs written by Logger
# -----------------------------
my $log_path = File::Spec->catfile($log_dir, $log_file);
ok(-e $log_path, "Log file was created: $log_path");

if (-e $log_path) {
    open my $lf, '<', $log_path or die "Cannot open log file: $!";
    my @lines = <$lf>;
    close $lf;

    my $has_start    = grep { /Echo server starting/ } @lines;
    my $has_connect  = grep { /New connection established/ } @lines;
    my $has_close    = grep { /Connection closed/ } @lines;

    ok($has_start,   "Log contains server start message");
    ok($has_connect, "Log contains audit for new connection");
    ok($has_close,   "Log contains audit for closed connection");
}

# -----------------------------
# Restore original directory
# -----------------------------
chdir $original_dir;

done_testing();
