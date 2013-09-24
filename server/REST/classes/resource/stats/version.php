<?php

class Resource_stats_version extends Resource
{

	

	public function get()
	{

		$data = $this->get_data();
		$TopDir = "../../";
		$jbrowse = file_get_contents($TopDir."jbrowse_conf.json");
		$jbrowse = json_decode($jbrowse, true);
		
		$dataset = $data['dataset'];
		//return;

		if (isset($jbrowse['datasets'][$dataset])) {
			$url = $dataset ." in dataset" .
							$jbrowse['datasets'][$dataset]['url'];
			$url = preg_split("/=/", $url)[1];
			$url = rtrim($url, '/').'/';
			chdir($TopDir.$url);
			exec('git log --pretty=format:"%H%n%ci%n%s" |cat'
					, $result, $code);
			$this->_data = $result;

		} else {
			$this->_data = "unknow sequence name";
		}
	}

	public function post()
	{
		///$this->_data = array_merge($this->get_data(), array('type' => 'post'));
		//return;
		$data = array_merge( $this->get_data(), array('type' => 'post'));
		$TopDir = "../../";
		$jbrowse = file_get_contents($TopDir."jbrowse_conf.json");
		$jbrowse = json_decode($jbrowse, true);
		
		$dataset = $data['dataset'];
		//return;
		$this->_data = $data['dataset'];


		if (isset($jbrowse['datasets'][$dataset])) {
			$url = $dataset ." in dataset" .
							$jbrowse['datasets'][$dataset]['url'];
			$url = preg_split("/=/", $url)[1];
			$this->_data = "choose roll back method";
			chdir($TopDir.$url);
			$this->_data = $data;
			if (isset($data['reset'])) {

				exec("git reset --hard {$data['hashcode']}"
									, $result, $code);
				$this->_data = array_merge( $result, array("ok"=>true) );
				return;
			}
			if (isset($data['checkout'])) {
				$this->_data = "to Checkout";
				return;
			}
		} else {

			$this->_data = "unknow sequence name";
		}
	}
}
