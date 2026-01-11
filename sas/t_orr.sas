/*******************************************************************************
 * Program: best_overall_response_analysis.sas
 * Purpose: Analyze Best Overall Response (BOR) and Objective Response Rate (ORR)
 * Inputs:  ADAM.ADSL, ADAM.ADRS
 * Outputs: fin1 (final analysis dataset)
 ******************************************************************************/

/* Set library reference */
libname adam "&path.";

/*-----------------------------------------------------------------------------
 * SECTION 1: Calculate treatment group denominators (Big N)
 *---------------------------------------------------------------------------*/
proc sql;
    /* Get counts for each treatment group */
    select count(distinct USUBJID) into :N1-:N3 
    from adam.adsl(where=(TRT01P ne "Screen Failure"))
    group by TRT01P
    order by TRT01P;
    
    /* Create denominator dataset */
    create table bign as 
    select count(distinct USUBJID) as bign, TRT01P  
    from adam.adsl(where=(TRT01P ne "Screen Failure"))
    group by TRT01P
    order by TRT01P;
quit;

%put Treatment Group Ns: &N1 &N2 &N3;

/*-----------------------------------------------------------------------------
 * SECTION 2: Best Overall Response Categories (CR, PR, SD, PD)
 *---------------------------------------------------------------------------*/

/* Filter to BOR parameter and relevant response categories */
data bor_responses;
    set adam.adrs;
    where RSORRES in ("CR" "PR" "SD" "PD") and PARAMCD = "BOR";
run;

/* Get frequency counts by treatment and response */
proc sort data=bor_responses; 
    by TRT01P;
run;

proc freq data=bor_responses noprint;
    table RSORRES / out=bor_freq;
    by TRT01P;
run;

/* Merge with denominators and calculate percentages */
proc sort data=bign; by TRT01P; run;
proc sort data=bor_freq; by TRT01P; run;

data bor_summary;
    length RSORRES_ $100.;
    merge bign(in=a) bor_freq(in=b);
    by TRT01P;
    if b;
    
    /* Format as n(%) */
    val = put(COUNT, best.) || "(" || strip(put((COUNT/bign)*100, 7.2)) || "%)";
    
    /* Assign display labels and sort order */
    select (RSORRES);
        when ("CR") do;
            RSORRES_ = "	Complete Response (CR)";
            subsec = 1;
        end;
        when ("PR") do;
            RSORRES_ = "	Partial Response (PR)";
            subsec = 2;
        end;
        when ("SD") do;
            RSORRES_ = "	Stable Disease (SD)";
            subsec = 3;
        end;
        when ("PD") do;
            RSORRES_ = "	Progressive Disease (PD)";
            subsec = 4;
        end;
    end;
    sec = 1;
run;

/* Transpose to wide format */
proc sort data=bor_summary; 
    by RSORRES_ sec subsec;
run;

proc transpose data=bor_summary out=bor_transposed;
    var val;
    by RSORRES_ sec subsec;
    id TRT01P;
run;

/* Add header row and fill missing values */
data bor_header;
    length RSORRES_ $100.;
    RSORRES_ = "Best Overall Response";
    subsec = 0;
run;

data bor_final;
    set bor_header bor_transposed;
    
    /* Replace missing with 0 for display */
    if subsec > 0 then do;
        if missing(Placebo) then Placebo = "0";
        if missing("Xanomeline High Dose"n) then "Xanomeline High Dose"n = "0";
        if missing("Xanomeline Low Dose"n) then "Xanomeline Low Dose"n = "0";
    end;
run;

/*-----------------------------------------------------------------------------
 * SECTION 3: Best Objective Response (CR or PR)
 *---------------------------------------------------------------------------*/

/* Create binary indicator for objective response */
data orr_data;
    set adam.adrs;
    where RSORRES ne "" and PARAMCD = "BOR";
    
    if RSORRES in ("CR" "PR") then obj = 0;  /* Response */
    else if RSORRES ne "" then obj = 1;      /* Non-response */
run;

proc sort data=orr_data; 
    by TRT01P;
run;

/* Count objective responses by treatment */
proc freq data=orr_data noprint;
    by TRT01P;
    tables obj / out=orr_freq(drop=percent where=(obj=0));
run;

/* Calculate ORR with percentages */
proc sort data=bign; by TRT01P; run;
proc sort data=orr_freq; by TRT01P; run;

data orr_summary;
    length RSORRES_ $100.;
    merge bign(in=a) orr_freq(in=b);
    by TRT01P;
    if b;
    
    val = put(COUNT, best.) || "(" || strip(put((COUNT/bign)*100, 7.2)) || "%)";
    RSORRES_ = "Best Objective Response (CR or PR)";
    subsec = 1;
    sec = 2;
run;

proc sort data=orr_summary; 
    by RSORRES_ sec subsec;
run;

proc transpose data=orr_summary out=orr_transposed;
    var val;
    by RSORRES_ sec subsec;
    id TRT01P;
run;

/*-----------------------------------------------------------------------------
 * SECTION 4: 95% CI for ORR (Clopper-Pearson)
 *---------------------------------------------------------------------------*/

proc freq data=orr_data;
    by TRT01P;
    table obj / binomial(exact);
    ods output binomialcls=orr_ci;
run;

data orr_ci_formatted;
    length RSORRES_ $100.;
    set orr_ci;
    
    ci = put(LowerCL, 7.2) || "%  -" || put(UpperCL, 7.2) || "%";
    RSORRES_ = "95% CI for Objective Response Rate ";
    sec = 3;
run;

proc sort data=orr_ci_formatted; 
    by RSORRES_ sec;
run;

proc transpose data=orr_ci_formatted out=orr_ci_transposed;
    var ci;
    id TRT01P;
    by RSORRES_ sec;
run;

/*-----------------------------------------------------------------------------
 * SECTION 5: Treatment Comparison Statistics
 *---------------------------------------------------------------------------*/

/* Calculate risk difference and 95% CI */
proc freq data=orr_data;
    tables obj*TRT01P / exact riskdiff(equal var=null);
    ods output RiskDiffCol1=risk_diff;
run;

/* Format risk difference */
data risk_diff_point;
    length tt $100.;
    set risk_diff;
    where Row = "Difference";
    
    tt = put(Risk, 7.4) || "%";
    RSORRES_ = " Difference in Objective Response Rate ";
    sec = 4;
run;

/* Format confidence interval for difference */
data risk_diff_ci;
    length tt $100.;
    set risk_diff;
    where Row = "Difference";
    
    tt = put(LowerCL, 7.2) || "%  -" || put(UpperCL, 7.2) || "%";
    RSORRES_ = "  95% CI for Difference in Objective Response Rate ";
    sec = 5;
run;

/* Chi-square test for treatment comparison */
proc freq data=orr_data;
    table TRT01P*obj / chisq;
    ods output ChiSq=chisq_test;
run;

data pvalue;
    set chisq_test;
    where Statistic = "Chi-Square";
    
    tt = put(Prob, 7.4);
    RSORRES_ = "  P-value";
    sec = 6;
run;

/*-----------------------------------------------------------------------------
 * SECTION 6: Combine All Results
 *---------------------------------------------------------------------------*/

data fin1;
    set bor_final 
        orr_transposed 
        orr_ci_transposed 
        risk_diff_point 
        risk_diff_ci 
        pvalue;
    keep RSORRES_ tt "Xanomeline High Dose"n Placebo sec subsec;
run;

proc sort data=fin1; 
    by sec subsec;
run;

/* Clean up temporary datasets */
proc datasets library=work nolist;
    delete bor_: orr_: risk_diff: chisq_test pvalue bign;
quit;
