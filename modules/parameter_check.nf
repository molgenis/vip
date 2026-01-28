//Reads a configuration file and returns only its parameter section
def readConfigParams(String filePath) {
    def defaultConfig = nextflow.config.ConfigParserFactory.create().parse( new File(filePath).toURI().toURL() );
    HashMap<String, Object> defaultParams = defaultConfig.get("params");
    return defaultParams;
}


//Adds the VIP CLI options as these are also some (such as input and output) in the default params object.
def addCliParameters(Map<String, Object> paramsMap) {
    //paramsMap.put("workflow", "workflowToRun");
    paramsMap.put("input", "path/to/samplesheet");
    paramsMap.put("output", "path/to/outputdir");
    //paramsMap.put("config", "path/to/config");
    //paramsMap.put("profile", "profileToRunWith");
    //paramsMap.put("resume", "toResumePreviousWorkflow");
    return paramsMap;
}


//Method that asserts that all supplied parameters are valid.
def assertAllKeysExist(
            Map<String, Object> source,
            Map<String, Object> target,
            String path
    ) {
        for (Map.Entry<String, Object> entry : source.entrySet()) {
            String key = entry.getKey();
            Object sourceValue = entry.getValue();
            String currentPath = path.isEmpty() ? key : path + "." + key;

            if (!target.containsKey(key)) {
                throw new IllegalArgumentException(
                        "Invalid parameter: " + currentPath
                );
            }

            Object targetValue = target.get(key);

            if (sourceValue instanceof Map) {
                if (!(targetValue instanceof Map)) {
                    throw new IllegalArgumentException(
                            "Expected block at parameter: " + currentPath
                    );
                }

                assertAllKeysExist(
                        (Map<String, Object>) sourceValue,
                        (Map<String, Object>) targetValue,
                        currentPath
                );
            }
        }
    }


def mergeMaps(
        Map<String, Object> target,
        Map<String, Object> source) {

    source.forEach((key, value) -> {
        if (!target.containsKey(key)) {
            target.put(key, value);
            return;
        }

        Object existing = target.get(key);

        // Both values are maps → recurse
        if (existing instanceof Map && value instanceof Map) {
            mergeMaps(
                (Map<String, Object>) existing,
                (Map<String, Object>) value
            );
        } else {
            // Conflict resolution strategy
            target.put(key, value); // overwrite
        }
    });

    return target;
}