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
package org.apache.rocketmq.dashboard.task;

import java.util.ArrayList;
import java.util.Map;
import javax.annotation.Resource;

import org.apache.rocketmq.dashboard.dingding.SendTextMessage;
import org.apache.rocketmq.dashboard.model.ConsumerMonitorConfig;
import org.apache.rocketmq.dashboard.model.GroupConsumeInfo;
import org.apache.rocketmq.dashboard.service.ConsumerService;
import org.apache.rocketmq.dashboard.service.MonitorService;
import org.apache.rocketmq.dashboard.util.JsonUtil;
import org.springframework.scheduling.annotation.Scheduled;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;

@Component
public class MonitorTask {
    private Logger logger = LoggerFactory.getLogger(MonitorTask.class);

    @Resource
    private MonitorService monitorService;

    @Resource
    private ConsumerService consumerService;

    @Scheduled(cron = "3 * * * * ?")
    public void scanProblemConsumeGroup() {
        for (Map.Entry<String, ConsumerMonitorConfig> configEntry : monitorService.queryConsumerMonitorConfig().entrySet()) {
            GroupConsumeInfo consumeInfo = consumerService.queryGroup(configEntry.getKey());
            String engineerBobiles = configEntry.getValue().getEngineerMobiles();

            if (consumeInfo.getCount() < configEntry.getValue().getMinCount() || consumeInfo.getDiffTotal() > configEntry.getValue().getMaxDiffTotal()) {
                logger.info("op=look consumeInfo {}", JsonUtil.obj2String(consumeInfo)); // notify the alert system
                logger.info("///////////////////////////////////////////////");
                logger.info("################################" + configEntry.getValue().getEngineerMobiles());
                logger.info("///////////////////////////////////////////////");

                String msg = "mq alert: \n" + "SubscriptionGroup: " + consumeInfo.getGroup() + "\n" +
                        "Instances: " + consumeInfo.getCount() + "\n" +
                        "Delay: " + consumeInfo.getCount() + "\n" +
                        "Tps: " + consumeInfo.getConsumeTps() + "\n" +
                        "Delay: " + consumeInfo.getDiffTotal();

                if (engineerBobiles.equals("")) {
                    SendTextMessage.send(msg);
                } else {
                    ArrayList<String> mobiles = new ArrayList<String>();
                    for (String engineerMobile : engineerBobiles.split(",")) {
                        mobiles.add(engineerMobile.split(":")[1]);
                        SendTextMessage.sendWithAt(msg, mobiles);
                        System.out.println(engineerMobile.split(":")[1]);
                    }
                }
            }
        }
    }
}
