-- ============================================================
-- Q4 — How do hospitalization costs vary with case mix
--      and resource use?
-- ============================================================

--Q4.1 — LOS × Cost
--How does hospitalization cost (VAL_TOT) vary by length of stay (LOS) categories?

WITH ranked AS (
    SELECT
        CASE
            WHEN DIAS_PERM = 0 THEN '0 days'
            WHEN DIAS_PERM BETWEEN 1 AND 3 THEN '1-3 days'
            WHEN DIAS_PERM BETWEEN 4 AND 7 THEN '4-7 days'
            WHEN DIAS_PERM BETWEEN 8 AND 30 THEN '8-30 days'
            ELSE '31+ days'
        END AS los_category,
        VAL_TOT,
        ROW_NUMBER() OVER (
            PARTITION BY CASE
                WHEN DIAS_PERM = 0 THEN '0 days'
                WHEN DIAS_PERM BETWEEN 1 AND 3 THEN '1-3 days'
                WHEN DIAS_PERM BETWEEN 4 AND 7 THEN '4-7 days'
                WHEN DIAS_PERM BETWEEN 8 AND 30 THEN '8-30 days'
                ELSE '31+ days'
            END
            ORDER BY VAL_TOT
        ) AS rn,
        COUNT(*) OVER (
            PARTITION BY CASE
                WHEN DIAS_PERM = 0 THEN '0 days'
                WHEN DIAS_PERM BETWEEN 1 AND 3 THEN '1-3 days'
                WHEN DIAS_PERM BETWEEN 4 AND 7 THEN '4-7 days'
                WHEN DIAS_PERM BETWEEN 8 AND 30 THEN '8-30 days'
                ELSE '31+ days'
            END
        ) AS n
    FROM SIH_SUS_2024_analysis_ready
)
SELECT
    los_category,
    COUNT(*) AS admissions,
    ROUND(100.0 * COUNT(*) /  (SELECT COUNT(*) FROM admissions_q2_diagnosis_extended), 2) AS pct_admissions,
    ROUND(AVG(VAL_TOT), 2) AS mean_cost,
    ROUND(AVG(CASE
        WHEN rn IN ((n + 1) / 2, (n + 2) / 2) THEN VAL_TOT
    END), 2) AS median_cost,
    ROUND(AVG(CASE WHEN rn = CAST(0.75 * n AS INT) THEN VAL_TOT END), 2) AS p75_cost,
	ROUND(AVG(CASE WHEN rn = CAST(0.90 * n AS INT) THEN VAL_TOT END), 2) AS p90_cost,
	ROUND(AVG(CASE WHEN rn = CAST(0.95 * n AS INT) THEN VAL_TOT END), 2) AS p95_cost,
	ROUND(MAX(VAL_TOT), 2) AS max_cost
FROM ranked
GROUP BY los_category;


--4.2 ICU/No-ICU × Cost

SELECT
    CASE WHEN MARCA_UTI <> 0 THEN 'ICU' ELSE 'No ICU' END AS icu_status,
    COUNT(*) AS admissions,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS pct_admissions,
    ROUND(AVG(VAL_TOT), 2) AS avg_cost,
    ROUND(AVG(VAL_TOT / NULLIF(DIAS_PERM, 0)), 2) AS avg_cost_per_day,
    ROUND(AVG(VAL_SH), 2) AS avg_sh_cost,
    ROUND(AVG(VAL_SP), 2) AS avg_sp_cost
FROM SIH_SUS_2024_analysis_ready
GROUP BY CASE WHEN MARCA_UTI <> 0 THEN 'ICU' ELSE 'No ICU' END;


-- Q4.3 — ESPEC / Bed Specialty × Cost & Resource Profile

WITH ranked AS (
    SELECT
        a.ESPEC AS espec_code,
        l.def_leitos_en AS bed_specialty,
        a.VAL_TOT,
        a.VAL_SH,
        a.VAL_SP,
        a.DIAS_PERM,
        a.QT_DIARIAS,
        a.MARCA_UTI,
        a.MARCA_UCI,
        ROW_NUMBER() OVER (PARTITION BY a.ESPEC  ORDER BY a.VAL_TOT) AS rn,
        COUNT(*) OVER (PARTITION BY a.ESPEC) AS n
    FROM SIH_SUS_2024_analysis_ready AS a
    LEFT JOIN LEITOS_enriched AS l
        ON a.ESPEC = l.cod
)
SELECT
    espec_code,
    bed_specialty,
    COUNT(*) AS admissions,
    ROUND(
        100.0 * COUNT(*) / SUM(COUNT(*)) OVER (),
        2
    ) AS pct_of_all_admissions,
    ROUND(AVG(VAL_TOT), 2) AS mean_total_cost,
    ROUND( AVG(CASE WHEN rn IN ((n + 1) / 2, (n + 2) / 2) THEN VAL_TOT END), 2) AS median_total_cost,
    ROUND(AVG(VAL_TOT / NULLIF(DIAS_PERM, 0)), 2) AS avg_cost_per_day,
    ROUND(AVG(DIAS_PERM), 2) AS avg_los,
    ROUND(AVG(QT_DIARIAS), 2) AS avg_qt_diarias,
    ROUND(100.0 * SUM(CASE WHEN MARCA_UTI <> 0 THEN 1 ELSE 0 END) / COUNT(*), 2) AS icu_pct,
    ROUND(100.0 * SUM(CASE WHEN MARCA_UCI <> 0 THEN 1 ELSE 0 END) / COUNT(*), 2) AS uci_pct,
    ROUND(AVG(VAL_SH), 2) AS mean_hospital_services,
    ROUND(AVG(VAL_SP), 2) AS mean_professional_services
FROM ranked
GROUP BY espec_code, bed_specialty
ORDER BY admissions DESC;

--Q4.4 — ICU × Cost (Corrected Query)

WITH ranked AS (
    SELECT
        CASE 
            WHEN MARCA_UTI <> 0 THEN 'ICU'
            ELSE 'No ICU'
        END AS icu_flag,
        VAL_TOT,
        DIAS_PERM,
        ROW_NUMBER() OVER (
            PARTITION BY CASE WHEN MARCA_UTI <> 0 THEN 'ICU' ELSE 'No ICU' END
            ORDER BY VAL_TOT
        ) AS rn,
        COUNT(*) OVER (
            PARTITION BY CASE WHEN MARCA_UTI <> 0 THEN 'ICU' ELSE 'No ICU' END
        ) AS n
    FROM SIH_SUS_2024_analysis_ready
)
SELECT
    icu_flag,
    COUNT(*) AS admissions,
    ROUND(AVG(VAL_TOT), 2) AS mean_cost,
    ROUND(AVG(CASE
        WHEN rn IN ((n + 1) / 2, (n + 2) / 2) THEN VAL_TOT
    END), 2) AS median_cost,
    ROUND(AVG(CASE WHEN rn = CAST(0.75 * n AS INT) THEN VAL_TOT END), 2) AS p75_cost,
	ROUND(AVG(CASE WHEN rn = CAST(0.90 * n AS INT) THEN VAL_TOT END), 2) AS p90_cost,
	ROUND(AVG(CASE WHEN rn = CAST(0.95 * n AS INT) THEN VAL_TOT END), 2) AS p95_cost,
	ROUND(MAX(VAL_TOT), 2) AS max_cost,
    ROUND(AVG(VAL_TOT / NULLIF(DIAS_PERM,0)), 2) AS avg_cost_per_day
FROM ranked
GROUP BY icu_flag;


--Q4.5 Continuation vs single admission cost/utilization


SELECT
    CASE
        WHEN i.has_ident_5 = 1 THEN 'continuation'
        ELSE 'single admission'
    END AS continuation_status,
    COUNT(*) AS admissions,
    ROUND(
        COUNT(*) * 100.0 /
        SUM(COUNT(*)) OVER (),
        2
    ) AS pct_admissions,
    ROUND(AVG(a.DIAS_PERM), 2) AS avg_los,
    ROUND(SUM(a.VAL_TOT), 2) AS total_cost,
 	ROUND(SUM(a.VAL_TOT) * 100.0 / SUM(SUM(a.VAL_TOT)) OVER (), 2) AS pct_total_cost,
    ROUND(AVG(a.VAL_TOT), 2) AS mean_cost,
    ROUND(MAX(a.VAL_TOT), 2) AS max_cost,
    ROUND(AVG(a.VAL_SH), 2) AS mean_val_sh,
    ROUND(AVG(a.VAL_SP), 2) AS mean_val_sp
FROM SIH_SUS_2024_analysis_ready AS a
LEFT JOIN IDENT_lookup_final AS i
    ON a.N_AIH = i.N_AIH
   AND a.ANO_CMPT = i.ANO_CMPT
   AND a.MES_CMPT = i.MES_CMPT
GROUP BY continuation_status
ORDER BY admissions DESC;


--Q4.6 Clinical case mix × cost:  ICD-10 chapter × cost

WITH ranked AS (
		SELECT 
		icd10_chapter_label,
		VAL_TOT,
		VAL_SH,
		VAL_SP,
		ROW_NUMBER () OVER (
			PARTITION BY icd10_chapter_label ORDER BY VAL_TOT
			) AS rn,
			COUNT (*) OVER (
			PARTITION BY icd10_chapter_label
			) AS n
		FROM admissions_q2_diagnosis_extended
)
SELECT 
	icd10_chapter_label,
	COUNT (*) AS admissions,
	ROUND(100.0 * COUNT(*) /  (SELECT COUNT(*) FROM admissions_q2_diagnosis_extended), 2) AS pct_admissions,
	ROUND(AVG(VAL_TOT),2) AS mean_cost,
	ROUND(AVG(CASE WHEN rn IN ((n+1)/2 , (n+2)/2) THEN VAL_TOT END),2) AS median_cost,
	ROUND (AVG(VAL_SH),2) AS mean_val_sh,
	ROUND(AVG(VAL_SP), 2) AS mean_val_sp,
	ROUND(SUM(VAL_TOT),2) AS total_cost,
	ROUND(SUM(VAL_TOT)*100/(SELECT SUM(VAL_TOT) FROM admissions_q2_diagnosis_extended),2) AS pct_total_cost
FROM ranked 
GROUP BY icd10_chapter_label 
ORDER BY pct_total_cost DESC;
          
                   
--4.7 Secondary Diagnosis Count × Cost × LOS
                   
WITH ranked AS (
    SELECT
        secondary_diag_count,
        VAL_TOT,
        DIAS_PERM,
        ROW_NUMBER() OVER (
            PARTITION BY secondary_diag_count ORDER BY VAL_TOT
        ) AS rn,
        COUNT(*) OVER (
            PARTITION BY secondary_diag_count
        ) AS n
    FROM admissions_q2_diagnosis_extended
)
SELECT
    secondary_diag_count,
    COUNT(*) AS admissions,
    ROUND(100.0 * COUNT(*) /  (SELECT COUNT(*) FROM admissions_q2_diagnosis_extended), 2) AS pct_admissions,
    ROUND(AVG(VAL_TOT), 2) AS mean_cost,
    ROUND(AVG(CASE WHEN rn IN ((n+1)/2, (n+2)/2) THEN VAL_TOT END), 2) AS median_cost,
    ROUND(AVG(DIAS_PERM), 2) AS mean_los,
    ROUND(AVG(CASE WHEN DIAS_PERM > 0 THEN VAL_TOT / DIAS_PERM END), 2) AS mean_cost_per_day
FROM ranked
GROUP BY secondary_diag_count
ORDER BY secondary_diag_count;


---Q4.8  ICU_UCI_cost_components
SELECT
    COUNT(CASE WHEN VAL_UTI > 0 AND MARCA_UTI <> 0 THEN 1 END)
        AS admissions_nonzero_val_uti,
    Round(AVG(CASE WHEN VAL_UTI > 0 AND MARCA_UTI <> 0 THEN VAL_UTI END) ,2)
        AS mean_val_uti,
    MEDIAN(CASE WHEN VAL_UTI > 0 AND MARCA_UTI <> 0 THEN VAL_UTI END)
        AS median_val_uti,
    SUM(CASE WHEN VAL_UTI > 0 AND MARCA_UTI <> 0 THEN VAL_UTI END)
        AS total_val_uti,
    COUNT(CASE WHEN VAL_UCI > 0 AND MARCA_UCI <> 0 THEN 1 END)
        AS admissions_nonzero_val_uci,
    ROUND(AVG(CASE WHEN VAL_UCI > 0 AND MARCA_UCI <> 0 THEN VAL_UCI END),2)
        AS mean_val_uci,
    MEDIAN(CASE WHEN VAL_UCI > 0 AND MARCA_UCI <> 0 THEN VAL_UCI END)
        AS median_val_uci,
    SUM(CASE WHEN VAL_UCI > 0 AND MARCA_UCI <> 0 THEN VAL_UCI END)
        AS total_val_uci,
    ROUND(
        100.0 * SUM(CASE WHEN MARCA_UTI <> 0 THEN VAL_UTI ELSE 0 END)
        / NULLIF(SUM(CASE WHEN MARCA_UTI <> 0 THEN VAL_TOT ELSE 0 END), 0),
        2
    ) AS pct_val_uti_total,
    ROUND(
        100.0 * SUM(CASE WHEN MARCA_UCI <> 0 THEN VAL_UCI ELSE 0 END)
        / NULLIF(SUM(CASE WHEN MARCA_UCI <> 0 THEN VAL_TOT ELSE 0 END), 0),
        2
    ) AS pct_val_uci_total
FROM SIH_SUS_2024_analysis_ready;



