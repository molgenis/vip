package Hpo;

use strict;
use warnings;

use Bio::EnsEMBL::Variation::Utils::BaseVepPlugin;
use base qw(Bio::EnsEMBL::Variation::Utils::BaseVepPlugin);

=head1 NAME
 Hpo
=head1 SYNOPSIS
 mv Hpo.pm ~/.vep/Plugins
 ./vep -i variations.vcf --plugin Hpo,/FULL_PATH_TO_GENES_TO_PHENOTYPE_FILE/genes_to_phenotype.tsv,HP:0000275\;HP:0000276
=head1 DESCRIPTION
 Plugin to annotate consequences with HPO flag based on given HPO identifiers.
 See `utils/create_hpo.sh` in the VIP repo on how to generate the genes_to_phenotype.tsv input file.
=cut

sub version {
    return '1.0';
}

sub feature_types {
    return [ 'Transcript' ];
}

sub get_header_info {
    my $self = Hpo->new;
    return {
        HPO => "List of HPO terms for the gene, based on  '" . $self->params->[0] . "' ",
    };
}
sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);

    my $file = $self->params->[0];
    die("ERROR: input file not specified\n") unless $file;

    my $hpo_ids_arg = $self->params->[1];
    die("ERROR: input HPO identifier(s) not specified\n") unless $hpo_ids_arg;
    my %hpo_ids = map {$_ => 1} split(';', $hpo_ids_arg);

    open(FH, '<', $file) or die $!;

    my @tokens;
    my $hpo_id;
    my $entrez_gene_id;
    my %entrez_gene_ids;

    <FH>; # skip header
    while (<FH>) {
        chomp; # avoid \n on last field
        @tokens = split(/\t/);
        $hpo_id = $tokens[1];
        if (exists($hpo_ids{$hpo_id})) {
            $entrez_gene_id = $tokens[0];
            push(@{$entrez_gene_ids{$entrez_gene_id}}, $hpo_id);
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

1;
