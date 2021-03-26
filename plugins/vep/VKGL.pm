package VKGL;

use strict;
use warnings;

use Bio::EnsEMBL::Variation::Utils::BaseVepPlugin;
use base qw(Bio::EnsEMBL::Variation::Utils::BaseVepPlugin);

=head1 NAME
 VKGL
=head1 SYNOPSIS
 mv VKGL.pm ~/.vep/Plugins
 ./vep -i variations.vcf --plugin VKGL,/FULL_PATH_TO_VKGL_file
 ./vep -i variations.vcf --plugin VKGL,/FULL_PATH_TO_VKGL_file,consensus_only(1 or 0)

=head1 DESCRIPTION
 Plugin to annotate classifications of variants as provided by the VKGL project.
=cut

sub version {
    return '1.0';
}

sub feature_types {
    return [ 'Transcript' ];
}

sub get_header_info {
    my $self = VKGL->new;

    my $result;

    $result->{VKGL_CL} = "VKGL consensus variant classification.";
    if(!$self->{consensus_only}) {
        $result->{VKGL_AMC} = "VKGL AMC variant classification.";
        $result->{VKGL_ERASMUS} = "VKGL ERASMUS variant classification.";
        $result->{VKGL_LUMC} = "VKGL LUMC variant classification.";
        $result->{VKGL_NKI} = "VKGL NKI variant classification.";
        $result->{VKGL_UMCG} = "VKGL UMCG variant classification.";
        $result->{VKGL_UMCU} = "VKGL UMCU variant classification.";
        $result->{VKGL_RADBOUD_MUMC} = "VKGL RADBOUD/MUMC variant classification.";
        $result->{VKGL_VUMC} = "VKGL VUMC variant classification.";
    }
    return $result;
}

my $self;

sub new {
    if (!(defined $self)) {
        my $class = shift;
        $self = $class->SUPER::new(@_);
        my $file = $self->params->[0];
        if (length($self->params->[1])) {
            $self->{consensus_only} = ($self->params->[1] == 1);
        }else{
            $self->{consensus_only} = 0;
        }
        die("ERROR: input file not specified\n") unless $file;
        readFile($file);
    }
    return $self;
}

sub readFile {
    my @headers;
    my @lines;
    my @split;

    open(FH, '<', @_) or die $!;
    while (<FH>) {
        chomp;
        my @list = split(/\t/);
        for (my $i = 0; $i <= $#list; $i++) {
            ## skip header
            if ($. != 1) {
                @split = split(/\t/, $_);
            }
        }
        if (@split) {
            push @lines, [ @split ];
        }
    }
    $self->{headers} = \@headers;
    $self->{lines} = \@lines;
}

sub run {
    my ($self, $tva) = @_;

    my $transcript = $tva->transcript;
    return {} unless ($transcript->{_gene_symbol_source} eq "EntrezGene");

    my $vf = $tva->base_variation_feature;
    my @vcf_line = @{$vf->{_line}};
    my $chrom = $vcf_line[0];
    my $pos = $vcf_line[1];
    my $ref = $vcf_line[3];
    my $alt = $vcf_line[4];
    my $symbol = $transcript->{_gene_symbol} || $transcript->{_gene_hgnc};

    my @lines = @{$self->{lines}};

    my $result = ();
    $result->{VKGL_AMC} = undef;
    $result->{VKGL_ERASMUS} = undef;
    $result->{VKGL_LUMC} = undef;
    $result->{VKGL_NKI} = undef;
    $result->{VKGL_RADBOUD_MUMC} = undef;
    $result->{VKGL_UMCG} = undef;
    $result->{VKGL_UMCU} = undef;
    $result->{VKGL_VUMC} = undef;
    $result->{VKGL_CL} = undef;

    for my $line (@lines) {
        my @line = @{$line};
        if ($line[6] eq $symbol) {
            if ($line[1] eq $chrom
                && $line[2] == $pos
                && $line[4] eq $ref
                && $line[5] eq $alt) {
                if(!$self->{consensus_only}) {
                    $result->{VKGL_AMC} = mapClassification($line[19]);
                    $result->{VKGL_ERASMUS} = mapClassification($line[20]);
                    $result->{VKGL_LUMC} = mapClassification($line[21]);
                    $result->{VKGL_NKI} = mapClassification($line[22]);
                    $result->{VKGL_RADBOUD_MUMC} = mapClassification($line[23]);
                    $result->{VKGL_UMCG} = mapClassification($line[24]);
                    $result->{VKGL_UMCU} = mapClassification($line[25]);
                    $result->{VKGL_VUMC} = mapClassification($line[26]);
                }
                $result->{VKGL_CL} = mapConsensusClassification(\@line);
            }
        }
    }
    return $result;
}

sub mapClassification {
    my $input = $_[0];
    my $output;
    if ($input eq "Benign") {
        $output = "B";
    }
    elsif($input eq "Likely benign") {
        $output = "LB";
    }
    elsif($input eq "VUS") {
        $output = "VUS";
    }
    elsif($input eq "Likely pathogenic") {
        $output = "LP";
    }
    elsif($input eq "Pathogenic") {
        $output = "P";
    }
    return $output;
}

sub mapConsensusClassification {
    my @line = @{$_[0]};
    my $consensus = $line[27];
    my %classifications;
    my $output = "";

    if(length $consensus) {
        my @a = (19 .. 26);
        for (@a) {
            if (length($line[$_])) {
                $classifications{$line[$_]} = 1;
            }
        }
        if($consensus ne "No consensus" && $consensus ne "Opposite classifications"){
            if($consensus eq "VUS"){
                $output = "VUS";
            }
            elsif($consensus eq "(Likely) pathogenic"){
                if(exists($classifications{"Likely pathogenic"})){
                    $output = "LP";
                }
                else{
                    $output = "P";
                }
            }
            elsif($consensus eq "(Likely) benign"){
                if(exists($classifications{"Likely benign"})){
                    $output = "LB";
                }
                else{
                    $output = "B";
                }
            }
            elsif($consensus eq "Classified by one lab"){
                $output = mapClassification((keys %classifications)[0]);
            }
        }
    }
    return $output;
}

1;