package PreferredTranscript;

use strict;
use warnings;

use Bio::EnsEMBL::Variation::Utils::BaseVepPlugin;
use base qw(Bio::EnsEMBL::Variation::Utils::BaseVepPlugin);

=head1 NAME
 PreferredTranscript
=head1 SYNOPSIS
 mv PreferredTranscript.pm ~/.vep/Plugins
 ./vep -i variations.vcf --plugin PreferredTranscript,/FULL_PATH_TO_PREFERRED_TRANSCRIPT_FILE/preferred_transcripts.txt
=head1 DESCRIPTION
 Plugin to annotate consequences with PREFERRED flag based on a predefined list.
=cut

sub version {
    return '1.0';
}

sub feature_types {
    return ['Transcript'];
}

sub get_header_info {
    return {
        PREFERRED   => "Flags a transcript as preferred"
    };
}
sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);
    my $file = $self->params->[0];

    die("ERROR: input file not specified\n") unless $file;
    open(FH, '<', $file) or die $!;

    my %preferred_transcripts;

    while(<FH>){
        my $preferred_transcript = $_;
	chomp $preferred_transcript;
        $preferred_transcripts{$preferred_transcript} = 1;
    }

    $self->{preferred_transcripts} = \%preferred_transcripts;

    return $self;
}

sub run {
    my ($self, $tva) = @_;
    my $preferred_transcripts = $self->{preferred_transcripts};

    my $transcriptId = $tva->transcript->stable_id;

    return {
       PREFERRED => $preferred_transcripts->{$transcriptId}
    };
}

1;
