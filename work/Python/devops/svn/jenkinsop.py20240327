from jenkins import Jenkins
from xpinyin import Pinyin
import xml.etree.ElementTree as ET
import re
from redis.sentinel import Sentinel
from datetime import datetime

NORMAL_SVN_ROOT = "http://svn.cnzhonglunnet.com/svn/zlnet/code/project/branch/"
JENKINS_CONN = {"url": "http://172.19.233.38:8080/", "username": "admin", "password": "admin"}


def updateSvnPath(pattern, service, svnUrl):
    jk = Jenkins(**JENKINS_CONN)
    jobsAll = [job["name"] for job in jk.get_jobs()]
    jobService = svnUrl.split('/')[-1].split('@')[0]
    jobBranch = svnUrl.split('/')[-2]
    jobDesc = "系统: {jobService}----分支: {jobBranch}".format(jobService=jobService, jobBranch=jobBranch)
    for job in jobsAll:
        if "rollback" not in job:
            #  print("#####################")
            # print(pattern + service + '.*')
            # print("#####################")
            if re.search(pattern + "-" + service + "$", job):
                print("!!!!!!!!!!!!!!!!!!!!!!")
                print(job)
                print("!!!!!!!!!!!!!!!!!!!!!!")
                jobConfig = ET.fromstring(jk.get_job_config(job))
                try:
                    jobConfig.find("scm/locations/hudson.scm.SubversionSCM_-ModuleLocation/remote").text = svnUrl
                except AttributeError:
                    jobConfig.findall("definition/scm/locations/hudson.scm.SubversionSCM_-ModuleLocation/remote")[1].text = svnUrl
                jobConfig.find('description').text = jobDesc
                jk.reconfig_job(job, ET.tostring(jobConfig).decode())


def SVNUpdate(service, branch, target):
    year = branch[:4]
    month = branch[4:6]
    svnUrl = NORMAL_SVN_ROOT + year + "/" + month + "/" + branch + "/" + service + "@HEAD"
    env = get_env("prod", service)
    if target == "生产环境":
        updateSvnPath(env + "-" + env, service, svnUrl)
    elif target == "灰度环境":
        updateSvnPath("prodv5gray" + "-" + "prodv5", service, svnUrl)
    elif target == "生产+灰度环境":
        updateSvnPath("", service, svnUrl)


def createUser(user):
    cmdTemplate = '''
                import jenkins.model.*
                import hudson.security.*
                def jk = Jenkins.getInstance()
                def hudsonRealm = new HudsonPrivateSecurityRealm(false)
                if (! hudsonRealm.getUser("{user}")) {{
                    hudsonRealm.createAccount("{user}","password")
                    jk.setSecurityRealm(hudsonRealm)
                    jk.save()
                }}
                '''
    cmd = cmdTemplate.format(user=user)
    jk = Jenkins(**JENKINS_CONN)
    info = jk.run_script(cmd)


def grantRole(role, pattern, user):
    cmdTemplate = '''
            import jenkins.model.Jenkins
            import hudson.security.PermissionGroup
            import hudson.security.Permission
            import com.michelin.cio.hudson.plugins.rolestrategy.RoleBasedAuthorizationStrategy
            import com.michelin.cio.hudson.plugins.rolestrategy.Role
            import com.synopsys.arc.jenkins.plugins.rolestrategy.RoleType
            import org.jenkinsci.plugins.rolestrategy.permissions.PermissionHelper
            
            Jenkins jk = Jenkins.getInstance()
            def rbas = jk.getAuthorizationStrategy() 
            
            // remove the existing role, if has.
            def tmpRoleMaps = rbas.getRoleMaps()
            tmpProjecRoleMaps = tmpRoleMaps["projectRoles"]
            tmpRole = tmpProjecRoleMaps.getRole("{role}")
            if (tmpRole) {{
                 tmpProjecRoleMaps.removeRole(tmpRole)
            }}
            // create the project role
            Set<Permission> permissions = new HashSet<Permission>();
            permissions.add(Permission.fromId("hudson.model.Item.Read"));
            permissions.add(Permission.fromId("hudson.model.Item.Build"));
            permissions.add(Permission.fromId("hudson.model.Item.Workspace"));
            permissions.add(Permission.fromId("hudson.model.Item.Cancel"));
         //   permissions.add(Permission.fromId("hudson.model.Item.Configure"));
            Role newRole = new Role("{role}", "{pattern}", permissions);       
            rbas.addRole(RoleBasedAuthorizationStrategy.PROJECT, newRole);
            def roleMaps = rbas.getRoleMaps()
            // grant Global read-only role
            globalRoleMaps = roleMaps["globalRoles"]
            defaultGlobalRole = globalRoleMaps.getRole("default")
            globalRoleMaps.assignRole(defaultGlobalRole, "{user}")
            // grant the project role
            projecRoleMaps = roleMaps["projectRoles"]
            projecRoleMaps.assignRole(newRole, "{user}")
            jk.setAuthorizationStrategy(rbas)
            jk.save()
        '''
    cmd = cmdTemplate.format(role=role, pattern=pattern, user=user)
    # print(cmd)
    jk = Jenkins(**JENKINS_CONN)
    info = jk.run_script(cmd)


def get_env(env, service):
    if 'v5' in service:
        env = env + 'v5'
    return env


def getRoleAndPattern(sysop, target):
    print("#################")
    print("sysop: " + sysop)
    print("#################")
    service, user = sysop.split("@")
    py = Pinyin()
    user = py.get_pinyin(user, splitter='_')
    role = ""
    pattern = ""
    env = get_env("prod", service)
    if target == "生产环境":
        role = "prod" + "-" + service
        pattern = env + "-" + env + "-" + service
    elif target == "灰度环境":
        role = "gray" + "-" + service
        pattern = "prodv5gray" + "-" + "prodv5" + "-" + service
    elif target == "生产+灰度环境":
        role = service
        pattern = ".*" + service + ".*"
    return role, user, service, pattern




def autoAuth(sysops, target, branch, eta_remove_auth_str):

    sentinel = Sentinel([('192.168.1.32', 17020), ('192.168.1.33', 17020),
                         ('192.168.1.34', 17020)], socket_timeout=0.1)
    redis = sentinel.master_for('release_master_1', decode_responses=True)

    for sysop in sysops:
        if "@" in sysop:
            role, user, service, pattern = getRoleAndPattern(sysop, target)
            print("user：" + user)
            print("role：" + role)
            print("service：" + service)
            print("pattern：" + pattern)
            print("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!")

            job_key = "remove-eta-" + role + "-" + user
            rollback_key = "remove-eta-" + role + "-rollback" + "-" + user

            print("------------------autoAuth-------- before ---********* eta_remove_auth_str ***********--------------------------")
            print(type(eta_remove_auth_str))
            print(eta_remove_auth_str)
            print("------------------------------------------------------------------------")

            eta_remove_auth = datetime.strptime(eta_remove_auth_str, "%Y-%m-%d %H:%M:%S")


            print("------------------autoAuth-----------********* eta_remove_auth  datetime??***********--------------------------")
            print(type(eta_remove_auth))
            print(eta_remove_auth)
            print("------------------------------------------------------------------------")

            if redis.exists(job_key):
                if datetime.strptime(redis.get(job_key), "%Y-%m-%d %H:%M:%S") < eta_remove_auth:
                    redis.set(job_key, eta_remove_auth_str)
                    redis.set(rollback_key, eta_remove_auth_str)
            else:
                redis.set(job_key, eta_remove_auth_str)
                redis.set(rollback_key, eta_remove_auth_str)

            createUser(user)
            grantRole(role, pattern, user)
            grantRole(role + "-rollback", pattern + "-rollback", user)
        else:
            print("service entry has no releaser")
            service = sysop
        SVNUpdate(service, branch, target)
    redis.close()

def unsssignRole(sysops, target, eta_remove_auth_str):
    cmdTemplate = '''
            import jenkins.model.Jenkins
            import hudson.security.PermissionGroup
            import hudson.security.Permission
            import com.michelin.cio.hudson.plugins.rolestrategy.RoleBasedAuthorizationStrategy
            import com.michelin.cio.hudson.plugins.rolestrategy.Role
            import com.synopsys.arc.jenkins.plugins.rolestrategy.RoleType
            import org.jenkinsci.plugins.rolestrategy.permissions.PermissionHelper
            Jenkins jk = Jenkins.getInstance()
            def rbas = jk.getAuthorizationStrategy() 
            def roleMaps = rbas.getRoleMaps()
            // unAssgin the project role
            projecRoleMaps = roleMaps["projectRoles"]
            prole = projecRoleMaps.getRole("{role}")
            projecRoleMaps.unAssignRole(prole, "{user}")
            jk.setAuthorizationStrategy(rbas)
            jk.save()
        '''

    sentinel = Sentinel([('192.168.1.32', 17020), ('192.168.1.33', 17020),
                         ('192.168.1.34', 17020)], socket_timeout=0.1)
    redis = sentinel.master_for('release_master_1', decode_responses=True)

    for sysop in sysops:
        if "@" in sysop:
            role, user, _, _ = getRoleAndPattern(sysop, target)

            job_key = "remove-eta-" + role + "-" + user
            rollback_key = "remove-eta-" + role + "-rollback" + "-" + user

          #  eta_remove_auth = datetime.strptime(eta_remove_auth_str, "%Y-%m-%d %H:%M:%S")

            print("@@@@@@@@@@@@@@@@@@！show time @@@@@@@@@@@@@@@@")
            print(redis.get(job_key))
            print(eta_remove_auth_str)
            print(redis.get(job_key) == eta_remove_auth_str)
            print("@@@@@@@@@@@@@@@@@@@@@@@@@@")

            if redis.exists(job_key):
                if redis.get(job_key) == eta_remove_auth_str:

                    cmd = cmdTemplate.format(role=role, user=user)
                    cmd_rollback = cmdTemplate.format(role=role + "-rollback", user=user)
                    # print(cmd)
                    jk = Jenkins(**JENKINS_CONN)
                    info = jk.run_script(cmd)
                    info_rollback = jk.run_script(cmd_rollback)
                    print("################# remove redis key  ############################")
                    redis.delete(job_key, rollback_key)
            else:
                print("################# remove redis key  not exist ############################")
                cmd = cmdTemplate.format(role=role, user=user)
                cmd_rollback = cmdTemplate.format(role=role + "-rollback", user=user)
                # print(cmd)
                jk = Jenkins(**JENKINS_CONN)
                info = jk.run_script(cmd)
                info_rollback = jk.run_script(cmd_rollback)
    redis.close()


def getRoleAndPatternRestart(sysop, target):
    print("#################")
    print("sysop: " + sysop)
    print("#################")
    service, user = sysop.split("@")
    py = Pinyin()
    user = py.get_pinyin(user, splitter='_')
    role = ""
    pattern = ""
    env = get_env("prod", service)
    if target == "生产环境":
        role = "prod" + "-" + service + "-" + "restart"
        pattern = env + "-" + service + "-" + "restart"
    return role, user, service, pattern

def autoAuthRestart(sysops, target):
    for sysop in sysops:
        if "@" in sysop:
            role, user, service, pattern = getRoleAndPatternRestart(sysop, target)
            print("user：" + user)
            print("role：" + role)
            print("service：" + service)
            print("pattern：" + pattern)
            print("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!")
            createUser(user)
            grantRole(role, pattern, user)

def unsssignRoleRestart(sysops, target):
    cmdTemplate = '''
            import jenkins.model.Jenkins
            import hudson.security.PermissionGroup
            import hudson.security.Permission
            import com.michelin.cio.hudson.plugins.rolestrategy.RoleBasedAuthorizationStrategy
            import com.michelin.cio.hudson.plugins.rolestrategy.Role
            import com.synopsys.arc.jenkins.plugins.rolestrategy.RoleType
            import org.jenkinsci.plugins.rolestrategy.permissions.PermissionHelper
            Jenkins jk = Jenkins.getInstance()
            def rbas = jk.getAuthorizationStrategy() 
            def roleMaps = rbas.getRoleMaps()
            // unAssgin the project role
            projecRoleMaps = roleMaps["projectRoles"]
            prole = projecRoleMaps.getRole("{role}")
            projecRoleMaps.unAssignRole(prole, "{user}")
            jk.setAuthorizationStrategy(rbas)
            jk.save()
        '''

    for sysop in sysops:
        if "@" in sysop:
            role, user, _, _ = getRoleAndPatternRestart(sysop, target)
            cmd = cmdTemplate.format(role=role, user=user)
            # print(cmd)
            jk = Jenkins(**JENKINS_CONN)
            info = jk.run_script(cmd)





def getExistBranchFromJenkins(service):
    if 'v5' in service:
        env = "prod" + 'v5'
    else:
        env = "prod"
    jobName = env + "-" + env + "-" + service
    jk = Jenkins(**JENKINS_CONN)
    jobConfig = ET.fromstring(jk.get_job_config(jobName))
    try:
        branch = jobConfig.find("scm/locations/hudson.scm.SubversionSCM_-ModuleLocation/remote").text.split("/")[-2]
    except AttributeError:
        branch = jobConfig.findall("definition/scm/locations/hudson.scm.SubversionSCM_-ModuleLocation/remote")[1].text.split("/")[-2]
    return branch

def changeBranchAndBuild(service, branch):
    year = branch[0:4]
    month = branch[4:6]
    svnUrl = NORMAL_SVN_ROOT + year + "/" + month + "/" + branch + "/" + service + "@HEAD"
    jk = Jenkins(**JENKINS_CONN)
    jobDesc = "系统: {jobService}----分支: {jobBranch}".format(jobService=service, jobBranch=branch)
    jobName = "prodv5-standby-" + service
    #修改Job的SVN路径
    jobConfig = ET.fromstring(jk.get_job_config(jobName))
    try:
        jobConfig.find("scm/locations/hudson.scm.SubversionSCM_-ModuleLocation/remote").text = svnUrl
    except AttributeError:
        jobConfig.findall("definition/scm/locations/hudson.scm.SubversionSCM_-ModuleLocation/remote")[1].text = svnUrl
    jobConfig.find('description').text = jobDesc
    jk.reconfig_job(jobName, ET.tostring(jobConfig).decode())

    #执行构建
    jk.build_job(jobName)

def restartJenkinsJobforPod(service):
    jk = Jenkins(**JENKINS_CONN)
    if 'v5' in service:
        env = "prod" + 'v5'
    else:
        env = "prod"
    jobName = env + "-" + service + "-restart"
    jk.build_job(jobName)


