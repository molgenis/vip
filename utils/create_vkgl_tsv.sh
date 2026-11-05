#!/bin/bash

set -euo pipefail

SCRIPT_NAME="$(basename "$0")"

usage() {
  echo -e "usage: ${SCRIPT_NAME} -i <arg> -g <arg> -a <arg> -f <arg> -o <arg>

  -i, --input <arg>           Public or private consensus .csv file (flavour is detected from the header, downloaded from https://vkgl.molgeniscloud.org/VKGL/tables/#/Consensus / https://vkgl.molgeniscloud.org/Public/tables/#/PublicConsensus)
  -g, --gene2refseq <arg>     NCBI gene2refseq .gz file from https://ftp.ncbi.nlm.nih.gov/gene/DATA/
  -a, --assembly-report <arg> NCBI GRCh38 assembly report .txt (or .txt.gz) used to map RefSeq accessions to chromosomes, e.g.
                              https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/001/405/GCF_000001405.40_GRCh38.p14/GCF_000001405.40_GRCh38.p14_assembly_report.txt
  -f, --fasta <arg>           GRCh38 reference genome .fasta (or .fasta.gz) with .fai index. Variants for which the input contains 'too long' as ref or alt
                              allele are written as symbolic allele (<DEL>, <DUP> or <INS>), conform the VCF specification. The start is the position
                              from the input (posGRCh38), ref is the anchor nucleotide (the allele of the input that is not too long, otherwise it is
                              looked up in the fasta), and the hgvsGRCh38 g. notation is only used to determine the type and length of the variant:
                              stop (VCF END) is start + length for a deletion/duplication and start for an insertion. 'delins' variants are skipped.
  -o, --output <arg>          Consensus .tsv file for the VEP plugin with GRCh38 positions:
                              public:  'chromosome', 'start', 'ref', 'alt', 'gene_id_entrez_gene', 'classification', 'stop'
                              private: 'chromosome', 'start', 'ref', 'alt', 'gene_id_entrez_gene', 'amc', 'erasmus', 'lumc', 'nki', 'radboud_mumc', 'umcg', 'umcu', 'classification', 'stop'
                              stop is the last reference nucleotide of the variant (start + length of ref - 1, so equal to start for SNVs)
                              rows that cannot be processed are written to the '.err' file next to the output,
                              prefixed with the reason (NO_GRCH38_POSITION, NO_ENTREZ_GENE_ID, NO_LAB_CLASSIFICATION, UNKNOWN_CLASSIFICATION, UNKNOWN_LAB_CLASSIFICATION, UNKNOWN_CHROMOSOME,
                              TOO_LONG_DELINS, TOO_LONG_UNPARSABLE_HGVS, TOO_LONG_CONTIG_NOT_IN_FASTA, or TOO_LONG_FASTA_LOOKUP_FAILED)
                              classifications, including those of the separate labs, are mapped to B, LB, VUS, LP and P
                              the chromosome is looked up in the assembly report using the RefSeq accession in the hgvsGRCh38 column, e.g. NC_000008.11 -> 8
  -h, --help                  Print this message and exit"
}

# create a tab separated 'G', 'transcript (without version)', 'Entrez GeneID' mapping for human
create_mapping() {
  local -r gene2refseq="${1}"
  local -r mapping="${2}"

  zcat "${gene2refseq}" | awk -F'\t' '
    NR == 1 {
      # column names are matched case-insensitively (NCBI uses "RNA_nucleotide_accession.version")
      for (i = 1; i <= NF; i++) {
        h[tolower($i)] = i
      }
      n = split("#tax_id geneid rna_nucleotide_accession.version", req, " ")
      for (k = 1; k <= n; k++) {
        if (!(req[k] in h)) {
          print "missing column \"" req[k] "\" in gene2refseq header" > "/dev/stderr"
          exit 1
        }
      }
      next
    }
    $h["#tax_id"] == 9606 {
      tx = $h["rna_nucleotide_accession.version"]
      gene = $h["geneid"]
      if (tx != "-") {
        # NM_000546.6 -> NM_000546
        sub(/\.[0-9]+$/, "", tx)
        if (tx in map && map[tx] != gene) {
          print "WARNING: transcript maps to multiple GeneIDs:", tx, map[tx], gene > "/dev/stderr"
        }
        map[tx] = gene
      }
    }
    END {
      for (tx in map) {
        print "G\t" tx "\t" map[tx]
      }
    }' > "${mapping}"
}

# append a tab separated 'C', 'RefSeq accession (with version)', 'chromosome name' mapping from the NCBI assembly report
# and 'A', 'chromosome name', 'alias' lines (sequence name, RefSeq and GenBank accession) used to find the contig in the fasta
# only assembled molecules (chromosomes and mitochondrion) are included, not alternate, patch or unlocalized sequences
create_chromosome_mapping() {
  local -r assembly_report="${1}"
  local -r mapping="${2}"

  zcat -f "${assembly_report}" | awk -F'\t' '
    /^# Sequence-Name/ {
      line = $0
      sub(/\r$/, "", line)
      sub(/^# /, "", line)
      nf = split(line, f, "\t")
      for (i = 1; i <= nf; i++) {
        h[f[i]] = i
      }
      n = split("Sequence-Name Sequence-Role RefSeq-Accn UCSC-style-name", req, " ")
      for (k = 1; k <= n; k++) {
        if (!(req[k] in h)) {
          print "missing column \"" req[k] "\" in assembly report header" > "/dev/stderr"
          exit 1
        }
      }
      next
    }
    /^#/ {
      next
    }
    {
      if (!("Sequence-Role" in h)) {
        print "assembly report header not found" > "/dev/stderr"
        exit 1
      }
      line = $0
      sub(/\r$/, "", line)
      split(line, f, "\t")
      if (f[h["Sequence-Role"]] == "assembled-molecule" && f[h["RefSeq-Accn"]] != "na") {
        name = f[h["UCSC-style-name"]]
        print "C\t" f[h["RefSeq-Accn"]] "\t" name
        print "A\t" name "\t" f[h["Sequence-Name"]]
        print "A\t" name "\t" f[h["RefSeq-Accn"]]
        if (("GenBank-Accn" in h) && f[h["GenBank-Accn"]] != "na") {
          print "A\t" name "\t" f[h["GenBank-Accn"]]
        }
        found++
      }
    }
    END {
      if (found == 0) {
        print "no chromosomes found in assembly report" > "/dev/stderr"
        exit 1
      }
    }' >> "${mapping}"
}

# append a tab separated 'F', 'contig name', 'contig length' line for every contig in the fasta index
create_fasta_mapping() {
  local -r fasta="${1}"
  local -r mapping="${2}"

  cut -f1,2 "${fasta}.fai" | awk -F'\t' '{ print "F\t" $1 "\t" $2 }' >> "${mapping}"
}

# convert the consensus .csv to the plugin .tsv, detecting public/private from the header
convert() {
  local -r input="${1}"
  local -r mapping="${2}"
  local -r fasta="${3}"
  local -r output="${4}"
  local -r err="${5}"

  gawk -v err="${err}" -v fasta="${fasta}" '
    BEGIN {
      FPAT = "([^,]*)|(\"([^\"]|\"\")*\")"
      OFS = "\t"

      # input column name -> output column name expected by the Perl plugin
      nlabs = 7
      src[1] = "aumc";        dst[1] = "amc"
      src[2] = "erasmusmc";   dst[2] = "erasmus"
      src[3] = "lumc";        dst[3] = "lumc"
      src[4] = "nki";         dst[4] = "nki"
      src[5] = "radboudmumc"; dst[5] = "radboud_mumc"
      src[6] = "umcg";        dst[6] = "umcg"
      src[7] = "umcu";        dst[7] = "umcu"

      # classification (lowercase, "_" and "-" replaced by a space) -> abbreviation
      cls["benign"] = "B"
      cls["likely benign"] = "LB"
      cls["vus"] = "VUS"
      cls["uncertain significance"] = "VUS"
      cls["variant of uncertain significance"] = "VUS"
      cls["likely pathogenic"] = "LP"
      cls["pathogenic"] = "P"
      cls["(likely) benign"] = "LB"
      cls["(likely) pathogenic"] = "LP"
    }

    # returns B, LB, VUS, LP or P, or an empty string if the classification is unknown
    function map_classification(s) {
      s = tolower(s)
      gsub(/[_-]/, " ", s)
      gsub(/^ +| +$/, "", s)
      return (s in cls) ? cls[s] : ""
    }

    function clean(s) {
      if (s ~ /^".*"$/) {
        s = substr(s, 2, length(s) - 2)
        gsub(/""/, "\"", s)
      }
      gsub(/[\t\r\n]/, " ", s)
      return s
    }

    # returns the name of the contig in the fasta that belongs to the chromosome (UCSC style name),
    # tries the chromosome name itself, followed by the sequence name, RefSeq and GenBank accession
    function fasta_contig(chr,   n, cands, i, res) {
      if (chr in contig_cache) return contig_cache[chr]
      res = ""
      if (chr in fcontig) {
        res = chr
      } else {
        n = split(alias[chr], cands, "\t")
        for (i = 1; i <= n; i++) {
          if (cands[i] != "" && cands[i] in fcontig) {
            res = cands[i]
            break
          }
        }
      }
      contig_cache[chr] = res
      return res
    }

    # returns the (uppercase) fasta sequence of contig:a-b (1-based, inclusive) or an empty string on failure
    function fetch(contig, a, b,   cmd, line, seq) {
      if (a < 1 || b < a) return ""
      cmd = "samtools faidx \"" fasta "\" \"" contig ":" a "-" b "\" 2> /dev/null"
      seq = ""
      while ((cmd | getline line) > 0) {
        if (line !~ /^>/) seq = seq line
      }
      close(cmd)
      seq = toupper(seq)
      if (length(seq) != b - a + 1) return ""
      return seq
    }

    # derives the symbolic allele and END of a variant with too long alleles. The start is the position from the input (VCF style,
    # posGRCh38), the hgvs g. notation is only used to determine the type and the length of the variant:
    #   deletion      g.s_edel        ALT=<DEL>  END=start+(e-s+1)
    #   duplication   g.s_edup        ALT=<DUP>  END=start+(e-s+1)
    #   insertion     g.s_(s+1)ins..  ALT=<INS>  END=start
    # REF is the anchor nucleotide: the (single nucleotide) allele of the input that is not too long, otherwise taken from the fasta.
    # sets the globals l_pos, l_ref, l_alt and l_end
    # returns an empty string on success, otherwise the reason why the variant cannot be processed
    function resolve_too_long(hgvs, chr, pos, ref, alt,   i, d, m, type, s, e, rest, short, anchor, contig) {
      i = index(hgvs, ":")
      if (i == 0) return "TOO_LONG_UNPARSABLE_HGVS"
      d = substr(hgvs, i + 1)
      if (d !~ /^[gm]\./) return "TOO_LONG_UNPARSABLE_HGVS"
      d = toupper(substr(d, 3))

      if (d ~ /DELINS/) {
        return "TOO_LONG_DELINS"
      } else if (match(d, /^([0-9]+)(_([0-9]+))?DEL(.*)$/, m)) {
        type = "del"; s = m[1]; e = (m[3] == "") ? s : m[3]; rest = m[4]
      } else if (match(d, /^([0-9]+)(_([0-9]+))?DUP(.*)$/, m)) {
        type = "dup"; s = m[1]; e = (m[3] == "") ? s : m[3]; rest = m[4]
      } else if (match(d, /^([0-9]+)_([0-9]+)INS(.+)$/, m)) {
        type = "ins"; s = m[1]; e = m[2]; rest = ""
        if (e + 0 != s + 1) return "TOO_LONG_UNPARSABLE_HGVS"
      } else {
        return "TOO_LONG_UNPARSABLE_HGVS"
      }
      s = s + 0
      e = e + 0
      if (e < s) return "TOO_LONG_UNPARSABLE_HGVS"

      # a sequence or length after del/dup is not used, but it has to look like one
      if (rest != "" && rest !~ /^[ACGTN]+$/ && rest !~ /^[ACGTN]*[\(\[]/) return "TOO_LONG_UNPARSABLE_HGVS"

      # anchor nucleotide: the allele that is not too long, e.g. alt T for a deletion and ref T for a duplication or insertion
      short = toupper((tolower(ref) ~ /too long/) ? alt : ref)
      if (short ~ /^[ACGTN]$/) {
        anchor = short
      } else {
        contig = fasta_contig(chr)
        if (contig == "") return "TOO_LONG_CONTIG_NOT_IN_FASTA"
        anchor = fetch(contig, pos, pos)
        if (anchor == "") return "TOO_LONG_FASTA_LOOKUP_FAILED"
      }

      l_pos = pos
      l_ref = anchor
      l_alt = "<" toupper(type) ">"
      l_end = (type == "ins") ? pos + 0 : pos + (e - s + 1)
      return ""
    }

    # mapping: transcript -> GeneID ('G'), RefSeq accession -> chromosome ('C'), chromosome -> fasta contig aliases ('A'),
    # contigs in the fasta ('F') (tab separated, so bypass FPAT)
    NR == FNR {
      split($0, a, "\t")
      if (a[1] == "G") {
        geneid[a[2]] = a[3]
      } else if (a[1] == "C") {
        chromosome[a[2]] = a[3]
      } else if (a[1] == "A") {
        alias[a[2]] = alias[a[2]] "\t" a[3]
      } else if (a[1] == "F") {
        fcontig[a[2]] = a[3]
      }
      next
    }

    FNR == 1 {
      raw = $0
      sub(/\r$/, "", raw)
      print "reason" OFS raw > err

      for (i = 1; i <= NF; i++) {
        col[clean($i)] = i
      }

      n = split("hgvsGRCh38 posGRCh38 refGRCh38 altGRCh38 transcript consensusClassification", req, " ")
      for (k = 1; k <= n; k++) {
        if (!(req[k] in col)) {
          print "missing column \"" req[k] "\" in input header" > "/dev/stderr"
          exit 1
        }
      }

      # detect private / public
      present = 0
      for (k = 1; k <= nlabs; k++) {
        if (src[k] in col) present++
      }
      if (present == nlabs) {
        private = 1
      } else if (present == 0) {
        private = 0
      } else {
        print "only " present " of " nlabs " lab columns found in input header, cannot determine public/private" > "/dev/stderr"
        exit 1
      }
      print "detected " (private ? "private" : "public") " consensus input" > "/dev/stderr"

      line = "chromosome" OFS "start" OFS "ref" OFS "alt" OFS "gene_id_entrez_gene"
      if (private) {
        for (k = 1; k <= nlabs; k++) {
          line = line OFS dst[k]
        }
        print line OFS "classification" OFS "stop"
      } else {
        print line OFS "classification" OFS "stop"
      }
      next
    }

    {
      pos = clean($(col["posGRCh38"]))
      ref = clean($(col["refGRCh38"]))
      alt = clean($(col["altGRCh38"]))

      raw = $0
      sub(/\r$/, "", raw)

      too_long = (tolower(ref " " alt) ~ /too long/)

      if (pos == "" || pos == "-" || (too_long && pos !~ /^[0-9]+$/)) {
        print "NO_GRCH38_POSITION" OFS raw > err
        skipped++
        next
      }

      # chromosome: lookup of the RefSeq accession of the GRCh38 HGVS (e.g. NC_000008.11:g.41933350C>T) in the assembly report
      hgvs = clean($(col["hgvsGRCh38"]))
      accession = hgvs
      sub(/:.*$/, "", accession)
      chr = (accession in chromosome) ? chromosome[accession] : ""
      if (chr == "") {
        print "UNKNOWN_CHROMOSOME" OFS raw > err
        nochr++
        next
      }

      # stop: last reference nucleotide of the variant (equal to start for SNVs), too long alleles: derive start, ref, symbolic alt and stop (END) from the hgvs g. notation and the fasta
      stoppos = (pos ~ /^[0-9]+$/) ? pos + length(ref) - 1 : ""
      if (too_long) {
        reason = resolve_too_long(hgvs, chr, pos, ref, alt)
        if (reason != "") {
          print reason OFS raw > err
          toolong_skipped[reason]++
          notoolong++
          next
        }
        pos = l_pos
        ref = l_ref
        alt = l_alt
        stoppos = l_end
        toolong_resolved++
      }

      tx = clean($(col["transcript"]))
      sub(/\.[0-9]+$/, "", tx)
      entrez = (tx in geneid) ? geneid[tx] : ""
      if (entrez == "") {
        print "NO_ENTREZ_GENE_ID" OFS raw > err
        noentrez++
        next
      }

      consensus = clean($(col["consensusClassification"]))

      if (!private) {
        final = map_classification(consensus)
        if (final == "") {
          print "UNKNOWN_CLASSIFICATION" OFS raw > err
          unknown[consensus]++
          nounknown++
          next
        }
        print chr, pos, ref, alt, entrez, final, stoppos
        written++
        next
      }

      # private: lab classifications + final classification
      labline = ""
      badlab = ""
      found = 0
      single = ""
      for (k = 1; k <= nlabs; k++) {
        v = clean($(col[src[k]]))
        m = map_classification(v)
        if (v != "" && m == "") {
          badlab = src[k] ": " v
          break
        }
        labline = labline OFS m
        if (v != "") {
          found++
          single = v
        }
      }

      if (badlab != "") {
        print "UNKNOWN_LAB_CLASSIFICATION" OFS raw > err
        unknown[badlab]++
        nobadlab++
        next
      }

      if (tolower(consensus) ~ /classified by one lab/) {
        if (found == 0) {
          print "NO_LAB_CLASSIFICATION" OFS raw > err
          nolab++
          next
        }
        final = single
        if (found > 1) {
          print "WARNING: more than one lab classified data row " FNR - 1 > "/dev/stderr"
        }
      } else {
        final = consensus
      }

      raw_final = final
      final = map_classification(final)
      if (final == "") {
        print "UNKNOWN_CLASSIFICATION" OFS raw > err
        unknown[raw_final]++
        nounknown++
        next
      }

      print chr, pos, ref, alt, entrez labline, final, stoppos
      written++
    }

    END {
      printf "rows written: %d, rows in .err file: %d (no GRCh38 position: %d, no Entrez GeneID: %d, no lab classification: %d, unknown classification: %d, unknown lab classification: %d, unknown chromosome: %d, too long: %d)\n", written, skipped + noentrez + nolab + nounknown + nobadlab + nochr + notoolong, skipped, noentrez, nolab, nounknown, nobadlab, nochr, notoolong > "/dev/stderr"
      printf "too long alleles resolved: %d, skipped: %d\n", toolong_resolved, notoolong > "/dev/stderr"
      for (r in toolong_skipped) {
        printf "  %s: %d rows\n", r, toolong_skipped[r] > "/dev/stderr"
      }
      for (u in unknown) {
        printf "  unknown classification \"%s\": %d rows\n", u, unknown[u] > "/dev/stderr"
      }
    }' "${mapping}" "${input}" > "${output}"
}

validate() {
  local -r input="${1}"
  local -r gene2refseq="${2}"
  local -r assembly_report="${3}"
  local -r fasta="${4}"
  local -r output="${5}"
  local -r err="${6}"

  if [[ -z "${input}" ]]; then
    echo -e "missing required -i, --input"
    usage
    exit 1
  fi

  if [[ ! -f "${input}" ]]; then
    echo -e "-i, --input '${input}' does not exist"
    exit 1
  fi

  if [[ "${input}" != *.csv ]]; then
    echo -e "-i, --input '${input}' is not a '.csv' file"
    exit 1
  fi

  if [[ -z "${gene2refseq}" ]]; then
    echo -e "missing required -g, --gene2refseq"
    usage
    exit 1
  fi

  if [[ ! -f "${gene2refseq}" ]]; then
    echo -e "-g, --gene2refseq '${gene2refseq}' does not exist"
    exit 1
  fi

  if [[ "${gene2refseq}" != *.gz ]]; then
    echo -e "-g, --gene2refseq '${gene2refseq}' is not a '.gz' file"
    exit 1
  fi

  if [[ -z "${assembly_report}" ]]; then
    echo -e "missing required -a, --assembly-report"
    usage
    exit 1
  fi

  if [[ ! -f "${assembly_report}" ]]; then
    echo -e "-a, --assembly-report '${assembly_report}' does not exist"
    exit 1
  fi

  if [[ "${assembly_report}" != *.txt && "${assembly_report}" != *.txt.gz ]]; then
    echo -e "-a, --assembly-report '${assembly_report}' is not a '.txt' or '.txt.gz' file"
    exit 1
  fi

  if [[ -z "${fasta}" ]]; then
    echo -e "missing required -f, --fasta"
    usage
    exit 1
  fi

  if [[ ! -f "${fasta}" ]]; then
    echo -e "-f, --fasta '${fasta}' does not exist"
    exit 1
  fi

  if [[ "${fasta}" != *.fa && "${fasta}" != *.fasta && "${fasta}" != *.fna && "${fasta}" != *.fa.gz && "${fasta}" != *.fasta.gz && "${fasta}" != *.fna.gz ]]; then
    echo -e "-f, --fasta '${fasta}' is not a '.fa', '.fasta' or '.fna' file (optionally gzipped)"
    exit 1
  fi

  if [[ ! -f "${fasta}.fai" ]]; then
    echo -e "-f, --fasta index '${fasta}.fai' does not exist (possible solution: run 'samtools faidx ${fasta}')"
    exit 1
  fi

  if [[ -z "${output}" ]]; then
    echo -e "missing required -o, --output"
    usage
    exit 1
  fi

  if [[ "${output}" != *.tsv ]]; then
    echo -e "-o, --output '${output}' is not a '.tsv' file"
    exit 1
  fi

  if [[ -f "${output}" ]]; then
    echo -e "-o, --output '${output}' already exists"
    exit 1
  fi

  if [[ -f "${err}" ]]; then
    echo -e "error file '${err}' already exists"
    exit 1
  fi

  if ! command -v zcat &> /dev/null; then
    echo "command 'zcat' could not be found"
    exit 1
  fi

  if ! command -v gawk &> /dev/null; then
    echo "command 'gawk' could not be found (required for quote-aware csv parsing)"
    exit 1
  fi

  if ! command -v samtools &> /dev/null; then
    echo "command 'samtools' could not be found (run 'ml SAMtools' before executing this script)"
    exit 1
  fi
}

main() {
  local -r args=$(getopt -a -n pipeline -o i:g:a:f:o:h --long input:,gene2refseq:,assembly-report:,fasta:,output:,help -- "$@")
  # shellcheck disable=SC2181
  if [[ $? != 0 ]]; then
    usage
    exit 2
  fi

  local input=""
  local gene2refseq=""
  local assembly_report=""
  local fasta=""
  local output=""

  eval set -- "${args}"
  while :; do
    case "$1" in
      -h | --help)
        usage
        exit 0
        ;;
      -i | --input)
        input="$2"
        shift 2
        ;;
      -g | --gene2refseq)
        gene2refseq="$2"
        shift 2
        ;;
      -a | --assembly-report)
        assembly_report="$2"
        shift 2
        ;;
      -f | --fasta)
        fasta="$2"
        shift 2
        ;;
      -o | --output)
        output="$2"
        shift 2
        ;;
      --)
        shift
        break
        ;;
      *)
        usage
        exit 2
        ;;
    esac
  done

  if [[ -z "${output}" && -n "${input}" ]]; then
    output="${input%.csv}.tsv"
  fi

  local -r err="${output%.tsv}.err"

  validate "${input}" "${gene2refseq}" "${assembly_report}" "${fasta}" "${output}" "${err}"

  local mapping
  mapping="$(mktemp)"
  trap "rm -f '${mapping}'" EXIT

  create_mapping "${gene2refseq}" "${mapping}"
  create_chromosome_mapping "${assembly_report}" "${mapping}"
  create_fasta_mapping "${fasta}" "${mapping}"
  convert "${input}" "${mapping}" "${fasta}" "${output}" "${err}"
}

main "${@}"
