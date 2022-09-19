
node {
      stage ("inits") {

        sh """
           echo "init ----------"
           """
         checkout scm
        }

    try {

     load  'pipelines/pipeline.groovy'

     } finally  {
            cleanWs()
        }


}

