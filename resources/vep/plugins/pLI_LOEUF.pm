=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
Copyright [2016-2025] EMBL-European Bioinformatics Institute

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

=head1 CONTACT

  Ensembl <https://www.ensembl.org/info/about/contact/index.html>

=cut

=head1 NAME

pLI_LOEUF - Add pLI and LOEUF scores to the output

=head1 SYNOPSIS

  mv pLI.pm ~/.vep/Plugins
  mv pLI_values.txt ~/.vep/Plugins
  ./vep -i variants.vcf --plugin pLI_LOEUF

=head1 DESCRIPTION


  An Ensembl VEP plugin that adds both the probability of a gene being loss-of-function intolerant (pLI) and the LOEUF score to the output
  
  Lek et al. (2016) estimated pLI using the expectation-maximization 
  (EM) algorithm and data from 60,706 individuals from 
  ExAC (http://exac.broadinstitute.org). The closer pLI is to 1, 
  the more likely the gene is loss-of-function (LoF) intolerant.
  Loss-of-function Observed/Expected Upper Bound Fraction (LOEUF) scores are interpreted the other way around,
  scores indicate a higher constraint. 

  
  Note: the pLI and LOEUF scores were calculated using a (MANE) representative transcript and
  is reported by gene in the plugin.

  gnomAD v4 release was used for the of pLI and LOEUF scores. The file can be downloaded from -
    https://gnomad.broadinstitute.org/downloads#v4-constraint (Constraint metrics TSV)
  To use the data you can follow the same procedure as above but needs to change the column number to accordingly.

=cut

package pLI_LOEUF;

use strict;
use warnings;

use DBI;
use base qw(Bio::EnsEMBL::Variation::Utils::BaseVepPlugin);
use List::MoreUtils qw/zip/;


my %include_columns = (
  "transcript" => {
    "pLI"   => "pLI_transcript_value",
    "LOEUF" => "LOEUF_transcript_value"
  },
  "gene" => {
    "pLI"   => "pLI_gene_value",
    "LOEUF" => "LOEUF_gene_value"
  }
);


sub new {
  my $class = shift;
  my $self = $class->SUPER::new(@_);

  my $file = $self->params->[0];
  my $mode = defined($self->params->[1]) ? $self->params->[1] : 'gene';

  if (!$file) {
    my $plugin_dir = $INC{'pLI_LOEUF.pm'};
    $plugin_dir =~ s/pLI_LOEUF\.pm//i;
    $file = $plugin_dir.'/pLI_LOEUF_values.txt';
  }

  die("ERROR: pLI values file $file not found\n") unless -e $file;

  # Read header line
  open my $in, "<", $file or die "ERROR: Could not open $file: $!";
  while (<$in>) {
    next unless /gene|transcript/;
    chomp;
    $self->{headers} = [split];
    last;
  }
  close $in;

  die "ERROR: Could not read headers from $file\n" unless defined($self->{headers});
  die "Error: File does not have a $mode column\n" unless grep { $_ eq $mode } @{$self->{headers}};

  $self->{header}{$include_columns{$mode}{"name"}} = "pLI and LOEUF values by $mode";

  # Parse scores in one pass
  my %scores;
  open my $fh, "<", $file or die "ERROR: Could not open $file: $!";
  while (<$fh>) {
    chomp;
    my ($id, $score_pli, $score_loeuf) = split;
    next if $id eq $mode;  # skip header
    $scores{lc($id)} = {
      pLI   => sprintf("%.2f", $score_pli),
      LOEUF => sprintf("%.2f", $score_loeuf),
    };
  }
  close $fh;

  die("ERROR: No scores read from $file\n") unless keys %scores;

  $self->{scores} = \%scores;
  return $self;
}


sub feature_types {
  return ['Transcript'];
}

sub get_header_info {
  my $self = shift;
  return {
    $include_columns{"gene"}{"pLI"}   => "pLI score by gene",
    $include_columns{"gene"}{"LOEUF"} => "LOEUF score by gene",
    $include_columns{"transcript"}{"pLI"}   => "pLI score by transcript",
    $include_columns{"transcript"}{"LOEUF"} => "LOEUF score by transcript"
  };
}


sub run {
  my $self = shift;
  my $tva = shift;

  my $transcript = $tva->transcript;
  return {} unless $transcript;

  if (!defined($self->params->[1]) || $self->params->[1] eq "gene") {
    my $symbol = $tva->transcript->{_gene_symbol} || $tva->transcript->{_gene_hgnc};
    return {} unless $symbol;
    my $score_data = $self->{scores}->{lc($symbol)};
    return $score_data ? {
      $include_columns{"gene"}{"pLI"}   => $score_data->{pLI},
      $include_columns{"gene"}{"LOEUF"} => $score_data->{LOEUF}
    } : {};

  }

  if ($self->params->[1] eq "transcript") {
    my $transcript_id = $transcript->stable_id;
    return {} unless $transcript_id;
    my $score_data = $self->{scores}->{lc($transcript_id)};
    return $score_data ? {
      $include_columns{"transcript"}{"pLI"}   => $score_data->{pLI},
      $include_columns{"transcript"}{"LOEUF"} => $score_data->{LOEUF}
    } : {};
  }

  return {};
}

1;

