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

sub variant_feature_types {
  return [ 'VariationFeature', 'StructuralVariationFeature' ];
}

sub feature_types {
  return [ 'Transcript', 'RegulatoryFeature', 'MotifFeature', 'Intergenic'];
}

my $self;

sub get_header_info {
    $self = VKGL->new;

    my $result;
    $result->{VKGL} = "file:" . $self->params->[0] . "'";
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
        parse_file($file);
        # BEGIN - map ensembl back to refseq
        my $mappingFile = $self->params->[2];
        die("ERROR: Gene mapping file not specified\n") unless $mappingFile;
        my %gene_mapping = parseMappingFile($mappingFile);
        $self->{gene_mapping} = \%gene_mapping;
        # END - map ensembl back to refseq
    }
    return $self;
}

sub parseMappingFile {
    my %mapping_data;
    my $file = $_[0];
    open(MAPPING_FH, '<', $file) or die $!;

    my @split;

    while (<MAPPING_FH>) {
        my $line = $_;
        chomp($line);
        @split = split(/\t/, $line);
        if (defined $split[0] and length $split[0] and defined $split[1] and length $split[1]){
            $mapping_data{$split[0]} = $split[1];
        }
    }
    return %mapping_data
}

sub create_key {
    my $chr = $_[0];
    my $pos = $_[1];
    my $ref = $_[2];
    my $alt = $_[3];
    my $gene_id = $_[4];
    return "${chr}_${pos}_${ref}_${alt}_${gene_id}";
}

sub map_class {
    my $src_class = $_[0];
    my $class;
    if ($src_class eq "Benign" || $src_class eq "B") {
        $class = "B";
    }
    elsif ($src_class eq "Likely benign" || $src_class eq "LB") {
        $class = "LB";
    }
    elsif ($src_class eq "VUS" || $src_class eq "VUS") {
        $class = "VUS";
    }
    elsif ($src_class eq "Likely pathogenic" || $src_class eq "LP") {
        $class = "LP";
    }
    elsif ($src_class eq "Pathogenic" || $src_class eq "P") {
        $class = "P";
    }
    return $class;
}

sub uniq {
    my @no_empty = grep {defined} @{$_[0]};
    do { my %seen; grep { !$seen{$_}++ } @no_empty };
}

sub map_consensus {
    my $src_consensus = $_[0];
    my $classes = $_[1];
    my $class_consensus;

    if (length $src_consensus && $src_consensus ne "No consensus" && $src_consensus ne "Opposite classifications") {
        if ($src_consensus eq "VUS") {
            $class_consensus = "VUS";
        }
        elsif ($src_consensus eq "(Likely) benign") {
            # WARNING: Failed to instantiate plugin VKGL: Can't use string ("1") as an ARRAY ref while "strict refs" in use at /groups/umcg-gdio/tmp01/projects/modular_ngs_pipeline/moon/v2.4.4-singularity/run5/vip/plugins/vep/VKGL.pm line 112, <FH> line 2.
            my @classes_unique = uniq($classes);
            $class_consensus = $#classes_unique == 0 ? $classes_unique[0] : "LB";
        }
        elsif ($src_consensus eq "(Likely) pathogenic") {
            my @classes_unique = uniq($classes);
            $class_consensus = $#classes_unique == 0 ? $classes_unique[0] : "LP";
        }
        elsif ($src_consensus eq "Classified by one lab") {
            my @no_empty = grep {defined} @{$classes};
            $class_consensus = $no_empty[0];
        }
    }

    return $class_consensus;
}

sub parse_file_header {
    my @tokens = split /\t/, $_[0];

    my $col_idx;
    for my $i (0 .. $#tokens) {
        if ($tokens[$i] eq "chromosome") {
            $col_idx->{idx_chr} = $i;
        }
        if ($tokens[$i] eq "start") {
            $col_idx->{idx_pos} = $i;
        }
        if ($tokens[$i] eq "ref") {
            $col_idx->{idx_ref} = $i;
        }
        if ($tokens[$i] eq "alt") {
            $col_idx->{idx_alt} = $i;
        }
        if ($tokens[$i] eq "gene_id_entrez_gene") {
            $col_idx->{idx_gene_id} = $i;
        }
        if (!$self->{consensus_only}) {
            if ($tokens[$i] eq "amc") {
                $col_idx->{idx_class_amc} = $i;
            }
            if ($tokens[$i] eq "erasmus") {
                $col_idx->{idx_class_erasmus} = $i;
            }
            if ($tokens[$i] eq "lumc") {
                $col_idx->{idx_class_lumc} = $i;
            }
            if ($tokens[$i] eq "nki") {
                $col_idx->{idx_class_nki} = $i;
            }
            if ($tokens[$i] eq "radboud_mumc") {
                $col_idx->{idx_class_radboud_mumc} = $i;
            }
            if ($tokens[$i] eq "umcg") {
                $col_idx->{idx_class_umcg} = $i;
            }
            if ($tokens[$i] eq "umcu") {
                $col_idx->{idx_class_umcu} = $i;
            }
            if ($tokens[$i] eq "vumc") {
                $col_idx->{idx_class_vumc} = $i;
            }
        }
        if ($tokens[$i] eq "consensus_classification" || $tokens[$i] eq "classification") {
            $col_idx->{idx_class} = $i;
        }
    }
    return $col_idx;
}

sub parse_file {
    my %classes_map;
    open(FH, '<', @_) or die $!;

    chomp(my $header = <FH>);
    $header =~ s/\s*\z//;
    my $col_idx = parse_file_header($header);

    my $i = 0;
    my $idx_class_amc;
    my $idx_class_erasmus;
    my $idx_class_lumc;
    my $idx_class_nki;
    my $idx_class_radboud_mumc;
    my $idx_class_umcg;
    my $idx_class_umcu;
    my $idx_class_vumc;
    if (!$self->{consensus_only}) {
        $idx_class_amc = $i++;
        $idx_class_erasmus = $i++;
        $idx_class_lumc = $i++;
        $idx_class_nki = $i++;
        $idx_class_radboud_mumc = $i++;
        $idx_class_umcg = $i++;
        $idx_class_umcu = $i++;
        $idx_class_vumc = $i++;
    }
    my $idx_class = $i;

    while (my $line = <FH>) {
        $line =~ s/\s*\z//;
        my @tokens = split /\t/, $line;

        my $gene_id = $tokens[$col_idx->{idx_gene_id}];
        if(defined $gene_id) {
            my $chr = $tokens[$col_idx->{idx_chr}];
            my $pos = $tokens[$col_idx->{idx_pos}];
            my $ref = $tokens[$col_idx->{idx_ref}];
            my $alt = $tokens[$col_idx->{idx_alt}];
            my $key = create_key($chr, $pos, $ref, $alt, $gene_id);

            my @classes;

            if (!$self->{consensus_only}) {
                $classes[$idx_class_amc] = map_class($tokens[$col_idx->{idx_class_amc}]);
                $classes[$idx_class_erasmus] = map_class($tokens[$col_idx->{idx_class_erasmus}]);
                $classes[$idx_class_lumc] = map_class($tokens[$col_idx->{idx_class_lumc}]);
                $classes[$idx_class_nki] = map_class($tokens[$col_idx->{idx_class_nki}]);
                $classes[$idx_class_radboud_mumc] = map_class($tokens[$col_idx->{idx_class_radboud_mumc}]);
                $classes[$idx_class_umcg] = map_class($tokens[$col_idx->{idx_class_umcg}]);
                $classes[$idx_class_umcu] = map_class($tokens[$col_idx->{idx_class_umcu}]);
                $classes[$idx_class_vumc] = map_class($tokens[$col_idx->{idx_class_vumc}]);
                $classes[$idx_class] = map_consensus($tokens[$col_idx->{idx_class}], \@classes);
            }
            else {
                $classes[$idx_class] = map_class($tokens[$col_idx->{idx_class}]);
            }
            $classes_map{$key} = \@classes;
        }
    }
    close FH;

    $self->{classes_map} = \%classes_map;
    $self->{idx_class} = $idx_class;
    if (!$self->{consensus_only}) {
        $self->{idx_class_amc} = $idx_class_amc;
        $self->{idx_class_erasmus} = $idx_class_erasmus;
        $self->{idx_class_lumc} = $idx_class_lumc;
        $self->{idx_class_nki} = $idx_class_nki;
        $self->{idx_class_radboud_mumc} = $idx_class_radboud_mumc;
        $self->{idx_class_umcg} = $idx_class_umcg;
        $self->{idx_class_umcu} = $idx_class_umcu;
        $self->{idx_class_vumc} = $idx_class_vumc;
    }
}

sub run {
    my ($self, $base_variation_feature_overlap_allele) = @_;

		# fail fast: sub-class doesn't contain transcript method
    return {} unless ($base_variation_feature_overlap_allele->can('transcript'));
		my $transcript = $base_variation_feature_overlap_allele->transcript;

		# fail fast: gene identifier is not from NCBI's Entrez Gene
    #return {} unless ($transcript->{_gene_symbol_source} eq "EntrezGene");

    my $ensembl_gene_id = $transcript->{_gene_stable_id};
    return {} unless $ensembl_gene_id;

    my $gene_id = $self->{gene_mapping}->{$ensembl_gene_id};
    return {} unless $gene_id;

    my @vcf_line = @{$base_variation_feature_overlap_allele->base_variation_feature->{_line}};
    my $chr = $vcf_line[0];
    my $pos = $vcf_line[1];
    my $ref = $vcf_line[3];
    my $alt = $vcf_line[4]; # assume site is biallelic

    my $result = {};
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

    my $key = create_key($chr, $pos, $ref, $alt, $gene_id);
    my $classes = $self->{classes_map}->{$key};
    if (defined $classes) {
        $result->{VKGL_CL} = $classes->[$self->{idx_class}];
        if (!$self->{consensus_only}) {
            $result->{VKGL_AMC} = $classes->[$self->{idx_class_amc}];
            $result->{VKGL_ERASMUS} = $classes->[$self->{idx_class_erasmus}];
            $result->{VKGL_LUMC} = $classes->[$self->{idx_class_lumc}];
            $result->{VKGL_NKI} = $classes->[$self->{idx_class_nki}];
            $result->{VKGL_RADBOUD_MUMC} = $classes->[$self->{idx_class_radboud_mumc}];
            $result->{VKGL_UMCG} = $classes->[$self->{idx_class_umcg}];
            $result->{VKGL_UMCU} = $classes->[$self->{idx_class_umcu}];
            $result->{VKGL_VUMC} = $classes->[$self->{idx_class_vumc}];
        }
    }

    return $result;
}
1;