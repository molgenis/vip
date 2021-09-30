package Inheritance;

use strict;
use warnings;

use Bio::EnsEMBL::Variation::Utils::BaseVepPlugin;
use base qw(Bio::EnsEMBL::Variation::Utils::BaseVepPlugin);

=head1 NAME
 Inheritance
=head1 SYNOPSIS
 mv Inheritance.pm ~/.vep/Plugins
 ./vep -i variations.vcf --plugin Inheritance,/FULL_PATH_TO_PREPROCESSED_INHERITANCE_FILE/gene_inheritance_modes.tsv
 Or, to include hpo phenotypes:
 ./vep -i variations.vcf --plugin Inheritance,/FULL_PATH_TO_PREPROCESSED_INHERITANCE_FILE/gene_inheritance_modes.tsv,1
=head1 DESCRIPTION
 Plugin to annotate consequences with inheritance modes based on their gene.
=head1 MAPPING
 Y-LINKED: YL
 X-LINKED DOMINANT: XD
 X-LINKED RECESSIVE: XR
 X-LINKED: XL
 AUTOSOMAL RECESSIVE: AR
 AUTOSOMAL DOMINANT: AD
 PSEUDOAUTOSOMAL RECESSIVE: PR
 PSEUDOAUTOSOMAL DOMINANT: PD
 ISOLATED CASES: IC
 DIGENIC: DG
 DIGENIC RECESSIVE: DGR
 DIGENIC DOMINANT: DGD
 MITOCHONDRIAL: MT
 MULTIFACTORIAL: MF
 SOMATIC MUTATION: SM
 SOMATIC MOSAICISM: SMM
 INHERITED CHROMOSOMAL IMBALANCE: ICI
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

sub get_header_info {
    my $self = Inheritance->new;
    my $result;
    $result->{InheritanceModesGene} = "List of inheritance modes for the gene";
    if ($self->{include_pheno}) {
        $result->{InheritanceModesPheno} = "List of inheritance modes for provided HPO terms";
    }
    return $result;
}

my $self;

sub new {
    if (!(defined $self)) {
        my $class = shift;
        $self = $class->SUPER::new(@_);
        my $file = $self->params->[0];
        $self->{include_pheno} = $self->params->[1];

        my %gene_data;
        my %pheno_data;

        die("ERROR: input file not specified\n") unless $file;
        open(FH, '<', $file) or die $!;

        my @split;

        while (<FH>) {
            @split = split(/\t/, $_);
            $gene_data{$split[0]} = $split[1];
            my $pheno = $split[2];
            chomp $pheno;
            if ($pheno ne "") {
                $pheno_data{$split[0]} = $pheno;
            }
        }

        $self->{gene_data} = \%gene_data;
        $self->{pheno_data} = \%pheno_data;
    }
    return $self;
}

sub run {
    my ($self, $transcript_variation_allele) = @_;
    my $gene_data = $self->{gene_data};
    my $pheno_data = $self->{pheno_data};

    my $transcript = $transcript_variation_allele->transcript;
    return {} unless ($transcript->{_gene_symbol_source} eq "EntrezGene");

    my $entrez_gene_id = $transcript->{_gene_stable_id};
    return {} unless $entrez_gene_id;
    my $result;
    $result->{InheritanceModesGene} = $gene_data->{$entrez_gene_id};
    if (defined $self->{include_pheno} && $pheno_data->{$entrez_gene_id}) {
        $result->{InheritanceModesPheno} = $pheno_data->{$entrez_gene_id};
    }
    return $result;
}
1;