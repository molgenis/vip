package GTEx;

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

my $self;

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
    $self = GTEx->new;
    my $result;
    my %tissues = map {$_ => 1} split(';', $self->params->[1]);

    $result->{"GTEx_Tissues"} = "GTEx tissues with a TPM > 1. (Filtered for input parameters:".(keys %tissues);
    foreach (keys %tissues) {
        my $desc = ("GTEx_" . $_);
        $desc =~ s/_/ /g;
        $result->{"GTEx_" . $_} = $desc . " TPM value.";
    }
    return $result;
}

sub new {
    if (!(defined $self)) {
        my $class = shift;
        $self = $class->SUPER::new(@_);
        my $GTExFile = $self->params->[0];

        my %tissues = map {$_ => 1} split(';', $self->params->[1]);
        die("ERROR: GTEx file not specified\n") unless $GTExFile;
        my %transcript_data = parseGTExFile($GTExFile);

        $self->{transcript_data} = \%transcript_data;
        $self->{tissues} = \%tissues;
    }
    return $self;
}

sub parseGTExFile {
    my %transcript_data;
    my $file = $_[0];
    open(FH, '<', $file) or die $!;

    my @split;

    while (<FH>) {
        my $line = $_;
        chomp($line);
        @split = split(/\t/, $line);
        my @transcript = split(/\./, $split[0]);
        $transcript_data{$transcript[0]} = {
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
    return %transcript_data
}

sub run {
    my ($self, $transcript_variation_allele) = @_;

    my $transcript = $transcript_variation_allele->transcript;

    my $transcript_value = $self->{transcript_data}->{$transcript->stable_id};
    return {} unless $transcript_value;
    
    return {} unless $transcript_value->{Adipose_Subcutaneous};

    my %tissues = %{$self->{tissues}};

    my $result = {};
    my $gtex_tissues = "";
    foreach (keys %tissues) {
        my $tissue = $_;
        $result->{"GTEx_" . $_} = $transcript_value->{$tissue};
        if($transcript_value->{$tissue} > 1){
            if($gtex_tissues){
                $gtex_tissues = $gtex_tissues.",".$tissue;
                    print "TEST1:$gtex_tissues|\n";
            }else{
                $gtex_tissues = $tissue;
                    print "TEST2:$gtex_tissues|\n";
            }
        }
    }
    print "TEST3:$gtex_tissues|\n";
    $result->{"GTEx_Tissues"} = $gtex_tissues;
    return $result;
}
1;