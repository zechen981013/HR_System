package com.pt.attendance.service;

import org.springframework.stereotype.Component;

import java.math.BigDecimal;
import java.math.RoundingMode;

/**
 * 个人所得税计算（综合所得-月度预扣，中国/深圳标准）
 * 起征点 5000 元/月，超额累进税率。
 */
@Component
public class TaxCalculator {

    // 月度税率表：上限(元,含) -> [税率, 速算扣除数]
    private static final double[][] BRACKETS = {
            {3000, 0.03, 0},
            {12000, 0.10, 210},
            {25000, 0.20, 1410},
            {35000, 0.25, 2660},
            {55000, 0.30, 4410},
            {80000, 0.35, 7160},
            {Double.MAX_VALUE, 0.45, 15160}
    };

    /**
     * 计算月度个人所得税
     *
     * @param taxableIncome 应纳税所得额 = 应发工资 - 起征点(5000) - 五险一金
     */
    public BigDecimal compute(BigDecimal taxableIncome) {
        if (taxableIncome == null || taxableIncome.signum() <= 0) {
            return BigDecimal.ZERO.setScale(2, RoundingMode.HALF_UP);
        }
        double amount = taxableIncome.doubleValue();
        for (double[] b : BRACKETS) {
            if (amount <= b[0]) {
                double tax = amount * b[1] - b[2];
                return BigDecimal.valueOf(Math.max(tax, 0)).setScale(2, RoundingMode.HALF_UP);
            }
        }
        return BigDecimal.ZERO.setScale(2, RoundingMode.HALF_UP);
    }
}
