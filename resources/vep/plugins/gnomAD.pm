package gnomAD;

use strict;
use warnings;

use Bio::EnsEMBL::Variation::Utils::BaseVepTabixPlugin;
use base qw(Bio::EnsEMBL::Variation::Utils::BaseVepTabixPlugin);

=head1 NAME
 gnomAD
=head1 SYNOPSIS
 mv gnomAD.pm ~/.vep/Plugins
 ./vep -i variations.vcf --plugin gnomAD,/FULL_PATH_TO_GNOMAD_FILE
=head1 DESCRIPTION
 Plugin to annotate gnomAD allele frequencies and number of homozygotes, see https://gnomad.broadinstitute.org/.
 This plugin serves as a workaround for https://github.com/Ensembl/ensembl-vep/issues/1397 and has double the performance.
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
  return [ 'VariationFeature', 'StructuralVariationFeature' ];
}

sub feature_types {
  return [ 'Transcript', 'RegulatoryFeature', 'MotifFeature', 'Intergenic'];
}

sub get_header_info {
  return {
    gnomAD_SRC => 'gnomAD source: E=exomes, G=genomes, T=total',
    gnomAD_AF => 'gnomAD allele frequency',
    gnomAD_FAF95 => 'gnomAD filtering allele frequency (95% confidence)',
    gnomAD_FAF99 => 'gnomAD filtering allele frequency (99% confidence)',
    gnomAD_HN => 'gnomAD number of homozygotes',
    gnomAD_QC => 'gnomAD quality control filters that failed',
    gnomAD_COV => 'gnomAD coverage (percent of individuals in gnomAD source)'
  };
}

sub run {
  my ($self, $base_variation_feature_overlap_allele) = @_;

  my @line = @{$base_variation_feature_overlap_allele->base_variation_feature->{_line}};
  my $chr = $line[0];
  my $pos = $line[1];
  my $ref = $line[3];
  my $alt = $line[4]; # assume site is biallelic

  # get all records from annotation file with matching chr and pos
  my @data = @{$self->get_data($chr, $pos, $pos)};

  # return first record with matching ref and alt
  for my $rec (@data) {
    return $rec->{result} unless $rec->{ref} ne $ref || $rec->{alt} ne $alt
  }

  # otherwise return empty hash
  return {};
}

sub uniq {
  my %seen;
  return grep { !$seen{$_}++ } @_;
}

sub parse_data {
  my ($self, $line) = @_;
  my ($chr, $pos, $ref, $alt, $af_e, $af_g, $af_t, $faf95_e, $faf95_g, $faf95_t, $faf99_e, $faf99_g, $faf99_t, $hn_e, $hn_g, $hn_t, $qc_e, $qc_g, $not_e, $not_g, $cov_e, $cov_g, $cov_t) = split /\t/, $line;

  # determine data source: E=exomes, G=genomes, T=total, N=none
	my $src;
	if($not_e ne '1') {
	  # called in exomes: true
		if($not_g ne '1') {
  		# called in genomes: true
  		$src = $qc_e eq '' ? ($qc_g eq '' ? 'T' : 'E') : ($qc_g eq '' ? 'G': 'T');
  	} else {
  		# called in genomes: false
  		$src = 'E';
  	}
	} else {
	  # called in exomes: false
		if($not_g ne '1') {
		  # called in genomes: true
		  $src = 'G';
    } else {
      # called in genomes: false
    	$src = 'N';
    }
	}

  # use 'total' in case both exomes and genomes qc fail
  my @qc;
  if($src eq 'E') {
    @qc = split(/,/, $qc_e);
  } elsif($src eq 'E') {
    @qc = split(/,/, $qc_g);
  } else {
    @qc = uniq(split(/,/, $qc_e . ',' . $qc_g));
  }

  return {
    chr => $chr,
    pos => $pos,
    ref => $ref,
    alt => $alt,
    result => $src ne 'N' ? {
      gnomAD_SRC => $src,
      gnomAD_AF => $src eq 'T' ? $af_t : ($src eq 'E' ? $af_e : $af_g),
      gnomAD_FAF95 => $src eq 'T' ? $faf95_t : ($src eq 'E' ? $faf95_e : $faf95_g),
      gnomAD_FAF99 => $src eq 'T' ? $faf99_t : ($src eq 'E' ? $faf99_e : $faf99_g),
      gnomAD_HN => $src eq 'T' ? $hn_t : ($src eq 'E' ? $hn_e : $hn_g),
      gnomAD_QC => join(',', @qc),
      gnomAD_COV => $src eq 'T' ? $cov_t : ($src eq 'E' ? $cov_e : $cov_g)
    } : {}
  };
}

1;
