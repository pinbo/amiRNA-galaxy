# amiRNA-galaxy
A galaxy tool for designing amiRNAs and potential target search using WMD3 scripts.

This way it is easy for me to add cDNA libraries I need. Now I only include now 3 scripts:

1. cDNA blast to find cDNA names in the library;
1. amiRNA design (time consuming step, several hours for wheat);
1. miRNA target search.

# Prepare the installation
Here is an example I installed on my home folder without sysmatic permission.

```sh
## Download the wmd3 source
wget http://wmd3.weigelworld.org/downloads/wmd3-3.1.tar.gz
tar -xzf wmd3-3.1.tar.gz
cd wmd3-3.1

## Install genomemapper
wget http://1001genomes.org/data/software/genomemapper/genomemapper_0.4.4/genomemapper-0.4.4.tar.gz
tar xvfz genomemapper-0.4.4.tar.gz
cd genomemapper-0.4.4
ls /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX10.11.sdk/
vim Makefile # need to change to: CFLAGS_STD+=-arch x86_64 -isysroot /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX10.11.sdk/ -mmacosx-version-min=10.11
make
which genomemapper
mkdir ~/bin2
vim ~/.bash_profile # set the bin2 library in PATH
cp genomemapper gmindex ~/bin2

## Install ViennaRNA
cd ..
wget https://www.tbi.univie.ac.at/RNA/download/sourcecode/2_1_x/ViennaRNA-2.1.9.tar.gz
tar  xvfz ViennaRNA-2.1.9.tar.gz
cd ViennaRNA-2.1.9
./configure
make
cd Progs/
cp RNAfold RNAcofold RNAup ~/bin2

## install AmiRNA perl scripts
cd ../../AmiRNA
vim Makefile.PL

cd # go to home directory
which sqlite3 # check whether seqlite3 is installed
mkdir amirna # make the database library
cd amirna/
sqlite3 amirna.db # create the amiRNA database for libraries

cd ~/wmd3-3.1
cd AmiRNA
perl Makefile.PL # this will remind you which perl library needed.
which cpanm # check whether cpanm is installed for easy installation of other perl modules
which cpan # check whether cpan is installed
cpan App::cpanminus # install cpanm
which cpanm # seems not available, we need set the perl module path
vim ~/.bash_profile # export PERL5LIB=~/perl5/lib/perl5
source  ~/.bash_profile # add: export PERL5LIB=/Users/galaxy/perl5/lib/perl5
echo $PERL5LIB
which cpanm
perldoc -l Data::Types # check whether perl can find it
cpanm Data::Types # install modules
cpanm XML::Smart

perl Makefile.PL # retry
make # easy, just create some perl modules
make install # if we set PERL5LIB to home directory, it will automatically be installed to there
cp tools/Designerd/designerd.pl ~/bin2
vim etc/AmiRNA.xml # change some locations and SQL tools, see my example in the folder
cp tools/Designerd/designerd.xml etc # may not necessary
vim etc/designerd.xml # change some settings

cp tools/Preprocess/* ~/bin2
cp tools/amirna_initdb.pl ~/bin2 # script to initialize SQL database
amirna_initdb.pl -c ~/wmd3-3.1/AmiRNA/etc/AmiRNA.xml
cpanm XML/Dumper.pm # install missing modules
amirna_initdb.pl -c ~/wmd3-3.1/AmiRNA/etc/AmiRNA.xml

## prepare cDNA libraries
cd
mkdir blastdb
wget http://wmd3.weigelworld.org/downloads/TAIR8_cdna_20080412.gz
gunzip TAIR8_cdna_20080412.gz
generate_mapping_index.pl -d "A. thaliana CDNA" -f TAIR8_cdna_20080412 -c ~/wmd3-3.1/AmiRNA/etc/AmiRNA.xml

## Test the tool
cd ~/wmd3-3.1/AmiRNA/test/

# need to fix ViennaRNA parameters
cpanm  Error # install Error module
grep noCloseGU /Users/galaxy/perl5/lib/perl5/AmiRNA/TargetSearch/ViennaRNA.pm
sed -i 's/noCloseGU/-noClosingGU/g' /Users/galaxy/perl5/lib/perl5/AmiRNA/TargetSearch/ViennaRNA.pm
sed -i 's/noLP/-noLP/g' /Users/galaxy/perl5/lib/perl5/AmiRNA/TargetSearch/ViennaRNA.pm
grep Xp /Users/galaxy/perl5/lib/perl5/AmiRNA/TargetSearch/ViennaRNA.pm
sed -i 's/Xp/-interaction_pairwise/g' /Users/galaxy/perl5/lib/perl5/AmiRNA/TargetSearch/ViennaRNA.pm
sed -i 's/length(@targets_array)/@targets_array/g' /Users/galaxy/perl5/lib/perl5/AmiRNA/Designer/MiRNA.pm

./test_TargetSearch.pl -g TAIR8_cdna_20080412 -i ugacagaagagagugagcac -c ~/wmd3-3.1/AmiRNA/etc/AmiRNA.xml
./test_ViennaRNA_module.pl -t 23 -c ~/wmd3-3.1/AmiRNA/etc/AmiRNA.xml
./test_Error.pl -c ~/wmd3-3.1/AmiRNA/etc/AmiRNA.xml
./test_Oligo.pl
./test_DB_Sequences.pl -c ~/wmd3-3.1/AmiRNA/etc/AmiRNA.xml -t AT1G01010.1 -g TAIR8_cdna_20080412
# designing cDNA takes about one hour, so be patient
./test_Designer.pl -c ~/wmd3-3.1/AmiRNA/etc/AmiRNA.xml -g TAIR8_cdna_20080412 -t AT1G01090.1 -m 1 -a 1

## Set up wheat cDNA libraries
cd ~/blastdb
# get wheat IWGSC v1.0
wget https://urgi.versailles.inra.fr/download/iwgsc/IWGSC_RefSeq_Annotations/v1.0/iwgsc_refseqv1.0_HighConf_CDS_2017Mar13.fa.zip
unzip iwgsc_refseqv1.0_HighConf_CDS_2017Mar13.fa.zip
rm iwgsc_refseqv1.0_HighConf_CDS_2017Mar13.fa.zip

# get wheat IWGSC v1.1
wget https://urgi.versailles.inra.fr/download/iwgsc/IWGSC_RefSeq_Annotations/v1.1/iwgsc_refseqv1.1_genes_2017July06.zip
unzip iwgsc_refseqv1.1_genes_2017July06.zip
rm iwgsc_refseqv1.1_genes_2017July06.zip
cd iwgsc_refseqv1.1_genes_2017July06/
generate_mapping_index.pl -d "Triticum aestivum IWGSC v1.1 HC cds" -f IWGSC_v1.1_HC_20170706_cds.fasta -c ~/wmd3-3.1/AmiRNA/etc/AmiRNA.xml

# Test the amiRNA design scripts
cd ~/wmd3-3.1/AmiRNA/test/
./test_TargetSearch.pl -g IWGSC_v1.1_HC_20170706_cds.fasta -t TAACCGCTTTGGCAGGTCCGG -c ~/wmd3-3.1/AmiRNA/etc/AmiRNA.xml

# index the blast libraries
cd ~/blastdb/
makeblastdb -in TAIR8_cdna_20080412 -parse_seqids -dbtype nucl
```

