"""Parse output of softwares in pipeline."""

from .phenotype import (
    parse_resfinder_amr_pred,
    parse_amrfinder_amr_pred,
    parse_virulencefinder_vir_pred,
    parse_amrfinder_vir_pred,
)
from .qc import parse_quast_results
from .species import parse_kraken_result
from .typing import parse_cgmlst_results, parse_mlst_results
