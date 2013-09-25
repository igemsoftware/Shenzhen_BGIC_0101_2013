<?php

class Resource_features_searchFeaturesByLocation extends Resource
{

	public function getArray($track, $class) {
			$trackqueue = array();
			$result = array();
			for ($i=0; $i < count($track); ++$i) {
				$arr = array();
				$tracktype = $class[$track[$i][0]]['attributes'];

				$counttrack = count($track[$i]);
				for ($j = 1; $j < count($track[$i]); ++$j) {
					if (isset($tracktype[$j-1]) && isset($track[$i])) {
						if ($tracktype[$j-1] == "Subfeatures") {
							$arr['SubFeatures'] = $this->getArray($track[$i][$j], $class);
						} else {
							$arr[$tracktype[$j-1]] = $track[$i][$j];
						}
					}
				}
				array_push($result, $arr);
			}
			return $result;
	}


	public function get()
	{

		$data = $this->get_data();
		$TopDir = "../../";
		//return;

		if (isset($data['baseUrl']) && isset($data['refseq'])) {
			chmod("$TopDir");
			$seqname = $data['refseq'];
			$url = $data['baseUrl'];
			$trackList = json_decode(file_get_contents($url."trackList.json"), true)['tracks'][1];
		
			$template = str_replace( "{refseq}", $seqname, $trackList['urlTemplate']);
		
			$trackData = json_decode(file_get_contents($url.$template), true)['intervals'];
			$trackClass = $trackData['classes'];
			$trackNCList = $trackData['nclist'];
			$this->_data = $trackClass;
			//return;
			$result = $this->getArray($trackNCList, $trackClass);
			$count = count($result);
			if (isset($data['start'])) {
				$start = $data['start'];
				for ($i = $count-1; $i >= 0; $i--) {
					if ($result[$i]["End"] < $start) {
						unset($result[$i]);
					}
				}
			}
			if (isset($data['end'])) {
				$end = $data['end'];
				for ($i = $count-1; $i >= 0; $i--) {
					if (isset($result[$i]) && $result[$i]["Start"] > $end) {
						unset($result[$i]);
					}
				}
			}

			$tmp = array();
			for ($i = 0; $i < $count; ++$i) {
				if (isset($result[$i])) {
					array_push($tmp, $result[$i]);
				}
			}

			$this->_data = $tmp;

		} else {
			$this->_data = "unknow sequence name";
		}
	}

	public function post()
	{
		$this->_data = array_merge($this->get_data(), array('type' => 'post'));
	}
}
