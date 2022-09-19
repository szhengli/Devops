        stage('Hello') {
                echo 'Hello Worldi from submodel **********'
                sh """ 
                     ls  -l
                     """
        }


        stage('Build') {
                echo 'Hello Worldi from submodel **********'
                sh """ 
                     cd devops
                      mvn  clean package
                     """
        }





:wq


