package Vibe;

use strict;
use warnings;

use Bio::EnsEMBL::Variation::Utils::BaseVepPlugin;
use base qw(Bio::EnsEMBL::Variation::Utils::BaseVepPlugin);

=head1 NAME
 Vibe
=head1 SYNOPSIS
 mv Vibe.pm ~/.vep/Plugins
 ./vep -i variations.vcf --plugin Vibe,/FULL_PATH_TO_VIBE_FILE1;/FULL_PATH_TO_VIBE_FILE1
=head1 DESCRIPTION
 Plugin to annotate consequences with HPO flag based on Vibe output.
 Vibe can be found here: https://github.com/molgenis/vibe, and should be used with the -l/--simple-output option.
 Vibe output should be enriched with an headers specifying the HPO terms used, e.g.: #HPO=HP:123456,HP:123457
=cut

sub version {
    return '1.0';
}

sub feature_types {
    return [ 'Transcript' ];
}

sub get_header_info {
    return {
        HPO => "List of HPO terms for the gene",
    };
}

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);
    my @args = @{$self->params};

    my %entrez_gene_ids;
    foreach(@args){
        my $file = $_;
        die("ERROR: input file not specified\n") unless $file;
        open(FH, '<', $file) or die $!;

        my @hpo;
        while (<FH>) {
            my $vibe_line = $_;
            chomp($vibe_line);
            if ($vibe_line =~ /^#/) {
                if ($vibe_line =~ /^#HPO=(.*)/) {
                    (my $value = $1) =~ s/\r//g;
                    @hpo = split(",", $value);
                }
            }
            else {
                if (!@hpo) {
                    die("ERROR: input file misses #HPO header\n");
                }
                my @genes = split(',', $vibe_line);
                foreach my $entrez_gene_id ( @genes ) {
                    push(@{$entrez_gene_ids{$entrez_gene_id}}, @hpo);
                }
            }
        }
    }

    $self->{entrez_gene_ids} = \%entrez_gene_ids;
    return $self;
}

sub run {
    my ($self, $transcript_variation_allele) = @_;

    my $transcript = $transcript_variation_allele->transcript;
    return {} unless ($transcript->{_gene_symbol_source} eq "EntrezGene");

    my $entrez_gene_id = $transcript->{_gene_stable_id};
    my $entrez_gene_ids = $self->{entrez_gene_ids};
    my $hpo_ids = $entrez_gene_ids->{$entrez_gene_id};
    return {} unless $hpo_ids;
    return {
        HPO => join('&', @{$hpo_ids})
    };
}

1