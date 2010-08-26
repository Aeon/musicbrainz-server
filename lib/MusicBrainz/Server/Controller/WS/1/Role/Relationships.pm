package MusicBrainz::Server::Controller::WS::1::Role::Relationships;
use Moose::Role;

before 'lookup' => sub {
    my ($self, $c) = @_;

    return unless ($c->stash->{inc}->has_rels);

    my $entity = $c->stash->{entity};

    my $types = $c->stash->{inc}->get_rel_types;

    my @rels = $c->model('Relationship')->load_subset($types, $entity);
    my @releases;
    for my $relationship (@{$entity->relationships}) {
        if ($relationship->target->isa('MusicBrainz::Server::Entity::Release')) {
            push @releases, $relationship->target;
        }
    }

    # We need to be able to display the release type
    $c->model('ReleaseGroup')->load(@releases);
    $c->model('ReleaseGroupType')->load(map { $_->release_group } @releases);
    $c->model('ReleaseStatus')->load(@releases);
    $c->model('Language')->load(@releases);
    $c->model('Script')->load(@releases);
};

1;