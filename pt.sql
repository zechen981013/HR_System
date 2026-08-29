-- ============================================================
-- 员工考勤系统 初始化脚本 (pt.sql)
-- 数据库: MySQL 8.4   默认班次: 08:30 上班 / 18:00 下班
-- 数据: 3 个部门、21 名员工、2026 年 7 月全月考勤
-- 执行方式: mysql -uroot -p < pt.sql
-- ============================================================

CREATE DATABASE IF NOT EXISTS pt DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE pt;

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- ---------------------------- 部门表 ----------------------------
DROP TABLE IF EXISTS salary_record;
DROP TABLE IF EXISTS sales_record;
DROP TABLE IF EXISTS attendance_record;
DROP TABLE IF EXISTS employee;
DROP TABLE IF EXISTS department;

CREATE TABLE department (
  id          BIGINT       NOT NULL AUTO_INCREMENT COMMENT '部门ID',
  name        VARCHAR(50)  NOT NULL COMMENT '部门名称',
  description VARCHAR(200) DEFAULT NULL COMMENT '部门描述',
  created_at  DATETIME     DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  PRIMARY KEY (id),
  UNIQUE KEY uk_dept_name (name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='部门表';


CREATE TABLE employee (
  id            BIGINT       NOT NULL AUTO_INCREMENT COMMENT '员工ID',
  username      VARCHAR(50)  NOT NULL COMMENT '登录用户名',
  password      VARCHAR(100) NOT NULL COMMENT '登录密码(默认123456)',
  name          VARCHAR(50)  NOT NULL COMMENT '姓名',
  gender        TINYINT      DEFAULT NULL COMMENT '性别: 1男 2女',
  department_id BIGINT       NOT NULL COMMENT '所属部门ID',
  position      VARCHAR(50)  DEFAULT NULL COMMENT '职位',
  phone         VARCHAR(20)  DEFAULT NULL COMMENT '联系电话',
  hire_date     DATE         DEFAULT NULL COMMENT '入职日期',
  salary_type   VARCHAR(10)  NOT NULL DEFAULT 'FIXED' COMMENT '薪资类型: FIXED固定薪水 / SALES底薪+提成',
  base_salary   DECIMAL(10,2) DEFAULT 0 COMMENT '月基本工资(固定薪水/销售底薪, 元)',
  created_at    DATETIME     DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  PRIMARY KEY (id),
  UNIQUE KEY uk_emp_username (username),
  KEY idx_emp_dept (department_id),
  CONSTRAINT fk_emp_dept FOREIGN KEY (department_id) REFERENCES department (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='员工表';


CREATE TABLE attendance_record (
  id              BIGINT       NOT NULL AUTO_INCREMENT COMMENT '记录ID',
  employee_id     BIGINT       NOT NULL COMMENT '员工ID',
  attendance_date DATE         NOT NULL COMMENT '考勤日期',
  weekday         VARCHAR(10)  DEFAULT NULL COMMENT '星期几',
  check_in_time   TIME         DEFAULT NULL COMMENT '上班打卡时间',
  check_out_time  TIME         DEFAULT NULL COMMENT '下班打卡时间',
  status          VARCHAR(20)  NOT NULL DEFAULT '正常' COMMENT '考勤状态: 正常/迟到/早退/迟到早退/请假/缺勤/休息',
  work_hours      DECIMAL(4,1) DEFAULT 0 COMMENT '实际工作时长(小时,扣除1小时午休)',
  remark          VARCHAR(200) DEFAULT NULL COMMENT '备注',
  created_at      DATETIME     DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  PRIMARY KEY (id),
  UNIQUE KEY uk_emp_date (employee_id, attendance_date),
  KEY idx_att_date (attendance_date),
  CONSTRAINT fk_att_emp FOREIGN KEY (employee_id) REFERENCES employee (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='考勤记录表';


CREATE TABLE sales_record (
  id          BIGINT        NOT NULL AUTO_INCREMENT COMMENT '记录ID',
  employee_id BIGINT        NOT NULL COMMENT '员工ID',
  stat_month  VARCHAR(7)    NOT NULL COMMENT '统计月份(如 2026-07)',
  amount      DECIMAL(12,2) NOT NULL COMMENT '当月销售额(元)',
  created_at  DATETIME      DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  PRIMARY KEY (id),
  UNIQUE KEY uk_sales_emp_month (employee_id, stat_month),
  CONSTRAINT fk_sales_emp FOREIGN KEY (employee_id) REFERENCES employee (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='销售业绩表';


CREATE TABLE salary_record (
  id                   BIGINT        NOT NULL AUTO_INCREMENT COMMENT '记录ID',
  employee_id          BIGINT        NOT NULL COMMENT '员工ID',
  year                 INT           NOT NULL COMMENT '年份',
  month                INT           NOT NULL COMMENT '月份',
  base_salary          DECIMAL(10,2) NOT NULL DEFAULT 0 COMMENT '基本工资/底薪',
  attendance_deduction DECIMAL(10,2) NOT NULL DEFAULT 0 COMMENT '考勤扣款(迟到/请假/旷工)',
  commission           DECIMAL(10,2) NOT NULL DEFAULT 0 COMMENT '销售提成',
  gross_salary         DECIMAL(10,2) NOT NULL DEFAULT 0 COMMENT '应发工资',
  social_insurance     DECIMAL(10,2) NOT NULL DEFAULT 0 COMMENT '五险一金(个人承担)',
  tax                  DECIMAL(10,2) NOT NULL DEFAULT 0 COMMENT '个人所得税',
  net_salary           DECIMAL(10,2) NOT NULL DEFAULT 0 COMMENT '实发工资',
  status               VARCHAR(20)   NOT NULL DEFAULT '待发放' COMMENT '发放状态: 待发放/发放中/已发放/发放失败',
  pay_date             DATETIME      DEFAULT NULL COMMENT '实际发放时间',
  remark               VARCHAR(200)  DEFAULT NULL COMMENT '备注',
  created_at           DATETIME      DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  updated_at           DATETIME      DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (id),
  UNIQUE KEY uk_sal_emp_month (employee_id, year, month),
  CONSTRAINT fk_sal_emp FOREIGN KEY (employee_id) REFERENCES employee (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='工资记录表';


-- ---------------------------- 部门数据 ----------------------------
INSERT INTO department (id, name, description) VALUES (1, '财务部', '负责公司财务核算、预算与资金管理');
INSERT INTO department (id, name, description) VALUES (2, '技术部', '负责产品研发、系统开发与运维');
INSERT INTO department (id, name, description) VALUES (3, '销售部', '负责市场开拓与产品销售');

-- ---------------------------- 员工数据 (21人) ----------------------------
INSERT INTO employee (id, username, password, name, gender, department_id, position, phone, hire_date, salary_type, base_salary) VALUES (1, 'wangfang', '123456', '王芳', 2, 1, '财务经理', '13800000001', '2021-03-15', 'FIXED', 15000);
INSERT INTO employee (id, username, password, name, gender, department_id, position, phone, hire_date, salary_type, base_salary) VALUES (2, 'zhangwei', '123456', '张伟', 1, 2, '技术总监', '13800000002', '2018-06-01', 'FIXED', 25000);
INSERT INTO employee (id, username, password, name, gender, department_id, position, phone, hire_date, salary_type, base_salary) VALUES (3, 'liqiang', '123456', '李强', 1, 2, '高级开发工程师', '13800000003', '2019-02-11', 'FIXED', 18000);
INSERT INTO employee (id, username, password, name, gender, department_id, position, phone, hire_date, salary_type, base_salary) VALUES (4, 'liuyang', '123456', '刘洋', 1, 2, '高级开发工程师', '13800000004', '2020-04-20', 'FIXED', 18000);
INSERT INTO employee (id, username, password, name, gender, department_id, position, phone, hire_date, salary_type, base_salary) VALUES (5, 'chenjie', '123456', '陈杰', 1, 2, '后端开发工程师', '13800000005', '2021-08-16', 'FIXED', 15000);
INSERT INTO employee (id, username, password, name, gender, department_id, position, phone, hire_date, salary_type, base_salary) VALUES (6, 'yangfan', '123456', '杨帆', 1, 2, '前端开发工程师', '13800000006', '2022-01-10', 'FIXED', 14000);
INSERT INTO employee (id, username, password, name, gender, department_id, position, phone, hire_date, salary_type, base_salary) VALUES (7, 'zhaolei', '123456', '赵磊', 1, 2, '后端开发工程师', '13800000007', '2022-05-23', 'FIXED', 15000);
INSERT INTO employee (id, username, password, name, gender, department_id, position, phone, hire_date, salary_type, base_salary) VALUES (8, 'zhoumin', '123456', '周敏', 2, 2, '测试工程师', '13800000008', '2023-03-06', 'FIXED', 12000);
INSERT INTO employee (id, username, password, name, gender, department_id, position, phone, hire_date, salary_type, base_salary) VALUES (9, 'wuting', '123456', '吴婷', 2, 2, '产品经理', '13800000009', '2020-09-14', 'FIXED', 16000);
INSERT INTO employee (id, username, password, name, gender, department_id, position, phone, hire_date, salary_type, base_salary) VALUES (10, 'zhenghao', '123456', '郑浩', 1, 2, '运维工程师', '13800000010', '2021-11-08', 'FIXED', 14000);
INSERT INTO employee (id, username, password, name, gender, department_id, position, phone, hire_date, salary_type, base_salary) VALUES (11, 'sunlei', '123456', '孙磊', 1, 2, '前端开发工程师', '13800000011', '2023-07-17', 'FIXED', 13000);
INSERT INTO employee (id, username, password, name, gender, department_id, position, phone, hire_date, salary_type, base_salary) VALUES (12, 'fengxue', '123456', '冯雪', 2, 3, '销售经理', '13800000012', '2019-05-27', 'SALES', 8000);
INSERT INTO employee (id, username, password, name, gender, department_id, position, phone, hire_date, salary_type, base_salary) VALUES (13, 'jiangtao', '123456', '蒋涛', 1, 3, '销售专员', '13800000013', '2021-02-22', 'SALES', 5000);
INSERT INTO employee (id, username, password, name, gender, department_id, position, phone, hire_date, salary_type, base_salary) VALUES (14, 'hanmei', '123456', '韩梅', 2, 3, '销售专员', '13800000014', '2021-07-12', 'SALES', 5500);
INSERT INTO employee (id, username, password, name, gender, department_id, position, phone, hire_date, salary_type, base_salary) VALUES (15, 'caoyang', '123456', '曹阳', 1, 3, '销售专员', '13800000015', '2022-03-28', 'SALES', 5000);
INSERT INTO employee (id, username, password, name, gender, department_id, position, phone, hire_date, salary_type, base_salary) VALUES (16, 'pengli', '123456', '彭丽', 2, 3, '销售专员', '13800000016', '2022-09-05', 'SALES', 5200);
INSERT INTO employee (id, username, password, name, gender, department_id, position, phone, hire_date, salary_type, base_salary) VALUES (17, 'dongqiang', '123456', '董强', 1, 3, '销售专员', '13800000017', '2023-01-09', 'SALES', 5000);
INSERT INTO employee (id, username, password, name, gender, department_id, position, phone, hire_date, salary_type, base_salary) VALUES (18, 'liangyu', '123456', '梁宇', 1, 3, '销售专员', '13800000018', '2023-06-19', 'SALES', 5500);
INSERT INTO employee (id, username, password, name, gender, department_id, position, phone, hire_date, salary_type, base_salary) VALUES (19, 'sulei', '123456', '苏蕾', 2, 3, '销售专员', '13800000019', '2024-02-26', 'SALES', 5000);
INSERT INTO employee (id, username, password, name, gender, department_id, position, phone, hire_date, salary_type, base_salary) VALUES (20, 'gaoxiang', '123456', '高翔', 1, 3, '销售专员', '13800000020', '2024-08-12', 'SALES', 4800);
INSERT INTO employee (id, username, password, name, gender, department_id, position, phone, hire_date, salary_type, base_salary) VALUES (21, 'linjing', '123456', '林静', 2, 3, '销售专员', '13800000021', '2025-03-03', 'SALES', 5200);

-- ---------------------------- 2026年7月销售业绩 ----------------------------
INSERT INTO sales_record (employee_id, stat_month, amount) VALUES (12, '2026-07', 360000);
INSERT INTO sales_record (employee_id, stat_month, amount) VALUES (13, '2026-07', 150000);
INSERT INTO sales_record (employee_id, stat_month, amount) VALUES (14, '2026-07', 230000);
INSERT INTO sales_record (employee_id, stat_month, amount) VALUES (15, '2026-07', 85000);
INSERT INTO sales_record (employee_id, stat_month, amount) VALUES (16, '2026-07', 120000);
INSERT INTO sales_record (employee_id, stat_month, amount) VALUES (17, '2026-07', 60000);
INSERT INTO sales_record (employee_id, stat_month, amount) VALUES (18, '2026-07', 190000);
INSERT INTO sales_record (employee_id, stat_month, amount) VALUES (19, '2026-07', 45000);
INSERT INTO sales_record (employee_id, stat_month, amount) VALUES (20, '2026-07', 30000);
INSERT INTO sales_record (employee_id, stat_month, amount) VALUES (21, '2026-07', 98000);

-- ---------------------------- 2026年7月考勤数据 ----------------------------
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (1, '2026-07-01', '星期三', NULL, NULL, '请假', 0, '事假');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (1, '2026-07-02', '星期四', '08:06:00', '18:19:00', '正常', 9.2, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (1, '2026-07-03', '星期五', '08:12:00', '19:02:00', '正常', 9.8, '加班');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (1, '2026-07-04', '星期六', NULL, NULL, '休息', 0, '周末休息');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (1, '2026-07-05', '星期日', NULL, NULL, '休息', 0, '周末休息');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (1, '2026-07-06', '星期一', '08:11:00', '18:25:00', '正常', 9.2, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (1, '2026-07-07', '星期二', '08:27:00', '18:11:00', '正常', 8.7, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (1, '2026-07-08', '星期三', '08:10:00', '18:10:00', '正常', 9, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (1, '2026-07-09', '星期四', '08:09:00', '18:05:00', '正常', 8.9, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (1, '2026-07-10', '星期五', '08:04:00', '18:25:00', '正常', 9.4, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (1, '2026-07-11', '星期六', NULL, NULL, '休息', 0, '周末休息');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (1, '2026-07-12', '星期日', NULL, NULL, '休息', 0, '周末休息');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (1, '2026-07-13', '星期一', '08:44:00', '18:20:00', '迟到', 8.6, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (1, '2026-07-14', '星期二', '08:02:00', '18:03:00', '正常', 9, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (1, '2026-07-15', '星期三', '08:30:00', '18:20:00', '正常', 8.8, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (1, '2026-07-16', '星期四', '08:39:00', '18:01:00', '迟到', 8.4, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (1, '2026-07-17', '星期五', '08:27:00', '18:23:00', '正常', 8.9, '加班');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (1, '2026-07-18', '星期六', NULL, NULL, '休息', 0, '周末休息');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (1, '2026-07-19', '星期日', NULL, NULL, '休息', 0, '周末休息');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (1, '2026-07-20', '星期一', '08:13:00', '18:02:00', '正常', 8.8, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (1, '2026-07-21', '星期二', '08:08:00', '18:21:00', '正常', 9.2, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (1, '2026-07-22', '星期三', '08:05:00', '20:06:00', '正常', 11, '加班');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (1, '2026-07-23', '星期四', '08:05:00', '18:07:00', '正常', 9, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (1, '2026-07-24', '星期五', '08:13:00', '18:23:00', '正常', 9.2, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (1, '2026-07-25', '星期六', NULL, NULL, '休息', 0, '周末休息');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (1, '2026-07-26', '星期日', NULL, NULL, '休息', 0, '周末休息');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (1, '2026-07-27', '星期一', '08:09:00', '18:06:00', '正常', 9, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (1, '2026-07-28', '星期二', '08:12:00', '18:21:00', '正常', 9.2, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (1, '2026-07-29', '星期三', '08:06:00', '18:01:00', '正常', 8.9, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (1, '2026-07-30', '星期四', '08:00:00', '18:03:00', '正常', 9.1, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (1, '2026-07-31', '星期五', '08:18:00', '18:09:00', '正常', 8.9, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (2, '2026-07-01', '星期三', '08:08:00', '18:16:00', '正常', 9.1, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (2, '2026-07-02', '星期四', '08:02:00', '18:16:00', '正常', 9.2, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (2, '2026-07-03', '星期五', '08:02:00', '18:13:00', '正常', 9.2, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (2, '2026-07-04', '星期六', NULL, NULL, '休息', 0, '周末休息');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (2, '2026-07-05', '星期日', NULL, NULL, '休息', 0, '周末休息');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (2, '2026-07-06', '星期一', '08:28:00', '18:22:00', '正常', 8.9, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (2, '2026-07-07', '星期二', '08:25:00', '18:23:00', '正常', 9, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (2, '2026-07-08', '星期三', '08:27:00', '18:11:00', '正常', 8.7, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (2, '2026-07-09', '星期四', '08:24:00', '18:10:00', '正常', 8.8, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (2, '2026-07-10', '星期五', '08:03:00', '18:14:00', '正常', 9.2, '加班');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (2, '2026-07-11', '星期六', NULL, NULL, '休息', 0, '周末休息');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (2, '2026-07-12', '星期日', NULL, NULL, '休息', 0, '周末休息');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (2, '2026-07-13', '星期一', '08:00:00', '18:18:00', '正常', 9.3, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (2, '2026-07-14', '星期二', '08:22:00', '18:11:00', '正常', 8.8, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (2, '2026-07-15', '星期三', '08:06:00', '18:24:00', '正常', 9.3, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (2, '2026-07-16', '星期四', '08:15:00', '20:09:00', '正常', 10.9, '加班');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (2, '2026-07-17', '星期五', '08:09:00', '18:11:00', '正常', 9, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (2, '2026-07-18', '星期六', NULL, NULL, '休息', 0, '周末休息');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (2, '2026-07-19', '星期日', NULL, NULL, '休息', 0, '周末休息');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (2, '2026-07-20', '星期一', NULL, NULL, '请假', 0, '出差');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (2, '2026-07-21', '星期二', '08:30:00', '18:01:00', '正常', 8.5, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (2, '2026-07-22', '星期三', '08:03:00', '19:33:00', '正常', 10.5, '加班');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (2, '2026-07-23', '星期四', '08:08:00', '19:34:00', '正常', 10.4, '加班');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (2, '2026-07-24', '星期五', '08:17:00', '18:25:00', '正常', 9.1, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (2, '2026-07-25', '星期六', NULL, NULL, '休息', 0, '周末休息');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (2, '2026-07-26', '星期日', NULL, NULL, '休息', 0, '周末休息');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (2, '2026-07-27', '星期一', '08:02:00', '18:25:00', '正常', 9.4, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (2, '2026-07-28', '星期二', '08:11:00', '18:03:00', '正常', 8.9, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (2, '2026-07-29', '星期三', '08:22:00', '20:00:00', '正常', 10.6, '加班');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (2, '2026-07-30', '星期四', '08:20:00', '18:13:00', '正常', 8.9, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (2, '2026-07-31', '星期五', '08:27:00', '18:13:00', '正常', 8.8, '加班');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (3, '2026-07-01', '星期三', '08:29:00', '18:54:00', '正常', 9.4, '加班');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (3, '2026-07-02', '星期四', '08:03:00', '18:25:00', '正常', 9.4, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (3, '2026-07-03', '星期五', '08:24:00', '18:11:00', '正常', 8.8, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (3, '2026-07-04', '星期六', NULL, NULL, '休息', 0, '周末休息');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (3, '2026-07-05', '星期日', NULL, NULL, '休息', 0, '周末休息');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (3, '2026-07-06', '星期一', NULL, NULL, '请假', 0, '事假');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (3, '2026-07-07', '星期二', '08:06:00', '18:01:00', '正常', 8.9, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (3, '2026-07-08', '星期三', '08:16:00', '18:10:00', '正常', 8.9, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (3, '2026-07-09', '星期四', '08:13:00', '18:21:00', '正常', 9.1, '加班');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (3, '2026-07-10', '星期五', '08:29:00', '18:15:00', '正常', 8.8, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (3, '2026-07-11', '星期六', NULL, NULL, '休息', 0, '周末休息');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (3, '2026-07-12', '星期日', NULL, NULL, '休息', 0, '周末休息');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (3, '2026-07-13', '星期一', NULL, NULL, '请假', 0, '年假');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (3, '2026-07-14', '星期二', NULL, NULL, '请假', 0, '年假');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (3, '2026-07-15', '星期三', '08:19:00', '18:12:00', '正常', 8.9, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (3, '2026-07-16', '星期四', '08:04:00', '18:14:00', '正常', 9.2, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (3, '2026-07-17', '星期五', '08:20:00', '18:18:00', '正常', 9, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (3, '2026-07-18', '星期六', NULL, NULL, '休息', 0, '周末休息');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (3, '2026-07-19', '星期日', NULL, NULL, '休息', 0, '周末休息');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (3, '2026-07-20', '星期一', '08:16:00', '18:23:00', '正常', 9.1, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (3, '2026-07-21', '星期二', '08:00:00', '18:22:00', '正常', 9.4, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (3, '2026-07-22', '星期三', '08:01:00', '18:11:00', '正常', 9.2, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (3, '2026-07-23', '星期四', '08:28:00', '18:12:00', '正常', 8.7, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (3, '2026-07-24', '星期五', '08:10:00', '18:10:00', '正常', 9, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (3, '2026-07-25', '星期六', NULL, NULL, '休息', 0, '周末休息');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (3, '2026-07-26', '星期日', NULL, NULL, '休息', 0, '周末休息');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (3, '2026-07-27', '星期一', '08:02:00', '18:09:00', '正常', 9.1, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (3, '2026-07-28', '星期二', '08:19:00', '18:23:00', '正常', 9.1, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (3, '2026-07-29', '星期三', '08:25:00', '18:10:00', '正常', 8.8, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (3, '2026-07-30', '星期四', '08:09:00', '18:07:00', '正常', 9, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (3, '2026-07-31', '星期五', '08:09:00', '18:09:00', '正常', 9, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (4, '2026-07-01', '星期三', '08:02:00', '20:02:00', '正常', 11, '加班');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (4, '2026-07-02', '星期四', '08:27:00', '18:16:00', '正常', 8.8, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (4, '2026-07-03', '星期五', '08:25:00', '18:06:00', '正常', 8.7, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (4, '2026-07-04', '星期六', NULL, NULL, '休息', 0, '周末休息');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (4, '2026-07-05', '星期日', NULL, NULL, '休息', 0, '周末休息');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (4, '2026-07-06', '星期一', '08:05:00', '18:10:00', '正常', 9.1, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (4, '2026-07-07', '星期二', '08:01:00', '18:16:00', '正常', 9.3, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (4, '2026-07-08', '星期三', NULL, NULL, '缺勤', 0, '无故缺勤');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (4, '2026-07-09', '星期四', '08:02:00', '18:29:00', '正常', 9.5, '加班');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (4, '2026-07-10', '星期五', '08:02:00', '18:09:00', '正常', 9.1, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (4, '2026-07-11', '星期六', NULL, NULL, '休息', 0, '周末休息');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (4, '2026-07-12', '星期日', NULL, NULL, '休息', 0, '周末休息');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (4, '2026-07-13', '星期一', '08:15:00', '18:06:00', '正常', 8.9, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (4, '2026-07-14', '星期二', '08:27:00', '19:44:00', '正常', 10.3, '加班');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (4, '2026-07-15', '星期三', '08:03:00', '18:02:00', '正常', 9, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (4, '2026-07-16', '星期四', '08:02:00', '18:22:00', '正常', 9.3, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (4, '2026-07-17', '星期五', '08:09:00', '18:16:00', '正常', 9.1, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (4, '2026-07-18', '星期六', NULL, NULL, '休息', 0, '周末休息');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (4, '2026-07-19', '星期日', NULL, NULL, '休息', 0, '周末休息');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (4, '2026-07-20', '星期一', '08:00:00', '18:07:00', '正常', 9.1, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (4, '2026-07-21', '星期二', '08:00:00', '18:14:00', '正常', 9.2, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (4, '2026-07-22', '星期三', '08:30:00', '19:29:00', '正常', 10, '加班');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (4, '2026-07-23', '星期四', '08:25:00', '18:08:00', '正常', 8.7, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (4, '2026-07-24', '星期五', '08:19:00', '18:04:00', '正常', 8.8, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (4, '2026-07-25', '星期六', NULL, NULL, '休息', 0, '周末休息');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (4, '2026-07-26', '星期日', NULL, NULL, '休息', 0, '周末休息');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (4, '2026-07-27', '星期一', '08:22:00', '18:16:00', '正常', 8.9, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (4, '2026-07-28', '星期二', '08:30:00', '18:15:00', '正常', 8.8, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (4, '2026-07-29', '星期三', '08:25:00', '18:06:00', '正常', 8.7, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (4, '2026-07-30', '星期四', '08:29:00', '18:13:00', '正常', 8.7, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (4, '2026-07-31', '星期五', '08:01:00', '18:15:00', '正常', 9.2, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (5, '2026-07-01', '星期三', '08:11:00', '20:04:00', '正常', 10.9, '加班');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (5, '2026-07-02', '星期四', '08:16:00', '18:25:00', '正常', 9.2, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (5, '2026-07-03', '星期五', '08:09:00', '18:25:00', '正常', 9.3, '加班');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (5, '2026-07-04', '星期六', NULL, NULL, '休息', 0, '周末休息');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (5, '2026-07-05', '星期日', NULL, NULL, '休息', 0, '周末休息');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (5, '2026-07-06', '星期一', '08:20:00', '18:06:00', '正常', 8.8, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (5, '2026-07-07', '星期二', NULL, NULL, '请假', 0, '请假');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (5, '2026-07-08', '星期三', '08:12:00', '20:03:00', '正常', 10.9, '加班');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (5, '2026-07-09', '星期四', '08:02:00', '18:35:00', '正常', 9.6, '加班');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (5, '2026-07-10', '星期五', '08:12:00', '18:07:00', '正常', 8.9, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (5, '2026-07-11', '星期六', NULL, NULL, '休息', 0, '周末休息');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (5, '2026-07-12', '星期日', NULL, NULL, '休息', 0, '周末休息');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (5, '2026-07-13', '星期一', '08:11:00', '18:10:00', '正常', 9, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (5, '2026-07-14', '星期二', '08:25:00', '18:05:00', '正常', 8.7, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (5, '2026-07-15', '星期三', '08:06:00', '19:16:00', '正常', 10.2, '加班');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (5, '2026-07-16', '星期四', '08:16:00', '18:01:00', '正常', 8.8, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (5, '2026-07-17', '星期五', '08:09:00', '18:07:00', '正常', 9, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (5, '2026-07-18', '星期六', NULL, NULL, '休息', 0, '周末休息');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (5, '2026-07-19', '星期日', NULL, NULL, '休息', 0, '周末休息');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (5, '2026-07-20', '星期一', '08:12:00', '18:11:00', '正常', 9, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (5, '2026-07-21', '星期二', '08:02:00', '18:14:00', '正常', 9.2, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (5, '2026-07-22', '星期三', '08:42:00', '18:06:00', '迟到', 8.4, '交通拥堵');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (5, '2026-07-23', '星期四', '08:17:00', '18:04:00', '正常', 8.8, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (5, '2026-07-24', '星期五', '08:18:00', '18:23:00', '正常', 9.1, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (5, '2026-07-25', '星期六', NULL, NULL, '休息', 0, '周末休息');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (5, '2026-07-26', '星期日', NULL, NULL, '休息', 0, '周末休息');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (5, '2026-07-27', '星期一', '08:25:00', '18:05:00', '正常', 8.7, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (5, '2026-07-28', '星期二', '08:24:00', '18:15:00', '正常', 8.9, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (5, '2026-07-29', '星期三', '08:29:00', '18:16:00', '正常', 8.8, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (5, '2026-07-30', '星期四', '08:13:00', '18:07:00', '正常', 8.9, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (5, '2026-07-31', '星期五', '08:13:00', '18:25:00', '正常', 9.2, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (6, '2026-07-01', '星期三', '08:09:00', '18:10:00', '正常', 9, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (6, '2026-07-02', '星期四', '08:03:00', '18:01:00', '正常', 9, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (6, '2026-07-03', '星期五', '08:02:00', '18:07:00', '正常', 9.1, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (6, '2026-07-04', '星期六', NULL, NULL, '休息', 0, '周末休息');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (6, '2026-07-05', '星期日', NULL, NULL, '休息', 0, '周末休息');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (6, '2026-07-06', '星期一', '08:13:00', '18:15:00', '正常', 9, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (6, '2026-07-07', '星期二', '08:16:00', '18:58:00', '正常', 9.7, '加班');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (6, '2026-07-08', '星期三', '08:15:00', '18:05:00', '正常', 8.8, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (6, '2026-07-09', '星期四', '08:06:00', '18:00:00', '正常', 8.9, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (6, '2026-07-10', '星期五', '08:16:00', '18:09:00', '正常', 8.9, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (6, '2026-07-11', '星期六', NULL, NULL, '休息', 0, '周末休息');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (6, '2026-07-12', '星期日', NULL, NULL, '休息', 0, '周末休息');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (6, '2026-07-13', '星期一', '08:20:00', '20:15:00', '正常', 10.9, '加班');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (6, '2026-07-14', '星期二', '08:22:00', '18:06:00', '正常', 8.7, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (6, '2026-07-15', '星期三', '08:25:00', '18:19:00', '正常', 8.9, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (6, '2026-07-16', '星期四', '08:05:00', '18:11:00', '正常', 9.1, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (6, '2026-07-17', '星期五', '08:28:00', '18:24:00', '正常', 8.9, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (6, '2026-07-18', '星期六', NULL, NULL, '休息', 0, '周末休息');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (6, '2026-07-19', '星期日', NULL, NULL, '休息', 0, '周末休息');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (6, '2026-07-20', '星期一', '08:23:00', '18:06:00', '正常', 8.7, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (6, '2026-07-21', '星期二', '08:13:00', '18:04:00', '正常', 8.9, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (6, '2026-07-22', '星期三', '08:18:00', '18:18:00', '正常', 9, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (6, '2026-07-23', '星期四', '08:25:00', '18:19:00', '正常', 8.9, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (6, '2026-07-24', '星期五', '08:10:00', '18:07:00', '正常', 9, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (6, '2026-07-25', '星期六', NULL, NULL, '休息', 0, '周末休息');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (6, '2026-07-26', '星期日', NULL, NULL, '休息', 0, '周末休息');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (6, '2026-07-27', '星期一', '08:01:00', '18:15:00', '正常', 9.2, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (6, '2026-07-28', '星期二', '08:13:00', '18:09:00', '正常', 8.9, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (6, '2026-07-29', '星期三', '08:30:00', '17:05:00', '早退', 7.6, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (6, '2026-07-30', '星期四', '08:07:00', '18:20:00', '正常', 9.2, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (6, '2026-07-31', '星期五', '08:21:00', '19:23:00', '正常', 10, '加班');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (7, '2026-07-01', '星期三', '08:04:00', '18:08:00', '正常', 9.1, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (7, '2026-07-02', '星期四', '08:08:00', '18:16:00', '正常', 9.1, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (7, '2026-07-03', '星期五', '08:09:00', '18:05:00', '正常', 8.9, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (7, '2026-07-04', '星期六', NULL, NULL, '休息', 0, '周末休息');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (7, '2026-07-05', '星期日', NULL, NULL, '休息', 0, '周末休息');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (7, '2026-07-06', '星期一', '08:09:00', '18:21:00', '正常', 9.2, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (7, '2026-07-07', '星期二', '08:17:00', '18:22:00', '正常', 9.1, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (7, '2026-07-08', '星期三', '08:13:00', '18:03:00', '正常', 8.8, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (7, '2026-07-09', '星期四', '08:00:00', '20:24:00', '正常', 11.4, '加班');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (7, '2026-07-10', '星期五', '08:08:00', '18:03:00', '正常', 8.9, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (7, '2026-07-11', '星期六', NULL, NULL, '休息', 0, '周末休息');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (7, '2026-07-12', '星期日', NULL, NULL, '休息', 0, '周末休息');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (7, '2026-07-13', '星期一', '08:29:00', '18:05:00', '正常', 8.6, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (7, '2026-07-14', '星期二', '08:01:00', '18:01:00', '正常', 9, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (7, '2026-07-15', '星期三', '08:18:00', '17:45:00', '早退', 8.5, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (7, '2026-07-16', '星期四', '08:20:00', '19:38:00', '正常', 10.3, '加班');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (7, '2026-07-17', '星期五', '08:21:00', '18:21:00', '正常', 9, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (7, '2026-07-18', '星期六', NULL, NULL, '休息', 0, '周末休息');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (7, '2026-07-19', '星期日', NULL, NULL, '休息', 0, '周末休息');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (7, '2026-07-20', '星期一', '08:19:00', '18:25:00', '正常', 9.1, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (7, '2026-07-21', '星期二', '08:13:00', '18:25:00', '正常', 9.2, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (7, '2026-07-22', '星期三', '08:03:00', '18:23:00', '正常', 9.3, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (7, '2026-07-23', '星期四', '08:00:00', '18:05:00', '正常', 9.1, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (7, '2026-07-24', '星期五', '08:23:00', '18:00:00', '正常', 8.6, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (7, '2026-07-25', '星期六', NULL, NULL, '休息', 0, '周末休息');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (7, '2026-07-26', '星期日', NULL, NULL, '休息', 0, '周末休息');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (7, '2026-07-27', '星期一', '08:24:00', '18:37:00', '正常', 9.2, '加班');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (7, '2026-07-28', '星期二', '08:21:00', '18:03:00', '正常', 8.7, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (7, '2026-07-29', '星期三', '08:11:00', '18:06:00', '正常', 8.9, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (7, '2026-07-30', '星期四', '08:00:00', '18:06:00', '正常', 9.1, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (7, '2026-07-31', '星期五', '08:15:00', '18:25:00', '正常', 9.2, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (8, '2026-07-01', '星期三', '08:28:00', '18:16:00', '正常', 8.8, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (8, '2026-07-02', '星期四', '08:21:00', '18:03:00', '正常', 8.7, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (8, '2026-07-03', '星期五', '08:08:00', '18:24:00', '正常', 9.3, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (8, '2026-07-04', '星期六', NULL, NULL, '休息', 0, '周末休息');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (8, '2026-07-05', '星期日', NULL, NULL, '休息', 0, '周末休息');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (8, '2026-07-06', '星期一', '08:06:00', '18:12:00', '正常', 9.1, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (8, '2026-07-07', '星期二', '08:07:00', '18:00:00', '正常', 8.9, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (8, '2026-07-08', '星期三', '08:22:00', '18:01:00', '正常', 8.7, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (8, '2026-07-09', '星期四', '08:22:00', '18:00:00', '正常', 8.6, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (8, '2026-07-10', '星期五', '08:11:00', '18:04:00', '正常', 8.9, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (8, '2026-07-11', '星期六', NULL, NULL, '休息', 0, '周末休息');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (8, '2026-07-12', '星期日', NULL, NULL, '休息', 0, '周末休息');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (8, '2026-07-13', '星期一', '08:03:00', '18:07:00', '正常', 9.1, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (8, '2026-07-14', '星期二', '08:24:00', '18:03:00', '正常', 8.7, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (8, '2026-07-15', '星期三', '08:11:00', '18:05:00', '正常', 8.9, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (8, '2026-07-16', '星期四', '08:01:00', '18:06:00', '正常', 9.1, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (8, '2026-07-17', '星期五', '08:23:00', '18:21:00', '正常', 9, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (8, '2026-07-18', '星期六', NULL, NULL, '休息', 0, '周末休息');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (8, '2026-07-19', '星期日', NULL, NULL, '休息', 0, '周末休息');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (8, '2026-07-20', '星期一', '08:02:00', '18:08:00', '正常', 9.1, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (8, '2026-07-21', '星期二', '08:24:00', '19:33:00', '正常', 10.2, '加班');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (8, '2026-07-22', '星期三', '08:15:00', '18:16:00', '正常', 9, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (8, '2026-07-23', '星期四', '08:20:00', '18:03:00', '正常', 8.7, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (8, '2026-07-24', '星期五', '08:06:00', '18:08:00', '正常', 9, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (8, '2026-07-25', '星期六', NULL, NULL, '休息', 0, '周末休息');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (8, '2026-07-26', '星期日', NULL, NULL, '休息', 0, '周末休息');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (8, '2026-07-27', '星期一', '08:03:00', '18:07:00', '正常', 9.1, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (8, '2026-07-28', '星期二', '08:07:00', '18:22:00', '正常', 9.3, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (8, '2026-07-29', '星期三', '08:07:00', '18:12:00', '正常', 9.1, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (8, '2026-07-30', '星期四', '08:01:00', '19:14:00', '正常', 10.2, '加班');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (8, '2026-07-31', '星期五', '08:02:00', '18:05:00', '正常', 9.1, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (9, '2026-07-01', '星期三', '08:15:00', '18:16:00', '正常', 9, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (9, '2026-07-02', '星期四', '08:09:00', '18:06:00', '正常', 9, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (9, '2026-07-03', '星期五', '08:06:00', '18:20:00', '正常', 9.2, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (9, '2026-07-04', '星期六', NULL, NULL, '休息', 0, '周末休息');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (9, '2026-07-05', '星期日', NULL, NULL, '休息', 0, '周末休息');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (9, '2026-07-06', '星期一', '08:12:00', '18:16:00', '正常', 9.1, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (9, '2026-07-07', '星期二', '08:19:00', '18:01:00', '正常', 8.7, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (9, '2026-07-08', '星期三', '08:18:00', '18:16:00', '正常', 9, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (9, '2026-07-09', '星期四', '08:16:00', '18:06:00', '正常', 8.8, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (9, '2026-07-10', '星期五', '08:07:00', '18:22:00', '正常', 9.3, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (9, '2026-07-11', '星期六', NULL, NULL, '休息', 0, '周末休息');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (9, '2026-07-12', '星期日', NULL, NULL, '休息', 0, '周末休息');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (9, '2026-07-13', '星期一', '08:25:00', '18:16:00', '正常', 8.9, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (9, '2026-07-14', '星期二', '08:21:00', '18:21:00', '正常', 9, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (9, '2026-07-15', '星期三', '08:03:00', '18:15:00', '正常', 9.2, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (9, '2026-07-16', '星期四', '08:27:00', '18:21:00', '正常', 8.9, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (9, '2026-07-17', '星期五', '08:22:00', '18:24:00', '正常', 9, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (9, '2026-07-18', '星期六', NULL, NULL, '休息', 0, '周末休息');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (9, '2026-07-19', '星期日', NULL, NULL, '休息', 0, '周末休息');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (9, '2026-07-20', '星期一', '08:26:00', '18:19:00', '正常', 8.9, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (9, '2026-07-21', '星期二', '08:10:00', '18:17:00', '正常', 9.1, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (9, '2026-07-22', '星期三', '08:08:00', '18:05:00', '正常', 9, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (9, '2026-07-23', '星期四', '08:12:00', '18:07:00', '正常', 8.9, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (9, '2026-07-24', '星期五', '08:12:00', '18:01:00', '正常', 8.8, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (9, '2026-07-25', '星期六', NULL, NULL, '休息', 0, '周末休息');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (9, '2026-07-26', '星期日', NULL, NULL, '休息', 0, '周末休息');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (9, '2026-07-27', '星期一', '08:07:00', '18:15:00', '正常', 9.1, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (9, '2026-07-28', '星期二', '08:05:00', '18:14:00', '正常', 9.2, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (9, '2026-07-29', '星期三', '08:20:00', '18:08:00', '正常', 8.8, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (9, '2026-07-30', '星期四', '08:21:00', '18:06:00', '正常', 8.8, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (9, '2026-07-31', '星期五', '08:00:00', '18:06:00', '正常', 9.1, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (10, '2026-07-01', '星期三', '08:09:00', '18:24:00', '正常', 9.3, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (10, '2026-07-02', '星期四', '08:19:00', '18:23:00', '正常', 9.1, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (10, '2026-07-03', '星期五', NULL, NULL, '请假', 0, '请假');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (10, '2026-07-04', '星期六', NULL, NULL, '休息', 0, '周末休息');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (10, '2026-07-05', '星期日', NULL, NULL, '休息', 0, '周末休息');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (10, '2026-07-06', '星期一', '08:30:00', '18:10:00', '正常', 8.7, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (10, '2026-07-07', '星期二', '08:27:00', '18:05:00', '正常', 8.6, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (10, '2026-07-08', '星期三', '08:52:00', '18:01:00', '迟到', 8.2, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (10, '2026-07-09', '星期四', '08:27:00', '18:15:00', '正常', 8.8, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (10, '2026-07-10', '星期五', '08:00:00', '18:22:00', '正常', 9.4, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (10, '2026-07-11', '星期六', NULL, NULL, '休息', 0, '周末休息');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (10, '2026-07-12', '星期日', NULL, NULL, '休息', 0, '周末休息');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (10, '2026-07-13', '星期一', '08:00:00', '18:19:00', '正常', 9.3, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (10, '2026-07-14', '星期二', '08:00:00', '18:12:00', '正常', 9.2, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (10, '2026-07-15', '星期三', '08:25:00', '18:25:00', '正常', 9, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (10, '2026-07-16', '星期四', '08:15:00', '18:04:00', '正常', 8.8, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (10, '2026-07-17', '星期五', '08:16:00', '19:09:00', '正常', 9.9, '加班');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (10, '2026-07-18', '星期六', NULL, NULL, '休息', 0, '周末休息');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (10, '2026-07-19', '星期日', NULL, NULL, '休息', 0, '周末休息');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (10, '2026-07-20', '星期一', '08:14:00', '18:05:00', '正常', 8.9, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (10, '2026-07-21', '星期二', '08:04:00', '18:08:00', '正常', 9.1, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (10, '2026-07-22', '星期三', '08:23:00', '18:19:00', '正常', 8.9, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (10, '2026-07-23', '星期四', '08:03:00', '18:12:00', '正常', 9.2, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (10, '2026-07-24', '星期五', '09:02:00', '17:28:00', '迟到早退', 7.4, '夜间值班');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (10, '2026-07-25', '星期六', NULL, NULL, '休息', 0, '周末休息');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (10, '2026-07-26', '星期日', NULL, NULL, '休息', 0, '周末休息');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (10, '2026-07-27', '星期一', '08:19:00', '18:13:00', '正常', 8.9, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (10, '2026-07-28', '星期二', '08:17:00', '18:03:00', '正常', 8.8, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (10, '2026-07-29', '星期三', '08:28:00', '19:55:00', '正常', 10.5, '加班');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (10, '2026-07-30', '星期四', '08:27:00', '18:24:00', '正常', 9, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (10, '2026-07-31', '星期五', '08:01:00', '18:15:00', '正常', 9.2, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (11, '2026-07-01', '星期三', '08:18:00', '18:18:00', '正常', 9, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (11, '2026-07-02', '星期四', '08:12:00', '18:09:00', '正常', 9, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (11, '2026-07-03', '星期五', '08:11:00', '18:16:00', '正常', 9.1, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (11, '2026-07-04', '星期六', NULL, NULL, '休息', 0, '周末休息');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (11, '2026-07-05', '星期日', NULL, NULL, '休息', 0, '周末休息');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (11, '2026-07-06', '星期一', '08:23:00', '18:12:00', '正常', 8.8, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (11, '2026-07-07', '星期二', '08:26:00', '18:23:00', '正常', 9, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (11, '2026-07-08', '星期三', '08:12:00', '18:09:00', '正常', 9, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (11, '2026-07-09', '星期四', '08:01:00', '18:10:00', '正常', 9.2, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (11, '2026-07-10', '星期五', '08:02:00', '18:21:00', '正常', 9.3, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (11, '2026-07-11', '星期六', NULL, NULL, '休息', 0, '周末休息');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (11, '2026-07-12', '星期日', NULL, NULL, '休息', 0, '周末休息');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (11, '2026-07-13', '星期一', '08:02:00', '18:14:00', '正常', 9.2, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (11, '2026-07-14', '星期二', '08:08:00', '18:23:00', '正常', 9.3, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (11, '2026-07-15', '星期三', '08:30:00', '18:24:00', '正常', 8.9, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (11, '2026-07-16', '星期四', '08:00:00', '18:13:00', '正常', 9.2, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (11, '2026-07-17', '星期五', '08:19:00', '18:25:00', '正常', 9.1, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (11, '2026-07-18', '星期六', NULL, NULL, '休息', 0, '周末休息');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (11, '2026-07-19', '星期日', NULL, NULL, '休息', 0, '周末休息');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (11, '2026-07-20', '星期一', '08:21:00', '18:25:00', '正常', 9.1, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (11, '2026-07-21', '星期二', '08:30:00', '18:20:00', '正常', 8.8, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (11, '2026-07-22', '星期三', '08:30:00', '18:21:00', '正常', 8.9, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (11, '2026-07-23', '星期四', '08:12:00', '18:12:00', '正常', 9, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (11, '2026-07-24', '星期五', '08:19:00', '18:16:00', '正常', 9, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (11, '2026-07-25', '星期六', NULL, NULL, '休息', 0, '周末休息');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (11, '2026-07-26', '星期日', NULL, NULL, '休息', 0, '周末休息');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (11, '2026-07-27', '星期一', NULL, NULL, '缺勤', 0, '缺勤');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (11, '2026-07-28', '星期二', '08:00:00', '18:13:00', '正常', 9.2, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (11, '2026-07-29', '星期三', '08:09:00', '18:14:00', '正常', 9.1, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (11, '2026-07-30', '星期四', '08:21:00', '18:13:00', '正常', 8.9, '加班');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (11, '2026-07-31', '星期五', '08:05:00', '18:02:00', '正常', 9, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (12, '2026-07-01', '星期三', '08:23:00', '18:09:00', '正常', 8.8, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (12, '2026-07-02', '星期四', '08:11:00', '18:01:00', '正常', 8.8, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (12, '2026-07-03', '星期五', '08:08:00', '18:30:00', '正常', 9.4, '加班');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (12, '2026-07-04', '星期六', NULL, NULL, '休息', 0, '周末休息');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (12, '2026-07-05', '星期日', NULL, NULL, '休息', 0, '周末休息');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (12, '2026-07-06', '星期一', '08:11:00', '18:00:00', '正常', 8.8, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (12, '2026-07-07', '星期二', '08:23:00', '18:14:00', '正常', 8.9, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (12, '2026-07-08', '星期三', '08:01:00', '18:22:00', '正常', 9.4, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (12, '2026-07-09', '星期四', '08:26:00', '18:13:00', '正常', 8.8, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (12, '2026-07-10', '星期五', '08:22:00', '18:17:00', '正常', 8.9, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (12, '2026-07-11', '星期六', NULL, NULL, '休息', 0, '周末休息');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (12, '2026-07-12', '星期日', NULL, NULL, '休息', 0, '周末休息');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (12, '2026-07-13', '星期一', '08:10:00', '18:22:00', '正常', 9.2, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (12, '2026-07-14', '星期二', '08:11:00', '18:05:00', '正常', 8.9, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (12, '2026-07-15', '星期三', '08:04:00', '17:36:00', '早退', 8.5, '客户拜访');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (12, '2026-07-16', '星期四', '08:23:00', '18:07:00', '正常', 8.7, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (12, '2026-07-17', '星期五', '08:20:00', '18:19:00', '正常', 9, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (12, '2026-07-18', '星期六', NULL, NULL, '休息', 0, '周末休息');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (12, '2026-07-19', '星期日', NULL, NULL, '休息', 0, '周末休息');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (12, '2026-07-20', '星期一', '08:30:00', '20:39:00', '正常', 11.2, '加班');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (12, '2026-07-21', '星期二', NULL, NULL, '请假', 0, '请假');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (12, '2026-07-22', '星期三', '08:24:00', '18:04:00', '正常', 8.7, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (12, '2026-07-23', '星期四', '08:15:00', '18:05:00', '正常', 8.8, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (12, '2026-07-24', '星期五', NULL, NULL, '缺勤', 0, '缺勤');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (12, '2026-07-25', '星期六', NULL, NULL, '休息', 0, '周末休息');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (12, '2026-07-26', '星期日', NULL, NULL, '休息', 0, '周末休息');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (12, '2026-07-27', '星期一', '08:12:00', '20:03:00', '正常', 10.9, '加班');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (12, '2026-07-28', '星期二', '08:22:00', '18:05:00', '正常', 8.7, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (12, '2026-07-29', '星期三', '08:19:00', '18:04:00', '正常', 8.8, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (12, '2026-07-30', '星期四', '08:24:00', '18:02:00', '正常', 8.6, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (12, '2026-07-31', '星期五', '08:09:00', '18:13:00', '正常', 9.1, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (13, '2026-07-01', '星期三', '08:59:00', '17:55:00', '迟到早退', 7.9, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (13, '2026-07-02', '星期四', '08:25:00', '18:24:00', '正常', 9, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (13, '2026-07-03', '星期五', '08:01:00', '18:57:00', '正常', 9.9, '加班');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (13, '2026-07-04', '星期六', NULL, NULL, '休息', 0, '周末休息');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (13, '2026-07-05', '星期日', NULL, NULL, '休息', 0, '周末休息');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (13, '2026-07-06', '星期一', '08:25:00', '18:24:00', '正常', 9, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (13, '2026-07-07', '星期二', '08:09:00', '17:06:00', '早退', 8, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (13, '2026-07-08', '星期三', '08:10:00', '18:10:00', '正常', 9, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (13, '2026-07-09', '星期四', '08:13:00', '18:01:00', '正常', 8.8, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (13, '2026-07-10', '星期五', '08:13:00', '18:21:00', '正常', 9.1, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (13, '2026-07-11', '星期六', NULL, NULL, '休息', 0, '周末休息');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (13, '2026-07-12', '星期日', NULL, NULL, '休息', 0, '周末休息');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (13, '2026-07-13', '星期一', '08:23:00', '18:05:00', '正常', 8.7, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (13, '2026-07-14', '星期二', '08:17:00', '18:06:00', '正常', 8.8, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (13, '2026-07-15', '星期三', '08:12:00', '17:46:00', '早退', 8.6, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (13, '2026-07-16', '星期四', '08:28:00', '18:05:00', '正常', 8.6, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (13, '2026-07-17', '星期五', '08:02:00', '18:15:00', '正常', 9.2, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (13, '2026-07-18', '星期六', NULL, NULL, '休息', 0, '周末休息');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (13, '2026-07-19', '星期日', NULL, NULL, '休息', 0, '周末休息');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (13, '2026-07-20', '星期一', '08:14:00', '18:06:00', '正常', 8.9, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (13, '2026-07-21', '星期二', '08:26:00', '18:06:00', '正常', 8.7, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (13, '2026-07-22', '星期三', '08:04:00', '19:16:00', '正常', 10.2, '加班');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (13, '2026-07-23', '星期四', '08:09:00', '18:23:00', '正常', 9.2, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (13, '2026-07-24', '星期五', '08:26:00', '18:24:00', '正常', 9, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (13, '2026-07-25', '星期六', NULL, NULL, '休息', 0, '周末休息');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (13, '2026-07-26', '星期日', NULL, NULL, '休息', 0, '周末休息');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (13, '2026-07-27', '星期一', NULL, NULL, '请假', 0, '病假');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (13, '2026-07-28', '星期二', '08:17:00', '18:37:00', '正常', 9.3, '加班');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (13, '2026-07-29', '星期三', '08:20:00', '18:01:00', '正常', 8.7, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (13, '2026-07-30', '星期四', '08:11:00', '18:06:00', '正常', 8.9, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (13, '2026-07-31', '星期五', '08:14:00', '18:04:00', '正常', 8.8, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (14, '2026-07-01', '星期三', '08:17:00', '18:13:00', '正常', 8.9, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (14, '2026-07-02', '星期四', '08:21:00', '18:18:00', '正常', 9, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (14, '2026-07-03', '星期五', '08:25:00', '20:32:00', '正常', 11.1, '加班');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (14, '2026-07-04', '星期六', NULL, NULL, '休息', 0, '周末休息');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (14, '2026-07-05', '星期日', NULL, NULL, '休息', 0, '周末休息');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (14, '2026-07-06', '星期一', '08:06:00', '20:02:00', '正常', 10.9, '加班');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (14, '2026-07-07', '星期二', '08:14:00', '18:25:00', '正常', 9.2, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (14, '2026-07-08', '星期三', '08:09:00', '18:01:00', '正常', 8.9, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (14, '2026-07-09', '星期四', '08:15:00', '18:12:00', '正常', 9, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (14, '2026-07-10', '星期五', '08:21:00', '18:50:00', '正常', 9.5, '加班');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (14, '2026-07-11', '星期六', NULL, NULL, '休息', 0, '周末休息');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (14, '2026-07-12', '星期日', NULL, NULL, '休息', 0, '周末休息');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (14, '2026-07-13', '星期一', '08:18:00', '18:03:00', '正常', 8.8, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (14, '2026-07-14', '星期二', '08:11:00', '19:48:00', '正常', 10.6, '加班');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (14, '2026-07-15', '星期三', '08:28:00', '18:01:00', '正常', 8.6, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (14, '2026-07-16', '星期四', '08:04:00', '18:02:00', '正常', 9, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (14, '2026-07-17', '星期五', '09:24:00', '17:13:00', '迟到早退', 6.8, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (14, '2026-07-18', '星期六', NULL, NULL, '休息', 0, '周末休息');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (14, '2026-07-19', '星期日', NULL, NULL, '休息', 0, '周末休息');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (14, '2026-07-20', '星期一', '08:04:00', '18:09:00', '正常', 9.1, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (14, '2026-07-21', '星期二', '08:24:00', '18:08:00', '正常', 8.7, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (14, '2026-07-22', '星期三', '08:16:00', '18:13:00', '正常', 9, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (14, '2026-07-23', '星期四', '08:02:00', '18:17:00', '正常', 9.3, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (14, '2026-07-24', '星期五', '08:07:00', '18:08:00', '正常', 9, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (14, '2026-07-25', '星期六', NULL, NULL, '休息', 0, '周末休息');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (14, '2026-07-26', '星期日', NULL, NULL, '休息', 0, '周末休息');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (14, '2026-07-27', '星期一', '08:10:00', '18:54:00', '正常', 9.7, '加班');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (14, '2026-07-28', '星期二', '08:17:00', '18:00:00', '正常', 8.7, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (14, '2026-07-29', '星期三', '08:06:00', '18:23:00', '正常', 9.3, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (14, '2026-07-30', '星期四', '08:23:00', '18:11:00', '正常', 8.8, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (14, '2026-07-31', '星期五', '08:03:00', '18:17:00', '正常', 9.2, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (15, '2026-07-01', '星期三', '08:29:00', '18:17:00', '正常', 8.8, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (15, '2026-07-02', '星期四', '08:25:00', '18:05:00', '正常', 8.7, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (15, '2026-07-03', '星期五', '08:09:00', '20:27:00', '正常', 11.3, '加班');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (15, '2026-07-04', '星期六', NULL, NULL, '休息', 0, '周末休息');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (15, '2026-07-05', '星期日', NULL, NULL, '休息', 0, '周末休息');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (15, '2026-07-06', '星期一', '08:28:00', '18:13:00', '正常', 8.8, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (15, '2026-07-07', '星期二', '08:43:00', '17:18:00', '迟到早退', 7.6, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (15, '2026-07-08', '星期三', '08:08:00', '18:10:00', '正常', 9, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (15, '2026-07-09', '星期四', '08:11:00', '20:18:00', '正常', 11.1, '加班');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (15, '2026-07-10', '星期五', '08:01:00', '18:02:00', '正常', 9, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (15, '2026-07-11', '星期六', NULL, NULL, '休息', 0, '周末休息');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (15, '2026-07-12', '星期日', NULL, NULL, '休息', 0, '周末休息');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (15, '2026-07-13', '星期一', '08:25:00', '18:24:00', '正常', 9, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (15, '2026-07-14', '星期二', '08:25:00', '18:10:00', '正常', 8.8, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (15, '2026-07-15', '星期三', '08:05:00', '18:03:00', '正常', 9, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (15, '2026-07-16', '星期四', '08:22:00', '18:21:00', '正常', 9, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (15, '2026-07-17', '星期五', '08:17:00', '18:23:00', '正常', 9.1, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (15, '2026-07-18', '星期六', NULL, NULL, '休息', 0, '周末休息');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (15, '2026-07-19', '星期日', NULL, NULL, '休息', 0, '周末休息');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (15, '2026-07-20', '星期一', '08:24:00', '18:05:00', '正常', 8.7, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (15, '2026-07-21', '星期二', '08:28:00', '18:22:00', '正常', 8.9, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (15, '2026-07-22', '星期三', '08:26:00', '18:24:00', '正常', 9, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (15, '2026-07-23', '星期四', '08:07:00', '18:25:00', '正常', 9.3, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (15, '2026-07-24', '星期五', '08:22:00', '18:03:00', '正常', 8.7, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (15, '2026-07-25', '星期六', NULL, NULL, '休息', 0, '周末休息');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (15, '2026-07-26', '星期日', NULL, NULL, '休息', 0, '周末休息');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (15, '2026-07-27', '星期一', '08:19:00', '18:16:00', '正常', 9, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (15, '2026-07-28', '星期二', '08:19:00', '18:07:00', '正常', 8.8, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (15, '2026-07-29', '星期三', '08:23:00', '18:20:00', '正常', 9, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (15, '2026-07-30', '星期四', '08:08:00', '18:06:00', '正常', 9, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (15, '2026-07-31', '星期五', '08:17:00', '18:01:00', '正常', 8.7, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (16, '2026-07-01', '星期三', '08:07:00', '18:05:00', '正常', 9, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (16, '2026-07-02', '星期四', '08:08:00', '18:15:00', '正常', 9.1, '加班');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (16, '2026-07-03', '星期五', '08:13:00', '18:03:00', '正常', 8.8, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (16, '2026-07-04', '星期六', NULL, NULL, '休息', 0, '周末休息');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (16, '2026-07-05', '星期日', NULL, NULL, '休息', 0, '周末休息');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (16, '2026-07-06', '星期一', '08:02:00', '17:33:00', '早退', 8.5, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (16, '2026-07-07', '星期二', '08:24:00', '19:25:00', '正常', 10, '加班');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (16, '2026-07-08', '星期三', '08:29:00', '18:18:00', '正常', 8.8, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (16, '2026-07-09', '星期四', '08:04:00', '18:00:00', '正常', 8.9, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (16, '2026-07-10', '星期五', '08:26:00', '20:27:00', '正常', 11, '加班');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (16, '2026-07-11', '星期六', NULL, NULL, '休息', 0, '周末休息');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (16, '2026-07-12', '星期日', NULL, NULL, '休息', 0, '周末休息');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (16, '2026-07-13', '星期一', '08:11:00', '18:04:00', '正常', 8.9, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (16, '2026-07-14', '星期二', '08:04:00', '18:16:00', '正常', 9.2, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (16, '2026-07-15', '星期三', '08:09:00', '18:00:00', '正常', 8.9, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (16, '2026-07-16', '星期四', '08:25:00', '18:23:00', '正常', 9, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (16, '2026-07-17', '星期五', '08:19:00', '18:11:00', '正常', 8.9, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (16, '2026-07-18', '星期六', NULL, NULL, '休息', 0, '周末休息');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (16, '2026-07-19', '星期日', NULL, NULL, '休息', 0, '周末休息');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (16, '2026-07-20', '星期一', '08:03:00', '18:18:00', '正常', 9.3, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (16, '2026-07-21', '星期二', '08:09:00', '18:14:00', '正常', 9.1, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (16, '2026-07-22', '星期三', '08:21:00', '18:02:00', '正常', 8.7, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (16, '2026-07-23', '星期四', '08:00:00', '20:40:00', '正常', 11.7, '加班');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (16, '2026-07-24', '星期五', '08:08:00', '18:21:00', '正常', 9.2, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (16, '2026-07-25', '星期六', NULL, NULL, '休息', 0, '周末休息');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (16, '2026-07-26', '星期日', NULL, NULL, '休息', 0, '周末休息');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (16, '2026-07-27', '星期一', '08:12:00', '18:10:00', '正常', 9, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (16, '2026-07-28', '星期二', '08:02:00', '18:15:00', '正常', 9.2, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (16, '2026-07-29', '星期三', '08:06:00', '18:23:00', '正常', 9.3, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (16, '2026-07-30', '星期四', '08:15:00', '18:11:00', '正常', 8.9, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (16, '2026-07-31', '星期五', '08:23:00', '18:07:00', '正常', 8.7, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (17, '2026-07-01', '星期三', '08:00:00', '18:13:00', '正常', 9.2, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (17, '2026-07-02', '星期四', '08:05:00', '18:20:00', '正常', 9.3, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (17, '2026-07-03', '星期五', '08:08:00', '18:13:00', '正常', 9.1, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (17, '2026-07-04', '星期六', NULL, NULL, '休息', 0, '周末休息');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (17, '2026-07-05', '星期日', NULL, NULL, '休息', 0, '周末休息');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (17, '2026-07-06', '星期一', '08:07:00', '18:14:00', '正常', 9.1, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (17, '2026-07-07', '星期二', '08:13:00', '18:20:00', '正常', 9.1, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (17, '2026-07-08', '星期三', '09:24:00', '18:23:00', '迟到', 8, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (17, '2026-07-09', '星期四', '08:30:00', '18:15:00', '正常', 8.8, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (17, '2026-07-10', '星期五', NULL, NULL, '请假', 0, '请假');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (17, '2026-07-11', '星期六', NULL, NULL, '休息', 0, '周末休息');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (17, '2026-07-12', '星期日', NULL, NULL, '休息', 0, '周末休息');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (17, '2026-07-13', '星期一', '08:02:00', '18:07:00', '正常', 9.1, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (17, '2026-07-14', '星期二', '08:08:00', '18:06:00', '正常', 9, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (17, '2026-07-15', '星期三', '08:08:00', '18:06:00', '正常', 9, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (17, '2026-07-16', '星期四', '08:08:00', '18:10:00', '正常', 9, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (17, '2026-07-17', '星期五', '08:22:00', '18:18:00', '正常', 8.9, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (17, '2026-07-18', '星期六', NULL, NULL, '休息', 0, '周末休息');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (17, '2026-07-19', '星期日', NULL, NULL, '休息', 0, '周末休息');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (17, '2026-07-20', '星期一', '09:21:00', '18:21:00', '迟到', 8, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (17, '2026-07-21', '星期二', '08:15:00', '18:03:00', '正常', 8.8, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (17, '2026-07-22', '星期三', '08:11:00', '18:11:00', '正常', 9, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (17, '2026-07-23', '星期四', '08:24:00', '18:18:00', '正常', 8.9, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (17, '2026-07-24', '星期五', '08:59:00', '18:22:00', '迟到', 8.4, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (17, '2026-07-25', '星期六', NULL, NULL, '休息', 0, '周末休息');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (17, '2026-07-26', '星期日', NULL, NULL, '休息', 0, '周末休息');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (17, '2026-07-27', '星期一', '08:20:00', '18:06:00', '正常', 8.8, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (17, '2026-07-28', '星期二', '08:00:00', '18:20:00', '正常', 9.3, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (17, '2026-07-29', '星期三', '08:24:00', '18:00:00', '正常', 8.6, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (17, '2026-07-30', '星期四', '08:00:00', '18:02:00', '正常', 9, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (17, '2026-07-31', '星期五', '08:15:00', '18:23:00', '正常', 9.1, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (18, '2026-07-01', '星期三', '08:05:00', '18:19:00', '正常', 9.2, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (18, '2026-07-02', '星期四', '08:15:00', '20:16:00', '正常', 11, '加班');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (18, '2026-07-03', '星期五', '08:21:00', '18:20:00', '正常', 9, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (18, '2026-07-04', '星期六', NULL, NULL, '休息', 0, '周末休息');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (18, '2026-07-05', '星期日', NULL, NULL, '休息', 0, '周末休息');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (18, '2026-07-06', '星期一', '08:23:00', '18:22:00', '正常', 9, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (18, '2026-07-07', '星期二', '08:11:00', '18:03:00', '正常', 8.9, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (18, '2026-07-08', '星期三', '08:04:00', '18:02:00', '正常', 9, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (18, '2026-07-09', '星期四', '08:30:00', '18:33:00', '正常', 9.1, '加班');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (18, '2026-07-10', '星期五', NULL, NULL, '缺勤', 0, '缺勤');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (18, '2026-07-11', '星期六', NULL, NULL, '休息', 0, '周末休息');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (18, '2026-07-12', '星期日', NULL, NULL, '休息', 0, '周末休息');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (18, '2026-07-13', '星期一', '08:06:00', '20:02:00', '正常', 10.9, '加班');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (18, '2026-07-14', '星期二', '08:15:00', '18:20:00', '正常', 9.1, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (18, '2026-07-15', '星期三', '08:11:00', '18:05:00', '正常', 8.9, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (18, '2026-07-16', '星期四', '08:28:00', '18:01:00', '正常', 8.6, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (18, '2026-07-17', '星期五', '08:25:00', '18:15:00', '正常', 8.8, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (18, '2026-07-18', '星期六', NULL, NULL, '休息', 0, '周末休息');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (18, '2026-07-19', '星期日', NULL, NULL, '休息', 0, '周末休息');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (18, '2026-07-20', '星期一', '08:27:00', '18:02:00', '正常', 8.6, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (18, '2026-07-21', '星期二', '08:14:00', '18:12:00', '正常', 9, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (18, '2026-07-22', '星期三', '08:12:00', '18:22:00', '正常', 9.2, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (18, '2026-07-23', '星期四', '08:00:00', '18:14:00', '正常', 9.2, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (18, '2026-07-24', '星期五', '08:04:00', '18:07:00', '正常', 9.1, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (18, '2026-07-25', '星期六', NULL, NULL, '休息', 0, '周末休息');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (18, '2026-07-26', '星期日', NULL, NULL, '休息', 0, '周末休息');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (18, '2026-07-27', '星期一', '08:08:00', '18:08:00', '正常', 9, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (18, '2026-07-28', '星期二', '09:10:00', '18:00:00', '迟到', 7.8, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (18, '2026-07-29', '星期三', '08:11:00', '18:16:00', '正常', 9.1, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (18, '2026-07-30', '星期四', '08:25:00', '18:06:00', '正常', 8.7, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (18, '2026-07-31', '星期五', '08:04:00', '18:07:00', '正常', 9.1, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (19, '2026-07-01', '星期三', '08:09:00', '18:02:00', '正常', 8.9, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (19, '2026-07-02', '星期四', '08:15:00', '18:04:00', '正常', 8.8, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (19, '2026-07-03', '星期五', '08:30:00', '18:03:00', '正常', 8.6, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (19, '2026-07-04', '星期六', NULL, NULL, '休息', 0, '周末休息');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (19, '2026-07-05', '星期日', NULL, NULL, '休息', 0, '周末休息');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (19, '2026-07-06', '星期一', '08:02:00', '18:19:00', '正常', 9.3, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (19, '2026-07-07', '星期二', '08:15:00', '18:08:00', '正常', 8.9, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (19, '2026-07-08', '星期三', '08:08:00', '18:22:00', '正常', 9.2, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (19, '2026-07-09', '星期四', '08:14:00', '18:02:00', '正常', 8.8, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (19, '2026-07-10', '星期五', '08:29:00', '18:06:00', '正常', 8.6, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (19, '2026-07-11', '星期六', NULL, NULL, '休息', 0, '周末休息');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (19, '2026-07-12', '星期日', NULL, NULL, '休息', 0, '周末休息');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (19, '2026-07-13', '星期一', '08:05:00', '18:10:00', '正常', 9.1, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (19, '2026-07-14', '星期二', '08:02:00', '18:02:00', '正常', 9, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (19, '2026-07-15', '星期三', '08:26:00', '18:17:00', '正常', 8.9, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (19, '2026-07-16', '星期四', '08:20:00', '18:20:00', '正常', 9, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (19, '2026-07-17', '星期五', '08:23:00', '18:07:00', '正常', 8.7, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (19, '2026-07-18', '星期六', NULL, NULL, '休息', 0, '周末休息');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (19, '2026-07-19', '星期日', NULL, NULL, '休息', 0, '周末休息');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (19, '2026-07-20', '星期一', '08:27:00', '18:09:00', '正常', 8.7, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (19, '2026-07-21', '星期二', '08:08:00', '18:20:00', '正常', 9.2, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (19, '2026-07-22', '星期三', '08:30:00', '18:00:00', '正常', 8.5, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (19, '2026-07-23', '星期四', '08:07:00', '18:18:00', '正常', 9.2, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (19, '2026-07-24', '星期五', '08:29:00', '18:13:00', '正常', 8.7, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (19, '2026-07-25', '星期六', NULL, NULL, '休息', 0, '周末休息');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (19, '2026-07-26', '星期日', NULL, NULL, '休息', 0, '周末休息');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (19, '2026-07-27', '星期一', '08:25:00', '19:33:00', '正常', 10.1, '加班');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (19, '2026-07-28', '星期二', '08:07:00', '18:25:00', '正常', 9.3, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (19, '2026-07-29', '星期三', '08:02:00', '18:13:00', '正常', 9.2, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (19, '2026-07-30', '星期四', NULL, NULL, '缺勤', 0, '无故缺勤');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (19, '2026-07-31', '星期五', '08:07:00', '17:36:00', '早退', 8.5, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (20, '2026-07-01', '星期三', '08:01:00', '18:21:00', '正常', 9.3, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (20, '2026-07-02', '星期四', '08:20:00', '18:10:00', '正常', 8.8, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (20, '2026-07-03', '星期五', '08:17:00', '18:04:00', '正常', 8.8, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (20, '2026-07-04', '星期六', NULL, NULL, '休息', 0, '周末休息');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (20, '2026-07-05', '星期日', NULL, NULL, '休息', 0, '周末休息');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (20, '2026-07-06', '星期一', '08:15:00', '19:16:00', '正常', 10, '加班');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (20, '2026-07-07', '星期二', '08:02:00', '18:01:00', '正常', 9, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (20, '2026-07-08', '星期三', '08:20:00', '19:29:00', '正常', 10.2, '加班');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (20, '2026-07-09', '星期四', '08:18:00', '18:19:00', '正常', 9, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (20, '2026-07-10', '星期五', NULL, NULL, '请假', 0, '年假');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (20, '2026-07-11', '星期六', NULL, NULL, '休息', 0, '周末休息');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (20, '2026-07-12', '星期日', NULL, NULL, '休息', 0, '周末休息');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (20, '2026-07-13', '星期一', '08:28:00', '18:25:00', '正常', 9, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (20, '2026-07-14', '星期二', '08:39:00', '18:10:00', '迟到', 8.5, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (20, '2026-07-15', '星期三', '08:30:00', '18:18:00', '正常', 8.8, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (20, '2026-07-16', '星期四', '08:00:00', '18:06:00', '正常', 9.1, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (20, '2026-07-17', '星期五', '08:14:00', '18:12:00', '正常', 9, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (20, '2026-07-18', '星期六', NULL, NULL, '休息', 0, '周末休息');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (20, '2026-07-19', '星期日', NULL, NULL, '休息', 0, '周末休息');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (20, '2026-07-20', '星期一', '08:24:00', '18:17:00', '正常', 8.9, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (20, '2026-07-21', '星期二', '08:22:00', '19:30:00', '正常', 10.1, '加班');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (20, '2026-07-22', '星期三', '08:12:00', '19:19:00', '正常', 10.1, '加班');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (20, '2026-07-23', '星期四', '09:09:00', '18:07:00', '迟到', 8, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (20, '2026-07-24', '星期五', '08:00:00', '18:12:00', '正常', 9.2, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (20, '2026-07-25', '星期六', NULL, NULL, '休息', 0, '周末休息');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (20, '2026-07-26', '星期日', NULL, NULL, '休息', 0, '周末休息');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (20, '2026-07-27', '星期一', '08:46:00', '17:10:00', '迟到早退', 7.4, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (20, '2026-07-28', '星期二', '08:04:00', '17:16:00', '早退', 8.2, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (20, '2026-07-29', '星期三', '08:20:00', '18:19:00', '正常', 9, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (20, '2026-07-30', '星期四', '08:05:00', '18:04:00', '正常', 9, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (20, '2026-07-31', '星期五', '08:12:00', '19:04:00', '正常', 9.9, '加班');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (21, '2026-07-01', '星期三', '08:08:00', '18:25:00', '正常', 9.3, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (21, '2026-07-02', '星期四', '08:08:00', '18:11:00', '正常', 9.1, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (21, '2026-07-03', '星期五', '08:19:00', '18:21:00', '正常', 9, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (21, '2026-07-04', '星期六', NULL, NULL, '休息', 0, '周末休息');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (21, '2026-07-05', '星期日', NULL, NULL, '休息', 0, '周末休息');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (21, '2026-07-06', '星期一', '08:18:00', '18:13:00', '正常', 8.9, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (21, '2026-07-07', '星期二', '08:23:00', '18:22:00', '正常', 9, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (21, '2026-07-08', '星期三', '08:23:00', '18:18:00', '正常', 8.9, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (21, '2026-07-09', '星期四', '08:13:00', '18:09:00', '正常', 8.9, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (21, '2026-07-10', '星期五', '08:30:00', '18:09:00', '正常', 8.7, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (21, '2026-07-11', '星期六', NULL, NULL, '休息', 0, '周末休息');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (21, '2026-07-12', '星期日', NULL, NULL, '休息', 0, '周末休息');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (21, '2026-07-13', '星期一', '08:25:00', '18:16:00', '正常', 8.9, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (21, '2026-07-14', '星期二', '08:02:00', '18:09:00', '正常', 9.1, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (21, '2026-07-15', '星期三', '08:23:00', '18:11:00', '正常', 8.8, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (21, '2026-07-16', '星期四', '08:21:00', '18:21:00', '正常', 9, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (21, '2026-07-17', '星期五', '08:13:00', '18:06:00', '正常', 8.9, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (21, '2026-07-18', '星期六', NULL, NULL, '休息', 0, '周末休息');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (21, '2026-07-19', '星期日', NULL, NULL, '休息', 0, '周末休息');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (21, '2026-07-20', '星期一', '08:01:00', '18:08:00', '正常', 9.1, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (21, '2026-07-21', '星期二', '08:18:00', '18:32:00', '正常', 9.2, '加班');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (21, '2026-07-22', '星期三', '08:21:00', '18:20:00', '正常', 9, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (21, '2026-07-23', '星期四', '08:57:00', '17:27:00', '迟到早退', 7.5, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (21, '2026-07-24', '星期五', '09:23:00', '18:24:00', '迟到', 8, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (21, '2026-07-25', '星期六', NULL, NULL, '休息', 0, '周末休息');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (21, '2026-07-26', '星期日', NULL, NULL, '休息', 0, '周末休息');
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (21, '2026-07-27', '星期一', '08:54:00', '17:22:00', '迟到早退', 7.5, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (21, '2026-07-28', '星期二', '08:23:00', '18:15:00', '正常', 8.9, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (21, '2026-07-29', '星期三', '08:12:00', '18:14:00', '正常', 9, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (21, '2026-07-30', '星期四', '08:22:00', '18:25:00', '正常', 9.1, NULL);
INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (21, '2026-07-31', '星期五', '08:23:00', '17:24:00', '早退', 8, NULL);

SET FOREIGN_KEY_CHECKS = 1;

-- 校验统计
SELECT '部门数' AS 项目, COUNT(*) AS 数量 FROM department UNION ALL SELECT '员工数', COUNT(*) FROM employee UNION ALL SELECT '考勤记录数', COUNT(*) FROM attendance_record UNION ALL SELECT '销售业绩数', COUNT(*) FROM sales_record;
