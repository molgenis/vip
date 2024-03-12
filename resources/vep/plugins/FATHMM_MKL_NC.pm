package FATHMM_MKL_NC;

use strict;
use warnings;

use Bio::EnsEMBL::Variation::Utils::BaseVepTabixPlugin;
use base qw(Bio::EnsEMBL::Variation::Utils::BaseVepTabixPlugin);

=head1 NAME
 FATHMM_MKL_NC
=head1 SYNOPSIS
 Predict the Functional Consequences of Non-Coding Single Nucleotide Variants (SNVs)
 ./vep -i variations.vcf --plugin FATHMM-MKL-NC,/FULL_PATH_TO_FATHMM-MKL-NC_file
=head1 DESCRIPTION
 Predict the Functional Consequences of Non-Coding Single Nucleotide Variants (SNVs)
 This plugin is build on top of the GREEN-DB dataset for FATHMM-MKL non coding scores: https://zenodo.org/records/3981121
=cut

my $output_vcf;

my $self;

sub new {
    if (!(defined $self)) {
        my $class = shift;
        $self = $class->SUPER::new(@_);

        $self->expand_left(0);
        $self->expand_right(0);

        my $score_file = $self->params->[0];
        die("ERROR: input file not specified\n") unless $score_file;

        $self->add_file($score_file);
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
      FATHMM_MKL_NC => "FATHMM_MKL_NC: Predict the Functional Consequences of Non-Coding Single Nucleotide Variants (SNVs)"
    }
}

sub getScore {
  my $chr = $_[0];
  my $pos = $_[1];
  my $ref = $_[2];
  my $alt = $_[3];

  # get candidate annotations from precomputed scores file
  my @data = @{$self->get_data($chr, $pos, $pos)};
  for my $line (@data) {
    my @values = split("\t", $line);
    return $values[4] unless $values[2] ne $ref || $values[3] ne $alt;
  }
}

sub run {
  my ($self, $base_variation_feature_overlap_allele) = @_;

  my @line = @{$base_variation_feature_overlap_allele->base_variation_feature->{_line}};
  my $chr = $line[0];
  my $pos = $line[1];
  my $ref = $line[3];
  my $alt = $line[4]; # assume site is biallelic
  my $score;
  my $result = {};

  $score = getScore($chr, $pos, $ref, $alt);
  return {} unless $score;
  return {
      FATHMM_MKL_NC => $score,
  };
}
1;

