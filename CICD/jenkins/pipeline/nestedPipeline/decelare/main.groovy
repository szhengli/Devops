node {
     checkout scm
     try {
     load  'pipelines/dec_pipeline.groovy'

     } finally {
        cleanWs()

     }

}

