package MusicBrainz::Server::EditRegistry;

require UNIVERSAL::require;

our %_types;
our $_registered = 0;

my @CLASSES = qw(
    MusicBrainz::Server::Edit::Artist::AddAnnotation
    MusicBrainz::Server::Edit::Artist::Create
    MusicBrainz::Server::Edit::Artist::Delete
    MusicBrainz::Server::Edit::Artist::Edit
    MusicBrainz::Server::Edit::Artist::Merge
    MusicBrainz::Server::Edit::Label::AddAnnotation
    MusicBrainz::Server::Edit::Label::Create
    MusicBrainz::Server::Edit::Label::Delete
    MusicBrainz::Server::Edit::Label::Edit
    MusicBrainz::Server::Edit::Label::Merge
    MusicBrainz::Server::Edit::Medium::Create
    MusicBrainz::Server::Edit::Medium::Edit
    MusicBrainz::Server::Edit::Recording::AddAnnotation
    MusicBrainz::Server::Edit::Relationship::Edit
    MusicBrainz::Server::Edit::Relationship::Delete
    MusicBrainz::Server::Edit::Release::AddAnnotation
    MusicBrainz::Server::Edit::Release::DeleteReleaseLabel
    MusicBrainz::Server::Edit::Release::Edit
    MusicBrainz::Server::Edit::Release::EditReleaseLabel
    MusicBrainz::Server::Edit::ReleaseGroup::AddAnnotation
    MusicBrainz::Server::Edit::ReleaseGroup::Delete
    MusicBrainz::Server::Edit::ReleaseGroup::Edit
    MusicBrainz::Server::Edit::ReleaseGroup::Merge
    MusicBrainz::Server::Edit::Track::Edit
    MusicBrainz::Server::Edit::Tracklist::AddTrack
    MusicBrainz::Server::Edit::Tracklist::DeleteTrack
    MusicBrainz::Server::Edit::WikiDoc::Change
    MusicBrainz::Server::Edit::Work::AddAnnotation
    MusicBrainz::Server::Edit::Work::Edit
);

sub register_type
{
    my ($class, $edit_class, $overwrite) = @_;
    _register_default_types() unless $_registered;
    $class->_register_type($edit_class, $overwrite);
}

sub class_from_type
{
    my ($class, $type) = @_;
    _register_default_types() unless $_registered;
    return $_types{$type};
}

sub get_all_types
{
    _register_default_types() unless $_registered;
    return keys %_types;
}

sub get_all_classes
{
    _register_default_types() unless $_registered;
    return values %_types;
}

sub _register_type
{
    my ($class, $edit_class, $overwrite) = @_;
    my $type = $edit_class->edit_type;
    warn "Type $type already registered" if exists $_types{$type} && !$overwrite;
    $_types{$type} = $edit_class;
}

sub _register_default_types
{
    foreach my $class (@CLASSES) {
        $class->require or die $@;
        _register_type(undef, $class);
    }
    $_registered = 1;
}

no Moose;
1;

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