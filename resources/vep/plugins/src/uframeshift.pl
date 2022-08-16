use strict;
use warnings;

sub uFrameshift{

    #Description: annotate if a five_prime_UTR_varint create a frameshift in existing uORFs
    #Returntype: hashref

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

    my @sequence = split //, $UTR_info->{seq};
    my $strand = $UTR_info->{strand};
    my $utr_length = @sequence;

    my %existing_uORF = %{$self->existing_uORF(\@sequence)};


    #return annotators
	my $uFrameshift_ref_type = ""; # the type of uORF with the reference allele
    my $uFrameshift_ref_type_length = ""; # the length of the uORF with of the reference allele.
    my $uFrameshift_StartDistanceToCDS = ""; # the distance between the start codon of the disrupted uORF and CDS
    my $uFrameshift_alt_type = ""; # the type of uORF with the alternative allele
    my $uFrameshift_alt_type_length = ""; # the length of the uORF with of the alternative allele
    my $uFrameshift_KozakContext = ""; # the Kozak context sequence of the disrupted uORF
    my $uFrameshift_KozakStrength = ""; # the Kozak strength of the disrupted uORF
    my $uFrameshift_evidence = ""; # whehter there is translation evidence for the disrupted uORF


    #indicate whether the variant ever introduce a frameshift variant
    my $flag_uORF;
    my $output_flag = "";

    my $current_kozak="";
    my $current_kozak_strength="";

    my %result = (); #result is a hash table with two elements: $flag and $output_effects
    my $output_effects="";

    my $ref_coding = $self->get_ref_coding($ref);
    my $alt_coding = $self->get_alt_coding($alt,$strand);

	#skip alleles with same length
	return {} unless(length($ref_coding) ne length($alt_coding));

 	my ($mut_pos, $end_pos) = $self->get_allele_exon_pos($strand, $pos, $ref_coding, $UTR_info);
    return {} unless(defined($mut_pos)&defined($end_pos));

    #if it's a deletion at the boundary of exon and intron, we would skip the annotation

	my $mut_utr_seq = $self->mut_utr_sequence(\@sequence,$mut_pos,$ref_coding,$alt_coding,$strand);
  	my @mut_utr_seq = split //,$mut_utr_seq;
    my $length = @mut_utr_seq;

    my @start = @{$self->get_ATG_pos(\@sequence)};


	#check for each uORF
    if(@start){
    for (my $i=0;$i<@start;$i++){
        $flag_uORF=0;
        my $start_pos = $start[$i];


        my $check_point = $start_pos;
        # the checking end point of eligible area
        #For uORF: start_pos .. check_point
        #For overlapping ORF: start_pos .. 3' end of 5'UTR sequence

        #if the variant is entirely in the uORF (within 5'UTR)

        if(exists($existing_uORF{$start_pos})) {
            my @stops = sort {$a <=> $b} @{$existing_uORF{$start_pos}};
            $check_point = $stops[0]-1;;
        }else{
        #if the existing uORF is an oORF
            $check_point = $utr_length-1;
        }

        # only check the ones between start and stop codons and
        # ignore the cases at the boundary of start and stop codon since the effect on start/stop would be evaluated anyway
		if(($mut_pos>=$start_pos+3)&($end_pos<=$check_point)){
		#snp and insertion could only be annotated here
			$flag_uORF = abs(length($ref_coding)-length($alt_coding))%3;
		}

        if($flag_uORF){

                #getting the Kozak context and Kozak strength of the start codon

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

                $uFrameshift_KozakContext=$current_kozak;
                $uFrameshift_KozakStrength=$kozak_strength{$current_kozak_strength}? $kozak_strength{$current_kozak_strength}:$current_kozak_strength;


                #the annotation of the original uORF
                my @ref_overlapping_seq = split //, $UTR_info->{seq}.$UTR_info->{cds_seq};
                my %ref_existing_oORF = %{$self->existing_uORF(\@ref_overlapping_seq)};

                if (exists($existing_uORF{$start_pos})){ #if there is stop codon within 5'UTR
                    $uFrameshift_ref_type = "uORF";
                }elsif (($utr_length-$start_pos) % 3) {
                    $uFrameshift_ref_type = "OutOfFrame_oORF";

                }else{
                    $uFrameshift_ref_type = "InFrame_oORF";
                    }

                if (exists($ref_existing_oORF{$start_pos})){
                    my @stops = sort {$a <=> $b} @{$ref_existing_oORF{$start_pos}};
                    $uFrameshift_ref_type_length = $stops[0]-$start_pos+3;
                    }else{
                     $uFrameshift_ref_type_length = "NA";
                }

                $uFrameshift_StartDistanceToCDS = $utr_length - $start_pos;

                #if there is an alternative stop codon in the mutant uORF sequence
                my %mut_uORF = %{$self->existing_uORF(\@mut_utr_seq)};
                my @alt_overlapping_seq = split //, $mut_utr_seq.$UTR_info->{cds_seq};
                my %alt_existing_oORF = %{$self->existing_uORF(\@alt_overlapping_seq)};

                if (exists($mut_uORF{$start_pos})){
                $uFrameshift_alt_type = "uORF";
                } #if there is no alternative stop codon
                elsif(($length-$start_pos)%3) {
                    $uFrameshift_alt_type = "OutOfFrame_oORF";
                }
                else{
                    $uFrameshift_alt_type = "InFrame_oORF";
                }

                #get the length
                if (exists($alt_existing_oORF{$start_pos})){
                    my @stops = sort {$a <=> $b} @{$alt_existing_oORF{$start_pos}};
                    $uFrameshift_alt_type_length = $stops[0]-$start_pos+3;
                    }else{
                     $uFrameshift_alt_type_length = "NA";
                }

            	#find evidence from sorfs.org

                $uFrameshift_evidence=$self->find_uorf_evidence($UTR_info,$chr,$start_pos);

                my %uORF_effect = (
                "uFrameShift_ref_type" => $uFrameshift_ref_type,
                "uFrameShift_ref_type_length" => $uFrameshift_ref_type_length,
                "uFrameShift_ref_StartDistanceToCDS" => $uFrameshift_StartDistanceToCDS,
                "uFrameShift_alt_type" => $uFrameshift_alt_type,
                "uFrameShift_alt_type_length" => $uFrameshift_alt_type_length,
                "uFrameShift_KozakContext" => $uFrameshift_KozakContext,
                "uFrameShift_KozakStrength" => $uFrameshift_KozakStrength,
                "uFrameShift_Evidence" => $uFrameshift_evidence,
	             );

                $output_flag = $output_flag? $output_flag."&"."uFrameShift":"uFrameShift";
                $output_effects = $output_effects? $output_effects."&".$self->transform_hash_to_string(\%uORF_effect):$self->transform_hash_to_string(\%uORF_effect);
            }

    }
    }

    $result{'uFrameShift_flag'} = $output_flag;
    $result{'uFrameShift_effect'} = $output_effects;

    return \%result;
}

1;