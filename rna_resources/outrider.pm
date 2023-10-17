package outrider;

use strict;
use warnings;

use Bio::EnsEMBL::Variation::Utils::BaseVepPlugin;
use base qw(Bio::EnsEMBL::Variation::Utils::BaseVepPlugin);

=head1 NAME
 outrider
=head1 SYNOPSIS
 mv outrider.pm ~/.vep/Plugins
 ./vep -i variations.vcf --plugin outrider,/PATH_TO_OUTRIDER_RESULTS,ensembl_ncbi_gene_id_mapping.tsv
=head1 DESCRIPTION
 Plugin to annotate classifications of variants as provided by the OUTRIDER tool
=cut

sub version {
    return '1.0';
}

sub feature_types {
    return ['Transcript'];
}

sub variant_feature_types {
    return ['VariationFeature'];
}

my $self;

# Create a new object
sub new {
    if (!(defined $self)) {
        my $class = shift;
        $self = $class->SUPER::new(@_);
        # Load files
        my $outriderFile = $self->params->[0];
        my $mappingFile = $self->params->[1];

        die("ERROR: Outrider output file not specified\n") unless $gadoFile;
        die("ERROR: Gene mapping file not specified\n") unless $mappingFile;
        my %gene_data = parseFile($outriderFile);
        my %gene_mapping = parseMappingFile($mappingFile);

        # Create maps for results and mapping
        $self->{gene_mapping} = \%gene_mapping;
        $self->{gene_data} = \%gene_data;
    }
    return $self;
}

# Parse outrider results
sub parseFile {
    my %gene_data;
    my $file = $_[0];
    open(FH, '<', $file) or die $!;

    my @split;

    # Loop through tsv and save results for each gene
    while (<FH>) {
        my $line = $_;
        chomp($line);
        @split = split(/\t/, $line);
        $gene_data{$split[0]} = {AE => $split[11], Pval => $split[3], Zscore => $split[4]};
    }
    return %gene_data
}

# Parse mapping file
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

# Run plugin, return results if in VCF, otherwise return {}
sub run {
    my ($self, $transcript_variation_allele) = @_;

    my $transcript = $transcript_variation_allele->transcript;
    return {} unless ($transcript->{_gene_symbol_source} eq "EntrezGene");

    my $entrez_gene_id = $transcript->{_gene_stable_id};
    return {} unless $entrez_gene_id;

    my $ensembl_gene_id = $self->{gene_mapping}->{$entrez_gene_id};
    return {} unless $ensembl_gene_id;

    my $gene_value = $self->{gene_data}->{$ensembl_gene_id};
    return {} unless $gene_value;
    
    my $significance = $gene_value->{Pval};
    return {} unless $significance;

    my $expression = $gene_value->{AE};
    my $score = $gene_value->{Zscore};

    return {
        AE_Pval => $significance,
        AberrantExpression => $expression,
        AE_Zscore => $score
    };
}
1;
