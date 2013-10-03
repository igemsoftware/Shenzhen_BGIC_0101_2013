<?php

class Resource_Segmentation_info extends Resource
{


	public function get()
	{

		$data = $this->get_data();
		$TopDir = "../../";
		if (isset($data['baseUrl']) || isset($data['dataset'])) {
			chdir($TopDir);
			$dataUrl = $data['baseUrl'];
			$dataUrl = rtrim($dataUrl, "/")."/";
			exec("ls {$dataUrl}*.gff", $gff);
			$gff = $gff[0];
			exec("ls {$dataUrl}*.fa", $fa);
			$fa = $fa[0];
			exec("ls {$dataUrl}", $dir);
			$result = array();
			if (in_array("01.whole2mega", $dir)) {
				exec("ls {$dataUrl}01.whole2mega/*.json", $megajson);
					if (!empty($megajson)) {
						$megajson = json_decode(file_get_contents($megajson[0]));
						$result['mega'] = $megajson;
					}
			}
			if (in_array("02.globalREmarkup", $dir)) {
				exec("ls {$dataUrl}02.globalREmarkup/*", $markup);
				$result['markup'] = $markup;
			}
			if (in_array("03.mega2chunk2mini", $dir)) {
				exec("ls {$dataUrl}03.mega2chunk2mini/*", $mini);
				$result['mini'] = $mini;
			}

			if (in_array("chip_data", $dir)) {
				exec("ls {$dataUrl}chip_data/*", $chipjson);
				$result['chip'] = $chipjson;
			}


			$this->_data = $result;
		} else {
			$this->_data = "unknow sequence name";
		}
	}

	public function post()
	{
		$this->_data = array_merge($this->get_data(), array('type' => 'post'));
	}
}
