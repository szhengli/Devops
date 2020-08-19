package com.controller;

import com.alibaba.fastjson.JSON;
import com.alibaba.fastjson.JSONObject;
import com.alibaba.fastjson.JSONArray;

import com.config.Constant;
import com.config.URLConstant;
import com.dingtalk.api.DefaultDingTalkClient;
import com.dingtalk.api.DingTalkClient;
import com.dingtalk.api.request.OapiCallBackDeleteCallBackRequest;
import com.dingtalk.api.request.OapiCallBackGetCallBackRequest;
import com.dingtalk.api.request.OapiCallBackRegisterCallBackRequest;
import com.dingtalk.api.response.OapiCallBackDeleteCallBackResponse;
import com.dingtalk.api.response.OapiCallBackRegisterCallBackResponse;

import com.dingtalk.api.request.OapiProcessinstanceCreateRequest;
import com.dingtalk.api.request.OapiProcessinstanceGetRequest;
import com.dingtalk.api.response.OapiProcessinstanceCreateResponse;
import com.dingtalk.api.response.OapiProcessinstanceGetResponse;

import com.util.LogFormatter;
import com.util.LogFormatter.LogEvent;
import com.util.ServiceResultCode;


import com.dingtalk.oapi.lib.aes.DingTalkEncryptor;
import com.dingtalk.oapi.lib.aes.Utils;
import com.util.AccessTokenUtil;
import com.util.MessageUtil;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseBody;
import org.springframework.web.bind.annotation.RestController;

import java.util.Arrays;
import java.util.Map;
import java.io.*;
import java.text.SimpleDateFormat;
import java.util.Date;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.io.OutputStreamWriter;
import java.net.URL;
import java.net.URLConnection;

/**
 * E应用回调信息处理
 */
@RestController
public class CallbackController {

    private static final Logger bizLogger = LoggerFactory.getLogger("BIZ_CALLBACKCONTROLLER");
    private static final Logger mainLogger = LoggerFactory.getLogger(CallbackController.class);

    /**
     * 创建套件后，验证回调URL创建有效事件（第一次保存回调URL之前）
     */
    private static final String CHECK_URL = "check_url";

    /**
     * 审批任务回调
     */
    private static final String BPMS_TASK_CHANGE = "bpms_task_change";

    /**
     * 审批实例回调
     */
    private static final String BPMS_INSTANCE_CHANGE = "bpms_instance_change";

    /**
     * 相应钉钉回调时的值
     */
    private static final String CALLBACK_RESPONSE_SUCCESS = "success";


    @RequestMapping(value = "/callback", method = RequestMethod.POST)
    @ResponseBody
    public Map<String, String> callback(@RequestParam(value = "signature", required = false) String signature,
                                        @RequestParam(value = "timestamp", required = false) String timestamp,
                                        @RequestParam(value = "nonce", required = false) String nonce,
                                        @RequestBody(required = false) JSONObject json) {
        String params = " signature:" + signature + " timestamp:" + timestamp + " nonce:" + nonce + " json:" + json;
        try {
            DingTalkEncryptor dingTalkEncryptor = new DingTalkEncryptor(Constant.TOKEN, Constant.ENCODING_AES_KEY,
                    Constant.CORP_ID);

            //从post请求的body中获取回调信息的加密数据进行解密处理
            String encryptMsg = json.getString("encrypt");
            String plainText = dingTalkEncryptor.getDecryptMsg(signature, timestamp, nonce, encryptMsg);
            // writeByFileWrite(plainText);
            JSONObject obj = JSON.parseObject(plainText);
            //根据回调数据类型做不同的业务处理
            String eventType = obj.getString("EventType");
            //事件唯一标识
            String eventProcessCode = obj.getString("processCode");
            //事件进度
            String eventProcessType = obj.getString("type");
            //事件ID
            String taskId = obj.getString("processInstanceId");
            //事件是否已审批通过
            boolean isProcessFinished = eventProcessType.equals("finish");
            if (BPMS_TASK_CHANGE.equals(eventType)) {
                bizLogger.info("收到审批任务进度更新: " + plainText);
                //todo: 实现审批的业务逻辑，如发消息
            } else if (BPMS_INSTANCE_CHANGE.equals(eventType)) {
                //封版并且已通过
                if (Constant.PROCESS_CODE_F.equals(eventProcessCode) && isProcessFinished) {
                    getTaskInfo(taskId, 1);
                }
                //解版并且已通过
                else if (Constant.PROCESS_CODE_J.equals(eventProcessCode) && isProcessFinished) {
                    getTaskInfo(taskId, 2);
                }
                //分支创建并且已通过
                else if (Constant.PROCESS_CODE_C.equals(eventProcessCode) && isProcessFinished) {
                    getTaskInfo(taskId, 3);
                }
                //分支调整并且已通过
                else if (Constant.PROCESS_CODE_T.equals(eventProcessCode) && isProcessFinished) {
                    getTaskInfo(taskId, 4);
                }
            } else {
                // 其他类型事件处理
            }

            // 返回success的加密信息表示回调处理成功
            return dingTalkEncryptor.getEncryptedMap(CALLBACK_RESPONSE_SUCCESS, System.currentTimeMillis(), Utils.getRandomStr(8));
        } catch (Exception e) {
            //失败的情况，应用的开发者应该通过告警感知，并干预修复
            bizLogger.error("process callback failed！" + params);
            return null;
        }

    }

    /**
     * 获取钉钉审批详细信息
     */
    public static void getTaskInfo(String _sInstanceID, int toDoFlag) throws Exception {
        try {
            //钉钉查询事件详情
            DingTalkClient client = new DefaultDingTalkClient(URLConstant.URL_PROCESSINSTANCE_GET);
            OapiProcessinstanceGetRequest request = new OapiProcessinstanceGetRequest();
            request.setProcessInstanceId(_sInstanceID);
            OapiProcessinstanceGetResponse response = client.execute(request, AccessTokenUtil.getToken());
            if (response.getErrcode().longValue() != 0) {
                bizLogger.error(response.getErrmsg() + "123");
            }
            JSONObject json = (JSONObject) JSONObject.toJSON(response);
            //详情主体
            JSONObject data = json.getJSONObject("processInstance");
            String jsonStr = JSONObject.toJSONString(json);
            // writeByFileWrite(jsonStr);
            //打印日志
            bizLogger.info(jsonStr);
            String svnCallUrl = "";
            String svnCallParams = "";
            JSONArray data2 = data.getJSONArray("formComponentValues");
            String svnLoc = "";//svn地址
            String includedSystems = "";//svn包含系统
            String releaseDate = "";//分支发布日期
            //审批选填信息，包含分支svn地址
            if(toDoFlag == 1){
                //封版
                svnLoc = getUrlParams(data2,"svn地址");
                svnCallUrl = Constant.F_SVN_HOST;
                svnCallParams = "&svnAddresses=" + svnLoc;
            }
            else if(toDoFlag == 2){
                //解版
                //"解版系统" "svn地址"
                svnLoc = getUrlParams(data2,"svn地址");
                svnCallUrl = Constant.J_SVN_HOST;
                svnCallParams = "&svnAddresses=" + svnLoc;
            }
            else if(toDoFlag == 3){
                //分支创建
                //"发布日期"  "包含系统"
                releaseDate = getUrlParams(data2,"发布日期");
                includedSystems = getUrlParams(data2,"包含系统");
                svnCallUrl = Constant.C_SVN_HOST;
                svnCallParams = "&includedSystems=" + includedSystems + "&releaseDate=" + releaseDate;
            }
            else if(toDoFlag == 4){
                //分支调整
                //分支地址  新增系统 删除系统 调整说明
                String p1 = getUrlParams(data2,"分支地址");
                String p2 = getUrlParams(data2,"新增系统");
                String p3 = getUrlParams(data2,"删除系统");
                String p4 = getUrlParams(data2,"调整说明");
                svnCallUrl = Constant.T_SVN_HOST;
                svnCallParams = "&branch=" + p1 + "&addedSystems=" + p2 + "&deletedSystems=" + p3 + "&comment=" + p4;
                writeByFileWrite(svnCallParams);
            }

            getJsonData(svnCallUrl,svnCallParams);

        } catch (Exception e) {
            String errLog = LogFormatter.getKVLogData(LogEvent.END,
                    LogFormatter.KeyValue.getNew("instanceId", _sInstanceID));
            bizLogger.error(ServiceResultCode.SYS_ERROR.getErrMsg());
        }
    }

    //测试用
    @RequestMapping(value = "/getresult", method = RequestMethod.GET)
    public String getresult() {
        String svnCallUrl = Constant.C_SVN_HOST;
        String svnCallParams = "&includedSystems=" + "testsys" + "&releaseDate=" + "2020-07-31";
        getJsonData(svnCallUrl,svnCallParams);
        return "welcome";
    }

    //从钉钉内容中截取内容
    public static String getUrlParams(JSONArray originData,String findKey){
        String result = "";
        for (int i = 0; i < originData.size(); i++) {
            JSONObject jo = originData.getJSONObject(i);
            String op_name = jo.getString("name");
            String op_value = jo.getString("value");
            //获得svn地址，并发起操作请求
            if (op_name.equals(findKey)) {
                result = op_value;
                break;
            }
        }
        return result;
    }

    //请求svn执行相应操作
    public static void getJsonData(String url,String urlParams) {
        OutputStreamWriter out = null;
        BufferedReader in = null;
        StringBuilder result = new StringBuilder();
        try {
            URL realUrl = new URL(url);
            // 打开和URL之间的连接
            URLConnection conn = realUrl.openConnection();
            //设置通用的请求头属性
            conn.setRequestProperty("accept", "*/*");
            conn.setRequestProperty("connection", "Keep-Alive");
            conn.setRequestProperty("user-agent", "Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1;SV1)");
            // 发送POST请求必须设置如下两行   否则会抛异常（java.net.ProtocolException: cannot write to a URLConnection if doOutput=false - call setDoOutput(true)）
            conn.setDoOutput(true);
            conn.setDoInput(true);
            //获取URLConnection对象对应的输出流并开始发送参数
            out = new OutputStreamWriter(conn.getOutputStream(), "UTF-8");
            //添加参数
            out.write(urlParams);
            out.flush();
            in = new BufferedReader(new InputStreamReader(conn.getInputStream(), "UTF-8"));
            String line;
            while ((line = in.readLine()) != null) {
                result.append(line);
            }
            writeByFileWrite("url:" +url + "   "+ urlParams + " result:" + result);
        } catch (Exception e) {
            e.printStackTrace();
        } finally {// 使用finally块来关闭输出流、输入流
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

    /**
     * 欢迎页面,通过url访问，判断后端服务是否启动
     */
    @RequestMapping(value = "/registCallback", method = RequestMethod.GET)
    public String registCallback() {
        String result = "";
        // 先删除企业已有的回调
        DingTalkClient client = new DefaultDingTalkClient(URLConstant.DELETE_CALLBACK);
        OapiCallBackDeleteCallBackRequest request = new OapiCallBackDeleteCallBackRequest();
        request.setHttpMethod("GET");
        try {
            client.execute(request, AccessTokenUtil.getToken());
        } catch (Exception e) {
            System.out.println("catch exception");
        }
        // 重新为企业注册回调
        client = new DefaultDingTalkClient(URLConstant.REGISTER_CALLBACK);
        OapiCallBackRegisterCallBackRequest registerRequest = new OapiCallBackRegisterCallBackRequest();
        registerRequest.setUrl(Constant.CALLBACK_URL_HOST + "/callback");
        registerRequest.setAesKey(Constant.ENCODING_AES_KEY);
        registerRequest.setToken(Constant.TOKEN);
        registerRequest.setCallBackTag(Arrays.asList("bpms_instance_change", "bpms_task_change"));
        try {
            OapiCallBackRegisterCallBackResponse registerResponse = client.execute(registerRequest, AccessTokenUtil.getToken());
            if (registerResponse.isSuccess()) {
                result = "回调注册成功了！！！";
                System.out.println(result);
            }
        } catch (Exception e) {
            result = "回调注册失败了！！！";
            System.out.println(result);
        }

        return result;
    }

    public static void main(String[] args) throws Exception {
        // 先删除企业已有的回调
        DingTalkClient client = new DefaultDingTalkClient(URLConstant.DELETE_CALLBACK);
        OapiCallBackDeleteCallBackRequest request = new OapiCallBackDeleteCallBackRequest();
        request.setHttpMethod("GET");
        client.execute(request, AccessTokenUtil.getToken());

        // 重新为企业注册回调
        client = new DefaultDingTalkClient(URLConstant.REGISTER_CALLBACK);
        OapiCallBackRegisterCallBackRequest registerRequest = new OapiCallBackRegisterCallBackRequest();
        registerRequest.setUrl(Constant.CALLBACK_URL_HOST + "/callback");
        registerRequest.setAesKey(Constant.ENCODING_AES_KEY);
        registerRequest.setToken(Constant.TOKEN);
        registerRequest.setCallBackTag(Arrays.asList("bpms_instance_change", "bpms_task_change"));
        OapiCallBackRegisterCallBackResponse registerResponse = client.execute(registerRequest, AccessTokenUtil.getToken());
        if (registerResponse.isSuccess()) {
            System.out.println("回调注册成功了！！！");
        }
    }

    public static void writeByFileWrite(String _sContent) throws IOException {
        String content = "\n\n请求时间为：\n" + new SimpleDateFormat("yyyy-MM-dd HH:mm:ss-SSS").format(new Date()) + "\n" + _sContent;
        bizLogger.info(content);
//        String filePath = "/writetext8/log.txt";
//        String file = filePath.substring(0, filePath.lastIndexOf("/"));
//        File logfile = new File(file);
//        if (!logfile.exists()) {
//            logfile.mkdirs();
//        }
//        File log = new File(filePath);
//        if (!log.exists()) {
//            log.createNewFile();
//        }
//        String content = "\n\n请求时间为：\n" + new SimpleDateFormat("yyyy-MM-dd HH:mm:ss-SSS").format(new Date()) + "\n" + _sContent;
//        BufferedWriter fw = new BufferedWriter(new OutputStreamWriter(new FileOutputStream(log, true), "UTF-8"));
//        try {
//
//            fw.write(content);
//        } catch (Exception ex) {
//            ex.printStackTrace();
//        } finally {
//            if (fw != null) {
//                fw.close();
//                fw = null;
//            }
//        }
    }
}
