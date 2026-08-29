package com.pt.attendance.dto;

import java.util.List;

/**
 * 发工资请求
 */
public class PayRequestDTO {

    private List<Long> ids;

    public List<Long> getIds() {
        return ids;
    }

    public void setIds(List<Long> ids) {
        this.ids = ids;
    }
}
