
def findCramIndex(cram) {
    def cram_index
    if(cram == null) cram_index = null
    else if(file(cram + ".crai").exists()) cram_index = cram + ".crai"
    else if(file(cram + ".bai").exists()) cram_index = cram + ".bai"
    cram_index
}