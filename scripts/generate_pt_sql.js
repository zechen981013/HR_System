/**
 * 生成 pt.sql：创建数据库 pt、部门表、员工表、考勤记录表，
 * 并生成 21 名员工 2026 年 7 月全月考勤数据（默认上班 08:30，下班 18:00）。
 * 使用种子随机数，重复执行生成结果一致。
 *
 * 运行：node scripts/generate_pt_sql.js
 */
const fs = require('fs');
const path = require('path');

// ---------- 确定性随机数（mulberry32） ----------
function mulberry32(seed) {
  return function () {
    seed |= 0; seed = (seed + 0x6D2B79F5) | 0;
    let t = Math.imul(seed ^ (seed >>> 15), 1 | seed);
    t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}
const rnd = mulberry32(20260701);

// ---------- 部门 ----------
const departments = [
  { id: 1, name: '财务部', description: '负责公司财务核算、预算与资金管理' },
  { id: 2, name: '技术部', description: '负责产品研发、系统开发与运维' },
  { id: 3, name: '销售部', description: '负责市场开拓与产品销售' },
];

// ---------- 员工（财务部 1 人、技术部 10 人、销售部 10 人，共 21 人） ----------
// username 为登录用户名，默认密码均为 123456
// salaryType: FIXED 固定薪水 / SALES 底薪+提成
const employees = [
  // 财务部
  { username: 'wangfang',  name: '王芳', gender: 2, dept: 1, position: '财务经理',     phone: '13800000001', hireDate: '2021-03-15', reliability: 0.98, salaryType: 'FIXED', baseSalary: 15000 },
  // 技术部
  { username: 'zhangwei',  name: '张伟', gender: 1, dept: 2, position: '技术总监',     phone: '13800000002', hireDate: '2018-06-01', reliability: 0.97, salaryType: 'FIXED', baseSalary: 25000 },
  { username: 'liqiang',   name: '李强', gender: 1, dept: 2, position: '高级开发工程师', phone: '13800000003', hireDate: '2019-02-11', reliability: 0.94, salaryType: 'FIXED', baseSalary: 18000 },
  { username: 'liuyang',   name: '刘洋', gender: 1, dept: 2, position: '高级开发工程师', phone: '13800000004', hireDate: '2020-04-20', reliability: 0.93, salaryType: 'FIXED', baseSalary: 18000 },
  { username: 'chenjie',   name: '陈杰', gender: 1, dept: 2, position: '后端开发工程师', phone: '13800000005', hireDate: '2021-08-16', reliability: 0.95, salaryType: 'FIXED', baseSalary: 15000 },
  { username: 'yangfan',   name: '杨帆', gender: 1, dept: 2, position: '前端开发工程师', phone: '13800000006', hireDate: '2022-01-10', reliability: 0.92, salaryType: 'FIXED', baseSalary: 14000 },
  { username: 'zhaolei',   name: '赵磊', gender: 1, dept: 2, position: '后端开发工程师', phone: '13800000007', hireDate: '2022-05-23', reliability: 0.94, salaryType: 'FIXED', baseSalary: 15000 },
  { username: 'zhoumin',   name: '周敏', gender: 2, dept: 2, position: '测试工程师',   phone: '13800000008', hireDate: '2023-03-06', reliability: 0.96, salaryType: 'FIXED', baseSalary: 12000 },
  { username: 'wuting',    name: '吴婷', gender: 2, dept: 2, position: '产品经理',     phone: '13800000009', hireDate: '2020-09-14', reliability: 0.95, salaryType: 'FIXED', baseSalary: 16000 },
  { username: 'zhenghao',  name: '郑浩', gender: 1, dept: 2, position: '运维工程师',   phone: '13800000010', hireDate: '2021-11-08', reliability: 0.93, salaryType: 'FIXED', baseSalary: 14000 },
  { username: 'sunlei',    name: '孙磊', gender: 1, dept: 2, position: '前端开发工程师', phone: '13800000011', hireDate: '2023-07-17', reliability: 0.91, salaryType: 'FIXED', baseSalary: 13000 },
  // 销售部
  { username: 'fengxue',   name: '冯雪', gender: 2, dept: 3, position: '销售经理',     phone: '13800000012', hireDate: '2019-05-27', reliability: 0.95, salaryType: 'SALES', baseSalary: 8000 },
  { username: 'jiangtao',  name: '蒋涛', gender: 1, dept: 3, position: '销售专员',     phone: '13800000013', hireDate: '2021-02-22', reliability: 0.90, salaryType: 'SALES', baseSalary: 5000 },
  { username: 'hanmei',    name: '韩梅', gender: 2, dept: 3, position: '销售专员',     phone: '13800000014', hireDate: '2021-07-12', reliability: 0.91, salaryType: 'SALES', baseSalary: 5500 },
  { username: 'caoyang',   name: '曹阳', gender: 1, dept: 3, position: '销售专员',     phone: '13800000015', hireDate: '2022-03-28', reliability: 0.89, salaryType: 'SALES', baseSalary: 5000 },
  { username: 'pengli',    name: '彭丽', gender: 2, dept: 3, position: '销售专员',     phone: '13800000016', hireDate: '2022-09-05', reliability: 0.92, salaryType: 'SALES', baseSalary: 5200 },
  { username: 'dongqiang', name: '董强', gender: 1, dept: 3, position: '销售专员',     phone: '13800000017', hireDate: '2023-01-09', reliability: 0.88, salaryType: 'SALES', baseSalary: 5000 },
  { username: 'liangyu',   name: '梁宇', gender: 1, dept: 3, position: '销售专员',     phone: '13800000018', hireDate: '2023-06-19', reliability: 0.90, salaryType: 'SALES', baseSalary: 5500 },
  { username: 'sulei',     name: '苏蕾', gender: 2, dept: 3, position: '销售专员',     phone: '13800000019', hireDate: '2024-02-26', reliability: 0.87, salaryType: 'SALES', baseSalary: 5000 },
  { username: 'gaoxiang',  name: '高翔', gender: 1, dept: 3, position: '销售专员',     phone: '13800000020', hireDate: '2024-08-12', reliability: 0.86, salaryType: 'SALES', baseSalary: 4800 },
  { username: 'linjing',   name: '林静', gender: 2, dept: 3, position: '销售专员',     phone: '13800000021', hireDate: '2025-03-03', reliability: 0.89, salaryType: 'SALES', baseSalary: 5200 },
];

// 2026年7月销售业绩（销售额，单位：元）：<10万 提成3%，>=10万 提成5%
const salesAmounts = {
  'fengxue': 360000, 'jiangtao': 150000, 'hanmei': 230000, 'caoyang': 85000, 'pengli': 120000,
  'dongqiang': 60000, 'liangyu': 190000, 'sulei': 45000, 'gaoxiang': 30000, 'linjing': 98000,
};
employees.forEach((e, i) => (e.id = i + 1));

// ---------- 2026 年 7 月 ----------
const YEAR = 2026, MONTH = 7, DAYS = 31;
const WEEK_CN = ['星期日', '星期一', '星期二', '星期三', '星期四', '星期五', '星期六'];
function dayInfo(d) {
  const dow = new Date(Date.UTC(YEAR, MONTH - 1, d)).getUTCDay();
  return { weekday: WEEK_CN[dow], isWeekend: dow === 0 || dow === 6, day: d };
}

// ---------- 手工指定特殊考勤（用户名 + 日期 => 特殊类型） ----------
// 类型: leave 请假 / absent 缺勤 / late 迟到 / early 早退 / lateEarly 迟到并早退
const overrides = {
  'zhangwei': { '20': { type: 'leave', remark: '出差' } },
  'liqiang':  { '06': { type: 'leave', remark: '事假' }, '13': { type: 'leave', remark: '年假' }, '14': { type: 'leave', remark: '年假' } },
  'liuyang':  { '08': { type: 'absent', remark: '无故缺勤' } },
  'fengxue':  { '15': { type: 'early', remark: '客户拜访' } },
  'jiangtao': { '27': { type: 'leave', remark: '病假' } },
  'sulei':    { '30': { type: 'absent', remark: '无故缺勤' } },
  'gaoxiang': { '10': { type: 'leave', remark: '年假' } },
  'chenjie':  { '22': { type: 'late', remark: '交通拥堵' } },
  'zhenghao': { '24': { type: 'lateEarly', remark: '夜间值班' } },
  'wangfang': { '01': { type: 'leave', remark: '事假' } },
};

// 时间工具（分钟数 => "HH:MM:SS"）
const fmt = (m) => {
  m = Math.round(m) % 1440;
  const h = String(Math.floor(m / 60)).padStart(2, '0');
  const mi = String(m % 60).padStart(2, '0');
  return `${h}:${mi}:00`;
};

// 计算工作时长（下班-上班-1小时午休，保留1位小数）
function calcHours(checkInMin, checkOutMin) {
  if (checkInMin == null || checkOutMin == null) return 0;
  const h = (checkOutMin - checkInMin - 60) / 60;
  return Math.round(h * 10) / 10;
}

// 生成一名员工一天的考勤
function genDay(emp, info, isFirstDay) {
  const over = overrides[emp.username] && overrides[emp.username][pad(info.day)];
  // 迟到/早退处理概率
  let type = 'normal';
  if (over) type = over.type;

  if (info.isWeekend) {
    return { date: `${YEAR}-${pad(MONTH)}-${pad(info.day)}`, weekday: info.weekday, in: null, out: null, status: '休息', hours: 0, remark: '周末休息' };
  }
  if (type === 'leave') {
    return { date: null, weekday: info.weekday, in: null, out: null, status: '请假', hours: 0, remark: (over && over.remark) || '请假' };
  }
  if (type === 'absent') {
    return { date: null, weekday: info.weekday, in: null, out: null, status: '缺勤', hours: 0, remark: (over && over.remark) || '缺勤' };
  }

  const r = rnd();
  if (type === 'normal' && r < emp.reliability) {
    // 正常出勤，8:00-8:30 打卡，18:00-18:25 下班，约 15% 概率加班
    const checkInMin = 480 + Math.floor(rnd() * 31);            // 480 = 08:00
    let checkOutMin;
    let remark = null;
    if (rnd() < 0.15) {
      checkOutMin = 1090 + Math.floor(rnd() * 151);             // 18:10 ~ 20:40 加班
      remark = '加班';
    } else {
      checkOutMin = 1080 + Math.floor(rnd() * 26);              // 18:00 ~ 18:25
    }
    return { date: null, weekday: info.weekday, in: fmt(checkInMin), out: fmt(checkOutMin), status: '正常', hours: calcHours(checkInMin, checkOutMin), remark };
  }

  // 异常考勤：迟到 / 早退 / 迟到早退
  const roll = rnd();
  const pick = type !== 'normal' ? type : (roll < 0.38 ? 'late' : roll < 0.62 ? 'early' : roll < 0.78 ? 'lateEarly' : roll < 0.9 ? 'leave' : 'absent');
  let checkInMin, checkOutMin, status, remark = null;
  switch (pick) {
    case 'late':
      checkInMin = 511 + Math.floor(rnd() * 60);   // 08:31 ~ 09:30
      checkOutMin = 1080 + Math.floor(rnd() * 26); // 18:00 ~ 18:25
      status = '迟到';
      remark = (over && over.remark) || null;
      break;
    case 'early':
      checkInMin = 480 + Math.floor(rnd() * 31);   // 08:00 ~ 08:30
      checkOutMin = 1020 + Math.floor(rnd() * 60); // 17:00 ~ 17:59
      status = '早退';
      remark = (over && over.remark) || null;
      break;
    case 'lateEarly':
      checkInMin = 511 + Math.floor(rnd() * 60);
      checkOutMin = 1020 + Math.floor(rnd() * 60);
      status = '迟到早退';
      remark = (over && over.remark) || null;
      break;
    case 'leave':
      return { date: null, weekday: info.weekday, in: null, out: null, status: '请假', hours: 0, remark: '请假' };
    case 'absent':
      return { date: null, weekday: info.weekday, in: null, out: null, status: '缺勤', hours: 0, remark: '缺勤' };
  }
  return { date: null, weekday: info.weekday, in: fmt(checkInMin), out: fmt(checkOutMin), status, hours: calcHours(checkInMin, checkOutMin), remark };
}

const pad = (n) => String(n).padStart(2, '0');
const iso = (d) => `${YEAR}-${pad(MONTH)}-${pad(d)}`;

// ---------- 生成 SQL ----------
const lines = [];
lines.push('-- ============================================================');
lines.push('-- 员工考勤系统 初始化脚本 (pt.sql)');
lines.push('-- 数据库: MySQL 8.4   默认班次: 08:30 上班 / 18:00 下班');
lines.push('-- 数据: 3 个部门、21 名员工、2026 年 7 月全月考勤');
lines.push('-- 执行方式: mysql -uroot -p < pt.sql');
lines.push('-- ============================================================');
lines.push('');
lines.push('CREATE DATABASE IF NOT EXISTS pt DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;');
lines.push('USE pt;');
lines.push('');
lines.push('SET NAMES utf8mb4;');
lines.push('SET FOREIGN_KEY_CHECKS = 0;');
lines.push('');

// 建表
lines.push('-- ---------------------------- 部门表 ----------------------------');
lines.push('DROP TABLE IF EXISTS salary_record;');
lines.push('DROP TABLE IF EXISTS sales_record;');
lines.push('DROP TABLE IF EXISTS attendance_record;');
lines.push('DROP TABLE IF EXISTS employee;');
lines.push('DROP TABLE IF EXISTS department;');
lines.push(`
CREATE TABLE department (
  id          BIGINT       NOT NULL AUTO_INCREMENT COMMENT '部门ID',
  name        VARCHAR(50)  NOT NULL COMMENT '部门名称',
  description VARCHAR(200) DEFAULT NULL COMMENT '部门描述',
  created_at  DATETIME     DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  PRIMARY KEY (id),
  UNIQUE KEY uk_dept_name (name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='部门表';
`);
lines.push(`
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
`);
lines.push(`
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
`);
lines.push(`
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
`);
lines.push(`
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
`);
lines.push('');

// 部门数据
lines.push('-- ---------------------------- 部门数据 ----------------------------');
departments.forEach((d) => {
  lines.push(`INSERT INTO department (id, name, description) VALUES (${d.id}, '${d.name}', '${d.description}');`);
});
lines.push('');

// 员工数据
lines.push('-- ---------------------------- 员工数据 (21人) ----------------------------');
employees.forEach((e) => {
  lines.push(`INSERT INTO employee (id, username, password, name, gender, department_id, position, phone, hire_date, salary_type, base_salary) VALUES (${e.id}, '${e.username}', '123456', '${e.name}', ${e.gender}, ${e.dept}, '${e.position}', '${e.phone}', '${e.hireDate}', '${e.salaryType}', ${e.baseSalary});`);
});
lines.push('');

// 销售业绩数据
lines.push('-- ---------------------------- 2026年7月销售业绩 ----------------------------');
for (const [username, amount] of Object.entries(salesAmounts)) {
  const emp = employees.find((e) => e.username === username);
  lines.push(`INSERT INTO sales_record (employee_id, stat_month, amount) VALUES (${emp.id}, '2026-07', ${amount});`);
}
lines.push('');

// 考勤数据
lines.push('-- ---------------------------- 2026年7月考勤数据 ----------------------------');
let total = 0;
for (const emp of employees) {
  for (let d = 1; d <= DAYS; d++) {
    const info = dayInfo(d);
    const rec = genDay(emp, info, d === 1);
    const inSql = rec.in ? `'${rec.in}'` : 'NULL';
    const outSql = rec.out ? `'${rec.out}'` : 'NULL';
    const remarkSql = rec.remark ? `'${rec.remark}'` : 'NULL';
    lines.push(`INSERT INTO attendance_record (employee_id, attendance_date, weekday, check_in_time, check_out_time, status, work_hours, remark) VALUES (${emp.id}, '${iso(d)}', '${rec.weekday}', ${inSql}, ${outSql}, '${rec.status}', ${rec.hours}, ${remarkSql});`);
    total++;
  }
}
lines.push('');
lines.push('SET FOREIGN_KEY_CHECKS = 1;');
lines.push('');
lines.push('-- 校验统计');
lines.push(`SELECT '部门数' AS 项目, COUNT(*) AS 数量 FROM department UNION ALL SELECT '员工数', COUNT(*) FROM employee UNION ALL SELECT '考勤记录数', COUNT(*) FROM attendance_record UNION ALL SELECT '销售业绩数', COUNT(*) FROM sales_record;`);
lines.push('');

const sql = lines.join('\n');
const outPath = path.join(__dirname, '..', 'pt.sql');
fs.writeFileSync(outPath, sql, 'utf8');
console.log(`生成成功: ${outPath}`);
console.log(`考勤记录数: ${total} (21人 x 31天)`);
console.log(`销售业绩数: ${Object.keys(salesAmounts).length}`);
