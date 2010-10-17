package Plack::Middleware::Watermark;

use strict;
use warnings;

our $VERSION = '0.01';

use parent qw( Plack::Middleware );
use Plack::Util::Accessor qw( comment );

use Plack::Util;
use Carp ();

sub prepare_app {
    my $self = shift;

    unless ($self->comment) {
        Carp::croak "'comment' is not defined";
    }
}

my %comment_style = (
    'html' => [ '<!--', '-->' ],
    'xml'  => [ '<!--', '-->' ],
    'css'  => [ '/*', '*/' ],
    'js'   => [ '//', '' ],
);

my %mime_type = (
    # html
    'text/html'             => 'html',
    'application/xhtml+xml' => 'html',
    # xml
    'text/xml'             => 'xml',
    'application/xml'      => 'xml',
    'application/rss+xml'  => 'xml',
    'application/atom+xml' => 'xml',
    # css
    'text/css' => 'css',
    # js
    'text/javascript'        => 'js',
    'application/javascript' => 'js',
);

sub call {
    my $self  = shift;
    my ($env) = @_;

    my $res = $self->app->($env);
    $self->response_cb($res, sub {
        my $res  = shift;
        my $type = Plack::Util::header_get($res->[1], 'Content-Type');
        if ($type && $res->[0] == 200) {
            ($type) = split /;\s*/, $type;
            my ($start, $stop) = @{ $comment_style{$mime_type{$type}||''} || [] };
            if ($start or $stop) {
                return sub {
                    my $chunk = shift;
                    return unless defined $chunk;
                    my $comment = ref $self->comment eq 'CODE' ? $self->comment->($env) : $self->comment;
                    $chunk .= join ' ', $start, $comment, $stop;
                    return $chunk;
                };
            }
        }
    });
}

1;
__END__

=pod

=head1 NAME

Plack::Middleware::Watermark - Add watermark to response body

=head1 SYNOPSIS

  use Plack::Builder;
  my $app = sub {
      [ 200, [ 'Content-Type' => 'text/html' ], [ "Hello World\n" ] ]
  };
  builder {
      enable 'Watermark', comment => 'generated on my server';
      $app;
  }

  # Hello World
  # <!-- generated on my server -->

=head1 DESCRIPTION

The watermark middleware offers appending some string to response body as comment.

=head1 OPTIONS

=head2 comment

Specify comment string or subroutine returning some string.

  builder {
      enable 'Watermark', comment => sub { 'Generated by ' . Sys::Hostname::hostname };
      $app;
  }

=head1 AUTHOR

Hiroshi Sakai E<lt>ziguzagu@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 2010 Six Apart, Ltd. All rights reserved.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut