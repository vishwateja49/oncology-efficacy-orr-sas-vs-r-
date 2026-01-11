# SAS vs R Implementation Notes

This repository contains both SAS and R implementations of the
same oncology ORR efficacy table.

---

## Analytical Equivalence

- Both implementations use the same endpoint definitions
- The same analysis populations are applied
- Statistical methods are conceptually aligned

Differences reflect tool-specific idioms rather than
analytical intent.

---

## SAS Implementation

- Uses PROC SQL and PROC FREQ for derivations
- Relies on ODS OUTPUT for statistical results
- Mirrors traditional CRO and sponsor reporting workflows

---

## R Implementation

- Uses pharmaverse ADaM data and tidyverse-based derivations
- Employs exact binomial confidence intervals
- Produces CSR-style output using `r2rtf`

---

## Intent

The goal is not to compare languages syntactically, but to
demonstrate how the same clinical reporting logic can be
implemented across platforms.
