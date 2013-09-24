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
			$ol = isset($data['ol']) ? $data['ol']:1000;
			//chdir("../server");
			$output = isset($data['ot'])? $data['ot']:"03.mega2chunk2mini";
			$cmd = "perl server/bin/03.mega2chunk2mini.pl \
						-re server/config/globalREmarkup/standard_and_IIB\
						-sg 01.whole2mega/sce_chr01_0.mega\
						-ps 02.globalREmarkup/sce_chr01_0.parse
						-ot server/tmp_data/{$output}";

			exec($cmd, $result);

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
