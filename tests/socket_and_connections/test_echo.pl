#!/usr/bin/env perl
use strict;
use warnings;
use v5.16;

use Test::More;
use IO::Socket::SSL qw(SSL_VERIFY_NONE);
use File::Temp qw(tempdir);
use File::Spec;
use File::Basename qw(dirname);
use Cwd qw(getcwd chdir);
use FindBin qw($RealBin);

# -----------------------------
# Paths (adjust if needed)
# -----------------------------
my $server_script = "$RealBin/../../practices/socket_and_connections/echop.pl";

unless (-f $server_script) {
    plan skip_all => "Cannot find echo server script at $server_script";
}

my $server_dir = dirname($server_script);
my $cert_path  = File::Spec->catfile($server_dir, 'server.crt');
my $key_path   = File::Spec->catfile($server_dir, 'server.key');

unless (-f $cert_path && -f $key_path) {
    plan skip_all =>
        "Cannot find server.crt or server.key in $server_dir (expected SSL cert/key)";
}

# -----------------------------
# Test setup: temp dir + config
# -----------------------------
my $original_dir = getcwd();
my $tmp_dir      = tempdir( CLEANUP => 1 );
chdir $tmp_dir or die "Cannot chdir to $tmp_dir: $!";

my $port     = 6778;          # can be randomized if needed
my $log_file = 'test-echo.log';
my $log_dir  = $tmp_dir;

# Write a local inline.cnfg used by the server
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

use_ssl=1
ssl_cert_file=$cert_path
ssl_key_file=$key_path
ssl_verify_mode=NONE
CFG
    close $cfg;
}

# -----------------------------
# Start server in background
# -----------------------------
my $pid = fork();
die "Cannot fork: $!" unless defined $pid;

if ($pid == 0) {
    # Child: run server from the temp dir (so it picks up inline.cnfg here)
    exec $^X, $server_script
        or die "Failed to exec echo server: $!";
    exit 0;
}

# Parent: give server a moment to start
sleep 1;

# -----------------------------
# Connect to server via SSL
# -----------------------------
my $sock = IO::Socket::SSL->new(
    PeerHost        => '127.0.0.1',
    PeerPort        => $port,
    Proto           => 'tcp',
    SSL_verify_mode => SSL_VERIFY_NONE,  # don't verify self-signed cert
);

ok($sock, "Client connected to SSL echo server on port $port")
    or BAIL_OUT("Cannot connect to server: $IO::Socket::SSL::SSL_ERROR");

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

    my $has_start = grep {
        /Server\s*\|\s*INFO\s*\|/i   # category + level
            && /echo server/i          # message contains "echo server"
    } @lines;

    ok($has_start, "Log contains server start message");
}

# -----------------------------
# Restore original directory
# -----------------------------
chdir $original_dir;

done_testing();
