from jenkins import Jenkins
from xpinyin import Pinyin
import xml.etree.ElementTree as ET
import re

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
                    jobConfig.find(
                        "definition/scm/locations/hudson.scm.SubversionSCM_-ModuleLocation/remote").text = svnUrl
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
        updateSvnPath(env + "-" + env, service, svnUrl)
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
        role = "vip" + "-" + service
        pattern = get_env("vip", service) + "-" + service + '.*'
    elif target == "生产+灰度环境":
        role = service
        pattern = ".*" + service + ".*"
    return role, user, service, pattern


def autoAuth(sysops, target, branch):
    for sysop in sysops:
        if "@" in sysop:
            role, user, service, pattern = getRoleAndPattern(sysop, target)
            print("user：" + user)
            print("role：" + role)
            print("service：" + service)
            print("pattern：" + pattern)
            print("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!")
            createUser(user)
            grantRole(role, pattern, user)
            grantRole(role + "-rollback", pattern + "-rollback", user)
        else:
            print("service entry has no releaser")
            service = sysop
        SVNUpdate(service, branch, target)

def unsssignRole(sysops, target):
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
            role, user, _, _ = getRoleAndPattern(sysop, target)
            cmd = cmdTemplate.format(role=role, user=user)
            cmd_rollback = cmdTemplate.format(role=role + "-rollback", user=user)
            # print(cmd)
            jk = Jenkins(**JENKINS_CONN)
            info = jk.run_script(cmd)
            info_rollback = jk.run_script(cmd_rollback)
