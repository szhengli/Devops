package com.config;

/**
 * 项目中的常量定义类
 */
public class Constant {
    /**
     * 企业corpid, 需要修改成开发者所在企业
     */
    public static final String CORP_ID = "ding7d8c50eee77bbbad35c2f4657eb6378f";
    /**
     * 应用的AppKey，登录开发者后台，点击应用管理，进入应用详情可见
     */
    public static final String APPKEY = "dingzziapfzlrb3s3jpv";
    /**
     * 应用的AppSecret，登录开发者后台，点击应用管理，进入应用详情可见
     */
    public static final String APPSECRET = "3cYKqHldeQuyUGsRDMpVwVFwo6F4nYbhgLhuNYW8Q410aFkP1PQXP9gpTUuXGmZr";

    /**
     * 数据加密密钥。用于回调数据的加密，长度固定为43个字符，从a-z, A-Z, 0-9共62个字符中选取,您可以随机生成
     */
    public static final String ENCODING_AES_KEY = "1122334455667788990011223344556677889900123";

    /**
     * 加解密需要用到的token，企业可以随机填写。如 "12345"
     */
    public static final String TOKEN = "223366";

    /**
     * 应用的agentdId，登录开发者后台可查看
     */
    public static final Long AGENTID = 836496853L;

    /**
     * 审批模板唯一标识，可以在审批管理后台找到
     */
    public static final String PROCESS_CODE = "PROC-NWDKIKJV-UL8U5X65VDVY8ITQAUSW1-LEXKWUFJ-1";

    /**
     * 封版
     */
    public static final String PROCESS_CODE_F = "PROC-NWDKIKJV-UL8U5X65VDVY8ITQAUSW1-LEXKWUFJ-1";

    /**
     * 解版
     */
    public static final String PROCESS_CODE_J = "PROC-3KYJ13FV-WF8U6QT8M0SC33PS9E9O2-MQYMWUFJ-B";

    /**
     * 分支创建
     */
    public static final String PROCESS_CODE_C = "PROC-52IKRYIV-AS1VP4KBMCJ9FCWGK7JW1-6WJPYZGJ-9";

    /**
     * 分支调整
     */
    public static final String PROCESS_CODE_T = "PROC-WIYJNNZV-WV1VMLYTOKVTLL1GGE3S1-7YJS10HJ-6";

    /**
     * 封版host
     */
    public static final String F_SVN_HOST = "http://58.210.99.210:8010/svn/branchRo/";

    /**
     * 解版host
     */
    public static final String J_SVN_HOST = "http://58.210.99.210:8010/svn/branchRw/";

    /**
     * 分支创建host
     */
    public static final String C_SVN_HOST = "http://58.210.99.210:8010/svn/branchCreate/";

    /**
     * 分支调整host
     */
    public static final String T_SVN_HOST = "http://58.210.99.210:8010/svn/branchAdjust/";

    /**
     * 回调host
     */
    public static final String CALLBACK_URL_HOST = "http://47.100.53.55:18080";
}
