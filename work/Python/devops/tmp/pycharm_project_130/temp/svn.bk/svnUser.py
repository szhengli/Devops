import re
from xpinyin import Pinyin




passfile = "/data/svn/passwd.http"

def isValidUsername(username):
    with open(passfile, 'r') as file:
        # Check if the string is present in the content
        for line_num, content in enumerate(file, start=1):
            if username + ":" in content:
                print(line_num)
                return True
        return False

def getUsername(user):

    py = Pinyin()
    nlpy = py.get_pinyin(user, "_")
    nlpy2 = re.split('_', nlpy)

    nlFname, nlLname = nlpy2[0], nlpy2[1:]

    nlLnameAbb = ""

    for name in nlLname:
        if not name:
            nlLnameAbb = name[0]
        else:
            nlLnameAbb = nlLnameAbb + name[0]

    username1 = nlFname + nlLnameAbb
    username2 = nlFname[0] + nlLnameAbb
    username = py.get_pinyin(user, "")

    for user in [username, username1, username2]:
        if isValidUsername(user):
            return user
    return ""


#n2 = "印嘉伟"

#username = getUsername(n2)

#print(username)


