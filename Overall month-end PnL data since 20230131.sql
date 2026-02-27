SELECT 
    ITEM_NAME,
    AS_OF_DATE,
    SUM(ITEM_VALUE) AS TOTAL_ITEM_VALUE
FROM (
    SELECT ITEM_NAME, AS_OF_DATE, ITEM_VALUE
    FROM (
        SELECT 
            ITEM_NAME, 
            AS_OF_DATE, 
            ITEM_VALUE,
            ROW_NUMBER() OVER (
                PARTITION BY ITEM_NAME, YEAR(AS_OF_DATE), MONTH(AS_OF_DATE)
                ORDER BY AS_OF_DATE DESC
            ) AS rn
        FROM DMS_OUT_MARS_MUTEDRISK_VARPNL
        WHERE AIIB_MUTED_CS_RISK_NODE_NAME = 'Firm'
          AND ITEM_NAME LIKE '%_99_HVAR_SCENARIO%'
          AND AS_OF_DATE >= '2023-01-31' AND AS_OF_DATE <= '2025-07-31'
    ) t
    WHERE t.rn = 1

    UNION ALL

    SELECT ITEM_NAME, AS_OF_DATE, ITEM_VALUE
    FROM (
        SELECT 
            ITEM_NAME, 
            AS_OF_DATE, 
            ITEM_VALUE,
            ROW_NUMBER() OVER (
                PARTITION BY ITEM_NAME, YEAR(AS_OF_DATE), MONTH(AS_OF_DATE)
                ORDER BY AS_OF_DATE DESC
            ) AS rn
        FROM DMS_OUT_MARS_FULLRISK_VARPNL
        WHERE AIIB_FULL_RISK_FACTOR_NODE_NAME = 'Firm'
          AND ITEM_NAME LIKE '%_99_HVAR_SCENARIO%'
          AND AS_OF_DATE >= '2023-01-31' AND AS_OF_DATE <= '2025-07-31'
    ) t
    WHERE t.rn = 1
) AS combined
GROUP BY ITEM_NAME, AS_OF_DATE
ORDER BY ITEM_NAME, AS_OF_DATE DESC;

