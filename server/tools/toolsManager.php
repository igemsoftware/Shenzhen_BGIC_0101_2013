<?php
    if (isset($_REQUEST['nav'])) {
        echo join("", file('resource.json'));
    }
    if (isset($_REQUEST['species']) && isset($_REQUEST['pathway'])) {
        $species = $_REQUEST['species'];
        $pathway = $_REQUEST['pathway'];
    
    
        exec("Plugin/01.GrapGene.pl --species $species --pathway $pathway --pathdir pathway 2>&1", $result, $code);
        echo json_encode($result);
    }
?>
