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
#  -g  genome / transcript_library
#  -i miRNA-file
#  -p: allow gaps or not
our( $opt_m, $opt_t, $opt_c, $opt_g, $opt_i, $opt_p );
getopts('m:t:c:g:i:p:');

if ( (! defined $opt_g) || (! defined $opt_i) ) {
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
if(defined $opt_p) { $user_param{allow_gaps} = $opt_p; }

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
	chomp($opt_i);
	print "\n\nMiRNA-Seq: $opt_i\n\n";

	### Search for query string
	#print "Test 1";
	$targetSearch->search($opt_i);
	#print "Test 2";

	# Loop through targets and print results
	foreach my $target ( @{ $$targetSearch{searchResults}{targets} } ) {
		if( ($target->{filter_passed} == 1) && ($target->{message} eq "passed") ) {
			print "Target:\t";
			print $target->{seq_id} . "\t";
			print $target->{begin} . "\t";
			print $target->{mismatches} . "\t";
			print sprintf("%.1f", $target->{dG}) . "\t";
			print sprintf("%.1f", $target->{dG_ratio}) . "\t";
			print $target->{query_string} . "\t";
			print $target->{target_string} . "\t";
			print $target->{sequence} . "\t";
			print $target->{message} . "\n";
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


sub usage {
	return <<EOT
$0 Version 3.1, Stephan Ossowski, Joffrey Fitz, Markus Riester 2008

Usage: $0 [-m mismatches] [-t temperature] [-c config_file] -g <transcript_library> -i <mirna-seq>

Available Options:

-g      genome/transcript_library
-i      Input miRNA as string
-m      Mismatches, optional, default 5
-t      Temperature, optional, default 23C
-c      configfile, optional, default /etc/AmiRNA//AmiRNA.xml
-p      allow gaps, optional, 1 for yes, 0 for no, default 0
--help	This help.

Example: $0 -g TAIR8_cdna_20080412 -i ugacagaagagagugagcac -c /etc/AmiRNA/AmiRNA.xml

EOT
;
}
