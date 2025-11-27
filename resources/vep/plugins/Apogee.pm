package Apogee;

use strict;
use warnings;

use Bio::EnsEMBL::Variation::Utils::BaseVepTabixPlugin;
use base qw(Bio::EnsEMBL::Variation::Utils::BaseVepTabixPlugin);

=head1 NAME
	Apogee
=head1 SYNOPSIS
	mv Apogee.pm ~/.vep/Plugins
	./vep -i variations.vcf --plugin Apogee,/FULL_PATH_TO_APOGEE_FILE
=head1 DESCRIPTION
	Plugin to annotate Apogee Score and Unbiased score values
=cut

my $self;

sub new {
	if (!(defined $self)) {
		my $class = shift;
		$self = $class->SUPER::new(@_);
		
		$self->expand_left(0);
		$self->expand_right(0);
		
		my $ann_file = $self->params->[0];
		die("ERROR: input file not specified\n") unless $ann_file;
		
		$self->add_file($ann_file);
	}
	return $self;
}

sub variant_feature_types {
	return [ 'VariationFeature', 'StructuralVariationFeature' ]
}

sub feature_types {
	return [ 'Transcript', 'RegulatoryFeature', 'MotifFeature', 'Intergenic' ]
}

sub get_header_info {
	return {
		apogee_Score => "Score assigned by APOGEE",
		apogee_Uscore => "Unbiased score assigned by APOGEE",
	};
}

sub run {
	my ($self, $base_variation_feature_overlap_allele) = @_;
	
	my @line = @{$base_variation_feature_overlap_allele->base_variation_feature->{_line}};
	my $chr = $line[0];
	my $pos = $line[1];
	my $ref = $line[3];
	my $alt = $line[4];
	
	# Get all the apogee records from apogee annotation file with matching chr and pos
	my @data = @{$self->get_data($chr, $pos, $pos)};
	
	# return the first record with matching ref and alt
	for my $rec (@data){
		return $rec->{result} unless $rec->{ref} ne $ref || $rec->{alt} ne $alt
	}
	
	# otherwise return empty hash
	return {};
}

sub parse_data {
	my ($self, $line) = @_;
	my ($chr, $pos, $ref, $alt, $genesym, $apo_score, $apo_uscore) = split /\t/, $line;
	
	return {
		chr => $chr,
		pos => $pos,
		ref => $ref,
		alt => $alt,
		genesym => $genesym,
		result => {
			apogee_Score => $apo_score,
			apogee_Uscore => $apo_uscore
		}
	};
}

1;
