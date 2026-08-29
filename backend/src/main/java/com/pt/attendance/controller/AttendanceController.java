package com.pt.attendance.controller;

import com.pt.attendance.dto.ApiResult;
import com.pt.attendance.dto.AttendanceMonthResponse;
import com.pt.attendance.dto.DayRecordDTO;
import com.pt.attendance.dto.EmployeeAttendanceDTO;
import com.pt.attendance.entity.AttendanceRecord;
import com.pt.attendance.entity.Department;
import com.pt.attendance.entity.Employee;
import com.pt.attendance.repository.AttendanceRecordRepository;
import com.pt.attendance.repository.DepartmentRepository;
import com.pt.attendance.repository.EmployeeRepository;
import com.pt.attendance.repository.SalesRecordRepository;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.time.LocalDate;
import java.time.YearMonth;
import java.util.*;
import java.util.stream.Collectors;

/**
 * 考勤查询接口
 */
@RestController
@RequestMapping("/api/attendance")
public class AttendanceController {

    private final EmployeeRepository employeeRepository;
    private final DepartmentRepository departmentRepository;
    private final AttendanceRecordRepository attendanceRecordRepository;
    private final SalesRecordRepository salesRecordRepository;

    @Value("${app.work-start}")
    private String workStart;

    @Value("${app.work-end}")
    private String workEnd;

    public AttendanceController(EmployeeRepository employeeRepository,
                                DepartmentRepository departmentRepository,
                                AttendanceRecordRepository attendanceRecordRepository,
                                SalesRecordRepository salesRecordRepository) {
        this.employeeRepository = employeeRepository;
        this.departmentRepository = departmentRepository;
        this.attendanceRecordRepository = attendanceRecordRepository;
        this.salesRecordRepository = salesRecordRepository;
    }

    /**
     * 查询指定月份全部员工考勤
     */
    @GetMapping("/month")
    public ApiResult<AttendanceMonthResponse> month(@RequestParam(defaultValue = "2026") int year,
                                                    @RequestParam(defaultValue = "7") int month) {
        YearMonth ym = YearMonth.of(year, month);
        LocalDate start = ym.atDay(1);
        LocalDate end = ym.atEndOfMonth();
        String statMonth = String.format("%04d-%02d", year, month);

        Map<Long, Department> deptMap = departmentRepository.findAll().stream()
                .collect(Collectors.toMap(Department::getId, d -> d));
        Map<Long, Double> monthlySales = salesRecordRepository.findByStatMonth(statMonth).stream()
                .collect(Collectors.toMap(s -> s.getEmployeeId(), s -> s.getAmount().doubleValue()));
        Map<Long, List<AttendanceRecord>> recordMap = attendanceRecordRepository
                .findByAttendanceDateBetween(start, end)
                .stream()
                .collect(Collectors.groupingBy(AttendanceRecord::getEmployeeId));

        List<EmployeeAttendanceDTO> list = new ArrayList<>();
        for (Employee emp : employeeRepository.findAllByOrderByDepartmentIdAscIdAsc()) {
            EmployeeAttendanceDTO dto = new EmployeeAttendanceDTO();
            dto.setEmployeeId(emp.getId());
            dto.setName(emp.getName());
            dto.setPosition(emp.getPosition());
            dto.setGender(emp.getGender() != null && emp.getGender() == 2 ? "女" : "男");
            dto.setSalaryType(emp.getSalaryType());
            dto.setBaseSalary(emp.getBaseSalary() != null ? emp.getBaseSalary().doubleValue() : 0.0);
            dto.setMonthlySales(monthlySales.getOrDefault(emp.getId(), 0.0));
            Department dept = deptMap.get(emp.getDepartmentId());
            dto.setDepartmentName(dept != null ? dept.getName() : "");

            Map<LocalDate, AttendanceRecord> dayMap = recordMap.getOrDefault(emp.getId(), Collections.emptyList())
                    .stream()
                    .collect(Collectors.toMap(AttendanceRecord::getAttendanceDate, r -> r));

            List<DayRecordDTO> records = new ArrayList<>();
            for (int day = 1; day <= ym.lengthOfMonth(); day++) {
                LocalDate date = ym.atDay(day);
                DayRecordDTO dayDto = new DayRecordDTO();
                dayDto.setDate(date);
                AttendanceRecord rec = dayMap.get(date);
                if (rec != null) {
                    dayDto.setWeekday(rec.getWeekday());
                    dayDto.setCheckInTime(rec.getCheckInTime());
                    dayDto.setCheckOutTime(rec.getCheckOutTime());
                    dayDto.setStatus(rec.getStatus());
                    dayDto.setWorkHours(rec.getWorkHours() != null ? rec.getWorkHours().doubleValue() : 0.0);
                    dayDto.setRemark(rec.getRemark());
                } else {
                    dayDto.setStatus("无记录");
                    dayDto.setWorkHours(0.0);
                }
                records.add(dayDto);
            }
            dto.setRecords(records);
            list.add(dto);
        }

        AttendanceMonthResponse resp = new AttendanceMonthResponse();
        resp.setYear(year);
        resp.setMonth(month);
        resp.setWorkStart(workStart);
        resp.setWorkEnd(workEnd);
        resp.setEmployees(list);
        return ApiResult.ok(resp);
    }
}
