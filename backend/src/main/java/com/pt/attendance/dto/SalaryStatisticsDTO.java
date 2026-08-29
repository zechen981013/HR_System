package com.pt.attendance.dto;

import java.util.List;

/**
 * 工资统计响应：总额、部门均值、饼图数据、折线图(累计工资)数据
 */
public class SalaryStatisticsDTO {

    private int year;
    private int month;
    private double totalGross;      // 应发总额
    private double totalNet;        // 实发总额
    private double totalTax;        // 个税总额
    private double totalSocial;     // 五险一金总额
    private int employeeCount;

    private List<DeptStat> deptStats;   // 分部门统计（平均值等）

    public static class DeptStat {
        private String department;
        private int count;
        private double avgGross;
        private double avgNet;
        private double totalNet;

        public String getDepartment() {
            return department;
        }

        public void setDepartment(String department) {
            this.department = department;
        }

        public int getCount() {
            return count;
        }

        public void setCount(int count) {
            this.count = count;
        }

        public double getAvgGross() {
            return avgGross;
        }

        public void setAvgGross(double avgGross) {
            this.avgGross = avgGross;
        }

        public double getAvgNet() {
            return avgNet;
        }

        public void setAvgNet(double avgNet) {
            this.avgNet = avgNet;
        }

        public double getTotalNet() {
            return totalNet;
        }

        public void setTotalNet(double totalNet) {
            this.totalNet = totalNet;
        }
    }

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

    public double getTotalGross() {
        return totalGross;
    }

    public void setTotalGross(double totalGross) {
        this.totalGross = totalGross;
    }

    public double getTotalNet() {
        return totalNet;
    }

    public void setTotalNet(double totalNet) {
        this.totalNet = totalNet;
    }

    public double getTotalTax() {
        return totalTax;
    }

    public void setTotalTax(double totalTax) {
        this.totalTax = totalTax;
    }

    public double getTotalSocial() {
        return totalSocial;
    }

    public void setTotalSocial(double totalSocial) {
        this.totalSocial = totalSocial;
    }

    public int getEmployeeCount() {
        return employeeCount;
    }

    public void setEmployeeCount(int employeeCount) {
        this.employeeCount = employeeCount;
    }

    public List<DeptStat> getDeptStats() {
        return deptStats;
    }

    public void setDeptStats(List<DeptStat> deptStats) {
        this.deptStats = deptStats;
    }
}
