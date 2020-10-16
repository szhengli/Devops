package net.chenqiong.dubbo.consumer;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

import com.alibaba.dubbo.config.spring.context.annotation.EnableDubbo;

/**
 * @ClassName: DubboConsumerApplication
 * @Description: 消费者启动类
 * @author: 陈琼
 * @date: 2019年1月3日 下午9:52:46
 */
@SpringBootApplication
@EnableDubbo
public class DubboConsumerApplication {
    public static void main(String[] args) {
        SpringApplication.run(DubboConsumerApplication.class, args);
    }
}
