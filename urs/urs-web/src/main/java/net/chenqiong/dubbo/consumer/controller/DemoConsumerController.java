package net.chenqiong.dubbo.consumer.controller;

import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.alibaba.dubbo.config.annotation.Reference;

import net.chenqiong.dubbo.api.service.DemoService;

/**
 * @ClassName: DemoConsumerController
 * @Description: 消费者控制层,访问地址：http://localhost:9091/sayHello/HelloWorld
 * @author: 陈琼
 * @date: 2019年1月3日 下午6:10:43
 */
@RestController
public class DemoConsumerController {

	@Reference(version = "${demo.service.version}")
	private DemoService demoService;

	@RequestMapping("/sayHello/{name}")
	public String sayHello(@PathVariable("name") String name) {
		return demoService.sayHello(name);
	}
}
