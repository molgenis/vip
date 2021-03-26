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
    if (!$self->{consensus_only}) {
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
        }
        else {
            $self->{consensus_only} = 0;
        }
        die("ERROR: input file not specified\n") unless $file;
        readFile($file);
        getFieldIndices($self->{headers});
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
        my @list = split(/\t/); ## Collect the elements of this line
        for (my $i = 0; $i <= $#list; $i++) {
            ## If this is the 1st line, collect the names
            if ($. == 1) {
                my $header = $list[$i];
                $header =~ tr/ /_/;
                $headers[$i] = $header;
            }
            else {
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

sub mapClassification {
    my $input = $_[0];
    my $output;
    if ($input eq "Benign") {
        $output = "B";
    }
    elsif ($input eq "Likely benign") {
        $output = "LB";
    }
    elsif ($input eq "VUS") {
        $output = "VUS";
    }
    elsif ($input eq "Likely pathogenic") {
        $output = "LP";
    }
    elsif ($input eq "Pathogenic") {
        $output = "P";
    }
    return $output;
}

sub mapConsensusClassification {
    my @line = @{$_[0]};
    my $consensus = $line[$self->{VKGL_CL_idx}];
    my %classifications;
    my $output = "";

    if (length $consensus) {
        if(length($self->{VKGL_AMC_idx})) {
            my @a = ($self->{VKGL_AMC_idx}, $self->{VKGL_ERASMUS_idx}, $self->{VKGL_LUMC_idx}, $self->{VKGL_NKI_idx}, $self->{VKGL_RADBOUD_MUMC_idx}, $self->{VKGL_UMCG_idx}, $self->{VKGL_UMCU_idx}, $self->{VKGL_VUMC_idx});
            for (@a) {
                if (length($line[$_])) {
                    $classifications{$line[$_]} = 1;
                }
            }
            if ($consensus ne "No consensus" && $consensus ne "Opposite classifications") {
                if ($consensus eq "VUS") {
                    $output = "VUS";
                }
                elsif ($consensus eq "(Likely) pathogenic") {
                    if (exists($classifications{"Likely pathogenic"})) {
                        $output = "LP";
                    }
                    else {
                        $output = "P";
                    }
                }
                elsif ($consensus eq "(Likely) benign") {
                    if (exists($classifications{"Likely benign"})) {
                        $output = "LB";
                    }
                    else {
                        $output = "B";
                    }
                }
                elsif ($consensus eq "Classified by one lab") {
                    $output = mapClassification((keys %classifications)[0]);
                }
            }
        }
        elsif ($consensus eq "LB" || $consensus eq "LP" || $consensus eq "VUS") {
            $output = $consensus;
        }
    }
    return $output;
}

sub getFieldIndices {
    my @headers = @{$_[0]};
    for my $idx (0 .. $#headers) {
        if ($headers[$idx] eq "chromosome") {
            $self->{chrom_idx} = $idx;
        }
        if ($headers[$idx] eq "start") {
            $self->{pos_idx} = $idx;
        }
        if ($headers[$idx] eq "ref") {
            $self->{ref_idx} = $idx;
        }
        if ($headers[$idx] eq "alt") {
            $self->{alt_idx} = $idx;
        }
        if ($headers[$idx] eq "gene") {
            $self->{gene_idx} = $idx;
        }
        if ($headers[$idx] eq "amc") {
            $self->{VKGL_AMC_idx} = $idx;
        }
        if ($headers[$idx] eq "erasmus") {
            $self->{VKGL_ERASMUS_idx} = $idx;
        }
        if ($headers[$idx] eq "lumc") {
            $self->{VKGL_LUMC_idx} = $idx;
        }
        if ($headers[$idx] eq "nki") {
            $self->{VKGL_NKI_idx} = $idx;
        }
        if ($headers[$idx] eq "radboud_mumc") {
            $self->{VKGL_RADBOUD_MUMC_idx} = $idx;
        }
        if ($headers[$idx] eq "umcg") {
            $self->{VKGL_UMCG_idx} = $idx;
        }
        if ($headers[$idx] eq "umcu") {
            $self->{VKGL_UMCU_idx} = $idx;
        }
        if ($headers[$idx] eq "vumc") {
            $self->{VKGL_VUMC_idx} = $idx;
        }
        if ($headers[$idx] eq "consensus_classification" || $headers[$idx] eq "classification") {
            $self->{VKGL_CL_idx} = $idx;
        }
    }
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
    if (!$self->{consensus_only}) {
        $result->{VKGL_AMC} = undef;
        $result->{VKGL_ERASMUS} = undef;
        $result->{VKGL_LUMC} = undef;
        $result->{VKGL_NKI} = undef;
        $result->{VKGL_RADBOUD_MUMC} = undef;
        $result->{VKGL_UMCG} = undef;
        $result->{VKGL_UMCU} = undef;
        $result->{VKGL_VUMC} = undef;
    }
    $result->{VKGL_CL} = undef;

    for my $line (@lines) {
        my @line = @{$line};
        if ($line[$self->{gene_idx}] eq $symbol) {
            if ($line[$self->{chrom_idx}] eq $chrom
                && $line[$self->{pos_idx}] == $pos
                && $line[$self->{ref_idx}] eq $ref
                && $line[$self->{alt_idx}] eq $alt) {
                if (!$self->{consensus_only}) {
                    $result->{VKGL_AMC} = mapClassification($line[$self->{VKGL_AMC_idx}]);
                    $result->{VKGL_ERASMUS} = mapClassification($line[$self->{VKGL_ERASMUS_idx}]);
                    $result->{VKGL_LUMC} = mapClassification($line[$self->{VKGL_LUMC_idx}]);
                    $result->{VKGL_NKI} = mapClassification($line[$self->{VKGL_NKI_idx}]);
                    $result->{VKGL_RADBOUD_MUMC} = mapClassification($line[$self->{VKGL_RADBOUD_MUMC_idx}]);
                    $result->{VKGL_UMCG} = mapClassification($line[$self->{VKGL_UMCG_idx}]);
                    $result->{VKGL_UMCU} = mapClassification($line[$self->{VKGL_UMCU_idx}]);
                    $result->{VKGL_VUMC} = mapClassification($line[$self->{VKGL_VUMC_idx}]);
                }
                $result->{VKGL_CL} = mapConsensusClassification(\@line);
            }
        }
    }
    return $result;
}


1;