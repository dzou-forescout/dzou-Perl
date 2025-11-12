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

sub evaluate_infix{
    my ($s) = @_;
    $s =~ s/\s+//g;
    return (0, undef, "empty expression") if $s eq '';

    my @numbers;
    my @ops;

    my $len  = length($s);
    my $i    = 0;
    my $prev = 'START';

    while($i < $len){
        my $c = substr($s, $i, 1);

        if ($c =~ /[\d\.]/) {
            my ($number, $j, $err) = _read_number($s, $i, $len);
            return (0, undef, $err) unless defined $number;
            push @numbers, $number + 0;
            $i = $j;
            $prev = 'NUM';
            next;
        }

        if($c eq '('){
            push @ops, $c;
            $i++;
            $prev = 'LPAREN';
            next;
        }

        if(($c eq '+' || $c eq '-') && ($prev eq 'START' || $prev eq 'OP' || $prev eq 'LPAREN')){
            if($c eq '+'){
                $i++;
                next;
            }
            if($i + 1 < $len && substr($s, $i + 1, 1) =~ /[\d\.]/){
                my ($number, $j, $err) = _read_number($s, $i + 1, $len);
                return (0, undef, $err) unless defined $number;
                push @numbers, -$number;
                $i = $j;
                $prev = 'NUM';
                next;
            } elsif($i + 1 < $len && substr($s, $i + 1, 1) eq '('){
                push @numbers, -0.0;
                push @ops, '-';
                $i++;
                $prev = 'OP';
                next;
            } else {
                return (0, undef, "dangling unary '-' at pos $i");
            }            
        }

        if($c eq ')'){
            if(!(@ops)){ return (0, undef, "mismatched ')' at pos $i") }
            while(@ops && $ops[-1] ne '('){
                my($ok, $error) = _apply_top(\@numbers, \@ops);
                return (0, undef, $error) unless $ok;
            }
            return (0, undef, "mismatched ')' at pos $i") unless (@ops && $ops[-1] eq '(');
            pop @ops;
            $i++;
            $prev = 'RPAREN';
            next;
        }

        if(_is_op($c)){
            return (0, undef, "operator '$c' cannot follow $prev at pos $i")
                unless ($prev eq 'NUM' || $prev eq 'RPAREN');
            while(@ops && $ops[-1] ne '(' && _prec($ops[-1] >= _prec($c))){
                my($ok, $error) = _apply_top(\@numbers, \@ops);
                return (0, undef, $error) unless $ok;
            }
            push @ops, $c;
            $i++;
            $prev = 'OP';
            next;
        }

        return (0, undef, "invalid char '$c' at pos $i");
    }
    while (@ops) {
        my $op = $ops[-1];
        return (0, undef, "mismatched '('") if $op eq '(';
        my ($ok, $err) = _apply_top(\@numbers, \@ops);
        return (0, undef, $err) unless $ok;
    }

    return (0, undef, "malformed expression") unless @numbers == 1;
    return (1, $numbers[0], undef);

}


sub _is_op { $_[0] eq '+' || $_[0] eq '-' || $_[0] eq '*' || $_[0] eq '/' }
sub _prec  { ($_[0] eq '+' || $_[0] eq '-') ? 1 : 2 }

sub _read_number{
    my ($s, $i, $len) = @_;
    my $j = $i;
    my $dot = 0;

    while ($j < $len) {
        my $ch = substr($s, $j, 1);
        if($ch eq '.'){
            if($dot){
                return (undef, undef, "invalid number format");
            }
            $dot = 1;
        } elsif ($ch =~ /\d/) {
            $j++;
        }else{
            last;
        }
    }
    # return (undef, $i, "number expected at pos $i") if $j == $i;
    my $num = substr($s, $i, $j - $i);
    return ($num+0, $j, undef);
}

sub _apply_top{
    my($numbers, $ops) = @_;
    return (0, "not enough operands") if @$numbers < 2;
    my $b = pop @$numbers;
    my $a = pop @$numbers;
    my $op = pop @$ops;

    my $curr;

    if($op = '+'){
        $curr = $a + $b;
    } elsif($op eq '-'){
        $curr = $a - $b;
    } elsif($op eq '*'){
        $curr = $a * $b;
    } elsif($op eq '/'){
        if($b == 0){
            return (0, "division by zero");
        }
        $curr = $a / $b;
    } else {
        return (0, "unknown operator '$op'");
    }
    push @$numbers, $curr;
    return (1, undef);
}

main();
