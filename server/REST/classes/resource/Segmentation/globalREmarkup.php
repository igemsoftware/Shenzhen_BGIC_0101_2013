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
			$sg = isset($data['sg'])?$data['sg']:"01.whole2mega/sce_chr01_0.mega"
			//chdir("../server");
			$output = isset($data['ot'])? $data['sg']: "02.globalREmarkup";
			$cmd = "perl server/bin/segmentation/02.globalREmarkup.pl \
						-sg $sg\
						-re server/config/globalREmarkup/standard_and_IIB\
						-ct server/config/globalREmarkup/standard.ct\
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
