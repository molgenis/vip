package Artefacts;

use strict;
use warnings;

use Bio::EnsEMBL::Variation::Utils::BaseVepPlugin;
use base qw(Bio::EnsEMBL::Variation::Utils::BaseVepPlugin);

=head1 NAME
 Artefacts
=head1 SYNOPSIS
 mv Artefacts.pm ~/.vep/Plugins
 ./vep -i variations.vcf --plugin Artefacts,/FULL_PATH_TO_Artefacts_file

=head1 DESCRIPTION
 Plugin to annotate if variants are considered artefacts.
=cut

sub version {
    return '1.0';
}

sub feature_types {
    return [ 'Transcript' ];
}

sub get_header_info {
    return {
        ARTEFACT => "Flags all transcripts of an artefact as such"
    };
}

my $self;

sub new {
    if (!(defined $self)) {
        my $class = shift;
        $self = $class->SUPER::new(@_);
        my $file = $self->params->[0];
        die("ERROR: input file not specified\n") unless $file;
        readFile($file);
    }
    return $self;
}

sub readFile {
    my @lines;
    my @split;

    open(FH, '<', @_) or die $!;
    while (<FH>) {
        chomp;
        my @list = split(/\t/); ## Collect the elements of this line
        for (my $i = 0; $i <= $#list; $i++) {
            ## Ignore the 1st line (header)
            if ($. != 1) {
                @split = split(/\t/, $_);
            }
        }
        if (@split) {
            push @lines, [ @split ];
        }
    }
    $self->{lines} = \@lines;
}

sub run {
    my ($self, $tva) = @_;

    my $vf = $tva->base_variation_feature;
    my @vcf_line = @{$vf->{_line}};
    my @lines = @{$self->{lines}};

    my $result->{ARTEFACT} = undef;
    for my $line (@lines) {
        my @line = @{$line};
        if ($line[1] eq $vcf_line[0]
            && $line[2] == $vcf_line[1]
            && $line[4] eq $vcf_line[3]
            && $line[5] eq $vcf_line[4]) {
            $result->{ARTEFACT} = 1;
        }
    }
    return $result;
}

1;