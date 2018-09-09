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

use AmiRNA::DB::Base;
use AmiRNA::DB::Results;
use AmiRNA::DB::Job;
use AmiRNA::DB::Sequences;
use Text::Wrap;

# cmd line arguments:
#  -t Target genes names (as string)
#  -g  genome / transcript_library
#  -c configfile

our( $opt_c, $opt_g, $opt_t );
getopts('c:t:g:');

if(not defined($opt_c) or not defined($opt_t) or not defined($opt_g)) {
	print usage();
	exit;
}


my $db;


eval {
	# Database connection
	$db = AmiRNA::DB::Base->new( $opt_c );
	$db->connect();
	
	# Create Sequences object
	my $seq_db = AmiRNA::DB::Sequences->new($db);
	
	my %results = ();
	eval {
		%results = $seq_db->get_cdna( $opt_g, $opt_t);
	};
	die if $@;

	use Data::Dumper;
	print STDERR "Dump: " . Dumper(%results) . "\n-----------------\n";
		
	# Output FATA
	foreach my $seq (keys %results) {
		my @output = (">$seq",  $results{ $seq });
		$Text::Wrap::columns = 72;
		print wrap("", "", @output) . "\n\n";
	}
};
if($@) {
        print "Error: " . $@->{'msg'} . "\n" . $@->{'errno'} . "\n" . $@->{'subject'} . "\n";
        foreach my $x (@{ $@->{'chain'} } ) {
                foreach my $y ( @{ $x } ) { print "$y\n"; }
        }
}

$db->disconnect();
exit 0;
#####################################################################################

sub usage {
	return <<EOT
$0 Version 3.1, Stephan Ossowski, Joffrey Fitz, Markus Riester 2009

Usage: $0 -c <configfile> -g <transcript_library> -t <gene ID>

Available Options:

-t      Target genes names (as string)
-g      genome/transcript_library
-c      configfile 
--help	This help.

Example: $0 -c /etc/AmiRNA/AmiRNA.xml -t AT1G01010.1 -g TAIR8_cdna_20080412

EOT
;
}
