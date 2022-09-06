use strict;
use warnings;

sub uSTOP_lost{

    #Description: annotate if a five_prime_UTR_varint removes a stop codon of an existing uORF(given that uORF doesn't not change)


    #Returntype: hashref

    #output annotations
#    If the variant removes the stop codon of an existing uORF
#    uSTOP_AltStop => 'Whether there is another stop codon in the uORF',
#    uSTOP_AltStopDistanceToCDS => 'The distance of an alternative stop codon to CDS',
#    uSTOP_FrameWithCDS => 'Consequence: Frame with respect to the main ORF coding sequence ',
#    uSTOP_KozakContext => 'The surrounding Kozak sequence of the uAUG in the existing uORF',
#    uSTOP_KozakStrength => 'Strength of the surrounding Kozak consensus of the uAUG in the existing uORF',
#    uSTOP_Evidence => 'Whether there is prior evidence of translation documented in sorfs.org',

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

    my %existing_uORF = %{$self->existing_uORF(\@sequence)};

    #return annotators
    my $uSTOP_lost_AltStop = "";  #whether there is an alternative stop codon downstream
    my $uSTOP_lost_AltStopDistanceToCDS = ""; # the distance between alternative stop codon and the CDS
    my $uSTOP_lost_FrameWithCDS = ""; # the frame of the uORF with respect to CDS
    my $uSTOP_lost_KozakContext = ""; # the Kozak context sequence of the uORF with the lost stop codon
    my $uSTOP_lost_KozakStrength = ""; # the Kozak strength of the uORF with the lost stop codon
    my $uSTOP_lost_evidence = ""; # whether this uORF has any evidence of being translated
    ###

    my $current_kozak = "";
    my $current_kozak_strength = "";

    #indicate whether the variant ever disrupts a stop codon
    my $output_flag = "";
    #indicate whether the variant ever disrupts the uORF that being analyzed
    my $flag_uORF=0;

    #the relative position of input variant in the UTR sequence
    my %result = (); #result is a hash table with two elements: $flag and $output_effects
    my $output_effects="";

    my @stop_codons = ("TAA","TGA","TAG");

    my $ref_coding = $self->get_ref_coding($ref);
    my $alt_coding = $self->get_alt_coding($alt,$strand);

    #if it's a deletion at the boundary of exon and intron, we would skip the annotation

    my ($mut_pos, $end_pos) = $self->get_allele_exon_pos($strand, $pos, $ref_coding, $UTR_info);
    return {} unless(defined($mut_pos)&defined($end_pos));

	my $mut_utr_seq = $self->mut_utr_sequence(\@sequence,$mut_pos,$ref_coding,$alt_coding,$strand);
  	my @mut_utr_seq = split //,$mut_utr_seq;
    my $length = @mut_utr_seq;

    my @start = sort {$a <=> $b} (keys %existing_uORF);

    if(%existing_uORF){
    for (my $i=0;$i<@start;$i++){
        $flag_uORF=0;
        my $start_pos = $start[$i];
        my @stops = sort {$a <=> $b} @{$existing_uORF{$start_pos}};
        my $stop_pos=$stops[0];

        if ($mut_pos-$stop_pos>2) {next;}


        if (length($ref_coding)){

        #for snps and deletion
        if ($mut_pos+length($ref_coding)-1<$stop_pos) {next;}

        } elsif ($mut_pos<$stop_pos) {next;}   #for insertion


        #for deletion, it definitely disrupting the stop codon.

        if (length($alt_coding) eq 0) {
        $flag_uORF=1;
        }else{
        my $mut_codon = $mut_utr_seq[$stop_pos].$mut_utr_seq[$stop_pos+1].$mut_utr_seq[$stop_pos+2];

        if ( grep( /^$mut_codon$/, @stop_codons ) ) {next;}
        $flag_uORF=1;
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

                $uSTOP_lost_KozakContext=$current_kozak;
                $uSTOP_lost_KozakStrength=$kozak_strength{$current_kozak_strength}? $kozak_strength{$current_kozak_strength}:$current_kozak_strength;

                #if there is an alternative stop codon in the mutant uORF sequence
                my %mut_uORF = %{$self->existing_uORF(\@mut_utr_seq)};

                # the sequence before mut_pos should not be changed. Thus start_pos shall still correspond to a start codon;
                # if the sequence is indeed very short as such ATGTGA

                my @mut_stops;
                if(exists($mut_uORF{$start_pos})){
                @mut_stops = sort {$a <=> $b} @{$mut_uORF{$start_pos}}};


                if (@mut_stops>0){
                $uSTOP_lost_AltStop = "True";
             #   $uSTOP_AltStopDistance = $mut_stops[0]-$stops[0];
                $uSTOP_lost_AltStopDistanceToCDS = $length-$mut_stops[0];
                } #if there is no alternative stop codon
                else{
                    $uSTOP_lost_AltStop = "False";
                #    $uSTOP_AltStopDistance = "-";
                    $uSTOP_lost_AltStopDistanceToCDS = "NA";
                }
            	if (($length-$start_pos) % 3){
                	$uSTOP_lost_FrameWithCDS = "outOfFrame";
                    }
                else{
                    $uSTOP_lost_FrameWithCDS = "inFrame";
                    }
            	#find evidence from sorf

                $uSTOP_lost_evidence=$self->find_uorf_evidence($UTR_info,$chr,$start_pos);

                my %uORF_effect = (
                "uSTOP_lost_AltStop" => $uSTOP_lost_AltStop,
                "uSTOP_lost_AltStopDistanceToCDS" => $uSTOP_lost_AltStopDistanceToCDS,
                "uSTOP_lost_FrameWithCDS" => $uSTOP_lost_FrameWithCDS,
                "uSTOP_lost_KozakContext" => $uSTOP_lost_KozakContext,
                "uSTOP_lost_KozakStrength" => $uSTOP_lost_KozakStrength,
                "uSTOP_lost_Evidence" => $uSTOP_lost_evidence,
	             );

                $output_flag = $output_flag? $output_flag."&"."uSTOP_lost":"uSTOP_lost";
                $output_effects = $output_effects? $output_effects."&".$self->transform_hash_to_string(\%uORF_effect):$self->transform_hash_to_string(\%uORF_effect);

            }




    }
    }

    $result{'uSTOP_lost_flag'} = $output_flag;
    $result{'uSTOP_lost_effect'} = $output_effects;

    return \%result;
}

1;