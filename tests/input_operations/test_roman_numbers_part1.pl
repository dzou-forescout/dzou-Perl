#!/usr/bin/env perl
use strict;
use warnings;
use v5.16;
use Test::More;
use FindBin qw($RealBin);
use lib "$RealBin/../../practices/input_operations";

require_ok('roman_numbers_part1.pl');
RomanNumbers->import();

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
is(roman_to_int("CC"), 200, "Roman CC = 200");
is(roman_to_int("CCC"), 300, "Roman CCC = 300");
is(roman_to_int("MM"), 2000, "Roman MM = 2000");
is(roman_to_int("MMM"), 3000, "Roman MMM = 3000");

# Additive combinations (different numerals)
is(roman_to_int("VI"), 6, "Roman VI = 6");
is(roman_to_int("VII"), 7, "Roman VII = 7");
is(roman_to_int("VIII"), 8, "Roman VIII = 8");
is(roman_to_int("XI"), 11, "Roman XI = 11");
is(roman_to_int("XII"), 12, "Roman XII = 12");
is(roman_to_int("XV"), 15, "Roman XV = 15");
is(roman_to_int("LX"), 60, "Roman LX = 60");
is(roman_to_int("LXX"), 70, "Roman LXX = 70");
is(roman_to_int("CL"), 150, "Roman CL = 150");
is(roman_to_int("DC"), 600, "Roman DC = 600");
is(roman_to_int("MC"), 1100, "Roman MC = 1100");

# Subtractive combinations
is(roman_to_int("IV"), 4, "Roman IV = 4");
is(roman_to_int("IX"), 9, "Roman IX = 9");
is(roman_to_int("XL"), 40, "Roman XL = 40");
is(roman_to_int("XC"), 90, "Roman XC = 90");
is(roman_to_int("CD"), 400, "Roman CD = 400");
is(roman_to_int("CM"), 900, "Roman CM = 900");

# Complex numbers (mix of additive and subtractive)
is(roman_to_int("XIV"), 14, "Roman XIV = 14");
is(roman_to_int("XIX"), 19, "Roman XIX = 19");
is(roman_to_int("XXIV"), 24, "Roman XXIV = 24");
is(roman_to_int("XXIX"), 29, "Roman XXIX = 29");
is(roman_to_int("XLIV"), 44, "Roman XLIV = 44");
is(roman_to_int("XLIX"), 49, "Roman XLIX = 49");
is(roman_to_int("XCIV"), 94, "Roman XCIV = 94");
is(roman_to_int("XCIX"), 99, "Roman XCIX = 99");
is(roman_to_int("CDXC"), 490, "Roman CDXC = 490");
is(roman_to_int("CMXC"), 990, "Roman CMXC = 990");

# Famous years and numbers
is(roman_to_int("MCMXCIV"), 1994, "Roman MCMXCIV = 1994");
is(roman_to_int("MMXXIII"), 2023, "Roman MMXXIII = 2023");
is(roman_to_int("MMXXIV"), 2024, "Roman MMXXIV = 2024");
is(roman_to_int("MCMXC"), 1990, "Roman MCMXC = 1990");
is(roman_to_int("MM"), 2000, "Roman MM = 2000");
is(roman_to_int("MCMXLIV"), 1944, "Roman MCMXLIV = 1944");
is(roman_to_int("MDCCCL"), 1850, "Roman MDCCCL = 1850");

# Case insensitivity tests
is(roman_to_int("i"), 1, "Lowercase i = 1");
is(roman_to_int("v"), 5, "Lowercase v = 5");
is(roman_to_int("x"), 10, "Lowercase x = 10");
is(roman_to_int("mcmxciv"), 1994, "Lowercase mcmxciv = 1994");
is(roman_to_int("MmXxIi"), 2022, "Mixed case MmXxIi = 2022");
is(roman_to_int("iVxL"), 44, "Mixed case iVxL = 44");

# Edge cases for roman_to_int
is(roman_to_int("MMMCMXCIX"), 3999, "Roman MMMCMXCIX = 3999 (largest standard)");

##########
## Integer to Roman Tests
##########

# Basic single numerals
is(int_to_roman(1), "I", "1 = I");
is(int_to_roman(5), "V", "5 = V");
is(int_to_roman(10), "X", "10 = X");
is(int_to_roman(50), "L", "50 = L");
is(int_to_roman(100), "C", "100 = C");
is(int_to_roman(500), "D", "500 = D");
is(int_to_roman(1000), "M", "1000 = M");

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

# Tens (10-90)
is(int_to_roman(10), "X", "10 = X");
is(int_to_roman(20), "XX", "20 = XX");
is(int_to_roman(30), "XXX", "30 = XXX");
is(int_to_roman(40), "XL", "40 = XL");
is(int_to_roman(50), "L", "50 = L");
is(int_to_roman(60), "LX", "60 = LX");
is(int_to_roman(70), "LXX", "70 = LXX");
is(int_to_roman(80), "LXXX", "80 = LXXX");
is(int_to_roman(90), "XC", "90 = XC");

# Hundreds (100-900)
is(int_to_roman(100), "C", "100 = C");
is(int_to_roman(200), "CC", "200 = CC");
is(int_to_roman(300), "CCC", "300 = CCC");
is(int_to_roman(400), "CD", "400 = CD");
is(int_to_roman(500), "D", "500 = D");
is(int_to_roman(600), "DC", "600 = DC");
is(int_to_roman(700), "DCC", "700 = DCC");
is(int_to_roman(800), "DCCC", "800 = DCCC");
is(int_to_roman(900), "CM", "900 = CM");

# Thousands (1000-3000)
is(int_to_roman(1000), "M", "1000 = M");
is(int_to_roman(2000), "MM", "2000 = MM");
is(int_to_roman(3000), "MMM", "3000 = MMM");

# Complex numbers with all components
is(int_to_roman(14), "XIV", "14 = XIV");
is(int_to_roman(19), "XIX", "19 = XIX");
is(int_to_roman(24), "XXIV", "24 = XXIV");
is(int_to_roman(29), "XXIX", "29 = XXIX");
is(int_to_roman(44), "XLIV", "44 = XLIV");
is(int_to_roman(49), "XLIX", "49 = XLIX");
is(int_to_roman(94), "XCIV", "94 = XCIV");
is(int_to_roman(99), "XCIX", "99 = XCIX");
is(int_to_roman(444), "CDXLIV", "444 = CDXLIV");
is(int_to_roman(490), "CDXC", "490 = CDXC");
is(int_to_roman(944), "CMXLIV", "944 = CMXLIV");
is(int_to_roman(990), "CMXC", "990 = CMXC");

# Famous years
is(int_to_roman(1994), "MCMXCIV", "1994 = MCMXCIV");
is(int_to_roman(2023), "MMXXIII", "2023 = MMXXIII");
is(int_to_roman(2024), "MMXXIV", "2024 = MMXXIV");
is(int_to_roman(1990), "MCMXC", "1990 = MCMXC");
is(int_to_roman(1944), "MCMXLIV", "1944 = MCMXLIV");
is(int_to_roman(1776), "MDCCLXXVI", "1776 = MDCCLXXVI");
is(int_to_roman(1492), "MCDXCII", "1492 = MCDXCII");

# Edge cases
is(int_to_roman(3999), "MMMCMXCIX", "3999 = MMMCMXCIX (largest standard)");

# Numbers with patterns
is(int_to_roman(58), "LVIII", "58 = LVIII");
is(int_to_roman(158), "CLVIII", "158 = CLVIII");
is(int_to_roman(1258), "MCCLVIII", "1258 = MCCLVIII");
is(int_to_roman(3888), "MMMDCCCLXXXVIII", "3888 = MMMDCCCLXXXVIII");

##########
## Round-trip Tests (int → roman → int)
##########

for my $num (1..100) {
    my $roman = int_to_roman($num);
    my $back = roman_to_int($roman);
    is($back, $num, "Round-trip: $num → $roman → $num");
}

# Round-trip for larger numbers
for my $num (100, 200, 300, 400, 500, 750, 1000, 1500, 2000, 2500, 3000, 3999) {
    my $roman = int_to_roman($num);
    my $back = roman_to_int($roman);
    is($back, $num, "Round-trip: $num → $roman → $num");
}

##########
## Edge Cases and Special Scenarios
##########

# Zero and negative numbers (if applicable)
is(int_to_roman(0), "", "0 returns empty string");

# Very specific patterns
is(roman_to_int("DCLXVI"), 666, "DCLXVI = 666");
is(int_to_roman(666), "DCLXVI", "666 = DCLXVI");

is(roman_to_int("CMXCIX"), 999, "CMXCIX = 999");
is(int_to_roman(999), "CMXCIX", "999 = CMXCIX");

# All subtractive cases
is(roman_to_int("IV"), 4, "Subtractive: IV = 4");
is(roman_to_int("IX"), 9, "Subtractive: IX = 9");
is(roman_to_int("XL"), 40, "Subtractive: XL = 40");
is(roman_to_int("XC"), 90, "Subtractive: XC = 90");
is(roman_to_int("CD"), 400, "Subtractive: CD = 400");
is(roman_to_int("CM"), 900, "Subtractive: CM = 900");

# Numbers ending in 4, 9 (special cases)
is(int_to_roman(4), "IV", "4 = IV (special)");
is(int_to_roman(9), "IX", "9 = IX (special)");
is(int_to_roman(14), "XIV", "14 = XIV");
is(int_to_roman(19), "XIX", "19 = XIX");
is(int_to_roman(39), "XXXIX", "39 = XXXIX");
is(int_to_roman(49), "XLIX", "49 = XLIX");
is(int_to_roman(89), "LXXXIX", "89 = LXXXIX");
is(int_to_roman(99), "XCIX", "99 = XCIX");
is(int_to_roman(399), "CCCXCIX", "399 = CCCXCIX");
is(int_to_roman(499), "CDXCIX", "499 = CDXCIX");
is(int_to_roman(899), "DCCCXCIX", "899 = DCCCXCIX");
is(int_to_roman(999), "CMXCIX", "999 = CMXCIX");

# Numbers ending in 5 (another pattern)
is(int_to_roman(5), "V", "5 = V");
is(int_to_roman(15), "XV", "15 = XV");
is(int_to_roman(25), "XXV", "25 = XXV");
is(int_to_roman(35), "XXXV", "35 = XXXV");
is(int_to_roman(45), "XLV", "45 = XLV");
is(int_to_roman(55), "LV", "55 = LV");
is(int_to_roman(65), "LXV", "65 = LXV");
is(int_to_roman(75), "LXXV", "75 = LXXV");
is(int_to_roman(85), "LXXXV", "85 = LXXXV");
is(int_to_roman(95), "XCV", "95 = XCV");

##########
## Stress Tests
##########

# All numbers ending in same digit
for my $ones (1..9) {
    for my $tens (0..3) {
        my $num = $tens * 10 + $ones;
        next if $num > 39;
        my $roman = int_to_roman($num);
        my $back = roman_to_int($roman);
        is($back, $num, "Stress test: $num converts correctly");
    }
}

# Sequential numbers
for my $n (50..60) {
    my $roman = int_to_roman($n);
    my $back = roman_to_int($roman);
    is($back, $n, "Sequential: $n → $roman → $n");
}

# Jump by hundreds
for my $n (100, 200, 300, 400, 500, 600, 700, 800, 900) {
    my $roman = int_to_roman($n);
    my $back = roman_to_int($roman);
    is($back, $n, "Hundreds: $n → $roman → $n");
}

done_testing();