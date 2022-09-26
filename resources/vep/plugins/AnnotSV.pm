package AnnotSV;

use strict;
use warnings;

use Bio::EnsEMBL::Variation::Utils::BaseVepPlugin;
use base qw(Bio::EnsEMBL::Variation::Utils::BaseVepPlugin);

=head1 NAME
 AnnotSV
=head1 SYNOPSIS
 mv AnnotSV.pm ~/.vep/Plugins
 ./vep -i variations.vcf --plugin AnnotSV,/FULL_PATH_TO_ANNOTSV_OUTPUT,column1;column2
 Please note that for columns with spaces in the name, those spaces should be replaces with underscores.
 Results in the CSQ will be prefixed with ASV_ to avoid name collisions.
=head1 DESCRIPTION
 Plugin to annotate consequences of structural variants with specified columns from the AnnotSV output.
=cut

sub version {
    return '1.0';
}

sub variant_feature_types {
    return [ 'BaseVariationFeature' ];
}

sub feature_types {
    return [ 'Transcript', 'RegulatoryFeature', 'MotifFeature', 'Intergenic'];
}

my $self;

sub get_header_info {
    $self = AnnotSV->new;
    my $result;
    my @fields = @{$self->{fields}};
    for (@fields) {
        $result->{$self->{prefix} . $_} = "AnnotSv '" . $_ . "' output.";
    }
    return $result;
}

sub new {
    if (!(defined $self)) {
        my $class = shift;
        $self = $class->SUPER::new(@_);
        $self->{prefix} = "ASV_";
        my $file = $self->params->[0];
        my $fields_arg = $self->params->[1];

        die("ERROR: input file not specified\n") unless $file;
        readFile($file);
        getFieldIndices($fields_arg, $self->{headers});
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
        if(@split) {
            push @lines, [ @split ];
        }
    }
    $self->{headers} = \@headers;
    $self->{lines} = \@lines;
}

sub getFieldIndices{
    my $fields_arg = $_[0];
    my @headers = @{$_[1]};

    my @fields = split(";", $fields_arg);
    for (@fields) {
        my %params = map {$_ => 1} @headers;
        if (!exists($params{$_})) {
            die "ERROR: requested field '$_' is not available in input file. (note: spaces should be replaced with underscores.)";
        }
    }
    my %indices;
    for my $idx (0 .. $#headers) {
        if ($headers[$idx] eq "SV_chrom") {
            $self->{chrom_idx} = $idx;
        }
        if ($headers[$idx] eq "SV_start") {
            $self->{pos_idx} = $idx;
        }
        if ($headers[$idx] eq "REF") {
            $self->{ref_idx} = $idx;
        }
        if ($headers[$idx] eq "ALT") {
            $self->{alt_idx} = $idx;
        }
        if ($headers[$idx] eq "Gene_name") {
            $self->{gene_idx} = $idx;
        }
        for my $field (@fields) {
            if ($field eq $headers[$idx]) {
                $indices{$field} = $idx;
            }
        }
    }
    $self->{indices} = \%indices;
    $self->{fields} = \@fields;
}

sub mapAnnotations{
    my $result;
    my @line = @{$_[0]};
    my @vcf_line = @{$_[1]};
    my %indices = %{$_[2]};

    my $chrom = $vcf_line[0];
    my $pos = $vcf_line[1];
    my $ref = $vcf_line[3];
    my $alt = $vcf_line[4];

    if ($line[$self->{chrom_idx}] eq $chrom
        && $line[$self->{pos_idx}] == $pos
        && $line[$self->{ref_idx}] eq $ref
        && $line[$self->{alt_idx}] eq $alt) {
        foreach my $key (keys %indices) {
            my $val = $line[$indices{$key}];
            if (length $val) {
                # escape characters with special meaning using VCFv4.3 percent encoding
                $val =~ s/%/%25/g; # must be first
                $val =~ s/:/%3A/g;
                $val =~ s/;/%3B/g;
                $val =~ s/=/%3D/g;
                $val =~ s/,/%2C/g;
                $val =~ s/\r/%0D/g;
                $val =~ s/\n/%0A/g;
                $val =~ s/\t/%09/g;
            }
            $result->{$self->{prefix} . $key} = $val;
        }
    }
    return $result;
}

sub run {
    my ($self, $bvfoa) = @_;
    my $result = ();
    my $annotations;

    my $svf = $bvfoa->base_variation_feature;
    my @vcf_line = @{$svf->{_line}};
    my $symbol = "";

    if ($bvfoa->can("transcript")) {
        $symbol = $bvfoa->transcript->{_gene_symbol} || $bvfoa->transcript->{_gene_hgnc};
    }

    my @lines = @{$self->{lines}};
    my %indices = %{$self->{indices}};

    foreach my $key (keys %indices) {
        $result->{$self->{prefix} . $key} = undef;
    }
    for my $line (@lines) {
        my @line = @{$line};
        my @genes = split(";", $line[$self->{gene_idx}]);
        if ($symbol eq "") {
            $annotations = mapAnnotations(\@line, \@vcf_line, \%indices);
            if($annotations){
                $result = $annotations;
            }
        }
        else {
            for my $gene (@genes) {
                if ($gene eq $symbol) {
                    $annotations = mapAnnotations(\@line, \@vcf_line, \%indices);
                    if($annotations){
                        $result = $annotations;
                    }
                }
            }
        }
    }
    return $result;
}
1;
