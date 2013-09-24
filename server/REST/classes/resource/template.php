<?php

class Resource_decouple extends Resource
{

	public function get()
	{

		$data = $this->get_data();
		$TopDir = "../../";
		$jbrowse = file_get_contents($TopDir."jbrowse_conf.json");
		$jbrowse = json_decode($jbrowse, true);
		
		$dataset = $data['dataset'];
		//return;

		if (isset($jbrowse['datasets'][$dataset]) && isset($data['refseq'])) {
			$seqname = $data['refseq'];
			$url = $dataset ." in dataset" .
							$jbrowse['datasets'][$dataset]['url'];
			$url = preg_split("/=/", $url)[1];

		} else {
			$this->_data = "unknow sequence name";
		}
	}

	public function post()
	{
		$this->_data = array_merge($this->get_data(), array('type' => 'post'));
	}
}
