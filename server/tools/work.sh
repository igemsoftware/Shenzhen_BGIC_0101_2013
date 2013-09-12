perl ../Plugin/01.GrapGene.pl --species Saccharomyces_cerevisiae  --pathway Glycolysis --pathdir ../pathway > Sce.Glycolysis.gene.list
perl ../Plugin/02.GeneDecouple.pl --species saccharomyces_cerevisiae_chr --gene_order Sce.Glycolysis.gene.list --geneset_dir ../gene_set

perl /ifs1/ST_PLANT/USER/liyuxiang/test/iGEM_test/sequence_modificationV1.pl /ifs1/ST_PLANT/USER/liyuxiang/test/iGEM_test/00.data/saccharomyces_cerevisiae_chr.fa -step 2 -genegff /ifs1/ST_PLANT/USER/liyuxiang/test/iGEM_test/00.data/saccharomyces_cerevisiae_chr.gff -genelist /ifs1/ST_PLANT/USER/liyuxiang/test/iGEM_test/gene_list |le

perl ../Plugin/02.GeneDecouple.1.pl --species saccharomyces_cerevisiae_chr --gene_order Sce.Glycolysis.gene.list --geneset_dir ../gene_set --extendlen 100 |le
