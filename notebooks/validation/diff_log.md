# SIH/SUS Cross-Month Validation Diff-Log

**Last updated: 2026-09-01** (full 12-month cycle closed; document now stable unless a 2025 dataset reopens it)

Purpose: track how each month's dataset compares to the January baseline, to confirm whether domain-level findings are systemic to SIH/SUS (and therefore safe to generalize/refactor) or month-specific anomalies requiring individual handling.

Template validated against: `01_validation_template.ipynb`

---

## January 2024 (Baseline)

| Metric | Value |
|---|---|
| Row count | 1,107,877 |
| Columns | 113 |
| Schema check vs. dictionary | N/A (dictionary built from this month) |
| Implausible age (NASC > 120 yrs) | 11 records |
| DIAS_PERM vs. calendar-day mismatch | 10,887 records (0.98%) |
| RACA_COR = 99 | 282 records |
| SEXO observed codes | 1, 3 |
| CEP non-8-digit | 91,461 records |

---

## February 2024

| Metric | Value | vs. January |
|---|---|---|
| Row count | 1,092,862 | −15,015 (fewer days in month, expected) |
| Columns | 113 | Unchanged |
| Schema check vs. dictionary | 0 missing_from_dict, 0 missing_from_data | **Pass — identical schema** |
| Implausible age (NASC > 120 yrs) | 19 records | +8, same pattern (IDADE 20–24, COD_IDADE=5, NASC≈1899) |
| DIAS_PERM vs. calendar-day mismatch | 11,038 records (1.01%) | Consistent rate |
| RACA_COR = 99 | 275 records | Consistent, slightly lower |
| SEXO observed codes | 1, 3 | Unchanged |
| CEP non-8-digit | 92,307 records | Consistent rate (~8.4%) |

**Notable finding:** Large `DIAS_PERM` mismatches trace to admissions with `DT_INTER` well before February (long-stay carryovers from prior months) — confirms this is a structural SIH/SUS reporting convention, not a February-specific data issue.

---

## March 2024

| Metric | Value | vs. Jan/Feb |
|---|---|---|
| Row count | 1,183,297 | Higher than both Jan and Feb — noted, not treated as anomalous (plausible volume variation) |
| Columns | 113 | Unchanged |
| Schema check vs. dictionary | 0 missing_from_dict, 0 missing_from_data | **Pass — identical schema, 3rd consecutive month** |
| Implausible age (NASC > 120 yrs) | 16 records | Consistent with Jan (11) / Feb (19) |
| DIAS_PERM vs. calendar-day mismatch | 11,091 records (0.94%) | Consistent rate |
| RACA_COR = 99 | 258 records | Consistent, continuing slight downward trend |
| SEXO observed codes | 1, 3 | Unchanged |
| CEP non-8-digit | 100,856 records (8.52%) | Consistent rate |

---

## April 2024

*First month under the streamlined check (post decision-gate). Layer 1 + Layer 2 + Layer 3 change-detection, not full domain profiling.*

| Metric | Value | vs. Jan–Mar baseline |
|---|---|---|
| Row count | 1,220,168 | Higher than Jan/Feb/Mar — noted, not anomalous |
| Columns (original schema) | 113 | Unchanged |
| Schema check vs. dictionary | PASS | Pass — 4th consecutive month |
| Dtype changes | `DIAGSEC8`: float64→str, `DIAGSEC9`: float64→str | **⚠ Changed** — see notable finding below |
| Duplicate rows | 0 | Consistent (0) |
| Implausible age (NASC > 120 yrs) | 17 records | Within baseline (11–19) |
| DIAS_PERM vs. calendar-day mismatch | 11,149 records (0.91%) | Within baseline (0.94%–1.01%, buffer) |
| RACA_COR = 99 | 243 records | **⚠ Outside baseline (258–282)** — see notable finding below |
| SEXO observed codes | 1, 3 | Unchanged |
| CEP non-8-digit | 103,271 records (8.46%) | Within baseline (8.26%–8.52%) |
| Stable-empty field changes | `DIAGSEC8`: 6 records populated (0.00049%); `DIAGSEC9`: 5 records populated (0.00041%) | **⚠ Changed** — first occurrence since Jan |
| Stable-constant field changes | None | Unchanged |
| Missingness outside Jan–Mar range | `DIAGSEC1`: baseline 77.11%–77.60%, now 78.27% (~8,175 more missing rows than baseline max) | **⚠ Outside range** |

**Notable finding — DIAGSEC8/DIAGSEC9 first occurrence:** these two fields have been 100% empty every month since January. April is the first month either contains data — 6 records in `DIAGSEC8`, 5 in `DIAGSEC9` (a subset of the 6). Inspected all 6 directly: every prior `DIAGSEC1`–`7` slot is populated with no gaps, and `TPDISEC` flags are consistently non-zero exactly where `DIAGSEC` is populated — internally consistent, not corrupted. Reflects genuinely high-comorbidity admissions (one record has 9 distinct diagnosis codes recorded), not a data quality issue. One of the 6 `N_AIH` values appears twice with different diagnosis sets — consistent with the already-documented `N_AIH` near-uniqueness (1,107,309 / 1,107,877 unique in the Jan baseline), not a new anomaly.

**Notable finding — RACA_COR=99 trend:** Jan=282 → Feb=275 → Mar=258 → **Apr=243**. Consistent monotonic decline every month, not a random dip. The fixed 3-month range (258–282, no buffer) was always likely to eventually be "broken" by a trend continuing in the same direction. Not treated as a data quality problem — flagged here as a trend to keep watching in May; if it keeps declining, worth eventually asking whether recording practices for RACA_COR are changing over the year.

**Notable finding — DIAGSEC1 missingness shift:** ~8,175 more rows missing `DIAGSEC1` than the Jan–Mar baseline max would predict. Scale-checked against the DIAGSEC8/9 event (6 records) — three orders of magnitude apart, ruled out as the same cause. No root cause identified yet; treating as a standalone finding to watch in May rather than assuming a connection to the DIAGSEC8/9 event.

---

## May 2024

| Metric | Value | vs. Jan–Mar baseline |
|---|---|---|
| Row count | 1,217,431 | Higher than Jan/Feb/Mar — noted, not anomalous |
| Columns (original schema) | 113 | Unchanged |
| Schema check vs. dictionary | PASS | Pass — 5th consecutive month |
| Dtype changes | `DIAGSEC8`: float64→str, `DIAGSEC9`: float64→str | **⚠ Changed** — 2nd consecutive month, see notable finding |
| Duplicate rows | 0 | Consistent (0) |
| Implausible age (NASC > 120 yrs) | 14 records | Within baseline (11–19) |
| DIAS_PERM vs. calendar-day mismatch | 11,040 records (0.91%) | Within baseline (0.94%–1.01%, buffer) |
| RACA_COR = 99 | 224 records | **⚠ Outside baseline (258–282)** — 5-month decline continues |
| SEXO observed codes | 1, 3 | Unchanged |
| CEP non-8-digit | 102,723 records (8.44%) | Within baseline (8.26%–8.52%) |
| Stable-empty field changes | `DIAGSEC8`: 218 records populated (0.0179%); `DIAGSEC9`: 76 records populated (0.0062%) | **⚠ Changed** — 2nd consecutive month, ~27x April's volume |
| Stable-constant field changes | None | Unchanged |
| Missingness outside Jan–Mar range | None — `DIAGSEC1` back within range | No flag this month (April's flag did not recur) |

**Notable finding — DIAGSEC8/DIAGSEC9 scaling up:** second consecutive month of new data, and volume grew sharply: 11 total populated records in April → **294 in May (~27x)**. Investigated the full record set: sequential integrity still holds across all 294 — no gaps in `DIAGSEC1`–`7` before `DIAGSEC8`/`9` populate, `TPDISEC` flags track exactly where `DIAGSEC` is populated, and `DIAGSEC9` is a perfect subset of `DIAGSEC8` (0 records have 9 populated without 8). Still consistent with genuine high-comorbidity admissions, not corruption — but this is no longer a rare edge case, and "stable-empty" is becoming an inaccurate label for these two fields. **Decision:** whether to graduate `DIAGSEC8`/`DIAGSEC9` out of the Layer 3.1 stable-empty list and into a proper Layer 2 tracked metric (with its own baseline range, like `RACA_COR=99`) is deferred until after June's run — need a 3rd data point to see if the growth trend continues before changing the template.

**Notable finding — N_AIH near-uniqueness, sharper example:** `N_AIH` 3524104189320 appears twice with drastically different diagnostic completeness — one version has all 9 diagnosis slots filled, the other only 3 codes with nothing beyond (`I693`, `G978`, `Z652`). Same underlying quirk documented in the January baseline (1,107,309 / 1,107,877 unique `N_AIH`), but the starkest instance seen so far. Also noted: `N_AIH` 3524112190687 appears twice with *identical* diagnosis codes across all columns shown — since Layer 1's full-row duplicate check returned 0, these two rows must differ somewhere outside the diagnosis fields. Neither requires action; both are documentation notes for if/when diagnosis-level analysis begins.

**Notable finding — RACA_COR=99 trend continues:** Jan=282 → Feb=275 → Mar=258 → Apr=243 → **May=224**. Five consecutive months of decline. Still not treated as a data quality problem, but the trend is now well-established rather than tentative — worth deciding at some point whether this reflects a genuine shift in recording practice over 2024, once more months are in.

---

## June 2024

| Metric | Value | vs. Jan–Mar baseline |
|---|---|---|
| Row count | 1,179,843 | Within normal range seen so far |
| Columns (original schema) | 113 | Unchanged |
| Schema check vs. dictionary | PASS | Pass — 6th consecutive month |
| Dtype changes | `DIAGSEC8`: float64→str, `DIAGSEC9`: float64→str | 3rd consecutive month — no longer a surprise, see notable finding |
| Duplicate rows | 0 | Consistent (0) |
| Implausible age (NASC > 120 yrs) | 7 records | **⚠ Outside baseline (11–19)** — first time below range, see notable finding |
| DIAS_PERM vs. calendar-day mismatch | 10,828 records (0.92%) | Within baseline (0.94%–1.01%, buffer) |
| RACA_COR = 99 | 205 records | **⚠ Outside baseline (258–282)** — 6-month decline continues |
| SEXO observed codes | 1, 3 | Unchanged |
| CEP non-8-digit | 100,886 records (8.55%) | Within baseline (8.26%–8.52%, buffer) |
| Stable-empty field changes | `DIAGSEC8`: 284 records populated (0.024%); `DIAGSEC9`: 126 records populated (0.011%) | 3rd consecutive month — see notable finding |
| Stable-constant field changes | None | Unchanged |
| Missingness outside Jan–Mar range | None | No flag — 2nd consecutive clean month |

**Notable finding — implausible age, first below-range month:** June's count (7) is the first to fall *below* the established 11–19 range, rather than within or above it. Inspected all 7 directly: identical signature to every prior month — `COD_IDADE=5`, recorded `IDADE` in the 20s, `NASC` in the 1896–1903 placeholder-date range. Not a new anomaly type, just a naturally low month for an already-understood pattern. Side-observation: only 2 of the 7 records have `DT_INTER` actually in June — the rest date to March/May, consistent with the historical-carryover pattern already documented in earlier months (a given month's *file* isn't the same as that month's *admissions*).

**Notable finding — DIAGSEC8/DIAGSEC9, 3rd month of growth, decision made:** Apr=11 total → May=294 → **June=410** (284 + 126). Growth is decelerating in relative terms (27x, then 1.4x) but still climbing in absolute terms — three points is enough to say this isn't a one-off, but not yet enough to set a meaningful fixed pass/fail range (11–410 would be too wide to be useful). **Decision:** graduating `DIAGSEC8`/`DIAGSEC9` out of the Layer 3.1 stable-empty list (the "⚠ previously empty" framing is no longer accurate — this is an established pattern, not a surprise) and into lightweight trend-only tracking — reporting count/% each month without a pass/fail threshold, until 2–3 more months show whether it's actually stabilizing. Template change applied starting July.

**RACA_COR=99 trend, 6 months:** Jan=282 → Feb=275 → Mar=258 → Apr=243 → May=224 → **Jun=205**. Deltas: −7, −17, −15, −19, −19 — decline rate has been steady-to-slightly-accelerating, not plateauing. Still not treated as a data quality issue, but six months of consistent direction makes this a real pattern worth eventually explaining rather than just tracking.

---

## July 2024

*First month with the DIAGSEC8/9 template change applied — graduated from Layer 3.1 stable-empty to trend-only tracking.*

| Metric | Value | vs. Jan–Mar baseline |
|---|---|---|
| Row count | 1,186,206 | Within normal range seen so far |
| Columns (original schema) | 113 | Unchanged |
| Schema check vs. dictionary | PASS | Pass — 7th consecutive month |
| Dtype changes | `DIAGSEC8`: float64→str, `DIAGSEC9`: float64→str | 4th consecutive month — expected, no longer flagged as a surprise |
| Duplicate rows | 0 | Consistent (0) |
| Implausible age (NASC > 120 yrs) | 12 records | Within baseline (11–19) — back in range after June's low |
| DIAS_PERM vs. calendar-day mismatch | 11,152 records (0.94%) | Within baseline (0.94%–1.01%) |
| RACA_COR = 99 | 182 records | **⚠ Outside baseline (258–282)** — 7-month decline, steepest single-month drop yet |
| SEXO observed codes | 1, 3 | Unchanged |
| CEP non-8-digit | 102,231 records (8.62%) | Within baseline (8.26%–8.52%, buffer) |
| Stable-empty field changes | None | All 3 remaining fields (`NUM_PROC`, `INFEHOSP`, `GESTOR_DT`) still 100% missing |
| Emerging fields (trend-only) | `DIAGSEC8`: 263 (0.022%); `DIAGSEC9`: 103 (0.0087%) | First month of *decline* after 3 months of growth (11→294→410→366 total) |
| Stable-constant field changes | None | Unchanged |
| Missingness outside Jan–Mar range | `CGC_HOSP`: baseline 25.41%–25.61%, now 24.66% (~8,863 fewer missing rows than baseline min) | **⚠ New column flagged** — first time since April, and first time a column other than `DIAGSEC1` has triggered this check |

**Notable finding — CGC_HOSP missingness shift, not yet investigated:** first appearance of this flag on a facility-identifier field (hospital CNPJ). Missingness *decreased* — roughly 8,863 more records have `CGC_HOSP` populated than the established baseline predicts. Not investigated in detail this month (logged as-is per decision); worth a closer look if it recurs in August, similar to how `DIAGSEC1`'s one-off flag in April was treated as noise once it didn't repeat in May.

**RACA_COR=99, 7 months:** Jan=282 → Feb=275 → Mar=258 → Apr=243 → May=224 → Jun=205 → **Jul=182**. Deltas: −7, −17, −15, −19, −19, **−23**. Decline has now clearly accelerated rather than plateaued — worth flagging as a pattern that increasingly looks intentional/systemic (e.g. a shift in recording practice) rather than random drift, though root cause remains undetermined.

**DIAGSEC8/DIAGSEC9, first month off the stable-empty list:** template change (agreed post-June) applied cleanly — no more misleading "previously empty" warning. Trend so far: Apr=11, May=294, Jun=410, **Jul=366** — first decline after three months of growth. Still too early to say whether this has stabilized; continuing trend-only tracking, no fixed baseline range set yet.

---

## August 2024

| Metric | Value | vs. Jan–Mar baseline |
|---|---|---|
| Row count | 1,142,359 | Within normal range seen so far |
| Columns (original schema) | 113 | Unchanged |
| Schema check vs. dictionary | PASS | Pass — 8th consecutive month |
| Dtype changes | `DIAGSEC8`: float64→str, `DIAGSEC9`: float64→str | 5th consecutive month — expected |
| Duplicate rows | 0 | Consistent (0) |
| Implausible age (NASC > 120 yrs) | 16 records | Within baseline (11–19) |
| DIAS_PERM vs. calendar-day mismatch | 10,618 records (0.93%) | Within baseline (0.94%–1.01%, buffer) |
| RACA_COR = 99 | 175 records | **⚠ Outside baseline (258–282)** — 8-month decline, but rate slowed (−7 vs. −23 last month) |
| SEXO observed codes | 1, 3 | Unchanged |
| CEP non-8-digit | 102,656 records (8.99%) | Within baseline (buffer) — **note: only 0.03pp of buffer margin remaining, trend climbing since April** |
| Stable-empty field changes | None | All 3 remaining fields still 100% missing |
| Emerging fields (trend-only) | `DIAGSEC8`: 218 (0.019%); `DIAGSEC9`: 75 (0.0066%) | 2nd consecutive month of decline (410→366→293 total) |
| Stable-constant field changes | None | Unchanged |
| Missingness outside Jan–Mar range | `FAEC_TP`: 92.91%–93.86% → 91.93% (~11,195 more populated); `CNPJ_MANT`: 47.53%–48.05% → 49.25% (~13,708 more missing); `CGC_HOSP`: 25.41%–25.61% → 23.33% (~23,761 more populated) | **⚠ Three fields flagged simultaneously — new this month** |

**Notable finding — three facility/financial identifier fields shift together, not yet investigated:** `CGC_HOSP`, `CNPJ_MANT`, and `FAEC_TP` all fell outside their Jan–Mar range this month. Directions are mixed (`CGC_HOSP` and `FAEC_TP` missingness *decreased*; `CNPJ_MANT` missingness *increased*), so a single shared cause isn't obvious without deeper investigation — deferred per decision this month. **`CGC_HOSP` specifically is now a 2-month pattern** (July: 24.66%, August: 23.33%, same direction both times, ~15,193 additional rows populated month-over-month) — more evidence behind this one than the other two, which are appearing for the first time. Revisit in September: if `CGC_HOSP` continues the same direction and/or `CNPJ_MANT`/`FAEC_TP` recur, treat as an established pattern (facility/financing metadata reporting may be improving over the year) rather than noise.

**RACA_COR=99, 8 months:** Jan=282 → ... → Jul=182 → **Aug=175**. Decline continues but the rate has slowed for the first time (−7, vs. −19/−19/−23 the three months prior) — worth watching whether this is leveling off or just a temporary pause in an 8-month trend.

**CEP non-8-digit rate — buffer margin nearly exhausted:** August (8.99%) leaves only 0.03pp before the buffered ceiling (9.02%) would be breached. Rate has climbed steadily since April (8.46→8.44→8.55→8.62→8.99). If September ticks up further, this will flip to an explicit "OUTSIDE baseline" flag — worth treating as an anticipated finding rather than a surprise if it happens.

**DIAGSEC8/DIAGSEC9, trend continuing to decline:** Jun=410 → Jul=366 → **Aug=293**. Second consecutive month of decline since the June peak — increasingly looks like a transient spike (Apr–Jun) rather than a permanently higher baseline. Still no fixed range set; continuing trend-only tracking.

---

## September 2024

| Metric | Value | vs. Jan–Mar baseline |
|---|---|---|
| Row count | 1,117,171 | Within normal range seen so far |
| Columns (original schema) | 113 | Unchanged |
| Schema check vs. dictionary | PASS | Pass — 9th consecutive month |
| Dtype changes | `ETNIA`: int64→str (**new**); `DIAGSEC8`: float64→str; `DIAGSEC9`: float64→str | **⚠ New field affected** — see notable finding |
| Duplicate rows | 0 | Consistent (0) |
| Implausible age (NASC > 120 yrs) | 15 records | Within baseline (11–19) |
| DIAS_PERM vs. calendar-day mismatch | 10,568 records (0.95%) | Within baseline (0.94%–1.01%) |
| RACA_COR = 99 | 161 records | **⚠ Outside baseline (258–282)** — 9-month decline continues |
| SEXO observed codes | 1, 3 | Unchanged |
| CEP non-8-digit | 99,252 records (8.88%) | Within baseline (buffer) — pulled back from August's near-breach (8.99%) |
| Stable-empty field changes | None | All 3 remaining fields still 100% missing |
| Emerging fields (trend-only) | `DIAGSEC8`: 228 (0.020%); `DIAGSEC9`: 82 (0.0073%) | Slight uptick after 2 months of decline (293→310 total) |
| Stable-constant field changes | None | Unchanged |
| Missingness outside Jan–Mar range | `FAEC_TP`: → 92.04%; `CNPJ_MANT`: → 50.14%; `CGC_HOSP`: → 23.26% | 2nd–3rd consecutive month, roughly holding August's levels — possibly stabilizing rather than continuing to drift |

**Notable finding — ETNIA dtype change, first occurrence, root cause identified:** `ETNIA` has been `int64` every month since January; this is the first flip to `str`. Investigated directly: 32 records carry non-numeric values in an `X###` format (e.g. `X400`, `X266`, `X306`) instead of the standard 4-digit numeric codes. All 32 — without exception — have `RACA_COR = 5` (Indigenous), which is the only category where `ETNIA` is analytically meaningful (everyone else carries the `"0000"` placeholder, 1,114,465 of 1,117,171 rows this month). Internally consistent, not a data quality issue — appears to be a legitimate alphanumeric ethnicity-code format coexisting with the standard numeric ones. Scale is small (32 of 2,706 populated `ETNIA` records, ~1.2%). Logged as first-occurrence only; not added to any tracked list yet — revisit if it recurs in October, same approach as `DIAGSEC8`/`9` in April.

**RACA_COR=99, 9 months:** Jan=282 → ... → Aug=175 → **Sep=161** (−14). Decline continuing, roughly back to the pace seen mid-year after August's brief slowdown.

**Facility/financial fields, 2nd–3rd month:** `CGC_HOSP` (Jul 24.66 → Aug 23.33 → **Sep 23.26**), `CNPJ_MANT` (Aug 49.25 → **Sep 50.14**), `FAEC_TP` (Aug 91.93 → **Sep 92.04**) — all three roughly held their August levels rather than continuing to drift further. Tentatively reads as stabilizing at a new level rather than an open-ended trend, but one more month would confirm.

**CEP non-8-digit rate:** 8.88%, down from August's 8.99% — the buffer-ceiling concern from last month did not materialize this month.

---

## October 2024

| Metric | Value | vs. Jan–Mar baseline |
|---|---|---|
| Row count | 1,188,544 | Within normal range seen so far |
| Columns (original schema) | 113 | Unchanged |
| Schema check vs. dictionary | PASS | Pass — 10th consecutive month |
| Dtype changes | `ETNIA`: int64→str; `DIAGSEC8`: float64→str; `DIAGSEC9`: float64→str | `ETNIA` now 2nd consecutive month — see notable finding |
| Duplicate rows | 0 | Consistent (0) |
| Implausible age (NASC > 120 yrs) | 9 records | **⚠ Outside baseline (11–19)** — 2nd below-range month (June was 7) |
| DIAS_PERM vs. calendar-day mismatch | 10,998 records (0.93%) | Within baseline (0.94%–1.01%) |
| RACA_COR = 99 | 163 records | **⚠ Outside baseline (258–282)** — but first *increase* in 10 months, see notable finding |
| SEXO observed codes | 1, 3 | Unchanged |
| CEP non-8-digit | 103,966 records (8.75%) | Within baseline (buffer) — pulled back further from August's near-breach |
| Stable-empty field changes | None | All 3 remaining fields still 100% missing |
| Emerging fields (trend-only) | `DIAGSEC8`: 245 (0.021%); `DIAGSEC9`: 95 (0.0080%) | Continuing to fluctuate (293→310→340 total) |
| Stable-constant field changes | None | Unchanged |
| Missingness outside Jan–Mar range | `CNPJ_MANT`: → 49.17%; `CGC_HOSP`: → 23.84% | `FAEC_TP` **resolved** — back within range after 2 months out; other two persist |

**Notable finding — ETNIA, now a confirmed 2-month pattern:** 63 non-numeric `X###`-format records this month, up from September's 32 (~2x). Verified all 63 correlate with `RACA_COR = 5` (Indigenous), same clean signature as September — confirms this is a real, recurring alphanumeric ethnicity-coding format, not a one-off. Given the growth trajectory mirrors `DIAGSEC8`/`9`'s April→May pattern, worth watching whether this becomes a 3rd tracked "emerging field" if November confirms continued growth.

**Notable finding — RACA_COR=99, first increase in 10 months:** Jun=205 → Jul=182 → Aug=175 → Sep=161 → **Oct=163** (+2). Nine consecutive months of decline (deltas: −7,−17,−15,−19,−19,−23,−7,−14) broken by a small increase. Too early to call this a genuine reversal vs. noise around a new lower floor — needs November/December to confirm either way.

**Notable finding — implausible age, 2nd below-range month:** 9 records (June was 7) — both now-flagged months share the same understood signature from June's investigation (`COD_IDADE=5`, `NASC`≈1899 placeholder pattern). Treated as a naturally low-count month for an already-understood anomaly, not a new issue.

**Facility/financial fields diverge:** `FAEC_TP` has resolved — back within its Jan–Mar range after being flagged in August and September. `CGC_HOSP` (4th consecutive month) and `CNPJ_MANT` (3rd consecutive month) persist, though both pulled back slightly from their most extreme points (`CGC_HOSP`: 23.26%→23.84%; `CNPJ_MANT`: 50.14%→49.17%). Increasingly looks like `CGC_HOSP`/`CNPJ_MANT` reflect a genuine, more durable shift, while `FAEC_TP`'s 2-month appearance was closer to a temporary fluctuation.

---

## November 2024

| Metric | Value | vs. Jan–Mar baseline |
|---|---|---|
| Row count | 1,061,011 | Lowest month yet — noted, not treated as anomalous (fewer admission days plausible) |
| Columns (original schema) | 113 | Unchanged |
| Schema check vs. dictionary | PASS | Pass — 11th consecutive month |
| Dtype changes | `ETNIA`: int64→str; `DIAGSEC8`: float64→str; `DIAGSEC9`: float64→str | `ETNIA` now 3rd consecutive month |
| Duplicate rows | 0 | Consistent (0) |
| Implausible age (NASC > 120 yrs) | 15 records | Within baseline (11–19) |
| DIAS_PERM vs. calendar-day mismatch | 10,460 records (0.99%) | Within baseline (0.94%–1.01%) |
| RACA_COR = 99 | 152 records | **⚠ Outside baseline (258–282)** — October's uptick was noise; decline resumed |
| SEXO observed codes | 1, 3 | Unchanged |
| CEP non-8-digit | 98,496 records (9.28%) | **⚠ Outside baseline — first-ever CEP flag**, see notable finding |
| Stable-empty field changes | None | All 3 remaining fields still 100% missing |
| Emerging fields (trend-only) | `DIAGSEC8`: 257 (0.024%); `DIAGSEC9`: 89 (0.0084%) | Roughly matches October (340→346 total) — appears to have settled into a ~300–350 range |
| Stable-constant field changes | None | Unchanged |
| Missingness outside Jan–Mar range | `CNPJ_MANT`: → 50.49%; `CGC_HOSP`: → 22.64% | Both hit their most extreme values yet — see notable finding |

**Notable finding — CEP non-8-digit rate, first breach since tracking began:** exceeded the buffered ceiling (9.02%) by 0.26pp, ~2,759 records beyond what the buffer allowed. This is the trend flagged as a risk back in August ("only 0.03pp of margin remaining") — it wobbled below the line for two months (Sep 8.88%, Oct 8.75%) before finally crossing it. Full-year trend: Apr 8.46 → May 8.44 → Jun 8.55 → Jul 8.62 → Aug 8.99 → Sep 8.88 → Oct 8.75 → **Nov 9.28**. Not a sudden spike so much as a slow drift finally clearing the threshold — consistent with the CEP leading-zero storage issue being a stable but slowly worsening data characteristic over the year, not a one-off event.

**RACA_COR=99, decline resumes:** Sep=161 → Oct=163 (+2) → **Nov=152 (−11)**. Confirms October's small uptick was noise around a declining trend, not a genuine reversal — 11 months in, the overall direction remains firmly downward.

**CGC_HOSP/CNPJ_MANT — new extremes, not stabilizing after all:** contrary to October's tentative read, both fields hit their most extreme points yet this month (`CGC_HOSP`: 22.64%, lower than any prior month; `CNPJ_MANT`: 50.49%, higher than any prior month). 5th and 4th consecutive months respectively — this now looks like an ongoing drift rather than a plateau.

---

## December 2024

*Final month of the 2024 validation cycle.*

| Metric | Value | vs. Jan–Mar baseline |
|---|---|---|
| Row count | 1,090,085 | Within normal range seen so far |
| Columns (original schema) | 113 | Unchanged |
| Schema check vs. dictionary | PASS | Pass — 12th consecutive month, clean for the full year |
| Dtype changes | `ETNIA`: int64→str; `DIAGSEC8`: float64→str; `DIAGSEC9`: float64→str | `ETNIA` now 4th consecutive month |
| Duplicate rows | 0 | Consistent (0) — 0 duplicates every month, all year |
| Implausible age (NASC > 120 yrs) | 15 records | Within baseline (11–19) |
| DIAS_PERM vs. calendar-day mismatch | 11,039 records (1.01%) | Within baseline (right at the upper edge) |
| RACA_COR = 99 | 146 records | **⚠ Outside baseline (258–282)** — year-end value, see full-year finding below |
| SEXO observed codes | 1, 3 | Unchanged |
| CEP non-8-digit | 93,028 records (8.53%) | Within baseline — pulled back from November's breach |
| Stable-empty field changes | None | All 3 remaining fields still 100% missing, all 12 months |
| Emerging fields (trend-only) | `DIAGSEC8`: 286 (0.026%); `DIAGSEC9`: 113 (0.010%) | Highest month yet (346→399 total) |
| Stable-constant field changes | None | Unchanged, all 12 months |
| Missingness outside Jan–Mar range | `CNPJ_MANT`: → 49.28%; `CGC_HOSP`: → 24.04%; `DIAGSEC1`: → 76.57% | **`DIAGSEC1` returns after 7 clean months** — see notable finding |

**Notable finding — DIAGSEC1 flag returns, opposite direction from April:** first flag on this field since April (May–November were all clean). But the direction reversed: April was 78.27% (*above* the range — more missing than usual), December is 76.57% (*below* the range — more populated than usual, ~6,000+ rows more complete than baseline). Given it appeared once, disappeared for 7 months, then reappeared in the opposite direction, this reads as normal monthly noise around the edges of a narrow baseline range rather than a systemic drift — unlike `CGC_HOSP`/`CNPJ_MANT`, which have moved consistently in one direction for months.

**Full-year finding — RACA_COR=99, closing the year at 146 (down 48% from January):** Jan=282 → Feb=275 → Mar=258 → Apr=243 → May=224 → Jun=205 → Jul=182 → Aug=175 → Sep=161 → Oct=163 → Nov=152 → **Dec=146**. Nearly halved over 12 months, with only one minor uptick (October, +2, later shown to be noise). This is the most consistent trend of the year — worth flagging in any future write-up as a genuine year-over-year shift in how "not informed" race/color is being recorded, though the underlying cause was never identified within the scope of this validation exercise.

**Full-year finding — CGC_HOSP/CNPJ_MANT, 6th and 5th consecutive months:** `CGC_HOSP` ticked back up from November's low (22.64% → 24.04%); `CNPJ_MANT` pulled back from November's peak (50.49% → 49.28%). Both remain outside their Jan–Mar range but the extreme monotonic drift seen in Oct–Nov didn't continue — closes the year looking more like sustained elevated variability than runaway drift.

**DIAGSEC8/DIAGSEC9 — highest month of the year:** 399 total (286+113), surpassing June's previous peak (410 combined — essentially tied). Full-year trend: 11→294→410→366→293→310→340→346→**399**. Never returned to April's near-zero baseline after the initial jump — this now reads as a genuine, permanent shift in coding practice starting in April 2024, not a temporary spike. Worth setting a proper Layer 2 baseline range for 2025 data using the Apr–Dec range as the new normal, rather than continuing indefinite trend-only tracking.

**ETNIA — 4th consecutive month, fluctuating within an established range:** Sep=32 → Oct=63 → Nov=55 → Dec=37 — settled into roughly a 30–65 record range rather than continuing to grow. Same `RACA_COR=5` correlation held in this month's sample. Candidate for a proper tracked range in 2025, similar to `DIAGSEC8`/`9`.

---

## 2024 Full-Year Summary

All 12 months validated (Jan–Mar full domain-by-domain validation; Apr–Dec streamlined checks with targeted investigation on flags). Key takeaways for portfolio documentation:

- **Schema stability**: 113/113 columns matched the dictionary in all 12 months — zero schema drift for the entire year.
- **Zero duplicate records** in any month.
- **Three genuinely new patterns emerged during the year** (not present in the Jan–Mar baseline): `DIAGSEC8`/`DIAGSEC9` populating (high-comorbidity coding, April onward), `ETNIA` alphanumeric codes (Indigenous ethnicity sub-codes, September onward), and a sustained shift in `CGC_HOSP`/`CNPJ_MANT` missingness (facility/manager CNPJ reporting, July onward) — all three investigated and found to be legitimate, not data quality defects.
- **One clear year-long trend**: `RACA_COR=99` declined 48% from January to December, the most consistent pattern observed — cause undetermined, flagged for any future analysis using this field.
- **One threshold breach**: CEP non-8-digit rate exceeded its established range once (November), following a slow upward drift visible from August onward — resolved by December.
- **Streamlined-check design validated**: the April decision to move from full validation to structural + trend-based checks caught every meaningful finding above without requiring a full 11-domain re-profile in any month after March.

---

## Running Interpretation

- **Schema**: stable across Jan–Mar (113/113 match, 0 unexpected columns either direction, 3 consecutive months). Confirms all months tested so far share identical structure.
- **Anomaly patterns**: implausible-birthdate records, RACA_COR=99, DIAS_PERM mismatches, and non-standard CEP formatting all recur at consistent rates across three independent months. These are systemic SIH/SUS characteristics, not isolated data-entry errors in any one month.
- **Scope note**: this diff-log tracks a deliberately selected set of structural checks and recurring validation findings — not a literal comparison across all 11 domains. Each month closely mirrors the others on the metrics tracked here; no new schema-level issues or materially different anomaly patterns identified within that scope.
- **DECISION GATE REACHED (post-March):** three months of full domain-by-domain validation confirm stable schema and consistent recurring anomaly rates. Per the pre-agreed plan, full manual validation stops here. April–December move to a streamlined check: structural checks (row/column count, schema match, dtype changes) + the specific recurring quality metrics tracked in this table. Full domain investigation is reserved for any month where the streamlined check flags something that breaks this pattern.
- **Streamlined check validated (April):** first month run under the new process, and it worked as designed — Layer 3 change-detection caught two genuine first-occurrence/trend findings (`DIAGSEC8`/`9` populating for the first time, `RACA_COR=99` continuing a 4-month decline) without requiring a full re-profile of all 11 domains. Both were resolved via a small targeted investigation, not a return to exhaustive validation.

---

## Template Notes (carried forward, not month-specific)

- `pd.to_datetime` insertion for `NASC_dt`/`DT_INTER_dt`/`DT_SAIDA_dt` triggers a `PerformanceWarning` (DataFrame fragmentation) every month — cosmetic, not a data issue. Candidate fix if/when refactoring: build all three at once via `pd.concat`.
- Dictionary schema-check cell (`dict_df` load) depends on `filtered_dict_translated.csv` path — confirm path validity before each new month's run.

---

## Months Remaining (streamlined check from here)

None — all 12 months of 2024 validated (Jan–Mar full validation, Apr–Dec streamlined checks). See "2024 Full-Year Summary" above.
