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
     * 加解密需要用到的token，企业可以随机填写。如 "223366"
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

    // 封版(旧)
    public static final String PROCESS_CODE_F = "PROC-NWDKIKJV-UL8U5X65VDVY8ITQAUSW1-LEXKWUFJ-1";


    public static final String PROCESS_CODE_ZD =  "PROC-DF4142C6-A177-4B1F-BA98-3BEF54E40623";

    public static final String PROCESS_CODE_ZD_JOB =  "PROC-BA41C1CA-13CC-47F9-B51D-4E0E0DA2CFEE";


    // 封版(新)
    public static final String PROCESS_CODE_FX = "PROC-4FBACFC7-0958-47A0-88F1-30F6BB6E77EF";

    // 紧急解版
    public static final String PROCESS_CODE_FQ = "PROC-705E4A7A-FF1D-4926-AB4E-CBF682E5A09B";

    // 解版(旧)
    public static final String PROCESS_CODE_J = "PROC-3KYJ13FV-WF8U6QT8M0SC33PS9E9O2-MQYMWUFJ-B";

    // 解版(新)
    public static final String PROCESS_CODE_JX = "PROC-30D74EB7-1D2E-4621-9FD9-10FB2C2A1671";

    // 分支创建
    public static final String PROCESS_CODE_C = "PROC-52IKRYIV-AS1VP4KBMCJ9FCWGK7JW1-6WJPYZGJ-9";

    // 分支调整
    public static final String PROCESS_CODE_T = "PROC-WIYJNNZV-WV1VMLYTOKVTLL1GGE3S1-7YJS10HJ-6";

    // 发布系统
    public static final String PROCESS_CODE_FB = "PROC-QA3L0ZMV-USOPUHD7S1MNK1RP5E2S2-ZND7UG9J-3";

    // 分支调整
    public static final String PROCESS_CODE_S = "PROC-0A3CDAC0-E145-490E-9157-4B209C6AD664";

    // 重启系统
    public static final String PROCESS_CODE_ReStart = "PROC-CE44F1F1-DEC8-4086-91EB-1F02FFC7CB86";

    public static final String PROCESS_CODE_SYPROD = "PROC-A8ED0C1E-DE0C-4945-B76A-E07075FAA3C2";


    public static final String F_SVN_HOST = "http://58.210.99.210:8010/svn/branchRo/";
    public static final String J_SVN_HOST = "http://58.210.99.210:8010/svn/branchRw/";
    public static final String C_SVN_HOST = "http://58.210.99.210:8010/svn/branchCreate/";
    public static final String T_SVN_HOST = "http://58.210.99.210:8010/svn/branchAdjust/";
    public static final String S_C_SVN_HOST = "http://58.210.99.210:8010/svn/branchNew/";
    public static final String S_T_SVN_HOST = "http://58.210.99.210:8010/svn/branchChange/";
    public static final String S_Q_SVN_HOST = "http://58.210.99.210:8010/svn/branchMove/";
    public static final String F_B_SVN_HOST = "http://58.210.99.210:8010/svn/jenkinsAutoAuth/";
    public static final String CALLBACK_URL_HOST = "http://58.210.99.210:18080";
}
