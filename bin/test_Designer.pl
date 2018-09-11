#!/usr/bin/perl
#
#    WMD - A tool for miRNA target search and amiRNA design
#
#    Test program for WMD3 classes
#    Version 3.1
#
#    Authors: Stephan Ossowski, Joffrey Fitz, Markus Riester
#    Copyright (C) 2005-2009 by Max Planck Institute for Developmental Biology, Tuebingen.
##########################################################################################

use strict;
use warnings;
use Getopt::Std;
use AmiRNA::Designer::AmiRNADesigner;

### Example genes for testing with A.thaliana:
# SINGLE: AT1G01090.1
# MULTI:  AT1G74280.1,AT1G74290.1,AT1G74300.1


# cmd line arguments:
#  -c  configfile
#  -g  genome / transcript_library
#  -f fasta_file
#  -t Gene list
#  -m Minimum number of targets.
#  -a annotated
#  -o offtarget list

our( $opt_c, $opt_g, $opt_f, $opt_t, $opt_a, $opt_o, $opt_m );
getopts('c:g:f:t:a:o:m:');

unless ( defined ($opt_g) && (defined $opt_m) ) {
	print usage();
	exit;
}

if(	( defined($opt_f) && defined ($opt_t) ) ||
	( ! defined($opt_f) && ! defined ($opt_t) )
) {
	print "Please specify either fasta sequence (-f) or list of gene names as string\n\n";
	print usage();
	exit;
}


my %user_param = (
	configfile         => $opt_c,
	transcript_library => $opt_g,
        target_fasta       => '',
	target_genes       => '',
	musthave           => $opt_m,
	annotated          => 1,
	offtargets         => '',
	temperature        => 23,
	relaxed_rules      => 1,
	accelerate_design  => 1,
	flanking           => 0,
);

if(defined $opt_f) { $user_param{target_fasta} = $opt_f; }
if(defined $opt_t) { $user_param{target_genes} = $opt_t; }
if(defined $opt_a) { $user_param{annotated}    = $opt_a; }
if( (defined $opt_o) && ($opt_o ne "0") ) { $user_param{offtargets}   = $opt_o; }

#while (my ($key, $value) = each (%user_param)){ print "$key => $value\n"; }

eval {
	my $amiRNAdesigner = AmiRNA::Designer::AmiRNADesigner->new(%user_param);
	$amiRNAdesigner -> design();
	
	print "amiRNA\tType\tScore\tMutations\tOptimal_energy\tTargets\n";

	foreach my $amiRNA ( @{ $amiRNAdesigner->{miRNA_objs} } ) {
		print	$amiRNA->{mirna_pattern} . "\t" . $amiRNA->{type} . "\t" . $amiRNA->{score} . "\t" .
			$amiRNA->{mutations} . "\t" . $amiRNA->{optimal_energy} . "\t" . $amiRNA->{targets} . "\n";
	}
};
if($@) {
        print "Error: " . $@->{'msg'} . "\n" . $@->{'errno'} . "\n" . $@->{'subject'} . "\n";
        foreach my $x (@{ $@->{'chain'} } ) {
                foreach my $y ( @{ $x } ) { print "$y\n"; }
        }
}


exit(0);


sub usage {
	return <<EOT
$0 Version 3.1, Stephan Ossowski, Joffrey Fitz, Markus Riester 2009

Usage: $0 -c <configfile> -g <transcript_library> -t <gene ID> -m <min targets> -a <0|1> [-o list_of_offtargets]

Available Options:

-c      configfile 
-g      genome/transcript_library
-f      Multi fasta sequence of target genes (as string) Do not use with -t
-t      Target genes names (as string). Do not use with -f.
-m      Minimum number of targets.
-a      Gene is annotated in transcript libray < 0 | 1 >
-o      List of acceptable offtargets (gene names as defined in transcript library)
--help	This help.

Example: ./test_Designer.pl -c /etc/AmiRNA/AmiRNA.xml -g TAIR8_cdna_20080412 -t AT1G01090.1 -m 1 -a 1

EOT
;
}
