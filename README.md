# Oncology Objective Response Rate (ORR) Efficacy Table  
### SAS vs R 

This repository demonstrates a **real-world clinical reporting implementation**
of an oncology Objective Response Rate (ORR) efficacy table using:

- **SAS** (PROC FREQ, PROC SQL, ODS)
- **R** (pharmaverse ADaM data + tidyverse + r2rtf)

## Output

<img width="841" height="280" alt="Screenshot 2026-01-06 102945" src="https://github.com/user-attachments/assets/20a78681-8174-4562-a84e-12c4ce44d10a" />

The project is designed to reflect **production-style oncology reporting**
rather than tutorial examples, with identical business logic implemented
independently in SAS and R.
## Objective

- Summarize Best Overall Response (BOR)
- Derive Objective Response Rate (CR or PR)
- Compute:
  - Clopper–Pearson 95% CI for ORR
  - Difference in ORR vs Placebo
  - 95% CI for difference
  - P-value for treatment comparison
- Produce a CSR-ready RTF table
## Input Data

- **ADSL** – Subject-level analysis dataset  
- **ADRS** – Tumor response analysis dataset  

The datasets are **synthetic ADaM data provided by the pharmaverse ecosystem**.

- No real clinical trial data is used
- No proprietary or sponsor data is included
- Data is included to ensure reproducibility
## Endpoint Definitions

- **Best Overall Response (BOR)**:
  - CR, PR, SD, PD based on tumor response records

- **Objective Response Rate (ORR)**:
  - Proportion of subjects with CR or PR
## Statistical Methods

- ORR calculated by treatment group
- Exact binomial (Clopper–Pearson) 95% CI for ORR
- Difference in ORR between active treatment and placebo
- Approximate 95% CI for difference
- Cochran–Armitage / Chi-square test for treatment comparison
## SAS Implementation

The SAS program uses standard clinical reporting procedures:

- PROC SQL for Big N derivation
- PROC FREQ for:
  - BOR counts
  - ORR estimation
  - Exact binomial CI
  - Risk difference and CI
- PROC TRANSPOSE for table shaping
- ODS OUTPUT for statistical results

This reflects a traditional CRO/sponsor oncology reporting workflow.
## R Implementation (pharmaverse)

The R program reproduces the same analysis logic using:

- `pharmaverseadam` for ADaM-aligned data
- `dplyr` and `tidyr` for derivations
- `binom` for exact confidence intervals
- `DescTools` for trend testing
- `r2rtf` for CSR-ready table output

The script demonstrates how SAS-style reporting logic
can be translated into an R workflow while maintaining
clinical rigor.


The output layout mirrors standard oncology efficacy tables
used in clinical study reports.
## SAS vs R: Practical Notes

- SAS provides established, regulator-familiar procedures
- R offers improved modularity, readability, and version control
- Both implementations use the same endpoint definitions
- Differences reflect tool-specific idioms, not analytical intent

