#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "Usage: create_str_catalogs.sh -i <catalog.json> -o <output_basename> [-d]"
  echo
  echo "-i STRipy catalog.json (raw from GitLab)"
  echo "-o Output basename (produces <basename>.tsv, <basename>.stranger.json, <basename>.eh.json), please add the creation data to the output filenames"
  echo "-d Enable debug logging"
  exit 1
}

debug=0
log() {
  if [[ $debug -eq 1 ]]; then
    echo "$@" >&2
  fi
}

input=""
output=""
stranger_catalog=""
straglr_catalog=""
eh_catalog=""
first=1
eh_first=1
declare -A locus_motifs

parse_args() {
  while getopts ":i:o:hd" opt; do
    case "$opt" in
      i) input="$OPTARG" ;;
      o) output="$OPTARG" ;;
      d) debug=1 ;;
      h) usage ;;
      *) usage ;;
    esac
  done

  [[ -z "${input:-}" || -z "${output:-}" ]] && usage

  stranger_catalog="${output}.stranger.json"
  straglr_catalog="${output}.tsv"
  eh_catalog="${output}.eh.json"
}

init_outputs() {
  echo "Converting catalog from $input"
  : > "$stranger_catalog"
  : > "$straglr_catalog"
  : > "$eh_catalog"
  echo "[" >> "$stranger_catalog"
  first=1
  eh_first=1
}

build_locus_motif_map() {
  locus_motifs=()

  while read -r locus; do
    if [[ "$locus" == RFC1:* ]]; then
      base="RFC1"
      motif_part="${locus#RFC1:}"
      if [[ -n "${locus_motifs[$base]:-}" ]]; then
        locus_motifs[$base]+=",$motif_part"
      else
        locus_motifs[$base]="$motif_part"
      fi
    elif [[ "$locus" == *:* ]]; then
      base="${locus%%:*}"
      motif_part="${locus#*:}"
      locus_motifs[$base]="$motif_part"
    else
      locus_motifs[$locus]=""
    fi
  done < <(jq -r '.[].Locus' "$input")
}

write_straglr_line() {
  local locus="$1"
  local gene="$2"
  local motif="$3"
  local region="$4"

  local chr start end
  chr=$(echo "$region" | cut -d: -f1)
  start=$(echo "$region" | cut -d: -f2 | cut -d- -f1)
  end=$(echo "$region" | cut -d: -f2 | cut -d- -f2)

  echo -e "$chr\t$start\t$end\t-\t$gene\t$locus\t$motif" >> "$straglr_catalog"
}

append_eh_entry() {
  local locus="$1"
  local motif="$2"
  local region="$3"

  if [[ $eh_first -eq 1 ]]; then
    eh_first=0
    echo "[" >> "$eh_catalog"
  else
    echo "," >> "$eh_catalog"
  fi

  cat >> "$eh_catalog" <<EOF
{
  "VariantType": "Repeat",
  "LocusId": "$locus",
  "LocusStructure": "(${motif})*",
  "ReferenceRegion": "$region"
}
EOF
}

append_stranger_disease_entries() {
  local json="$1"
  local locus="$2"
  local motif="$3"
  local region="$4"

  while read -r disease; do
    disease_name=$(echo "$disease" | jq -r '.value.DiseaseName // empty')
    normalmax=$(echo "$disease" | jq -r '.value.NormalRange.Max // empty')
    pathmin=$(echo "$disease" | jq -r '.value.PathogenicCutoff // empty')

    if [[ -z "$normalmax" || -z "$pathmin" ]]; then
      echo "Error: missing required value: normalmax='$normalmax', pathmin='$pathmin'" >&2
      exit 1
    fi

    disease_name=${disease_name// /_}
    log "  Disease: $disease_name normalmax=$normalmax pathmin=$pathmin"

    if [[ $first -eq 1 ]]; then
      first=0
    else
      echo "," >> "$stranger_catalog"
    fi

    cat >> "$stranger_catalog" <<EOF
{
  "VariantType": "Repeat",
  "LocusId": "$locus",
  "LocusStructure": "(${motif})*",
  "ReferenceRegion": "$region",
  "Disease": "$disease_name",
  "NormalMax": $normalmax,
  "PathologicMin": $pathmin
}
EOF
  done < <(echo "$json" | jq -c '.Diseases | to_entries[]')
}

process_non_rfc1_loci() {
  for locus in "${!locus_motifs[@]}"; do
    motifs="${locus_motifs[$locus]}"

    log "Fetching locus from STRipy API: $locus"
    data=$(curl -s "https://api.stripy.org/locus/$locus")

    region=$(echo "$data" | jq -r '.LocationCoordinates.hg38 // empty')
    motif_api=$(echo "$data" | jq -r '.Motif // empty')
    gene=$(echo "$data" | jq -r '.Gene // empty')

    if [[ -n "$motifs" ]]; then
      motif="$motifs"
    else
      motif="$motif_api"
    fi

    log "Processing locus: $locus (gene: $gene, motif: $motif, region: $region)"

    if [[ -z "$region" || -z "$motif" || -z "$gene" ]]; then
      echo "Error: missing required value: region='$region', motif='$motif', gene='$gene'" >&2
      exit 1
    fi

    write_straglr_line "$locus" "$gene" "$motif" "$region"

    if [[ "$locus" != "RFC1" ]]; then
      append_eh_entry "$locus" "$motif" "$region"
    fi

    append_stranger_disease_entries "$data" "$locus" "$motif" "$region"
  done
}

process_rfc1_special() {
  local rfc_base="RFC1"

  log "Fetching base RFC1 from STRipy API: $rfc_base"
  rfc_data_base=$(curl -s "https://api.stripy.org/locus/$rfc_base")
  rfc_region=$(echo "$rfc_data_base" | jq -r '.LocationCoordinates.hg38 // empty')
  rfc_gene=$(echo "$rfc_data_base" | jq -r '.Gene // empty')

  if [[ -z "$rfc_region" || -z "$rfc_gene" ]]; then
    echo "Error: missing RFC1 base value: region='$rfc_region', gene='$rfc_gene'" >&2
    exit 1
  fi

  while read -r rfc_locus; do
    log "Adding original RFC1 entry to stranger and EH: $rfc_locus"

    rfc_motif=$(jq -r --arg locus "$rfc_locus" '
      .[] | select(.Locus == $locus) | .MotifPlusStrand // empty
    ' "$input")

    if [[ -z "$rfc_motif" ]]; then
      echo "Error: missing RFC1 motif for $rfc_locus" >&2
      exit 1
    fi

    rfc_data="$rfc_data_base"

    append_stranger_disease_entries "$rfc_data" "$rfc_locus" "$rfc_motif" "$rfc_region"
    append_eh_entry "$rfc_locus" "$rfc_motif" "$rfc_region"
  done < <(jq -r '.[].Locus | select(startswith("RFC1:"))' "$input")
}

finalize_outputs() {
  echo "]" >> "$stranger_catalog"
  if [[ $eh_first -eq 0 ]]; then
    echo "]" >> "$eh_catalog"
  fi
  echo "Done"
}

main() {
  parse_args "$@"
  init_outputs
  build_locus_motif_map
  process_non_rfc1_loci
  process_rfc1_special
  finalize_outputs
}

main "$@"
