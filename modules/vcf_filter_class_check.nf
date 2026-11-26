//Collect all leaf node classes from the supplied decision tree
def getDecisionTreeClasses(decisionTreePath) {
  def decisionTree = new groovy.json.JsonSlurper().parse(file(decisionTreePath))
  def leafClasses = decisionTree.nodes
    .values()
    .findAll { it.type == "LEAF" }
    .collect { it.class }
  return leafClasses
}

//Collect the supplied vcf.filter.classes || vcf.filter_samples.classes from the config that are not in the decision tree
def checkSuppliedClasses(suppliedClasses, decisionTreeClasses) {
  if ( suppliedClasses.length() == 0 ) exit 1, "No filter classes supplied in config"
  
  def filterClasses = suppliedClasses.split(',', -1)
  
  //Check for every filter class if it is in the list of decision tree leaf classses
  def filterClassesNotInDecTree = filterClasses.findAll { !(it in decisionTreeClasses) }
  
  return filterClassesNotInDecTree;
}

//Check whether the filter classes are in the decision tree
def checkFilterClasses(decisionTreePath, filterClasses) {
  def decisionTreeClasses = getDecisionTreeClasses(decisionTreePath)
  def invalidFilterClasses = checkSuppliedClasses(filterClasses, decisionTreeClasses)
  if (invalidFilterClasses.size() > 0) exit 1, "Filter classes '${invalidFilterClasses.join(',')}' are not in the supplied decision tree"
}