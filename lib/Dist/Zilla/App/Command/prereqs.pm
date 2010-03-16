use 5.008;
use strict;
use warnings;

package Dist::Zilla::App::Command::prereqs;

# ABSTRACT: print your distribution's prerequisites
use Dist::Zilla::App -command;
use Moose::Autobox;
use Capture::Tiny 'capture';
sub abstract { "print your distribution's prerequisites" }

sub execute {
    my ($self, $opt, $arg) = @_;
    capture {
        $_->before_build for $self->zilla->plugins_with(-BeforeBuild)->flatten;
        $_->gather_files for $self->zilla->plugins_with(-FileGatherer)->flatten;
        $_->prune_files  for $self->zilla->plugins_with(-FilePruner)->flatten;
        $_->munge_files  for $self->zilla->plugins_with(-FileMunger)->flatten;
        for my $plugin ($self->zilla->plugins_with(-FixedPrereqs)->flatten) {
            my $prereq = $plugin->prereq;
            $self->zilla->register_prereqs($_ => $prereq->{$_}) for keys %$prereq;
        }
    };
    my $prereq = $self->zilla->prereq->as_distmeta;
    my %req;
    for (qw(requires build_requires configure_requires)) {
        $req{$_}++ for keys %{ $prereq->{$_} || {} };
    }
    delete $req{perl};
    print map { "$_\n" } sort keys %req;
}
1;

=pod

=head1 SYNOPSIS

    # dzil prereqs | xargs cpanm

=head1 DESCRIPTION

This is a command plugin for L<Dist::Zilla>. It provides the C<prereqs>
command, which prints your distribution's prerequisites. You could use that
list to pipe it into L<cpanm> - see L<App::cpanminus>.

