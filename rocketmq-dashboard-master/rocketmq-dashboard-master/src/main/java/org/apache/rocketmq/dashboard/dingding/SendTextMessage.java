/*
 * Licensed to the Apache Software Foundation (ASF) under one or more
 * contributor license agreements.  See the NOTICE file distributed with
 * this work for additional information regarding copyright ownership.
 * The ASF licenses this file to You under the Apache License, Version 2.0
 * (the "License"); you may not use this file except in compliance with
 * the License.  You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package org.apache.rocketmq.dashboard.dingding;


import lombok.extern.slf4j.Slf4j;

import java.util.ArrayList;


@Slf4j
public class SendTextMessage {
    //
    public static String WEBHOOK_TOKEN = "https://oapi.dingtalk.com/robot/send?access_token=23c00bad28edc4a9896de4c2ed945a31bf08411ef4c8424508e5fea889e3fc90";

    private static RobotClient robot = new RobotClient();
   // private static final org.slf4j.Logger log = org.slf4j.LoggerFactory.getLogger(SendTextMessage.cl

    /**
     *
     *
     * @param message
     * @return
     */
    public static SendResult send(String message) {
        TextMessage textMessage = new TextMessage(message);
        SendResult sendResult = null;
        try {
            sendResult = robot.send(WEBHOOK_TOKEN, textMessage);
        } catch (Exception e) {

            log.error("===> send robot message error:", sendResult);
        }
        return sendResult;
    }

    /**
     *
     *
     * @param message
     * @param atMobiles rrayList<String>
     * @return
     */
    public static SendResult sendWithAt(String message, ArrayList<String> atMobiles) {
        TextMessage textMessage = new TextMessage(message);
        SendResult sendResult = null;
        textMessage.setAtMobiles(atMobiles);
        try {
            sendResult = robot.send(WEBHOOK_TOKEN, textMessage);
        } catch (Exception e) {
            log.error("===> send robot message atPeople error:", sendResult);
        }
        return sendResult;
    }

    /**
     *
     *
     * @param message
     * @return
     */
    public static SendResult sendWithAtAll(String message) {
        TextMessage textMessage = new TextMessage(message);
        SendResult sendResult = null;
        textMessage.setIsAtAll(true);
        try {
            sendResult = robot.send(WEBHOOK_TOKEN, textMessage);
        } catch (Exception e) {
            log.error("===> send robot message atAll error:", sendResult);
        }
        return sendResult;
    }




}