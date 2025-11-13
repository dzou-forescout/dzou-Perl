#!/usr/bin/env perl
use strict;
use warnings;
use v5.16;
use Test::More;
use FindBin qw($RealBin);
use lib "$RealBin/../../practices/input_operations";

# Import calculator (main() won't run!)
require_ok('calculator_part2.pl');
Calculator->import();

# Test simple calculations
is(calculate("2+2"), 4, "Simple addition");
is(calculate("10-5"), 5, "Simple subtraction");
is(calculate("3*4"), 12, "Simple multiplication");
is(calculate("8/2"), 4, "Simple division");

# Test order of operations
is(calculate("2+3*4"), 14, "Order of operations");
is(calculate("(2+3)*4"), 20, "Parentheses first");

# Test complex expressions
is(calculate("10/4"), 2.5, "Decimal result");
is(calculate("2.5+3.5"), 6, "Decimal input");

# Test negative numbers
is(calculate("-5+3"), -2, "Negative number");
is(calculate("10+-5"), 5, "Adding negative number");

# Test more complex cases
is(calculate("((2+3)*4)/2"), 10, "Nested parentheses");
is(calculate("2+3*4-5/2"), 11.5, "Multiple operations");
is(calculate("100-50+20*2-10/2"), 85, "Long expression");

# Test validation functions
ok(is_valid_expression("2+2"), "Valid expression");
ok(is_valid_expression("(2+3)*4"), "Valid with parentheses");
ok(!is_valid_expression("2+a"), "Invalid: contains letter");
ok(!is_valid_expression("2^3"), "Invalid: contains caret");
ok(!is_valid_expression(""), "Invalid: empty string");

# Test parentheses balance
ok(has_balanced_parentheses("(2+3)"), "Balanced parentheses");
ok(has_balanced_parentheses("((2+3)*4)"), "Nested balanced");
ok(!has_balanced_parentheses("(2+3"), "Unbalanced: missing closing");
ok(!has_balanced_parentheses("2+3)"), "Unbalanced: missing opening");

# Test error handling (suppress output)
{
    local *STDOUT;
    open STDOUT, '>', '/dev/null';

    is(calculate("2+a"), undef, "Invalid character error");
    is(calculate("(2+3"), undef, "Unbalanced parentheses error");
    is(calculate("5/0"), undef, "Division by zero error");
    is(calculate("2^3"), undef, "Invalid operator error");
    is(calculate(""), undef, "Empty input error");
}

done_testing();