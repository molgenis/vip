#!/bin/bash
set -euo pipefail

mod_basecaller() {
  ${CMD_DORADO} basecaller !{params.dorado_model} !{in} --modified-bases 5mCG_5hmCG --reference !{params.reference_g1k_v37} > !{params.run}.bam
}

basecaller() {
	${CMD_DORADO} basecaller !{params.dorado_model} !{in} --reference !{params.reference_g1k_v37} > !{params.run}.bam
}

main() {
  mod_basecaller    
}

main "$@"