WITH CombinedData AS (
    SELECT 
        AS_OF_DATE,
        ITEM_VALUE
    FROM DMS_OUT_MARS_MUTEDRISK_VARPNL
    WHERE AIIB_MUTED_CS_RISK_NODE_NAME = 'Firm'
      AND ITEM_NAME LIKE '%_99_HVAR_SCENARIO%'
      AND AS_OF_DATE = EOMONTH(AS_OF_DATE)  -- Only month-end rows
    UNION ALL
    SELECT 
        AS_OF_DATE,
        ITEM_VALUE
    FROM DMS_OUT_MARS_FULLRISK_VARPNL
    WHERE AIIB_FULL_RISK_FACTOR_NODE_NAME = 'Firm'
      AND ITEM_NAME LIKE '%_99_HVAR_SCENARIO%'
      AND AS_OF_DATE = EOMONTH(AS_OF_DATE)  -- Only month-end rows
),
StatsWithVaR AS (
    SELECT
        AS_OF_DATE,
        ITEM_VALUE,
        AVG(ITEM_VALUE) OVER (PARTITION BY AS_OF_DATE) AS Mean_Item_Value,
        STDEV(ITEM_VALUE) OVER (PARTITION BY AS_OF_DATE) AS StdDev_Item_Value,
        COUNT(*) OVER (PARTITION BY AS_OF_DATE) AS NumObs,
        PERCENTILE_CONT(0.01) WITHIN GROUP (ORDER BY ITEM_VALUE ASC) OVER (PARTITION BY AS_OF_DATE) AS VaR_1PCT_RAW
    FROM CombinedData
),
FinalStats AS (
    SELECT DISTINCT
        AS_OF_DATE,
        Mean_Item_Value,
        StdDev_Item_Value,
        NumObs,
        VaR_1PCT_RAW
    FROM StatsWithVaR
),
ExpectedShortfall AS (
    SELECT
        s.AS_OF_DATE,
        AVG(c.ITEM_VALUE) AS ES_1PCT_RAW
    FROM FinalStats s
    JOIN CombinedData c ON s.AS_OF_DATE = c.AS_OF_DATE
    WHERE c.ITEM_VALUE <= s.VaR_1PCT_RAW
    GROUP BY s.AS_OF_DATE
)
SELECT
    s.AS_OF_DATE,
    CAST(ROUND(s.Mean_Item_Value / 1000000.0, 1) AS DECIMAL(12, 2)) AS "Mean (USDm)",
    CAST(ROUND(s.StdDev_Item_Value / 1000000.0, 0) AS INT) AS "StdDev",
    CAST(ROUND(s.VaR_1PCT_RAW / -1000000.0, 0) AS INT) AS "99% VaR",
    CAST(ROUND(-(s.Mean_Item_Value - 2.3263 * s.StdDev_Item_Value) / 1000000.0, 0) AS INT) AS "Normal 99% VaR",
    CAST(ROUND(e.ES_1PCT_RAW / -1000000.0, 0) AS INT) AS "99% ES",
    CAST(ROUND(-(s.Mean_Item_Value - 2.6652 * s.StdDev_Item_Value) / 1000000.0, 0) AS INT) AS "Normal 99% ES"
FROM FinalStats s
JOIN ExpectedShortfall e ON s.AS_OF_DATE = e.AS_OF_DATE
ORDER BY s.AS_OF_DATE DESC;
