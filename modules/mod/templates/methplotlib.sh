#!/bin/bash
set -euo pipefail

setup_env() {
  # Setting up python environment
  module load Python
  source ${PYTHON_ENV_ACTIVATE}
}

methplotlib() {
	methplotlib -m !{bed} -n !{name} -w !{region} --static !{png} 
}

deactivate_env() {
	deactivate
}

main() {
  setup_env    
  methplotlib
  deactivate_env

}

main "$@"