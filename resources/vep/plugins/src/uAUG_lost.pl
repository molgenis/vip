use strict;
use warnings;

sub uAUG_lost{
    #Description: annotate if a five_prime_UTR_varint removes a start codon of an existing uORF
    #Returntype: hashref

    #output annotations
#    If the variant removes the start codon of an existing uORF
#    uAUG_loss_FrameWithCDS => 'Frame with respect to the main ORF coding sequence'
#    uAUG_loss_KozakContext => 'The surrounding Kozak sequence of the lost uAUG',
#    uAUG_loss_KozakStrength => 'Strength of the surrounding Kozak consensus of the lost uAUG',
#    uAUG_loss_Evidence => 'Whether there is prior evidence of translation documented in sorfs.org',

    my ($self, $variant_info, $UTR_info) = @_;
    my %flip;
    $flip{'A'}='T';
    $flip{'C'}='G';
    $flip{'G'}='C';
    $flip{'T'}='A';

    my %kozak_strength;
    $kozak_strength{1}='Weak';
    $kozak_strength{2}='Moderate';
    $kozak_strength{3}='Strong';

    my $chr = $variant_info->{chr};
    my $pos = $variant_info->{pos};
    my $ref = $variant_info->{ref};
    my $alt = $variant_info->{alt};

    my @sorted_starts = @{$UTR_info->{start}};
    my @sequence = split //, $UTR_info->{seq};
    my $utr_length = @sequence;
    my $strand = $UTR_info->{strand};

    my %existing_ref_uORF = %{$self->existing_uORF(\@sequence)};

    #return annotators
    my $uAUG_lost_type = "";   # the uORF type with the reference allele - uORF, inframe_oORF, outOfFrame_oORF
    my $uAUG_lost_DistanceToCDS = ""; # the distance of the lost uAUG to CDS
    my $uAUG_lost_DistanceToSTOP = ""; # the distance of the lost uAUG to stop codon (could be in CDS)
    my $uAUG_lost_KozakContext = ""; # the Kozak context sequence of the lost uAUG
    my $uAUG_lost_KozakStrength = ""; # the strength of KozakContext of the lost uAUG
    my $uAUG_lost_evidence = ""; # whether this uAUG has any evidence of being translated

    my $current_kozak = "";
    my $current_kozak_strength = "";

    #indicate whether the variant ever disrupts a stop codon
    my $output_flag = "";
    #indicate whether the variant ever disrupts the uORF that being analyzed
    my $flag_uORF=0;

    #the relative position of input variant in the UTR sequence


    my %result = (); #result is a hash table with two elements: $flag and $output_effects
    my $output_effects="";

    my $ref_coding = $self->get_ref_coding($ref);
    my $alt_coding = $self->get_alt_coding($alt,$strand);

    my ($mut_pos, $end_pos) = $self->get_allele_exon_pos($strand, $pos, $ref_coding, $UTR_info);
    return {} unless(defined($mut_pos)&defined($end_pos));


	my $mut_utr_seq = $self->mut_utr_sequence(\@sequence,$mut_pos,$ref_coding,$alt_coding,$strand);
  	my @mut_utr_seq = split //,$mut_utr_seq;

    my @start = @{$self->get_ATG_pos(\@sequence)};


    for (my $i=0;$i<@start;$i++){

        $flag_uORF=0;
        my $start_pos = $start[$i];


        if ($mut_pos-$start_pos>2) {
        next;
        }

        if (length($ref_coding) ne 0){
        if ($mut_pos+length($ref_coding)-1<$start_pos) {
        next;

        }
        } elsif ($mut_pos<$start_pos) {next;}   #for insertion


        #for deletion, it definitely disrupting the uORF.

        if (length($alt_coding) eq 0) {
        $flag_uORF=1;
        }else{

        my $mut_codon = $mut_utr_seq[$start_pos].$mut_utr_seq[$start_pos+1].$mut_utr_seq[$start_pos+2];

        if ($mut_codon eq "ATG") {next;}
        $flag_uORF=1;
        }



        if($flag_uORF){


                #getting the Kozak context and Kozak strength of the lost start codon
  				if ((($start_pos-3)>=0)&&($sequence[($start_pos+3)])){
  					$current_kozak = $sequence[($start_pos-3)].$sequence[($start_pos-2)].$sequence[$start_pos-1]."ATG".$sequence[$start_pos+3];
  				}
  				else{
  					$current_kozak = '-';
  				}

                if ($current_kozak !~ /-/){
                    my @split_kozak = split //, $current_kozak;
                    $current_kozak_strength = 1;
                    if ((($split_kozak[0] eq 'A')||($split_kozak[0] eq 'G'))&&($split_kozak[6] eq 'G')){
                        $current_kozak_strength = 3;
                    }
                    elsif ((($split_kozak[0] eq 'A')||($split_kozak[0] eq 'G'))||($split_kozak[6] eq 'G')){
                        $current_kozak_strength = 2;
                    }
                }
                $uAUG_lost_KozakContext=$current_kozak;
                $uAUG_lost_KozakStrength=$kozak_strength{$current_kozak_strength}? $kozak_strength{$current_kozak_strength}:$current_kozak_strength;

                #check what kind of uORF does that correspond to?
                #first check whether it's overlapping with CDS


                if (exists($existing_ref_uORF{$start_pos})){ #if there is stop codon within 5'UTR
                    $uAUG_lost_type = "uORF"
                }elsif (($utr_length-$start_pos) % 3){
                	$uAUG_lost_type = "OutOfFrame_oORF";
                    }
                else{
                    $uAUG_lost_type = "InFrame_oORF";
                    }

                $uAUG_lost_DistanceToCDS = $utr_length - $start_pos;

                my @overlapping_seq = split //, $UTR_info->{seq}.$UTR_info->{cds_seq};
                my %existing_overlapping_uORF = %{$self->existing_uORF(\@overlapping_seq)};
                if(exists($existing_overlapping_uORF{$start_pos})){

                my @stop_pos_array = sort{$a<=>$b}@{$existing_overlapping_uORF{$start_pos}};
                my $stop_pos = $stop_pos_array[0];
                $uAUG_lost_DistanceToSTOP = $stop_pos-$start_pos;

                }else{
                $uAUG_lost_DistanceToSTOP = "NA"
                }



                $uAUG_lost_evidence=$self->find_uorf_evidence($UTR_info,$chr,$start_pos);

                my %uORF_effect = (
                "uAUG_lost_type" => $uAUG_lost_type,
                "uAUG_lost_CapDistanceToStart" =>$start_pos,
                "uAUG_lost_DistanceToCDS" => $uAUG_lost_DistanceToCDS,
                "uAUG_lost_DistanceToStop" => $uAUG_lost_DistanceToSTOP,
                "uAUG_lost_KozakContext" => $uAUG_lost_KozakContext,
                "uAUG_lost_KozakStrength" => $uAUG_lost_KozakStrength,
                "uAUG_lost_Evidence" => $uAUG_lost_evidence,
	             );

                $output_flag = $output_flag? $output_flag."&"."uAUG_lost":"uAUG_lost";
                $output_effects = $output_effects? $output_effects."&".$self->transform_hash_to_string(\%uORF_effect):$self->transform_hash_to_string(\%uORF_effect);

            }




    }

    $result{'uAUG_lost_flag'} = $output_flag;
    $result{'uAUG_lost_effect'} = $output_effects;

    return \%result;
}

1;