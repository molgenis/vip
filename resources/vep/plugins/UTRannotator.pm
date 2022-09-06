=head1 LICENSE
Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
Copyright [2016-2018] EMBL-European Bioinformatics Institute
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
 Ensembl <http://www.ensembl.org/info/about/contact/index.html>

=cut

=head1 NAME
 UTRannotator
=head1 SYNOPSIS
 mv UTRannotator/* $HOME/.vep/Plugins
 vep -i variations.vcf --tab --plugin UTRannotator,/path/to/uORF_starts_ends_GRCh37_PUBLIC.txt
=head1 DESCRIPTION
 A VEP plugin that annotates the effect of 5' UTR variant especially for variant creating/disrupting upstream ORFs
 Please cite Whiffin et al. Characterising the loss-of-function impact of 5' untranslated region variants in whole genome sequence data from 15,708 individuals. bioRxiv (2019)
=cut


package UTRannotator;

require "src/uSTOP_lost.pl";
require "src/uAUG_lost.pl";
require "src/uAUG_gained.pl";
require "src/uSTOP_gained.pl";
require "src/uframeshift.pl";
require "src/five_prime_UTR_utils.pl";

use base qw(Bio::EnsEMBL::Variation::Utils::BaseVepPlugin);
use strict;


sub feature_types {
        return ['Transcript'];
    }

	sub new {
        my $class = shift;
        my $self = $class->SUPER::new(@_);
        my $file = $self->params->[0];

        if ($file)
        {
        open my $fh, "<", $file or die $!;
        my %uORF_evidence;

        while (<$fh>) {
            chomp;
            my ($chr, $pos, $gene, $strand, $type, $stop_pos) = split /\t/;

            my $key = $chr . ":" . $pos; # chr has 'chr' proceeding
            $uORF_evidence{$key} = 1;
        }

        close $fh;

        $self->{uORF_evidence} = \%uORF_evidence;
        }else{
         printf "Warning: small ORF file not found. For human, you could use our curated list of uORFs(from sorf.org) at the repository: 'uORF_starts_ends_GRCh37_PUBLIC.txt' for GRCh37 or 'uORF_starts_ends_GRCh38_PUBLIC.txt' for GRCh38\n";
        }

  return $self;
}

    sub get_header_info {

	my $self->{_header_info} = {
	     five_prime_UTR_variant_consequence => "Output the variant consequences of a given 5 prime UTR variant: uAUG_gained, uAUG_lost, uSTOP_lost or uFrameshift",
	     five_prime_UTR_variant_annotation => "Output the annotation of a given 5 prime UTR variant",
         existing_uORFs => 'The number of existing uORFs with a stop codon within the 5 prime UTR',
         existing_OutOfFrame_oORFs => 'The number of existing out-of-frame overlapping ORFs (OutOfFrame oORF) at the 5 prime UTR',
         existing_InFrame_oORFs => 'The number of existing inFrame overlapping ORFs (inFrame oORF) at the 5 prime UTR',
        };
		return $self->{_header_info};
    }

    sub run {
        my ($self, $tva) = @_;

  #only annotate the effect if the variant is (1)5_prime_UTR_variant
	return {} unless grep {$_->SO_term eq '5_prime_UTR_variant'}  @{$tva->get_all_OverlapConsequences};

    my $bvfo = $tva->base_variation_feature_overlap;
    my $bvfoa = $tva;

	#retrieve the variant info
	my $vf = $tva->variation_feature;
	my $chr = ($vf->{chr}||$vf->seq_region_name);
	my $pos = ($vf->{start}||$vf->seq_region_start);
	my $ref = $bvfo->get_reference_VariationFeatureOverlapAllele->variation_feature_seq;
	my $alt = $tva->variation_feature_seq;
	my %variant = (
	"chr" => $chr,
	"pos" => $pos,
	"ref" => $ref,
	"alt" => $alt,
	);

  #retrieve the UTR info: transcript id, strand, five prime UTR sequence, start and end genomic coordinates.
	my $t = $bvfo->transcript;
	my $transcript_id = (defined $t? $t->stable_id: undef);
    #print $transcript_id."\n";

	#retrieve the gene symbol of the transcript
	my $symbol = $t->{_gene_symbol} || $t->{_gene_hgnc};
	#retrieve the strand of the transcript
	my $tr_strand = $t->strand + 0;
	my $cds = $t->translateable_seq();
	#print $cds_seq."\n";
	#retrieve the five prime utr sequence
	my $five_prime_seq = (defined $t->five_prime_utr? $t->five_prime_utr->seq(): undef);
    #print $five_prime_seq."\n";

    #Type: five_prime_feature - Bio::EnsEMBL::Feature
	my $UTRs = $t->get_all_five_prime_UTRs();
	my @five_utr_starts;
	my @five_utr_ends;
	foreach  my $utr (@$UTRs){
		my $start = $utr->start(); # this will return the absolute starting positions in chromosome of the UTR exons
		my $end = $utr->end(); # this will return the absolute ending positions in chromosome of the UTR exons
		push(@five_utr_starts, $start);
		push(@five_utr_ends,$end);
	}

	
	my @sorted_starts = sort {$a <=> $b} @five_utr_starts;
	my @sorted_ends = sort {$a <=> $b} @five_utr_ends;

	my %UTR_info = (
	"gene" => $symbol,
	"start" => \@sorted_starts,
	"end" => \@sorted_ends,
	"seq" => $five_prime_seq,   #the exon sequences in 5'UTR
	"strand" => $tr_strand,
	"cds_seq" => $cds,
	);

#    my $ucanonial_splicing = %{$self->ucanonical_splicing(\%variant,\%UTR_info)};
	my %uAUG_gained = %{$self->uAUG_gained(\%variant,\%UTR_info)};
  	my %uSTOP_lost = %{$self->uSTOP_lost(\%variant,\%UTR_info)};
  	my %uAUG_lost = %{$self->uAUG_lost(\%variant,\%UTR_info)};
	my %uSTOP_gained = %{$self->uSTOP_gained(\%variant,\%UTR_info)};
    my %uFrameshift = %{$self->uFrameshift(\%variant,\%UTR_info)};

    my %five_prime_flag = (
#    "ucanonical_splicing"=> $ucanonial_splicing{'ucanonical_splicing_flag'},
    "uAUG_gained" => $uAUG_gained{'uAUG_gained_flag'},
    "uSTOP_lost" => $uSTOP_lost{'uSTOP_lost_flag'},
    "uAUG_lost" => $uAUG_lost{'uAUG_lost_flag'},
	"uSTOP_gained" => $uSTOP_gained{'uSTOP_gained_flag'},
    "uFrameshift" =>$uFrameshift{'uFrameShift_flag'},
    );

    my %five_prime_annotation = (
#    "ucanonical_splicing"=> $ucanonial_splicing{'ucanonical_splicing_effect'},
    "uAUG_gained" => $uAUG_gained{"uAUG_gained_effect"},
    "uSTOP_lost" => $uSTOP_lost{"uSTOP_lost_effect"},
    "uAUG_lost" => $uAUG_lost{"uAUG_lost_effect"},
	"uSTOP_gained" => $uSTOP_gained{'uSTOP_gained_effect'},
	"uFrameshift" =>$uFrameshift{'uFrameShift_effect'},
    );


    my @output_five_prime_flag=();
    my @output_five_prime_annotation=();

    foreach my $flag (keys %five_prime_flag){
        if($five_prime_flag{$flag}){
            push @output_five_prime_flag,$five_prime_flag{$flag};
            push @output_five_prime_annotation,$five_prime_annotation{$flag};
        }
    };

	if(!@output_five_prime_flag){@output_five_prime_flag=("-");};
	if(!@output_five_prime_annotation){@output_five_prime_annotation=("-");};
    my %utr_effect = (
    "five_prime_UTR_variant_consequence" => (join "&", @output_five_prime_flag),
    "five_prime_UTR_variant_annotation" => (join "&", @output_five_prime_annotation),
    );

  	my $existing_uORF_num = $self->count_number_ATG($five_prime_seq);
	my $output ={%utr_effect, %$existing_uORF_num};
	return $output? $output: {};
 }


 1;
