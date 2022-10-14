def validateMeta(meta, keys) {
    keys.each { key -> if(!meta.containsKey(key)) throw new IllegalArgumentException("""meta is missing required '${key}'""") }
    meta
}