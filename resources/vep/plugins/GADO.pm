package GADO;

use strict;
use warnings;

use Bio::EnsEMBL::Variation::Utils::BaseVepPlugin;
use base qw(Bio::EnsEMBL::Variation::Utils::BaseVepPlugin);

=head1 NAME
 GADO
=head1 SYNOPSIS
 
=head1 DESCRIPTION
 Plugin to annotate consequences with GADO scores modes based on their gene.
=cut

sub version {
    return '0.1';
}

sub feature_types {
    return ['Transcript'];
}

sub variant_feature_types {
    return ['VariationFeature'];
}

my $self;

sub get_header_info {
    $self = GADO->new;
    my $result;
    $result->{Zscore} = "The combined prioritization Z-score over the supplied HPO terms for this case. This score is used for the ranking";
    return $result;
}

sub new {
    if (!(defined $self)) {
        my $class = shift;
        $self = $class->SUPER::new(@_);
        my $file = $self->params->[0];

        my %gene_data;

        die("ERROR: input file not specified\n") unless $file;
        open(FH, '<', $file) or die $!;

        my @split;

        while (<FH>) {
            my $line = $_;
            chomp($line);
            @split = split(/\t/, $line);
            $gene_data{$split[1]} = {Zscore => $split[3]};
        }

        $self->{gene_data} = \%gene_data;
    }
    return $self;
}

sub run {
    my ($self, $transcript_variation_allele) = @_;
    my %gene_data = %{$self->{gene_data}};
    my $pheno_data = $self->{pheno_data};

    my $transcript = $transcript_variation_allele->transcript;
    #return {} unless ($transcript->{_gene_symbol_source} eq "EntrezGene");

    #my $entrez_gene_id = $transcript->{_gene_stable_id};
    #return {} unless $entrez_gene_id;
    my $result;
    my $symbol = $transcript->{_gene_symbol};
    my $gene_value = $gene_data{$symbol};
    return {} unless $gene_value;

    my %gene_hash = %{$gene_value};
    $result->{Zscore} = $gene_hash{Zscore};
    return $result;
}
1;