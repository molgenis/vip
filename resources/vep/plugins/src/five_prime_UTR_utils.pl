

sub count_number_ATG{

      #Description: count the number of existing ATGs in the five prime UTR sequence
      #Return: two numbers: the number of uORFs and the number of oORFs
      #Returntype: listref

      my ($self,$seq) = @_;
      my @sequence = split //, $seq;
	  my $length = @sequence;

      my @atg_pos = @{$self->get_ATG_pos(\@sequence)};
      my @mes_pos = @{$self->get_stopcodon_pos(\@sequence)};

      my $atg_num = $self->get_ATG_pos(\@sequence);
      my $inframe_stop_num=0;
      my $outofframe_atg_num=0;
      my $inframeORF_num=0;
      my $flag=0;

      foreach my $atg (@atg_pos){
        $flag=0;
         #indicate whether there is a stop codon with respect to this ATG
        foreach my $mes (@mes_pos){
		        if ((($mes-$atg) % 3)||($mes-$atg)<0){}
		        else{
            $flag=1;
            last;
          }
        }
        #if there is no stop codon, then look at whether it's Out_of_frame or Inframe
        if($flag==1){$inframe_stop_num++;
        }else{
         (($length-$atg) % 3)?$outofframe_atg_num++:$inframeORF_num++;
       }

      }

      my %existing_uORF_num = (
      "existing_uORFs" => $inframe_stop_num,
      "existing_OutOfFrame_oORFs" => $outofframe_atg_num,
      "existing_InFrame_oORFs" => $inframeORF_num,);

        return \%existing_uORF_num;

    }

    sub existing_uORF{
        #Description: obtaining the relative coordinates of start and end pos of existing uORF in the five prime UTR sequence
        #Return: hashref(key:the pos of the first nucleotide of start codon; value:all the positions of the first nucleotide of stop codon)
        my ($self,$seq) = @_;
        my $length = @{$seq};

        my @atg_pos = @{$self->get_ATG_pos($seq)};
        my @mes_pos = @{$self->get_stopcodon_pos($seq)};
        my %uORF;

        foreach my $atg (@atg_pos){
            my @stop_pos;
            foreach my $mes (@mes_pos){
                if ((($mes-$atg) % 3)||($mes-$atg)<0){}
                else{
                    push @stop_pos,$mes;
                }
            }
            if (@stop_pos){
            $uORF{$atg}=[@stop_pos];
        }

    }

        return \%uORF;
    }

    sub get_ATG_pos{

      #Description: get all the relative position of A in ATG of the five prime UTR sequence
      #Returntype: listref

      my ($self,$seq) = @_;

      my @sequence = @{$seq};
      my $length = @sequence;
      my $seq_str=join '', @sequence;;
      my @atg_pos = grep {(substr ($seq_str, $_,3) eq 'ATG')} 0..($length);

      return \@atg_pos;

    }



    sub reverse_sequence{
    #Description: get the complementary sequence of a given input sequence
    #Return: string - the complementary sequence

    my ($self,$seq) = @_;
    my $rev_seq = reverse $seq;
    $rev_seq =~ tr/ATGCatgc/TACGtacg/;
    return $rev_seq

    }


    sub get_stopcodon_pos{
	#Description: get all the relative position of stop codons in the five prime UTR sequence
	#Returntype: listref
	my ($self,$seq) = @_;

  	my @sequence = @{$seq};
  	my $length = @sequence;

	my @met_pos;
    if($length){
	for (my $seq_n=0; $seq_n<$length; $seq_n++){
	if ((($sequence[$seq_n] eq 'T')&&($sequence[$seq_n+1] eq 'A')&&($sequence[$seq_n+2] eq 'A'))
	||(($sequence[$seq_n] eq 'T')&&($sequence[$seq_n+1] eq 'A')&&($sequence[$seq_n+2] eq 'G'))
	||(($sequence[$seq_n] eq 'T')&&($sequence[$seq_n+1] eq 'G')&&($sequence[$seq_n+2] eq 'A')))
				{
					push @met_pos,$seq_n;
				}
	}}
	#return a reference
	return \@met_pos;
}
    sub get_ref_coding{

    my ($self,$ref) = @_;
    my $ref_coding = $ref;

    if($ref_coding eq "-"){   #for insertion
    $ref_coding = "";}

    return $ref_coding;

    }

    sub get_alt_coding{


    my ($self,$alt,$strand) = @_;
    my $alt_coding = $alt;

    if($alt_coding eq "-"){
    $alt_coding = "";
    }


    if($strand == -1){
    $alt_coding = $self->reverse_sequence($alt_coding);
    }

    return $alt_coding;

    }

    sub mut_utr_sequence{

    #Description: get the mutated five prime UTR sequence
    #Returntype: a string of sequence

    my ($self,$seq,$mut_pos,$ref_coding,$alt_coding,$strand) = @_;
    my @sequence = @{$seq};
    my $length = @sequence;

    #order from 5' to 3'
    my $mut_sequence;
    $mut_sequence = (join "", @sequence[0..$mut_pos-1]).$alt_coding.(join "", @sequence[$mut_pos+length($ref_coding)..$length-1]);

    return $mut_sequence;

    }

    sub transform_hash_to_string{

    my ($self,$hash) = @_;
    my %hash = %{$hash};

    my $output_str = "";
    foreach my $key (sort keys %hash){
    $output_str = $output_str.$key.":".$hash{$key}.",";


    };
    if($output_str){chop($output_str);
    }
    return $output_str;


    }

    sub utr_exon_position{
    #give chr position, output utr position
        my ($self,$UTR_info) = @_;
        my @sorted_starts = @{$UTR_info->{start}};
	    my @sorted_ends = @{$UTR_info->{end}};
	    my $num_exons = @sorted_starts;
        my $strand = $UTR_info->{strand};
	    my %chr_position;
	    my $utr_position = 0;

        if ($strand == 1){

  	#create a map from chromosome position to UTR position
  	for (my $m=0; $m<$num_exons; $m++)
  	{
  		for (my $p=$sorted_starts[$m]; $p<=$sorted_ends[$m]; $p++)
  		{
  			$chr_position{$p}=$utr_position;
  			$utr_position++;
  		}
  	} }

  	 if ($strand == -1){

  	#create a map from chromosome position to UTR position
  	#the exons were arranged in increasing order above

  	for (my $m=$num_exons-1; $m>=0; $m--)
  	{
  		for (my $p=$sorted_ends[$m]; $p>=$sorted_starts[$m]; $p--)
  		{
  			$chr_position{$p}=$utr_position;
  			$utr_position++;

  		}
  	}}

        return \%chr_position;
    }

    sub chr_position{
    #give utr position, output chr position

        my ($self,$UTR_info) = @_;
        my @sorted_starts = @{$UTR_info->{start}};
	    my @sorted_ends = @{$UTR_info->{end}};
	    my $num_exons = @sorted_starts;
        my $strand = $UTR_info->{strand};
	    my %utr_position;
	    my $utr_position = 0;

        if ($strand == 1){

  	#create a map from chromosome position to UTR position
  	for (my $m=0; $m<$num_exons; $m++)
  	{
  		for (my $p=$sorted_starts[$m]; $p<=$sorted_ends[$m]; $p++)
  		{
  			$utr_position{$utr_position}=$p;
  			$utr_position++;
  		}
  	} }

  	 if ($strand == -1){

  	#create a map from chromosome position to UTR position
  	#the exons were arranged in increasing order above

  	for (my $m=$num_exons-1; $m>=0; $m--)
  	{
  		for (my $p=$sorted_ends[$m]; $p>=$sorted_starts[$m]; $p--)
  		{
  			$utr_position{$utr_position}=$p;
  			$utr_position++;

  		}
  	}}

        return \%utr_position;
    }
    
    sub get_allele_exon_pos {
        # return the 5' start and end position at the exon of the ref allele

        my ($self, $strand, $pos, $ref_coding, $UTR_info) = @_;
        my %utr_exon_pos = %{$self->utr_exon_position($UTR_info)};

        my $ref_start;
        my $ref_end;

        if ($strand == 1) {
            $ref_start = $utr_exon_pos{$pos};
            #if it's an insertion (length($ref_coding)==1)
            if(length($ref_coding)){
            $ref_end = $utr_exon_pos{$pos + length($ref_coding) - 1};}
            else{
            $ref_end = $ref_start;
            }
        }
        else {
            $ref_start = $utr_exon_pos{$pos+length($ref_coding)-1};
            if(length($ref_coding)){
                $ref_end = $utr_exon_pos{$pos};
            }else{
                $ref_end = $ref_start;
            }

        }

        return ($ref_start, $ref_end);
    }


    sub find_uorf_evidence{
       my ($self,$UTR_info,$chr,$start_pos)=@_;
       my %utr_pos = %{$self->chr_position($UTR_info)};
       my $start_chr_pos = $utr_pos{$start_pos};


       my $query = ($chr=~/chr/i)?$chr.":".$start_chr_pos:"chr".$chr.":".$start_chr_pos;
       if(exists($self->{uORF_evidence})){
          $evidence=$self->{uORF_evidence}->{$query}?"True":"False";
       }else{
          $evidence= "NA";
       }

       return $evidence;

    }







1;