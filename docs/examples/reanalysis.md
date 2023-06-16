# Reanalysis
The VCF workflow can be used to reanalyse data from previous runs with the pipeline.
It is possible to start from the normalize, annotate, classify, filter, inheritance, classify_samples, filter_samples steps, this can for example be usefull if you update one of your decision trees, or if you which to re-run the inheritance matching with a different set of low-penetrance genes.

For reanalysis the basics of running VIp remain the same, however the correct intermediate file should be provided as input in the sample sheet.
Several intermediate results are available in the "intermediates" subfolder of your output folder.
Furthermore the step form which you whish to start should be added in the configuration parameter "vcf.start"

For an example on how to reanalyze VIP data using a different classification tree see [here](https://github.com/molgenis/vip/blob/main/test/test_vcf.sh#L104).