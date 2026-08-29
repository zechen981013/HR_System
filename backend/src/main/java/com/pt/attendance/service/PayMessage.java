package com.pt.attendance.service;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;

import java.time.LocalDateTime;
import java.util.UUID;

/**
 * 发工资消息（生产->队列->消费）
 */
@JsonIgnoreProperties(ignoreUnknown = true)
public class PayMessage {

    private String messageId;
    private Long salaryRecordId;
    private Long employeeId;
    private String employeeName;
    private Double netSalary;
    private boolean simulate;
    private LocalDateTime createdAt;

    public PayMessage() {
    }

    public PayMessage(Long salaryRecordId, Long employeeId, String employeeName, Double netSalary, boolean simulate) {
        this.messageId = UUID.randomUUID().toString();
        this.salaryRecordId = salaryRecordId;
        this.employeeId = employeeId;
        this.employeeName = employeeName;
        this.netSalary = netSalary;
        this.simulate = simulate;
        this.createdAt = LocalDateTime.now();
    }

    public String getMessageId() {
        return messageId;
    }

    public void setMessageId(String messageId) {
        this.messageId = messageId;
    }

    public Long getSalaryRecordId() {
        return salaryRecordId;
    }

    public void setSalaryRecordId(Long salaryRecordId) {
        this.salaryRecordId = salaryRecordId;
    }

    public Long getEmployeeId() {
        return employeeId;
    }

    public void setEmployeeId(Long employeeId) {
        this.employeeId = employeeId;
    }

    public String getEmployeeName() {
        return employeeName;
    }

    public void setEmployeeName(String employeeName) {
        this.employeeName = employeeName;
    }

    public Double getNetSalary() {
        return netSalary;
    }

    public void setNetSalary(Double netSalary) {
        this.netSalary = netSalary;
    }

    public boolean isSimulate() {
        return simulate;
    }

    public void setSimulate(boolean simulate) {
        this.simulate = simulate;
    }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }
}
