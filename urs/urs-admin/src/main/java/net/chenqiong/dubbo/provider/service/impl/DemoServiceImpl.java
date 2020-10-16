package net.chenqiong.dubbo.provider.service.impl;

import com.alibaba.dubbo.config.annotation.Service;

import net.chenqiong.dubbo.api.service.DemoService;

/**
 * @ClassName: DemoServiceImpl
 * @Description: 服务提供类
 * @author: 陈琼
 * @date: 2019年1月3日 下午10:19:38
 */
@Service(version = "${demo.service.version}")
public class DemoServiceImpl implements DemoService {

	@Override
	public String sayHello(String name) {
		return "Hello, " + name + " (from your Dubbo&Zokeeper.)";
	}
}
