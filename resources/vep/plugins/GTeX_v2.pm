package GTeX;

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

sub feature_types {
    return ['Transcript'];
}

sub variant_feature_types {
    return ['VariationFeature'];
}

sub get_header_info {
    return {
        GTeX_Tissues => "GTeX tissues with median TPM > 0.5",
    };
}

my $self;

sub new {
    if (!(defined $self)) {
        my $class = shift;
        $self = $class->SUPER::new(@_);
        my $gtexFile = $self->params->[0];
        my $mappingFile = $self->params->[1];

        die("ERROR: GTeX file not specified\n") unless $gtexFile;
        die("ERROR: Gene mapping file not specified\n") unless $mappingFile;
        my %gene_data = parseGTeXFile($gtexFile);
        my %gene_mapping = parseMappingFile($mappingFile);

        $self->{gene_mapping} = \%gene_mapping;
        $self->{gene_data} = \%gene_data;
    }
    return $self;
}

sub parseGTeXFile {
    my %gene_data;
    my $file = $_[0];
    open(FH, '<', $file) or die $!;

    my @split;

    while (<FH>) {
        my $line = $_;
        chomp($line);
        @split = split(/\t/, $line);
        my @gene = split(/\./, $split[0]);
        $gene_data{$gene[0]} = {
            Adipose_Subcutaneous => $split[2],
            Adipose_Visceral => $split[3],
            AdrenalGland => $split[4],
            Artery_Aorta => $split[5],
            Artery_Coronary => $split[6],
            Artery_Tibial => $split[7],
            Bladder => $split[8],
            Brain_Amygdala => $split[9],
            Brain_Anteriorcingulatecortex => $split[10],
            Brain_Caudate => $split[11],
            Brain_CerebellarHemisphere => $split[12],
            Brain_Cerebellum => $split[13],
            Brain_Cortex => $split[14],
            Brain_FrontalCortex => $split[15],
            Brain_Hippocampus => $split[16],
            Brain_Hypothalamus => $split[17],
            Brain_Nucleusaccumbens => $split[19],
            Brain_Putamen => $split[19],
            Brain_Spinalcord => $split[20],
            Brain_Substantianigra => $split[21],
            Breast_MammaryTissue => $split[22],
            Cells_Culturedfibroblasts => $split[23],
            Cells_EBV_transformedlymphocytes => $split[24],
            Cervix_Ectocervix => $split[25],
            Cervix_Endocervix => $split[26],
            Colon_Sigmoid => $split[27],
            Colon_Transverse => $split[28],
            Esophagus_GastroesophagealJunction => $split[29],
            Esophagus_Mucosa => $split[30],
            Esophagus_Muscularis => $split[31],
            FallopianTube => $split[32],
            Heart_AtrialAppendage => $split[33],
            Heart_LeftVentricle => $split[34],
            Kidney_Cortex => $split[35],
            Kidney_Medulla => $split[36],
            Liver => $split[37],
            Lung => $split[38],
            MinorSalivaryGland => $split[39],
            Muscle_Skeletal => $split[40],
            Nerve_Tibial => $split[41],
            Ovary => $split[42],
            Pancreas => $split[43],
            Pituitary => $split[44],
            Prostate => $split[45],
            Skin_NotSunExposed => $split[46],
            Skin_SunExposed => $split[47],
            SmallIntestine_TerminalIleum => $split[48],
            Spleen => $split[49],
            Stomach => $split[50],
            Testis => $split[51],
            Thyroid => $split[52],
            Uterus => $split[53],
            Vagina => $split[54],
            WholeBlood => $split[55]
        };
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

    my $transcript = $transcript_variation_allele->transcript;
    return {} unless ($transcript->{_gene_symbol_source} eq "EntrezGene");

    my $entrez_gene_id = $transcript->{_gene_stable_id};
    return {} unless $entrez_gene_id;

    my $ensembl_gene_id = $self->{gene_mapping}->{$entrez_gene_id};
    return {} unless $ensembl_gene_id;

    my $gene_value = $self->{gene_data}->{$ensembl_gene_id};
    return {} unless $gene_value;
    
    my $gtex_exists = $gene_value->{Adipose_Subcutaneous};
    return {} unless $gtex_exists;

    my $gtex_tissues = "";

    my %gtex = %{$gene_value};

    $gtex_tissues = "";
    foreach my $key (keys %gtex) {
         if($gtex{$key} > 0.5){
            if($gtex_tissues){
                $gtex_tissues = $gtex_tissues.",".$key;
            }else{
                $gtex_tissues = $key;
            }
        }
    }

    return {
        GTeX_Tissues => $gtex_tissues
    };
}
1;