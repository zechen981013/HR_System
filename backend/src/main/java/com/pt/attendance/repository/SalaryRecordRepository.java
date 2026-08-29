package com.pt.attendance.repository;

import com.pt.attendance.entity.SalaryRecord;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface SalaryRecordRepository extends JpaRepository<SalaryRecord, Long> {

    List<SalaryRecord> findByYearAndMonth(Integer year, Integer month);

    Optional<SalaryRecord> findByEmployeeIdAndYearAndMonth(Long employeeId, Integer year, Integer month);
}
