use Test::More tests => 2;
use strict;
use warnings;

# the order is important
use EthURL;
use Dancer::Test;

route_exists [GET => '/:id'], 'a route handler is defined for /:id';
route_exists [GET => '/add'], 'a route handler is defined for /add';
