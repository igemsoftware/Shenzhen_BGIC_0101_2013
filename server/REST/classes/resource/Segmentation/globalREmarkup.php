<?php

class Resource_Segmentation_globalREmarkup extends Resource
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
			// NEED FILE NAME
			$sg = isset($data['sg'])?$data['sg']:"01.whole2mega/sce_chr01_0.mega";
			//chdir("../server");
			///$output = isset($data['ot'])? $data['sg']: "02.globalREmarkup";
			$re = isset($data['re'])?$data['re']:"02.globalREmarkup";
			$ct = isset($data['ct'])?$data['ct']:"server/config/globalREmarkup/standard.ct";
			$cmd = "perl server/bin/segmentation/02.globalREmarkup.pl \
						-sg $sg\
						-re server/config/globalREmarkup/$re\
						-ct server/config/globalREmarkup/$ct \
						-ot {$dataUrl}02.globalREmarkup";

			exec($cmd, $result);
			$this->_data = $cmd;
			chdir($dataUrl);
			exec("git add .");
			exec('git commit -m "02.globalREmarkup created"');
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
