package GREEN_DB;

use strict;
use warnings;

use Bio::EnsEMBL::Variation::Utils::BaseVepTabixPlugin;
use base qw(Bio::EnsEMBL::Variation::Utils::BaseVepTabixPlugin);

=head1 NAME
 GREEN_DB
=head1 SYNOPSIS
 mv GREEN_DB.pm ~/.vep/Plugins
 ./vep -i variations.vcf --plugin GREEN_DB,/FULL_PATH_TO_GREEN_DB_file
=head1 DESCRIPTION
 TODO GREEN_DB
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

sub getScores {
  my $chr = $_[0];
  my $one_based_pos = $_[1];

  #VEP is 1 based, bed 0 based -> correct the pos for that
  my $pos = $one_based_pos - 1;
  die "ERROR: Encountered a negative zero-based position" unless $pos >= 0;

  # get candidate annotations from precomputed scores file
  my @data = @{$self->get_data($chr, $pos, $pos)};

  my $size = @data;
  die("ERROR: Expecting no more than one score for a position.\n") unless $size <= 1;
  if($size == 0){
    return;
  }

  my %values;

  if($size > 1){
    for my $i (0 .. $#data) {
      my @line = split("\t", $data[0]);
      if(!$values{$line[4]} || $line[6] > $values{$line[4]}){
        $values{$line[4]} = $line[6];
      }
    }
  }
  return %values;
}

sub run {
  my ($self, $base_variation_feature_overlap_allele) = @_;

  # fail fast: sub-class doesn't contain transcript method
  return {} unless ($base_variation_feature_overlap_allele->can('variation_feature'));
	my $variation_feature = $base_variation_feature_overlap_allele->variation_feature;

  my $chr = $variation_feature->{chr};
  my $start = $variation_feature->{start};
  my $end = $variation_feature->{end};
  my %scores;
  my $result = {};

  %scores = getScore($chr, $start);

  $result->{GDB_PRO} = $scores{"promotor"};
  $result->{GDB_ENH} = $scores{"enhancer"};
  $result->{GDB_BIV} = $scores{"bivalent"};
  $result->{GDB_SIL} = $scores{"silencer"};
  $result->{GDB_INS} = $scores{"insulator"};
  
  return $result;
  };
1;

