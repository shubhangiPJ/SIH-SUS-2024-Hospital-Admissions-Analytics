	# SIH/SUS 2024 Hospital Admissions Analytics — Project Status Summary

**Last updated:** 2026-10-08 — Q4 closed; final dashboard completed; project ready for GitHub packaging

**Purpose:** Single reference point for where the project stands — what is completed, what was decided, what remains, and where the analytical work should continue.

---

## 1. Objective

To analyze patterns and variation in hospital admissions within Brazil's SUS system during 2024 — patient characteristics, diagnostic case mix, resource utilization, length of stay, and hospitalization costs, across demographic, facility/specialty, and geographic dimensions.

The project is **descriptive and variation-focused**, not causal or performance-focused. Findings should be described as patterns or associations; causal claims, population-level rates without denominators, unique-patient estimates, and unsupported efficiency/quality conclusions are outside scope.

### Unit of analysis

The primary unit of analysis is the hospital admission record represented in the SIH/SUS AIH RD data. Analyses describe patterns across hospitalization records rather than unique patients. `N_AIH` is an AIH/hospitalization authorization identifier and is not treated as a guaranteed unique-patient identifier. Full hospitalization-episode reconstruction (Portela et al. 1997) is treated as methodological context only, not implemented.

---

## 2. Analytical questions

| Question | Focus | Status |
|---|---|---|
| Q1 — Who is admitted? | Demographic and geographic composition | **Closed** |
| Q2 — What are patients admitted for? | Principal diagnosis/case mix and secondary diagnosis structure | **Closed** |
| Q3 — How are hospital resources utilized? | LOS, ICU/intermediate care, mortality, continuation/long-stay structure, specialty/bed category, geography | **Closed** |
| Q4 — What are the associated hospitalization costs? | Financial/resource expenditure patterns and cost variation | **Closed** |

Geography is a cross-cutting analytical lens, not a standalone question.

---

## 3. Phases completed

### Phase 1 — Environment & initial exploration
VS Code/Jupyter local setup, DBeaver + SQLite for SQL work. Encoding (`latin-1`), delimiter (`;`), and dtype issues resolved.

### Phase 2 — Full validation (Jan–Mar 2024)
All 113 variables profiled across 11 domains for three consecutive months. Baseline schema stability, recurring anomalies (CEP leading-zero loss, `RACA_COR=99`, `DIAS_PERM`/date mismatches, implausible birthdates), and stable-empty/constant fields established. Decision gate reached after 3 months of confirmed stability.

### Phase 3 — Streamlined validation (Apr–Dec 2024)
Structural checks + known-metric tracking + change detection replaced full domain profiling. All 12 months closed. Genuine new patterns caught and investigated: `DIAGSEC8/9` populating from April, `ETNIA` alphanumeric codes from September, `CGC_HOSP`/`CNPJ_MANT` missingness shift from July, a CEP threshold breach in November. Full record in `diff_log.md`.

### Phase 4 — Documentation & provenance
DATASUS Notas Técnicas, official SIH RD layout, PCDaS/ICICT ETL methodology (wiki + `bases_auxiliares.zip` lookup tables), WHO ICD-10 material, Souto et al. 2024, Coelho/Rocha/Hone 2024, and Portela et al. 1997 reviewed and cross-verified. Full record in `references.md`.

### Phase 5 — Business understanding & analytical scope
Four core questions defined with explicit boundaries: no causal claims, no population-level rates without denominators, no unique-patient counts, no unsupported efficiency/quality conclusions. See `SIH_SUS_Analytical_Framework.docx`.

### Phase 6 — Variable selection
Variables classified Core / Supporting / Exploratory / Exclude across all four questions. Key decisions:
- `UF_ZI` excluded — confirmed administrative/payment-linkage field, not geography (verified against 3 independent official sources).
- `MUNIC_MOV` reassigned from Q1 to Q3.
- `CID_ASSO`, `CID_MORTE` dropped — confirmed constant at 0 all 12 months, likely deprecated per Portaria 1.324/2014.
- `DIAG_SECUN` excluded — confirmed constant at 0 all 12 months (explicit dated decision, 2026-09-01; not merely dropped by extraction-rework coincidence).
- `US_TOT` dropped — confirmed deterministic, redundant function of `VAL_TOT` (identical ratio for every record within a given month).
- `INFEHOSP`, `HOMONIMO`, `NATUREZA`, `VAL_SADT` excluded — confirmed 100%-missing or constant.
- `NACIONAL` downgraded to Exploratory-only — confirmed 99.0% one value, every month, all 12 months.
- `FAEC_TP` retained as Supporting (~94% missing, conditional on `FINANC`=FAEC).
- `N_AIH`, `ANO_CMPT`, `MES_CMPT` added to the manifest for traceability and month-tracking (were initially missing).

### Phase 7 — Derived metrics locked
- Age groups: official PCDaS `idade_pub` scheme (9 groups) — chosen over `idade_18` (too granular for readable cross-tabs) and `idade_bas` (too coarse).
- Age derivation: `COD_IDADE` in (2,3) → 0 years; `COD_IDADE`=4 → `IDADE` as-is; `COD_IDADE` in (0,5) → excluded from valid age groups, reported as `Unknown/Unreliable` (0 = 8 records, Q4 2024 only; 5 = undefined in every source checked, 100% correlated with implausible-age records all year).
- `MUNIC_RES` → state code via `SUBSTR(MUNIC_RES,1,2)` — confirmed safe (uniformly 6 digits, no leading-zero corruption, full 13,786,854-row check).
- ICD-10: `DIAG_PRINC` → 3-character category → chapter via ICICT `cid10_tabela_capitulos.csv` (NOT `LEFT(DIAG_PRINC,1)` — `D` spans Chapters II/III, `H` spans VII/VIII).
- Secondary diagnosis count: `DIAGSEC1-7` only, `DIAGSEC8/9` explicitly excluded (population only began April 2024 — including them would silently change the metric's meaning mid-year). Termed "secondary diagnosis count," not "comorbidity index."
- ICU: `MARCA_UTI = 0` → No ICU; `MARCA_UTI <> 0` → ICU involvement. `MARCA_UCI` (intermediate care) kept separate, never combined with ICU.
- LOS categories: `0 days`, `1-3 days`, `4-7 days`, `8-30 days`, `31+ days` (official PCDaS-derived scheme, inspected against the real distribution before applying).
- `MORTE`: `0` = No death, `1` = Death occurred.
- `RACA_COR` mapping retained as `3=Parda, 4=Amarela` despite SIM subsystem's dictionary showing the reverse order — documented as a two-document discrepancy, not a general SIM-vs-SIH claim; SIH's own empirical output + the IBGE-aligned national standard both agree against SIM.
- `ESPEC` → `LEITOS` mapping confirmed via explicit SIH ETL wiki citation (left join on `LEITOS.cod`, extracting `def_leitos`) — not just value-correlation inference. English label layer (`def_leitos_en`) referenced in project notes.
- `IDENT` stays outside the frozen table; used via a separately validated composite-key lookup (see Phase 13).

### Phase 8 — Decode/reference enrichment
Built `variable_reference.csv` (all 113 variables), `Q1`–`Q4_variable_reference.csv` (per-question decisions with full decode/grouping guidance), and `lookup_tables/` (official complete code tables: `ETNIA`, `NACION3D`, `CBO`, `CNAE`, `LEITOS`, `TB_SIGTAB`, `icd10_chapter_lookup_en` — the latter cross-checked byte-for-byte against the official WHO reference file, 0 mismatches across all 22 chapters).

### Phase 9 — Extraction manifest & post-combination checklist
Final manifest: **54 variables**. Every open question (`NACIONAL` distribution, `US_TOT`/`VAL_TOT` relationship, `PROC_SOLIC`/`PROC_REA` redundancy — confirmed genuinely different, ~6-8% mismatch/month — `GESTAO`/`FINANC` value sets, `TPDISEC1-9` scheme consistency, `ANO_CMPT`/`MES_CMPT` integrity) resolved with real 12-month data before extraction. Checklist fully closed.

### Phase 10 — Extraction executed
Bug caught and fixed: missing `sep=';'`/`encoding='latin-1'` initially caused a `usecols` mismatch on every column. Re-ran clean. `FAEC_TP` and `ETNIA` dtype fixed to `string`/`VARCHAR` to preserve leading zeros and alphanumeric codes — confirmed working end-to-end on the frozen table (`X400`-style `ETNIA` codes and `040024`-style `FAEC_TP` codes both verified intact via direct SQL query). DBeaver's per-file auto-type-detection (a separate risk from the Python-side dtype map) was caught and corrected by building one authoritative `CREATE TABLE` DDL rather than letting each monthly import auto-generate its own schema.

### Phase 11 — Combined dataset frozen
All 12 monthly extracts imported into `SIH_SUS_2024_analysis_ready`. **13,786,854 records confirmed** — matches the exact sum of all 12 known monthly counts from `diff_log.md`. The frozen table is authoritative and is not modified during analysis; derived/analytical views are built on top of it.

`N_AIH` cross-month duplication investigated: 52,596 distinct `N_AIH` values (~0.38% of all records) appear in more than one month — consistent with the documented AIH re-presentation/reprocessing mechanism (DATASUS Notas Técnicas; Portela et al. 1997). Project retains AIH-record-level analysis; does not attempt episode reconstruction.

### Phase 12 — Q1 completed
Age, sex, race/color, and state (from `MUNIC_RES`) derived and cross-tabulated. All four dimensions independently confirmed to sum to exactly 13,786,854 — no rows lost in any derivation.

Key findings: 65+ = 23.40% of records; Female = 56.46%, Male = 43.54%; Parda = 56.92%, White = 36.22%; state shares vary substantially (largest state = 20.46%). `RACA_COR=99` cross-tab total independently verified to sum to the correct 2,466 (3 age groups genuinely have zero records, not a query gap).

Two export-stage bugs caught and must be checked for on any future export: Excel auto-date-conversion silently corrupted `idade_pub` labels `"1-4"`/`"5-14"` into `"01-Apr"`/`"May-14"` (underlying counts were correct, only display labels affected); recurrence of a UTF-8/Latin-1 mojibake bug (`"IndÃ­gena"`) originally fixed in `data_dictionary.md`.

### Phase 13 — IDENT / continuation structure
`IDENT` deliberately stays outside the frozen 54-variable table. Only `IDENT=1` (Principal) and `IDENT=5` (Long-stay) observed in 2024; `IDENT=3` (Continuação, per Kaggle dataset documentation) never appears.

`IDENT_lookup_final` built via composite key (`N_AIH + ANO_CMPT + MES_CMPT`) after extensive validation caught and resolved a real fan-out risk:
- Initial raw extraction had a bug duplicating January's file (1,107,877 extra rows) — found via exact arithmetic match, fixed, re-verified against `diff_log.md`'s known monthly counts.
- Even after that fix, 2,124 pure exact-duplicate rows and 4,409 composite keys with genuinely 2 different `IDENT` values (8,818 total rows) remained.
- Deeper investigation found some `IDENT=5` combinations had 2-3 physical rows (genuine multi-segment continuation records, e.g. one `N_AIH` spanning Feb-May 2024 across 3 continuation segments), not simple duplicates.
- Final aggregation: one row per composite key with `has_ident_1`, `has_ident_5`, `continuation_count`, `continuation_days` (`SUM(QT_DIARIAS)` for `IDENT=5` rows), `continuation_cost` (`SUM(VAL_TOT)` for `IDENT=5` rows), `admission_start`, `discharge_end`. Explicitly labeled as aggregated `IDENT=5` records, not reconstructed total episode days/cost.
- Full reconciliation confirmed: 13,786,854 (raw) − 2,124 (exact duplicates) − 4,409 (keys merging from 2 distinct combos to 1) = 13,780,321 (final distinct keys) — arithmetic verified exactly.
- **Watch item carried into Q4 use**: `SUM()` over zero `IDENT=5` rows returns `NULL`, not `0`, for the ~13.77M non-continuation records — must use `COALESCE(SUM(...), 0)` or any downstream `total_cost = VAL_TOT + continuation_cost` calculation will silently null out 99.97% of results.

### Phase 14 — Q2 completed
`DIAG_PRINC` mapped to ICD-10 chapter via the verified ICICT lookup. Coverage validation: 1,666 distinct categories in real data, **0 unmapped** against the 2,560-category lookup. Chapter distribution sums exactly to 13,786,854. Chapter 20 ("External causes") correctly shows 0 admissions as principal diagnosis — confirmed via direct query, consistent with standard clinical coding convention (external-cause codes are supplementary, not standalone principal diagnoses).

Top 6 chapters by volume: Pregnancy (14.85%), Injury (11.20%), Digestive (10.58%), Respiratory (9.50%), Circulatory (9.47%), Neoplasms (7.93%) — together ~63.5% of all admissions.

`secondary_diag_count` built (`DIAGSEC1-7` only). Injury chapter's outlier average (1.05 vs. ~0.1-0.23 elsewhere) investigated, not just flagged: driven by `DIAGSEC1` being systematically populated with Chapter-20 external-cause codes (`W19`, `W99`, `Y34`, `V29`, etc.) for ~100% of Injury admissions, not elevated comorbidity (96.66% of Injury admissions have exactly 1 secondary diagnosis). This directly cross-validates the Chapter 20 = 0 finding — the same codes that never appear as principal diagnosis are the ones systematically filling `DIAGSEC1` for injury admissions.

Top 10 categories identified and clinically verified for the 6 largest chapters (e.g. `I50`/`I64`/`I21` — heart failure/stroke/MI — topping Circulatory; `O80`/`O82` — vaginal/C-section delivery — correctly dominating Pregnancy).

### Phase 15 — Q3 completed

**LOS**: Mean ≈ 5.0 days, median = 2 days. Distribution: 10.38% (0 days), 51.97% (1-3 days), 19.55% (4-7 days), 16.48% (8-30 days), 1.62% (31+ days) — strongly right-skewed. `DIAS_PERM` remains the primary LOS measure; percentile results (P50=2, P75=6) verified consistent with the raw frequency table.

**ICU**: 1,248,209 admissions (9.05%) involved ICU. Involvement rises monotonically with LOS: 1.03% (0 days) → 3.25% (1-3) → 12.73% (4-7) → 25.68% (8-30) → 33.39% (31+). Mean ICU days among ICU-involved records = 6.83.

**Intermediate care (UCI)**: 106,828 records (0.78%) involved `MARCA_UCI`; mean UCI days among involved records = 7.64. Kept fully separate from ICU throughout.

**ICU × demographics/geography**: Age shows a U-shape, not monotonic — `<1` = 22.65% (likely NICU-driven), dips through childhood/young adulthood (~3-6%), rises to 14.98% at 65+. Sex: Male 11.36% vs. Female 7.28% — gap is not uniform across ages; narrow in infancy, wide in reproductive ages (25-34: M=6.2% vs. F=2.07%), plausibly diluted by Pregnancy admissions (Q2's largest chapter) in the female reproductive-age group — compositional note, not a causal claim. State-level ICU involvement ranges ~2.72%-11.69%.

**ICU × ICD-10**: Both within-chapter ICU% and share-of-all-ICU-admissions retained as distinct views — they answer different analytical questions. Circulatory disease contributes the largest share of ICU-involved records (24.93%), consistent with its total-admission volume (1,305,100 × 23.84% ICU rate ≈ matches independently).

**Continuation/long-stay**: Concentrated among longer stays — 22.57% of 31+ day records show continuation vs. 0.02% of 0-day records. Continuation × ICU relationship (0.10% vs. 9.14% for single-admission records) treated as an administrative/record-structure finding, not a clinical conclusion.

**MORTE × LOS × ICU** (using `MARCA_UTI <> 0` as the ICU definition — admission counts per LOS×ICU cell independently verified to reproduce the exact ICU% figures above):

| LOS | ICU status | Admissions | Deaths | Mortality |
|---|---|---:|---:|---:|
| 0 days | ICU | 14,704 | 8,403 | 57.15% |
| 0 days | No ICU | 1,416,243 | 36,216 | 2.56% |
| 1–3 days | ICU | 232,525 | 59,796 | 25.72% |
| 1–3 days | No ICU | 6,932,921 | 123,894 | 1.79% |
| 4–7 days | ICU | 343,061 | 55,349 | 16.13% |
| 4–7 days | No ICU | 2,352,289 | 84,728 | 3.60% |
| 8–30 days | ICU | 583,282 | 111,159 | 19.06% |
| 8–30 days | No ICU | 1,688,328 | 106,638 | 6.32% |
| 31+ days | ICU | 74,637 | 15,160 | 20.31% |
| 31+ days | No ICU | 148,864 | 9,443 | 6.34% |

Descriptive associations only — not causal or performance conclusions.

**ESPEC + LEITOS**: Official mapping confirmed directly from the SIH ETL wiki (`ESPEC` → left join on `LEITOS.cod` → `def_leitos`), not inferred from value-correlation alone. Full chain now documented as `ESPEC → LEITOS code → Portuguese description → English label (def_leitos_en)`. Original `ESPEC` code retained unchanged throughout.

**CNES decision**: Retained in the frozen dataset as the establishment identifier. **Facility-level analysis excluded from current scope** — a deliberate scope decision, not a data-quality exclusion. Meaningful facility interpretation would require integrating separate CNES establishment-level reference data (facility name, type, capacity) to decode raw facility IDs into something interpretable; that's a distinct data-integration effort beyond current scope. `CNES` remains available for a future phase if added.

### Phase 16 — Q3 closed
Consolidated analytical view: `q3_resource_utilization` (combines the frozen base + derived Q3 measures + the validated `IDENT_lookup_final` join). Frozen base unchanged throughout.

### Phase 17 — Q4 completed

**Financial-variable specification finalized:** `VAL_TOT` (total AIH value), `VAL_SH` (hospital services), `VAL_SP` (professional services), `VAL_UTI` (ICU-related financial component), `VAL_UCI` (UCI/intermediate-care financial component), with `FINANC`/`FAEC_TP` retained as supporting fields where interpretable. `VAL_SADT` and `US_TOT` remained excluded.

**Financial interpretation:** `VAL_TOT` is interpreted within the SIH/SUS reimbursement/recorded-value context, not as complete economic cost. `VAL_SH` and `VAL_SP` were used as recorded components of `VAL_TOT`; no profitability, efficiency, cost-effectiveness, or value-for-money claims are made.

**Completed Q4 analyses:**
- **ICD-10 chapter × cost:** total recorded cost, mean recorded cost, median cost, and chapter contribution to total recorded cost. The top three cost-contributing chapters were Circulatory (~21.66%), Neoplasms (~11.70%), and Injury (~9.72%), together ~43.08% of total recorded cost.
- **LOS × cost:** mean recorded cost increased across the locked LOS categories. Mean cost was 1,025 for 1–3 day stays and 8,524 for 31+ day stays; 31+ day stays represented 1.62% of admissions.
- **Secondary diagnosis count × cost:** mean recorded cost increased from 1,632 for records with 0 recorded secondary diagnoses to 6,778 for records with 7. The distribution is highly concentrated at 0 (77.39% of admissions), so the metric is presented as a descriptive coding/cost association, not as a comorbidity measure.
- **ICU × cost:** ICU-involved records (9.05% of admissions) had mean recorded cost of 8,281 versus 1,038 for records without ICU involvement. Cost-per-day was also higher among ICU-involved records (1,102 vs. 440), using `DIAS_PERM > 0` for cost-per-day derivation.
- **ICU/UCI financial components:** `VAL_UTI` was positive for 1,248,209 ICU-involved records, with mean 4,521 and median 2,430; `VAL_UCI` was positive for 106,828 UCI-involved records, with mean 1,429 and median 900. Their reported cost shares use different denominators and are not combined.
- **Continuation/single-admission cost:** continuation records accounted for 0.99% of admissions versus 99.01% for single-admission records. Mean recorded cost was 1,753 vs. 1,694 and mean LOS was 24.18 vs. 4.29 days, respectively. This remains an administrative/record-structure comparison, not episode reconstruction.
- **Specialty × cost/utilization:** specialty-level admissions, mean recorded cost, mean cost/day, and mean LOS were examined. The final dashboard uses a descriptive quadrant/bubble view with admissions on the x-axis, mean recorded cost on the y-axis, bubble size representing mean cost/day, and median-based reference lines. Quadrants are labeled High/Low Volume × High/Low Cost; no efficiency or performance interpretation is attached.
- **`ESPEC`/bed-specialty mapping:** final specialty labels use the verified `LEITOS` reference mapping while preserving the original `ESPEC` code.

**Final Q4 dashboard outputs:** total cost by ICD-10 chapter; mean cost by ICD-10 chapter; specialty-level cost/utilization bubble plot; secondary diagnosis count × mean cost; LOS × mean cost; ICU/UCI financial-component table; ICU vs. No ICU cost comparison; continuation vs. single-admission cost table; and supporting KPI cards comparing the most analytically useful contrasts (including 1–3 vs. 31+ day LOS and 0 vs. 7 secondary diagnoses).

**Dashboard assembly decision:** the earlier `VAL_SH` vs. `VAL_SP` chapter chart was replaced by the specialty-level cost/utilization bubble plot because the latter integrates volume, mean recorded cost, and cost intensity in one descriptive view. The SH/SP component analysis remains part of the underlying analytical evidence/documentation.

**Cost-per-day rule:** derived only for `DIAS_PERM > 0`; zero-day stays remain in the core dataset and overall cost analysis.

**`QT_DIARIAS` rule:** `DIAS_PERM` remains the primary LOS measure. `QT_DIARIAS` remains exploratory and does not replace `DIAS_PERM`; no dashboard conclusion depends on substituting one for the other.

**Q4 closed without expanding scope:** no facility-level `CNES` analysis, no causal cost-driver claims, no efficiency/performance ranking, and no economic evaluation were added.

---

## 4. Current analytical objects

### Frozen base
`SIH_SUS_2024_analysis_ready` — 13,786,854 records, 54 selected variables, authoritative analytical base. **Do not modify.**

### Reference/lookup objects
- `icd10_chapter_lookup_en` — ICD-10 category-to-chapter enrichment
- `LEITOS_enriched` — ESPEC/bed-category enrichment with Portuguese + English labels
- `IDENT_lookup_final` — continuation/long-stay enrichment using the validated composite key
- Supporting lookup/reference files used for decoding and mapping

### Analytical layers
- Q1 demographic derivations
- Q2 diagnosis/chapter analytical layer
- `q3_resource_utilization` — consolidated Q3 analytical view
- Q4 cost analytical queries/views built on the frozen base and established Q2/Q3 layers

These are **local analytical objects**, not GitHub deliverables. The repository will contain the reproducible SQL scripts that create/derive them, not the populated SQLite database, the 13.8M-row tables/views, or raw SIH/SUS data.

---

## 5. Key locked decisions (so they aren't re-litigated later)

- Primary unit = SIH/SUS hospital admission/AIH record. No unique-patient analysis. No full episode reconstruction.
- Frozen base is never modified during analysis; derived variables live in views/layers on top of it.
- `MARCA_UTI = 0` → No ICU; `MARCA_UTI <> 0` → ICU involvement. `MARCA_UCI` stays separate from ICU, never combined.
- `MORTE`: `0` = No death, `1` = Death occurred.
- `DIAS_PERM` is the primary LOS measure; LOS categories are locked (`0`/`1-3`/`4-7`/`8-30`/`31+` days). `QT_DIARIAS` is exploratory only, never a replacement.
- ICD-10 chapter mapping uses the verified ICICT lookup — never `LEFT(DIAG_PRINC,1)`.
- `DIAG_SECUN`, `CID_ASSO`, `CID_MORTE`, `US_TOT`, `VAL_SADT`, `INFEHOSP`, `HOMONIMO`, `NATUREZA`, `UF_ZI` are all excluded, each for an independently confirmed reason.
- `IDENT` stays outside the frozen table, joined only via the composite key (`N_AIH`+`ANO_CMPT`+`MES_CMPT`) — never `N_AIH` alone.
- `ESPEC` remains the original SIH field; `LEITOS` supplies the description, confirmed via explicit SIH ETL documentation.
- `CNES` remains in the dataset; facility-level enrichment/analysis is excluded from current scope.
- Descriptive differences are never interpreted as causal or as facility/clinical performance measures.
- Cost-per-day is calculated only where `DIAS_PERM > 0`.
- Q4 financial values are interpreted as SIH/SUS recorded/reimbursement values, not automatically as complete economic costs.
- Total cost and individual financial components remain analytically distinct; ICU and UCI cost-share percentages are never combined because their denominators differ.
- Dashboard quadrant labels use relative median-based High/Low Volume and High/Low Cost groupings only; they are not efficiency or performance classifications.
- Two recurring export-stage bugs must be checked before final public export: Excel auto-date conversion on range-like text labels and UTF-8/Latin-1 mojibake on Portuguese labels.
- The final dashboard is organized as four question-based dashboards (Q1–Q4). Dashboard refinement is presentation work and should not reopen frozen analytical decisions unless a genuine analytical error is identified.

---

### Q4 cautions retained

- Interpret `VAL_TOT` within the SIH/SUS reimbursement/recorded-value context — not automatically "complete economic cost."
- No cost-effectiveness, profitability, or efficiency/value-for-money claims without additional data/methodology.
- No "high cost = poor performance" framing.
- Distinguish within-group rates from contribution to the overall population.
- Keep total cost and individual financial components analytically distinct.

---

## 6. Deliverable inventory

| File/object | Purpose | Status |
|---|---|---|
| `data_dictionary.md` | Master dictionary covering the 113 source variables | Reference |
| `diff_log.md` | Record of validation checks and differences identified during Jan–Dec data validation | Final |
| `references.md` | Documentation of external sources used in the project | Final |
| `Q1`–`Q4_variable_reference.csv` | Question-specific variable selection and analytical decisions | Reference |
| Lookup and enrichment files | Reference tables supporting ICD-10 chapter mapping, continuation-record handling, and ESPEC/bed-category enrichment | Maintained |
| Analytical plan and scope document | Business objective, analytical questions, scope, and planned deliverables | Core reference |
| `SIH_SUS_2024_analysis_ready` | Frozen 54-variable analytical base derived from the source data | **Frozen / local only** |
| `icd10_chapter_lookup_en` | ICD-10 chapter enrichment used for diagnostic case-mix analysis | Active / local |
| `IDENT_lookup_final` | Continuation-record enrichment | Active / local |
| `LEITOS_enriched` | ESPEC and bed-category enrichment | Active / local |
| `q3_resource_utilization` | Consolidated analytical view for resource-utilization analysis | Active / local |
| Q1 results | Demographic and geographic analysis | Complete |
| Q2 results | ICD-10 and diagnostic case-mix analysis | Complete |
| Q3 results | Resource-utilization analysis | Complete |
| Q4 cost analysis | Financial and expenditure analysis | Complete |
| Tableau dashboard views | Visualization of findings across Q1–Q4 | Complete |
| Tableau Public dashboard | Interactive presentation of the project findings | Published |
| GitHub repository package | Public project documentation, analytical code, selected reference files, and dashboard screenshots; excludes raw data and the local database | Published |


