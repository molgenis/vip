package GREEN_DB;

use strict;
use warnings;

use Bio::EnsEMBL::Variation::Utils::BaseVepTabixPlugin;
use base qw(Bio::EnsEMBL::Variation::Utils::BaseVepTabixPlugin);

=head1 NAME
 GREEN-DB constraint score annotations
=head1 SYNOPSIS
 mv GREEN_DB.pm ~/.vep/Plugins
 ./vep -i variations.vcf --plugin GREEN_DB,/FULL_PATH_TO_GREEN_DB_file
=head1 DESCRIPTION
 Plugin to annotate GREEN-DB constrain score for each of the GREEN-DB region types; enhancer, silencer, bivalent, promoter, insulator.
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
      GDB_PRO => "GREEN_DB Promotor maximum constraint score.",
      GDB_ENH => "GREEN_DB Enhancer maximum constraint score.",
      GDB_BIV => "GREEN_DB Bivalent maximum constraint score.",
      GDB_SIL => "GREEN_DB Silencer maximum constraint score.",
      GDB_INS => "GREEN_DB Insulator maximum constraint score."
    }
}

sub get_scores {
  my $chr = $_[0];
  my $one_based_start = $_[1];
  my $one_based_end = $_[2];

  my $start = $one_based_start - 1;
  my $end = $one_based_end - 1;
  #VEP is 1 based, bed 0 based -> correct the positions for that
  die "ERROR: Encountered a negative zero-based position" unless $start >= 0 && $end >= 0;

  # get candidate annotations from precomputed scores file
  my @data;
  if($start <= $end){
    @data = @{$self->get_data($chr, $start, $end)};
  }else{
    #structural variant on the reverse strand
    @data = @{$self->get_data($chr, $end, $start)};
  }

  my $size = @data;
  if($size == 0){
    return;
  }

  my $values;

  #if data is present
  if($size >= 1){
    for my $i (0 .. $#data) {
      my @line = split("\t", $data[0]);
      #if no value present for the type of region (line[4]), or the current line has a higher score (line[6]) for this type of region, add/overwrite it in the result.
      if(!$values->{$line[4]} || $line[8] > $values->{$line[4]}){
        if($line[8] != "NA"){
          $values->{$line[4]} = $line[8];
        }
      }
    }
  }
  return $values;
}

sub run {
  my ($self, $base_variation_feature_overlap_allele) = @_;

  # fail fast: sub-class doesn't contain transcript method
  return {} unless ($base_variation_feature_overlap_allele->can('variation_feature'));
	my $variation_feature = $base_variation_feature_overlap_allele->variation_feature;

  my $chr = $variation_feature->{chr};
  my $start = $variation_feature->{start};
  my $end = $variation_feature->{end};
  my $result = {};

  my $scores = get_scores($chr, $start, $end);

  $result->{GDB_PRO} = $scores->{"promoter"};
  $result->{GDB_ENH} = $scores->{"enhancer"};
  $result->{GDB_BIV} = $scores->{"bivalent"};
  $result->{GDB_SIL} = $scores->{"silencer"};
  $result->{GDB_INS} = $scores->{"insulator"};
  
  return $result;
  };
1;

