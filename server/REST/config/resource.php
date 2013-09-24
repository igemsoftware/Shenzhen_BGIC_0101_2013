<?php

return array(
	'/example/(?<id>[0-9]+)' => 'example',
	'/example/foo/(?<name>[a-zA-Z_0-9]+)' => 'example/foo',
	'/stats/global' => 'stats/global',
	'/features/(?<dataset>\w+)' => 'features/searchFeaturesByLocation',
	'/stats/version/(?<dataset>\w+)' => 'stats/version',
	'/pathway/nav'	=> '/pathway/nav',
	'/decouple' => 'decouple',
	'/modify/Add' => 'modify/Add',
	'/Segmentation/globalREmarkup' => 'Segmentation/globalREmarkup',
	'/Segmentation/mega2chunk2mini' => 'Segmentation/mega2chunk2mini',
	'/Segmentation/whole2mega' => 'Segmentation/whole2mega',
	'/CodenOptimize'	=> 'CodenOptimize'
);
