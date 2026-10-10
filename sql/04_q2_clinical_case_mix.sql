--Q2 — Clinical Case Mix and Hospital Utilization
--1. admissions_q2_diagnosis view

CREATE VIEW admissions_q2_diagnosis_extended AS
SELECT 
	a.*,
	SUBSTR(a.DIAG_PRINC, 1,3) AS icd10_category,
	l.icd10_chapter_code,
	l.icd10_chapter_label,
	(
	CASE WHEN TRIM(DIAGSEC1) <> '' THEN 1 ELSE 0 END +
	CASE WHEN TRIM(DIAGSEC2) <> '' THEN 1 ELSE 0 END +
	CASE WHEN TRIM(DIAGSEC3) <> '' THEN 1 ELSE 0 END +
	CASE WHEN TRIM(DIAGSEC4) <> '' THEN 1 ELSE 0 END +
	CASE WHEN TRIM(DIAGSEC5) <> '' THEN 1 ELSE 0 END +
	CASE WHEN TRIM(DIAGSEC6) <> '' THEN 1 ELSE 0 END +
	CASE WHEN TRIM(DIAGSEC7) <> '' THEN 1 ELSE 0 END 
	) AS secondary_diag_count								---- Secondary diagnosis count:
															-- Number of non-blank secondary diagnosis fields across DIAGSEC1–DIAGSEC7.
															-- This is a coding-density measure, not a comorbidity index.
FROM SIH_SUS_2024_analysis_ready a
LEFT JOIN icd10_chapter_lookup_en l
	ON SUBSTR(a.DIAG_PRINC, 1,3) = l.icd10_category;


--2. Q2.1 Overall ICD-10 chapter distribution
		-- Core dashboard result
		
SELECT 
    icd10_chapter_label,
    COUNT(*) AS admissions,
    ROUND( 100.0 * COUNT(*)/(SELECT COUNT(*) FROM admissions_q2_diagnosis_extended) ,2) AS pct_admissions
FROM admissions_q2_diagnosis_extended 
GROUP BY icd10_chapter_label
ORDER BY admissions DESC;

--3. Q2.2 Top three ICD-10 categories within the six highest-volume chapters
		-- Core dashboard result
  		-- admissions + % within chapter + avg secondary diagnosis count
   
WITH chapter_totals AS (
	SELECT 
		icd10_chapter_label,
		COUNT (*) AS chapter_admissions
	FROM admissions_q2_diagnosis_extended
	WHERE icd10_chapter_label IN (
		'Pregnancy, childbirth and the puerperium',
		'Injury, poisoning and certain other consequences of external causes',
		'Diseases of the digestive system',
		'Diseases of the respiratory system',
		'Diseases of the circulatory system',
		'Neoplasms'
	)
	GROUP BY icd10_chapter_label 
)
SELECT *
FROM (
	SELECT 
		a.icd10_chapter_label,
		SUBSTR(DIAG_PRINC, 1,3) AS icd10_category,
		COUNT(*) AS admissions,
		ROUND(100.0 * COUNT(*) /ct.chapter_admissions,2) AS pct_of_chapter,
		ROUND (AVG (a.secondary_diag_count),2) AS avg_secondary_dx,
		ROW_NUMBER () OVER (
			PARTITION BY a.icd10_chapter_label
			ORDER BY COUNT(*) DESC
		) AS rn
	FROM admissions_q2_diagnosis_extended a
	JOIN chapter_totals ct
		ON a.icd10_chapter_label = ct.icd10_chapter_label
	GROUP BY a.icd10_chapter_label, SUBSTR (DIAG_PRINC,1,3)
)
WHERE rn <=3
ORDER BY icd10_chapter_label, rn;


--4. Q2.3 ICD-10 chapter and ICU utilization
				-- Core dashboard result

SELECT 
    icd10_chapter_label,
    COUNT(*) AS admissions,
    SUM(CASE WHEN MARCA_UTI <> 0 THEN 1 ELSE 0 END) AS icu_admissions,
    ROUND(SUM(CASE WHEN MARCA_UTI <> 0 THEN 1 ELSE 0 END) * 100.0 / COUNT(*),2) AS icu_pct,
    ROUND(AVG(DIAS_PERM),2) AS mean_los
FROM admissions_q2_diagnosis_extended
GROUP BY icd10_chapter_label
ORDER BY icu_pct DESC;

--5. Q2.4 ICD-10 chapter and mortality
				-- Core dashboard result

SELECT 
    icd10_chapter_label,
    COUNT(*) AS admissions,
    SUM(CASE WHEN MORTE = 1 THEN 1 ELSE 0 END) AS deaths,
    ROUND(SUM(CASE WHEN MORTE = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*),2) AS mortality_pct
FROM admissions_q2_diagnosis_extended
GROUP BY icd10_chapter_label
ORDER BY mortality_pct DESC;


-- 6. ============================================================
--    Supporting analysis — Injury secondary-diagnosis structure
--    ============================================================

-- 6.1 Secondary diagnosis count distribution 

SELECT
    secondary_diag_count,
    COUNT(*) AS admissions
FROM admissions_q2_diagnosis_extended
WHERE icd10_chapter_label =
    'Injury, poisoning and certain other consequences of external causes'
GROUP BY secondary_diag_count
ORDER BY secondary_diag_count;


-- 6.2 DIAGSEC1 category distribution

SELECT
    SUBSTR(DIAGSEC1, 1, 3) AS secondary_dx_category,
    COUNT(*) AS admissions
FROM admissions_q2_diagnosis_extended
WHERE icd10_chapter_label =
    'Injury, poisoning and certain other consequences of external causes'
GROUP BY SUBSTR(DIAGSEC1, 1, 3)
ORDER BY admissions DESC
LIMIT 20;


-- 6.3 3 DIAGSEC position population
   		-- Supporting/evidence analysis

SELECT
	icd10_chapter_label,
    SUM(CASE WHEN TRIM(DIAGSEC1) <> '' THEN 1 ELSE 0 END) AS dx1,
    SUM(CASE WHEN TRIM(DIAGSEC2) <> '' THEN 1 ELSE 0 END) AS dx2,
    SUM(CASE WHEN TRIM(DIAGSEC3) <> '' THEN 1 ELSE 0 END) AS dx3,
    SUM(CASE WHEN TRIM(DIAGSEC4) <> '' THEN 1 ELSE 0 END) AS dx4,
    SUM(CASE WHEN TRIM(DIAGSEC5) <> '' THEN 1 ELSE 0 END) AS dx5,
    SUM(CASE WHEN TRIM(DIAGSEC6) <> '' THEN 1 ELSE 0 END) AS dx6,
    SUM(CASE WHEN TRIM(DIAGSEC7) <> '' THEN 1 ELSE 0 END) AS dx7
FROM admissions_q2_diagnosis_extended
WHERE icd10_chapter_label =
    'Injury, poisoning and certain other consequences of external causes';
