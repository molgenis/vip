package AlphScore;

use strict;
use warnings;
use List::Util qw(max);

use Bio::EnsEMBL::Utils::Sequence qw(reverse_comp);
use Bio::EnsEMBL::Variation::Utils::Sequence qw(get_matched_variant_alleles);

use Bio::EnsEMBL::Variation::Utils::BaseVepTabixPlugin;
use Bio::EnsEMBL::Variation::VariationFeature;

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
        my $mappingFile = $self->params->[1];
        die("ERROR: input file not specified\n") unless $score_file;
        my %gene_mapping = parseMappingFile($mappingFile);

        $self->add_file($score_file);        
        $self->{gene_mapping} = \%gene_mapping;
    }
  return $self;
}

sub feature_types {
  return ['Transcript'];
}

sub get_header_info {
    $self = AlphScore->new;

    my $result;
    $result->{ALPHSCORE_FILE} = "file:" . $self->params->[0] . "'";
    $result->{ALPHSCORE} = "AlphScore_final scores as described in https://doi.org/10.1093/bioinformatics/btad280";
    return $result;
}

sub parseMappingFile {
    my %mapping_data;
    my $file = $_[0];
    open(MAPPING_FH, '<', $file) or die $!;

    my @split;
    while (<MAPPING_FH>) {
        my $line = $_;
        chomp($line);
        @split = split(/\t/, $line);
        #approved symbol
        if (defined $split[0] and length $split[0] and defined $split[3] and length $split[3]){
            $mapping_data{$split[0]} = $split[3];
        }
        #previous symbol
        if (defined $split[1] and length $split[1] and defined $split[3] and length $split[3]){
            $mapping_data{$split[1]} = $split[3];
        }
        #alias symbol
        if (defined $split[2] and length $split[2] and defined $split[3] and length $split[3]){
            $mapping_data{$split[2]} = $split[3];
        }
    }
    return %mapping_data
}

sub run {
  my ($self, $tva) = @_;
  my %gene_mapping = %{$self->{gene_mapping}};
  my $vf = $tva->variation_feature;
  my @vcf_line = @{$vf->{_line}};
  my $vcf_chr = $vcf_line[0];
  my $vcf_pos = $vcf_line[1];  
  my $vcf_ref = $vcf_line[3];
  my $vcf_alt = $vcf_line[4];
  my $vcf_gene = $tva->transcript->{_gene_stable_id};

  my $result = {};

  my @data = @{$self->get_data($vcf_chr, $vcf_pos, $vcf_pos)} if(defined $vcf_chr);
  #list of lines, tab separated values
  for(@data){
    my @values = split("\t", $_);
    my $as_ref = $values[2];
    my $as_alt = $values[3];
    my $as_score = $values[22];
    my $genes = $values[10];
    if($as_ref eq $vcf_ref && $as_alt eq $vcf_alt){
      if($genes){
        my @gene_symbols = split(";", $genes);
        for(@gene_symbols){
          if($gene_mapping{$_} eq $vcf_gene){
            $result->{ALPHSCORE} = $as_score;
            last;
          }
        }
      }
    }
  }
  
  return $result;
  };
1;

