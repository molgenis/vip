# Frequently asked questions

## Why doesn't my report contain any variants?
VIP filters your input variants using classification trees for variant-effect and variant-sample combinations.
Usually if your report doesn't contain any records this implies that they were filtered out based on these trees.   

Inspect the `_classifications.vcf.gz` files in the `intermediates` output folder to determine why a variant record was removed.  

The default VIP classification tree and class filter removes variants on the 'non-standard' contigs. For GRCh37 this implies [1-22,X,Y,MT]. The hg19 GRCh37 reference sequence uses different contigs identifiers which will result in filtering out of all records. In this case you should provide your own classification tree with the correct contig identifiers.

## Why does VIP fail with an `Unexpected Error [InvocationTargetException]`?
This issue can mean a number of things, check the `.nxf.log` for more details.
One of the causes is a mismatch between the reference genome that was used to call the variants in your .vcf file and the reference genome used by VIP.
For example:

- Your variants are called with a reference genome that differs from the default VIP reference genome
- Your variants are called with GRCh37 and you use the GRCh38 assembly or vice-versa
 
## Why does VIP fail with a file not found error but my file exists?
You might need to update `APPTAINER_BIND`, for more details see [here](../usage/config.md#environment). To understand the cause of this issue take a look at the [Apptainer documentation](https://apptainer.org/docs/user/main/bind_paths_and_mounts.html).

## Why does VIP fail with an exit code 137?
A process has run out of memory. See the [config](../usage/config.md#process) documentation on how to update resource assignments for some or all processes.
