package GADO;

use strict;
use warnings;

use Bio::EnsEMBL::Variation::Utils::BaseVepPlugin;
use base qw(Bio::EnsEMBL::Variation::Utils::BaseVepPlugin);

=head1 NAME
 GADO
=head1 SYNOPSIS
 
=head1 DESCRIPTION
 Plugin to annotate consequences with GADO scores modes based on their gene.
=cut

sub version {
    return '0.1';
}

sub feature_types {
    return ['Transcript'];
}

sub variant_feature_types {
    return ['VariationFeature'];
}

my $self;

sub get_header_info {
    $self = GADO->new;
    my $result;
    $result->{GADO_SC} = "The combined prioritization GADO Z-score over the supplied HPO terms for this case.";
    $result->{GADO_PD} = "The GADO predicion for the relation between the phenotypes and the gene, HC: high confidence, LC: low confidence.";
    return $result;
}

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
        if (defined $split[0] and length $split[0]){
            $mapping_data{$split[1]} = $split[0];
        }
    }
    return %mapping_data
}

sub run {
    my ($self, $transcript_variation_allele) = @_;
    my %gene_data = %{$self->{gene_data}};
    my %gene_mapping = %{$self->{gene_mapping}};
    my $transcript = $transcript_variation_allele->transcript;
    return {} unless ($transcript->{_gene_symbol_source} eq "EntrezGene");
    my $entrez_gene_id = $transcript->{_gene_stable_id};
    return {} unless $entrez_gene_id;
    my $ensembl_gene_id = $gene_mapping{$entrez_gene_id};
    return {} unless $ensembl_gene_id;
    my $result;
    my $gene_value = $gene_data{$ensembl_gene_id};
    return {} unless $gene_value;

    print $ensembl_gene_id;
    print $entrez_gene_id;

    my %gene_hash = %{$gene_value};
    my $score = $gene_hash{Zscore};
    $result->{GADO_SC} = $score;
    if($score >= 5){
        $result->{GADO_PD} = "HC";
    } elsif($score >= 3){
        $result->{GADO_PD} = "LC";
    }
    return $result;
}
1;