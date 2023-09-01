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

        die("ERROR: input file not specified\n") unless $file;
        readFile($file);
    }
    return $self;
}

sub readFile {
    my @headers;
    my %line_map;

    open(FH, '<', @_) or die $!;
    while (<FH>) {
        chomp;
        my @split;
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

        getFieldIndices($self->params->[1], \@headers);

        if(@split) {
            my $key = create_key($split[$self->{chrom_idx}],$split[$self->{pos_idx}],$split[$self->{ref_idx}],$split[$self->{alt_idx}]);
            $line_map{$key} = \@split;
        }
    }
    $self->{headers} = \@headers;
    $self->{line_map} = \%line_map;
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
    my %indices = %{$self->{indices}};

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
    return $result;
}

sub create_key {
    my $chr = $_[0];
    my $pos = $_[1];
    my $ref = $_[2];
    my $alt = $_[3];
    return "${chr}_${pos}_${ref}_${alt}";
}

sub run {
    my ($self, $bvfoa) = @_;
    my %indices = %{$self->{indices}};
    my $result = {};
    my $annotations;

    my $svf = $bvfoa->base_variation_feature;
    my @vcf_line = @{$svf->{_line}};
    my $symbol = "";

    if ($bvfoa->can("transcript")) {
        $symbol = $bvfoa->transcript->{_gene_symbol} || $bvfoa->transcript->{_gene_hgnc};
    }

    foreach my $key (keys %indices) {
        $result->{$self->{prefix} . $key} = undef;
    }
    my $vcf_key = create_key($vcf_line[0], $vcf_line[1], $vcf_line[3],$vcf_line[4]);
    my $line = $self->{line_map}->{$vcf_key};
    if(defined $line){
        my @line = @{$line};
        my @genes = split(";", $line[$self->{gene_idx}]);
        if ($symbol eq "") {
            $annotations = mapAnnotations(\@line, \@vcf_line);
            if(defined $annotations){
                $result = $annotations;
            }
        }
        else {
            for my $gene (@genes) {
                if ($gene eq $symbol) {
                    $annotations = mapAnnotations(\@line, \@vcf_line);
                    if(defined $annotations){
                        $result = $annotations;
                    }
                }
            }
        }
    }
    return $result;
}
1;
