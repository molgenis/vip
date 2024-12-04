package ReMM;

use strict;
use warnings;

use Bio::EnsEMBL::Variation::Utils::BaseVepTabixPlugin;
use base qw(Bio::EnsEMBL::Variation::Utils::BaseVepTabixPlugin);

=head1 NAME
 ReMM
=head1 SYNOPSIS
 The Regulatory Mendelian Mutation (ReMM) score was created for relevance prediction of non-coding variations (SNVs and small InDels) in the human genome (hg19) in terms of Mendelian diseases
 ./vep -i variations.vcf --plugin ReMM,/FULL_PATH_TO_ReMM_file
=head1 DESCRIPTION
 The Regulatory Mendelian Mutation (ReMM) score was created for relevance prediction of non-coding variations (SNVs and small InDels) in the human genome (hg19) in terms of Mendelian diseases
 This plugin is build on top of the GREEN-DB dataset for ReMM scores: https://zenodo.org/records/3955933
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
      ReMM => "ReMM scores. The Regulatory Mendelian Mutation (ReMM) score was created for relevance prediction of non-coding variations (SNVs and small InDels) in the human genome (hg19) in terms of Mendelian diseases."
    }
}

sub getScore {
  my $chr = $_[0];
  my $pos = $_[1];

  # get candidate annotations from precomputed scores file
  my @data = @{$self->get_data($chr, $pos, $pos)};
  my $size = @data;
  my $line;
  my $score;
  foreach my $data_value (@data) {
    my @values = split("\t", $data_value);
    if(!$score || $score < $values[2]){
      $score = $values[2];
    }
  }
  return $score;
}

sub run {
  my ($self, $base_variation_feature_overlap_allele) = @_;

  # fail fast: sub-class doesn't contain variation_feature method
  return {} unless ($base_variation_feature_overlap_allele->can('variation_feature'));
	my $variation_feature = $base_variation_feature_overlap_allele->variation_feature;

  my $chr = $variation_feature->{chr};
  my $start = $variation_feature->{start};
  my $end = $variation_feature->{end};
  my $score;
  my $result = {};

  if($start == $end){
    $score = getScore($chr, $start);
  }
  else{
    my $scoreStart = getScore($chr, $start);
    my $scoreEnd = getScore($chr, $start);
    if(length $scoreStart && length $scoreEnd){
        $score = $scoreStart > $scoreEnd ? $scoreStart : $scoreEnd;
    }elsif(length $scoreStart){
        $score = $scoreStart;
    }else{
        $score = $scoreEnd;
    }
  }
  
  return {} unless $score;
  return {
      ReMM => $score,
  };
}
1;
