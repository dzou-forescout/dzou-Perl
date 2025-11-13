#!/usr/bin/env perl
use strict;
use warnings;
use v5.16;

my %roman_val= (
    I => 1,   V => 5,   X => 10,  L => 50,
    C => 100, D => 500, M => 1000
);

my @number_map = (
    [1000, "M"], [900, "CM"], [500, "D"], [400, "CD"],
    [100, "C"],  [90, "XC"],  [50, "L"], [40, "XL"],
    [10, "X"],   [9, "IX"],   [5, "V"],  [4, "IV"],
    [1, "I"]
);

sub roman_to_int{
    my($roman_number) = @_;
    $roman_number = uc($roman_number); # to UpperCase
    my $result = 0;

    for(my $i = 0; $i < length($roman_number); $i++){
        my $val1 = $roman_val{substr($roman_number, $i, 1)};
        my $val2 = $roman_val{substr($roman_number, $i+1, 1)};

        if(defined $val2 && $val1 < $val2){
            $result += ($val2 - $val1);
            $i++;
        }else{
            $result += $val1;
        }
    }
    return $result;
}

sub int_to_roman{
    my ($number) = @_;
    my $result = "";
    for my $pair (@number_map){
        my ($val, $roman) = @$pair;
        while($number >= $val){
            $result .= $roman;
            $number -= $val;
        }
    }
    return $result;
}

sub main{
    while(1){
        print "Enter number in numeric or number in roman : ";
        my $input = <STDIN>;
        last unless defined $input;
        chomp $input;

        if($input =~ /^\d+$/) {
            say "Countdown (Roman):";
            while($input > 0) {
                my $roman = int_to_roman($input);
                say "$roman";
                sleep 1 if $input > 1;
                $input--;
            }
            say "Countdown (roman) Done";

        }elsif($input =~ /^[IVXLCDMivxlcdm]+$/){
            my $number = roman_to_int($input);
            say "Countdown (numeric):";
            while($number > 0){
                say "$number";
                sleep 1 if $number > 1;
                $number--;
            }
            say "Countdown (numeric) Done";
        }else{
            say "Invalid input!"
        }
    }
    return 0;
}

main();

