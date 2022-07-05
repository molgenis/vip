nextflow.enable.dsl=2

include { validate } from './modules/validate'
include { nr_records; split_determine; split; sort; merge } from './modules/utils'
include { prepare } from './modules/prepare'
include { preprocess; preprocess_publish } from './modules/preprocess'
include { annotate; annotate_publish } from './modules/annotate'
include { classify; classify_publish } from './modules/classify'
include { filter; filter_publish } from './modules/filter'
include { inheritance; inheritance_publish } from './modules/inheritance'
include { classify_samples; classify_samples_publish } from './modules/classify_samples'
include { filter_samples; filter_samples_publish } from './modules/filter_samples'
include { report } from './modules/report'

workflow {
  validate()

  channel.fromPath(params.input) \
      | prepare \
      | branch {
          small: nr_records(it.last()) <= params.chunk_size
          large: true
        }
      | set { inputs }

  // split large files
  inputs.small \
      | map { tuple -> new Tuple(tuple[0], 0, tuple[1]) }
      | set { inputs_files }

  inputs.large \
      | flatMap { tuple -> split_determine(tuple) } \
      | split
      | set { inputs_chunks }

  inputs_files.mix(inputs_chunks) \
      | branch {
          take: params.start <= 0
          skip: true
        }
      | set { preprocess_ch }

  // stage #0: preprocessing
  preprocess_ch.take \
      | preprocess
      | multiMap { it -> done: publish: it }
      | set { preprocessed_ch }

  preprocessed_ch.done.mix(preprocess_ch.skip) \
      | branch {
          take: params.start <= 1
          skip: true
        }
      | set { annotate_ch }

  preprocessed_ch.publish \
      | groupTuple \
      | map { it -> sort(it) } \
      | preprocess_publish

  // stage #1: annotation
  annotate_ch.take \
      | annotate
      | multiMap { it -> done: publish: it }
      | set { annotated_ch }

  annotated_ch.done.mix(annotate_ch.skip) \
      | branch {
          take: params.start <= 2
          skip: true
        }
      | set { classify_ch }

  annotated_ch.publish \
      | groupTuple \
      | map { it -> sort(it) } \
      | annotate_publish

  // stage #2: classification
  classify_ch.take \
      | classify
      | multiMap { it -> done: publish: it }
      | set { classified_ch }

  classified_ch.done.mix(classify_ch.skip) \
      | branch {
          take: params.start <= 3
          skip: true
        }
      | set { filter_ch }

  classified_ch.publish \
      | groupTuple \
      | map { it -> sort(it) } \
      | classify_publish

  // stage #3: filtering
  filter_ch.take \
      | filter
      | multiMap { it -> done: publish: it }
      | set { filtered_ch }

  filtered_ch.done.mix(filter_ch.skip) \
      | branch {
          take: params.start <= 4 && params.pedigree != ""
          skip: true
        }
      | set { inheritance_ch }

  filtered_ch.publish \
      | groupTuple \
      | map { it -> sort(it) } \
      | filter_publish

  // stage #4: inheritance matching
  inheritance_ch.take \
      | inheritance
      | set { inheritanced_ch }

  inheritanced_ch.mix(inheritance_ch.skip) \
        | branch {
            take: params.start <= 5 && params.pedigree != "" && params.filter_inheritance == true
            skip: true
          }
      | set { classify_samples_ch }

  // stage #5: classification
  classify_samples_ch.take \
      | classify_samples
      | multiMap { it -> done: publish: it }
      | set { classified_samples_ch }

  classified_samples_ch.done.mix(classify_samples_ch.skip) \
      | branch {
          take: params.start <= 6
          skip: true
        }
      | set { filter_samples_ch }

  // stage #6: filtering
  filter_samples_ch.take \
      | filter
      | multiMap { it -> done: publish: it }
      | set { filtered_samples_ch }

  filtered_samples_ch.done.mix(filter_samples_ch.skip) \
      | branch {
          take: params.start <= 7 && params.filter_samples != true
          skip: true
        }
      | set { report_ch }

  filtered_ch.publish \
      | groupTuple \
      | map { it -> sort(it) } \
      | filter_samples_publish

  // stage #7: reporting
  report_ch \
    | groupTuple \
    | map { it -> sort(it) } \
    | branch {
        single: it[1].size() == 1
        chunks: true
      }
    | set { reported_ch }

  reported_ch.chunks \
      | merge
      | set { merged_ch }

  merged_ch.mix(reported_ch.single) \
    | report
}

workflow.onComplete {
    println "output: $params.output"
    println "done"
}

workflow.onError {
    println "Oops .. something when wrong"
}

