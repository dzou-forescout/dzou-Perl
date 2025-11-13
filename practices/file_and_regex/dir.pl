#!/usr/bin/env perl
use strict;
use warnings;
use v5.16;

use Cwd qw(getcwd abs_path);

say "Simple dir shell. Commands:";
say "  pwd";
say "  cd <dir>";
say "  ls [options] [dir]   (options: -l -a -r -s -S -h)";
say "  tree [options] [dir] (options: -d -r)";
say "  exit / quit";
say "Pipes: cmd1 | cmd2 | ... (up to 8 pipes)";

my $current_dir = getcwd();
my $previous_dir = $current_dir;

sub main {
    while (1) {
        print "dir> ";
        my $line = <STDIN>;
        last unless defined $line;
        chomp $line;
        next if $line =~ /^\s*$/;

        my @stages = split /\|/, $line;
        if (@stages - 1 > 8) {
            say "Too many pipes (max 8 allowed)";
            next;
        }

        my @prev_output;
        for my $stage (@stages) {
            $stage =~ s/^\s+//;
            $stage =~ s/\s+$//;
            next if $stage eq '';

            my @tokens = split /\s+/, $stage;
            my $cmd = shift @tokens // '';

            @prev_output = _run_cmd($cmd, \@tokens, \@prev_output);
        }
        say for @prev_output;
    }
}

sub _make_path {
    my ($base, $target) = @_;
    return $target if defined $target && $target =~ m{^/};
    return "$base/$target";
}

sub _human_size {
    my $n = shift // 0;
    my $neg = $n < 0;
    $n = -$n if $neg;

    my @units = ('', 'K', 'M', 'G', 'T', 'P');
    my $i = 0;
    while ($n >= 1024 && $i < $#units) {
        $n /= 1024;
        $i++;
    }

    my $s = ($n >= 10 || $n == int($n))
        ? sprintf('%.0f', $n)
        : sprintf('%.1f', $n);

    $s .= $units[$i];
    return $neg ? "-$s" : $s;
}

sub _format_mode {
    my ($mode, $path) = @_;

    my $type = '-';
    if (-d $path) {$type = 'd';}
    elsif (-l $path) {$type = 'l';}

    my @perm = qw(--- --x -w- -wx r-- r-x rw- rwx);
    my $owner = $perm[ ($mode >> 6) & 7 ];
    my $group = $perm[ ($mode >> 3) & 7 ];
    my $other = $perm[  $mode & 7 ];

    return $type . $owner . $group . $other;
}

sub _format_time {
    my ($t) = @_;
    my @lt = localtime($t);
    my @mons = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);
    my $mon = $mons[$lt[4]];
    my $day = $lt[3];
    my $hour = $lt[2];
    my $min = $lt[1];
    return sprintf("%s %2d %02d:%02d", $mon, $day, $hour, $min);
}


sub _run_cmd {
    my ($cmd, $args_ref, $input_ref) = @_;
    my @args  = @$args_ref;
    my @input = @$input_ref;

    my @out;

    if ($cmd eq '') {
        return @out;
    }
    elsif ($cmd eq 'pwd') {
        $current_dir = getcwd();
        push @out, $current_dir;
    }
    elsif ($cmd eq 'cd') {
        my $target = $args[0];

        if (!defined $target || $target eq '') {
            push @out, "cd: missing directory";
            return @out;
        }

        if ($target eq '-') {
            my $tmp = $current_dir;
            $current_dir  = $previous_dir;
            $previous_dir = $tmp;

            unless (chdir $current_dir) {
                push @out, "cd: failed to change to $current_dir: $!";
                $current_dir = getcwd();
                return @out;
            }

            push @out, $current_dir;
            return @out;
        }

        my $newdir = _make_path($current_dir, $target);
        my $abs    = abs_path($newdir);

        if (!defined $abs || !-d $abs) {
            push @out, "cd: no such directory: $target";
            return @out;
        }

        $previous_dir = $current_dir;
        unless (chdir $abs) {
            push @out, "cd: failed to change to $abs: $!";
            return @out;
        }

        $current_dir = getcwd();
        push @out, $current_dir;
    }
    elsif ($cmd eq 'ls') {
        my @all_args = (@args, @input);
        @out = ls_collect(@all_args);
    }
    elsif ($cmd eq 'tree') {
        my @all_args = (@args, @input);
        @out = tree_collect(@all_args);
    }
    elsif ($cmd eq 'cat') {
        @out = _cat_collect(@args);
    }
    elsif ($cmd eq 'grep') {
        @out = _grep_collect(\@args, \@input);
    }
    elsif ($cmd eq 'exit' || $cmd eq 'quit') {
        push @out, "Use 'exit' or 'quit' alone to leave shell";
    }
    else {
        push @out, "Unknown command: $cmd";
    }

    return @out;
}

sub ls_collect {
    my (@args) = @_;

    my %opt = (
        l => 0,  # long format
        a => 0,  # all, include .*
        r => 0,  # reverse
        s => 0,  # show blocks
        S => 0,  # sort by size
        h => 0,  # human readable (with -l / -s)
    );

    my @paths;
    for my $a (@args) {
        if ($a =~ /^-/ && $a ne '-') {
            my $flags = substr($a, 1);
            $opt{$_} = 1 for split //, $flags;
        } else {
            push @paths, $a;
        }
    }

    my $dir = @paths ? $paths[0] : $current_dir;
    $dir = _make_path($current_dir, $dir) unless $dir =~ m{^/};
    my $abs = abs_path($dir);

    my @out;

    if (!defined $abs || !-d $abs) {
        push @out, "ls: no such directory: $dir";
        return @out;
    }

    opendir(my $dh, $abs) or do {
        push @out, "ls: cannot open directory $abs: $!";
        return @out;
    };
    my @entries = readdir $dh;
    closedir $dh;

    unless ($opt{a}) {
        @entries = grep { $_ ne '.' && $_ ne '..' } @entries;
    }

    my @items;
    for my $name (@entries) {
        my $full = "$abs/$name";
        my @st   = lstat($full);
        next unless @st;
        push @items, {
            name => $name,
            full => $full,
            stat => \@st,
        };
    }

    if ($opt{S}) {
        @items = sort {
            my $sa = $a->{stat}[7] // 0;
            my $sb = $b->{stat}[7] // 0;
            $sb <=> $sa;   # 大的在前
        } @items;
    } else {
        @items = sort { $a->{name} cmp $b->{name} } @items;
    }
    @items = reverse @items if $opt{r};

    if ($opt{l} || $opt{s}) {
        for my $it (@items) {
            my $name = $it->{name};
            my $full = $it->{full};
            my @st   = @{ $it->{stat} };

            my $mode   = $st[2];
            my $nlink  = $st[3];
            my $uid    = $st[4];
            my $gid    = $st[5];
            my $size   = $st[7];
            my $mtime  = $st[9];
            my $blocks = $st[12] // 0;

            my $perm   = _format_mode($mode, $full);
            my $user   = getpwuid($uid) // $uid;
            my $group  = getgrgid($gid) // $gid;
            my $time_s = _format_time($mtime);

            my $size_disp   = $size;
            my $blocks_disp = $blocks;

            if ($opt{h}) {
                $size_disp = _human_size($size);
            }

            my $line = '';

            if ($opt{s}) {
                $line .= sprintf("%4d ", $blocks_disp);
            }

            if ($opt{l}) {
                $line .= sprintf(
                    "%s %3d %-8s %-8s %8s %s %s",
                    $perm, $nlink, $user, $group,
                    $size_disp, $time_s, $name
                );
            } else {
                $line .= $name;
            }

            push @out, $line;
        }
    } else {
        my @names = map { $_->{name} } @items;
        push @out, @names;
    }

    return @out;
}


sub tree_collect {
    my (@args) = @_;

    my %opt = (
        d => 0,  # directories only
        r => 0,  # reversed order
    );

    my @paths;
    for my $a (@args) {
        if ($a =~ /^-/ && $a ne '-') {
            my $flags = substr($a, 1);
            $opt{$_} = 1 for grep { $_ =~ /^[dr]$/ } split //, $flags;
        } else {
            push @paths, $a;
        }
    }

    my $dir = @paths ? $paths[0] : $current_dir;
    $dir = _make_path($current_dir, $dir) unless $dir =~ m{^/};
    my $abs = abs_path($dir);

    my @out;

    if (!defined $abs || !-d $abs) {
        push @out, "tree: no such directory: $dir";
        return @out;
    }

    _collect_tree($abs, '', \%opt, \@out);

    return @out;
}

sub _collect_tree {
    my ($path, $indent, $opt, $out_ref) = @_;

    my $name = $path;
    $name =~ s!.*/!!;
    $name = '/' if $name eq '' && $path eq '/';

    push @$out_ref, $indent . $name;

    return unless -d $path;

    opendir(my $dh, $path) or do {
        push @$out_ref, $indent . "  [cannot open: $!]";
        return;
    };

    my @entries = grep { $_ ne '.' && $_ ne '..' } readdir $dh;
    closedir $dh;

    @entries = sort @entries;
    @entries = reverse @entries if $opt->{r};

    for my $e (@entries) {
        my $child = "$path/$e";

        # 不跟随目录型 symlink，避免循环
        if (-l $child && -d $child) {
            next if $opt->{d};    # -d 下也跳过
            push @$out_ref, $indent . '  ' . "$e@";
            next;
        }

        if (-d $child) {
            _collect_tree($child, $indent . '  ', $opt, $out_ref);
        } else {
            next if $opt->{d};
            push @$out_ref, $indent . '  ' . $e;
        }
    }
}

sub _cat_collect{
    my (@args) = @_;
    my @out;

    if(!@args){
        push @out, "cat: missing file";
        return @out;
    }

    for my $path (@args) {
        my $p = $path =~ m{^/} ? $path : _make_path($current_dir, $path);
        my $abs = abs_path($p);
        if (!defined $abs) {
            push @out, "cat: $path: No such file or directory";
            next;
        }
        if (-d $abs) {
            push @out, "cat: $path: Is a directory";
            next;
        }

        my $fh;
        unless (open $fh, '<', $abs) {
            push @out, "cat: $path: $!";
            next;
        }
        while (my $line = <$fh>) {
            chomp $line;
            push @out, $line;
        }
        close $fh;
    }
    return @out;
}

sub _grep_file {
    my ($file, $pattern, $out_ref) = @_;

    open my $fh, '<', $file or do {
        push @$out_ref, "grep: $file: $!";
        return;
    };

    while (my $line = <$fh>) {
        chomp $line;
        if (index($line, $pattern) != -1) {
            push @$out_ref, "$file:$line";
        }
    }

    close $fh;
}

sub _grep_dir {
    my ($dir, $pattern, $out_ref) = @_;

    opendir my $dh, $dir or do {
        push @$out_ref, "grep: $dir: $!";
        return;
    };
    my @entries = grep { $_ ne '.' && $_ ne '..' } readdir $dh;
    closedir $dh;

    for my $e (@entries) {
        my $child = "$dir/$e";

        #if it is a directory or symlink, break, prohibit infinite loop
        if (-l $child && -d $child) {
            next;
        }

        if (-d $child) {
            _grep_dir($child, $pattern, $out_ref);
        } elsif (-f $child) {
            _grep_file($child, $pattern, $out_ref);
        }
    }
}

sub _grep_collect {
    my ($args_ref, $input_ref) = @_;
    my @args  = @$args_ref;
    my @input = @$input_ref;

    my %opt = ( r => 0 );
    my @rest;

    for my $a (@args) {
        if ($a =~ /^-/ && $a ne '-') {
            my $flags = substr($a, 1);
            $opt{$_} = 1 for split //, $flags;
        } else {
            push @rest, $a;
        }
    }

    my @out;

    if (!@rest) {
        push @out, "grep: missing pattern";
        return @out;
    }

    my $pattern = shift @rest;

    # --- case 1, have pipe ---
    if (@input) {
        for my $line (@input) {
            if (index($line, $pattern) != -1) {
                push @out, $line;
            }
        }
        return @out;
    }

    # ----case 2, no pipe and using [<input>] ----
    my $input = $rest[0];
    if (!defined $input) {
        push @out, "grep: missing input";
        return @out;
    }

    my $path = $input;
    my $abs;
    if ($path =~ m{^/}) {
        $abs = abs_path($path);
    } else {
        $abs = abs_path(_make_path($current_dir, $path));
    }

    if (defined $abs) {
        if (-d $abs) {
            if ($opt{r}) {
                _grep_dir($abs, $pattern, \@out);
            } else {
                push @out, "grep: $input: Is a directory";
            }
            return @out;
        }
        elsif (-f $abs) {
            _grep_file($abs, $pattern, \@out);
            return @out;
        }
    }

    # --- <text> ---
    if (index($input, $pattern) != -1) {
        push @out, $input;
    }
    return @out;
}

main();
