package com.pt.attendance.config;

import org.springframework.amqp.core.Binding;
import org.springframework.amqp.core.BindingBuilder;
import org.springframework.amqp.core.DirectExchange;
import org.springframework.amqp.core.Queue;
import org.springframework.amqp.support.converter.Jackson2JsonMessageConverter;
import org.springframework.amqp.support.converter.MessageConverter;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/**
 * RabbitMQ 配置：发工资队列（削峰填谷）
 */
@Configuration
public class RabbitConfig {

    public static final String SALARY_QUEUE = "pt.salary.pay.queue";
    public static final String SALARY_EXCHANGE = "pt.salary.exchange";
    public static final String SALARY_ROUTING_KEY = "pt.salary.pay";

    @Bean
    public Queue salaryQueue() {
        return new Queue(SALARY_QUEUE, true);
    }

    @Bean
    public DirectExchange salaryExchange() {
        return new DirectExchange(SALARY_EXCHANGE, true, false);
    }

    @Bean
    public Binding salaryBinding(Queue salaryQueue, DirectExchange salaryExchange) {
        return BindingBuilder.bind(salaryQueue).to(salaryExchange).with(SALARY_ROUTING_KEY);
    }

    @Bean
    public MessageConverter jacksonMessageConverter() {
        return new Jackson2JsonMessageConverter();
    }
}
