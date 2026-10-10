# SIH/SUS Project — References & Sources

**Last updated: 2026-09-01**

Documents the external sources used to validate, interpret, and categorize the SIH/SUS 2024 dataset. Distinguishes what's **confirmed by official documentation** from what's **empirically observed but not externally confirmed**, so downstream write-ups don't overclaim either way.

---

## Primary Sources

### DATASUS — Notas Técnicas
[DATASUS Technical Notes — SIH-SUS](http://tabnet.datasus.gov.br/cgi/sih/rxdescr.htm)


Official Ministério da Saúde / DATASUS technical documentation for SIH-SUS hospitalization data. Highest-authority source used in this project.

**Confirms:**
- AIH processing-period mechanism: processing period generally corresponds to discharge month, but AIHs re-presented after rejection, or associated with long-stay hospitalizations, can appear across consecutive processing periods. Explains — but does not fully account for the scale of — the historical `DT_INTER` dates (back to 2008) found in the January 2024 file.
- Distinction between hospitalization-location and patient-residence-location variables (maps to `MUNIC_MOV` vs. `MUNIC_RES`).
- Official assignment rule for `DIAG_PRINC` vs. secondary diagnosis fields in multi-surgery cases.

**Not confirmed by this source (checked, not found):**

- Specific `DIAS_PERM`/hospital-occupancy calculation caveat — not located in retrieved text. 


Additional finding verified on subsequent review:
- UF_ZI: DATASUS documentation states that, according to the AIH payment system, some hospitals are associated with a Federation Unit (UF-ZI) that does not correspond to the Federation Unit of their physical location. Therefore, UF_ZI should not be interpreted as a direct indicator of hospital physical location.






### Data Science Platform Applied to Health (PCDaS) — SIHSUS ETL Documentation

The documentation describes the extract, transform, and load (ETL) process applied to data from DATASUS’s SUS Hospital Information System (SIH/SUS) for integration into the Data Science Platform Applied to Health (PCDaS). This source was consulted to understand data enrichment and transformation processes, including the use of decoded fields in the dataset.

[SIH/SUS — PCDaS Documentation](https://pcdas.icict.fiocruz.br/conjunto-de-dados/sistema-de-informacoes-hospitalares-do-sus-sihsus/documentacao/)
### Portela et al., "Algoritmo para a composição de dados por internação a partir do SIH/SUS"
Cadernos de Saúde Pública, 1997, 13(4):771-774. DOI: 10.1590/S0102-311X1997000400020. Portela, Schramm, Pepe, Noronha (Escola Nacional de Saúde Pública/Fiocruz), Pinto, Cianeli (Secretaria de Saúde do Estado do Rio de Janeiro).
[Portela et al. (1997) — article DOI](https://doi.org/10.1590/S0102-311X1997000400020)

**Note on age:** published 1997 — nearly 30 years old. Cited as the foundational methodological paper for a *structural characteristic of the AIH system* that remains true today (confirmed still being cited in a 2024 systematic review of SIH/SUS strengths and limitations), not as a description of the current data pipeline.

**Confirms:**
- An AIH can represent either a single acute admission, or a **delimited segment of a longer hospitalization** — the original academic source for the AIH-fragmentation pattern this project independently observed via historical `DT_INTER` dates and `N_AIH` non-uniqueness (see `diff_log.md`, January and May/June findings).
- Presents a published algorithm for composing multiple AIH records into one coherent hospitalization episode, specifically to get accurate mortality, cost, and length-of-stay figures for long-stay/chronic/psychiatric patients — a candidate method if this project ever needs true hospitalization-level (not AIH-level) analysis for Q2/Q3.


(Field-level layout documentation and regulatory Portarias referenced during dictionary categorization review)

**Confirms:**
- `NUM_PROC` = "Número do processamento" (processing/batch number) — an **administrative** field, not procedure-related. Original dictionary categorization (Procedures domain) corrected to Administrative based on this finding.
- `NUM_FILHOS`, `INSTRU`, `CID_NOTIF` are **conditionally populated fields**, filled only for tubal ligation, C-section-with-ligation, or vasectomy procedures — not general patient demographic fields. High missingness in these fields is structural/expected, not a data quality issue.
- `ETNIA` field origin: added via Portaria 508 (28/09/2010), effective from the October 2010 competence period onward. Confirms the field itself is long-standing and regulated.
- Portaria 1.324/2014: introduced the 8 secondary CID (`DIAGSEC1`–`8`) field structure; removed earlier "Diagnóstico da Causa Morte" and "Diagnóstico Causas Complementares" fields from the standard layout (relevant context for `CID_MORTE`/`CID_ASSO`).

**Not confirmed by this source:**
- The specific alphanumeric `X###` format observed in `ETNIA` values (e.g. `X400`, `X306`) starting September 2024 — field provenance is confirmed, this specific code format is not documented anywhere located. Conclusion that it's legitimate rests on internal consistency only (100% correlation with `RACA_COR=5` across all 195 instances observed Sep–Dec).

### Souto et al., "Dataset of hospital admissions authorizations in Brazil"
Research Square preprint, DOI: 10.21203/rs.3.rs-3838281/v1 — Souto, Kreischer, Saldanha, et al. (PCDaS/ICICT, Fiocruz), posted January 2024.

[Souto et al. — Research Square preprint](https://doi.org/10.21203/rs.3.rs-3838281/v1)

Describes the PCDaS team's own ETL methodology for SIH/SUS data — directly relevant as the same institutional source as this project's data dictionary.

**Confirms:**
- Dataset is specifically **AIH RD (Reduced)** — records that have been "effectively processed and validated" — distinct from AIH RJ (Rejected, pending) and SP (professional services detail). Worth stating explicitly as dataset scope.
- Authoritative admission of source dictionary imperfection: *"As DATASUS creates the original data dictionary, less than 10% of the variables do not precisely describe their meaning."* Direct support for the `NUM_PROC` miscategorization finding — a documented characteristic of the source, not a project error.
- Original files are legacy DBC (compressed DBF) format — explains why encoding handling (Latin-1) is a known, expected characteristic of this data ecosystem.
- Their own ETL structure (extraction → post-extraction validation → transformation → post-transformation validation) parallels this project's Raw → Validated → Analysis layering.
- Variable structure has been "more stable and compatible after 2008" — supports treating 2024 data as structurally reliable.

### Coelho, Rocha & Hone, "Improvements in data completeness in health information systems reveal racial inequalities: longitudinal national data from hospital admissions in Brazil 2010–2022"
*International Journal for Equity in Health*, 2024. DOI: 10.1186/s12939-024-02214-3

[Coelho, Rocha & Hone (2024) — article DOI](https://doi.org/10.1186/s12939-024-02214-3)

Peer-reviewed national longitudinal study of race/color data completeness in SIH specifically.

**Confirms — major finding:**
- Missing race/color values in Brazil's SIH declined from **34.7% (2010) to 21.2% (2020)** — an 11-year, national, documented trend of improving race/color recording completeness. This directly explains this project's largest unresolved 2024 finding: `RACA_COR = 99` declining 48% (282→146) over the year is consistent with, and likely a continuation of, this pre-existing national trend — not noise or a project-specific artifact. **This finding is moved to the "Confirmed" table below** on the strength of this source, though the exact code (`RACA_COR=99` specifically, vs. general "missing") and the specific 2024 monthly rate of decline are the project's own empirical measurement, not directly replicated in the paper.

### bigdata-icict/ETL-Dataiku-DSS — `bases_auxiliares.zip` (full lookup tables)


[PCDaS/ICICT ETL repository — auxiliary SIH lookup tables](https://github.com/bigdata-icict/ETL-Dataiku-DSS/blob/master/SIH/bases_auxiliares.zip)`

The actual auxiliary lookup tables referenced by the ETL wiki page above — not samples or excerpts, but the complete official code tables PCDaS's own pipeline joins against. Obtained and inspected directly for this project. Copies retained in `lookup_tables/` (`ETNIA.csv`, `NACION3D.csv`, `CBO.csv`, `CNAE.csv`, `LEITOS.csv`, `TB_SIGTAB.csv`).

**Resolves, definitively:**
- `NACIONAL` (332 nationality codes), `CBOR` (2,651 occupation codes), `CNAER` (217 CNAE industry codes), `ESPEC` (38 bed-specialty codes, up from a 4-code sample), `PROC_SOLIC`/`PROC_REA` (5,182 procedure codes each, independently sourced per field, not ambiguous) — all previously undecoded due to insufficient variation in the 100-row `preview_SIH.csv` sample. Full tables now available; no longer a gap.

**Upgrades — but does not fully close — the `ETNIA` finding:**
- The official `ETNIA.csv` contains exactly **265 codes**, `0000`–`0264`, **all purely numeric**. Confirmed matches for every previously-found code (`0058`=Guarani Kaiowá, `0077`=Kaingang, `0111`=Kaxinawá, `0207`=Terena, etc.).
- **Zero letter-prefixed codes exist anywhere in this table.** This means the `X###`-format codes observed in the actual 2024 data (Sep–Dec, e.g. `X400`, `X306`, `X266`) are now **confirmed absent** from the official lookup table used by this ETL pipeline — a stronger, more precise statement than "undocumented." Two explanations remain open: (a) a newer/updated official indigenous-ethnicity coding scheme exists (e.g., via FUNAI) that post-dates this 2019-vintage auxiliary table, or (b) some other coding convention not captured in this specific snapshot. Neither is confirmed. The underlying correlation with `RACA_COR=5` (100% across all 195 observed instances) still holds and remains the best available evidence that the codes are structurally legitimate, even without a label source.

### bigdata-icict/ETL-Dataiku-DSS — SIM dictionary (`dict_SIM.csv`)


[PCDaS/ICICT ETL repository — SIM dictionary](https://github.com/bigdata-icict/ETL-Dataiku-DSS/blob/master/SIM/dict_SIM.csv)

SIM (Sistema de Informações sobre Mortalidade) is a different DATASUS subsystem from SIH — checked here only for a specific comparison, not adopted as a source for this project's SIH-based derivations.

**Finding, precisely scoped:** `dict_SIM.csv` lists `RACACOR` as `3=Amarela, 4=Parda` — the reverse ordering of what this project's SIH `RACA_COR` derivation uses (`3=Parda, 4=Amarela`). **This is documented as "the SIM dictionary shows a different ordering for codes 3/4 than what is observed in SIH," not as "SIM and SIH use swapped codes" as a system-wide rule** — no primary SIH source was found explicitly contrasting itself against SIM, so the broader claim isn't supported by what's actually been checked, only the two specific documents/observations compared here.

**Project decision:** the SIH `RACA_COR` mapping used in Q1 (`3=Parda, 4=Amarela`) is retained as-is, supported by two independent, already-verified sources: the project's own empirically-decoded real SIH output (`preview_SIH.csv`), and the current official Brazilian national standard (IBGE-aligned, also used in Coelho, Rocha & Hone 2024, already cited above). Both agree with each other and disagree with `dict_SIM.csv` — the SIM dictionary is the outlier here, not the tiebreaker. No change to Q1's already-completed derivation.


### bigdata-icict/ETL-Dataiku-DSS Wiki — "SIH" page


[PCDaS/ICICT ETL Wiki — SIH decoding and enrichment](https://github.com/bigdata-icict/ETL-Dataiku-DSS/wiki/SIH#1-decodificando-e-enriquecendo-os-dados)

Official methodology documentation from the same institutional source as `dict_SIH.csv` (already cited above) and `preview_SIH.csv` (Synapse: syn52558808). Documents the decoding/enrichment ("decodificando e enriquecendo os dados") process used to generate the `def_*`-labeled columns mined for this project's `variable_reference.csv`.

**Relevance:** confirms `preview_SIH.csv`'s `def_*` columns are official PCDaS-generated decodes, not ad hoc or self-derived — produced by the same pipeline described in the Souto et al. 2024 preprint (extraction → validation → transformation → validation). Supports treating the extracted value labels (`RACA_COR`, `ESPEC`, `SEXO`, `MORTE`, diagnosis chapter hierarchy, age-bucket schemes, etc., see `variable_reference.csv`) as authoritative rather than independently inferred — same institutional lineage as the rest of this reference chain.

---

### Kaggle — "SIH/SUS - Hospital Admissions Municipalities 2024"

[Original Kaggle dataset — SIH/SUS Hospital Admissions Municipalities 2024](https://www.kaggle.com/datasets/andersonfranca/sistema-de-informaes-hospitalares-sus/data)

The original dataset source this project began from. Referenced again here specifically because its documentation confirms the `IDENT` field's full code scheme: `1=Principal, 3=Continuação, 5=Longa permanência`. This resolves what was previously an uncited claim (`IDENT=3="Continuação"` had no source in this project's own verification trail, though code 3 was never observed in the 2024 data regardless). `IDENT=1` and `IDENT=5` were already independently confirmed via the official ETL wiki decode table and directly via SQL frequency queries against the raw data (see Q3/Q4 variable references and `PROJECT_STATUS_SUMMARY.md`).

## Supporting Sources

### PCDaS / Fiocruz (ICICT) Documentation

[PCDaS/Fiocruz — SIH/SUS documentation](https://pcdas.icict.fiocruz.br/conjunto-de-dados/sistema-de-informacoes-hospitalares-do-sus-sihsus/documentacao/)

[PCDaS/Fiocruz — SIH/SUS visual analysis](https://pcdas.icict.fiocruz.br/conjunto-de-dados/sistema-de-informacoes-hospitalares-do-sus-sihsus/analise-visual/)

Source of the original 241-variable data dictionary, filtered to the 113 variables present in this dataset and translated to English. Same institutional lineage as `bigdata-icict/ETL-Dataiku-DSS` (GitHub), which was cross-referenced during initial dictionary construction (`dict_SIH.csv`).

### healthbR (R package documentation)

[healthbR — SIH hospital admissions guide](https://sidneybissoli.github.io/healthbR/articles/sih-hospital-admissions.html)

Practical/applied reference confirming general SIH structure (monthly AIH-level records, state coverage) and a plausible set of analytically central variables (`DIAG_PRINC`, `DIAS_PERM`, `MORTE`, `MUNIC_RES`/`MUNIC_MOV`, `VAL_TOT`, `PROC_REA`, `UTI_MES_TO`, `SEXO`, `NASC`). Treated as a supporting/practical source, not primary authority — DATASUS documentation takes precedence wherever the two would conflict.

### Villegas Ramirez, "A Look Into Public Healthcare Data Sources (5/5): DATASUS BRAZIL"
LinkedIn article, April 2024.

**Lowest tier of the sources used here** — a practitioner (epidemiologist/PM) thought-leadership post, not peer-reviewed or government-issued. Included for one specific, independently verified legal citation and one useful scope clarification; general background claims in the article (founding year, mission statement, population figures) are treated as approximate context, not relied upon for any specific finding.

**Verified independently before inclusion:**
- Cites Resolução CNS 510/2016 as the basis for public-domain health data being exempt from ethics-committee (CEP/CONEP) review. Confirmed directly against the resolution text (Art. 1º, sole paragraph): research using publicly-accessible information (Lei 12.527/2011), public-domain information, or aggregated non-identifiable data is exempt. A separate legal-commentary source explicitly names DATASUS-based studies as falling under this exemption. More precise citation than a general "Brazilian legislation exempts public data" statement.

**Useful, not independently verified:**
- SIA (outpatient/ambulatory) vs. SIH (hospital/inpatient) system distinction — confirms this project's data is inpatient-only, not ambulatory. Consistent with everything else in this reference set; not separately fact-checked.
- ~150 million people (~75%+ of Brazil's population) rely exclusively on SUS — useful context for dataset representativeness framing; treated as an approximate figure from a secondary source, not cited as precise.

---

## Findings Confirmed by External Documentation

| Finding | Source |
|---|---|
| Historical/carryover `DT_INTER` dates in monthly files | DATASUS Notas Técnicas (AIH reprocessing mechanism) |
| `N_AIH` not a guaranteed unique-per-patient identifier; can represent a segment of a longer hospitalization | DATASUS Notas Técnicas (AIH re-presentation after rejection/correction) + Portela et al. 1997 (independent academic confirmation, original source for this structural characteristic) |
| `MUNIC_RES` vs. hospitalization-location distinction | DATASUS Notas Técnicas |
| `NUM_PROC` is administrative, not procedure-related | DATASUS SIH RD layout |
| `NUM_FILHOS`/`INSTRU`/`CID_NOTIF` are conditional, procedure-triggered fields | DATASUS SIH RD layout (Portaria references) |
| `ETNIA` field regulatory origin (Oct 2010) | DATASUS SIH RD layout (Portaria 508/2010) |
| Dataset is AIH RD (processed/validated), not RJ or SP | Souto et al. 2024 |
| Source dictionary has known imperfections (~10% of variables) | Souto et al. 2024 |
| **`RACA_COR = 99` declining over time reflects a real, pre-existing national trend, not noise** | National SIH race/color missingness declined from 34.7% in 2010 to 21.2% in 2020 [Coelho, Rocha & Hone (2024)](https://doi.org/10.1186/s12939-024-02214-3);contextual evidence only for the project's 2024 pattern |
| Dataset scope is hospital/inpatient (SIH), distinct from ambulatory (SIA) | Villegas Ramirez 2024 (LinkedIn) |
| Research using public-domain information is listed among the categories exempt from CEP/CONEP registration and evaluation | Resolução CNS nº 510/2016, Art. 1º, sole paragraph, item III — [official text](https://www.gov.br/conselho-nacional-de-saude/pt-br/atos-normativos/resolucoes/2016/resolucao-no-510.pdf) | 
| `variable_reference.csv` decoded value labels are official PCDaS decodes, not self-inferred | bigdata-icict/ETL-Dataiku-DSS Wiki, "SIH" page |
| `ETNIA` alphanumeric `X###` codes are confirmed **absent** from the official 265-code ETNIA lookup table (all-numeric, `0000`–`0264`) | `bases_auxiliares.zip`, `ETNIA.csv` (directly inspected) |
| `NACIONAL`, `CBOR`, `CNAER`, `ESPEC`, `PROC_SOLIC`/`PROC_REA` full code tables | `bases_auxiliares.zip` (directly inspected) |

## Findings Empirically Observed, Not Externally Confirmed

*(Internally consistent within the data; no external documentation located confirming root cause. Stated as such in any analysis or write-up — not presented as externally validated.)*

| Finding | Basis for confidence |
|---|---|
| `DIAGSEC8`/`DIAGSEC9` populating starting April 2024, never reverting | Internal consistency (sequential slot-filling, `TPDISEC` alignment); no source addresses timing |
| `CGC_HOSP`/`CNPJ_MANT` missingness shift starting July 2024 | Internal trend consistency; no source located |
| `ETNIA` alphanumeric `X###` codes' actual meaning (Sep–Dec 2024) | Confirmed **absent** from the official 265-code lookup table (upgraded finding, see Confirmed table above) — but the codes' actual intended labels remain unknown. 100% correlation with `RACA_COR=5` across all observed instances is the only evidence of structural legitimacy. |

---

*Last updated alongside the 2024 full-year SIH/SUS validation cycle. Update this file if additional primary-source documentation is located for any "not externally confirmed" finding above.*
