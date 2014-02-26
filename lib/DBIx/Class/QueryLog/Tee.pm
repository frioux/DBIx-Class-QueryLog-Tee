package DBIx::Class::QueryLog::Tee;

use Moo;
use warnings NONFATAL => 'all';

use Sub::Name 'subname';
use namespace::clean;

has _loggers => (
   is => 'ro',
   init_arg => 'loggers',
);

sub add_logger {
   my ($self, $name, $logger) = @_;

   die "Logger $name is already in the list"
      if $self->_loggers->{$name};

   $self->_loggers->{$name} = $logger
}

sub remove_logger {
   my ($self, $name) = @_;

   die "unknown logger $name" unless $self->_loggers->{$name};

   delete $self->_loggers->{$name}
}

sub replace_logger { $_[0]->_loggers->{$_[1]} = $_[2] }

my @methods = qw(
   txn_begin txn_commit txn_rollback
   svp_begin svp_release svp_rollback
   query_start query_end
);
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
