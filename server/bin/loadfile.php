#!/usr/bin/php
<?php
			list($p, $output, $outdir, $tmpfile, $track) = $argv;
			mkdir($outdir, 0777);
			///echo $tmpfile;
			//return;
		    copy($tmpfile.$output.".fa", $outdir.$output.".fa");
		    copy($tmpfile.$output.".gff", $outdir.$output.".gff");
		    $err = Array(); 
		    exec("perl bin/prepare-refseqs.pl --fasta $outdir{$output}.fa --out $outdir 2>&1", $err); 
		    //error_log("1".print_r($err, true), 3, 'server/debug.log');
		    exec("perl bin/biodb-to-json.pl --conf $track --out $outdir 2>&1", $err);
		    ///error_log("2".print_r($err, true), 3, 'server/debug.log');
		    exec("perl bin/add-json.pl '{ \"dataset_id\": \"$output\" }' {$outdir}trackList.json 2>&1", $err);
		    //error_log("3".print_r($err, true), 3, 'server/debug.log');
		    exec("perl bin/generate-names.pl --dir $outdir 2>&1", $err);
		   // error_log("4".print_r($err, true), 3, 'server/debug.log');

		    $context= file_get_contents("jbrowse_conf.json");
		    $context= preg_replace("/([a-zA-Z0-9_]+?):/" , "\"$1\":", $context);
		    $context= preg_replace("`'([a-zA-Z0-9_ ?/=]+?)'`" , "\"$1\"", $context);
		   // error_log("5". $context, 3, 'server/debug.log');
		    $config = json_decode($context, true);
		  //  error_log('5.5  '.$datasetname, 3, 'server/debug.log');
		    $config['datasets'][$output] = array(
		            "url"=>"?data=".$outdir,
		            "name"=>$output
		        );
		 //   error_log("6".json_last_error(), 3, 'server/debug.log');
		 //   error_log("7".print_r( $config, true ), 3, 'server/debug.log');
		    $out = json_encode( $config, JSON_UNESCAPED_SLASHES );
		    $fout = fopen("jbrowse_conf.json", "w");
		    //error_log("5".($out), 3, 'server/debug.log');
		    fwrite($fout, $out );
		    fclose($fout);
		    exec("rm server/tmp_data/* -r");

		    chdir($outdir);
		    
		   //	exec("rm server/tmp_data/* -r");
		    
		    exec("git init", $err);
 			exec('sleep 10');	
		    exec('git config user.name \"Genovo\"', $err);
		    exec('git config user.email \"Genovo@igem.com\"', $err);
		    exec('sleep 10');
		    exec("git add *", $err);
		    exec('git commit -m "init version of '.$output.'"', $err);
		    // if it work
		    print(json_encode($err));
?>