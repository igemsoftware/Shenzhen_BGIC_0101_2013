<?php

class Resource_modify_Add extends Resource
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
			
			exec("ls {$dataUrl}*.gff*", $gff);
			//exec("ls {$dataUrl}", $gff);
			
			$gff = $gff[0];
			exec("ls {$dataUrl}*.fa", $fa);
			//return;
			$fa = $fa[0];
			//return;
			$chrname = $data["chrname"];
			$cmd = "perl server/bin/04.Add.pl \
					--loxp server/config/features/loxPsym.feat \
					--left_telomere server/config/features/UTC_left.feat \
					--right_telomere server/config/features/UTC_right.feat \
					--ars server/config/features/chromosome_I_ARS108.feature \
					--centromere server/config/features/chromosome_I_centromere.feat \
					--chr_gff $gff \
					--chr_seq $fa \
					--chr_name $chrname \
					--neochr_seq server/tmp_data/{$chrname}_add.fa \
					--neochr_gff server/tmp_data/{$chrname}_add.gff 2>&1";
			exec($cmd, $result, $code);

			$this->_data = $cmd;
			//return;
			exec("php server/bin/loadfile.php \
						{$chrname}_add data/{$chrname}_add/ \
						server/tmp_data/ server/add_track_conf.json > /dev/null &", $result);
			$this->_data = array_merge($result, 
							array("url"=>"data/{$chrname}_add") );

		} else {
			$this->_data = "unknow sequence name";
		}
	}

	public function post()
	{
		$this->_data = array_merge($this->get_data(), array('type' => 'post'));
	}
}
