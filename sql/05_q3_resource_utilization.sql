-- ============================================================
-- Q3 — How does resource utilization vary?
-- ============================================================

--1. --

CREATE VIEW q3_ready AS
SELECT
    a.*,
    l.has_ident_1,
    l.has_ident_5,
    l.continuation_count,
    l.continuation_days,
    l.continuation_cost,
    l.admission_start,
    l.discharge_end
FROM SIH_SUS_2024_analysis_ready a
LEFT JOIN IDENT_lookup_final l
  ON a.N_AIH = l.N_AIH
 AND a.ANO_CMPT = l.ANO_CMPT
 AND a.MES_CMPT = l.MES_CMPT;

--2.q3_resource_utilization

CREATE VIEW q3_resource_utilization AS
SELECT
    a.*,
    -- LOS category
    CASE
        WHEN a.DIAS_PERM = 0 THEN '0 days'
        WHEN a.DIAS_PERM BETWEEN 1 AND 3 THEN '1-3 days'
        WHEN a.DIAS_PERM BETWEEN 4 AND 7 THEN '4-7 days'
        WHEN a.DIAS_PERM BETWEEN 8 AND 30 THEN '8-30 days'
        WHEN a.DIAS_PERM >= 31 THEN '31+ days'
    END AS LOS_category,
    -- Age group (Q1 definition)
    CASE
        WHEN a.COD_IDADE IN (0,5) THEN 'Unknown/Unreliable'
        WHEN a.COD_IDADE IN (2,3) THEN '<1'
        WHEN a.COD_IDADE = 4 AND a.IDADE BETWEEN 1 AND 4 THEN '1-4'
        WHEN a.COD_IDADE = 4 AND a.IDADE BETWEEN 5 AND 14 THEN '5-14'
        WHEN a.COD_IDADE = 4 AND a.IDADE BETWEEN 15 AND 24 THEN '15-24'
        WHEN a.COD_IDADE = 4 AND a.IDADE BETWEEN 25 AND 34 THEN '25-34'
        WHEN a.COD_IDADE = 4 AND a.IDADE BETWEEN 35 AND 44 THEN '35-44'
        WHEN a.COD_IDADE = 4 AND a.IDADE BETWEEN 45 AND 54 THEN '45-54'
        WHEN a.COD_IDADE = 4 AND a.IDADE BETWEEN 55 AND 64 THEN '55-64'
        WHEN a.COD_IDADE = 4 AND a.IDADE >= 65 THEN '65+'
        ELSE 'Other'
    END AS age_group_pub,
    -- ICU / UCI flags
    CASE WHEN a.MARCA_UTI = 0 THEN 'No ICU' ELSE 'ICU involvement' END AS icu_involvement,
    a.MARCA_UTI AS icu_type,
    a.UTI_MES_TO AS icu_days,
    CASE WHEN a.MARCA_UCI = 0 THEN 'No UCI' ELSE 'UCI involvement' END AS uci_involvement,
    a.UTI_INT_TO AS uci_days,
    -- Continuation fields
    l.has_ident_1,
    l.has_ident_5,
    l.continuation_count,
    l.continuation_days,
    l.continuation_cost,
    l.admission_start,
    l.discharge_end
FROM SIH_SUS_2024_analysis_ready a
LEFT JOIN IDENT_lookup_final l
  ON a.N_AIH = l.N_AIH
 AND a.ANO_CMPT = l.ANO_CMPT
 AND a.MES_CMPT = l.MES_CMPT;

-- 3.Q3.1 Length-of-stay distribution

WITH ordered AS (
    SELECT
        DIAS_PERM,
        ROW_NUMBER() OVER (ORDER BY DIAS_PERM) AS rn
    FROM q3_ready
),
positions AS (
    SELECT 3446714.25 AS position, 'P25' AS percentile
    UNION ALL SELECT 6893427.50, 'P50'
    UNION ALL SELECT 10340140.75, 'P75'
    UNION ALL SELECT 12408168.70, 'P90'
    UNION ALL SELECT 13097511.35, 'P95'
)
SELECT
    p.percentile,
    p.position,
    lower_value.DIAS_PERM AS lower_value,
    upper_value.DIAS_PERM AS upper_value,
    lower_value.DIAS_PERM
        + (p.position - CAST(p.position AS INTEGER))
        * (upper_value.DIAS_PERM - lower_value.DIAS_PERM)
        AS percentile_value
FROM positions p
JOIN ordered lower_value
    ON lower_value.rn = CAST(p.position AS INTEGER)
JOIN ordered upper_value
    ON upper_value.rn = CAST(p.position AS INTEGER) + 1
ORDER BY p.position;


--4.Q3.2  ICU by patient characteristics: ICU involvement by age and sex

SELECT
	age_group_pub AS age_group,
    CASE age_group_pub
    	WHEN 'Unknown/Unreliable' THEN 0
    	WHEN '<1' THEN 1
    	WHEN '1-4' THEN 2
    	WHEN '5-14' THEN 3
    	WHEN '15-24' THEN 4
    	WHEN '25-34' THEN 5
    	WHEN '35-44' THEN 6
    	WHEN '45-54' THEN 7
    	WHEN '55-64' THEN 8
    	WHEN '65+' THEN 9
	END AS age_group_order,
    CASE
        WHEN SEXO = 1 THEN 'Male'
        WHEN SEXO = 3 THEN 'Female'
        ELSE 'Unknown'
    END AS sex,
    COUNT(*) AS total_admissions,
    SUM(CASE WHEN MARCA_UTI <> 0 THEN 1 ELSE 0 END) AS icu_admissions,
    ROUND(
        100.0 * SUM(CASE WHEN MARCA_UTI <> 0 THEN 1 ELSE 0 END)
        / COUNT(*),
        2
    ) AS icu_involvement_rate_pct
FROM q3_resource_utilization
GROUP BY
    age_group_pub,
    SEXO
ORDER BY
    CASE age_group_pub
        WHEN 'Unknown/Unreliable' THEN 0
        WHEN '<1' THEN 1
        WHEN '1-4' THEN 2
        WHEN '5-14' THEN 3
        WHEN '15-24' THEN 4
        WHEN '25-34' THEN 5
        WHEN '35-44' THEN 6
        WHEN '45-54' THEN 7
        WHEN '55-64' THEN 8
        WHEN '65+' THEN 9
    END,
    SEXO;


--5.Q3.3 ICU vs non-ICU mortality by LOS

SELECT
    LOS_category,
    icu_involvement,
    COUNT(*) AS admissions,
    SUM(CASE WHEN MORTE = 1 THEN 1 ELSE 0 END) AS deaths,
    ROUND(
        100.0 * SUM(CASE WHEN MORTE = 1 THEN 1 ELSE 0 END) / COUNT(*),
        2
    ) AS mortality_pct
FROM q3_resource_utilization
GROUP BY
    LOS_category,
    icu_involvement
ORDER BY
    CASE LOS_category
        WHEN '0 days' THEN 1
        WHEN '1-3 days' THEN 2
        WHEN '4-7 days' THEN 3
        WHEN '8-30 days' THEN 4
        WHEN '31+ days' THEN 5
    END,
    icu_involvement;


--6. Q3.4 ICU rate by state
-- State code = first two digits of MUNIC_RES. 
-- ICU involvement = MARCA_UTI <> 0.
--MUNIC_RES → first two digits → IBGE state code → validated state mapping → state name/abbreviation

SELECT
    SUBSTR(MUNIC_RES, 1,2) AS state_code,
    COUNT(*) AS total_admissions,
    SUM(
        CASE WHEN MARCA_UTI <> 0 THEN 1 ELSE 0 END
    ) AS icu_admissions,
    ROUND(
        100.0 * SUM(
            CASE WHEN MARCA_UTI <> 0 THEN 1 ELSE 0 END
        ) / COUNT(*),
        2
    ) AS icu_pct
FROM q3_resource_utilization
GROUP BY
    SUBSTR(MUNIC_RES, 1,2)
ORDER BY
    state_code;

--7. Q3.5 Specialty-level resource utilization
-- ESPEC is enriched through the validated LEITOS lookup.
-- ICU involvement: MARCA_UTI <> 0, LOS: DIAS_PERM, Mortality: MORTE = 1

SELECT
    a.ESPEC AS espec_code,
    l.def_leitos_en AS bed_specialty,
    COUNT(*) AS admissions,
    SUM(CASE WHEN a.MARCA_UTI <> 0 THEN 1 ELSE 0 END) AS icu_admissions,
    ROUND( 100.0 * SUM(CASE WHEN a.MARCA_UTI <> 0 THEN 1 ELSE 0 END) / COUNT(*), 2) AS icu_pct,
    ROUND(AVG(a.DIAS_PERM), 2) AS avg_los,
    SUM(CASE WHEN a.MORTE = 1 THEN 1 ELSE 0 END) AS deaths,
    ROUND(100.0 * SUM(CASE WHEN a.MORTE = 1 THEN 1 ELSE 0 END) / COUNT(*), 2) AS mortality_pct
FROM SIH_SUS_2024_analysis_ready a
LEFT JOIN LEITOS_enriched l
    ON a.ESPEC = l.cod
GROUP BY
    a.ESPEC,
    l.def_leitos_en
ORDER BY
    admissions DESC;

--8. Q3.6 icu_diagnostic_case_mix

SELECT
    icd10_chapter_label,
    COUNT(*) AS total_admissions,
    SUM(CASE WHEN MARCA_UTI <> 0 THEN 1 ELSE 0 END) AS icu_admissions,
    ROUND(
        SUM(CASE WHEN MARCA_UTI <> 0 THEN 1 ELSE 0 END) * 100.0 / COUNT(*),
        2
    ) AS icu_pct_within_chapter,
    ROUND(
        SUM(CASE WHEN MARCA_UTI <> 0 THEN 1 ELSE 0 END) * 100.0
        / SUM(SUM(CASE WHEN MARCA_UTI <> 0 THEN 1 ELSE 0 END)) OVER (),
        2
    ) AS pct_of_all_icu_admissions
FROM admissions_q2_diagnosis_extended
GROUP BY icd10_chapter_label
ORDER BY total_admissions DESC;

