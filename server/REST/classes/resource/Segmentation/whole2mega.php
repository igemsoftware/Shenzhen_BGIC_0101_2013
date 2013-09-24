<?php

class Resource_Segmentation_whole2mega extends Resource
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
			$ol = isset($data['ol'])? $data['ol']:1000;
			//chdir("../server");
			$output = "01.whole2mega";
			$cmd = "perl server/bin/segmentation/01.whole2mega.pl \
						--gff $gff\
						--fa  $fa\
						-ol $ol\
						-ck 30000\
						-m1 server/config/marker/LEU2.gff\
						-m2 server/config/marker/URA3.gff\
						-ot {$dataUrl}{$output} 2>&1";

			exec($cmd, $result);
			$this->_data = $result;
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
