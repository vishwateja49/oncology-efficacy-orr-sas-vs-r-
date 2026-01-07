library(dplyr)
library(tidyr)
library(binom)
library(DescTools)
library(r2rtf)
library(pharmaverseadam)

#------------------------------------------------------------
# Step 1: Subject count (Big N) by treatment
#------------------------------------------------------------

adsl_analysis <- pharmaverseadam::adsl %>%
  filter(!TRT01P %in% c("Screen Failure", "Xanomeline Low Dose"))

trt_n <- adsl_analysis %>%
  group_by(TRT01P) %>%
  summarise(N = n_distinct(USUBJID), .groups = "drop") %>%
  arrange(TRT01P)

N_high     <- trt_n$N[trt_n$TRT01P == "Xanomeline High Dose"]
N_placebo  <- trt_n$N[trt_n$TRT01P == "Placebo"]

#------------------------------------------------------------
# Step 2: Best Overall Response (BOR) counts and percentages
#------------------------------------------------------------

bor_data <- pharmaverseadam::adrs_onco %>%
  filter(
    PARAMCD == "BOR",
    AVALC %in% c("CR", "PR", "SD", "PD", "NE"),
    !TRT01P %in% c("Screen Failure", "Xanomeline Low Dose")
  )

bor_counts <- bor_data %>%
  group_by(TRT01P, AVALC, AVAL) %>%
  summarise(COUNT = n(), .groups = "drop")

bor_summary <- bor_counts %>%
  left_join(trt_n, by = "TRT01P") %>%
  mutate(
    val = paste0(COUNT, " (", sprintf("%.2f", COUNT / N * 100), "%)"),
    txt = case_when(
      AVALC == "CR" ~ "  Complete Response (CR)",
      AVALC == "PR" ~ "  Partial Response (PR)",
      AVALC == "SD" ~ "  Stable Disease (SD)",
      AVALC == "PD" ~ "  Progressive Disease (PD)"
    ),
    sec = 1
  )

bor_table <- bor_summary %>%
  select(sec, AVAL, TRT01P, txt, val) %>%
  pivot_wider(names_from = TRT01P, values_from = val)

# Section header row
bor_header <- data.frame(txt = "Best Overall Response", sec = 1, AVAL = 0)

bor_final <- bind_rows(bor_header, bor_table) %>%
  mutate(across(where(is.character) & !txt,
                ~ if_else(AVAL > 1 & is.na(.), "0", .)))

#------------------------------------------------------------
# Step 3: Objective Response Rate (CR or PR)
#------------------------------------------------------------

orr_flagged <- bor_data %>%
  mutate(orr_flag = if_else(AVALC %in% c("CR", "PR"), 1, 0))

orr_counts <- orr_flagged %>%
  filter(orr_flag == 1) %>%
  group_by(TRT01P) %>%
  summarise(COUNT = n(), .groups = "drop")

orr_summary <- orr_counts %>%
  left_join(trt_n, by = "TRT01P") %>%
  mutate(
    val = paste0(COUNT, " (", sprintf("%.2f", COUNT / N * 100), "%)"),
    txt = "Best Objective Response (CR or PR)",
    sec = 2
  ) %>%
  select(txt, TRT01P, val, sec) %>%
  pivot_wider(names_from = TRT01P, values_from = val)

#------------------------------------------------------------
# Step 4: 95% CI for ORR (Clopper–Pearson)
#------------------------------------------------------------

orr_ci <- orr_flagged %>%
  group_by(TRT01P) %>%
  summarise(
    success = sum(orr_flag),
    total = n(),
    .groups = "drop"
  ) %>%
  rowwise() %>%
  mutate(
    ci = list(binom.confint(success, total, method = "exact")),
    lower = ci$lower ,
    upper = ci$upper 
  ) %>%
  ungroup() %>%
  mutate(
    val = paste0(sprintf("%.2f", lower), "% - ", sprintf("%.2f", upper), "%"),
    txt = " 95% CI for Objective Response Rate",
    sec = 3
  ) %>%
  select(txt, TRT01P, val, sec) %>%
  pivot_wider(names_from = TRT01P, values_from = val)

#------------------------------------------------------------
# Step 5: Difference vs Placebo and CI
#------------------------------------------------------------

placebo_rate <- mean(orr_flagged$orr_flag[orr_flagged$TRT01P == "Placebo"])

diff_results <- orr_flagged %>%
  filter(TRT01P != "Placebo") %>%
  group_by(TRT01P) %>%
  summarise(
    rate = mean(orr_flag),
    n = n(),
    .groups = "drop"
  ) %>%
  mutate(
    diff = placebo_rate - rate,
    se = sqrt((rate * (1 - rate) / n) +
                (placebo_rate * (1 - placebo_rate) /
                   sum(orr_flagged$TRT01P == "Placebo"))),
    lower = diff - 1.96 * se,
    upper = diff + 1.96 * se
  )

diff_table <- diff_results %>%
  mutate(
    val2 = paste0(sprintf("%.4f", diff), "%"),
    txt = " Difference in Objective Response Rate",
    sec = 4
  )

diff_ci_table <- diff_results %>%
  mutate(
    val2 = paste0(sprintf("%.2f", lower), "% - ",
                  sprintf("%.2f", upper), "%"),
    txt = "  95% CI for Difference in Objective Response Rate",
    sec = 5
  )

#------------------------------------------------------------
# Step 6: Cochran–Armitage Trend Test
#------------------------------------------------------------

trend_test <- CochranArmitageTest(
  table(orr_flagged$TRT01P, orr_flagged$orr_flag)
)

pvalue_row <- data.frame(
  txt = "  P-value",
  sec = 6,
  val2 = sprintf("%.4f", trend_test$p.value)
)

#------------------------------------------------------------
# Step 7: Final table assembly
#------------------------------------------------------------

orr_table_raw <- bind_rows(
  bor_final,
  orr_summary,
  orr_ci,
  diff_table,
  diff_ci_table,
  pvalue_row
) %>%
  arrange(sec)

#------------------------------------------------------------
# Prepare table structure for RTF output
#------------------------------------------------------------

# Rename columns explicitly for final display order
colnames(orr_table_raw) <- c(
  "", 
  "Xanomeline High Dose", 
  "Placebo", 
  "Treatment Comparison"
)

#------------------------------------------------------------
# Section 1: Best Overall Response (counts & percentages only)
#------------------------------------------------------------
 

orr_section_bor <- orr_table_raw %>%
  filter(sec == 1) %>%
  select(txt, `Xanomeline High Dose`, Placebo) %>%
  mutate(
    `Treatment Comparison` = "",
    across(everything(), ~ replace_na(., ""))
  )

# Empty spacer row between BOR and statistics sections
section_separator <- data.frame(txt = "")

#------------------------------------------------------------
# Section 2+: ORR, CI, differences, and p-value
#------------------------------------------------------------

orr_section_stats <- orr_table_raw %>%
  filter(sec >= 2) %>%
  select(txt, `Xanomeline High Dose`, Placebo, val2) %>%
  rename(`Treatment Comparison` = val2) %>%
  mutate(across(everything(), ~ replace_na(., "")))

#------------------------------------------------------------
# Combine all sections for RTF rendering
#------------------------------------------------------------

orr_table_rtf <- bind_rows(
  orr_section_bor,
  section_separator,
  orr_section_stats
)

# First column must be blank for shell-compliant output
colnames(orr_table_rtf)[1] <- ""

#------------------------------------------------------------
# Generate RTF output using r2rtf
#------------------------------------------------------------

orr_table_rtf %>%
  rtf_page(
    orientation = "landscape",
    width = 11,
    height = 8.5
  ) %>%
  rtf_title(
    "Summarize objective response rates",
    text_justification = "c",
    text_font_size = 10
  ) %>%
  rtf_colheader(
    colheader = " | DRUG A | Placebo | Treatment Comparison",
    col_rel_width = c(3.5, 1.5, 1.5, 1.5),
    border_top = c("", "", "", ""),
    border_bottom = c("", "", "", ""),
    border_left = c("", "", "", ""),
    border_right = c("", "", "", "")
  ) %>%
  rtf_colheader(
    colheader = paste0(
      " | (N=", N_high, ") | (N=", N_placebo, ") | "
    ),
    col_rel_width = c(3.5, 1.5, 1.5, 1.5),
    text_font_size = 9,
    text_font = 1,  # Courier New (shell standard)
    border_top = c("", "", "", ""),
    border_bottom = c("", "", "", ""),
    border_left = c("", "", "", ""),
    border_right = c("", "", "", "")
  ) %>%
  rtf_body(
    col_rel_width = c(3.5, 1.5, 1.5, 1.5),
    text_justification = c("l", "c", "c", "c"),
    text_font_size = 9,
    text_font = 1,
    border_top = c("", "", "", ""),
    border_bottom = c("", "", "", ""),
    border_left = c("", "", "", ""),
    border_right = c("", "", "", "")
  ) %>%
  rtf_encode() %>%
  write_rtf(
    "//Novotech.com.au/files/Data_management/02-Data Management/SAS_Trainee/Trainings/Trainees/Vishwa/SRR/output/summary_ORR.rtf"
  )

