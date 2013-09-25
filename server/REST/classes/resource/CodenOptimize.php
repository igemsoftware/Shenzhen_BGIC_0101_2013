<?php

class Resource_CodenOptimize extends Resource
{

	public function get()
	{

		$data = $this->get_data();
		$TopDir = "../../";
		
		if (isset($data['baseUrl']) && isset($data['dataset'])) {
			if (!isset($data['step']['1']) && !isset($data['step']['2'])) {
				$this->_data = array("err"=>"no step targeted");
				return;
			}
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
			
			if (isset($data['step']['1']) && isset($data['step']['2'])) {
				$step = "23467";
			} else if ( isset( $data['step']['1']) ){
				$step = "23";
			} else if ( isset( $data['step']['2']) ) {
				$step = "2467";
			}	
			$cmd = "perl server/bin/sequence_modificationV1.pl"
						." $fa -step $step -genegff $gff"
						." -genelist server/config/Optimize/gene_list"
						." -codonoptimize server/config/Optimize/yeast.CodonPriority.txt"
						." -enzymelib server/config/Optimize/common_enzyme.list"
						." -optizeallgene"
						." -outfasta server/tmp_data/{$dataset}_{$step}.fa"
						." -outgff server/tmp_data/{$dataset}_{$step}.gff";
			
			//$this->_data = $cmd;
			exec($cmd, $result, $code);
		
			exec("php server/bin/loadfile.php"
						." {$dataset}_{$step} data/{$dataset}_{$step}/"
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
