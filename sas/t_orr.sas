
/*------------------------------------------------------------
 Program: t_orr.sas
 Purpose: Oncology Objective Response Rate (ORR) Efficacy Table
 Inputs : ADSL, ADRS (ADaM)
------------------------------------------------------------*/

/*------------------------------------------------------------
 Import analysis datasets
------------------------------------------------------------*/
libname adam "&path.";

/*------------------------------------------------------------
 Derive analysis population and Big N
------------------------------------------------------------*/
data adsl_ana;
    set adam.adsl;
    where TRT01P not in ( "Screen Failure" "Xanomeline Low Dose");
run;

proc sql;
    create table bigN as
    select
        TRT01P,
        count(distinct USUBJID) as N
    from adsl_ana
    group by TRT01P
    order by TRT01P;
quit;

/*------------------------------------------------------------
 Prepare BOR records
------------------------------------------------------------*/
data adrs_bor;
    set adam.adrs;
    where PARAMCD = "BOR"
          and RSORRES in ("CR","PR","SD","PD");
run;

proc sort data=adrs_bor; by TRT01P; run;

/*------------------------------------------------------------
 BOR frequency and percentages
------------------------------------------------------------*/
proc freq data=adrs_bor noprint;
    by TRT01P;
    tables RSORRES / out=bor_freq;
run;

proc sort data=bor_freq; by TRT01P; run;
proc sort data=bigN; by TRT01P; run;

data bor_summary;
    length display $100;
    merge bor_freq(in=a) bigN(in=b);
    by TRT01P;
    if a;

    pct = (count / N) * 100;
    value = cats(put(count, best.), " (", put(pct, 7.2), "%)");

    select (RSORRES);
        when ("CR") do; display="  Complete Response (CR)"; order=1; end;
        when ("PR") do; display="  Partial Response (PR)"; order=2; end;
        when ("SD") do; display="  Stable Disease (SD)";   order=3; end;
        when ("PD") do; display="  Progressive Disease (PD)"; order=4; end;
        otherwise;
    end;

    section = 1;
run;

proc sort data=bor_summary; by section order display; run;

proc transpose data=bor_summary out=bor_table;
    by display section order;
    id TRT01P;
    var value;
run;

/*------------------------------------------------------------
 Objective Response Rate (CR or PR)
------------------------------------------------------------*/
data orr_flag;
    set adrs_bor;
    orr = (RSORRES in ("CR","PR"));
run;

proc freq data=orr_flag noprint;
    by TRT01P;
    tables orr / out=orr_freq(where=(orr=1));
run;

proc sort data=orr_freq; by TRT01P; run;

data orr_summary;
    length display $100;
    merge orr_freq bigN;
    by TRT01P;

    pct = (count / N) * 100;
    value = cats(put(count,best.)," (",put(pct,7.2),"%)");

    display = "Best Objective Response (CR or PR)";
    section = 2;
run;

proc transpose data=orr_summary out=orr_table;
    by display section;
    id TRT01P;
    var value;
run;

/*------------------------------------------------------------
 95% CI for ORR (Clopper–Pearson)
------------------------------------------------------------*/
proc freq data=orr_flag;
    by TRT01P;
    tables orr / binomial(exact);
    ods output BinomialCLs=orr_ci_raw;
run;

data orr_ci;
    length display $100 value $40;
    set orr_ci_raw;
    value = cats(put(LowerCL,7.2),"% - ",put(UpperCL,7.2),"%");
    display = "95% CI for Objective Response Rate";
    section = 3;
run;

proc transpose data=orr_ci out=orr_ci_table;
    by display section;
    id TRT01P;
    var value;
run;

/*------------------------------------------------------------
 Difference in ORR vs Placebo
------------------------------------------------------------*/
proc freq data=orr_flag;
    tables orr*TRT01P / riskdiff(equal var=null);
    ods output RiskDiffCol1=orr_diff_raw;
run;

data orr_diff;
    length display $100 value $40;
    set orr_diff_raw;
    if Row="Difference";
    value = cats(put(Risk,7.4),"%");
    display = "Difference in Objective Response Rate";
    section = 4;
run;

data orr_diff_ci;
    length display $100 value $40;
    set orr_diff_raw;
    if Row="Difference";
    value = cats(put(LowerCL,7.2),"% - ",put(UpperCL,7.2),"%");
    display = "95% CI for Difference in Objective Response Rate";
    section = 5;
run;

/*------------------------------------------------------------
 P-value for treatment comparison
------------------------------------------------------------*/
proc freq data=orr_flag;
    tables TRT01P*orr / chisq;
    ods output ChiSq=chisq_raw;
run;

data pvalue;
    length display $100 value $20;
    set chisq_raw;
    if Statistic="Chi-Square";
    value = put(Prob,7.4);
    display = "P-value";
    section = 6;
run;

/*------------------------------------------------------------
 Final table assembly
------------------------------------------------------------*/
data final_table;
    set
        bor_table
        orr_table
        orr_ci_table
        orr_diff
        orr_diff_ci
        pvalue;
run;

proc sort data=final_table;
    by section;
run;
