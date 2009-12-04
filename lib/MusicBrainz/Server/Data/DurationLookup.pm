package MusicBrainz::Server::Data::DurationLookup;
use Moose;
use Readonly;
use MusicBrainz::Server::Entity::DurationLookupResult;
use MusicBrainz::Server::Entity::Medium;

with 'MusicBrainz::Server::Data::ContextRole';

Readonly our $DIMENSIONS => 6;

sub _parse_toc
{
    my ($toc) = @_;

    defined($toc) or return;
    $toc =~ s/\A\s+//;
    $toc =~ s/\s+\z//;
    $toc =~ /\A\d+(?: \d+)*\z/ or return;

    my ($firsttrack, $lasttrack, $leadoutoffset, @trackoffsets)
        = split ' ', $toc;

    $firsttrack == 1 or return;
    $lasttrack >=1 and $lasttrack <= 99 or return;
    @trackoffsets == $lasttrack or return;

    for (($firsttrack + 1) .. $lasttrack)
    {
        $trackoffsets[$_-1] > $trackoffsets[$_-1-1]
            or return;
    }

    $leadoutoffset > $trackoffsets[-1]
        or return;

    return (
        toc             => $toc,
        tracks          => scalar @trackoffsets,
        firsttrack      => $firsttrack,
        lasttrack       => $lasttrack,
        leadoutoffset   => $leadoutoffset,
        trackoffsets    => \@trackoffsets,
    );
}

sub lookup
{
    my ($self, $toc, $fuzzy) = @_;

    $toc =~ s/\+/ /g;
    my %toc_info = _parse_toc($toc);
    return undef unless scalar(%toc_info);

    my @offsets = @{$toc_info{trackoffsets}};
    push @offsets, $toc_info{leadoutoffset};

    my (@durations, $i);
    for($i = 0; $i < $toc_info{tracks}; $i++)
    {
        push @durations, int((($offsets[$i + 1] - $offsets[$i]) * 1000) / 75);
    }

    my $dur_string = "'{" . join(",", @durations) . "}'";

    my $sql = Sql->new($self->c->mb->dbh);
    my $list = $sql->select_list_of_hashes(
            "SELECT ti.tracklist AS tracklist, 
                    cube_distance(toc, create_cube_from_durations($dur_string)) AS distance, 
                    m.id as medium,
                    release,
                    position,
                    format,
                    name,
                    editpending
               FROM tracklist_index ti, medium m 
              WHERE m.tracklist = ti.tracklist 
                AND tracks = ? 
                AND toc <@ create_bounding_cube($dur_string, ?) 
           ORDER BY distance", $toc_info{tracks}, $fuzzy);

    my @results;
    foreach my $item (@{$list})
    {
        my $result = MusicBrainz::Server::Entity::DurationLookupResult->new();
        $result->distance(int($item->{distance}));
        $result->medium_id($item->{medium});
        my $medium = MusicBrainz::Server::Entity::Medium->new();
        $medium->id($item->{medium});
        $medium->release_id($item->{release});
        $medium->tracklist_id($item->{tracklist});
        $medium->position($item->{position});
        $medium->format_id($item->{format});
        $medium->name($item->{name} or '');
        $medium->edits_pending($item->{editpending});
        $result->medium($medium);
        push @results, $result;
    }
    return \@results;
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;

=head1 COPYRIGHT

Copyright (C) 2009 Robert Kaye

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