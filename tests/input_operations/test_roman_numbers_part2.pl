#!/usr/bin/env perl
use strict;
use warnings;
use v5.16;
use Test::More;
use FindBin qw($RealBin);
use lib "$RealBin/../../practices/input_operations";

require_ok('roman_numbers_part2.pl');
RomanNumbers->import();

##########
## NOTE: This script has the same roman_to_int and int_to_roman functions
## as roman_numbers_part1.pl, but with countdown functionality in main().
## The countdown is best tested manually since it involves sleep() and UI.
## These tests focus on the conversion functions.
##########

##########
## Roman to Integer Tests
##########

# Basic single numerals
is(roman_to_int("I"), 1, "Roman I = 1");
is(roman_to_int("V"), 5, "Roman V = 5");
is(roman_to_int("X"), 10, "Roman X = 10");
is(roman_to_int("L"), 50, "Roman L = 50");
is(roman_to_int("C"), 100, "Roman C = 100");
is(roman_to_int("D"), 500, "Roman D = 500");
is(roman_to_int("M"), 1000, "Roman M = 1000");

# Additive combinations (same numeral repeated)
is(roman_to_int("II"), 2, "Roman II = 2");
is(roman_to_int("III"), 3, "Roman III = 3");
is(roman_to_int("XX"), 20, "Roman XX = 20");
is(roman_to_int("XXX"), 30, "Roman XXX = 30");
is(roman_to_int("MM"), 2000, "Roman MM = 2000");

# Subtractive combinations
is(roman_to_int("IV"), 4, "Roman IV = 4");
is(roman_to_int("IX"), 9, "Roman IX = 9");
is(roman_to_int("XL"), 40, "Roman XL = 40");
is(roman_to_int("XC"), 90, "Roman XC = 90");
is(roman_to_int("CD"), 400, "Roman CD = 400");
is(roman_to_int("CM"), 900, "Roman CM = 900");

# Complex numbers
is(roman_to_int("MCMXCIV"), 1994, "Roman MCMXCIV = 1994");
is(roman_to_int("MMXXIII"), 2023, "Roman MMXXIII = 2023");

# Case insensitivity
is(roman_to_int("i"), 1, "Lowercase i = 1");
is(roman_to_int("mcmxciv"), 1994, "Lowercase mcmxciv = 1994");

##########
## Integer to Roman Tests
##########

# Numbers 1-10
is(int_to_roman(1), "I", "1 = I");
is(int_to_roman(2), "II", "2 = II");
is(int_to_roman(3), "III", "3 = III");
is(int_to_roman(4), "IV", "4 = IV");
is(int_to_roman(5), "V", "5 = V");
is(int_to_roman(6), "VI", "6 = VI");
is(int_to_roman(7), "VII", "7 = VII");
is(int_to_roman(8), "VIII", "8 = VIII");
is(int_to_roman(9), "IX", "9 = IX");
is(int_to_roman(10), "X", "10 = X");

# Special countdown-relevant numbers
is(int_to_roman(3), "III", "Countdown: 3 = III");
is(int_to_roman(2), "II", "Countdown: 2 = II");
is(int_to_roman(1), "I", "Countdown: 1 = I");

# Larger countdown numbers
is(int_to_roman(100), "C", "Countdown: 100 = C");
is(int_to_roman(50), "L", "Countdown: 50 = L");
is(int_to_roman(20), "XX", "Countdown: 20 = XX");

##########
## Countdown Sequence Tests
## Test that a countdown sequence converts correctly
##########

# Test countdown from 5
my @countdown_5 = (5, 4, 3, 2, 1);
my @expected_5 = ("V", "IV", "III", "II", "I");
for my $i (0..$#countdown_5) {
    my $num = $countdown_5[$i];
    my $expected = $expected_5[$i];
    is(int_to_roman($num), $expected, "Countdown sequence: $num = $expected");
}

# Test countdown from 10
my @countdown_10 = (10, 9, 8, 7, 6, 5, 4, 3, 2, 1);
my @expected_10 = ("X", "IX", "VIII", "VII", "VI", "V", "IV", "III", "II", "I");
for my $i (0..$#countdown_10) {
    my $num = $countdown_10[$i];
    my $expected = $expected_10[$i];
    is(int_to_roman($num), $expected, "Countdown from 10: $num = $expected");
}

# Test reverse countdown (numeric from Roman)
my @roman_countdown = ("X", "IX", "VIII", "VII", "VI", "V", "IV", "III", "II", "I");
my @numeric_countdown = (10, 9, 8, 7, 6, 5, 4, 3, 2, 1);
for my $i (0..$#roman_countdown) {
    my $roman = $roman_countdown[$i];
    my $expected = $numeric_countdown[$i];
    is(roman_to_int($roman), $expected, "Roman countdown: $roman = $expected");
}

##########
## Tens and Hundreds (for longer countdowns)
##########

is(int_to_roman(100), "C", "100 = C");
is(int_to_roman(90), "XC", "90 = XC");
is(int_to_roman(80), "LXXX", "80 = LXXX");
is(int_to_roman(70), "LXX", "70 = LXX");
is(int_to_roman(60), "LX", "60 = LX");
is(int_to_roman(50), "L", "50 = L");
is(int_to_roman(40), "XL", "40 = XL");
is(int_to_roman(30), "XXX", "30 = XXX");
is(int_to_roman(20), "XX", "20 = XX");

##########
## Famous countdown numbers
##########

# New Year's Eve countdown
is(int_to_roman(2024), "MMXXIV", "Year 2024 = MMXXIV");
is(int_to_roman(2023), "MMXXIII", "Year 2023 = MMXXIII");
is(int_to_roman(2022), "MMXXII", "Year 2022 = MMXXII");
is(int_to_roman(2021), "MMXXI", "Year 2021 = MMXXI");
is(int_to_roman(2020), "MMXX", "Year 2020 = MMXX");

# Apollo countdown
is(int_to_roman(10), "X", "Apollo: T-10 = X");
is(int_to_roman(5), "V", "Apollo: T-5 = V");
is(int_to_roman(3), "III", "Apollo: T-3 = III");

##########
## Round-trip Tests (critical for countdown accuracy)
##########

# Small countdown numbers
for my $num (1..20) {
    my $roman = int_to_roman($num);
    my $back = roman_to_int($roman);
    is($back, $num, "Round-trip countdown: $num → $roman → $num");
}

# Decade markers
for my $num (10, 20, 30, 40, 50, 60, 70, 80, 90, 100) {
    my $roman = int_to_roman($num);
    my $back = roman_to_int($roman);
    is($back, $num, "Round-trip decade: $num → $roman → $num");
}

##########
## Edge Cases for Countdown
##########

# Zero (countdown end)
is(int_to_roman(0), "", "Countdown end: 0 returns empty string");

# Single digit countdown
is(int_to_roman(1), "I", "Final countdown: 1 = I");

# Countdown through subtractive numbers
is(int_to_roman(9), "IX", "Through 9: IX");
is(int_to_roman(8), "VIII", "Through 8: VIII");
is(int_to_roman(7), "VII", "Through 7: VII");
is(int_to_roman(6), "VI", "Through 6: VI");
is(int_to_roman(5), "V", "Through 5: V");
is(int_to_roman(4), "IV", "Through 4: IV");
is(int_to_roman(3), "III", "Through 3: III");
is(int_to_roman(2), "II", "Through 2: II");
is(int_to_roman(1), "I", "Through 1: I");

##########
## Pattern Tests (relevant for countdown display)
##########

# Numbers ending in 9 (common in countdowns)
is(int_to_roman(99), "XCIX", "99 = XCIX");
is(int_to_roman(59), "LIX", "59 = LIX");
is(int_to_roman(49), "XLIX", "49 = XLIX");
is(int_to_roman(39), "XXXIX", "39 = XXXIX");
is(int_to_roman(29), "XXIX", "29 = XXIX");
is(int_to_roman(19), "XIX", "19 = XIX");

# Numbers ending in 5 (halfway markers)
is(int_to_roman(95), "XCV", "95 = XCV");
is(int_to_roman(85), "LXXXV", "85 = LXXXV");
is(int_to_roman(75), "LXXV", "75 = LXXV");
is(int_to_roman(65), "LXV", "65 = LXV");
is(int_to_roman(55), "LV", "55 = LV");
is(int_to_roman(45), "XLV", "45 = XLV");
is(int_to_roman(35), "XXXV", "35 = XXXV");
is(int_to_roman(25), "XXV", "25 = XXV");
is(int_to_roman(15), "XV", "15 = XV");

##########
## Specific Countdown Sequences
##########

# Countdown from 3 (common in sports)
my @countdown_3_nums = (3, 2, 1);
my @countdown_3_roman = ("III", "II", "I");
for my $i (0..$#countdown_3_nums) {
    is(int_to_roman($countdown_3_nums[$i]), $countdown_3_roman[$i],
        "3-2-1 countdown: $countdown_3_nums[$i] = $countdown_3_roman[$i]");
}

# Countdown from 20 (common starting point)
for my $n (20, 19, 18, 17, 16, 15, 14, 13, 12, 11, 10) {
    my $roman = int_to_roman($n);
    my $back = roman_to_int($roman);
    is($back, $n, "Countdown 20→10: $n → $roman → $n");
}

##########
## Large Countdown Numbers
##########

is(int_to_roman(1000), "M", "Millennium: 1000 = M");
is(int_to_roman(999), "CMXCIX", "Before millennium: 999 = CMXCIX");
is(int_to_roman(500), "D", "500 = D");
is(int_to_roman(499), "CDXCIX", "499 = CDXCIX");
is(int_to_roman(100), "C", "Century: 100 = C");
is(int_to_roman(99), "XCIX", "99 = XCIX");

##########
## Case Insensitivity (for Roman input countdown)
##########

is(roman_to_int("X"), 10, "Uppercase X = 10");
is(roman_to_int("x"), 10, "Lowercase x = 10");
is(roman_to_int("V"), 5, "Uppercase V = 5");
is(roman_to_int("v"), 5, "Lowercase v = 5");
is(roman_to_int("Iii"), 3, "Mixed case Iii = 3");

##########
## Stress Test: Sequential Countdown
##########

# Test every number from 50 down to 1 converts correctly
for my $n (1..50) {
    my $roman = int_to_roman($n);
    my $back = roman_to_int($roman);
    is($back, $n, "Sequential countdown test: $n → $roman → $n");
}

done_testing();