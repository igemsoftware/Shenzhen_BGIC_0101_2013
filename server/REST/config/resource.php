<?php

return array(
	'/example/(?<id>[0-9]+)' => 'example',
	'/example/foo/(?<name>[a-zA-Z_0-9]+)' => 'example/foo',
	'/stats/global' => 'stats/global',
	'/features/(?<refseq_name>\w+)' => 'features/searchFeaturesByLocation'
);
