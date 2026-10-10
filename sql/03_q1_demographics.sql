--Q1 — Demographics and Geography
--1. Create admissions_derived view
-- Create derived analytical view for Q1 demographic and geographic analysis.
-- Includes age normalization/grouping, sex and race/color labels,
-- municipality/state geography, and conditional ethnicity

CREATE VIEW admissions_derived AS 
SELECT 
	---Age normalization : converts  IDADE into usable numeric years using COD_IDADE
	CASE
		WHEN COD_IDADE IN (2,3) THEN 0				---infants (<1 year, recorded in days/months)
		WHEN COD_IDADE =4 THEN IDADE				---valid years
		ELSE NULL									---unspecified/unsupported
	END AS age_in_years,
		---Age quality diagnostic flag: preserves distinction between code 0 and 5
	CASE
		WHEN COD_IDADE = 0 THEN 'Code 0-unspecified'
		WHEN COD_IDADE = 5 THEN 'Code 5-unsupported'
		WHEN COD_IDADE IN (2,3,4) THEN 'Valid'
		ELSE 'Other/Unexpected'
	END AS age_quality_flag,
		---Age grouping for public reporting (idade_pub scheme)
	CASE
		WHEN COD_IDADE IN (0,5) THEN 'Unknown/Unreliable'
		WHEN COD_IDADE IN (2,3) THEN '<1'
		WHEN COD_IDADE = 4 AND IDADE BETWEEN 1 AND 4 THEN '1-4'
		WHEN COD_IDADE = 4 AND IDADE BETWEEN 5 AND 14 THEN '5-14'
		WHEN COD_IDADE = 4 AND IDADE BETWEEN 15 AND 24 THEN '15-24'
		WHEN COD_IDADE = 4 AND IDADE BETWEEN 25 AND 34 THEN '25-34'
		WHEN COD_IDADE = 4 AND IDADE BETWEEN 35 AND 44 THEN '35-44'
		WHEN COD_IDADE = 4 AND IDADE BETWEEN 45 AND 54 THEN '45-54'
		WHEN COD_IDADE = 4 AND IDADE BETWEEN 55 AND 64 THEN '55-64'
		WHEN COD_IDADE = 4 AND IDADE >=65 THEN '65+'
		ELSE 'Other'
	END AS age_group_pub,
		---Race/Color: maps numeric codes to human-readable labels
	RACA_COR,
	CASE
		WHEN RACA_COR = 1 THEN 'Branca / White'
		WHEN RACA_COR = 2 THEN 'Preta / Black'
		WHEN RACA_COR = 3 THEN 'Parda / Brown/Mixed'
		WHEN RACA_COR = 4 THEN 'Amarela / Yellow (Asian descent)'
    	WHEN RACA_COR = 5 THEN 'Indígena / Indigenous'
    	WHEN RACA_COR = 99 THEN 'Não informado / Not informed'
    	ELSE 'Other / Other'
	END AS race_color_label,
	---Sex: harmonizes numeric codes into Male/Female/Other
	SEXO AS sex_code,
	CASE
		WHEN SEXO = 1 THEN 'Male'
		WHEN SEXO = 3 THEN 'Female'
    	ELSE 'Other'
	END AS sex_label,
		---Geography: municipality of residence + derived state code
	MUNIC_RES,
	SUBSTR(MUNIC_RES, 1,2) AS state_code,
		---Ethnicity: only applies when race = Indigenous
	CASE
		WHEN RACA_COR != 5 THEN NULL
		WHEN ETNIA = '0000' THEN NULL						--not informed
		WHEN ETNIA LIKE 'X%' THEN 'Unclassified (X-code)'	-- X-coded values retained as an unclassified category
		ELSE ETNIA											--valid codes
	END AS etnia_conditional
FROM SIH_SUS_2024_analysis_ready;

--2. Q1.1 Overall age composition
--age_group_pub → admission count → % of recorded admission records.--

SELECT age_group_pub,
		COUNT (*) AS admissions,
		ROUND (100.0 * COUNT(*)/(SELECT COUNT(*) FROM admissions_derived), 2) AS pct
FROM admissions_derived
GROUP BY age_group_pub
ORDER BY age_group_pub ;

--3. Q1.2 Overall sex composition

SELECT sex_label,
		COUNT (*) AS admissions,
		ROUND (100.0 * COUNT(*)/(SELECT COUNT(*) FROM admissions_derived), 2) AS pct
FROM admissions_derived
GROUP BY sex_label
ORDER BY sex_label;

--4. Q1.3 Overall race/color composition

SELECT 	RACA_COR,
		race_color_label,
    	COUNT(*) AS admissions,
    	ROUND(
        100.0 * COUNT(*) /
        (SELECT COUNT(*) FROM admissions_derived),
        2) AS pct
FROM admissions_derived
GROUP BY race_color_label
ORDER BY admissions DESC;

--5. Q1.4 Geography

SELECT state_code,
		COUNT (*) AS admissions,
		ROUND (100.0 * COUNT(*)/(SELECT COUNT(*) FROM admissions_derived), 2) as pct
FROM admissions_derived ad 
GROUP BY ad.state_code 
ORDER BY ad.state_code ;
--State codes were mapped to state names/abbreviations using
-- the validated UF reference crosswalk documented in data_enrichment/.

--6. Q1.5 Age × sex

SELECT age_group_pub,
		SUM(CASE WHEN sex_label = 'Male' THEN 1 ELSE 0 END) AS male_count,
		SUM(CASE WHEN sex_label = 'Female' THEN 1 ELSE 0 END) AS female_count,
		SUM(CASE WHEN sex_label ='Other' THEN 1 ELSE 0 END) AS other_count,
		ROUND (100.0 * SUM(CASE WHEN sex_label = 'Male' THEN 1 ELSE 0 END)/COUNT(*), 2) as male_pct,
		ROUND (100.0 * SUM(CASE WHEN sex_label = 'Female' THEN 1 ELSE 0 END)/COUNT (*), 2) as female_pct,
		ROUND (100.0 * SUM(CASE WHEN sex_label = 'Other' THEN 1 ELSE 0 END)/COUNT (*), 2) as other_pct
FROM admissions_derived ad 
GROUP BY ad.age_group_pub 
ORDER BY ad.age_group_pub ;

--7. Q1.6 Age × race/color

SELECT age_group_pub,
		race_color_label,
		COUNT (*) AS admissions,
		ROUND (100.0 * COUNT(*)/SUM(COUNT(*)) OVER (PARTITION BY age_group_pub),2) AS row_pct
FROM admissions_derived
GROUP BY age_group_pub, race_color_label
ORDER BY age_group_pub, race_color_label;
