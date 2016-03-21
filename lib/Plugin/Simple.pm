package Plugin::Simple;
use 5.006;
use strict;
use warnings;

use Carp qw(croak);
use Data::Dumper;
use ExtUtils::Installed;
use Module::Load;

our $VERSION = '0.01';

my $self;

sub import {
    my ($class, %opts) = @_;

    my $pkg = (caller)[0];

    $self = __PACKAGE__->new(%opts);

    my $sub = sub {
        shift if ref $_[0] eq $pkg;

        my ($item, $can);

        if ($_[0] && $_[0] eq 'can'){
            shift;
            $can = shift;
        }
        else {
            $item = shift;
            shift;
            $can = shift;
        }

        if (@_){
            croak "usage: plugin(['Load::From'], [can => 'sub']), " .
                  "in that order\n";
        }
        my @plugins;

        if ($item){
            if (-e $item){
                @plugins = $self->_load($item);
            }
            else{ 
                @plugins = $self->_search($pkg, $item);
            }
        }
        if (! @plugins){    
            @plugins = _search($pkg);
        }

        my @wanted_plugins;

        if ($can){
            for (@plugins){
                if ($_->can($can)){
                    push @wanted_plugins, $_;
                }
            }
            return @wanted_plugins;
        }
        return @plugins;
    };

    my $sub_name = $opts{sub_name} ? $opts{sub_name} : 'plugins';

    {
        no warnings 'redefine';
        no strict 'refs';
        *{"$pkg\::$sub_name"} = $sub;
    }
}
sub _config {
    my ($self, %opts) = @_;
    for (keys %opts){
        $self->{$_} = $opts{$_};
    }
}
sub new {
    my ($class, %args) = @_;
    my $self = bless \%args, $class;

    return $self;
}
sub _cache {
    if ($self->{cache}){
        return @{ $self->{modules} } if $self->{modules};
    }

    my $inst = ExtUtils::Installed->new;
    @{ $self->{modules} } = $inst->modules;

    return @{ $self->{modules} };
}
sub _search {
    my ($self, $pkg, $item) = @_;

    my @modules = _cache();

    my @plugins;

    if ($item){
        @plugins = grep { $_ =~ /^$item/ } @modules;
    }
    else {
        my $path = $pkg;
        $path .= '::Plugin';
        @plugins = grep { $_ =~ /^$path/ } @modules;
    }

    my @loaded;

    for (@plugins){
        my $ok = $self->_load($_);
        push @loaded, $ok;
    }

    return @plugins;
}
sub _load {
    my ($self, $plugin) = @_;

    if ($plugin =~ /(.*)\W(\w+)\.pm/){
        unshift @INC, $1,
        $plugin = $2;
    }
    elsif ($plugin =~ /(?<!\W)(\w+)\.pm/){
        unshift @INC, '.';
        $plugin = $1;
    }

    my $loaded = eval { load $plugin; 1; };

    if ($loaded) {
        return $plugin;
    }
    else {
       warn "failed to load $plugin\n";
       return 0;
    }       
}
1;

=head1 NAME

Plugin::Simple - Load plugins from files or modules.

=head1 SYNOPSIS

    use Plugin::Simple;

    # load a plugin module from a file

    @plugins = plugins('/path/to/MyModule.pm');

    # load all modules under '__PACKAGE__::Plugin' namespace

    my @plugins = plugins();

    # load all plugins under a specific namespace

    @plugins = plugins('Any::Namespace');

    # load a plugin module from a file

    @plugins = plugins('/path/to/MyModule.pm');

    # load/return only the plugins that has a specific function

    @plugins = plugins(can => 'foo');

    # instead of importing 'plugins()', change the name:

    use Simple::Plugin sub_name => 'blah';
    @plugins = blah(...);

=head1 DESCRIPTION

There are many plugin modules available on the CPAN, but I wrote this one just
for fun. It's very simple, extremely lightweight (core only), and is extremely
minimalistic in what it does.

It searches for modules in installed packages or non-installed files, and loads
them (without string C<eval>). You can optionally have us return only the
plugins that C<can()> perform a specific task.

=head1 FUNCTIONS/METHODS

None. We simply install a C<plugin()> function within the namespace of the
package that C<use>d us. To specify a different sub name, use this module as
such: C<use Plugin::Simple sub_name => 'name_of_sub';>.

=head1 AUTHOR

Steve Bertrand, C<< <steveb at cpan.org> >>

=head2 CONTRIBUTING

Any and all feedback and help is appreciated. A Pull Request is the preferred
method of receiving changes (L<https://github.com/stevieb9/p5-plugin-simple>),
but regular patches through the bug tracker, or even just email discussions are
welcomed.

=head1 BUGS

L<https://github.com/stevieb9/p5-plugin-simple/issues>

=head1 SUPPORT

You can find documentation for this script and module with the perldoc command.

    perldoc Plugin::Simple;

=head1 SEE ALSO

There are far too many plugin import modules on the CPAN to mention here.

=head1 LICENSE AND COPYRIGHT

Copyright 2016 Steve Bertrand.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.

