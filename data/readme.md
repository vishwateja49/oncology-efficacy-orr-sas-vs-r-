
# Analysis Data

This folder contains **synthetic ADaM datasets** used to reproduce the
oncology Objective Response Rate (ORR) efficacy analysis in this repository.

---

## Data Source

The datasets in this folder are sourced from the **pharmaverse ecosystem**
and are intended for demonstration and educational purposes only.

- No real clinical trial data is included
- No sponsor, subject-identifiable, or proprietary data is used
- The data structure reflects CDISC ADaM conventions

---

## Datasets

### ADSL (Subject-Level Analysis Dataset)
Contains one record per subject and includes:
- Treatment assignment (TRT01P)
- Subject identifiers (USUBJID)
- Analysis population information

### ADRS (Tumor Response Analysis Dataset)
Contains tumor response records and includes:
- Best Overall Response (BOR)
- Response categories (CR, PR, SD, PD)
- Treatment assignment (TRT01P)

Only records relevant to the ORR analysis are used.

---

## Usage Notes

- These datasets are included to ensure **full reproducibility** of the
  SAS and R programs in this repository
- Derived or intermediate datasets are not stored
- All analysis derivations are performed within the code

---

## Compliance Statement

This repository uses **synthetic data only** and is safe for public sharing.
The analysis logic mirrors real-world oncology reporting workflows, with
synthetic data substituted for proprietary inputs.
