<?php

class Resource_decouple extends Resource
{
	public function setit( $a, $b) {
		return isset($a)?$a:$b;
	}

	public function get()
	{
		//return;
		$data = $this->get_data();
		if (isset($data['species']) && isset($data['geneorder'])) {
			$data = $this->get_data();
			$TopDir = "../../";
			chdir($TopDir);
			$genesetDir = "server/config/geneset/";
			$binDir = "server/bin/";
			$tmpdataDir = "server/tmp_data/";
			$species = $data['species'];
			$geneorder = $data['geneorder'];
			$neochr = $data['neochrName'];
			//$geneorder = rtrim($geneorder, '\n');
			$upstream_extend = isset($data['upstream_extend'])?
										$data['upstream_extend']:600;
			$downstream_extend = isset($data['downstream_extend'])?
										$data['downstream_extend']:100;
			$output = isset($data['output'])?$data['output']:"NeoChr_".date('w');

			$cmd ="perl server/bin/02.GeneDecouple.pl".
						" --species $species".
						' --list_format string'.
						" --gene_order='$geneorder'".
						" --geneset_dir $genesetDir".
						" --upstream_extend $upstream_extend".
						" --downstream_extend $downstream_extend".
						" --neo_chr_name {$neochr}".
						" --neo_chr_gff {$tmpdataDir}{$output}.gff".
						" --neo_chr_fa  {$tmpdataDir}{$output}.fa 2>&1";
			exec($cmd, $result, $code);

			//$this->_data = array_merge( $result, array("ok"=>true) );
			//$this->_data = $geneorder;
		    //return;

			$outdir = 'data/'.$output.'/';
		  //  return;
		    exec("php server/bin/loadfile.php "
		    			."	$output $outdir "
		    			."	server/tmp_data/ server/NeoChr_track_conf.json", $result, $code);
		    $this->_data = $cmd;
		    
		    return;
		} else {
			$this->_data = array("ok" => false);
		}
		
	}

	public function post()
	{
		$this->_data = array_merge($this->get_data(), array('type' => 'post'));
	}
}
