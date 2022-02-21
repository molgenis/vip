package Capice;

use strict;
use warnings;

use Bio::EnsEMBL::Variation::Utils::BaseVepPlugin;
use base qw(Bio::EnsEMBL::Variation::Utils::BaseVepPlugin);

=head1 NAME
 Capice
=head1 SYNOPSIS
 mv Capice.pm ~/.vep/Plugins
 ./vep -i variations.vcf --plugin Capice,/FULL_PATH_TO_CAPICE_GZ_file

=head1 DESCRIPTION
 Plugin to annotate if variants with CAPICE scores and suggested classes.
=cut

sub version {
    return '1.0';
}

sub feature_types {
    return [ 'Transcript', 'RegulatoryFeature', 'MotifFeature', 'Intergenic'];
}

sub get_header_info {
    return {
        CAPICE_SC => "CAPICE score",
        CAPICE_CL => "CAPICE classification"
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
    my $gene = $_[4]?$_[4]:"";
    my $source = $_[5]?$_[5]:"";
    my $feature_type = $_[6]?$_[6]:"";
    my $feature = $_[7]?$_[7]:"";
    return "${chr}_${pos}_${ref}_${alt}_${gene}_${source}_${feature_type}_${feature}";
}

sub parse_file_header {
    my @tokens = split /\t/, $_[0];

    my $col_idx;
    for my $i (0 .. $#tokens) {
        if ($tokens[$i] eq "chr") {
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
        if ($tokens[$i] eq "feature_type") {
            $col_idx->{idx_feature_type} = $i;
        }
        if ($tokens[$i] eq "feature") {
            $col_idx->{idx_feature} = $i;
        }
        if ($tokens[$i] eq "gene_id") {
            $col_idx->{idx_gene} = $i;
        }
        if ($tokens[$i] eq "id_source") {
            $col_idx->{idx_source} = $i;
        }
        if ($tokens[$i] eq "score") {
            $col_idx->{idx_score} = "$i";
        }
        if ($tokens[$i] eq "suggested_class") {
            $col_idx->{idx_class} = $i;
        }
    }
    return $col_idx;
}

sub parse_file {
    my %capice_map;
    open(FH, "gunzip -c @_ |") or die $!;

    chomp(my $header = <FH>);
    $header =~ s/\s*\z//;
    my $col_idx = parse_file_header($header);

    while (my $line = <FH>) {
        $line =~ s/\s*\z//;
        my @tokens = split /\t/, $line;

        my $key = create_key($tokens[$col_idx->{idx_chr}], $tokens[$col_idx->{idx_pos}], $tokens[$col_idx->{idx_ref}], $tokens[$col_idx->{idx_alt}], $tokens[$col_idx->{idx_gene}], $tokens[$col_idx->{idx_source}], $tokens[$col_idx->{idx_feature_type}], $tokens[$col_idx->{idx_feature}]);

        my %values;
        $values{s} = $tokens[$col_idx->{idx_score}];
        $values{c} = $tokens[$col_idx->{idx_class}];
        $capice_map{$key} = \%values;
    }
    close FH;

    $self->{capice_map} = \%capice_map;
}

sub run {
    my ($self, $tva) = @_;

    my $bvf = $tva->base_variation_feature;
    my @vcf_line = @{$bvf->{_line}};
    my $chr = $vcf_line[0];
    my $pos = $vcf_line[1];
    my $ref = $vcf_line[3];
    my $alt = $vcf_line[4];

    my $source = "";
    my $gene = "";
    my $transcript_id = "";

    if ($tva->can("transcript")) {
        $source = $tva->transcript->{_gene_symbol_source};
        return {} unless ($source eq "EntrezGene");

        $gene = $tva->transcript->{_gene_stable_id};
    }

    if($tva->feature) {
        $transcript_id = $tva->feature->stable_id;
    }

    my $key = create_key($chr,$pos,$ref,$alt,$gene,$source,$transcript_id);

    my $result = ();
    $result->{CAPICE_SC} = undef;
    $result->{CAPICE_CL} = undef;
    my $value = $self->{capice_map}{$key};
    if($value) {
        my %value_map = %{$value};
        $result->{CAPICE_SC} = $value_map{s};
        $result->{CAPICE_CL} = $value_map{c};
    }
    return $result;
}
1;