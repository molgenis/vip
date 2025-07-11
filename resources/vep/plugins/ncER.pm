package ncER;

use strict;
use warnings;

use Bio::EnsEMBL::Variation::Utils::BaseVepTabixPlugin;
use base qw(Bio::EnsEMBL::Variation::Utils::BaseVepTabixPlugin);

=head1 NAME
 ncER
=head1 SYNOPSIS
 mv ncER.pm ~/.vep/Plugins
 ./vep -i variations.vcf --plugin ncER,/FULL_PATH_TO_ncER_file
=head1 DESCRIPTION
 Plugin to annotate ncER(https://www.nature.com/articles/s41467-019-13212-3) scores.
 These scores indicate the likelyhood of a location being essential in terms of regulation.
 ncER file to be used is the tabixed version provided by GREEN-VARAN (https://github.com/edg1983/GREEN-VARAN) on Zenodo: https://zenodo.org/records/5636163
 For insertions the anchor based is used to obtain the scores, for larger variants the scores at the start en end position are compared and the highest is used.
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
      ncER => "ncER (https://www.nature.com/articles/s41467-019-13212-3) scores. This indicates the likelyhood of a location being essential in terms of regulation."
    }
}

sub getScore {
  my $chr = $_[0];
  my $one_based_pos = $_[1];

  #VEP is 1 based, bed 0 based -> correct the pos for that
  my $pos = $one_based_pos - 1;
  die "ERROR: Encountered a negative zero-based position" unless $pos >= 0;

  # get candidate annotations from precomputed scores file
  my @data = @{$self->get_data($chr, $pos, $pos)};

  my $size = @data;
  my $line;
  my $score;
  foreach my $data_value (@data) {
    my @values = split("\t", $data_value);
    if(!$score || $score < $values[3]){
      $score = $values[3];
    }
  }
  return $score;
}

sub run {
  my ($self, $base_variation_feature_overlap_allele) = @_;

  # fail fast: sub-class doesn't contain transcript method
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
    my $scoreEnd = getScore($chr, $end);
    if(length $scoreStart && length $scoreEnd){
        $score = $scoreStart > $scoreEnd ? $scoreStart : $scoreEnd;
    }elsif(length $scoreStart){
        $score = $scoreStart;
    }else{
        $score = $scoreEnd;
    }
  }

  if(length $score) {
    $result->{ncER} = $score;
  }
  
  return $result;
  };
1;

