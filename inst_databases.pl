#!/usr/bin/perl

# This script it's only for internal use.
# Please execute under your responsability.

system("rm -r -f res* VFDB*");

system("wget http://www.mgc.ac.cn/VFs/Down/VFDB_setA_nt.fas.gz");
system("wget http://www.mgc.ac.cn/VFs/Down/VFDB_setB_nt.fas.gz");
system("wget http://www.mgc.ac.cn/VFs/Down/VFDB_setA_pro.fas.gz");
system("wget http://www.mgc.ac.cn/VFs/Down/VFDB_setB_pro.fas.gz");
system("gzip -d *.fas.gz");


#system("mmseqs createdb VFDB_setA_nt.fas VFDB_setA_nucl");
#system("mmseqs createdb VFDB_setB_nt.fas VFDB_setB_nucl");
system("minimap2 -d VFDB_setA_nucl VFDB_setA_nt.fas");
system("minimap2 -d VFDB_setB_nucl VFDB_setB_nt.fas");
system("mmseqs createdb VFDB_setA_pro.fas VFDB_setA_prot");
system("mmseqs createdb VFDB_setB_pro.fas VFDB_setB_prot");

system("grep '>' VFDB_setB_nt.fas | sed 's/>//' | sed 's/^/VFB|/' > headersVFB.txt");
system("grep '>' VFDB_setA_nt.fas | sed 's/>//' | sed 's/^/VFA|/' > headersVFA.txt");


system("git clone https://bitbucket.org/genomicepidemiology/resfinder_db.git");

system("sed 's/>/\\n>/' ./resfinder_db/*.fsa > res_finder.fsa");
system("transeq res_finder.fsa res_finder.faa");
system("sed -i 's/*//' res_finder.faa");
system("grep '>' res_finder.fsa | sed 's/>//' | sed 's/^/AbR|/' > headersAbR.txt");
#system("mmseqs createdb res_finder.fsa resfinder_nucl");
system("minimap2 -d resfinder_nucl res_finder.fsa");
system("mmseqs createdb res_finder.faa resfinder_prot");

system("cat headersAbR.txt headersVFA.txt headersVFB.txt > headers.txt");


system("grep '>' ./resfinder_db/*.fsa > tmp");
open(OUT,">annot.data");

print OUT "ID\tDataBase\tGene\tDescription\n";

open(TMP, "tmp");
@tmp = <TMP>;
close TMP;
foreach $l (@tmp)
{
	$l =~ /.\/resfinder_db\/(.*)\.fsa:>(.*)\n/;
	print OUT "$2\tAbR\t$2\t$1\n";
}
undef @tmp;

system("grep '>' VFDB_set*nt.fas > tmp2");
open(TMP,"tmp2");
@tmp = <TMP>;

foreach $l (@tmp)
{
	$l =~ s/DB_set//;
	$l =~ /(.*)\_nt.fas:>(.*)\s(\(.*\))\s(.*)/;
	
	print OUT "$2\t$1\t$3\t$4\n";
		
}


system("wget http://bacmet.biomedicine.gu.se/download/BacMet2_EXP_database.fasta");
system("mmseqs createdb BacMet2_EXP_database.fasta bacmet");
system("grep '>' BacMet2_EXP_database.fasta | sed 's/>//' | sed 's/^//' > headersBACMET.txt");

open(A,"headersBACMET.txt");
@bacmet = <A>;
close A;

foreach $l (@bacmet)
{
	@c = split(/\s/,$l);
	#print "$c[0]\n";
	$Description = join(" ",@c[1 .. scalar(@c)]);
	$id = $c[0];
	@c2 = split(/\|/,$id);
	$gene = $c2[1];
	$database = "bacmet";
    
    print OUT "$id\t$database\t$gene\t$Description\n";
}



close OUT;

system("rm -f -r *.fas *.faa *.fsa resfinder_db tmp* Bac*");
