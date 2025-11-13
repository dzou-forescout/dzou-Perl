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
        my($ok, $result, $error) = evaluate_infix($input);
        if($ok) {
            say ">> result: $result";
        } else {
            say ">> Error: $error";
        }
    }

    return 0;
}

##########
## @brief Evaluates an infix mathematical expression with operator precedence
## Parses and evaluates expressions containing:
## - Numbers (integers and decimals)
## - Operators (+, -, *, /)
## - Parentheses for grouping
## - Unary minus for negative numbers
## Uses two-stack algorithm: one for operands, one for operators
## @param $s String containing the infix expression
## @return ($ok, $result, $error) where:
##         $ok = 1 if successful, 0 if error
##         $result = calculated result (if $ok = 1)
##         $error = error message (if $ok = 0)
##########
sub evaluate_infix{
    my ($s) = @_;

    # Remove all whitespace for easier parsing
    $s =~ s/\s+//g;
    return (0, undef, "empty expression") if $s eq '';

    # Stack for numbers/operands
    my @numbers;

    # Stack for operators
    my @ops;

    my $len  = length($s);
    my $i    = 0;

    # Track what the previous token was for parsing context
    # Possible values: START, NUM, OP, LPAREN, RPAREN
    my $prev = 'START';

    # Main parsing loop - process each character
    while($i < $len){
        my $c = substr($s, $i, 1);

        # If current character is a digit or decimal point, read a number
        if ($c =~ /[\d\.]/) {
            my ($number, $j, $err) = _read_number($s, $i, $len);
            return (0, undef, $err) unless defined $number;
            push @numbers, $number + 0;
            $i = $j;
            $prev = 'NUM';
            next;
        }

        # Handle opening parenthesis
        if($c eq '('){
            push @ops, $c;
            $i++;
            $prev = 'LPAREN';
            next;
        }

        # Handle unary plus or minus (when it appears at start, after operator, or after '(')
        if(($c eq '+' || $c eq '-') && ($prev eq 'START' || $prev eq 'OP' || $prev eq 'LPAREN')){
            # Unary plus - just skip it
            if($c eq '+'){
                $i++;
                next;
            }

            # Unary minus - handle negative numbers
            if($i + 1 < $len && substr($s, $i + 1, 1) =~ /[\d\.]/){
                # Next character is a digit, read the number and negate it
                my ($number, $j, $err) = _read_number($s, $i + 1, $len);
                return (0, undef, $err) unless defined $number;
                push @numbers, -$number;
                $i = $j;
                $prev = 'NUM';
                next;
            } elsif($i + 1 < $len && substr($s, $i + 1, 1) eq '('){
                # Unary minus before parenthesis: treat as (0 - expr)
                push @numbers, -0.0;
                push @ops, '-';
                $i++;
                $prev = 'OP';
                next;
            } else {
                return (0, undef, "dangling unary '-' at pos $i");
            }
        }

        # Handle closing parenthesis
        if($c eq ')'){
            # Check if we have a matching opening parenthesis
            if(!(@ops)){ return (0, undef, "mismatched ')' at pos $i") }

            # Apply all operators until we find the matching '('
            while(@ops && $ops[-1] ne '('){
                my($ok, $error) = _apply_top(\@numbers, \@ops);
                return (0, undef, $error) unless $ok;
            }

            # Check if we found the opening parenthesis
            return (0, undef, "mismatched ')' at pos $i") unless (@ops && $ops[-1] eq '(');

            # Remove the '(' from operator stack
            pop @ops;
            $i++;
            $prev = 'RPAREN';
            next;
        }

        # Handle binary operators (+, -, *, /)
        if(_is_op($c)){
            # Operator must follow a number or closing parenthesis
            return (0, undef, "operator '$c' cannot follow $prev at pos $i")
                unless ($prev eq 'NUM' || $prev eq 'RPAREN');

            # Apply operators with higher or equal precedence
            while(@ops && $ops[-1] ne '(' && _prec($ops[-1]) >= _prec($c)){
                my($ok, $error) = _apply_top(\@numbers, \@ops);
                return (0, undef, $error) unless $ok;
            }

            # Push current operator onto stack
            push @ops, $c;
            $i++;
            $prev = 'OP';
            next;
        }

        # Invalid character encountered
        return (0, undef, "invalid char '$c' at pos $i");
    }

    # Apply remaining operators after parsing all input
    while (@ops) {
        my $op = $ops[-1];
        return (0, undef, "mismatched '('") if $op eq '(';
        my ($ok, $err) = _apply_top(\@numbers, \@ops);
        return (0, undef, $err) unless $ok;
    }

    # Should have exactly one number left (the final result)
    return (0, undef, "malformed expression") unless @numbers == 1;
    return (1, $numbers[0], undef);
}


##########
## @brief Checks if a character is a binary operator
## @param $_[0] Character to check
## @return 1 if character is +, -, *, or /, 0 otherwise
##########
sub _is_op { $_[0] eq '+' || $_[0] eq '-' || $_[0] eq '*' || $_[0] eq '/' }

##########
## @brief Returns operator precedence for ordering operations
## Higher precedence operators are evaluated first
## @param $_[0] Operator character (+, -, *, /)
## @return 1 for addition/subtraction, 2 for multiplication/division
##########
sub _prec  { ($_[0] eq '+' || $_[0] eq '-') ? 1 : 2 }

##########
## @brief Reads a number (integer or decimal) from the expression string
## Parses digits and at most one decimal point
## @param $s The full expression string
## @param $i Starting position in the string
## @param $len Total length of the string
## @return ($number, $next_pos, $error) where:
##         $number = parsed number (or undef if error)
##         $next_pos = position after the number
##         $error = error message (or undef if success)
##########
sub _read_number{
    my ($s, $i, $len) = @_;
    my $j = $i;
    my $dot = 0;  # Track if we've seen a decimal point

    # Read digits and decimal point
    while ($j < $len) {
        my $ch = substr($s, $j, 1);
        if($ch eq '.'){
            # Only one decimal point allowed
            if($dot){
                return (undef, undef, "invalid number format");
            }
            $dot = 1;
            $j++;
        } elsif ($ch =~ /\d/) {
            # Regular digit
            $j++;
        } else {
            # Not a digit or decimal point, stop reading
            last;
        }
    }

    # Extract the number substring and convert to numeric
    my $num = substr($s, $i, $j - $i);
    return ($num+0, $j, undef);
}

##########
## @brief Applies the top operator from the operator stack to the top two numbers
## Pops two numbers and one operator, performs the operation, pushes result
## Handles division by zero error
## @param $numbers Reference to the numbers stack (array)
## @param $ops Reference to the operators stack (array)
## @return ($ok, $error) where:
##         $ok = 1 if successful, 0 if error
##         $error = error message (or undef if success)
##########
sub _apply_top{
    my($numbers, $ops) = @_;

    # Need at least two operands
    return (0, "not enough operands") if @$numbers < 2;

    # Pop two operands (order matters: b is on top, a is below)
    my $b = pop @$numbers;
    my $a = pop @$numbers;
    my $op = pop @$ops;

    my $curr;

    # Perform the operation
    # BUG FIX: Changed = to eq for proper string comparison
    if($op eq '+'){       # ✅ FIXED: was $op = '+' (assignment)
        $curr = $a + $b;
    } elsif($op eq '-'){
        $curr = $a - $b;
    } elsif($op eq '*'){
        $curr = $a * $b;
    } elsif($op eq '/'){
        # Check for division by zero
        if($b == 0){
            return (0, "division by zero");
        }
        $curr = $a / $b;
    } else {
        return (0, "unknown operator '$op'");
    }

    # Push result back onto numbers stack
    push @$numbers, $curr;
    return (1, undef);
}

main();