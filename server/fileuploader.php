<?php
$flg = 0;
for ($i = 0; $i < count($_FILES['uploadedfiles']['name']); $i++) {
    if (!file_exists("tmp_data/" . $_FILES["uploadedfiles"]["name"][$i])) {
        move_uploaded_file($_FILES["uploadedfiles"]["tmp_name"][$i],
            "tmp_data/" . $_FILES["uploadedfiles"]["name"][$i]);
    }
    $flg++;
}
//error_log(print_r($_FILES,true), 3, 'debug.log');
//error_log($flg, 3, 'debug.log');
//error_log(print_r($_POST, true), 3, 'debug.log');
if ($flg == 2) {
    $_fasta = $_FILES['uploadedfiles']['name'][0];
    $_gff   = $_FILES['uploadedfiles']['name'][1];
    $fasta = strpos($_fasta, "fa") ? $_fasta : null;
    $gff = strpos($_gff, "gff3") ? $_gff : strpos($_gff, "gff") ? $_gff:null;
    if (!($gff && $fasta)) {
        echo "less paramter";
        exit;
    }
    $datasetname = preg_split('/\./', $fasta, 0, PREG_SPLIT_NO_EMPTY)[0];
//    error_log(print_r($datasetname, true));
    $outdir = 'data/'.$datasetname.'/';
    chdir('..');
    mkdir($outdir, 0777);
    copy('server/tmp_data/'.$fasta, $outdir.$datasetname.".fa");
    copy('server/tmp_data/'.$gff, $outdir.$datasetname.".gff");
    $err = Array(); 
    exec("bin/prepare-refseqs.pl --fasta $outdir$fasta --out $outdir 2>&1", $err); 
    //error_log("1".print_r($err, true), 3, 'server/debug.log');
    exec("bin/biodb-to-json.pl --conf server/default_track_conf.json --out $outdir 2>&1", $err);
    ///error_log("2".print_r($err, true), 3, 'server/debug.log');
    exec("bin/add-json.pl '{ \"dataset_id\": \"$datasetname\" }' {$outdir}trackList.json 2>&1", $err);
    //error_log("3".print_r($err, true), 3, 'server/debug.log');
    exec("bin/generate-names.pl --dir $outdir 2>&1", $err);
   // error_log("4".print_r($err, true), 3, 'server/debug.log');

    $context= file_get_contents("jbrowse_conf.json");
    $context= preg_replace("/([a-zA-Z0-9_]+?):/" , "\"$1\":", $context);
    $context= preg_replace("`'([a-zA-Z0-9_ ?/=]+?)'`" , "\"$1\"", $context);
   // error_log("5". $context, 3, 'server/debug.log');
    $config = json_decode($context, true);
  //  error_log('5.5  '.$datasetname, 3, 'server/debug.log');
    $config['datasets'][$datasetname] = array(
            "url"=>"?data=".$outdir,
            "name"=>$datasetname
        );
 //   error_log("6".json_last_error(), 3, 'server/debug.log');
 //   error_log("7".print_r( $config, true ), 3, 'server/debug.log');
    $out = json_encode( $config, JSON_UNESCAPED_SLASHES );
    $fout = fopen("jbrowse_conf.json", "w");
    //error_log("5".($out), 3, 'server/debug.log');
    fwrite($fout, $out );
    fclose($fout);

    chdir($outdir);
    exec("git init", $err);
    exec("git add *", $err);
    exec('git commit -m "init version of '.$datasetname.'"', $err);
}



?>
