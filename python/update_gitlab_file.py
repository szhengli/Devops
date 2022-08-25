import gitlab
import re

filepath = "guestbook/guestbook-ui-deployment.yaml"
gitlabPath = "https://gitlab.cnzhonglunnet.com/"
private_token = "DZpBz7syRtRhx5n_8Ccp"
imageTag = "2.0"


gb = gitlab.Gitlab(gitlabPath, private_token)
example = gb.projects.get(19)
yaml = example.files.get(filepath, "master").decode().decode()

newImage = "guestbook-ui:{}\n".format(imageTag)
commit_message = "change gustbook image tag to  " + newImage

yaml = re.sub("guestbook-ui:.*\n", newImage, yaml)

example.files.update(filepath, {"branch": "master",
                                "content": yaml,
                                "commit_message": commit_message
                                }
                     )



