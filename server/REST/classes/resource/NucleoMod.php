<?php

class Resource_NucleoMod extends Resource
{

	public function get()
	{

		$data = $this->get_data();
		$TopDir = "../../";
		
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
			

			$cmd = "perl server/bin/NucleoMod.pl -inputfa $fa -inputgff $gff "
				   . 	" -outputfa server/tmp_data/{$dataset}_nucleo.fa "
				   .	" -outputgff server/tmp_data/{$dataset}_nucleo.gff ";

			if (isset($data["crisprnum"]) && isset($data["database"])) {
				$cmd .= " -crisprnum ".$data["crisprnum"]." -database server/config/geneset/".$data["database"];
			}
			if (isset($data["codonoptimize"]) && isset($data["optimizelist"])) {
				$cmd .= " -codonoptimize server/config/Optimize/".$data["codonoptimize"];
				if ($data["optimizelist"] == "optimizeallgene") {
					$cmd .= " -optimizeallgene";
				} else {
					$cmd .= " -optimizegenelist ".$data["optimizelist"];
				}
			}

			if (isset($data["repeatsmash"])) {
				$cmd .= " -repeatsmash ".$data["repeatsmash"];
			}
			//biobrickstandard
			if (isset($data["biobrickstrand"])) {
				if ($data["biobrickstrand"] == "biobrickstrand")
					$cmd .= " -biobrickstandard";
				else {
					$cmd .= " -delenzymelist server/config/Optimize/".$data["biobrickstrand"];
				}
			}
			if (isset($data["addenzymelist"]) && isset($data["addenzymeconfig"])) {
				$cmd .= " -addenzymelist server/config/Optimize/".$data["addenzymelist"]. " -addenzymeconfig ".$data["addenzymeconfig"];
			}
			$this->_data = $cmd;
			//return;
			exec($cmd, $result, $code);
		
			exec("php server/bin/loadfile.php"
						." {$dataset}_nucleo data/{$dataset}_nucleo/"
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
