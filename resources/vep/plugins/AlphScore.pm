package AlphScore;

use strict;
use warnings;

use Bio::EnsEMBL::Variation::Utils::BaseVepTabixPlugin;
use base qw(Bio::EnsEMBL::Variation::Utils::BaseVepTabixPlugin);

=head1 NAME
 AlphScore
=head1 SYNOPSIS
 mv AlphScore.pm ~/.vep/Plugins
 ./vep -i variations.vcf --plugin AlphScore,/FULL_PATH_TO_ALPHSCORE_file
=head1 DESCRIPTION
 Plugin to annotate AlphScore scores as described in https://doi.org/10.1093/bioinformatics/btad280/7135835
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

sub feature_types {
  return ['Transcript'];
}

sub get_header_info {
    return {
      ALPHSCORE => "AlphScore_final scores as described in https://doi.org/10.1093/bioinformatics/btad280"
    }
}

sub run {
  my ($self, $transcript_variation_allele) = @_;

  # fail fast: plugin needs EntrezGene gene identifiers
  my $transcript = $transcript_variation_allele->transcript;
  return {} unless ($transcript->{_gene_symbol_source} eq "EntrezGene");

  # fail fast: plugin needs gene identifier
  my $entrez_gene_id = $transcript->{_gene_stable_id};
  return {} unless $entrez_gene_id;

  # fail fast: AlphScore only predicts pathogenicity of missense variants
	return {} unless grep {$_->SO_term =~ 'missense'} @{$transcript_variation_allele->get_all_OverlapConsequences};

  my @vcf_line = @{$transcript_variation_allele->variation_feature->{_line}};
  my $vcf_ref = $vcf_line[3];
  my $vcf_alt = $vcf_line[4];

  # fail fast: AlphScore precomputed scores only exist for SNPs
  return {} unless length($vcf_ref) == 1 && length($vcf_alt) == 1;

  my $vcf_chr = $vcf_line[0];
  my $vcf_pos = $vcf_line[1];

  # get candidate annotations from precomputed scores file
  my @data = @{$self->get_data($vcf_chr, $vcf_pos, $vcf_pos)};

  #list of lines, tab separated values
  my $result = {};

  for(@data) {
    my @values = split("\t", $_);
    my $as_ref = $values[2];
    my $as_alt = $values[3];

    if($as_ref eq $vcf_ref && $as_alt eq $vcf_alt) {
      my $as_score = $values[4];
      $result->{ALPHSCORE} = $as_score;
    }
  }
  
  return $result;
  };
1;

