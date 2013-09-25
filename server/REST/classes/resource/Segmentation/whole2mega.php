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
			$ck = isset($data['ck']) ? $data['ck']:30000;
			//chdir("../server");
			$output = "01.whole2mega";
			$cmd = "perl server/bin/segmentation/01.whole2mega.pl"
						." --gff $gff"
						." --fa  $fa"
						." -ol $ol"
						." -ck $ck"
						." -m1 server/config/markers/LEU2.gff"
						." -m2 server/config/markers/URA3.gff"
						." -m3 server/config/markers/HIS3.gff"
						." -m4 server/config/markers/TRP1.gff"
						." -ot {$dataUrl}{$output} 2>&1";
			$this->_data  = $cmd;
			//return;
			exec($cmd, $result);

			$this->_data = $result;
			chdir($dataUrl);
			exec("git add .");
			exec('git commit -m "01.whole2mega created"');
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
