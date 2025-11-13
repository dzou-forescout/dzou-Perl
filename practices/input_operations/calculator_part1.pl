#!/usr/bin/env perl
use strict;
use warnings;
use v5.16;

package Calculator;
use base 'Exporter';
our @EXPORT = qw(calculate);

##########
## @brief Performs arithmetic calculation on input expression
## @param $expression String containing the arithmetic expression (e.g., "5 + 2")
## @return Calculated result or undef if invalid expression
## @exception Returns undef for invalid expressions or division by zero
##########
sub calculate {
    my ($expression) = @_;
    
    # Remove all whitespace to make parsing easier
    $expression =~ s/\s+//g; # =~ apply regex to variable
    
    # Match pattern: number operator number
    # Supports integers and decimals, operators: +, -, *, /
    if ($expression =~ /^(-?\d+\.?\d*)([\+\-\*\/])(-?\d+\.?\d*)$/) {
        my ($num1, $operator, $num2) = ($1, $2, $3);
        my $result = eval $expression;
        if ($@) {   # check for runtime errors
            say ">> Error: Invalid calculation - $@";
            return undef;
        }
        return $result
    }
    else {
        say ">> Error: Invalid expression format. Use: N operator N";
        return undef;
    }
}

##########
## @brief Main entry point for the calculator program
## Reads user input and performs arithmetic calculations
## @return Exit code
##########
sub main {
    say ">> Perl version: $^V";
    say ">> Perl calculator.pl";
    
    while (1) {
        print ">> Enter simple exercise with 2 numbers and an operator (+ - * /), ie: 5 * 2: ";
        my $input = <STDIN>;
        
        # Exit on EOF or empty input
        last unless defined $input;
        chomp $input;
        next if $input =~ /^\s*$/;
        
        # Calculate and display result
        my $result = calculate($input);
        if (defined $result) {
            say ">> result: $result";
        }
    }
    
    return 0;
}

main() unless caller();
1;
