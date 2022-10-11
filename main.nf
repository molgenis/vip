nextflow.enable.dsl=2

process fastq_to_cram {
  input:
    tuple val(meta), path(reference), path(referenceFai), path(referenceGzi), path(referenceMmiIndex)
  output:
    tuple val(meta), path(cram), path(cramCrai)
  script:
    cram="${meta.family_id}_${meta.individual_id}.cram"
    cramCrai="${cram}.crai"
    """
    ${CMD_MINIMAP2} -t ${task.cpus} -a -x sr ${referenceMmiIndex} ${meta.fastq_r1} ${meta.fastq_r2} | \
    ${CMD_SAMTOOLS} fixmate -u -m - - | \
    ${CMD_SAMTOOLS} sort -u -@ ${task.cpus} -T ${TMPDIR} - | \
    ${CMD_SAMTOOLS} markdup -@ ${task.cpus} --reference ${reference} --write-index - ${cram}
    """
}

process cram_stats {
  executor 'local'

  input:
    tuple val(meta), path(cram), path(cramCrai)
  output:
    tuple val(meta), path(cramStats)
  script:
    cramStats="${cram}.stats"
    """
    ${CMD_SAMTOOLS} idxstats ${cram} > ${cramStats}
    """
}

process deepvariant {
  input:
    tuple val(meta), path(reference), path(referenceFai), path(referenceGzi), path(cram), path(cramCrai)
  output:
    tuple val(meta), path(gVcf)
  script:
    vcf="${meta.family_id}_${meta.individual_id}_${meta.contig}.vcf.gz"
    gVcf="${meta.family_id}_${meta.individual_id}_${meta.contig}.g.vcf.gz"
    """
    ${CMD_DEEPVARIANT} \
      --model_type=WES \
      --ref=${reference} \
      --reads=${cram} \
      --regions ${meta.contig} \
      --sample_name ${meta.family_id}_${meta.individual_id} \
      --output_vcf="${vcf}" \
      --output_gvcf="${gVcf}" \
      --intermediate_results_dir ${TMPDIR} \
      --num_shards=${task.cpus}
    """
}

// FIXME set right model type
process deeptrio {
  input:
    tuple val(meta), path(reference), path(referenceFai), path(referenceGzi), path(cramChild), path(cramCraiChild), path(cramFather), path(cramCraiFather), path(cramMother), path(cramCraiMother)
  output:
    tuple val(meta), path(gVcfChild), path(gVcfFather), path(gVcfMother)
  script:
    vcfChild="${meta.family_id}_${meta.individual_id}_${meta.contig}.vcf.gz"
    vcfFather="${meta.family_id}_${meta.paternal_id}_${meta.contig}.vcf.gz"
    vcfMother="${meta.family_id}_${meta.maternal_id}_${meta.contig}.vcf.gz"
    gVcfChild="${meta.family_id}_${meta.individual_id}_${meta.contig}.g.vcf.gz"
    gVcfFather="${meta.family_id}_${meta.paternal_id}_${meta.contig}.g.vcf.gz"
    gVcfMother="${meta.family_id}_${meta.maternal_id}_${meta.contig}.g.vcf.gz"
    """
    ${CMD_DEEPTRIO} \
      --model_type=WES \
      --ref=${reference} \
      --reads_child=${cramChild} \
      --reads_parent1=${cramFather} \
      --reads_parent2=${cramMother} \
      --regions ${meta.contig} \
      --sample_name_child=${meta.family_id}_${meta.individual_id} \
      --sample_name_parent1=${meta.family_id}_${meta.paternal_id} \
      --sample_name_parent2=${meta.family_id}_${meta.maternal_id} \
      --output_vcf_child="${vcfChild}" \
      --output_vcf_parent1="${vcfFather}" \
      --output_vcf_parent2="${vcfMother}" \
      --output_gvcf_child="${gVcfChild}" \
      --output_gvcf_parent1="${gVcfFather}" \
      --output_gvcf_parent2="${gVcfMother}" \
      --intermediate_results_dir ${TMPDIR} \
      --num_shards=${task.cpus}
    """
}

// FIXME set right model type
process deeptrio_father {
  input:
    tuple val(meta), path(reference), path(referenceFai), path(referenceGzi), path(cramChild), path(cramCraiChild), path(cramFather), path(cramCraiFather)
  output:
    tuple val(meta), path(gVcfChild), path(gVcfFather)
  script:
    vcfChild="${meta.family_id}_${meta.individual_id}_${meta.contig}.vcf.gz"
    vcfFather="${meta.family_id}_${meta.paternal_id}_${meta.contig}.vcf.gz"
    gVcfChild="${meta.family_id}_${meta.individual_id}_${meta.contig}.g.vcf.gz"
    gVcfFather="${meta.family_id}_${meta.paternal_id}_${meta.contig}.g.vcf.gz"
    """
    ${CMD_DEEPTRIO} \
      --model_type=WES \
      --ref=${reference} \
      --reads_child=${cramChild} \
      --reads_parent1=${cramFather} \
      --regions ${meta.contig} \
      --sample_name_child=${meta.family_id}_${meta.individual_id} \
      --sample_name_parent1=${meta.family_id}_${meta.paternal_id} \
      --output_vcf_child="${vcfChild}" \
      --output_vcf_parent1="${vcfFather}" \
      --output_gvcf_child="${gVcfChild}" \
      --output_gvcf_parent1="${gVcfFather}" \
      --intermediate_results_dir ${TMPDIR} \
      --num_shards=${task.cpus}
    """
}

// FIXME set right model type
process deeptrio_mother {
  input:
    tuple val(meta), path(reference), path(referenceFai), path(referenceGzi), path(cramChild), path(cramCraiChild), path(cramMother), path(cramCraiMother)
  output:
    tuple val(meta), path(gVcfChild), path(gVcfMother)
  script:
    vcfChild="${meta.family_id}_${meta.individual_id}_${meta.contig}.vcf.gz"
    vcfMother="${meta.family_id}_${meta.maternal_id}_${meta.contig}.vcf.gz"
    gVcfChild="${meta.family_id}_${meta.individual_id}_${meta.contig}.g.vcf.gz"
    gVcfMother="${meta.family_id}_${meta.maternal_id}_${meta.contig}.g.vcf.gz"
    """
    ${CMD_DEEPTRIO} \
      --model_type=WES \
      --ref=${reference} \
      --reads_child=${cramChild} \
      --reads_parent1=${cramMother} \
      --regions ${meta.contig} \
      --sample_name_child=${meta.family_id}_${meta.individual_id} \
      --sample_name_parent1=${meta.family_id}_${meta.maternal_id} \
      --output_vcf_child="${vcfChild}" \
      --output_vcf_parent1="${vcfMother}" \
      --output_gvcf_child="${gVcfChild}" \
      --output_gvcf_parent1="${gVcfMother}" \
      --intermediate_results_dir ${TMPDIR} \
      --num_shards=${task.cpus}
    """
}

// FIXME set config based on sample sheet
// FIXME how to set mem-gbytes?
process glnexus {
  input:
    tuple val(meta), path(gVcfs)
  output:
    tuple val(meta), path(bcf)
  script:
    bcf="${meta.contig}.bcf"
    """
    ${CMD_GLNEXUS} \
      --dir ${TMPDIR}/glnexus \
      --config DeepVariantWES \
      --mem-gbytes 4 \
      --threads ${task.cpus} \
      ${gVcfs} > ${bcf}
    """
}

process bcftools_concat {
  input:
    path(bcfs)
  output:
    path(vcf)
  script:
    vcf="out.vcf.gz"
    """
    ${CMD_BCFTOOLS} concat \
    --output-type z9 \
    --output "${vcf}" \
    --no-version \
    --threads "${task.cpus}" ${bcfs}
    """
}

process vip_report {
  input:
    path(vcf)
  output:
    path(html)
  script:
    html="out.html"
    """
    ${CMD_VCFREPORT} java \
    -Djava.io.tmpdir=\"${TMPDIR}\" \
    -XX:ParallelGCThreads=2 \
    -jar /opt/vcf-report/lib/vcf-report.jar \
    --input "${vcf}" \
    --output "${html}"
    """
}

def validateInput() {
  if( !params.containsKey('input') )   exit 1, "missing required parameter 'input'"
  if( !file(params.input).exists() )   exit 1, "parameter 'input' value '${params.input}' does not exist"
  if( !params.input.endsWith(".csv") ) exit 1, "parameter 'input' value '${params.input}' is not a .csv file"
}

def validateReference() {
  if( !params.containsKey('reference') )   exit 1, "missing required parameter 'reference'"
  if( !file(params.reference).exists() )   exit 1, "parameter 'reference' value '${params.reference}' does not exist"
  
  def referenceFai = params.reference + ".fai"
  if( !file(referenceFai).exists() )   exit 1, "parameter 'reference' value '${params.reference}' index '${referenceFai}' does not exist"

  def referenceGzi = params.reference + ".gzi"
  if( !file(referenceGzi).exists() )   exit 1, "parameter 'reference' value '${params.reference}' index '${referenceGzi}' does not exist"

  def referenceMmi = params.reference + ".mmi"
  if( !file(referenceMmi).exists() )   exit 1, "parameter 'reference' value '${params.reference}' index '${referenceMmi}' does not exist"
}

def validate() {
  validateInput()
  validateReference()
}

def parseSampleSheet(csvFile) {
  def lines = new File(csvFile).readLines("UTF-8")
  if (lines.size() == 0) exit 1, "error parsing '${csvFile}': file is empty"
  
  def header = lines[0]
  def headerTokens = header.split(',', -1)
  def cols = [:]
  headerTokens.eachWithIndex { it, index -> cols[it] = index }
  
  // validate header
  if (!cols.containsKey('family_id') ) exit 1, "error parsing '${csvFile}' line 1: missing column 'family_id' in '${header}'"
  if (!cols.containsKey('individual_id') ) exit 1, "error parsing '${csvFile}' line 1: missing column 'individual_id' in '${header}'"
  if (!cols.containsKey('paternal_id') ) exit 1, "error parsing '${csvFile}' line 1: missing column 'paternal_id' in '${header}'"
  if (!cols.containsKey('maternal_id') ) exit 1, "error parsing '${csvFile}' line 1: missing column 'maternal_id' in '${header}'"
  if (!cols.containsKey('proband') ) exit 1, "error parsing '${csvFile}' line 1: missing column 'proband' in '${header}'"
  if (!cols.containsKey('fastq_r1') ) exit 1, "error parsing '${csvFile}' line 1: missing column 'fastq_r1' in '${header}'"
  if (!cols.containsKey('fastq_r2') ) exit 1, "error parsing '${csvFile}' line 1: missing column 'fastq_r2' in '${header}'"

  // first pass: create family_id -> individual_id -> sample map
  def samples=[:]
  for (int i = 1; i < lines.size(); i++) {
    def lineNr = i + 1

    def line = lines[i]
    if (line == null) continue;
    
    def tokens = line.split(',', -1)
    if (tokens.length != headerTokens.length) exit 1, "error parsing '${csvFile}' line ${lineNr}: expected ${headerTokens.length} columns instead of ${tokens.length}"
    
    def familyId = tokens[cols["family_id"]]
    if (familyId.length() == 0 ) exit 1, "error parsing '${csvFile}' line ${lineNr}: 'family_id' cannot be empty"

    def individualId = tokens[cols["individual_id"]]
    if (individualId.length() == 0 ) exit 1, "error parsing '${csvFile}' line ${lineNr}: 'individual_id' cannot be empty"

    def paternalId = tokens[cols["paternal_id"]]
    if (paternalId.length() == 0 ) paternalId = null

    def maternalId = tokens[cols["maternal_id"]]
    if (maternalId.length() == 0 ) maternalId = null
    
    if (paternalId != null && maternalId != null && paternalId == maternalId) exit 1, "error parsing '${csvFile}' line ${lineNr}: 'paternal_id' and 'maternal_id' cannot be equal"

    def proband = tokens[cols["proband"]]
    if (proband.length() == 0 || proband == "false") proband=false
    else if(proband == "true") proband=true
    else exit 1, "error parsing '${csvFile}' line ${lineNr}: invalid 'proband' value '${proband}'. valid values are 'true', 'false' or empty"

    def fastqR1 = tokens[cols["fastq_r1"]]
    if (fastqR1.length() == 0 ) exit 1, "error parsing '${csvFile}' line ${lineNr}: 'fastq_r1' cannot be empty"
    fastqR1=file(fastqR1)
    if (!fastqR1.exists()) exit 1, "error parsing '${csvFile}' line ${lineNr}: 'fastq_r1' '${fastqR1}' does not exist"
    if (!fastqR1.isFile()) exit 1, "error parsing '${csvFile}' line ${lineNr}: 'fastq_r1' '${fastqR1}' is not a file"

    def fastqR2 = tokens[cols["fastq_r2"]]
    if (fastqR2.length() == 0 ) exit 1, "error parsing '${csvFile}' line ${lineNr}: 'fastq_r2' cannot be empty"
    fastqR2=file(fastqR2)
    if (!fastqR2.exists()) exit 1, "error parsing '${csvFile}' line ${lineNr}: 'fastq_r2' '${fastqR2}' does not exist"
    if (!fastqR2.isFile()) exit 1, "error parsing '${csvFile}' line ${lineNr}: 'fastq_r2' '${fastqR2}' is not a file"

    def cram = tokens[cols["cram"]]
    def cramIndex
    if (cram.length() ==  0) {
      cram = null
      cramIndex = null
    }
    else {
      cram=file(cram)
      if (!cram.exists()) exit 1, "error parsing '${csvFile}' line ${lineNr}: 'cram' '${cram}' does not exist"
      if (!cram.isFile()) exit 1, "error parsing '${csvFile}' line ${lineNr}: 'cram' '${cram}' is not a file"
      
      cramIndex = file(cram + ".crai")
      if (!cramIndex.exists()) exit 1, "error parsing '${csvFile}' line ${lineNr}: 'cram' '${cramIndex}' does not exist"
      if (!cramIndex.isFile()) exit 1, "error parsing '${csvFile}' line ${lineNr}: 'cram' '${cramIndex}' is not a file"
    }

    def sample = [:]
    sample["sample_sheet_line"] = lineNr
    sample["family_id"] = familyId
    sample["individual_id"] = individualId
    sample["paternal_id"] = paternalId
    sample["maternal_id"] = maternalId
    sample["proband"] = proband
    sample["fastq_r1"] = fastqR1
    sample["fastq_r2"] = fastqR2
    sample["cram"] = cram
    sample["cram_index"] = cramIndex

    def family = samples[familyId]
    if (family == null) {
      family = [:]
      samples[familyId] = family
    }
    
    def individual = family[individualId]
    if (individual != null) exit 1, "error parsing '${csvFile}' line ${lineNr}: 'family_id/individual_id' '${familyId}/${individualId}' already exists on line ${individual.sample_sheet_line}"
    
    family[individualId] = sample
  }
  
  // second pass: validate paternal_id and maternal_id
  samples.each { familyEntry -> familyEntry.value.each { individualEntry ->
      def individual = individualEntry.value

      def paternalId = individual["paternal_id"]
      if (paternalId != null) {
        def father = familyEntry.value[paternalId]
        if (father == null) {
          System.err.println "warning parsing '${csvFile}' line ${individual.sample_sheet_line}: 'paternal_id' '${paternalId}' does not exist within the same family, ignoring..."
          individual["paternal_id"] = null
        }
      }

      def maternalId = individual["maternal_id"]
      if (maternalId != null) {
        def mother = familyEntry.value[maternalId]
        if (mother == null) {
          System.err.println "warning parsing '${csvFile}' line ${individual.sample_sheet_line}: 'maternal_id' '${maternalId}' does not exist within the same family, ignoring..."
          individual["maternal_id"] = null
        }
      }
      
      individual.remove("sample_sheet_line")
    }
  }  
  
  return samples
}

def parseContigs(faiFile) {
  def lines = new File(faiFile).readLines("UTF-8")
  if (lines.size() == 0) exit 1, "error parsing '${faiFile}': file is empty"

  def contigs = []
  for (int i = 0; i < lines.size(); i++) {
    def lineNr = i + 1

    def line = lines[i]
    if (line == null) continue;

    def tokens = line.split('\t', -1)
    if (tokens.length != 5) exit 1, "error parsing '${faiFile}' line ${lineNr}: expected 5 columns instead of ${tokens.length}"
    
    contigs+=tokens[0]
  }
  return contigs
}

def parseCramIndexStats(statsFile) {
  def lines = statsFile.readLines("UTF-8")
  if (lines.size() == 0) exit 1, "error parsing '${statsFile}': file is empty"

  def contigs = [:]
  for (int i = 0; i < lines.size(); i++) {
    def lineNr = i + 1

    def line = lines[i]
    if (line == null) continue;

    def tokens = line.split('\t', -1)
    if (tokens.length != 4) exit 1, "error parsing '${statsFile}' line ${lineNr}: expected 4 columns instead of ${tokens.length}"

    contigs[tokens[0]]=[length: tokens[1] as int, nrMappedReads: tokens[2] as int, nrUnmappedReads: tokens[3] as int]
  }
  return contigs
}

workflow {
  validate()

  def referenceFai = params.reference + ".fai"
  def referenceGzi = params.reference + ".gzi"
  def referenceMmi = params.reference + ".mmi"

  def sampleSheet = parseSampleSheet(params.input)
  // FIXME calculate from sample sheet
  def nrSamples = 8
  def contigs = parseContigs(referenceFai)
 
  sample_ch = Channel.from(sampleSheet.entrySet()) \
    | flatMap { it.value.values() }

  sample_ch \
    | branch {
        cram: it.cram != null
        fastq: true
      }
    | set { sample_branch_ch }

  sample_branch_ch.fastq \
    | map { tuple(it, params.reference, referenceFai, referenceGzi, referenceMmi) }
    | fastq_to_cram
    | map { tuple ->
        def sample = tuple[0].clone()
        sample.cram=tuple[1]
        sample.cram_index=tuple[2]
        sample
      }
    | set { sample_fastq_ch }

  sample_cram_ch = sample_branch_ch.cram.mix(sample_fastq_ch)

  sample_cram_ch \
    | map { sample -> tuple(groupKey(sample.family_id, sampleSheet[sample.family_id].size()), sample) }
    | groupTuple
    | map { group -> group[1] }
    | set { family_cram_ch }
  
  family_cram_ch
    | flatMap { samples ->
        def family = [:]
        samples.each { sample -> family[sample.individual_id] = sample }
        samples.collect { sample -> 
          def sampleWithFamily = sample.clone()
          sampleWithFamily.family = family
          sampleWithFamily
        }
      }
    | filter { sample -> sample.proband}
    | set { proband_cram_ch }
  
  proband_cram_ch
    | map { sample -> tuple(sample, sample.cram, sample.cram_index) }
    | cram_stats
    | flatMap { sample, statsFile ->
        def stats = parseCramIndexStats(statsFile)
        // FIXME remove (contig == "chr21" || contig == "chr22")
        def contigsWithReads = contigs.findAll( contig -> { (contig == "chr21" || contig == "chr22") && (stats[contig].nrMappedReads + stats[contig].nrUnmappedReads > 0) } )
        contigsWithReads.collect{ contig -> 
          def samplePerContig = sample.clone()
          samplePerContig.contig = contig
          samplePerContig.nr_contigs = contigsWithReads.size()
          samplePerContig
        }
      }
    | set {proband_cram_region_ch }

  // TODO deeptrio for duos
  proband_cram_region_ch
    | branch { sample ->
        trio: sample.paternal_id != null && sample.maternal_id != null
        duoFather: sample.paternal_id != null && sample.maternal_id == null
        duoMother: sample.paternal_id == null && sample.maternal_id != null
        other: true
      }
    | set { proband_cram_region_branch_ch } 
  
  proband_cram_region_branch_ch.trio
    | map { sample -> 
        tuple(
          sample,
          params.reference, referenceFai, referenceGzi,
          sample.cram, sample.cram_index,
          sample.family[sample.paternal_id].cram, sample.family[sample.paternal_id].cram_index,
          sample.family[sample.maternal_id].cram, sample.family[sample.maternal_id].cram_index
        )
      }
    | deeptrio
    | map { tuple ->
        def sample = tuple[0].clone()
        sample.g_vcf=tuple[1]
        sample.family=sample.family.clone()
        sample.family[sample.paternal_id].g_vcf=tuple[2]
        sample.family[sample.maternal_id].g_vcf=tuple[3]
        sample
      }
    | set { proband_gvcf_region_trio_ch }

  proband_cram_region_branch_ch.duoFather
    | map { sample -> 
        tuple(
          sample,
          params.reference, referenceFai, referenceGzi,
          sample.cram, sample.cram_index,
          sample.family[sample.paternal_id].cram, sample.family[sample.paternal_id].cram_index
        )
      }
    | deeptrio_father
    | map { tuple ->
        def sample = tuple[0].clone()
        sample.g_vcf=tuple[1]
        sample.family=sample.family.clone()
        sample.family[sample.paternal_id].g_vcf=tuple[2]
        sample
      }
    | set { proband_gvcf_region_duo_father_ch }

proband_cram_region_branch_ch.duoMother
    | map { sample -> 
        tuple(
          sample,
          params.reference, referenceFai, referenceGzi,
          sample.cram, sample.cram_index,
          sample.family[sample.maternal_id].cram, sample.family[sample.maternal_id].cram_index
        )
      }
    | deeptrio_mother
    | map { tuple ->
        def sample = tuple[0].clone()
        sample.g_vcf=tuple[1]
        sample.family=sample.family.clone()
        sample.family[sample.maternal_id].g_vcf=tuple[2]
        sample
      }
    | set { proband_gvcf_region_duo_mother_ch }

  proband_cram_region_branch_ch.other \
    | map { sample -> 
        tuple(
          sample,
          params.reference, referenceFai, referenceGzi,
          sample.cram, sample.cram_index
        )
      }
    | deepvariant
    | map { tuple ->
        def sample = tuple[0].clone()
        sample.g_vcf=tuple[1]
        sample
      }
    | set { proband_gvcf_region_other_ch }

  proband_gvcf_region_ch = proband_gvcf_region_trio_ch.mix(proband_gvcf_region_other_ch, proband_gvcf_region_duo_father_ch, proband_gvcf_region_duo_mother_ch)

  // FIXME move father.contig etc. to proband_cram_ch 
  proband_gvcf_region_ch
    | flatMap { sample -> 
        def samples = []
        samples << sample
        
        def father = sample.family[sample.paternal_id]
        if(father) {
          father = father.clone()
          father.contig = sample.contig
          father.nr_contigs = sample.nr_contigs
          samples << father
        }
        
        def mother = sample.family[sample.maternal_id]
        if(mother) {
          mother = mother.clone()
          mother.contig = sample.contig
          mother.nr_contigs = sample.nr_contigs
          samples << mother
        }
        samples
      }
    | set { sample_gvcf_region_ch }
  
  sample_gvcf_region_ch
    | map { sample -> tuple(groupKey(sample.contig, nrSamples), sample) }
    | groupTuple
    | map { group -> tuple([contig: group[0], samples: group[1]], group[1].collect(sample -> sample.g_vcf)) }
    | glnexus
    | map { tuple ->
        def contigSamples = tuple[0].clone()
        contigSamples.bcf=tuple[1]
        contigSamples
      }
    | set { bcf_region_ch }

  // TODO report probands
  // TODO report pedigree
  // TODO report reference
  // TODO report crams
  // TODO report genes
  // TODO report phenotypes from sample sheet
  bcf_region_ch 
    | toSortedList { thisContigSamples, thatContigSamples -> 
        contigs.findIndexOf{ it == thatContigSamples.contig } <=> contigs.findIndexOf{ it == thisContigSamples.contig }
      }
    | map { contigSamples -> contigSamples.collect{ it.bcf } }
    | bcftools_concat
    | vip_report

  // TODO start from gvcf
  // TODO start from vcf
  // TODO publish result
  // TODO publish intermediate results
}
