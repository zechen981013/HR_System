package com.pt.attendance.controller;

import com.pt.attendance.dto.ApiResult;
import com.pt.attendance.dto.LoginRequest;
import com.pt.attendance.dto.LoginResponse;
import com.pt.attendance.entity.Department;
import com.pt.attendance.entity.Employee;
import com.pt.attendance.repository.DepartmentRepository;
import com.pt.attendance.repository.EmployeeRepository;
import com.pt.attendance.service.TokenService;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.*;

import java.util.Optional;

/**
 * 登录接口
 */
@RestController
@RequestMapping("/api/auth")
public class AuthController {

    private final EmployeeRepository employeeRepository;
    private final DepartmentRepository departmentRepository;
    private final TokenService tokenService;

    public AuthController(EmployeeRepository employeeRepository,
                          DepartmentRepository departmentRepository,
                          TokenService tokenService) {
        this.employeeRepository = employeeRepository;
        this.departmentRepository = departmentRepository;
        this.tokenService = tokenService;
    }

    @PostMapping("/login")
    public ApiResult<LoginResponse> login(@Valid @RequestBody LoginRequest request) {
        Optional<Employee> optional = employeeRepository.findByUsername(request.getUsername().trim());
        if (optional.isEmpty()) {
            return ApiResult.error(401, "用户名或密码错误");
        }
        Employee emp = optional.get();
        if (!emp.getPassword().equals(request.getPassword())) {
            return ApiResult.error(401, "用户名或密码错误");
        }

        LoginResponse resp = new LoginResponse();
        resp.setToken(tokenService.createToken(emp.getId()));
        resp.setEmployeeId(emp.getId());
        resp.setUsername(emp.getUsername());
        resp.setName(emp.getName());
        resp.setPosition(emp.getPosition());
        departmentRepository.findById(emp.getDepartmentId())
                .map(Department::getName)
                .ifPresent(resp::setDepartmentName);
        return ApiResult.ok(resp);
    }

    @PostMapping("/logout")
    public ApiResult<Void> logout(@RequestHeader(value = "Authorization", required = false) String authorization) {
        if (authorization != null && authorization.startsWith("Bearer ")) {
            tokenService.removeToken(authorization.substring(7));
        }
        return ApiResult.ok(null);
    }
}
