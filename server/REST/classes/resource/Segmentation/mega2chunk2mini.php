<?php

class Resource_Segmentation_mega2chunk2mini extends Resource
{

	public function get()
	{

		$data = $this->get_data();
		$TopDir = "../../";
		//return;

		if (isset($data['baseUrl'])) {
			chdir($TopDir);
			$dataUrl = $data['baseUrl'];
			$dataUrl = rtrim($dataUrl, "/")."/";
			exec("ls {$dataUrl}*.gff", $gff);
			$gff = $gff[0];
			exec("ls {$dataUrl}*.fa", $fa);
			$fa = $fa[0];
			$re = isset($data['re']) ? $data['re']:"standard_and_IIB";
			//chdir("../server");
			$sg = isset($data['sg'])? $data['sg']:"03.mega2chunk2mini";
			$ps = isset($data['ps'])? $data['ps']:"03.mega2chunk2mini";
			$cmd = "perl server/bin/segmentation/03.mega2chunk2mini.pl"
					."	-re server/config/globalREmarkup/{$re} "
					."	-sg {$sg}"
					."	-ps {$ps}"
					."	-ot {$dataUrl}03.mega2chunk2mini 2>&1";

			exec($cmd, $result);
			$this->_data = $cmd;
			chdir($dataUrl);
			exec("git add .");
			exec('git commit -m "03.mega2chunk2mini created"');
			//TODO Move $output/sce_chr01_0.mega 

		} else {
			$this->_data = "unknow sequence name";
		}
	}

	public function post()
	{
		$this->_data = array_merge($this->get_data(), array('type' => 'post'));
	}
}
