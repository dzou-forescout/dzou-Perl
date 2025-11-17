#!/usr/bin/env perl
use strict;
use warnings;
use v5.16;
use Test::More;
use FindBin qw($RealBin);
use File::Temp qw(tempfile);
use Capture::Tiny qw(capture);

# Create test input file
my ($fh, $test_file) = tempfile(UNLINK => 1);
print $fh "Hello\n";
print $fh "World\n";
print $fh "Test\n";
close $fh;

# Path to the script
my $script = "$RealBin/../../practices/array_and_hashs/text_manipul.pl";
die "Cannot find script at: $script\n" unless -f $script;
print "✓ Found script at: $script\n";

# Test 1: -help flag
{
    my ($stdout, $stderr, $exit) = capture {
        system($^X, $script, '-help');
    };
    like($stdout, qr/Usage:/, "Help message displays usage");
    like($stdout, qr/-reverse/, "Help contains -reverse option");
    like($stdout, qr/-backward/, "Help contains -backward option");
    like($stdout, qr/-wc/, "Help contains -wc option");
}

# Test 2: -reverse flag (reverse line order)
{
    my ($stdout, $stderr, $exit) = capture {
        system($^X, $script, '-reverse', '-file', $test_file);
    };
    my @lines = split /\n/, $stdout;
    is($lines[0], "Test", "First line is 'Test' when reversed");
    is($lines[1], "World", "Second line is 'World' when reversed");
    is($lines[2], "Hello", "Third line is 'Hello' when reversed");
}

# Test 3: -backward flag (reverse characters in each line)
{
    my ($stdout, $stderr, $exit) = capture {
        system($^X, $script, '-backward', '-file', $test_file);
    };
    my @lines = split /\n/, $stdout;
    is($lines[0], "olleH", "First line characters reversed");
    is($lines[1], "dlroW", "Second line characters reversed");
    is($lines[2], "tseT", "Third line characters reversed");
}

# Test 4: -reverse and -backward combined
{
    my ($stdout, $stderr, $exit) = capture {
        system($^X, $script, '-reverse', '-backward', '-file', $test_file);
    };
    my @lines = split /\n/, $stdout;
    is($lines[0], "tseT", "Combined: First line is 'tseT'");
    is($lines[1], "dlroW", "Combined: Second line is 'dlroW'");
    is($lines[2], "olleH", "Combined: Third line is 'olleH'");
}

# Test 5: -wc flag (character count)
{
    my ($stdout, $stderr, $exit) = capture {
        system($^X, $script, '-wc', '-file', $test_file);
    };
    like($stdout, qr/\d+ \S+/, "Character count output format");
    like($stdout, qr/\d+ H/, "Contains count for 'H'");
    like($stdout, qr/\d+ e/, "Contains count for 'e'");
    like($stdout, qr/\d+ l/, "Contains count for 'l'");
    like($stdout, qr/\d+ o/, "Contains count for 'o'");
}

# Test 6: -wc -sort flags
{
    my ($stdout, $stderr, $exit) = capture {
        system($^X, $script, '-wc', '-sort', '-file', $test_file);
    };
    my @lines = split /\n/, $stdout;
    # Check that output is sorted
    ok(scalar(@lines) > 0, "Sort produces output");
    like($lines[0], qr/^\d+ \S+$/, "Sorted output has correct format");
}

# Test 7: Create a test file with known character counts
{
    my ($fh2, $test_file2) = tempfile(UNLINK => 1);
    print $fh2 "aaaa\n";
    print $fh2 "bb\n";
    print $fh2 "c\n";
    close $fh2;

    my ($stdout, $stderr, $exit) = capture {
        system($^X, $script, '-wc', '-sort', '-file', $test_file2);
    };
    my @lines = split /\n/, $stdout;
    # 'a' appears 3 times, should be first
    like($lines[0], qr/^4 a$/, "Most frequent character 'a' appears first");
}

# Test 8: Default behavior (no flags, reads self)
{
    my ($stdout, $stderr, $exit) = capture {
        system($^X, $script, '-file', $test_file);
    };
    like($stdout, qr/Hello/, "Default: prints file content");
    like($stdout, qr/World/, "Default: contains all lines");
    like($stdout, qr/Test/, "Default: file printed as-is");
}

# Test 9: Error handling - missing file path after -file
{
    my ($stdout, $stderr, $exit) = capture {
        system($^X, $script, '-file');
    };
    like($stderr, qr/Missing file path/, "Error on missing file path");
}

# Test 10: Error handling - unknown flag
{
    my ($stdout, $stderr, $exit) = capture {
        system($^X, $script, '-unknown');
    };
    like($stderr, qr/Unknown flag/, "Error on unknown flag");
}

# Test 11: Error handling - non-existent file
{
    my ($stdout, $stderr, $exit) = capture {
        system($^X, $script, '-file', '/nonexistent/file.txt');
    };
    like($stderr, qr/Cannot open/, "Error on non-existent file");
}

# Test 12: Special characters display in -wc
{
    my ($fh3, $test_file3) = tempfile(UNLINK => 1);
    print $fh3 "a b\tc\n";
    close $fh3;

    my ($stdout, $stderr, $exit) = capture {
        system($^X, $script, '-wc', '-file', $test_file3);
    };
    like($stdout, qr/SPACE/, "Space character displays as SPACE");
    like($stdout, qr/\\n/, "Newline displays as \\n");
    like($stdout, qr/\\t/, "Tab displays as \\t");
}

# Test 13: Multiple flags with help
{
    my ($stdout, $stderr, $exit) = capture {
        system($^X, $script, '-help', '-reverse', '-file', $test_file);
    };
    like($stdout, qr/Usage:/, "Help displays even with other flags");
}

# Test 14: -wc without -sort (unsorted output)
{
    my ($fh4, $test_file4) = tempfile(UNLINK => 1);
    print $fh4 "abc\n";
    close $fh4;

    my ($stdout, $stderr, $exit) = capture {
        system($^X, $script, '-wc', '-file', $test_file4);
    };
    # Output should contain all characters
    like($stdout, qr/1 a/, "Contains 'a'");
    like($stdout, qr/1 b/, "Contains 'b'");
    like($stdout, qr/1 c/, "Contains 'c'");
}

# Test 15: Empty file handling
{
    my ($fh5, $test_file5) = tempfile(UNLINK => 1);
    close $fh5;

    my ($stdout, $stderr, $exit) = capture {
        system($^X, $script, '-file', $test_file5);
    };
    is($stdout, "", "Empty file produces no output");
}

# Test 16: File with single line
{
    my ($fh6, $test_file6) = tempfile(UNLINK => 1);
    print $fh6 "SingleLine\n";
    close $fh6;

    my ($stdout, $stderr, $exit) = capture {
        system($^X, $script, '-reverse', '-file', $test_file6);
    };
    like($stdout, qr/SingleLine/, "Single line handled correctly");
}

# Test 17: Backward with special characters
{
    my ($fh7, $test_file7) = tempfile(UNLINK => 1);
    print $fh7 "123!@#\n";
    close $fh7;

    my ($stdout, $stderr, $exit) = capture {
        system($^X, $script, '-backward', '-file', $test_file7);
    };
    like($stdout, qr/#@!321/, "Special characters reversed correctly");
}

done_testing();