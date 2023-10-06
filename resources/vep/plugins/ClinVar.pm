package ClinVar;

use strict;
use warnings;

use Bio::EnsEMBL::Variation::Utils::BaseVepTabixPlugin;
use base qw(Bio::EnsEMBL::Variation::Utils::BaseVepTabixPlugin);

=head1 NAME
 ClinVar
=head1 SYNOPSIS
 mv ClinVar.pm ~/.vep/Plugins
 ./vep -i variations.vcf --plugin ClinVar,/FULL_PATH_TO_CLINVAR_FILE
=head1 DESCRIPTION
 Plugin to annotate ClinVar CLNSIG,CLNSIGINCL,CLNREVSTAT values, see https://www.ncbi.nlm.nih.gov/clinvar/.
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
    clinVar_CLNID => "ClinVar variation identifier", 
    clinVar_CLNSIG => "Clinical significance for this single variant; multiple values are separated by a vertical bar",
    clinVar_CLNSIGINCL => "Clinical significance for a haplotype or genotype that includes this variant. Reported as pairs of VariationID:clinical significance; multiple values are separated by a vertical bar",
    clinVar_CLNREVSTAT => "ClinVar review status for the Variation ID"
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

sub parse_data {
  my ($self, $line) = @_;
  my ($chr, $pos, $cln_id, $ref, $alt, $clin_sig, $clin_sig_incl, $cln_rev_stat) = split /\t/, $line;

  # when adding result elements with nullable values make sure to map "." to undef
  return {
    chr => $chr,
    pos => $pos,
    ref => $ref,
    alt => $alt,
    result => {
      # when adding elements with nullable values make sure to map "." to undef
      clinVar_CLNID => $cln_id ne "." ? $cln_id : undef,
      clinVar_CLNSIG => $clin_sig ne "." ? $clin_sig : undef,
      clinVar_CLNSIGINCL => $clin_sig_incl ne "." ? $clin_sig_incl : undef,
      clinVar_CLNREVSTAT => $cln_rev_stat  ne "." ? $cln_rev_stat : undef
    }
  };
}

1;