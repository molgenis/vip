package VIPVaranLevel;

use strict;
use warnings;

use Bio::EnsEMBL::Variation::Utils::BaseVepPlugin;
use base qw(Bio::EnsEMBL::Variation::Utils::BaseVepPlugin);

=head1 NAME
 VIPVaranLevel
=head1 SYNOPSIS
 mv VIPVaranLevel.pm ~/.vep/Plugins
=head1 DESCRIPTION
 Plugin to annotate VIPVaran level per variant based on constraint level, fathmm, ncER, ReMM scores and region.
=cut

sub version {
    return '0.1';
}

# Feature includes regulatory features 
sub feature_types {
    return [ 'Transcript', 'Intergenic', 'Feature'];
}

sub get_header_info {
    return {
        VIPVaranLevel => "Score between 1 and 3 based on constraint level, fathmm, ncER, ReMM scores and region"
    };
}

my %min_scores = (	
  fathmm => 0.5,
  ncER => 0.5,
  ReMM => 0.499,
  constraint => 0.7
);

sub is_in_region {
    my $region_values = $_[0];

    ## if region contains value
    unless($region_values eq "") {
        return 1;
    } else {
        return 0;
    }
}

sub tool_min_score {
    my $fathmm_score = $_[0];
    my $ncER_score = $_[1];
    my $ReMM_score = $_[2];

    # add logic for when there are multiple scores for the same variant from the same tool.
    # example: 99.7852&99.7217  (can be more than 2) ReMM: 0.1710&0.9490&0.9560 (low and high score what to do?)
    if($fathmm_score >= $min_scores{"fathmm"} || $ncER_score >= $min_scores{"ncER"} || $ReMM_score >= $min_scores{"ReMM"}) {
        return 1;
    } else {
        return 0;
    }
}

sub constraint_min_score {
    my $constraint_score = $_[0];

    if ($constraint_score >= $min_scores{"constraint"}) {
        return 1;
    } else {
        return 0;
    }
}

sub run {
    my ($self, $transcript_variation_allele, $line_hash) = @_;

    my $base_variation_feature = $transcript_variation_allele->base_variation_feature;
    my @vcf_line = @{$base_variation_feature->{_line}};

    #my $data = @{$self->get_data}; get_data is not a thing
    
    # my $test3 = $self->ncER; werkt ook niet met $line_hash
    #my @test_data = @{$self->green_db_tool_scores};
    # code to write to file
    my $filename = '/groups/solve-rd/tmp10/projects/vip/feat/non-coding/test/VIPVaranLevel.log';
    open(my $file, '>>', $filename) or die $!;
    #print($file "HIER onder is vcf line");
    # foreach (@vcf_line) {
    #     print($file "$_\n"); 
    # }
    print($file "params\n");
    my @params_array = $self->{"params"};
    foreach ($params_array) {
        print($file "$_\n");
    }
    print($file "variant feature types\n");
    my @vft_array = $self->{"variant_feature_types"};
    foreach ($vft_array) {
        print($file "$_\n");
    }
    print($file "feature types\n");
    my @f_types_array = $self->{"feature_types"};
    foreach ($f_types_array) {
        print($file "$_\n");
    }
    # print($file "variant feature types wanted\n");
    # foreach my $variant_feature_wanted ($self->{"variant_feature_types_wanted"}) {
    #     foreach my $key (keys %$variant_feature_wanted) {
    #             print($file "in keys loop variant feature types wanted\n");
    #             print($file $key);
    #             print($file "=>");
    #             print($file $variant_feature_wanted->{$key});
    #             print($file "\n")
    #     }
    # }
    # print($file "feature types wanted\n");
    # foreach my $feature_wanted ($self->{"feature_types_wanted"}) {
    #     foreach my $key (keys %$feature_wanted) {
    #             print($file "in keys loop feature types wanted\n");
    #             print($file $key);
    #             print($file "=>");
    #             print($file $feature_wanted->{$key});
    #             print($file "\n")
    #     }
    # }
    # print($file "config\n");
    # foreach my $config ($self->{"config"}) {
    #     foreach my $key (keys %$config) {
    #             print($file "in keys loop config\n");
    #             print($file $key);
    #             print($file "=>");
    #             print($file $config->{$key});
    #             print($file "\n")
    #     }
    # }
    #print($file @vcf_line); # bevat chrom pos ref alt, 0 en 3x "." 
    # print($file $transcript_variation_allele); # is een hash
    close($file);
    # score is 0 by default
    my $score = 0;

    # $region = something...
    # $fathmm = something..
    # $ReMM = something...
    # $ncER = something...
    # $constraint = something...
    my $region = 0;
    my $fathmm_score = 0;
    my $ncER_score = 0; 
    my $ReMM_score = 0;
    my $constraint_score = 0;

    # Higher level = higher chance of pathogenicity 
    # If variant lays in in TFBS,DNase or UCNE = level 1
    # If variant has score of FATHMM above 0.5, ncER above 0.5 or ReMM above 0.499 and above = level 2
    # If variant has constraint value above 0.7 and above = level 3
    # Something with phenotype for level 4?
    # What if scores are sufficient but it is not in one of the regions?
    # Something with UTRAnnotator?

    if(is_in_region($region) && tool_min_score($fathmm_score, $ncER_score, $ReMM_score) && constraint_min_score($constraint_score)) {
        $score = 3;
    } elsif(is_in_region($region) && tool_min_score($fathmm_score, $ncER_score, $ReMM_score) && !constraint_min_score($constraint_score)) {
        $score = 2;
    } elsif(is_in_region($region) && !tool_min_score($fathmm_score, $ncER_score, $ReMM_score) && !constraint_min_score($constraint_score)) {
        $score = 1;
    } else {
        $score = 0;
    }
    
    # return {
    #     #VIPVaranLevel => $results
    #     VIPVaranLevel => $score
    # };
    #return $score;
    return {};
}
  
1;