package DBIx::Class::QueryLog::Tee;

use Moo;
use warnings NONFATAL => 'all';

use Sub::Name 'subname';

my @methods = qw(
   txn_begin txn_commit txn_rollback
   svp_begin svp_release svp_rollback
   query_start query_end
);
sub _valid_logger { !$_[0]->can($_) && return 0 for @methods; 1 }

use namespace::clean;

has _loggers => (
   is => 'ro',
   isa => sub {
      die "loggers has to be a hashref"
         unless ref $_[0] && ref $_[0] eq 'HASH';
      !_valid_logger($_[0]->{$_}) && die "\$loggers->{$_} does not point to a valid logger"
         for keys %{$_[0]};
   },
   default => sub { {} },
   init_arg => 'loggers',
);

sub add_logger {
   my ($self, $name, $logger) = @_;

   die "$name is not a valid logger" unless _valid_logger($logger);

   die "Logger $name is already in the list"
      if $self->_loggers->{$name};

   $self->_loggers->{$name} = $logger
}

sub remove_logger {
   my ($self, $name) = @_;

   die "unknown logger $name" unless $self->_loggers->{$name};

   delete $self->_loggers->{$name}
}

sub replace_logger {
   die "that is not a valid logger" unless _valid_logger($_[2]);

   $_[0]->_loggers->{$_[1]} = $_[2]
}

for my $method (@methods) {
   no strict 'refs';
   *{$method} = subname $method => sub {
      my $self = shift;

      $_->$method(@_) for
         map $self->_loggers->{$_},
         sort keys %{$self->_loggers};
   };
}

1;
