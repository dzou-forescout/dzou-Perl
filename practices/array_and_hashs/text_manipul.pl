#!/usr/bin/env perl
use strict;
use warnings;

sub read_file {
    my ($file) = @_;
    open my $file_handle, '<', $file or die "Cannot open $file: $!"; # '<" for read, $! for system error
    my @lines = <$file_handle>;
    close $file_handle;
    return @lines;
}

sub reverse_lines {
    my (@lines) = @_;
    return reverse @lines;
}

sub backward_lines {
    my (@lines) = @_;
    my @result;
    for my $line (@lines) {
        chomp $line;                                #remove \n, "Hello\n"  →  "Hello"
        push @result, scalar reverse($line) . "\n"; #reverse $string(scalar context and add \n back
    }
    return @result;
}


# part 2, count all the different chars in the script
sub count_char {
    my @lines = @_;
    my %count;
    for my $line (@lines) {
        my @chars = split //, $line;
        for my $char (@chars) {
            $count{$char}++;
        }
    }
    return %count;
}

sub display_char {
    my ($char) = @_;
    return '\\n' if $char eq "\n";
    return '\\t' if $char eq "\t";
    return 'SPACE' if $char eq ' ';
    return $char;
}

sub do_wc {
    my ($sort, @lines) = @_;
    my %count_map = count_char(@lines);
    my @chars = keys %count_map;
    if ($sort) {
        @chars = sort {
            $count_map{$b} <=> $count_map{$a} # numeric descending
                || $a cmp $b                  # alphabetic ascending
        } @chars;
    }

    for my $char (@chars) {
        my $display = display_char($char);
        print $count_map{$char}, " ", $display, "\n";
    }

}

sub print_help {

    my $script = $0;
    print <<"USAGE";
Usage: $script [options] [-file <path>]

Options:
  -reverse       Print lines in reverse order (last line first).
  -backward      Reverse the characters in each line.
  -wc            Count characters and print "Num Char" for each distinct char.
  -sort          With -wc: sort by count (desc), then by character (asc).
  -file <path>   Use <path> as input file. If omitted, the script reads itself.
  -help          Show this help message and exit.

Examples:
  $script -reverse
  $script -backward
  $script -wc
  $script -wc -sort
  $script -file input.txt -reverse -backward
USAGE
}

sub main {
    my $reverse = 0;
    my $backward = 0;
    my $wc = 0;
    my $sort = 0;
    my $help = 0;
    my $file;

    while (@ARGV) {
        # perl script.pl -reverse -file input.txt --> @ARGV = ('-reverse', '-file', 'input.txt')
        my $arg = shift @ARGV;
        if ($arg eq '-reverse') {
            $reverse = 1;
        }
        elsif ($arg eq '-backward') {
            $backward = 1;
        }
        elsif ($arg eq '-wc') {
            $wc = 1;
        }
        elsif ($arg eq '-sort') {
            $sort = 1;
        }
        elsif ($arg eq '-help') {
            $help = 1;
        }
        elsif ($arg eq '-file') {
            $file = shift @ARGV or die "Missing file path after -file\n";
        }
        else {
            die "Unknown flag '$arg'\n";
        }
    }

    $file ||= $0; # if undef or null , then assign $0, $file = $file || $0;
    my @lines = read_file($file);
    if ($help) {
        print_help;
        print("\n")
    }

    if ($wc) {
        do_wc($sort, @lines);
    }
    if ($reverse) {
        @lines = reverse_lines(@lines);
    }
    if ($backward) {
        @lines = backward_lines(@lines);
    }

    print @lines;
}

main();

