package com.controller;

import com.alibaba.fastjson.JSON;
import com.alibaba.fastjson.JSONArray;
import com.alibaba.fastjson.JSONObject;
import com.dingtalk.api.DefaultDingTalkClient;
import com.dingtalk.api.DingTalkClient;
import com.dingtalk.api.request.OapiCallBackDeleteCallBackRequest;
import com.dingtalk.api.request.OapiCallBackRegisterCallBackRequest;
import com.dingtalk.api.request.OapiProcessinstanceGetRequest;
import com.dingtalk.api.response.OapiCallBackRegisterCallBackResponse;
import com.dingtalk.api.response.OapiProcessinstanceGetResponse;
import com.dingtalk.oapi.lib.aes.DingTalkEncryptException;
import com.dingtalk.oapi.lib.aes.DingTalkEncryptor;
import com.util.AccessTokenUtil;
import com.util.LogFormatter;
import com.util.LogFormatter.KeyValue;
import com.util.LogFormatter.LogEvent;
import com.util.ServiceResultCode;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.io.OutputStreamWriter;
import java.io.PrintStream;
import java.net.URL;
import java.net.URLConnection;
import java.util.Arrays;
import java.util.HashMap;
import java.util.Map;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.util.StringUtils;
import org.springframework.web.bind.annotation.*;

import static com.config.Constant.*;

@RestController
public class CallbackController {
    private static final Logger bizLogger = LoggerFactory.getLogger("BIZ_CALLBACKCONTROLLER");
    private static final Logger mainLogger = LoggerFactory.getLogger(CallbackController.class);
    private static final String CHECK_URL = "check_url";
    private static final String BPMS_TASK_CHANGE = "bpms_task_change";
    private static final String BPMS_INSTANCE_CHANGE = "bpms_instance_change";
    private static final String CALLBACK_RESPONSE_SUCCESS = "success";

    @RequestMapping(value = "/callback", method = RequestMethod.POST)
    @ResponseBody
    public Map<String, String> callback(@RequestParam(value = "plainText", required = true) String plainText) {
        try {
            JSONObject obj = JSON.parseObject(plainText);

            String eventType = obj.getString("EventType");
            bizLogger.info("收到回调" + plainText);
            if ("bpms_instance_change".equals(eventType)) {
                String eventProcessCode = obj.getString("processCode");
                String eventProcessResult = obj.getString("result");
                String taskId = obj.getString("processInstanceId");
                String businessId = obj.getString("businessId");
                boolean isProcessAgreed = eventProcessResult.equals("agree");

                if ((PROCESS_CODE_F.equals(eventProcessCode)) && (isProcessAgreed)) {
                    // 旧封版
                    getTaskInfo(taskId, 1,businessId);
                } else if ((PROCESS_CODE_FX.equals(eventProcessCode)) && (isProcessAgreed)) {
                    // 新封版
                    getTaskInfo(taskId, 11,businessId);
                } else if ((PROCESS_CODE_FQ.equals(eventProcessCode))) {
                    // 紧急解版
                    getTaskInfo(taskId, 10,businessId);
                } else if ((PROCESS_CODE_J.equals(eventProcessCode)) && (isProcessAgreed)) {
                    // 旧解版
                    getTaskInfo(taskId, 2,businessId);
                } else if ((PROCESS_CODE_JX.equals(eventProcessCode)) && (isProcessAgreed)) {
                    // 新解版
                    getTaskInfo(taskId, 12,businessId);
                } else if ((PROCESS_CODE_C.equals(eventProcessCode)) && (isProcessAgreed)) {
                    // 发布系统
                    getTaskInfo(taskId, 3,businessId);
                } else if ((PROCESS_CODE_T.equals(eventProcessCode)) && (isProcessAgreed)) {
                    // 分支调整
                    getTaskInfo(taskId, 4,businessId);
                } else if ((PROCESS_CODE_S.equals(eventProcessCode)) && (isProcessAgreed)) {
                    // 分支调整
                    getTaskInfo(taskId, 5,businessId);
                } else if ((PROCESS_CODE_FB.equals(eventProcessCode)) && (isProcessAgreed)) {
                    // 发布系统
                    getTaskInfo(taskId, 6,businessId);
                } else if ((PROCESS_CODE_ReStart.equals(eventProcessCode)) && (isProcessAgreed)) {
                    // 生产环境服务重启申请单
                    getTaskInfo(taskId, 7,businessId);
                } else if ((PROCESS_CODE_SYPROD.equals(eventProcessCode)) && (isProcessAgreed)) {
                    // 生产环境服务重启申请单
                    getTaskInfo(taskId, 8,businessId);
                } else if ((PROCESS_CODE_ZD.equals(eventProcessCode)) && (isProcessAgreed)) {
                    // 生产环境服务重启申请单
                    getTaskInfo(taskId, 13,businessId);
                }else if ((PROCESS_CODE_ZD_JOB.equals(eventProcessCode)) && (isProcessAgreed)) {
                    // 生产环境服务重启申请单
                    getTaskInfo(taskId, 14,businessId);
                }
            }
            Map<String, String> result = new HashMap();
            result.put("msg", "回调处理成功");
            bizLogger.error("回调处理成功" + plainText);
            return result;
        } catch (Exception e) {
            Map<String, String> result = new HashMap();
            result.put("msg", "回调处理抱错");
            bizLogger.error("" + plainText);
            bizLogger.error("回调处理抱错" + e.getMessage());
            return result;
        }
    }

    public static void getTaskInfo(String _sInstanceID, int toDoFlag,String businessId)
            throws Exception {
        try {
            DingTalkClient client = new DefaultDingTalkClient("https://oapi.dingtalk.com/topapi/processinstance/get");
            OapiProcessinstanceGetRequest request = new OapiProcessinstanceGetRequest();
            request.setProcessInstanceId(_sInstanceID);
            OapiProcessinstanceGetResponse response = (OapiProcessinstanceGetResponse) client.execute(request, AccessTokenUtil.getToken());
            if (response.getErrcode().longValue() != 0L) {
                bizLogger.error("获取审批详情抱错" + response.getErrmsg());
            }
            JSONObject json = (JSONObject) JSONObject.toJSON(response);

            JSONObject data = json.getJSONObject("processInstance");
            String jsonStr = JSONObject.toJSONString(json);

            bizLogger.info("钉钉详情信息" + jsonStr);
            String svnCallUrl = "";
            String svnCallParams = "";
            JSONArray data2 = data.getJSONArray("formComponentValues");
            String dingTitle = data.getString("title");
            bizLogger.info("title " + dingTitle);
            String[] orrginName = StringUtils.split(dingTitle, "提交的");
            String currentUserName = orrginName[0];
            bizLogger.info("currentUserName " + currentUserName);
            String svnNum = "";
            String systemNum = "";
            String includedSystems = "";
            String releaseDate = "";
            String svnLoc = "";
            String target = "";
            if (toDoFlag == 1) {
                // 旧封版
                svnLoc = getUrlParams(data2, "svn地址");
                svnCallUrl = "http://58.210.99.210:8010/svn/branchRo/";
                svnCallParams = "svnAddresses=" + svnLoc + "&originatorUserName=" + currentUserName;
            } else if (toDoFlag == 11) {
                // 新封版
                svnNum = getUrlParams(data2, "分支号");
                systemNum = getUrlParams(data2, "系统清单");
                svnCallUrl = "http://58.210.99.210:8010/svn/branchRoNew/";
                svnCallParams = "branch=" + svnNum + "&includedSystems=" + systemNum + "&originatorUserName=" + currentUserName;
            } else if (toDoFlag == 10) {
                // 紧急解版 = 解版 + 发布
                systemNum = getUrlParams(data2, "系统清单");
                svnCallUrl = "http://58.210.99.210:8010/svn/branchRwUG/";
                svnCallParams = "includedSystems=" + systemNum + "&originatorUserName=" + currentUserName;
                bizLogger.info("svnCallParams " + svnCallParams);
            } else if (toDoFlag == 2) {
                // 旧解版
                svnLoc = getUrlParams(data2, "svn地址");
                svnCallUrl = "http://58.210.99.210:8010/svn/branchRw/";
                svnCallParams = "svnAddresses=" + svnLoc + "&originatorUserName=" + currentUserName;
            } else if (toDoFlag == 12) {
                // 新解版
                svnNum = getUrlParams(data2, "分支号");
                systemNum = getUrlParams(data2, "系统清单");
                svnCallUrl = "http://58.210.99.210:8010/svn/branchRwNew/";
                svnCallParams = "branch=" + svnNum + "&includedSystems=" + systemNum + "&originatorUserName=" + currentUserName;
            } else if (toDoFlag == 3) {
                // 发布系统
                target = getUrlParams(data2, "发布环境");
                releaseDate = getUrlParams(data2, "发布日期");
                includedSystems = getUrlParams(data2, "包含系统");
                svnCallUrl = "http://58.210.99.210:8010/svn/branchCreate/";
                svnCallParams = "includedSystems=" + includedSystems + "&releaseDate=" + releaseDate +
                        "&originatorUserName=" + currentUserName + "$target" + target;
            } else if (toDoFlag == 4) {
                // 分支调整
                String p1 = getUrlParams(data2, "分支地址");
                String p2 = getUrlParams(data2, "新增系统");
                String p3 = getUrlParams(data2, "删除系统");
                String p4 = getUrlParams(data2, "调整说明");
                String p6 = getUrlParams(data2, "申请用途");
                svnCallUrl = "http://58.210.99.210:8010/svn/branchAdjust/";
                svnCallParams = "branch=" + p1 + "&addedSystems=" + p2 + "&deletedSystems=" + p3 + "&comment=" + p4 + "&originatorUserName=" + currentUserName + "&useinfo=" + p6;
            } else if (toDoFlag == 5) {
                // 分支调整
                String p1 = getUrlParams(data2, "申请类型");
                if (p1.equals("分支创建")) {
                    String p2 = getUrlParams(data2, "分支地址");
                    String p3 = getUrlParams(data2, "系统清单");
                    String p4 = getUrlParams(data2, "申请说明");
                    String p6 = getUrlParams(data2, "申请用途");
                    svnCallUrl = "http://58.210.99.210:8010/svn/branchNew/";
                    svnCallParams = "branch=" + p2 + "&includedSystems=" + p3 + "&comment=" + p4 + "&originatorUserName=" + currentUserName + "&useinfo=" + p6;
                } else if (p1.equals("分支调整")) {
                    String p2 = getUrlParams(data2, "分支地址");
                    String p3 = getUrlParams(data2, "新增系统");
                    String p4 = getUrlParams(data2, "删除系统");
                    String p5 = getUrlParams(data2, "申请说明");
                    String p6 = getUrlParams(data2, "申请用途");
                    svnCallUrl = "http://58.210.99.210:8010/svn/branchChange/";
                    svnCallParams = "branch=" + p2 + "&addedSystems=" + p3 + "&deletedSystems=" + p4 + "&comment=" + p5 + "&originatorUserName=" + currentUserName + "&useinfo=" + p6;
                } else if (p1.equals("分支迁移")) {
                    String p2 = getUrlParams(data2, "迁出分支地址");
                    String p3 = getUrlParams(data2, "迁入分支地址");
                    String p4 = getUrlParams(data2, "系统清单");
                    String p5 = getUrlParams(data2, "申请说明");
                    String p6 = getUrlParams(data2, "是否删除原分支系统");
                    String p7 = getUrlParams(data2, "申请用途");
                    if (p6.equals("是")) {
                        p6 = "no";
                    } else if (p6.equals("否")) {
                        p6 = "yes";
                    } else {
                        p6 = "";
                    }
                    svnCallUrl = "http://58.210.99.210:8010/svn/branchMove/";
                    svnCallParams = "srcBranch=" + p2 + "&desBranch=" + p3 + "&includedSystems=" + p4 + "&comment=" + p5 + "&originatorUserName=" + currentUserName + "&keep=" + p6 + "&useinfo=" + p7;
                }
            } else if (toDoFlag == 6) {
                // 发布系统
                String p1 = getUrlParams(data2, "发布环境");
                String p2 = getUrlParams(data2, "发布分支");
                String p3 = getUrlParams(data2, "是否停机发布");
                if (p3.equals("是")) {
                    p3 = "yes";
                } else if (p3.equals("否")) {
                    p3 = "no";
                } else {
                    p3 = "";
                }
                String p4 = getUrlParams(data2, "DB脚本");
                String p5 = getUrlParams(data2, "发布系统");
                String p6 = getUrlParams(data2, "发布时间");
                String p7 = getUrlParams(data2, "是否需要收银端打包");
                if (p7.equals("是")) {
                    p7 = "yes";
                } else if (p7.equals("否")) {
                    p7 = "no";
                } else {
                    p3 = "";
                }
                String p8 = getUrlParams(data2, "版本说明");
                svnCallUrl = "http://58.210.99.210:8010/svn/jenkinsAutoAuth/";
                if(p1.equals("生产环境")){
                    svnCallParams = "target=" + p1 + "&branch=" + p2 + "&shutdown =" + p3 + "&dbscript=" + p4 +
                            "&sysops=" + p5 + "&publishTime=" + p6 + "&packagePOS" + p7 + "&comment=" + p8 + "&applicant=" +
                            currentUserName + "&dingID=" + businessId;
                }else {
                    svnCallParams = "target=" + p1 + "&branch=" + p2 + "&shutdown =" + p3 + "&dbscript=" + p4 +
                            "&sysops=" + p5 + "&publishTime=" + p6 + "&packagePOS" + p7 + "&comment=" + p8 + "&applicant=" +
                            currentUserName;
                }
            } else if (toDoFlag == 7) {
                //生产环境服务重启申请单
                String p1 = getUrlParams(data2, "发布系统");
                String p2 = getUrlParams(data2, "发布时间");
                svnCallUrl = "http://58.210.99.210:8010/svn/jenkinsAutoAuthRestart/";
                svnCallParams = "target=生产环境&sysops=" + p1 + "&publishTime=" + p2 + "&originatorUserName=" + currentUserName;
            } else if (toDoFlag == 8) {
                //生产环境服务重启申请单
                String p3 = getUrlParams(data2, "同步分支号");
                String p1 = getUrlParams(data2, "系统清单");
                String p2 = getUrlParams(data2, "同步日期");
                svnCallUrl = "http://58.210.99.210:8010/svn/jenkinsAutoSyProd/";
                svnCallParams = "target=生产环境&sysops=" + p1 + "&publishTime=" + p2 + "&branch=" + p3 +  "&dingID=" + businessId;
            } else if (toDoFlag == 13) {
                String apptype = getUrlParams(data2, "应用类型");

                //稳定版收银机(WIN)
                if(apptype.equals("稳定版收银机(WIN)")){
                    //生产环境服务重启申请单
                    String env = getUrlParams(data2, "发布环境");
                    String apps = getUrlParams(data2, "应用选择");
                    String servertel = getUrlParams(data2, "服务商手机号");
                    String servername = getUrlParams(data2, "服务商名称");
                    String industrycn = getUrlParams(data2, "行业");
                    String systemvesrion = getUrlParams(data2, "系统版本");
                    String svnpath = getUrlParams(data2, "svn地址");
                    String appversion = getUrlParams(data2, "版本号");
                    String appversioncode = getUrlParams(data2, "版本编码");
                    String publisher = getUrlParams(data2, "发布人");
                    String website = getUrlParams(data2, "网站");
                    String lastbase = getUrlParams(data2, "上一次完整版本");
                    String lastsuccess = getUrlParams(data2, "上一次成功版本");
                    String h5homesvnpath = getUrlParams(data2, "h5主屏地址");
                    String h5seconsvnpath = getUrlParams(data2, "h5副屏地址");
                    String company = getUrlParams(data2, "公司名称");
                    String isincrement = getUrlParams(data2, "是否增量发全量");
                    String isignorversion = getUrlParams(data2, "是否忽略版本");
                    String isaloneupgrade = getUrlParams(data2, "是否独立升级");
                    String isforce = getUrlParams(data2, "是否强制升级");
                    String lbimagecount = getUrlParams(data2, "轮播图片数量");
                    String appdesc = getUrlParams(data2, "版本说明");
                    String upgradelog = getUrlParams(data2, "升级日志");
                    String devicecodes = getUrlParams(data2, "定向发布");
                    String pushtime = getUrlParams(data2, "发布时间");
                    svnCallUrl = "http://58.210.99.210:8010/svn/jenkinsAutoAdp/";
                    // 参数转换
                    isincrement = isincrement.equals("是") ? "1" : "0";
                    isignorversion = isignorversion.equals("是") ? "1" : "0";
                    isaloneupgrade = isaloneupgrade.equals("是") ? "1" : "0";
                    isforce = isforce.equals("是") ? "1" : "0";
                    String[] app = apps.split("-");
                    String appname = app[0];
                    String appid = app[1];
                    String appcode = app[2];
                    String servercode = app[3];
                    String osscode = "";
                    String industry = "";
                    if (industrycn.equals("通用版")) {
                        industry = "0";
                    }
                    if (industrycn.equals("农贸版")) {
                        industry = "1";
                    }
                    if (industrycn.equals("岗亭版")) {
                        industry = "2";
                    }
                    if (industrycn.equals("集中收银")) {
                        industry = "3";
                    }
                    if (industrycn.equals("生鲜")) {
                        industry = "4";
                    }
                    if (industrycn.equals("分拣")) {
                        industry = "5";
                    }
                    if (industrycn.equals("轻餐")) {
                        industry = "6";
                    }
                    if (industrycn.equals("茶舍")) {
                        industry = "7";
                    }
                    if (industrycn.equals("正餐")) {
                        industry = "8";
                    }
                    if (industrycn.equals("服装")) {
                        industry = "9";
                    }
                    if (industrycn.equals("自助收银机")) {
                        industry = "13";
                    }
                    svnCallParams = "env=" + env + "&apptype=" + apptype +
                            "appname=" + appname + "&servertel=" + servertel + "&industry=" + industry + "&systemvesrion=" + systemvesrion + "&svnpath=" + svnpath +
                            "appversion=" + appversion + "&appversioncode=" + appversioncode + "&publisher=" + publisher + "&website=" + website +
                            "lastbase=" + lastbase + "&lastsuccess=" + lastsuccess + "&h5homesvnpath=" + h5homesvnpath + "&h5seconsvnpath=" + h5seconsvnpath +
                            "company=" + company + "&isincrement=" + isincrement +
                            "&isignorversion=" + isignorversion + "&isaloneupgrade=" + isaloneupgrade + "&isforce=" + isforce + "&lbimagecount=" + lbimagecount +
                            "appdesc=" + appdesc + "&upgradelog=" + upgradelog + "&devicecodes=" + devicecodes + "&pushtime=" + pushtime + "&id=" + appid + "&appcode=" + appcode
                            + "&servercode=" + servercode + "&servername=" + servername + "&osscode" + osscode;
                }

            } else if(toDoFlag == 14){
                String apptype = getUrlParams(data2, "应用类型");
                svnCallUrl = "http://58.210.99.210:8010/svn/posPackage/";
                if(apptype.equals("稳定版收银机(WIN)")){
                    String apps = getUrlParams(data2, "应用选择");
                    String publishTime = getUrlParams(data2, "发布时间");
                    String[] app = apps.split("-");
                    String appid = app[app.length-3];
                    svnCallParams = "ID=" + appid + "&apptype=" + apptype + "&publishTime=" + publishTime;
                }
            }

            bizLogger.info("发起请求" + svnCallUrl + "?" + svnCallParams);

            // 发起请求
            getJsonData(svnCallUrl, svnCallParams);
        } catch (Exception e) {
            String errLog = LogFormatter.getKVLogData(LogFormatter.LogEvent.END, new LogFormatter.KeyValue[]{
                    LogFormatter.KeyValue.getNew("instanceId", _sInstanceID)});
            bizLogger.error("获取审批详情，解析catch" + ServiceResultCode.SYS_ERROR.getErrMsg() + "e==> " + e.getMessage());
        }
    }

    @RequestMapping(value = {"/getresult"}, method = {org.springframework.web.bind.annotation.RequestMethod.GET})
    public static String getresult()
            throws DingTalkEncryptException {
        DingTalkEncryptor dingTalkEncryptor = new DingTalkEncryptor("223366", "1122334455667788990011223344556677889900123", "ding7d8c50eee77bbbad35c2f4657eb6378f");
        String signature = "2f51c7c1cc046f764a62f12384a11799a85e983a";
        String timestamp = "1596708186951";
        String nonce = "53WDuWFq";
        String encryptMsg = "{\"encrypt\":\"354Hdb07ZYfCYBlTorrbQvpjLL7Rfgg1XMuTOba/rMnSRJ75Dk6q3fr/v5Zbk5xQC5/X+4QeEROZSkFBbEiEbzTk/JncD8hOh1K/yi5BqOFs3wSluBZ5BDh3G4bt4lZr\"}";
        String plainText = dingTalkEncryptor.getDecryptMsg(signature, timestamp, nonce, encryptMsg);
        return plainText;
    }

    public static String getUrlParams(JSONArray originData, String findKey) {
        String result = "";
        bizLogger.info("getUrlParams" + originData.toJSONString() + "?" + findKey);
        for (int i = 0; i < originData.size(); i++) {
            JSONObject jo = originData.getJSONObject(i);
            String op_name = jo.getString("name");
            String op_value = jo.getString("value");
            if (op_name != null && op_name.equals(findKey)) {
                result = op_value;
                break;
            }
        }
        return result;
    }

    public static void getJsonData(String url, String urlParams) {
        OutputStreamWriter out = null;
        BufferedReader in = null;
        StringBuilder result = new StringBuilder();
        try {
            URL realUrl = new URL(url);

            URLConnection conn = realUrl.openConnection();

            conn.setRequestProperty("accept", "*/*");
            conn.setRequestProperty("connection", "Keep-Alive");
            conn.setRequestProperty("user-agent", "Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1;SV1)");

            conn.setDoOutput(true);
            conn.setDoInput(true);

            out = new OutputStreamWriter(conn.getOutputStream(), "UTF-8");

            out.write(urlParams);
            out.flush();
            in = new BufferedReader(new InputStreamReader(conn.getInputStream(), "UTF-8"));
            String line;
            while ((line = in.readLine()) != null) {
                result.append(line);
            }
            bizLogger.info("url:" + url + "   " + urlParams + " result:" + result);
            return;
        } catch (Exception e) {
            bizLogger.error("svn接口失败");
            e.printStackTrace();
        } finally {
            try {
                if (out != null) {
                    out.close();
                }
                if (in != null) {
                    in.close();
                }
            } catch (IOException ex) {
                ex.printStackTrace();
            }
        }
    }
}
