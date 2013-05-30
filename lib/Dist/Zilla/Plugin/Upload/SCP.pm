use 5.008001;
use strict;
use warnings;

package Dist::Zilla::Plugin::Upload::SCP;
# ABSTRACT: Dist::Zilla release plugin to upload via scp
# VERSION

use autodie 2.00;
use Moose;
use MooseX::Types::Moose qw/Str Bool/;
use MooseX::Types::Path::Tiny qw/Path/;
use Net::OpenSSH 0.60;
use Path::Tiny;

use namespace::autoclean;

with 'Dist::Zilla::Role::Releaser';

=attr connection (required)

An ssh connection string, either C<host> or C<user@host> or anything else L<Net::OpenSSH>
supports as a C<host> parameter.

=cut

has connection => (
    is => 'ro',
    isa => Str,
    required => 1,
);

=attr directory (required)

Remote directory to receive the upload.

=cut

has directory => (
    is => 'ro',
    isa => Path,
    required => 1,
);

=attr clobber

Boolean for whether an existing destination path should be clobbered.
Defaults to false.

=cut

has clobber => (
    is => 'ro',
    isa => Bool,
    default => 0,
);

has _ssh => (
    is => 'ro',
    isa => 'Net::OpenSSH',
    lazy_build => 1,
);

sub _build__ssh {
    my $self = shift;
    my $ssh = Net::OpenSSH->new($self->connection);
    $self->log_fatal("Couldn't establish an ssh connection: " . $ssh->error)
        if $ssh->error;
    return $ssh;
}

sub release {
    my ( $self, $archive ) = @_;
    my $ssh = $self->_ssh;

    my $destination = $self->directory->child(path($archive)->basename);

    if ( $ssh->test("/bin/ls", $destination) && ! $self->clobber ) {
        $self->log_fatal("Destination file $destination exists.  Halting!");
    }
        
    $ssh->scp_put($archive, $destination)
        or $self->log_fatal("Error uploading: " . $ssh->error);

    $self->log( "$archive uploaded to " . join(":", $self->connection, $destination) );

    return;
}

__PACKAGE__->meta->make_immutable();
1;

=for Pod::Coverage release

=head1 SYNOPSIS

  [Upload::SCP]
  connection = david@example.com
  directory = public_html

=head1 DESCRIPTION

This module uploads a distribution tarball to a remote host via scp on release.

It does not manage passwords.  You can put that in your connection string if you're nuts,
but you really should use an SSH key and C<ssh-agent>.

=head1 SEE ALSO

=for :list
* L<Dist::Zilla::Plugin::UploadToSFTP> -- very similar but allows you to set passwords via F<.netrc>

=cut

# vim: ts=4 sts=4 sw=4 et:
