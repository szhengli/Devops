from jenkins import Jenkins
from xpinyin import Pinyin
import xml.etree.ElementTree as ET
import re

INFRA = ["fp-h5", "api", "basic", "entry","fms",
         "fp", "jobms", "sms", "urms", "wsms", "zkms"
         ]
INFRA_SVN_ROOT = "http://svn.cnzhonglunnet.com/svn/zlnet/code/framework/branches/"
NORMAL_SVN_ROOT = "http://svn.cnzhonglunnet.com/svn/zlnet/code/project/branch/"
JENKINS_CONN = {"url": "http://192.168.1.121:8080/", "username": "zhengli", "password": "Password1234"}

def updateSvnPath(pattern, service, svnUrl):
    jk = Jenkins(**JENKINS_CONN)
    jobsAll = [job["name"] for job in jk.get_jobs()]
    for job in jobsAll:
        print("#####################")
        print(pattern + service + '.*')
        print("#####################")
        if re.search(pattern + service + '.*', job):
            print("!!!!!!!!!!!!!!!!!!!!!!")
            print(job)
            print("!!!!!!!!!!!!!!!!!!!!!!")
            jobConfig = ET.fromstring(jk.get_job_config(job))
            try:
                jobConfig.find("scm/locations/hudson.scm.SubversionSCM_-ModuleLocation/remote").text = svnUrl
            except AttributeError:
                jobConfig.find("definition/scm/locations/hudson.scm.SubversionSCM_-ModuleLocation/remote").text = svnUrl
            jk.reconfig_job(job, ET.tostring(jobConfig).decode())

def SVNUpdate(service, branch, target):
    year = branch[:4]
    month = branch[4:6]
    if service in INFRA:
        svnUrl = INFRA_SVN_ROOT + year + "/" + month + "/" + branch + "/" + service + "@HEAD"
    else:
        svnUrl = NORMAL_SVN_ROOT + year + "/" + month + "/" + branch + "/" + service + "@HEAD"
    if target == "生产环境":
        updateSvnPath("prod-.*", service, svnUrl)
    elif target == "灰度环境":
        updateSvnPath("vip.*", service, svnUrl)
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
            permissions.add(Permission.fromId("hudson.model.Item.Configure"));
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

def autoAuth(sysops, target, branch):
    for sysop in sysops:
        if "-" not in sysop:
            print("service entry is in wrong format")
        service, user = sysop.split("-")
        py = Pinyin()
        user = py.get_pinyin(user, splitter='_')
        createUser(user)
        role = ""
        pattern = ""
        if target == "生产环境":
            role = "prod" + "-" + service + ".*"
            pattern = "prod" + "-.*" + service + ".*"
        elif target == "灰度环境":
            role = "vip" + "-" + service + "-"
            pattern = "vip" + "-.*" + service + ".*"
        elif target == "生产+灰度环境":
            role = service
            pattern = ".*" + service + ".*"
        grantRole(role, pattern, user)
        SVNUpdate(service, branch, target)




