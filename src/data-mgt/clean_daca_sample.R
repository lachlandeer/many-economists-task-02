# clean_daca_sample.R
#
# What this file does:
#
#  -TBD

# --- Libraries ---#
library(vroom)
library(dplyr)

#--- Command Line Args Unpacking ---# 
args <- commandArgs(trailingOnly = TRUE)

in_file  <- args[1]
out_file <- args[2]

# --- Load Data --- #
df <- vroom(in_file)

# --- Filter: Non-citizens --- #
# DACA eligible must be non citizens, so we filter to keep these
# our control group will also be non-citizens 
df <- 
    df %>%
    # non-citizens coded as a 3 by ACS
    filter(citizen == 3)

# --- DACA Eligibility --- # 
# Rule 1: Entered before 16th birthday 
# (a) compute when entered usa
df <- 
    df %>%
    mutate(age_enter_usa = age - yrsusa1) %>%
    # clean up the negative numbers in what we computed
    mutate(age_enter_usa = case_when(
        age_enter_usa == -1 ~ 0,
        age_enter_usa <  -1 ~ NA_real_, 
        TRUE ~ age_enter_usa
    )
    )

# (b) entered before 16th birthday?
df <-
    df %>%
    mutate(enter_under_16 = if_else(age_enter_usa < 16, TRUE, FALSE))

# Rule 2: Had not yet had their 31st birthday as of June 15, 2012 
threshold_date <- ceiling_date(ymd("2012-06-15"), "quarters") - years(31)

df <-
    df %>%
    mutate(quarter_of_birth = yq(paste(birthyr, birthqtr, sep = " "))) %>%
    mutate(under_31 = if_else(quarter_of_birth > threshold_date, TRUE, FALSE))

# Rule 3: Lived continuously in the US since June 15, 2007  
# use 2006 since in 2007 we don't know when they were interviewed
# assuming once in usa, always stayed in usa
df <- 
    df %>%
    mutate(lived_usa_2006 = ifelse(yrimmig <= 2006, TRUE, FALSE))

# Rule 4: Were present in the US on June 15, 2012 and did not have lawful status
# lawful status filtered on previously with citizen 
# present on this date if immigrated on or before 2012
df <- 
    df %>%
    mutate(present_2012 = ifelse(yrimmig <= 2012, TRUE, FALSE))

# DACA ELIGIBLE
df <- 
    df %>%
    mutate(daca_eligible = case_when(
        enter_under_16 == TRUE & 
            under_31 == TRUE &
            lived_usa_2006 == TRUE &
            present_2012 == TRUE ~ TRUE,
        # else false
        TRUE ~ FALSE
    )
    )

# Add a variable "after_2013" for when daca rules are in place (2013 - onwards)
df <- 
    df %>%
    mutate(after_2013 = if_else(year >= 2013, TRUE, FALSE))

# --- Full Time Work Indicator ---- # 

df <-
    df %>%
    mutate(fulltime_hrs = if_else(uhrswork >= 35, TRUE, FALSE))

# --- CONTROL VARIABLES --- # 
# Q: does everyone come from a state with a fips code?
# A: yes
df %>% filter(statefip <= 56) %>% nrow()

# Married
df <-
    df %>%
    mutate(married = if_else(marst <= 2, TRUE, FALSE))

# home language is Spanish 
df <- 
    df %>%
    mutate(home_lang_es = if_else(language == 12, TRUE, FALSE))


# --- SAMPLE SELECTION CRITERIA --- #
# criteria to be included in an estimation sample ... 
# i.e. we don't think very old or very young people are a good comparison group
# We set various indicators that we can filter on in the regression analysis

df <-
    df %>%
    mutate(
        # aged between 18 and 35
        age_bwtn_18_35 = case_when(
            age >= 18 & age <=35 ~ TRUE,
            TRUE ~ FALSE
        ),
        # entered US between 12 and 19 -- i.e. around the cutoff for DACA
        enter_btwn_12_19 = case_when(
            age_enter_usa >= 12 & age_enter_usa <= 19 ~ TRUE,
            TRUE ~ FALSE
        ),
        # around the age threshold and entered ok, age criterion an issue so we focus on that window
        age_betwn_27_34_enter_ok = case_when(
            age >= 27 & age < 34 & enter_under_16 == TRUE ~ TRUE,
            TRUE ~ FALSE
        ),
        # completed high school (was a criteria actually - but not for this study)
        finished_hs = if_else(educ > 6, TRUE, FALSE)
    )

# --- Save Data --- # 
# only keep if between 18 and 35 ?
df %>%
    mutate(under_18 = if_else(age < 18, TRUE, FALSE)) %>%
    filter(under_18 == FALSE) %>%
    group_by(daca_eligible) %>% 
    count()


df %>% filter(age_bwtn_18_35 == 1) %>% group_by(daca_eligible) %>% count()
# above says that daca elibility among over 18s is the same group ... so for now we
# apply this filter
df_filtered <-
    df %>% 
    filter(age_bwtn_18_35 == 1)

vroom_write(df_filtered, out_file, ",")

