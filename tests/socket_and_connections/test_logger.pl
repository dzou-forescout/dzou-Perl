#!/usr/bin/env perl
use strict;
use warnings;
use v5.16;

use FindBin qw($RealBin);
use lib "$RealBin/../../practices/socket_and_connections";  # <-- add this

use Logger;

my $log = Logger->new(
    file     => 'test.log',
    dir      => "$RealBin/../../practices/socket_and_connections",  # log into code folder
    level    => 'DEBUG',
    max_size => 1024 * 1024,
);

$log->info('Test',  'Hello from Logger');
$log->debug('Test', 'This is a debug line');
$log->audit('127.0.0.1:12345', 'Audit entry from test');

print "Wrote logs to $RealBin/../../practices/socket_and_connections/test.log\n";
