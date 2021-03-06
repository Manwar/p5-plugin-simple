#!/usr/bin/perl
use strict;
use warnings;

use File::Copy;
use Plugin::Simple cache => 1;
use Test::More;

my $file = 't/base/Testing.pm';

{ # can't load plugin
    my $ret = plugins('blah.pm');
    is ($ret, undef, "if plugin can't be loaded, ok");
}
{ # file
    my @plugins = plugins($file);
    is (@plugins, 1, "with file, got the correct number of plugins");
    is ($plugins[0], 'Testing', "...and the plugin name is ok");
    is ($plugins[0]->hello(), 'hello, world!', "...and the sub output ok");
}
{ # scalar context
    my $plugin = plugins($file);
    is ($plugin, 'Testing', "...return is ok in scalar context");
    is ($plugin->hello(), 'hello, world!', "...and the sub output ok");
}

SKIP: { # module test
    my @ret = plugins('DateTime');

    skip 'test mod not installed', 2, unless defined $INC{'DateTime.pm'};
    ok (@ret >= 1, "with an example item, things appear ok");
    is ($ret[0], 'DateTime', 'returned plugin is correct');
    can_ok('DateTime', 'new');
};
{ # can param bad
    my @plugins = plugins($file, can => ['blah']);
    is (@plugins, 0, "if plugin can()t, it isn't returned");
}
{ # can param good
    my @plugins = plugins($file, can => ['hello']);
    is (@plugins, 1, "if plugin can(), it's returned");
}
{ # can with multiple options
    my @plugins = plugins($file, can => ['hello', 'goodbye']);
    is (@plugins, 1, "if plugin can() multiple, it's returned");
}
{ # can w/o item
    my @plugins = plugins(can => ['hello']);
    is (@plugins, 0, "'can' can be sent in without item");
}
{ # can with wrong prototype
    my $ok = eval { plugins(can => ['hello'], 'this'); 1; };
    ok (! $ok, "with wrong order of params, plugins() croaks");
}
{ # file in cwd
    copy 't/base/Testing.pm', '.';

    my @plugins = plugins('Testing.pm');
    is (@plugins, 1, "plugin file in cwd works ok");
    ok ($plugins[0]->can('hello'),"file in cwd plugin can ok");

    unlink 'Testing.pm';
    ok (! -e 'Testing.pm', "unlinked file ok");
}


done_testing;
