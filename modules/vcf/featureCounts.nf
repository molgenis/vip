process featureCounts {
    input:
        tuple val(bamFiles), val(samples)
    output:
        tuple path("countMatrix.txt"), val(samples)
    script:
        """
        singularity exec --bind /groups/:/groups/ --bind /apps:/apps/ /groups/umcg-gdio/tmp01/umcg-rheins-kars/vip_branch/containers/featureCounts.sif \
        -a /apps/data/Ensembl/GrCh37.75/pub/release-75/gtf/homo_sapiens/Homo_sapiens.GRCh37.75.gtf -T $task.cpus -o countMatrix.txt ${bamFiles}
        """
}