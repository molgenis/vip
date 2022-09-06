use strict;
use warnings;

sub uSTOP_gained{
	#Description: annotate whether a five_prime_UTR_variant creates new stop codon. It only evaluate SNVs.
	#Returntype: hashref

	my ($self, $variant_info,$UTR_info) = @_;
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

	#return annotators
	my $uSTOP_gained_ref_StartDistanceToCDS = "";  # the distance between the uAUG of the disrupting uORF to CDS
	my $uSTOP_gained_KozakContext = "";  # the Kozak context sequence of the disrupting uORF
	my $uSTOP_gained_KozakStrength = ""; # the Kozak strength of the the disrupting uORF
	my $uSTOP_gained_ref_type = ""; # the type of uORF being disrupted - any of the following: uORF, inframe_oORF,OutOfFrame_oORF
	my $uSTOP_gained_newSTOPDistanceToCDS = ""; # the distance between the gained uSTOP to the start of the CDS
    my $uSTOP_gained_evidence = ""; # the translation evidence of the disrupted uORF

	#indicate whether the variant creates a stop codon
	my $flag = 0;
	my $current_kozak = "";
	my $current_kozak_strength ="";

	#the relative position of input variant in the UTR sequence

    my %result = (); #result is a hash table with two elements: $flag and $output_effects
    my $output_flag = 0;
    my $output_effects = "";

    my %existing_ref_uORF = %{$self->existing_uORF(\@sequence)};

    my $ref_coding = $self->get_ref_coding($ref);
    my $alt_coding = $self->get_alt_coding($alt,$strand);

    #only evaluate SNVs and MNVs, for deletion and insertion it would be evaluated in the uframeshift
    return{} unless(length($ref_coding) eq length($alt_coding));
    # the length of the 5'UTR won't change so as the coordinates of the nts


	my ($mut_pos, $end_pos) = $self->get_allele_exon_pos($strand, $pos, $ref_coding, $UTR_info);
    return {} unless(defined($mut_pos)&defined($end_pos));

	my $mut_utr_seq = $self->mut_utr_sequence(\@sequence,$mut_pos,$ref_coding,$alt_coding,$strand);
  	my @mut_utr_seq = split //,$mut_utr_seq;
    my $mut_utr_length = @mut_utr_seq;
    my %mut_uORF = %{$self->existing_uORF(\@mut_utr_seq)};

    my @start = @{$self->get_ATG_pos(\@sequence)};

    if(@start){
    for (my $i=0;$i<@start;$i++){
        $flag=0;
        my $start_pos = $start[$i];

        # to set the range for searching new STOP codon: not including start_codon, (1) for uORFs - start_codon...stop_codon (2) for oORFs - start_codon...end of 5'UTR

        my $check_point = $start_pos;
        # the checking end point of eligible area
        #For uORF: start_pos .. check_point
        #For overlapping ORF: start_pos .. 3' end of 5'UTR sequence
        #if the variant is entirely in the uORF (within 5'UTR
        if(exists($existing_ref_uORF{$start_pos})) {
            my @stops = sort {$a <=> $b} @{$existing_ref_uORF{$start_pos}};
            $check_point = $stops[0]-1;
        }else{
        #if the existing uORF is an oORF
            $check_point = $utr_length-1;
        }

        # only check the ones between start and stop codons
        # ignore the cases at the boundary of start and stop codon since the effect on start/stop would be evaluated anyway
		if(($mut_pos<$start_pos+3)|($end_pos>$check_point)) {next;}
        #check whether there are new stop codon induced by this mutation
        my @mut_stops;
        if(exists($mut_uORF{$start_pos})){
            @mut_stops = sort {$a <=> $b} @{$mut_uORF{$start_pos}};
        }else{next;};

        my $mut_stop = $mut_stops[0];
        if($mut_stop<$check_point){
            $flag=1;}

        if($flag){

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

                $uSTOP_gained_KozakContext=$current_kozak;
                $uSTOP_gained_KozakStrength=$kozak_strength{$current_kozak_strength}? $kozak_strength{$current_kozak_strength}:$current_kozak_strength;


                #the annotation of the original uORF
                if (exists($existing_ref_uORF{$start_pos})){ #if there is stop codon within 5'UTR
                    $uSTOP_gained_ref_type = "uORF"
                }elsif (($utr_length-$start_pos) % 3){
                	$uSTOP_gained_ref_type = "OutOfFrame_oORF";
                    }
                else{
                    $uSTOP_gained_ref_type = "InFrame_oORF";
                    }

                $uSTOP_gained_ref_StartDistanceToCDS = $utr_length - $start_pos;
                $uSTOP_gained_newSTOPDistanceToCDS = $mut_utr_length - $mut_stop;

            	#find evidence from sorfs.org

                $uSTOP_gained_evidence=$self->find_uorf_evidence($UTR_info,$chr,$start_pos);


                my %uORF_effect = (
                "uSTOP_gained_ref_type" => $uSTOP_gained_ref_type,
                "uSTOP_gained_ref_StartDistanceToCDS" => $uSTOP_gained_ref_StartDistanceToCDS,
                "uSTOP_gained_newSTOPDistanceToCDS" => $uSTOP_gained_newSTOPDistanceToCDS,
                "uSTOP_gained_KozakContext" => $uSTOP_gained_KozakContext,
                "uSTOP_gained_KozakStrength" => $uSTOP_gained_KozakStrength,
                "uSTOP_gained_Evidence" => $uSTOP_gained_evidence,
	             );

                $output_flag = $output_flag? $output_flag."&"."uSTOP_gained":"uSTOP_gained";
                $output_effects = $output_effects? $output_effects."&".$self->transform_hash_to_string(\%uORF_effect):$self->transform_hash_to_string(\%uORF_effect);
            }

    }
    }


    $result{'uSTOP_gained_flag'} = $output_flag;
    $result{'uSTOP_gained_effect'} = $output_effects;
    return \%result;

}

1;
