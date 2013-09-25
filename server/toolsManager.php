<?php
    if (isset($_REQUEST['nav'])) {
        echo join("", file('resource.json'));
    }
    if (isset($_REQUEST['species']) && isset($_REQUEST['pathway'])) {
        $species = $_REQUEST['species'];
        $pathway = $_REQUEST['pathway'];
      	$result = array();
        $result['genes'] = json_decode(
                        file_get_contents("pathway/{$pathway}_genes.json"));
        $result['relation'] = json_decode(
                        file_get_contents("pathway/{$pathway}_relation.json"));
      	echo json_encode($result);
    
       // exec("Plugin/01.GrapGene.pl --species $species --pathway \
	//			 $pathway --pathdir pathway 2>&1",
   //     			$result, $code);
       // echo json_encode($result);
    }
    if (isset($_REQUEST['decouple']))
    if (isset($_REQUEST['GetPrice']) && isset($_REQUEST['enzyme'])) {
    	$enzyme = $_REQUEST['enzyme'];
  	exec("perl GetPrice/getPrice.pl -E $enzyme 2>&1", $result, $code);
    	echo json_encode($result);
    }
?>
