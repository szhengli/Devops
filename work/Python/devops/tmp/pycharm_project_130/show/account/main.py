import jira
import re
from jira import JIRA
from xpinyin import Pinyin
import  logging
from atlassian import Confluence
from python_freeipa import ClientMeta

JIRA_URL = 'https://jira.cnzhonglunnet.com'
JIRA_TOKEN = 'Njc4MDk3ODI5MDk3OifB5plRRwXNe3b7gqQV2EZcJnMz'



# <JIRA User: displayName='郑利', key='zhengli', name='zhengli'>


def isValidUser(username):
    cli = JIRA(JIRA_URL, token_auth=JIRA_TOKEN)
    try:
        cli.user(username)
        return True
    except jira.JIRAError as e:
        print(e.text)
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

    for u in [username, username1, username2]:
        if isValidUser(u):
            return u
    return ""


def addJiraUser(fullname, referUser=""):
    py = Pinyin()
    username = py.get_pinyin(fullname, "")
    email = "sss@163.com"
    password = "Password1234"

    cli = JIRA(JIRA_URL, token_auth=JIRA_TOKEN)

    user = {"username": username, "email": email, "fullname": fullname, "password": password}

    try:
        cli.add_user(**user)
        print("jira user is created successfully!")
        if referUser:
            referUsername = getUsername(referUser)
        else:
            referUsername = ""
        if referUsername:
            print("begin add permission!")
            refer = cli.user(referUsername, expand="groups")
            for group in refer.groups.items:
                print(group.name)
                if group.name != "jira-software-users":
                    cli.add_user_to_group(user["username"], group)
        else:
            print("无参考用户，未添加其他权限。")
    except jira.JIRAError as e:
        print(e.text)
        return False
    print("all done!")
    return True


def deleteJiraUser(user):
    username = getUsername(user)
    cli = JIRA(JIRA_URL, token_auth=JIRA_TOKEN)

    try:
        if username and cli.delete_user(username):
            print(f"用户{username}删除成功")
            return True
        else:
            print("用户删除失败")
            return False

    except jira.JIRAError as e:
        print(e.text)
        print("用户删除失败")
        return False


def addSvnUser(user):
    py = Pinyin()
    username = py.get_pinyin(user, "")

    cmd = f'/bin/htpasswd  -b /data/svn/passwd.http  {username}  Password1234'
    print("创建svn账号: " + cmd)
    logger.info("封板请求: " + cmd)
    status, msg = getstatusoutput(cmd)
    logger.info(msg)
    if status == 0:
        return True
    else:
        return False





fullname = "赵奇"
referUser = "周奇"


#add_jira_user(fullname)


#diasble_jira_user(fullname)
