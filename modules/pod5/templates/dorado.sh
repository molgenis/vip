#!/bin/bash
set -euo pipefail

mod_basecaller() {
  # Command for Dorado tool
  echo "working"
  ${CMD_DORADO} basecaller !{params.dorado_model} ./ --modified-bases 5mCG_5hmCG --reference !{reference} > !{bam}
}

main() {
  mod_basecaller    
}

main "$@"