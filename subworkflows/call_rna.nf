nextflow.enable.dsl=2

// validate before starting

def createCountString(bamData) {
    return bamData.join(',')
}


workflow rna {
    // get input, sample id:sample
    channel.fromPath( '/groups/umcg-gdio/tmp01/umcg-kmaassen/samples/rnaseq/blood/*.bam' ).collect() |
    set { inputs }

    inputs |
    createCountString |
    set {countString}
    // convert to count matrix

    // ### featurecounts process

    // run outrider

    // get output

    // run fraser

    // get output
}

