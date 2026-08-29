package com.pt.attendance.service;

import com.pt.attendance.config.RabbitConfig;
import com.pt.attendance.entity.SalaryRecord;
import com.pt.attendance.repository.SalaryRecordRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.amqp.rabbit.core.RabbitTemplate;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Optional;

/**
 * 发工资服务（生产者）：把发放请求写入 RabbitMQ 队列，削峰填谷
 */
@Service
public class PayService {

    private static final Logger log = LoggerFactory.getLogger(PayService.class);

    private final RabbitTemplate rabbitTemplate;
    private final SalaryRecordRepository salaryRecordRepository;

    public PayService(RabbitTemplate rabbitTemplate, SalaryRecordRepository salaryRecordRepository) {
        this.rabbitTemplate = rabbitTemplate;
        this.salaryRecordRepository = salaryRecordRepository;
    }

    /**
     * 发放指定工资记录（单个或批量），全部投递到消息队列
     *
     * @return 成功投递数量
     */
    public int pay(List<Long> ids) {
        int sent = 0;
        for (Long id : ids) {
            Optional<SalaryRecord> optional = salaryRecordRepository.findById(id);
            if (optional.isEmpty()) {
                continue;
            }
            SalaryRecord rec = optional.get();
            // 仅待发放的可发起，预置"发放中"防止重复提交（乐观锁）
            if (!"待发放".equals(rec.getStatus())) {
                continue;
            }
            rec.setStatus("发放中");
            salaryRecordRepository.save(rec);

            PayMessage msg = new PayMessage(rec.getId(), rec.getEmployeeId(), null,
                    rec.getNetSalary().doubleValue(), false);
            rabbitTemplate.convertAndSend(RabbitConfig.SALARY_EXCHANGE, RabbitConfig.SALARY_ROUTING_KEY, msg);
            sent++;
        }
        return sent;
    }

    /**
     * 模拟高并发发工资：一次性向队列投递 count 条消息，
     * 消费者按自身能力一条条消费（削峰填谷）。
     */
    public int simulate(int count) {
        int sent = 0;
        for (int i = 1; i <= count; i++) {
            PayMessage msg = new PayMessage(null, null, "模拟员工-" + i, 0.0, true);
            rabbitTemplate.convertAndSend(RabbitConfig.SALARY_EXCHANGE, RabbitConfig.SALARY_ROUTING_KEY, msg);
            sent++;
        }
        log.info("已向队列投递 {} 条模拟发放消息", sent);
        return sent;
    }
}
