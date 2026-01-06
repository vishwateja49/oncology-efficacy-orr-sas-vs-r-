# Oncology Efficacy Table (ORR): SAS vs R (pharmaverse)
<img width="841" height="280" alt="Screenshot 2026-01-06 102945" src="https://github.com/user-attachments/assets/efe0501f-b0a9-4319-aafe-0ec6d0c2a512" />

This repository demonstrates an industry-style implementation of an
oncology Objective Response Rate (ORR) efficacy table using:

- **SAS** (traditional clinical reporting workflow)
- **R (pharmaverse + ADaM-based analysis)**

The goal is not to teach syntax, but to showcase **production-level thinking,
traceability, and efficiency** when transitioning from SAS to R in a
regulated clinical research environment.

## Objective

- Generate a Summary of Objective Response Rate (ORR) table
- Based on ADaM datasets (ADSL, ADRS)
- Using identical business logic in:
  - SAS
  - R (pharmaverse ecosystem)
- Compare **code structure, readability, and scalability**

## Why This Repository?

Most SAS vs R examples online are academic or toy examples.

This project reflects:
- Real-world oncology endpoints
- ADaM-compliant inputs
- Table-ready outputs suitable for CSR or IB use
- A programmer’s perspective who has **worked in SAS-first environments**
  and is now leveraging R for efficiency and reproducibility.
## Input Data

- **ADSL**: Subject-level analysis dataset
- **ADRS**: Tumor response analysis dataset

Data used here is:
- Synthetic / anonymized
- Structurally aligned with CDISC ADaM
- Designed to reflect real oncology workflows
## SAS Implementation

The SAS program follows a conventional clinical reporting flow:

- Data preparation using DATA step and PROC SQL
- Derivation of best overall response
- Calculation of ORR and confidence intervals
- Table formatting suitable for RTF output

This mirrors typical CRO and sponsor-side workflows.
## R Implementation (pharmaverse)

The R workflow uses:
- `pharmaverseadam` for ADaM-aligned data handling
- Functional, modular code design
- Clear separation between:
  - data preparation
  - analysis logic
  - table generation

Compared to SAS, this approach:
- Reduces boilerplate code
- Improves readability
- Enhances reproducibility and version control
# SAS vs R: Practical Insights from an Oncology Table

## What SAS Does Well
- Established validation processes
- Familiar to regulatory teams
- Stable for legacy pipelines

## Where R Adds Real Value
- Faster iteration for complex endpoints
- Cleaner abstraction of analysis logic
- Better collaboration via Git
- Easier extension to visual analytics

## Key Takeaway
R is not a replacement for SAS.
It is an accelerator when used by programmers who understand
clinical standards and reporting expectations.
## What This Demonstrates

- Hands-on experience with oncology efficacy endpoints
- Ability to translate SAS logic into R without loss of rigor
- Comfort working with ADaM datasets
- Practical understanding of regulated clinical reporting
