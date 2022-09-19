pipeline {
   agent any
    stages {



        stage('prepare') {
              steps {
                echo 'Hello Worldi from submodel **********'
                sh """ 
                     ls  -l
                     """
               }
        }


        stage('Build') {
             steps {
               echo 'Hello Worldi from submodel **********'
                sh """ 
                     cd devops
                      mvn  clean package
                          """
                  }
        }




}


}

