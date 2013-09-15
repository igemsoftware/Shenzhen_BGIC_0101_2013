<?php

    $context= file_get_contents("jbrowse_conf.json");
    $context= preg_replace("/([a-zA-Z0-9_]+?):/" , "\"$1\":", $context);
    $context= preg_replace("`'([a-zA-Z0-9_ ?/=]+?)'`" , "\"$1\"", $context);
    echo $context;
    $config = json_decode($context, true);
    $config['datasets']['asd'] = 'asd';
    echo json_last_error();
    echo print_r($config);

?>
