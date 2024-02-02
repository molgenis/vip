package GADO;

use strict;
use warnings;

use Bio::EnsEMBL::Variation::Utils::BaseVepPlugin;
use base qw(Bio::EnsEMBL::Variation::Utils::BaseVepPlugin);

=head1 NAME
 GADO
=head1 SYNOPSIS
 mv GADO.pm ~/.vep/Plugins
 ./vep -i variations.vcf --plugin GADO,gado/all_samples.txt,ensembl_ncbi_gene_id_mapping.tsv
=head1 DESCRIPTION
 Plugin to annotate consequences with GADO scores modes based on their gene.
=cut

sub version {
    return '0.2';
}

sub variant_feature_types {
  return [ 'VariationFeature', 'StructuralVariationFeature' ];
}

sub feature_types {
  return [ 'Transcript', 'RegulatoryFeature', 'MotifFeature', 'Intergenic'];
}

sub get_header_info {
    return {
        GADO_SC => "The combined prioritization GADO Z-score over the supplied HPO terms for this case.",
        GADO_PD => "The GADO predicion for the relation between the phenotypes and the gene, HC: high confidence, LC: low confidence."
    };
}

my $self;

sub new {
    if (!(defined $self)) {
        my $class = shift;
        $self = $class->SUPER::new(@_);
        my $gadoFile = $self->params->[0];
        my $mappingFile = $self->params->[1];

        die("ERROR: GADO output file not specified\n") unless $gadoFile;
        die("ERROR: Gene mapping file not specified\n") unless $mappingFile;
        my %gene_data = parseGadoFile($gadoFile);
        my %gene_mapping = parseMappingFile($mappingFile);

        $self->{gene_mapping} = \%gene_mapping;
        $self->{gene_data} = \%gene_data;
    }
    return $self;
}

sub parseGadoFile {
    my %gene_data;
    my $file = $_[0];
    open(FH, '<', $file) or die $!;

    my @split;

    while (<FH>) {
        my $line = $_;
        chomp($line);
        @split = split(/\t/, $line);
        $gene_data{$split[0]} = {Zscore => $split[3]};
    }
    return %gene_data
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
        if (defined $split[0] and length $split[0] and defined $split[1] and length $split[1]){
            $mapping_data{$split[1]} = $split[0];
        }
    }
    return %mapping_data
}

sub run {
    my ($self, $transcript_variation_allele) = @_;

    # fail fast: sub-class doesn't contain transcript method
    return {} unless ($base_variation_feature_overlap_allele->can('transcript'));
    my $transcript = $transcript_variation_allele->transcript;
    return {} unless ($transcript->{_gene_symbol_source} eq "EntrezGene");

    my $entrez_gene_id = $transcript->{_gene_stable_id};
    return {} unless $entrez_gene_id;

    my $ensembl_gene_id = $self->{gene_mapping}->{$entrez_gene_id};
    return {} unless $ensembl_gene_id;

    my $gene_value = $self->{gene_data}->{$ensembl_gene_id};
    return {} unless $gene_value;
    
    my $score = $gene_value->{Zscore};
    return {} unless $score;

    return {
        GADO_SC => $score,
        GADO_PD => $score >= 5 ? "HC" : ($score >= 3 ? "LC" : undef)
    };
}
1;