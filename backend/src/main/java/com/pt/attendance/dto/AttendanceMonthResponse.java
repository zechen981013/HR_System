package com.pt.attendance.dto;

import java.util.List;

/**
 * 月度考勤响应
 */
public class AttendanceMonthResponse {

    private int year;
    private int month;
    private String workStart;
    private String workEnd;
    private List<EmployeeAttendanceDTO> employees;

    public int getYear() {
        return year;
    }

    public void setYear(int year) {
        this.year = year;
    }

    public int getMonth() {
        return month;
    }

    public void setMonth(int month) {
        this.month = month;
    }

    public String getWorkStart() {
        return workStart;
    }

    public void setWorkStart(String workStart) {
        this.workStart = workStart;
    }

    public String getWorkEnd() {
        return workEnd;
    }

    public void setWorkEnd(String workEnd) {
        this.workEnd = workEnd;
    }

    public List<EmployeeAttendanceDTO> getEmployees() {
        return employees;
    }

    public void setEmployees(List<EmployeeAttendanceDTO> employees) {
        this.employees = employees;
    }
}
