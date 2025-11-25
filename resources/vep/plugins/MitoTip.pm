package MitoTip;

use strict;
use warnings;

use Bio::EnsEMBL::Variation::Utils::BaseVepTabixPlugin;
use base qw(Bio::EnsEMBL::Variation::Utils::BaseVepTabixPlugin);

=head1 NAME
	MitoTip
=head1 SYNOPSIS
	mv MitoTip.pm ~/.vep/Plugins
	./vep -i variations.vcf --plugin MitoTip,/FULL_PATH_TO_MITOTIP_FILE
=head1 DESCRIPTION
	Plugin to annotate MitoTip scores and quartile, see https://www.mitomap.org/foswiki/bin/view/MITOMAP/MitoTipInfo
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
	return{
		mitoTip_Score => "MitoTip Score",
		mitoTip_Quartile => "MitoTip Quartile"
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
	my ($chr, $pos, $ref, $alt, $mt_score, $mt_quart, $mt_count, $mt_perc, $mt_status) = split /\t/, $line;
	
	return {
		chr => $chr,
		pos => $pos,
		ref => $ref,
		alt => $alt,
		result => {
			mitoTip_Score => $mt_score,
			mitoTip_Quartile => $mt_quart
		},
		perc => $mt_perc,
		status => $mt_status
	};
}

1;
