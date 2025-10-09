package BrainMagnet;

use strict;
use warnings;

use Bio::EnsEMBL::Variation::Utils::BaseVepTabixPlugin;
use base qw(Bio::EnsEMBL::Variation::Utils::BaseVepTabixPlugin);

=head1 NAME
 BRAIN_MAGNET
=head1 SYNOPSIS
 BRAIN-MAGNET predictions for all possible bases from NSC NCREs
 ./vep -i variations.vcf --plugin BrainMagnet,path/to/BRAIN_MAGNET_scores_hg38.txt.bgz
=head1 DESCRIPTION
 Predict the contribution scores of non-coding regulatory elements (NCREs) in human neural stem cells from BRAIN-MAGNET (Deng et al.) https://doi.org/10.1101/2024.04.13.24305761 .
 This plugin is build for the BRAIN-MAGNET scores provided: https://github.com/ruizhideng/BRAIN-MAGNET
 BRAIN_MAGNET_scores_hg38.txt.bgz and index file can be downloaded from: https://huggingface.co/datasets/RuizhiDeng/BRAIN-MAGNET/tree/main
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
      BRAIN_MAGNET_CB_EACH => "BRAIN-MAGNET cb_each normalized percentile 0-100 predictions for all possible SNPs from Neural Stem Cells NSC Non-coding regulatory elements NCREs (~100 million)"
    }
}

sub getScore {
  my $chr = $_[0];
  my $pos = $_[1];

  # get candidate annotations from precomputed scores file
  my @data = @{$self->get_data($chr, $pos, $pos)};
  for my $line (@data) {
    my @values = split("\t", $line);
    return $values[7];
  }
}

sub run {
  my ($self, $base_variation_feature_overlap_allele) = @_;

  my @line = @{$base_variation_feature_overlap_allele->base_variation_feature->{_line}};
  my $chr = $line[0];
  my $pos = $line[1];
  my $score;
  my $result = {};

  $score = getScore($chr, $pos);
  return {} unless $score;
  return {
      BRAIN_MAGNET_CB_EACH => $score,
  };
}
1;

