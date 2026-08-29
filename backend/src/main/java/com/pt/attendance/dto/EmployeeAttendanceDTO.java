package com.pt.attendance.dto;

import java.util.List;

/**
 * 一名员工整月考勤汇总
 */
public class EmployeeAttendanceDTO {

    private Long employeeId;
    private String name;
    private String departmentName;
    private String position;
    private String gender;
    private String salaryType;
    private Double baseSalary;
    private Double monthlySales;
    private List<DayRecordDTO> records;

    public Long getEmployeeId() {
        return employeeId;
    }

    public void setEmployeeId(Long employeeId) {
        this.employeeId = employeeId;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public String getDepartmentName() {
        return departmentName;
    }

    public void setDepartmentName(String departmentName) {
        this.departmentName = departmentName;
    }

    public String getPosition() {
        return position;
    }

    public void setPosition(String position) {
        this.position = position;
    }

    public String getGender() {
        return gender;
    }

    public void setGender(String gender) {
        this.gender = gender;
    }

    public String getSalaryType() {
        return salaryType;
    }

    public void setSalaryType(String salaryType) {
        this.salaryType = salaryType;
    }

    public Double getBaseSalary() {
        return baseSalary;
    }

    public void setBaseSalary(Double baseSalary) {
        this.baseSalary = baseSalary;
    }

    public Double getMonthlySales() {
        return monthlySales;
    }

    public void setMonthlySales(Double monthlySales) {
        this.monthlySales = monthlySales;
    }

    public List<DayRecordDTO> getRecords() {
        return records;
    }

    public void setRecords(List<DayRecordDTO> records) {
        this.records = records;
    }
}
