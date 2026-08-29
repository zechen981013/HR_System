package com.pt.attendance.service;

import com.pt.attendance.dto.SalaryRecordDTO;
import com.pt.attendance.dto.SalaryStatisticsDTO;
import com.pt.attendance.entity.*;
import com.pt.attendance.repository.*;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.time.YearMonth;
import java.util.*;
import java.util.stream.Collectors;

/**
 * 工资计算服务
 * <p>
 * 规则：
 * 1. 固定薪水(FIXED)：日薪 = 底薪/21.75，时薪 = 日薪/8
 *    - 迟到/早退：按时薪按分钟扣款
 *    - 请假：扣 1 天(8小时)工资
 *    - 缺勤(旷工)：扣 3 倍日薪
 * 2. 销售(SALES)：底薪 + 提成，销售额 <10万 提成3%，>=10万 提成5%
 * 3. 个税：应发 - 起征点5000 - 五险一金 后按月度超额累进税率计算
 */
@Service
public class SalaryService {

    private final EmployeeRepository employeeRepository;
    private final DepartmentRepository departmentRepository;
    private final AttendanceRecordRepository attendanceRecordRepository;
    private final SalesRecordRepository salesRecordRepository;
    private final SalaryRecordRepository salaryRecordRepository;
    private final TaxCalculator taxCalculator;

    @Value("${app.tax.threshold:5000}")
    private double taxThreshold;

    @Value("${app.tax.social-insurance-rate:0.2}")
    private double socialInsuranceRate;

    public SalaryService(EmployeeRepository employeeRepository,
                         DepartmentRepository departmentRepository,
                         AttendanceRecordRepository attendanceRecordRepository,
                         SalesRecordRepository salesRecordRepository,
                         SalaryRecordRepository salaryRecordRepository,
                         TaxCalculator taxCalculator) {
        this.employeeRepository = employeeRepository;
        this.departmentRepository = departmentRepository;
        this.attendanceRecordRepository = attendanceRecordRepository;
        this.salesRecordRepository = salesRecordRepository;
        this.salaryRecordRepository = salaryRecordRepository;
        this.taxCalculator = taxCalculator;
    }

    /**
     * 计算指定月份全部员工工资并保存
     *
     * @return 生成/更新的工资记录数
     */
    @Transactional
    public int calculate(int year, int month) {
        YearMonth ym = YearMonth.of(year, month);
        LocalDate start = ym.atDay(1);
        LocalDate end = ym.atEndOfMonth();
        String statMonth = String.format("%04d-%02d", year, month);

        Map<Long, List<AttendanceRecord>> attMap = attendanceRecordRepository
                .findByAttendanceDateBetween(start, end).stream()
                .collect(Collectors.groupingBy(AttendanceRecord::getEmployeeId));
        Map<Long, SalesRecord> salesMap = salesRecordRepository.findByStatMonth(statMonth).stream()
                .collect(Collectors.toMap(SalesRecord::getEmployeeId, s -> s));

        int count = 0;
        for (Employee emp : employeeRepository.findAllByOrderByDepartmentIdAscIdAsc()) {
            BigDecimal base = emp.getBaseSalary() != null ? emp.getBaseSalary() : BigDecimal.ZERO;
            List<AttendanceRecord> records = attMap.getOrDefault(emp.getId(), Collections.emptyList());
            SalaryRecord rec = calcOne(emp, base, records, salesMap.get(emp.getId()), year, month);

            Optional<SalaryRecord> exist = salaryRecordRepository.findByEmployeeIdAndYearAndMonth(emp.getId(), year, month);
            if (exist.isPresent()) {
                rec.setId(exist.get().getId());
            }
            salaryRecordRepository.save(rec);
            count++;
        }
        return count;
    }

    /**
     * 计算单个员工工资
     */
    private SalaryRecord calcOne(Employee emp, BigDecimal base, List<AttendanceRecord> records,
                                 SalesRecord sales, int year, int month) {
        SalaryRecord rec = new SalaryRecord();
        rec.setEmployeeId(emp.getId());
        rec.setYear(year);
        rec.setMonth(month);
        rec.setBaseSalary(base);

        BigDecimal gross;
        if ("SALES".equals(emp.getSalaryType())) {
            // 底薪 + 提成
            BigDecimal commission = BigDecimal.ZERO;
            if (sales != null && sales.getAmount() != null) {
                double amt = sales.getAmount().doubleValue();
                double rate = amt >= 100000 ? 0.05 : 0.03;
                commission = BigDecimal.valueOf(amt * rate).setScale(2, RoundingMode.HALF_UP);
            }
            rec.setCommission(commission);
            gross = base.add(rec.getCommission());
            rec.setAttendanceDeduction(BigDecimal.ZERO);
        } else {
            // 固定薪水：按考勤扣款
            BigDecimal deduction = attendanceDeduction(base, records);
            rec.setAttendanceDeduction(deduction);
            gross = base.subtract(deduction).max(BigDecimal.ZERO);
            rec.setCommission(BigDecimal.ZERO);
        }
        rec.setGrossSalary(gross);

        // 五险一金 + 个税
        BigDecimal social = gross.multiply(BigDecimal.valueOf(socialInsuranceRate)).setScale(2, RoundingMode.HALF_UP);
        BigDecimal taxable = gross.subtract(BigDecimal.valueOf(taxThreshold)).subtract(social).max(BigDecimal.ZERO);
        BigDecimal tax = taxCalculator.compute(taxable);

        rec.setSocialInsurance(social);
        rec.setTax(tax);
        rec.setNetSalary(gross.subtract(social).subtract(tax).setScale(2, RoundingMode.HALF_UP));
        rec.setStatus("待发放");
        return rec;
    }

    /**
     * 考勤扣款：日薪 = 底薪/21.75，时薪 = 日薪/8
     */
    private BigDecimal attendanceDeduction(BigDecimal base, List<AttendanceRecord> records) {
        BigDecimal daily = base.divide(BigDecimal.valueOf(21.75), 4, RoundingMode.HALF_UP);
        BigDecimal hourly = daily.divide(BigDecimal.valueOf(8), 4, RoundingMode.HALF_UP);
        BigDecimal deduction = BigDecimal.ZERO;

        for (AttendanceRecord r : records) {
            String status = r.getStatus();
            if (status == null) {
                continue;
            }
            switch (status) {
                case "迟到":
                    deduction = deduction.add(minutesPenalty(hourly, lateMinutes(r)));
                    break;
                case "早退":
                    deduction = deduction.add(minutesPenalty(hourly, earlyMinutes(r)));
                    break;
                case "迟到早退":
                    deduction = deduction.add(minutesPenalty(hourly, lateMinutes(r)));
                    deduction = deduction.add(minutesPenalty(hourly, earlyMinutes(r)));
                    break;
                case "请假":
                    // 请假按比例扣 8 小时的钱（1 天）
                    deduction = deduction.add(daily);
                    break;
                case "缺勤":
                    // 旷工按 3 倍扣钱
                    deduction = deduction.add(daily.multiply(BigDecimal.valueOf(3)));
                    break;
                default:
                    break;
            }
        }
        return deduction.setScale(2, RoundingMode.HALF_UP);
    }

    private int lateMinutes(AttendanceRecord r) {
        if (r.getCheckInTime() == null) {
            return 0;
        }
        int late = r.getCheckInTime().toSecondOfDay() - 8 * 3600 - 30 * 60;
        return Math.max(late, 0) / 60;
    }

    private int earlyMinutes(AttendanceRecord r) {
        if (r.getCheckOutTime() == null) {
            return 0;
        }
        int early = 18 * 3600 - r.getCheckOutTime().toSecondOfDay();
        return Math.max(early, 0) / 60;
    }

    private BigDecimal minutesPenalty(BigDecimal hourly, int minutes) {
        return hourly.multiply(BigDecimal.valueOf(minutes)).divide(BigDecimal.valueOf(60), 2, RoundingMode.HALF_UP);
    }

    /**
     * 查询指定月份工资列表
     */
    public List<SalaryRecordDTO> list(int year, int month) {
        Map<Long, Employee> empMap = employeeRepository.findAll().stream()
                .collect(Collectors.toMap(Employee::getId, e -> e));
        Map<Long, String> deptMap = departmentRepository.findAll().stream()
                .collect(Collectors.toMap(Department::getId, Department::getName));

        return salaryRecordRepository.findByYearAndMonth(year, month).stream()
                .map(rec -> toDTO(rec, empMap, deptMap))
                .collect(Collectors.toList());
    }

    private SalaryRecordDTO toDTO(SalaryRecord rec, Map<Long, Employee> empMap, Map<Long, String> deptMap) {
        SalaryRecordDTO dto = new SalaryRecordDTO();
        dto.setId(rec.getId());
        dto.setEmployeeId(rec.getEmployeeId());
        dto.setBaseSalary(rec.getBaseSalary());
        dto.setAttendanceDeduction(rec.getAttendanceDeduction());
        dto.setCommission(rec.getCommission());
        dto.setGrossSalary(rec.getGrossSalary());
        dto.setSocialInsurance(rec.getSocialInsurance());
        dto.setTax(rec.getTax());
        dto.setNetSalary(rec.getNetSalary());
        dto.setStatus(rec.getStatus());
        dto.setPayDate(rec.getPayDate());
        dto.setRemark(rec.getRemark());
        Employee emp = empMap.get(rec.getEmployeeId());
        if (emp != null) {
            dto.setName(emp.getName());
            dto.setPosition(emp.getPosition());
            dto.setSalaryType(emp.getSalaryType());
            dto.setDepartmentName(deptMap.getOrDefault(emp.getDepartmentId(), ""));
        }
        return dto;
    }

    /**
     * 工资统计
     */
    public SalaryStatisticsDTO statistics(int year, int month) {
        SalaryStatisticsDTO stat = new SalaryStatisticsDTO();
        stat.setYear(year);
        stat.setMonth(month);

        List<SalaryRecordDTO> list = list(year, month);
        if (list.isEmpty()) {
            stat.setDeptStats(Collections.emptyList());
            return stat;
        }

        double totalGross = 0, totalNet = 0, totalTax = 0, totalSocial = 0;
        Map<String, List<SalaryRecordDTO>> byDept = new LinkedHashMap<>();
        for (SalaryRecordDTO dto : list) {
            totalGross += dto.getGrossSalary().doubleValue();
            totalNet += dto.getNetSalary().doubleValue();
            totalTax += dto.getTax().doubleValue();
            totalSocial += dto.getSocialInsurance().doubleValue();
            byDept.computeIfAbsent(dto.getDepartmentName(), k -> new ArrayList<>()).add(dto);
        }
        stat.setTotalGross(round2(totalGross));
        stat.setTotalNet(round2(totalNet));
        stat.setTotalTax(round2(totalTax));
        stat.setTotalSocial(round2(totalSocial));
        stat.setEmployeeCount(list.size());

        List<SalaryStatisticsDTO.DeptStat> deptStats = new ArrayList<>();
        for (Map.Entry<String, List<SalaryRecordDTO>> e : byDept.entrySet()) {
            SalaryStatisticsDTO.DeptStat ds = new SalaryStatisticsDTO.DeptStat();
            ds.setDepartment(e.getKey());
            ds.setCount(e.getValue().size());
            double sumGross = e.getValue().stream().mapToDouble(d -> d.getGrossSalary().doubleValue()).sum();
            double sumNet = e.getValue().stream().mapToDouble(d -> d.getNetSalary().doubleValue()).sum();
            ds.setAvgGross(round2(sumGross / e.getValue().size()));
            ds.setAvgNet(round2(sumNet / e.getValue().size()));
            ds.setTotalNet(round2(sumNet));
            deptStats.add(ds);
        }
        stat.setDeptStats(deptStats);
        return stat;
    }

    private double round2(double v) {
        return Math.round(v * 100.0) / 100.0;
    }
}
