package net.chenqiong.dubbo.provider;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

import com.alibaba.dubbo.config.spring.context.annotation.EnableDubbo;

/**
 * @ClassName: DubboProviderApplication
 * @Description: 服务提供启动类
 * @author: 陈琼
 * @date: 2019年1月3日 下午10:19:25
 */
@SpringBootApplication
@EnableDubbo
public class DubboProviderApplication {

    public static void main(String[] args) {
        SpringApplication.run(DubboProviderApplication.class, args);
    }
}
