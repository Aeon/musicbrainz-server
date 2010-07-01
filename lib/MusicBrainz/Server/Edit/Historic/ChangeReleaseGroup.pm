package MusicBrainz::Server::Edit::Historic::ChangeReleaseGroup;
use Moose;
use MooseX::Types::Structured qw( Dict );
use MooseX::Types::Moose qw( ArrayRef Int );
use MusicBrainz::Server::Constants qw( $EDIT_HISTORIC_CHANGE_RELEASE_GROUP );

extends 'MusicBrainz::Server::Edit::Historic';
with 'MusicBrainz::Server::Edit::Historic::NoSerialization';

sub edit_name     { 'Change release group' }
sub edit_type     { $EDIT_HISTORIC_CHANGE_RELEASE_GROUP }
sub historic_type { 73 }

sub change_fields
{
    return Dict[release_group_id => Int];
}

has '+data' => (
    isa => Dict[
        release_ids => ArrayRef[Int],
        old => change_fields(),
        new => change_fields(),
    ]
);

sub _release_group_ids
{
    my $self = shift;
    map { $self->data->{$_}{release_group_id} } qw( old new )
}

sub related_entities
{
    my $self = shift;
    return {
        release_group => [
            $self->_release_group_ids
        ],
        release       => $self->data->{release_ids}
    }
}

sub foreign_keys
{
    my $self = shift;
    return {
        Release      => $self->data->{release_ids},
        ReleaseGroup => [ $self->_release_group_ids ],
    }
}

sub build_display_data
{
    my ($self, $loaded) = @_;

    return {
        releases => [
            map {
                $loaded->{Release}{$_}
            } @{ $self->data->{release_ids} }
        ],
        release_group => {
            old => $loaded->{ReleaseGroup}{ $self->data->{old}{release_group_id} },
            new => $loaded->{ReleaseGroup}{ $self->data->{new}{release_group_id} },
        }
    }
}

sub upgrade
{
    my $self = shift;

    $self->data({
        release_ids => $self->album_release_ids($self->row_id),
        old         => { release_group_id => $self->previous_value },
        new         => { release_group_id => $self->new_value },
    });

    return $self;
}

no Moose;
__PACKAGE__->meta->make_immutable;