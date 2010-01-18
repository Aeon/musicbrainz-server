package MusicBrainz::Server::Controller::Test;
use Moose;

BEGIN { extends 'Catalyst::Controller' }

use DBDefs;

sub auto : Private
{
    my ($self, $c) = @_;
    unless (DBDefs::DB_STAGING_SERVER()) {
        $c->forward('/error_404');
        return 0;
    }
}

sub accept_edit : Path('/test/accept-edit') Args(1)
{
    my ($self, $c, $edit_id) = @_;

    my $edit = $c->model('Edit')->get_by_id($edit_id)
        or $c->detach('/error_404');

    _accept_edit($c, $edit);
    $c->response->redirect($c->request->referer);
}

sub reject_edit : Path('/test/reject-edit') Args(1)
{
    my ($self, $c, $edit_id) = @_;
    my $edit = $c->model('Edit')->get_by_id($edit_id)
        or $c->detach('/error_404');

    _reject_edit($c, $edit);
    $c->response->redirect($c->request->referer);
}

sub _accept_edit
{
    my ($c, $edit) = @_;

    my $sql = Sql->new($c->dbh);
    my $raw_sql = Sql->new($c->raw_dbh);
    Sql::run_in_transaction( sub { $c->model('Edit')->accept($edit) }, $sql, $raw_sql );
}

sub _reject_edit
{
    my ($c, $edit) = @_;

    my $sql = Sql->new($c->dbh);
    my $raw_sql = Sql->new($c->raw_dbh);
    Sql::run_in_transaction( sub { $c->model('Edit')->reject($edit) }, $sql, $raw_sql );
}

__PACKAGE__->meta->make_immutable;
no Moose;

1;