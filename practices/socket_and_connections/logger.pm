package Logger;

use strict;
use warnings;
use Carp;
use Fcntl qw(:flock);

my %LEVEL_NUM = (
    EMERG   => 0,
    ALERT   => 1,
    CRIT    => 2,
    ERR     => 3,
    ERROR   => 3, # alias
    WARNING => 4,
    WARN    => 4, # alias
    NOTICE  => 5,
    INFO    => 6,
    DEBUG   => 7,
);
my %NUM_LEVEL = map {$LEVEL_NUM{$_} => $_} keys %LEVEL_NUM;

# ------------------------------
# Constructor
#   my $log = Logger->new(
#       file      => 'echo.log',
#       dir       => '/tmp',
#       max_size  => 1024*1024,
#       level     => 'INFO',
#   );
# ------------------------------
sub new {
    my ($class, %args) = @_;

    my $file = $args{file} || 'app.log';
    my $dir = $args{dir} || '.';
    my $max_size = $args{max_size} || 1024 * 1024; # 1MB default
    my $level = uc($args{level} || 'INFO');

    croak "Unknown log level '$level'" unless exists $LEVEL_NUM{$level};

    my $self = {
        file      => $file,
        dir       => $dir,
        max_size  => $max_size,
        level_num => $LEVEL_NUM{$level},
        fh        => undef, # filehandle
    };

    bless $self, $class;

    $self->_open_log_file();

    return $self;
}

# ------------------------------
# Public API
# ------------------------------

sub get_level {
    my ($self) = @_;
    return $NUM_LEVEL{ $self->{level_num} } || 'UNKNOWN';
}

sub set_level {
    my ($self, $level) = @_;
    $level = uc $level;
    croak "Unknown log level '$level'" unless exists $LEVEL_NUM{$level};
    $self->{level_num} = $LEVEL_NUM{$level};
}

sub log {
    my ($self, $category, $severity, $message) = @_;

    $severity = uc $severity;
    unless (exists $LEVEL_NUM{$severity}) {
        carp "Unknown severity '$severity', treating as INFO";
        $severity = 'INFO';
    }

    my $msg_level = $LEVEL_NUM{$severity};
    return if $msg_level > $self->{level_num};

    $self->_write_line(
        sprintf "%s |%s | %s | %s",
            _timestamp(),
            $category,
            $severity,
            $message
    );
}

sub audit {
    my ($self, $other_ip, $message) = @_;

    $self->_write_line(
        sprintf "%s | Audit | %s | %s",
            _timestamp(),
            $other_ip,
            $message
    );
}

sub error {
    my ($self, $cat, $msg) = @_;
    $self->log($cat, 'ERROR', $msg)
}
sub err {
    my ($self, $cat, $msg) = @_;
    $self->log($cat, 'ERR', $msg)
}
sub warn {
    my ($self, $cat, $msg) = @_;
    $self->log($cat, 'WARN', $msg)
}
sub info {
    my ($self, $cat, $msg) = @_;
    $self->log($cat, 'INFO', $msg)
}
sub debug {
    my ($self, $cat, $msg) = @_;
    $self->log($cat, 'DEBUG', $msg)
}


# ------------------------------
# Internal Helpers
# ------------------------------
sub _open_log_file {
    my ($self) = @_;

    my $path = $self->_log_path();

    open my $fh, '>>', $path or croak "Cannot open log file '$path': $!";
    $fh->autoflush(1);
    $self->{fh} = $fh;
}

sub _log_path {
    my ($self) = @_;
    return "$self->{dir}/$self->{file}";
}

sub _write_line {
    my ($self, $line) = @_;

    $self->_rotate_if_needed();

    $self->_open_log_file() unless $self->{fh};
    my $fh = $self->{fh};

    flock($fh, LOCK_EX); # add Exclusive Lock
    print {$fh} "$line\n";
    flock($fh, LOCK_UN); # unlock
}
sub _rotate_if_needed {
    my ($self) = @_;

    my $path = $self->_log_path();
    my $max = $self->{max_size};

    return unless -e $path;
    my $size = -s $path;
    return if $size <= $max;

    # Simple rotation: rename current -> filename.timestamp
    my $timestamp = _timestamp();
    $timestamp =~ s/[\s:]/_/g; # safe in filename
    my $rotated = $path . "." . $timestamp;

    close $self->{fh} if $self->{fh};

    rename $path, $rotated
        or carp "Failed to rotate log '$path' to '$rotated': $!";
    #if (!rename(...)) { log.warn("Failed...");}

    $self->_open_log_file();
}

sub _timestamp {
    my @t = localtime();
    return sprintf(
        "%04d-%02d-%02d %02d:%02d:%02d",
        $t[5] + 1900,
        $t[4] + 1,
        $t[3],
        $t[2],
        $t[1],
        $t[0]
    );
}

1;
