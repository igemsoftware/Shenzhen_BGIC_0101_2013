<?php

class Resource_chip_chip extends Resource
{

	public function get()
	{

		$data = $this->get_data();
		$TopDir = "../../";
		//return;

		if (isset($data['fa'])) {
			chdir($TopDir);
			$faname = strrchr($data['fa'], '/');//substr($data['fa'], strchr($data['fa'], '/')+1 );
			$faname = ltrim($faname, '/');
			exec("cp ".$data['fa'].
				" server/bin/chip_new/ols-pool-generation-script/input-seqs/$faname", $result);
			$this->_data = "copy ".$data['fa'].
				" server/bin/chip_new/ols-pool-generation-script/input-seqs/$faname";
		
			chdir("server/bin/chip_new/ols-pool-generation-script/");
			
			$bb = $data['b'] == true? "True":"False";
			$cmd = "perl Get_configFile.pl"
					." -a {$data['a']} -b $bb"
					." -c {$data['c']} -d {$data['d']}"
					." -f {$data['f']}"
					." -i {$data['i']} -l $faname"
					." -n {$data['n']} -u {$data['u']}"
					." -o $faname 2>&1";

			exec($cmd, $result);
			$this->_data = $cmd;
			//return;
			

			$cmd = "python gasp.py $faname-config.json 2>&1";

			exec($cmd, $result);
			$this->_data = $result;
			//return;
			$shortfa = strchr($faname, ".");
			exec("ls output-oligos-and-primers/$shortfa*", $list);
			for ($i in $list) {
				exec("mv output-oligos-and-primers/ input-seqs/SHORTENED_yeast_chr1_3_16.all_bb.fasta ../../../../".$data['fa']).".chip";
			}
			$this->_data = $result;
			return;
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
