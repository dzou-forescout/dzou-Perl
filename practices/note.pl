
use strict;
use warnings;
use v5.16;

sub test {
    my $scalar = @_;      # Gets COUNT (how many args)
    my ($list) = @_;      # Gets FIRST VALUE
    
    print "Scalar: $scalar\n";
    print "List: $list\n";
}

sub test_eval{
    say "enter calculation: ";
    my $input = <STDIN>;
    chomp $input;
    my $result = eval $input;
    if ($@) {
        say "Error: $@";
    }
    say "Result: $result";
}

test("hello", "world");
test_eval();