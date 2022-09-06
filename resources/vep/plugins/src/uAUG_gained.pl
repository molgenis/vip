use strict;
use warnings;

sub uAUG_gained{
	#Description: annotate if a five_prime_UTR_variant creates ATG
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

	my $pos = $variant_info->{pos};
	my $ref = $variant_info->{ref};
	my $alt = $variant_info->{alt};

	my @sequence = split //, $UTR_info->{seq};
	my $strand = $UTR_info->{strand};

	#return annotators
	my $uAUG_gained_DistanceToCDS = "";  # the distance between the gained uAUG to CDS
	my $uAUG_gained_KozakContext = "";  # the Kozak context sequence of the gained uAUG
	my $uAUG_gained_KozakStrength = ""; # the Kozak strength of the gained uAUG
	my $uAUG_gained_type = ""; # the type of uORF created - any of the following: uORF, inframe_oORF,OutOfFrame_oORF
	my $uAUG_gained_DistanceFromCap = ""; # the distance between the gained uAUG to the start of the five prime UTR
    my $uAUG_gained_DistanceToStop = ""; #the distance between the gained uAUG to stop codon (could be in CDS)

	#indicate whether the variant creates a ATG
	my $flag = 0;
	my $current_kozak = "";
	my $current_kozak_strength ="";

	#the relative position of input variant in the UTR sequence

    my %result = (); #result is a hash table with two elements: $flag and $output_effects
    my $output_flag = "";
    my $output_effects = "";

    my $ref_coding = $self->get_ref_coding($ref);
    my $alt_coding = $self->get_alt_coding($alt,$strand);

	my ($mut_pos, $end_pos) = $self->get_allele_exon_pos($strand, $pos, $ref_coding, $UTR_info);
    return {} unless(defined($mut_pos)&defined($end_pos));

	my $mut_utr_seq = $self->mut_utr_sequence(\@sequence,$mut_pos,$ref_coding,$alt_coding,$strand);
  	my @mut_utr_seq = split //,$mut_utr_seq;
    my $mut_utr_length = @mut_utr_seq;

    #get the nt sequence that might have the pos_A for a new ATG codon
    my @mut_seq = @mut_utr_seq[$mut_pos-2..$mut_pos+length($alt_coding)+1];
    my @mut_atg_pos = @{$self->get_ATG_pos(\@mut_seq)};

    # check whether there is a ATG codon is to check the length of the array
    #if there is a ATG codon, flag it and output the relative positive of A
    my $pos_A;
    if (@mut_atg_pos){
    #get the pos of A (in ATG) in the UTR sequence
    $pos_A=$mut_pos-2+$mut_atg_pos[0];
    $flag=1;
    }

    if ($flag){

  ################################################################################
  #annotator 1: get the distance to the start codon of the main ORF
  ################################################################################
  		$uAUG_gained_DistanceToCDS = $mut_utr_length-$pos_A;
  		$uAUG_gained_DistanceFromCap = $pos_A;
  ################################################################################
  #annotator 2: determine kozak context;
  ################################################################################
  		if ((($pos_A-3)>=0)&&($mut_utr_seq[($pos_A+3)])){
  			$current_kozak = $mut_utr_seq[($pos_A-3)].$mut_utr_seq[($pos_A-2)].$mut_utr_seq[$pos_A-1]."ATG".$mut_utr_seq[$pos_A+3];
  		}
  		else{
  			$current_kozak = '-';
  		}
  		#get the strength of kozak context
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



		$uAUG_gained_KozakContext=$current_kozak;
        $uAUG_gained_KozakStrength=$kozak_strength{$current_kozak_strength}? $kozak_strength{$current_kozak_strength}:$current_kozak_strength;


  ################################################################################
  #annotator 3: Type of new ORF with respect the main ORF: uORF/Overlapping_inFrame/Overlapping_outofframe
  ################################################################################

        #check what kind of uORF does that correspond to?
        #first check whether it's overlapping with CDS
        my %existing_utr_uorf = %{$self->existing_uORF(\@mut_utr_seq)};


        if(exists($existing_utr_uorf{$pos_A})){ #if there is stop codon within 5'UTR
             $uAUG_gained_type = "uORF";
        }else{

            if(($mut_utr_length - $pos_A) % 3){
                $uAUG_gained_type = "OutOfFrame_oORF";
            }else{
                $uAUG_gained_type = "inFrame_oORF";
            }
        }

        my @overlapping_seq = split //, $mut_utr_seq.$UTR_info->{cds_seq};
        my %existing_uORF = %{$self->existing_uORF(\@overlapping_seq)};
        if(exists($existing_uORF{$pos_A})){
        my @stop_pos_array = sort{$a<=>$b}@{$existing_uORF{$pos_A}};
        my $stop_pos = $stop_pos_array[0];
        $uAUG_gained_DistanceToStop = $stop_pos-$pos_A;
        }else{
        $uAUG_gained_DistanceToStop = "NA";
        }


  		my %uORF_effect = (
        "uAUG_gained_KozakContext" => $uAUG_gained_KozakContext,
        "uAUG_gained_KozakStrength" => $uAUG_gained_KozakStrength,
        "uAUG_gained_DistanceToCDS" => $uAUG_gained_DistanceToCDS,
        "uAUG_gained_type" => $uAUG_gained_type,
        "uAUG_gained_DistanceToStop" => $uAUG_gained_DistanceToStop,
        "uAUG_gained_CapDistanceToStart" => $uAUG_gained_DistanceFromCap,
      );

       $output_flag = "uAUG_gained";
       $output_effects = $self->transform_hash_to_string(\%uORF_effect);


  	}
    $result{'uAUG_gained_flag'} = $output_flag;
    $result{'uAUG_gained_effect'} = $output_effects;

    return \%result;

}

1;