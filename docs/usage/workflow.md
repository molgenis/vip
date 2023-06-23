# Workflow
VIP consists of three workflows depending on the type of input data: fastq, bam/cram or (g)vcf.
The `fastq` workflow is an extension of the `cram` workflow. The `cram` workflow is an extension of the `vcf` workflow.
The `vcf` workflow produces the pipeline outputs as described [here](./output.md).
The following sections provide an overview of the steps of each of these workflows. 

```mermaid
flowchart TD
    p0((Channel.from))
    p1([map])
    p2([map])
    p3([branch])
    p4[minimap2_index]
    p5([map])
    p6([mix])
    p7([branch])
    p8([branch])
    p9([map])
    p10[fastq:concat_fastq_paired_end]
    p11([map])
    p12([mix])
    p13([map])
    p14[fastq:minimap2_align_paired_end]
    p15([map])
    p16([branch])
    p17([map])
    p18[fastq:concat_fastq]
    p19([map])
    p20([mix])
    p21([map])
    p22[fastq:minimap2_align]
    p23([map])
    p24([mix])
    p25([branch])
    p26([map])
    p27[fastq:cram:samtools_index]
    p28([map])
    p29([mix])
    p30([flatMap])
    p31([multiMap])
    p32([map])
    p33[fastq:cram:clair3_call]
    p34([map])
    p35([multiMap])
    p36([map])
    p37([groupTuple])
    p38([map])
    p39[fastq:cram:merge_gvcf]
    p40([map])
    p41([map])
    p42([groupTuple])
    p43([map])
    p44[fastq:cram:clair3_call_publish]
    p45(( ))
    p46([branch])
    p47([map])
    p48[fastq:cram:samtools_addreplacerg]
    p49([map])
    p50([groupTuple])
    p51([map])
    p52[fastq:cram:manta_call]
    p53([map])
    p54([multiMap])
    p55([map])
    p56([groupTuple])
    p57([map])
    p58[fastq:cram:manta_call_publish]
    p59(( ))
    p60([map])
    p61[fastq:cram:sniffles2_call]
    p62([map])
    p63([groupTuple])
    p64([map])
    p65[fastq:cram:sniffles2_combined_call]
    p66([map])
    p67([multiMap])
    p68([map])
    p69([groupTuple])
    p70([map])
    p71[fastq:cram:sniffles_call_publish]
    p72(( ))
    p73([mix])
    p74([mix])
    p75([map])
    p76([groupTuple])
    p77([map])
    p78[fastq:cram:concat_vcf]
    p79([flatMap])
    p80([map])
    p81([groupTuple])
    p82([map])
    p83([branch])
    p84([map])
    p85[fastq:cram:vcf:convert]
    p86([map])
    p87([map])
    p88[fastq:cram:vcf:index]
    p89([map])
    p90([map])
    p91[fastq:cram:vcf:stats]
    p92([map])
    p93([mix])
    p94([flatMap])
    p95([map])
    p96([groupTuple])
    p97([map])
    p98([branch])
    p99([map])
    p100[fastq:cram:vcf:merge_vcf]
    p101([map])
    p102([map])
    p103[fastq:cram:vcf:merge_gvcf]
    p104([map])
    p105([map])
    p106([mix])
    p107([branch])
    p108([flatMap])
    p109([branch])
    p110([map])
    p111[fastq:cram:vcf:split]
    p112([map])
    p113([mix])
    p114([map])
    p115([branch])
    p116([branch])
    p117[fastq:cram:vcf:normalize]
    p118([mix])
    p119([branch])
    p120[fastq:cram:vcf:annotate]
    p121([multiMap])
    p122([mix])
    p123([map])
    p124([groupTuple])
    p125([map])
    p126[fastq:cram:vcf:annotate_publish]
    p127(( ))
    p128([mix])
    p129([branch])
    p130[fastq:cram:vcf:classify]
    p131([multiMap])
    p132([mix])
    p133([map])
    p134([groupTuple])
    p135([map])
    p136[fastq:cram:vcf:classify_publish]
    p137(( ))
    p138([mix])
    p139([branch])
    p140[fastq:cram:vcf:filter]
    p141([branch])
    p142([mix])
    p143([branch])
    p144[fastq:cram:vcf:inheritance]
    p145([mix])
    p146([branch])
    p147[fastq:cram:vcf:classify_samples]
    p148([multiMap])
    p149([mix])
    p150([map])
    p151([groupTuple])
    p152([map])
    p153[fastq:cram:vcf:classify_samples_publish]
    p154(( ))
    p155([mix])
    p156([branch])
    p157[fastq:cram:vcf:filter_samples]
    p158([branch])
    p159([mix])
    p160([map])
    p161([groupTuple])
    p162([map])
    p163([branch])
    p164[fastq:cram:vcf:concat]
    p165([map])
    p166([branch])
    p167([map])
    p168([mix])
    p169([branch])
    p170([flatMap])
    p171([map])
    p172[fastq:cram:vcf:slice]
    p173([map])
    p174([map])
    p175([groupTuple])
    p176([map])
    p177([mix])
    p178([map])
    p179[fastq:cram:vcf:report]
    p180(( ))
    p0 --> p1
    p1 --> p2
    p2 --> p3
    p3 --> p6
    p3 --> p4
    p4 --> p5
    p5 -->|ch_index_indexed| p6
    p6 -->|meta| p7
    p7 --> p16
    p7 --> p8
    p8 --> p9
    p8 --> p12
    p9 --> p10
    p10 --> p11
    p11 -->|ch_input_paired_end_merged| p12
    p12 --> p13
    p13 --> p14
    p14 --> p15
    p15 -->|ch_input_paired_end_aligned| p24
    p16 --> p20
    p16 --> p17
    p17 --> p18
    p18 --> p19
    p19 -->|ch_input_single_merged| p20
    p20 --> p21
    p21 --> p22
    p22 --> p23
    p23 -->|ch_input_single_aligned| p24
    p24 -->|meta| p25
    p25 --> p26
    p25 --> p29
    p26 --> p27
    p27 --> p28
    p28 -->|ch_cram_indexed| p29
    p29 --> p30
    p30 --> p31
    p31 --> p32
    p31 --> p46
    p32 --> p33
    p33 --> p34
    p34 --> p35
    p35 --> p41
    p35 --> p36
    p36 --> p37
    p37 --> p38
    p38 --> p39
    p39 --> p40
    p40 -->|ch_vcf_chunked_snvs_merged| p74
    p41 --> p42
    p42 --> p43
    p43 --> p44
    p44 --> p45
    p46 --> p60
    p46 --> p47
    p47 --> p48
    p48 --> p49
    p49 --> p50
    p50 --> p51
    p51 --> p52
    p52 --> p53
    p53 --> p54
    p54 --> p73
    p54 --> p55
    p55 --> p56
    p56 --> p57
    p57 --> p58
    p58 --> p59
    p60 --> p61
    p61 --> p62
    p62 --> p63
    p63 --> p64
    p64 --> p65
    p65 --> p66
    p66 --> p67
    p67 --> p73
    p67 --> p68
    p68 --> p69
    p69 --> p70
    p70 --> p71
    p71 --> p72
    p73 -->|ch_vcf_chunked_svs_done| p74
    p74 --> p75
    p75 --> p76
    p76 --> p77
    p77 --> p78
    p78 --> p79
    p79 -->|meta| p80
    p80 --> p81
    p81 --> p82
    p82 --> p83
    p83 --> p90
    p83 --> p93
    p83 --> p87
    p83 --> p84
    p84 --> p85
    p85 --> p86
    p86 -->|ch_vcfs_converted| p93
    p87 --> p88
    p88 --> p89
    p89 -->|ch_vcfs_indexed| p93
    p90 --> p91
    p91 --> p92
    p92 -->|ch_vcfs_statsed| p93
    p93 --> p94
    p94 -->|ch_vcfs_preprocessed| p95
    p95 --> p96
    p96 --> p97
    p97 --> p98
    p98 --> p99
    p98 --> p102
    p98 --> p105
    p99 --> p100
    p100 --> p101
    p101 -->|ch_project_vcfs_merged_vcfs| p106
    p102 --> p103
    p103 --> p104
    p104 -->|ch_project_vcfs_merged_gvcfs| p106
    p105 --> p106
    p106 -->|ch_project_vcfs_merged| p107
    p107 --> p113
    p107 --> p108
    p108 --> p109
    p109 --> p113
    p109 --> p110
    p110 --> p111
    p111 --> p112
    p112 -->|ch_inputs_splitted| p113
    p113 -->|ch_inputs_scattered| p114
    p114 --> p115
    p115 --> p116
    p115 --> p122
    p116 --> p117
    p116 --> p118
    p117 --> p118
    p118 --> p119
    p119 --> p128
    p119 --> p120
    p120 --> p121
    p121 --> p128
    p121 --> p122
    p122 --> p123
    p123 --> p124
    p124 --> p125
    p125 --> p126
    p126 --> p127
    p128 --> p129
    p129 --> p138
    p129 --> p130
    p130 --> p131
    p131 --> p138
    p131 --> p132
    p115 --> p132
    p132 --> p133
    p133 --> p134
    p134 --> p135
    p135 --> p136
    p136 --> p137
    p138 --> p139
    p139 --> p140
    p139 --> p142
    p140 --> p141
    p141 --> p142
    p141 --> p149
    p142 --> p143
    p143 --> p145
    p143 --> p144
    p144 --> p145
    p145 --> p146
    p146 --> p147
    p146 --> p155
    p147 --> p148
    p148 --> p149
    p148 --> p155
    p115 --> p149
    p149 --> p150
    p150 --> p151
    p151 --> p152
    p152 --> p153
    p153 --> p154
    p155 --> p156
    p156 --> p159
    p156 --> p157
    p157 --> p158
    p158 --> p159
    p158 --> p159
    p115 --> p159
    p141 --> p159
    p159 --> p160
    p160 --> p161
    p161 --> p162
    p162 --> p163
    p163 --> p164
    p163 --> p167
    p164 --> p165
    p165 --> p166
    p166 --> p168
    p166 --> p168
    p167 -->|ch_output_singleton| p168
    p168 --> p169
    p169 --> p170
    p169 --> p177
    p170 --> p171
    p171 --> p172
    p172 --> p173
    p173 --> p174
    p174 --> p175
    p175 --> p176
    p176 -->|ch_sliced| p177
    p177 --> p178
    p178 --> p179
    p179 --> p180
```


*Above: Nextflow rendering of the `fastq` workflow*

## FASTQ
The `fastq` workflow consists of the following steps:

1. Parallelize sample sheet per sample and for each sample
2. Discover fastq index files and create missing indices
3. In case of multiple fastq files per sample, concatenate the files
4. Alignment using [minimap2](https://github.com/lh3/minimap2) producing a `cram` file per sample
5. Continue with step 2. of the `cram` workflow

For details, see [here](https://github.com/molgenis/vip/blob/main/vip_fastq.nf).

## CRAM
The `cram` workflow consists of the following steps:

1. Parallelize sample sheet per sample and for each sample
2. Discover cram index files and create missing indices
3. Discover short tandem repeats using [ExpansionHunter](https://github.com/Illumina/ExpansionHunter) and publish as intermediate result 
4. Parallelize cram in chunks consisting of one or more contigs and for each chunk
    1. Perform short variant calling with [Clair3](https://github.com/HKU-BAL/Clair3) producing a `gvcf` file per chunk per sample, the gvcfs of the samples in a project are than merged to one vcf per project (using [GLnexus](https://github.com/dnanexus-rnd/GLnexus).
    2. Perform structural variant calling with [Manta](https://github.com/Illumina/manta) or [cuteSV](https://github.com/tjiangHIT/cuteSV) producing a `vcf` file per chunk per project.
5. Concatenate short variant calling and structural variant calling `vcf` files per chunk per sample
6. Continue with step 3. of the `vcf` workflow

Known limitation: Clair3 is not calling the small variants on the Mitochondia.

For details, see [here](https://github.com/molgenis/vip/blob/main/vip_cram.nf).

## VCF
The `vcf` workflow consists of the following steps:

1. Parallelize sample sheet per sample and for each sample
2. Discover cram index files and create missing indices
3. Merge `vcf` files (using [GLnexus](https://github.com/dnanexus-rnd/GLnexus) in case of .g.vcf files) resulting in one `vcf` (per chunk) per project
4. If the data is not chunked: parallelize `vcf` files in chunks consisting of one or more contigs and for each chunk and for each chunk
    1. Normalize
    2. Annotate
    3. Classify
    4. Filter
    5. Perform inheritance matching
    6. Classify in the context of samples
    7. Filter in the context of samples
5. Concatenate chunks resulting in one vcf file per project
6. If `cram` data is available slice the `cram` files to only keep relevant reads
7. Create report

For details, see [here](https://github.com/molgenis/vip/blob/main/vip_vcf.nf).