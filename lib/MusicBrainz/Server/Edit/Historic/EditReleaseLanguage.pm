package MusicBrainz::Server::Edit::Historic::EditReleaseLanguage;
use Moose;
use MooseX::Types::Structured qw( Dict );
use MooseX::Types::Moose qw( ArrayRef Int Str );

use MusicBrainz::Server::Constants qw( $EDIT_HISTORIC_EDIT_RELEASE_LANGUAGE );
use MusicBrainz::Server::Edit::Types qw( Nullable );

use aliased 'MusicBrainz::Server::Entity::Release';

extends 'MusicBrainz::Server::Edit::Historic';

sub edit_name     { 'Edit release language' }
sub historic_type { 44 }
sub edit_type     { $EDIT_HISTORIC_EDIT_RELEASE_LANGUAGE }

sub related_entities
{
    my $self = shift;
    return {
        release => [ map { @{ $_->{release_ids} } } @{ $self->data->{old} } ]
    }
}

has '+data' => (
    isa => Dict[
        language_id => Nullable[Int],
        script_id   => Nullable[Int],
        old         => ArrayRef[Dict[
            release_ids  => ArrayRef[Int],
            language_id  => Nullable[Int],
            script_id    => Nullable[Int],
            release_name => Str,
        ]],
    ]
);

sub foreign_keys
{
    my $self = shift;
    return {
        Release => { map {
            map { $_ => ['ArtistCredit'] } @{ $_->{release_ids} }
        } @{ $self->data->{old} } },
        Language => [
            $self->data->{language_id},
            map { $_->{language_id} } @{ $self->data->{old} }
        ],
        Script => [
            $self->data->{script_id},
            map { $_->{script_id} } @{ $self->data->{old} }
        ]
    }
}

sub build_display_data
{
    my ($self, $loaded) = @_;
    return {
        old => [
            map {
                my $release_name = $_->{release_name};
                +{
                    language => $loaded->{Language}{ $_->{language_id} },
                    script   => $loaded->{Script}{ $_->{script_id} },
                    releases => [
                        map {
                            $loaded->{Release}{ $_ } ||
                                Release->new(name => $release_name)
                        } @{ $_->{release_ids} }
                    ]
                }
            } @{ $self->data->{old} }
        ],
        language => $loaded->{Language}->{ $self->data->{language_id} },
        script   => $loaded->{Script}->{ $self->data->{script_id} },
    }
}

sub upgrade
{
    my $self = shift;

    my @old;
    for (my $i = 0;; $i++)
    {
        my $album_id = $self->new_value->{"AlbumId$i"}
            or last;
        my ($language_id, $script_id) = split /,/, $self->new_value->{"Prev$i"};

        push @old, {
            release_ids  => $self->album_release_ids($album_id),
            language_id  => $language_id,
            script_id    => $script_id,
            release_name => $self->new_value->{"AlbumName$i"}
        }
    }

    my ($language_id, $script_id) = split /,/, $self->new_value->{Language};
    $self->data({
        language_id => $language_id,
        script_id   => $script_id,
        old => \@old
    });

    return $self;
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;