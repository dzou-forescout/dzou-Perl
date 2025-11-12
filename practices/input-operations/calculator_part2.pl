#!/usr/bin/env perl
use strict;
use warnings;
use v5.16;


##########
## @brief Main entry point for the calculator program
## Reads user input and performs arithmetic calculations
## @return Exit code
##########
sub main {
    say ">> Perl version: $^V";
    say ">> Perl calculator.pl";
    
    while (1) {
        print ">> Enter multiple operations, brackets, order of operations: ";
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

##########
## @brief Validates and evaluates a mathematical expression
## Supports multiple numbers, operators (+, -, *, /), and parentheses
## Follows standard order of operations (PEMDAS/BODMAS)
## @param $expression String containing the arithmetic expression
## @return Calculated result or undef if invalid expression
##########
sub calculate {
    my ($expression) = @_;
    
    # Validate the expression contains only allowed characters
    if (!is_valid_expression($expression)) {
        say ">> Error: Invalid characters. Use only: numbers, +, -, *, /, (, )";
        return undef;
    }
    
    # Check for balanced parentheses
    if (!has_balanced_parentheses($expression)) {
        say ">> Error: Unbalanced parentheses";
        return undef;
    }
    
    # Evaluate the expression
    my $result = eval_expression($expression);
    
    return $result;
}

##########
## @brief Validates that expression contains only allowed characters
## @param $expression String to validate
## @return 1 if valid, 0 if invalid
##########
sub is_valid_expression {
    my ($expression) = @_;
    
    # Remove all whitespace for checking
    my $cleaned = $expression;
    $cleaned =~ s/\s+//g;
    
    # Check if empty after removing whitespace
    return 0 if $cleaned eq '';
    
    # Allow only: digits, decimal points, operators, parentheses, minus sign
    # Pattern: numbers (including decimals and negatives), operators, and parentheses
    return $cleaned =~ /^[\d\.\+\-\*\/\(\)]+$/;
}

##########
## @brief Checks if parentheses are balanced in the expression
## @param $expression String to check
## @return 1 if balanced, 0 if unbalanced
##########
sub has_balanced_parentheses {
    my ($expression) = @_;
    
    my $count = 0;
    
    # Count opening and closing parentheses
    foreach my $char (split //, $expression) {
        if ($char eq '(') {
            $count++;
        }
        elsif ($char eq ')') {
            $count--;
            # If count goes negative, we have more ) than (
            return 0 if $count < 0;
        }
    }
    
    # Count should be zero if balanced
    return $count == 0;
}

##########
## @brief Evaluates a mathematical expression safely
## Uses Perl's eval in a controlled manner after validation
## @param $expression String containing validated expression
## @return Result of calculation or undef on error
##########
sub eval_expression {
    my ($expression) = @_;
    
    # Remove all whitespace for evaluation
    $expression =~ s/\s+//g;
    
    # Use eval to calculate (safe after validation)
    my $result = eval $expression;
    
    # Check for errors
    if ($@) { # NOTE: $@ is a special variable that contains error messages from eval
        # Parse the error message
        if ($@ =~ /division.*by zero/i) {
            say ">> Error: Division by zero";
        }
        elsif ($@ =~ /syntax error/i) {
            say ">> Error: Invalid syntax in expression";
        }
        else {
            say ">> Error: Cannot evaluate expression";
        }
        return undef;
    }
    
    return $result;
}

main();
