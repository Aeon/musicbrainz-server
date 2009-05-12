package MusicBrainz::Server::Data::ReleaseLabel;

use Moose;
use MusicBrainz::Server::Entity::ReleaseLabel;
use MusicBrainz::Server::Data::Utils qw( query_to_list placeholders );

extends 'MusicBrainz::Server::Data::Entity';

sub _table
{
    return 'release_label';
}

sub _columns
{
    return 'id, release AS release_id, label AS label_id, ' .
           'catno AS catalog_number, position';
}

sub _entity_class
{
    return 'MusicBrainz::Server::Entity::ReleaseLabel';
}

sub load
{
    my ($self, @releases) = @_;
    my %id_to_release = map { $_->id => $_ } @releases;
    my @ids = keys %id_to_release;
    my $query = "SELECT " . $self->_columns . "
                 FROM " . $self->_table . "
                 WHERE release IN (" . placeholders(@ids) . ")
                 ORDER BY release, position";
    my @labels = query_to_list($self->c, sub { $self->_new_from_row(@_) },
                               $query, @ids);
    foreach my $label (@labels) {
        $id_to_release{$label->release_id}->add_label($label);
    }
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;

=head1 NAME

MusicBrainz::Server::Data::ReleaseLabel

=head1 METHODS

=head2 loads (@releases)

Loads and sets labels for the specified releases. The data can be then
accessed using $release->labels.

=head1 COPYRIGHT

Copyright (C) 2009 Lukas Lalinsky

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.

=cut