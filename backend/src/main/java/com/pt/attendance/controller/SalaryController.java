package com.pt.attendance.controller;

import com.pt.attendance.dto.ApiResult;
import com.pt.attendance.dto.PayRequestDTO;
import com.pt.attendance.dto.SalaryRecordDTO;
import com.pt.attendance.dto.SalaryStatisticsDTO;
import com.pt.attendance.entity.Department;
import com.pt.attendance.entity.Employee;
import com.pt.attendance.repository.DepartmentRepository;
import com.pt.attendance.repository.EmployeeRepository;
import com.pt.attendance.service.PayService;
import com.pt.attendance.service.SalaryService;
import com.pt.attendance.service.TokenService;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * 工资管理接口（仅财务部可访问）
 */
@RestController
@RequestMapping("/api/salary")
public class SalaryController {

    private final SalaryService salaryService;
    private final PayService payService;
    private final TokenService tokenService;
    private final EmployeeRepository employeeRepository;
    private final DepartmentRepository departmentRepository;

    public SalaryController(SalaryService salaryService,
                            PayService payService,
                            TokenService tokenService,
                            EmployeeRepository employeeRepository,
                            DepartmentRepository departmentRepository) {
        this.salaryService = salaryService;
        this.payService = payService;
        this.tokenService = tokenService;
        this.employeeRepository = employeeRepository;
        this.departmentRepository = departmentRepository;
    }

    /**
     * 计算某月工资并入库
     */
    @PostMapping("/calculate")
    public ApiResult<Map<String, Object>> calculate(@RequestParam(defaultValue = "2026") int year,
                                                    @RequestParam(defaultValue = "7") int month,
                                                    HttpServletRequest request) {
        if (requireFinance(request) == null) {
            return ApiResult.error(403, "仅财务部可操作工资");
        }
        int count = salaryService.calculate(year, month);
        Map<String, Object> data = new HashMap<>();
        data.put("count", count);
        return ApiResult.ok(data);
    }

    /**
     * 工资列表
     */
    @GetMapping("/list")
    public ApiResult<List<SalaryRecordDTO>> list(@RequestParam(defaultValue = "2026") int year,
                                                 @RequestParam(defaultValue = "7") int month,
                                                 HttpServletRequest request) {
        if (requireFinance(request) == null) {
            return ApiResult.error(403, "仅财务部可操作工资");
        }
        return ApiResult.ok(salaryService.list(year, month));
    }

    /**
     * 工资统计（总额 / 分部门平均值，供饼图、折线图使用）
     */
    @GetMapping("/statistics")
    public ApiResult<SalaryStatisticsDTO> statistics(@RequestParam(defaultValue = "2026") int year,
                                                     @RequestParam(defaultValue = "7") int month,
                                                     HttpServletRequest request) {
        if (requireFinance(request) == null) {
            return ApiResult.error(403, "仅财务部可操作工资");
        }
        return ApiResult.ok(salaryService.statistics(year, month));
    }

    /**
     * 发工资：单个或批量（全部投递到 RabbitMQ 队列，消费者异步处理）
     */
    @PostMapping("/pay")
    public ApiResult<Map<String, Object>> pay(@RequestBody PayRequestDTO req, HttpServletRequest request) {
        if (requireFinance(request) == null) {
            return ApiResult.error(403, "仅财务部可操作工资");
        }
        if (req.getIds() == null || req.getIds().isEmpty()) {
            return ApiResult.error(400, "请选择要发放的工资单");
        }
        int sent = payService.pay(req.getIds());
        Map<String, Object> data = new HashMap<>();
        data.put("sent", sent);
        data.put("total", req.getIds().size());
        data.put("message", "已投递 " + sent + " 条发放请求到消息队列，请稍后刷新查看发放结果");
        return ApiResult.ok(data);
    }

    /**
     * 模拟高并发发工资（如 20000 人同时提交），验证 RabbitMQ 削峰填谷
     */
    @PostMapping("/pay/simulate")
    public ApiResult<Map<String, Object>> simulate(@RequestParam(defaultValue = "20000") int count,
                                                   HttpServletRequest request) {
        if (requireFinance(request) == null) {
            return ApiResult.error(403, "仅财务部可操作工资");
        }
        int sent = payService.simulate(count);
        Map<String, Object> data = new HashMap<>();
        data.put("sent", sent);
        data.put("message", "已向队列投递 " + sent + " 条模拟发放请求，消费者将按自身能力逐条消费（削峰填谷）");
        return ApiResult.ok(data);
    }

    /**
     * 校验当前登录用户是否为财务部
     */
    private Employee requireFinance(HttpServletRequest request) {
        String authorization = request.getHeader("Authorization");
        if (authorization == null || !authorization.startsWith("Bearer ")) {
            return null;
        }
        Long employeeId = tokenService.getEmployeeId(authorization.substring(7));
        if (employeeId == null) {
            return null;
        }
        Employee emp = employeeRepository.findById(employeeId).orElse(null);
        if (emp == null) {
            return null;
        }
        Department dept = departmentRepository.findById(emp.getDepartmentId()).orElse(null);
        if (dept == null || !"财务部".equals(dept.getName())) {
            return null;
        }
        return emp;
    }
}
