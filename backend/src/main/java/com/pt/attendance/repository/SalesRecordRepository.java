package com.pt.attendance.repository;

import com.pt.attendance.entity.SalesRecord;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface SalesRecordRepository extends JpaRepository<SalesRecord, Long> {

    Optional<SalesRecord> findByEmployeeIdAndStatMonth(Long employeeId, String statMonth);

    List<SalesRecord> findByStatMonth(String statMonth);
}
