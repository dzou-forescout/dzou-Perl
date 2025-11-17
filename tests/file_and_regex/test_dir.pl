#!/usr/bin/env perl
use strict;
use warnings;
use v5.16;
use Test::More;
use File::Temp qw(tempdir);
use File::Path qw(make_path remove_tree);
use Cwd qw(getcwd chdir abs_path);
use FindBin qw($RealBin);
use lib "$RealBin/../../practices/file_and_regex";

# Store original directory
my $original_dir = getcwd();

# Load the script without running main()
my $shell_script = "$RealBin/../../practices/file_and_regex/dir.pl";
unless (-f $shell_script) {
    plan skip_all => "Cannot find $shell_script";
}

# Load the script without running main()
{
    package DirShell;
    our ($current_dir, $previous_dir);
    do $shell_script or die "Failed to load $shell_script: $!";
}

# Import functions we want to test
no strict 'refs';
my $run_cmd = \&{'DirShell::_run_cmd'};
my $make_path = \&{'DirShell::_make_path'};
my $human_size = \&{'DirShell::_human_size'};
my $ls_collect = \&{'DirShell::ls_collect'};
my $tree_collect = \&{'DirShell::tree_collect'};
use strict 'refs';

# Create a test directory structure
my $test_dir = tempdir(CLEANUP => 1);
my $test_structure = {
    'file1.txt' => "Line 1\nLine 2\nLine 3",
    'file2.txt' => "Hello World\nTest Pattern\nAnother line",
    'empty.txt' => "",
    'dir1/subfile1.txt' => "Content in subdir",
    'dir1/subfile2.txt' => "More content\nWith pattern",
    'dir1/subdir/deep.txt' => "Deep file content",
    'dir2/another.txt' => "Another directory",
};

# Create test files
for my $path (keys %$test_structure) {
    my $full_path = "$test_dir/$path";
    my $dir = $full_path;
    $dir =~ s{/[^/]+$}{};
    make_path($dir) unless -d $dir;

    open my $fh, '>', $full_path or die "Cannot create $full_path: $!";
    print $fh $test_structure->{$path};
    close $fh;
}

# Change to test directory for tests
chdir $test_dir;
$DirShell::current_dir = getcwd();
$DirShell::previous_dir = $DirShell::current_dir;

### TEST: _make_path helper
{
    is($make_path->('/home', 'user'), '/home/user', '_make_path: relative path');
    is($make_path->('/home', '/absolute'), '/absolute', '_make_path: absolute path');
}

### TEST: _human_size helper
{
    is($human_size->(0), '0', 'human_size: 0 bytes');
    is($human_size->(100), '100', 'human_size: 100 bytes');
    is($human_size->(1024), '1K', 'human_size: 1K');
    is($human_size->(1536), '1.5K', 'human_size: 1.5K');
    is($human_size->(1048576), '1M', 'human_size: 1M');
    is($human_size->(1073741824), '1G', 'human_size: 1G');
}

### TEST: pwd command
{
    my @result = $run_cmd->('pwd', [], []);
    ok(@result == 1, 'pwd: returns one line');
    is($result[0], getcwd(), 'pwd: returns current directory');
}

### TEST: cd command
{
    my $start_dir = getcwd();

    # cd to dir1
    my @result = $run_cmd->('cd', ['dir1'], []);
    is(scalar(@result), 1, 'cd dir1: returns one line');
    like($result[0], qr/dir1$/, 'cd dir1: changes to dir1');

    # cd back
    chdir $start_dir;
    $DirShell::current_dir = $start_dir;

    # cd with missing directory
    @result = $run_cmd->('cd', [], []);
    like($result[0], qr/missing directory/, 'cd: error on missing directory');

    # cd to non-existent directory
    @result = $run_cmd->('cd', ['nonexistent'], []);
    like($result[0], qr/no such directory/, 'cd: error on non-existent directory');
}

### TEST: cd - (previous directory)
{
    my $start_dir = getcwd();

    # cd to dir1
    $run_cmd->('cd', ['dir1'], []);
    my $dir1 = getcwd();

    # cd back with -
    my @result = $run_cmd->('cd', ['-'], []);
    is(getcwd(), $start_dir, 'cd -: returns to previous directory');

    # cd - again
    @result = $run_cmd->('cd', ['-'], []);
    is(getcwd(), $dir1, 'cd -: toggles between directories');


    # Return to start
    chdir $start_dir;
    $DirShell::current_dir = $start_dir;
}

### TEST: ls command - basic
{
    my @result = $ls_collect->();
    ok(@result > 0, 'ls: returns files');
    ok((grep { $_ eq 'file1.txt' } @result), 'ls: finds file1.txt');
    ok((grep { $_ eq 'dir1' } @result), 'ls: finds dir1');
    ok(!(grep { $_ eq '.' } @result), 'ls: does not show . by default');
}

### TEST: ls -a (all files)
{
    my @result = $ls_collect->('-a');
    ok((grep { $_ eq '.' } @result), 'ls -a: shows . directory');
    ok((grep { $_ eq '..' } @result), 'ls -a: shows .. directory');
}

### TEST: ls -l (long format)
{
    my @result = $ls_collect->('-l');
    ok(@result > 0, 'ls -l: returns results');
    like($result[0], qr/^[dlrwx-]+/, 'ls -l: has permission string');
    like($result[0], qr/\d+/, 'ls -l: has numeric fields');
}

### TEST: ls -lh (long format with human readable sizes)
{
    my @result = $ls_collect->('-lh');
    ok(@result > 0, 'ls -lh: returns results');

    my $has_human = 0;
    for my $line (@result) {
        my @cols = split /\s+/, $line;
        next unless @cols >= 5;         # 保证有 size 那一列

        my $size = $cols[4];            # 第 5 列是 size_disp
        if ($size =~ /^\d+(\.\d+)?[KMGTP]?$/) {
            $has_human = 1;
            last;
        }
    }

    ok($has_human, 'ls -lh: has human-readable size format');
}

### TEST: ls -S (sort by size)
{
    my @result = $ls_collect->('-l', '-S');
    ok(@result > 0, 'ls -S: returns results');
    # Larger files should come first
}

### TEST: ls -r (reverse order)
{
    my @result_normal = $ls_collect->();
    my @result_reverse = $ls_collect->('-r');
    isnt($result_normal[0], $result_reverse[0], 'ls -r: reverses order');
}

### TEST: ls with specific directory
{
    my @result = $ls_collect->('dir1');
    ok((grep { $_ eq 'subfile1.txt' } @result), 'ls dir1: lists files in dir1');
    ok(!(grep { $_ eq 'file1.txt' } @result), 'ls dir1: does not list files from parent');
}

### TEST: ls with non-existent directory
{
    my @result = $ls_collect->('nonexistent');
    like($result[0], qr/no such directory/, 'ls nonexistent: error message');
}

### TEST: cat command
{
    my @result = $run_cmd->('cat', ['file1.txt'], []);
    is(scalar(@result), 3, 'cat: returns correct number of lines');
    is($result[0], 'Line 1', 'cat: correct first line');
    is($result[1], 'Line 2', 'cat: correct second line');
}

### TEST: cat with multiple files
{
    my @result = $run_cmd->('cat', ['file1.txt', 'file2.txt'], []);
    ok(@result >= 6, 'cat multiple: returns lines from both files');
}

### TEST: cat with missing file
{
    my @result = $run_cmd->('cat', [], []);
    like($result[0], qr/missing file/, 'cat: error on missing file');
}

### TEST: cat with non-existent file
{
    my @result = $run_cmd->('cat', ['nonexistent.txt'], []);
    like($result[0], qr/No such file/, 'cat: error on non-existent file');
}

### TEST: cat with directory
{
    my @result = $run_cmd->('cat', ['dir1'], []);
    like($result[0], qr/Is a directory/, 'cat: error on directory');
}

### TEST: grep with file
{
    my @result = $run_cmd->('grep', ['Pattern', 'file2.txt'], []);
    ok(@result > 0, 'grep: finds pattern in file');
    like($result[0], qr/Pattern/, 'grep: result contains pattern');
    like($result[0], qr/file2\.txt:/, 'grep: result has filename prefix');
}

### TEST: grep with pipe input
{
    my @input = ('Line with pattern', 'Line without', 'Another pattern line');
    my @result = $run_cmd->('grep', ['pattern'], \@input);
    is(scalar(@result), 2, 'grep pipe: finds correct number of matches');
    ok((grep { /pattern/ } @result), 'grep pipe: results contain pattern');
}

### TEST: grep -r (recursive)
{
    my @result = $run_cmd->('grep', ['-r', 'pattern', 'dir1'], []);
    ok(@result > 0, 'grep -r: finds matches in subdirectories');
    like($result[0], qr/dir1/, 'grep -r: result includes directory path');
}

### TEST: grep missing pattern
{
    my @result = $run_cmd->('grep', [], []);
    like($result[0], qr/missing pattern/, 'grep: error on missing pattern');
}

### TEST: grep on directory without -r
{
    my @result = $run_cmd->('grep', ['test', 'dir1'], []);
    like($result[0], qr/Is a directory/, 'grep: error on directory without -r');
}

### TEST: tree command
{
    my @result = $tree_collect->();
    ok(@result > 0, 'tree: returns results');
    ok((grep { /file1\.txt/ } @result), 'tree: shows files');
    ok((grep { /dir1/ } @result), 'tree: shows directories');
}

### TEST: tree -d (directories only)
{
    my @result = $tree_collect->('-d');
    ok((grep { /dir1/ } @result), 'tree -d: shows directories');
    ok(!(grep { /file1\.txt/ } @result), 'tree -d: does not show files');
}

### TEST: tree -r (reverse order)
{
    my @result_normal = $tree_collect->();
    my @result_reverse = $tree_collect->('-r');
    isnt($result_normal[-1], $result_reverse[-1], 'tree -r: changes order');
}

### TEST: tree with specific directory
{
    my @result = $tree_collect->('dir1');
    ok((grep { /subfile1\.txt/ } @result), 'tree dir1: shows files in dir1');
}

### TEST: tree with non-existent directory
{
    my @result = $tree_collect->('nonexistent');
    like($result[0], qr/no such directory/, 'tree: error on non-existent directory');
}

### TEST: Unknown command
{
    my @result = $run_cmd->('unknowncmd', [], []);
    like($result[0], qr/Unknown command/, 'Unknown command: error message');
}

### TEST: Empty command
{
    my @result = $run_cmd->('', [], []);
    is(scalar(@result), 0, 'Empty command: returns nothing');
}

### TEST: Piping - ls | grep
{
    # Simulate: ls | grep file
    my @ls_output = $ls_collect->();
    my @grep_output = $run_cmd->('grep', ['file'], \@ls_output);
    ok(@grep_output > 0, 'pipe ls|grep: returns results');
    ok((grep { /file/ } @grep_output), 'pipe ls|grep: filters correctly');
    ok(!(grep { /dir/ } @grep_output), 'pipe ls|grep: excludes non-matches');
}

### TEST: Piping - cat | grep
{
    # Simulate: cat file2.txt | grep Pattern
    my @cat_output = $run_cmd->('cat', ['file2.txt'], []);
    my @grep_output = $run_cmd->('grep', ['Pattern'], \@cat_output);
    ok(@grep_output > 0, 'pipe cat|grep: returns results');
    like($grep_output[0], qr/Pattern/, 'pipe cat|grep: contains pattern');
}

# Clean up and return to original directory
chdir $original_dir;

done_testing();