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
        GTeX_Description => "Description.",
        GTeX_Adipose_Subcutaneous => "Adipose - Subcutaneous.",
        GTeX_Adipose_Visceral => "Adipose - Visceral (Omentum).",
        GTeX_AdrenalGland => "Adrenal Gland.",
        GTeX_Artery_Aorta => "Artery - Aorta.",
        GTeX_Artery_Coronary => "Artery - Coronary.",
        GTeX_Artery_Tibial => "Artery - Tibial.",
        GTeX_Bladder => "Bladder.",
        GTeX_Brain_Amygdala => "Brain - Amygdala.",
        GTeX_Brain_Anteriorcingulatecortex => "Brain - Anterior cingulate cortex (BA24).",
        GTeX_Brain_Caudate => "Brain - Caudate (basal ganglia).",
        GTeX_Brain_CerebellarHemisphere => "Brain - Cerebellar Hemisphere.",
        GTeX_Brain_Cerebellum => "Brain - Cerebellum.",
        GTeX_Brain_Cortex => "Brain - Cortex.",
        GTeX_Brain_FrontalCortex => "Brain - Frontal Cortex (BA9).",
        GTeX_Brain_Hippocampus => "Brain - Hippocampus.",
        GTeX_Brain_Hypothalamus => "Brain - Hypothalamus.",
        GTeX_Brain_Nucleusaccumbens => "Brain - Nucleus accumbens (basal ganglia).",
        GTeX_Brain_Putamen => "Brain - Putamen (basal ganglia).",
        GTeX_Brain_Spinalcord => "Brain - Spinal cord (cervical c-1).",
        GTeX_Brain_Substantianigra => "Brain - Substantia nigra.",
        GTeX_Breast_MammaryTissue => "Breast - Mammary Tissue.",
        GTeX_Cells_Culturedfibroblasts => "Cells - Cultured fibroblasts.",
        GTeX_Cells_EBV_transformedlymphocytes => "Cells - EBV-transformed lymphocytes.",
        GTeX_Cervix_Ectocervix => "Cervix - Ectocervix.",
        GTeX_Cervix_Endocervix => "Cervix - Endocervix.",
        GTeX_Colon_Sigmoid => "Colon - Sigmoid.",
        GTeX_Colon_Transverse => "Colon - Transverse.",
        GTeX_Esophagus_GastroesophagealJunction => "Esophagus - Gastroesophageal Junction.",
        GTeX_Esophagus_Mucosa => "Esophagus - Mucosa.",
        GTeX_Esophagus_Muscularis => "Esophagus - Muscularis.",
        GTeX_FallopianTube => "Fallopian Tube.",
        GTeX_Heart_AtrialAppendage => "Heart - Atrial Appendage.",
        GTeX_Heart_LeftVentricle => "Heart - Left Ventricle.",
        GTeX_Kidney_Cortex => "Kidney - Cortex.",
        GTeX_Kidney_Medulla => "Kidney - Medulla.",
        GTeX_Liver => "Liver.",
        GTeX_Lung => "Lung.",
        GTeX_MinorSalivaryGland => "Minor Salivary Gland.",
        GTeX_Muscle_Skeletal => "Muscle - Skeletal.",
        GTeX_Nerve_Tibial => "Nerve - Tibial.",
        GTeX_Ovary => "Ovary.",
        GTeX_Pancreas => "Pancreas.",
        GTeX_Pituitary => "Pituitary.",
        GTeX_Prostate => "Prostate.",
        GTeX_Skin_NotSunExposed => "Skin - Not Sun Exposed (Suprapubic).",
        GTeX_Skin_SunExposed => "Skin - Sun Exposed (Lower leg).",
        GTeX_SmallIntestine_TerminalIleum => "Small Intestine - Terminal Ileum.",
        GTeX_Spleen => "Spleen.",
        GTeX_Stomach => "Stomach.",
        GTeX_Testis => "Testis.",
        GTeX_Thyroid => "Thyroid.",
        GTeX_Uterus => "Uterus.",
        GTeX_Vagina => "Vagina.",
        GTeX_WholeBlood => "Whole Blood."
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
    
    return {} unless $gene_value->{Adipose_Subcutaneous};

    return {
        GTeX_Adipose_Subcutaneous => $gene_value->{Adipose_Subcutaneous},
        GTeX_Adipose_Visceral => $gene_value->{Adipose_Visceral},
        GTeX_AdrenalGland => $gene_value->{AdrenalGland},
        GTeX_Artery_Aorta => $gene_value->{Artery_Aorta},
        GTeX_Artery_Coronary => $gene_value->{Artery_Coronary},
        GTeX_Artery_Tibial => $gene_value->{Artery_Tibial},
        GTeX_Bladder => $gene_value->{Bladder},
        GTeX_Brain_Amygdala => $gene_value->{Brain_Amygdala},
        GTeX_Brain_Anteriorcingulatecortex => $gene_value->{Brain_Anteriorcingulatecortex},
        GTeX_Brain_Caudate => $gene_value->{Brain_Caudate},
        GTeX_Brain_CerebellarHemisphere => $gene_value->{Brain_CerebellarHemisphere},
        GTeX_Brain_Cerebellum => $gene_value->{Brain_Cerebellum},
        GTeX_Brain_Cortex => $gene_value->{Brain_Cortex},
        GTeX_Brain_FrontalCortex => $gene_value->{Brain_FrontalCortex},
        GTeX_Brain_Hippocampus => $gene_value->{Brain_Hippocampus},
        GTeX_Brain_Hypothalamus => $gene_value->{Brain_Hypothalamus},
        GTeX_Brain_Nucleusaccumbens => $gene_value->{Brain_Nucleusaccumbens},
        GTeX_Brain_Putamen => $gene_value->{Brain_Putamen},
        GTeX_Brain_Spinalcord => $gene_value->{Brain_Spinalcord},
        GTeX_Brain_Substantianigra => $gene_value->{Brain_Substantianigra},
        GTeX_Breast_MammaryTissue => $gene_value->{Breast_MammaryTissue},
        GTeX_Cells_Culturedfibroblasts => $gene_value->{Cells_Culturedfibroblasts},
        GTeX_Cells_EBV_transformedlymphocytes => $gene_value->{Cells_EBV_transformedlymphocytes},
        GTeX_Cervix_Ectocervix => $gene_value->{Cervix_Ectocervix},
        GTeX_Cervix_Endocervix => $gene_value->{Cervix_Endocervix},
        GTeX_Colon_Sigmoid => $gene_value->{Colon_Sigmoid},
        GTeX_Colon_Transverse => $gene_value->{Colon_Transverse},
        GTeX_Esophagus_GastroesophagealJunction => $gene_value->{Esophagus_GastroesophagealJunction},
        GTeX_Esophagus_Mucosa => $gene_value->{Esophagus_Mucosa},
        GTeX_Esophagus_Muscularis => $gene_value->{Esophagus_Muscularis},
        GTeX_FallopianTube => $gene_value->{FallopianTube},
        GTeX_Heart_AtrialAppendage => $gene_value->{Heart_AtrialAppendage},
        GTeX_Heart_LeftVentricle => $gene_value->{Heart_LeftVentricle},
        GTeX_Kidney_Cortex => $gene_value->{Kidney_Cortex},
        GTeX_Kidney_Medulla => $gene_value->{Kidney_Medulla},
        GTeX_Liver => $gene_value->{Liver},
        GTeX_Lung => $gene_value->{Lung},
        GTeX_MinorSalivaryGland => $gene_value->{MinorSalivaryGland},
        GTeX_Muscle_Skeletal => $gene_value->{Muscle_Skeletal},
        GTeX_Nerve_Tibial => $gene_value->{Nerve_Tibial},
        GTeX_Ovary => $gene_value->{Ovary},
        GTeX_Pancreas => $gene_value->{Pancreas},
        GTeX_Pituitary => $gene_value->{Pituitary},
        GTeX_Prostate => $gene_value->{Prostate},
        GTeX_Skin_NotSunExposed => $gene_value->{Skin_NotSunExposed},
        GTeX_Skin_SunExposed => $gene_value->{Skin_SunExposed},
        GTeX_SmallIntestine_TerminalIleum => $gene_value->{SmallIntestine_TerminalIleum},
        GTeX_Spleen => $gene_value->{Spleen},
        GTeX_Stomach => $gene_value->{Stomach},
        GTeX_Testis => $gene_value->{Testis},
        GTeX_Thyroid => $gene_value->{Thyroid},
        GTeX_Uterus => $gene_value->{Uterus},
        GTeX_Vagina => $gene_value->{Vagina},
        GTeX_WholeBlood => $gene_value->{WholeBlood}
    };
}
1;