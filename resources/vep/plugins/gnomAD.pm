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
    gnomAD_AF => "gnomAD allele frequency",
    gnomAD_HN => "gnomAD number of homozygotes"
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
  my ($chr, $pos, $ref, $alt, $af, $hn) = split /\t/, $line;


  return {
    chr => $chr,
    pos => $pos,
    ref => $ref,
    alt => $alt,
    result => {
      # when adding elements with nullable values make sure to map "." to undef
      gnomAD_AF => $af,
      gnomAD_HN => $hn
    }
  };
}

1;