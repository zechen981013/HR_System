package com.pt.attendance.mq;

import com.pt.attendance.config.RabbitConfig;
import com.pt.attendance.entity.SalaryRecord;
import com.pt.attendance.repository.SalaryRecordRepository;
import com.pt.attendance.service.PayMessage;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.amqp.rabbit.annotation.RabbitListener;
import org.springframework.stereotype.Component;

import java.time.LocalDateTime;
import java.util.Optional;

/**
 * 发工资消费者：从队列按自身能力取消息处理（concurrency=1, prefetch=1）
 */
@Component
public class SalaryPayConsumer {

    private static final Logger log = LoggerFactory.getLogger(SalaryPayConsumer.class);

    private final SalaryRecordRepository salaryRecordRepository;

    public SalaryPayConsumer(SalaryRecordRepository salaryRecordRepository) {
        this.salaryRecordRepository = salaryRecordRepository;
    }

    @RabbitListener(queues = RabbitConfig.SALARY_QUEUE, concurrency = "1")
    public void onMessage(PayMessage message) throws InterruptedException {
        // 模拟银行/第三方打款耗时，体现消费者按自己能力消费 => 队列削峰填谷
        Thread.sleep(30);

        if (message.isSimulate()) {
            log.info("[模拟发放] {} 处理完成", message.getEmployeeName());
            return;
        }

        Optional<SalaryRecord> optional = salaryRecordRepository.findById(message.getSalaryRecordId());
        if (optional.isEmpty()) {
            log.warn("[发放] 工资记录不存在: {}", message.getSalaryRecordId());
            return;
        }
        SalaryRecord rec = optional.get();
        try {
            rec.setStatus("已发放");
            rec.setPayDate(LocalDateTime.now());
            salaryRecordRepository.save(rec);
            log.info("[发放成功] 工资单={} 金额={} 元, 消息={}", message.getSalaryRecordId(), message.getNetSalary(), message.getMessageId());
        } catch (Exception e) {
            rec.setStatus("发放失败");
            rec.setRemark(e.getMessage());
            salaryRecordRepository.save(rec);
            log.error("[发放失败] 工资单={}", message.getSalaryRecordId(), e);
        }
    }
}
