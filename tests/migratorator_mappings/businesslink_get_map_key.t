use strict;
use warnings;
use Test::More;
use Mappings::Businesslink;


my $test_url_parts = {
    scheme => '',
    host   => '',
    path   => '',
    query  => '',
    frag   => '',
};

$test_url_parts->{path}     = '/bdotg/action/layer';
$test_url_parts->{query}    = '=en&itemId=1081128808&lang=en&topicId=1081128739&type=RESOURCES';
my $result_key   = Mappings::Businesslink::get_map_key( undef, $test_url_parts );
is( 'layer.*topicId=1081128739', $result_key, "If a URL has both a topic id and an item id then use the topic id if it is a 'layer' URL" );

$test_url_parts->{path}     = '/bdotg/action/detail';
$test_url_parts->{query} = '=en&itemId=1081129545&lang=en&topicId=1081129016&type=RESOURCES';
$result_key   = Mappings::Businesslink::get_map_key( undef, $test_url_parts );
is( 'detail.*itemId=1081129545', $result_key, "If a URL has both a topic id and an item id then use the item id if it is a 'detail' URL" );

$test_url_parts->{path}     = '/bdotg/action/layer';
$test_url_parts->{query} = '=en&detail&itemId=1081128808&lang=en&topicId=1081128739&type=RESOURCES';
$result_key   = Mappings::Businesslink::get_map_key( undef, $test_url_parts );
is( 'layer.*topicId=1081128739', $result_key, "A 'layer' URL is determined by the start of the URL" );

$test_url_parts->{path}     = '/bdotg/action/detail';
$test_url_parts->{query} = '=en&layer&itemId=1081128808&lang=en&topicId=1081128739&type=RESOURCES';
$result_key   = Mappings::Businesslink::get_map_key( undef, $test_url_parts );
is( 'detail.*itemId=1081128808', $result_key, "A 'detail' URL is determined by the start of the URL" );

$test_url_parts->{path}     = '/bdotg/action/';
$test_url_parts->{query} = '=en&itemId=1081128808&lang=en&topicId=1081128739&type=RESOURCES';
$result_key   = Mappings::Businesslink::get_map_key( undef, $test_url_parts );
is( 'itemId=1081128808', $result_key, "If a URL has both a topic id and an item id and is not a 'layer' or 'detail' URL then use item id" );

$test_url_parts->{path}     = '/bdotg/action/layer';
$test_url_parts->{query} = 'topicId=1073858787';
$result_key   = Mappings::Businesslink::get_map_key( undef, $test_url_parts );
is( 'layer.*topicId=1073858787', $result_key, "If a URL has a topic id and no item Id then use the topic id" );

$test_url_parts->{path}     = '/bdotg/action/detail';
$test_url_parts->{query} = 'itemId=5002011861&type=ONEOFFPAGE';
$result_key   = Mappings::Businesslink::get_map_key( undef, $test_url_parts );
is( 'detail.*itemId=5002011861', $result_key, "If a URL has a item id and no topic id then use the item id" );

$test_url_parts->{path}     = '/bdotg/action/detail';
$test_url_parts->{query} = 'type=ONEOFFPAGE';
$result_key   = Mappings::Businesslink::get_map_key( undef, $test_url_parts );
is( undef, $result_key, "If a URL has no item id and no topic id then the map_key is undefined" );

done_testing();
