package BRAIN_MAGNET;

use strict;
use warnings;

use Bio::EnsEMBL::Variation::Utils::BaseVepTabixPlugin;
use base qw(Bio::EnsEMBL::Variation::Utils::BaseVepTabixPlugin);

=head1 NAME
 BRAIN_MAGNET
=head1 SYNOPSIS
 mv BRAIN_MAGNET.pm ~/.vep/Plugins
 ./vep -i variations.vcf --plugin BRAIN_MAGNET,/FULL_PATH_TO_BRAIN_MAGNET_FILE
=head1 DESCRIPTION
 Plugin to annotate BRAIN_MAGNET Category,cb score,percentile_all score,percentile_each score values, see https://github.com/ruizhideng/BRAIN-MAGNET.
=cut

my $self;

sub new {
  if (!(defined $self)) {
    my $class = shift;
    $self = $class->SUPER::new(@_);

    $self->expand_left(0);
    $self->expand_right(0);

    my $ann_file = $self->params->[0];
    die("ERROR: input file not specified\n") unless $ann_file;

    $self->add_file($ann_file);
  }
  return $self;
}

sub variant_feature_types {
  return [ 'VariationFeature', 'StructuralVariationFeature' ];
}

sub feature_types {
  return [ 'Transcript', 'RegulatoryFeature', 'MotifFeature', 'Intergenic'];
}

sub get_header_info {
  return {
    BRAIN_MAGNET_CATEGORY => "TODO",
    BRAIN_MAGNET_GENE => "TODO",
    BRAIN_MAGNET_CB_SCORE => "TODO",
    BRAIN_MAGNET_PERC_ALL => "TODO",
    BRAIN_MAGNET_PERC_EACH => "TODO"
  };
}

sub run {
  my ($self, $base_variation_feature_overlap_allele) = @_;

  my @line = @{$base_variation_feature_overlap_allele->base_variation_feature->{_line}};
  my $chr = $line[0];
  my $pos = $line[1];

  my @data = @{ $self->get_data($chr, $pos, $pos) };
  return {} unless @data;

  my %by_ncre;

  foreach my $row (@data) {
    my $ncre = $row->{ncre};

    if (!exists $by_ncre{$ncre}) {
      # store single-value fields once per ncre
      $by_ncre{$ncre} = {
        cat       => $row->{cat},
        cb_score  => $row->{cb_score},
        perc_all  => $row->{perc_all},
        perc_each => $row->{perc_each},
        genes     => {},
      };
    }

    $by_ncre{$ncre}->{genes}->{ $row->{gene} } = 1
      if defined $row->{gene} && $row->{gene} ne '';
  }

  # Now build final VEP output
  my (@cats, @genes, @scores, @perc_all, @perc_each);

  foreach my $ncre (sort keys %by_ncre) {
    my $entry = $by_ncre{$ncre};

    push @cats, $entry->{cat};
    push @genes, join("&", sort keys %{ $entry->{genes} });
    push @scores, $entry->{cb_score};
    push @perc_all, $entry->{perc_all};
    push @perc_each, $entry->{perc_each};
  }

  return {
    BRAIN_MAGNET_CATEGORY   => join("^", @cats),
    BRAIN_MAGNET_GENE       => join("^", @genes),
    BRAIN_MAGNET_CB_SCORE   => join("^", @scores),
    BRAIN_MAGNET_PERC_ALL   => join("^", @perc_all),
    BRAIN_MAGNET_PERC_EACH  => join("^", @perc_each),
  };
}

sub parse_data {
  my ($self, $line) = @_;
  my ($chr, $pos, $ncre, $cat, $gene, $cb_score, $perc_all, $perc_each) = split /\t/, $line;

  return {
    chr => $chr,
    pos => $pos,
    ncre => $ncre,
    cat => $cat,
    gene => $gene,
    cb_score => $cb_score,
    perc_all => $perc_all,
    perc_each => $perc_each,
  };
}

1;