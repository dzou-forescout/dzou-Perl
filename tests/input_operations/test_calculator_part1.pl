#!/usr/bin/env perl
use strict;
use warnings;
use v5.16;
use Test::More;
use FindBin qw($RealBin);
use lib "$RealBin/../../practices/input_operations";

# Import calculator (main() won't run!)
require_ok('calculator_part1.pl');
Calculator->import();

# Basic arithmetic
is(calculate("2+2"), 4, "Simple addition");
is(calculate("10-5"), 5, "Simple subtraction");
is(calculate("3*4"), 12, "Simple multiplication");
is(calculate("8/2"), 4, "Simple division");

# Decimals
is(calculate("2.5+3.5"), 6, "Decimal addition");
is(calculate("10/4"), 2.5, "Division with decimal result");

# Negatives
is(calculate("-5+3"), -2, "Negative plus positive");
is(calculate("-10/-2"), 5, "Negative divided by negative");

# Whitespace
is(calculate("2 + 2"), 4, "Addition with spaces");
is(calculate("  10  -  5  "), 5, "Multiple spaces");

{
    local *STDOUT;
    open STDOUT, '>', '/dev/null';

    # Division by zero
    is(calculate("5/0"), undef, "Division by zero");

    # Invalid format
    is(calculate("2+3+4"), undef, "Three numbers (not supported)");
    is(calculate("(2+3)"), undef, "Parentheses not supported");

    # Invalid operators
    is(calculate("2^3"), undef, "Invalid operator: caret");
    is(calculate("5%2"), undef, "Invalid operator: modulo");

    # Invalid characters
    is(calculate("2+a"), undef, "Contains letter");
    is(calculate("abc"), undef, "All letters");

    # Missing operands
    is(calculate("5+"), undef, "Missing second operand");
    is(calculate("+5"), undef, "Missing first operand");
}

done_testing();