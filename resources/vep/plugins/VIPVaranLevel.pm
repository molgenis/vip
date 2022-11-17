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

    print($transcript_variation_allele)
    #my @results = ... # do analysis

    return {
        VIPVaranLevel => $results
    };
}

1;