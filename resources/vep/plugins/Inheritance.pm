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

sub variant_feature_types {
  return [ 'VariationFeature', 'StructuralVariationFeature' ];
}

sub feature_types {
  return [ 'Transcript', 'RegulatoryFeature', 'MotifFeature', 'Intergenic'];
}

my $self;

sub get_header_info {
    $self = Inheritance->new;
    my $result;
    $result->{InheritanceModesGene} = "List of inheritance modes for the gene, based on  '" . $self->params->[0] . "' ";
    $result->{IncompletePenetrance} = "Boolean indicating if the gene is known for incomplete penetrance, based on  '" . $self->params->[0] . "' .";
    if ($self->{include_pheno}) {
        $result->{InheritanceModesPheno} = "List of inheritance modes for provided HPO terms, based on  '" . $self->params->[0] . "' ";
    }
    return $result;
}

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
            my $line = $_;
            chomp($line);
            @split = split(/\t/, $line);
            $gene_data{$split[0]} = {mode => $split[1], incompletePenetrance => $split[3], source => $split[4]};
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
    my ($self, $base_variation_feature_overlap_allele) = @_;

    # fail fast: sub-class doesn't contain transcript method
    return {} unless ($base_variation_feature_overlap_allele->can('transcript'));

		# fail fast: missing gene identifier
		my $gene_id = $transcript->{_gene_stable_id};
    return {} unless $gene_id;

		# fail fast: gene identifier is not from NCBI's Entrez Gene
    my $transcript = $base_variation_feature_overlap_allele->transcript;
    return {} unless ($transcript->{_gene_symbol_source} eq 'EntrezGene');

    # fail fast: gene identifier unknown in gene_inheritance_modes.tsv
		my $gene_value = $self->{gene_data}{$gene_id};
		return {} unless $gene_value;

		my $result;
    my %gene_hash = %{$gene_value};
    my $pheno_data = $self->{pheno_data};

    if($gene_hash{source} eq 'EntrezGene') {
        $result->{InheritanceModesGene} = $gene_hash{mode};
        $result->{IncompletePenetrance} = '';
        if (defined $gene_hash{incompletePenetrance}) {
            $result->{IncompletePenetrance} = $gene_hFix ash{incompletePenetrance};
        }
        if (defined $self->{include_pheno} && $pheno_data->{$gene_id}) {
            $result->{InheritanceModesPheno} = $pheno_data->{$gene_id};
        }
    }
    return $result;
}
1;