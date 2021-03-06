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
use AmiRNA::TargetSearch::SearchOptions;
use AmiRNA::TargetSearch::Vmatch;
use AmiRNA::TargetSearch::GenomeMapper;

# cmd line arguments:
#  -m  mismatches
#  -t  temperature
#  -c  configfile
#  -g  transcript_library
#  -f  miRNA-file
our( $opt_m, $opt_t, $opt_c, $opt_g, $opt_f );
getopts('m:t:c:g:f:');

if ( (! defined $opt_g) || (! defined $opt_f) ) {
	print usage();
	exit;
}

my %user_param = (
	transcript_library => $opt_g,
	mismatches         => 5,
	allow_gaps         => 0,	# < 0 | 1 >
	strand             => 'rev',	# < fwd | rev | both >
	remove_isoform     => 1,
	one_hit_per_gene   => 1,
	calculate_filter   => 1,	# < 0 | 1 >
	apply_filter       => 1,        # < 0 | 1 >
	calculate_folding  => "passed",	# < all | passed | non >
	folding_backend    => "RNAcofold",	# < RNAup | RNAcofold >
	temperature        => 23,	# 0 - 80 degree C
	cutoff             => 70,	# 0 to 99
	relaxed            => 1,	# < 0 | 1 >
	flanking           => 0,
	showdesc           => 50,	# 0 - any, 0 = off
	show_gene_length   => 0,
	sort_mode          => 'ea',	# < ea | ed | ga | gd | la | ld >
);

if(defined $opt_m) { $user_param{mismatches} = $opt_m; }
if(defined $opt_t) { $user_param{temperature} = $opt_t; }


### Create search object
my $searchOptions;
my $targetSearch;
eval {
	### SearchOptions object
	$searchOptions = AmiRNA::TargetSearch::SearchOptions->new($opt_c);

	### Create TargetSearch object
	if( $searchOptions->get_search_program() eq "vmatch" ) {
		$targetSearch = AmiRNA::TargetSearch::Vmatch->new($searchOptions, %user_param);
	}
	elsif( $searchOptions->get_search_program() eq "genomemapper" ) {
		$targetSearch = AmiRNA::TargetSearch::GenomeMapper->new($searchOptions, %user_param);
	}
};
if($@) {
	print "Some errors occured. Please send the following error message to wmd\@weigelworld.org.\n";
	print "Start error message.\n" . $@->{'msg'} . "\n" . $@->{'errno'} . "\n" . $@->{'subject'} . "\n";
	foreach my $x (@{ $@->{'chain'} } ) {
		foreach my $y ( @{ $x } ) { print "$y\n"; }
	}
	print "End error message.\n";
}


### Search targets for each input miRNA
eval {
	open (MIRNA, $opt_f);

	while(<MIRNA>) {
		chomp;
		if($_ ne "") {
			#my $name = $_;
			#my $query = <MIRNA>;
			my $query = $_;
			chomp($query);
			print "\n\nMiRNA-Seq: $query\n\n";
			print "Target\tGene_length\tBegin\tPosition_Percent\tMismatches\tdG\tdG_ratio\tmiRNA-RC\tTarget-Seq\n";

			### Search for query string
			$targetSearch->search($query);

			# Loop through targets and print results
			#print "$name";
			foreach my $target ( @{ $$targetSearch{searchResults}{targets} } ) {
				if( ($target->{filter_passed} == 1) && ($target->{message} eq "passed") ) {
					print $target->{seq_id} . "\t";
					print $target->{gene_length} . "\t";
					print $target->{begin} . "\t";
					print sprintf("%.1f", $target->{begin} / $target->{gene_length} * 100) . "\t";
					print $target->{mismatches} . "\t";
					print sprintf("%.1f", $target->{dG}) . "\t";
					print sprintf("%.1f", $target->{dG_ratio}) . "\t";
					print lc($target->{query_string}) . "\t";
					print markdiff($target->{query_string}, $target->{target_string}) . "\n";
				}
			}
			print "\n";
		}
	}
};
if($@) {
        print "Some errors occured. Please send the following error message to wmd\@weigelworld.org.\n";
        print "Start error message.\n" . $@->{'msg'} . "\n" . $@->{'errno'} . "\n" . $@->{'subject'} . "\n";
        foreach my $x (@{ $@->{'chain'} } ) {
                foreach my $y ( @{ $x } ) { print "$y\n"; }
        }
        print "End error message.\n";
}


exit(0);

# mark the difference as lowercase
sub markdiff {
my ($s1, $s2) = @_;
my $c3 = "";
for my $i (0..length($s2)-1){
    my $c1 = substr($s1, $i, 1);
    my $c2 = substr($s2, $i, 1);
    $c3 .= $c1 eq $c2 ? lc($c2) : $c2;
       
}
return $c3;
}

sub usage {
	return <<EOT
$0 Version 3.1, Stephan Ossowski, Joffrey Fitz, Markus Riester 2009

Usage: $0 [-m mismatches] [-t temperature] [-c config_file] -g <transcript_library> -f <fasta file>

Available Options:

-g      genome/transcript_library
-f      Input miRNAs as a file: each line is a miRNA sequence
-m      Mismatches, optional, default 5
-t      Temperature, optional, default 23C
-c      configfile, optional, default /etc/amirna/AmiRNA.conf
--help	This help.

Example: perl batch_TargetSearch.pl -g TAIR8_cdna_20080412 -f miRNA-seq.txt

EOT
;
}
