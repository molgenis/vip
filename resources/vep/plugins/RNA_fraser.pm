package RNA_fraser;

use strict;
use warnings;

use Bio::EnsEMBL::Variation::Utils::BaseVepPlugin;
use base qw(Bio::EnsEMBL::Variation::Utils::BaseVepPlugin);

=head1 NAME
 RNA
=head1 SYNOPSIS
 mv RNA_fraser.pm ~/.vep/Plugins
 ./vep -i variations.vcf --plugin RNA,/FULL_PATH_TO_INPUT,column1;column2
 Please note that for columns with spaces in the name, those spaces should be replaces with underscores.
 Results in the CSQ will be prefixed to avoid name collisions.
=head1 DESCRIPTION
 
=cut

sub version {
    return '1.0';
}

sub variant_feature_types {
  return [ 'VariationFeature', 'StructuralVariationFeature' ];
}

sub feature_types {
  return [ 'Transcript', 'RegulatoryFeature', 'MotifFeature', 'Intergenic'];
}

my $self;

sub get_header_info {
    $self = RNA_fraser->new;
    my $result;
    my @fields = @{$self->{fields}};
    for (@fields) {
        $result->{$self->{prefix} . $_} = "RNA Fraser '" . $_ . "' output (" . $self->params->[0] . ").";
    }
    return $result;
}

sub new {
    if (!(defined $self)) {
        my $class = shift;
        $self = $class->SUPER::new(@_);
        my $prefix = $self->params->[2];
        $self->{prefix} = $prefix;
        my $file = $self->params->[0];
        $self->{file} = $file;
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
                $header =~ s/"//g;
                $headers[$i] = $header;
            }
            else {
                @split = split(/\t/, $_);
            }
        }

        getFieldIndices($self->params->[1], \@headers);

        if(@split) {
            my $key = $split[$self->{gene_idx}];
            $key =~ s/"//g;
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
        if ($headers[$idx] eq "hgncSymbol") {
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
            $val =~ s/"//g;
        }
        $result->{$self->{prefix} . $key} = $val;
    }
    return $result;
}

sub run {
    my ($self, $transcript_variation_allele) = @_;
    my %indices = %{$self->{indices}};
    my $result = {};
    my $annotations;

    # fail fast: sub-class doesn't contain transcript method
    return {} unless ($transcript_variation_allele->can('transcript'));
    my $transcript = $transcript_variation_allele->transcript;
    return {} unless ($transcript->{_gene_symbol_source} eq "EntrezGene");

    my $symbol = $transcript->{_gene_symbol};
    return {} unless $symbol;

    foreach my $key (keys %indices) {
        $result->{$self->{prefix} . $key} = undef;
    }
    my $line = $self->{line_map}->{$symbol};
    if(defined $line){
        my @line = @{$line};
        $annotations = mapAnnotations(\@line);
        if(defined $annotations){
            $result = $annotations;
        }
    }
    return $result;
}
1;
