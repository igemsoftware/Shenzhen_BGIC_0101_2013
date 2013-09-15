<?php

class Resource_features_searchFeaturesByLocation extends Resource
{
	public function get()
	{
		/* set etag
		Response::instance()
			->if_none_match(md5('hello'))
			->add_etag(md5('hello'))
			;
		//*/


//		$this->_data = "123";

		$data = $this->get_data();
	//	$this->_data = $data;
		$TopDir = "../../../../../";
		$jbrowse = file_get_contents($TopDir."jbrowse_conf.json");
		$jbrowse = json_decode($jbrowse, true);
		if (in_array($data['refseq_name'], $jbrowse['datasets'])) {
			$this->_data = $data['refseq_name'] ."in dataset" . $jbrowse['datasets'][$data['refseq_name']];
		}
		
/*
		if ($this->validate())
		{
			$this->_data = $this->get_data();
		}
		else 
		{
			$this->_data = array('error' => implode(',', $this->getErrors()), 'request' => $_SERVER['REQUEST_URI']);
		}
*/
	}

	public function post()
	{
		$this->_data = array_merge($this->get_data(), array('type' => 'post'));
	}
}
