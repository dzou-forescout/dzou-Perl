#!/usr/bin/env perl
use strict;
use warnings;
use v5.16;
use Test::More;
use FindBin qw($RealBin);
use lib "$RealBin/../../practices/input_operations";

require_ok('calculator_part2_no_eval.pl');
Calculator->import();

##########
## Helper function to test successful calculations
##########
sub test_success {
    my ($expr, $expected, $description) = @_;
    my ($ok, $result, $error) = evaluate_infix($expr);
    ok($ok, "$description - should succeed");
    is($result, $expected, "$description - result");
}

##########
## Helper function to test error cases
##########
sub test_error {
    my ($expr, $error_pattern, $description) = @_;
    my ($ok, $result, $error) = evaluate_infix($expr);
    ok(!$ok, "$description - should fail");
    like($error, qr/$error_pattern/i, "$description - error message");
}

##########
## Basic Arithmetic Tests
##########

# Addition
test_success("2+2", 4, "Simple addition");
test_success("10+5", 15, "Addition: 10+5");
test_success("0+0", 0, "Addition with zeros");
test_success("100+200", 300, "Large number addition");

# Subtraction
test_success("10-5", 5, "Simple subtraction");
test_success("5-10", -5, "Subtraction resulting in negative");
test_success("0-5", -5, "Subtracting from zero");
test_success("100-100", 0, "Subtraction resulting in zero");

# Multiplication
test_success("3*4", 12, "Simple multiplication");
test_success("5*0", 0, "Multiplication by zero");
test_success("0*5", 0, "Zero times number");
test_success("10*10", 100, "Multiplication: 10*10");

# Division
test_success("8/2", 4, "Simple division");
test_success("10/4", 2.5, "Division with decimal result");
test_success("100/10", 10, "Division: 100/10");
test_success("1/2", 0.5, "Division resulting in 0.5");

##########
## Order of Operations (PEMDAS) Tests
##########

test_success("2+3*4", 14, "Multiplication before addition");
test_success("10-2*3", 4, "Multiplication before subtraction");
test_success("2*3+4*5", 26, "Multiple multiplications");
test_success("20/4+3*2", 11, "Division and multiplication before addition");
test_success("100-20/4", 95, "Division before subtraction");
test_success("2+3*4-5/2", 11.5, "All four operations with precedence");

##########
## Parentheses Tests
##########

# Simple parentheses
test_success("(2+3)*4", 20, "Parentheses override order");
test_success("2*(3+4)", 14, "Parentheses at end");
test_success("(10-5)*2", 10, "Subtraction in parentheses");
test_success("(8/2)+3", 7, "Division in parentheses");

# Nested parentheses
test_success("((2+3)*4)", 20, "Double nested parentheses");
test_success("((2+3)*4)/2", 10, "Nested parentheses with division");
test_success("2*((3+4)*5)", 70, "Nested parentheses in middle");
test_success("(((2+3)))", 5, "Deeply nested parentheses");

# Multiple parentheses
test_success("(2+3)*(4+5)", 45, "Two separate parentheses");
test_success("(10-5)+(20-15)", 10, "Multiple parentheses with addition");
test_success("(2+3)*(4-1)/(6+3)", 1.666666666666667, "Multiple operations with parentheses");

##########
## Complex Expressions
##########

test_success("2+3*4-5/2+6", 17.5, "Long expression with precedence");
test_success("((2+3)*4-5)/3", 5, "Complex nested expression");
test_success("10*(2+3)/(4-2)", 25, "Multiple operators with parentheses");
test_success("100-50+20*2-10/2", 85, "Long mixed expression");

##########
## Decimal Number Tests
##########

test_success("2.5+3.5", 6, "Decimal addition");
test_success("10.5-5.5", 5, "Decimal subtraction");
test_success("2.5*2", 5, "Decimal multiplication");
test_success("7.5/2.5", 3, "Decimal division");
test_success("0.1+0.2", 0.3, "Small decimal addition");
test_success("1.5*2.5", 3.75, "Both decimals multiplication");
test_success("(2.5+3.5)*2", 12, "Decimals in parentheses");

##########
## Negative Number Tests
##########

# Unary minus at start
test_success("-5", -5, "Negative number alone");
test_success("-5+3", -2, "Negative at start with addition");
test_success("-5-3", -8, "Negative at start with subtraction");
test_success("-5*2", -10, "Negative at start with multiplication");
test_success("-10/2", -5, "Negative at start with division");

# Unary minus after operator
test_success("5+-3", 2, "Plus then negative");
test_success("5--3", 8, "Minus then negative (double negative)");
test_success("5*-3", -15, "Multiply then negative");
test_success("10/-2", -5, "Divide then negative");

# Unary minus with parentheses
test_success("-(2+3)", -5, "Negative of parenthesized expression");
test_success("-(5-2)", -3, "Negative of subtraction");
test_success("2*-(3+4)", -14, "Negative parentheses in expression");
test_success("-(2+3)*4", -20, "Negative parentheses at start");

# Multiple negatives
test_success("-5+-3", -8, "Two negatives with plus");
test_success("-5--3", -2, "Two negatives with minus");
test_success("-5*-2", 10, "Two negatives with multiply");
test_success("-10/-2", 5, "Two negatives with divide");

##########
## Whitespace Handling Tests
##########

test_success("2 + 2", 4, "Addition with spaces");
test_success("  10  -  5  ", 5, "Multiple spaces");
test_success("( 2 + 3 ) * 4", 20, "Spaces with parentheses");
test_success("  5   *   3  ", 15, "Spaces around multiplication");

##########
## Edge Cases
##########

test_success("0", 0, "Zero alone");
test_success("1", 1, "One alone");
test_success("0+0", 0, "Zero plus zero");
test_success("0*0", 0, "Zero times zero");
test_success("0-0", 0, "Zero minus zero");
test_success("1*1", 1, "One times one");
test_success("1/1", 1, "One divided by one");
test_success("+5", 5, "Unary plus");
test_success("++5", 5, "Double unary plus");
test_success("+(2+3)", 5, "Unary plus before parentheses");

##########
## Error Handling Tests
##########

# Division by zero
test_error("5/0", "division by zero", "Division by zero");
test_error("10/0", "division by zero", "Another division by zero");
test_error("(2+3)/0", "division by zero", "Division by zero in expression");
test_error("0/0", "division by zero", "Zero divided by zero");

# Empty expression
test_error("", "empty", "Empty string");
test_error("   ", "empty", "Only whitespace");

# Mismatched parentheses
test_error("(2+3", "mismatched", "Missing closing parenthesis");
test_error("2+3)", "mismatched", "Missing opening parenthesis");
test_error("((2+3)", "mismatched", "One missing closing");
test_error("(2+3))", "mismatched", "Extra closing parenthesis");
test_error(")2+3(", "mismatched", "Reversed parentheses");
test_error("((2+3", "mismatched", "Two missing closing");

# Invalid characters
test_error("2+a", "invalid char", "Contains letter");
test_error("abc", "invalid char", "All letters");
test_error("2^3", "invalid char", "Invalid operator: caret");
test_error("5%2", "invalid char", "Invalid operator: modulo");
test_error("5&2", "invalid char", "Invalid operator: ampersand");
test_error("2#3", "invalid char", "Invalid character: hash");

# Operator errors
test_error("2++3", "cannot follow", "Double operator (plus-plus)");
test_error("2**3", "cannot follow", "Double operator (star-star)");
test_error("2/+3", "cannot follow", "Slash followed by plus");
test_error("+", "malformed|dangling", "Operator only: plus");
test_error("*", "invalid char|cannot follow", "Operator only: star");
test_error("/", "invalid char|cannot follow", "Operator only: slash");

# Missing operands
test_error("2+", "malformed|dangling", "Missing second operand");
test_error("*5", "invalid char|cannot follow", "Missing first operand");
test_error("2+()", "malformed|not enough", "Empty parentheses");

# Dangling unary minus
test_error("-", "malformed|dangling", "Dangling unary minus alone");
test_error("2+-", "malformed|dangling", "Dangling unary minus at end");

# Invalid number format
test_error("2.5.3", "invalid number format", "Two decimal points");
test_error("1.2.3+4", "invalid number format", "Multiple decimal points in number");

# Malformed expressions
test_error("2 3", "malformed|cannot follow", "Two numbers with space");
test_error("()", "malformed|not enough", "Empty parentheses");
test_error("2(3)", "malformed|cannot follow", "Number followed by parentheses");

##########
## Additional Complex Tests
##########

# Long expressions
test_success("1+2+3+4+5", 15, "Sum of 1 through 5");
test_success("10-1-2-3", 4, "Sequential subtractions");
test_success("2*3*4*5", 120, "Sequential multiplications");
test_success("1000/10/10", 10, "Sequential divisions");

# Mixed parentheses and operators
test_success("(1+2)*(3+4)*(5+6)", 231, "Multiple parenthesized additions");
test_success("((1+2)*3+4)*5", 65, "Nested with multiple operations");
test_success("(10-(5-2))*3", 21, "Nested subtraction");

# Stress tests
test_success("((((1+1))))", 2, "Many nested parentheses");
test_success("1+1+1+1+1+1+1+1+1+1", 10, "Many additions");
test_success("(1+(2+(3+(4+5))))", 15, "Right-nested parentheses");

done_testing();