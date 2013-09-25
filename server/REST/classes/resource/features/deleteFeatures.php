<?php

class Resource_features_deleteFeatures extends Resource
{

	public function get()
	{

		$data = $this->get_data();
		$TopDir = "../../";
		//return;

		if (isset($data['baseUrl']) && isset($data['dataset'])) {
			chdir($TopDir);
			$dataUrl = $data['baseUrl'];
			$dataset = $data['dataset'];
		
			$dataUrl = rtrim($dataUrl, "/")."/";
			//$this->_data = "ls {$dataUrl}*.gff";
			//return;
			exec("ls {$dataUrl}*.gff", $gff);
			$gff = $gff[0];
			exec("ls {$dataUrl}*.fa", $fa);
			$fa = $fa[0];

			$cmd = "perl server/bin/05.delete.pl"
						." --delete='{$data['features']}'"
						." --neochr_gff $gff"
						." --neochr_fa  $fa"
						." --slim_fa server/tmp_data/{$dataset}_delete.fa"
						." --slim_gff server/tmp_data/{$dataset}_delete.gff";
			exec($cmd, $result);
			//$this->_data = $cmd;
			///return;
			exec("php server/bin/loadfile.php"
					." {$dataset}_delete data/{$dataset}_delete/"
					." server/tmp_data/ server/default_track_conf.json 2>&1", $result);
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
