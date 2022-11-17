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

sub feature_types {
    return [ 'Transcript'];
}

sub get_header_info {
    return {
        VIPVaranLevel => "Score between 1 and 3 based on constraint level, fathmm, ncER, ReMM scores and region"
    };
}

sub run {
    my ($self, $transcript_variation_allele) = @_;

    print($transcript_variation_allele);
    my $base_variation_feature = $tva->base_variation_feature;
    my @vcf_line = @{$bvf->{_line}};
    print(@vcf_line);

    # score is 0 by default
    my $score = 0;

    # $region = something...
    # $fathmm = something..
    # $ReMM = something...
    # $ncER = something...
    # $constraint = something... 

    # Higher level = higher chance of pathogenicity 
    # If variant lays in in TFBS,DNase or UCNE = level 1
    # If variant has score of FATHMM above 0.5, ncER above 0.5 or ReMM above 0.499 and above = level 2
    # If variant has constraint value above 0.7 and above = level 3
    # Something with phenotype for level 4?
    # What if scores are sufficient but it is not in one of the regions?
    # Something with UTRAnnotator?

    my %min_scores = (	
     fathmm_min => 0.5,
     ncER_min => 0.5,
     ReMM_min => 0.499,
     constraint_min => 0.7
    );


    ## if region contains value
    unless($region_values eq "") {
        $region = 1;
    } else {
        $region = 0;
    }
    if($fathmm_score >= %min_scores{"fathmm_min"} || $ncER >= %min_scores{"ncER_min"} || ReMM >= %min_scores{"ReMM_min"}) {
        $score = 1;
    } else {
        $score = 0;
    }
    if($constraint_score >= %min_scores{"constraint_min"}) {
        $constraint = 1;
    } else {
        $constraint = 0;
    }

    if($region == 1 && $score == 1 && $constraint == 1) {
        $score = 3;
    } elsif($region == 1 && $score == 1 && $constraint == 0) {
        $score = 2;
    } elsif($region == 1 && $score == 0 && $constraint == 0) {
        $score = 1;
    } else {
        $score = 0;
    }
    

    return {
        #VIPVaranLevel => $results
        VIPVaranLevel => $score
    };
}

1;