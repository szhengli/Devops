package net.chenqiong.dubbo.api.service;

import com.alibaba.dubbo.config.spring.context.annotation.EnableDubbo;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

/**
 * @ClassName: DubboApiApplication
 * @Description: 消费者启动类
 * @author: 陈琼
 * @date: 2019年1月3日 下午10:20:10
 */
@EnableDubbo
@SpringBootApplication
public class DubboApiApplication {

	public static void main(String[] args) {
		SpringApplication.run(DubboApiApplication.class, args);
	}
}
