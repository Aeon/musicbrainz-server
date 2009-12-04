package MusicBrainz::Server::Edit::WithDifferences;
use Moose;

use Match::Smart qw( smart_match );
use MusicBrainz::Server::Edit::Exceptions;
use MusicBrainz::Server::Data::Utils qw( deep_equal );
use Scalar::Util qw( reftype );
use Storable qw( freeze );

extends 'MusicBrainz::Server::Edit';

sub _mapping { }

sub _change_hash
{
    my ($self, $instance, @keys) = @_;
    my %mapping = $self->_mapping;
    my %old = map {
        my $mapped = exists $mapping{$_} ? $mapping{$_} : $_;
        $_ => ref $mapped eq 'CODE' ? $mapped->($instance) : $instance->$mapped;
    } @keys;
    return \%old;
}

sub _change_data {
    my ($self, $object, %opts) = @_;
    local $Storable::canonical = 1;

    my $old = $self->_change_hash($object, keys %opts);
    my $new = \%opts;
    for my $key (keys %$old) {
        my $n = $new->{$key};
        my $o = $old->{$key};
        my $equal;
        if (defined $n && defined $o) {
            $equal = (ref $o || ref $n)
                ? deep_equal($n, $o)
                : smart_match($n, $o);
        } elsif (!defined $n && !defined $o) {
            $equal = 1;
        }

        if ($equal) {
            delete $old->{$key};
            delete $new->{$key};
        }
    }

    MusicBrainz::Server::Edit::Exceptions::NoChanges->throw unless keys %$new && keys %$old;

    return (
        old => $old,
        new => $new
    );
};

1;