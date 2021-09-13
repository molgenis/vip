package Artefact;

use strict;
use warnings;

use Bio::EnsEMBL::Variation::Utils::BaseVepPlugin;
use base qw(Bio::EnsEMBL::Variation::Utils::BaseVepPlugin);

=head1 NAME
 Artefact
=head1 SYNOPSIS
 mv Artefact.pm ~/.vep/Plugins
 ./vep -i variations.vcf --plugin Artefact,/FULL_PATH_TO_Artefacts_file

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
        parse_file($file);
    }
    return $self;
}

sub create_key {
    my $chr = $_[0];
    my $pos = $_[1];
    my $ref = $_[2];
    my $alt = $_[3];
    return "${chr}_${pos}_${ref}_${alt}";
}

sub parse_file_header {
    my @tokens = split /\t/, $_[0];

    my $col_idx;
    for my $i (0 .. $#tokens) {
        if ($tokens[$i] eq "chrom") {
            $col_idx->{idx_chr} = $i;
        }
        if ($tokens[$i] eq "pos") {
            $col_idx->{idx_pos} = $i;
        }
        if ($tokens[$i] eq "ref") {
            $col_idx->{idx_ref} = $i;
        }
        if ($tokens[$i] eq "alt") {
            $col_idx->{idx_alt} = $i;
        }
    }
    return $col_idx;
}

sub parse_file {
    my %artefact_map;
    open(FH, '<', @_) or die $!;

    chomp(my $header = <FH>);
    $header =~ s/\s*\z//;
    my $col_idx = parse_file_header($header);

    while (my $line = <FH>) {
        $line =~ s/\s*\z//;
        my @tokens = split /\t/, $line;

        my $key = create_key($tokens[$col_idx->{idx_chr}], $tokens[$col_idx->{idx_pos}], $tokens[$col_idx->{idx_ref}], $tokens[$col_idx->{idx_alt}]);
        $artefact_map{$key} = 1;
    }
    close FH;

    $self->{artefact_map} = \%artefact_map;
}

sub run {
    my ($self, $tva) = @_;

    my $vf = $tva->base_variation_feature;
    my @vcf_line = @{$vf->{_line}};
    my $chr = $vcf_line[0];
    my $pos = $vcf_line[1];
    my $ref = $vcf_line[3];
    my $alt = $vcf_line[4];
    my $key = create_key($chr, $pos, $ref, $alt);

    my $result->{ARTEFACT} = $self->{artefact_map}->{$key};
    return $result;
}

1;