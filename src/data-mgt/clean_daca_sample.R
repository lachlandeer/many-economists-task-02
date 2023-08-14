# clean_daca_sample.R
#
# What this file does:
#
#  - Keeps non-citizens
#  - Generates Indicators for daca rules
#  - Generates flag for if daca eligible based on rules:
#       -  Entered before 16th birthday 
#       - Had not yet had their 31st birthday as of June 15, 2012
#       - Lived continuously in the US since June 15, 2007  
#       -  Were present in the US on June 15, 2012 and did not have lawful status
#          lawful status filtered on previously with citizen 
#          present on this date if immigrated on or before 2012
#       - Completed at least high school (12th grade) OR are a veteran of the military
#  - Generates cleaned up control variables 
#  - Filters individual such that age is between 26 and 35 in June 2012
#  - Creates treatment and control groups based on daca eligible and age criteria 


# --- Libraries ---#
library(vroom)
library(dplyr)
library(lubridate)

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

# Rule 5:  Completed at least high school (12th grade) OR are a veteran of the military
df <- 
    df %>%
    mutate(finished_hs = if_else(educ > 6, TRUE, FALSE),
           is_veteran = if_else(vetstat ==2, TRUE, FALSE)
           # finish_school_or_veteran = case_when(
              # finished_hs == TRUE | is_veteran == TRUE ~ TRUE,
              # TRUE ~ FALSE
           # )
    )

# DACA ELIGIBLE
df <- 
    df %>%
    mutate(daca_eligible = case_when(
        enter_under_16 == TRUE & 
            under_31 == TRUE &
            lived_usa_2006 == TRUE &
            present_2012 == TRUE  &
            # finish_school_or_veteran == TRUE ~ TRUE,
            (finished_hs == TRUE | is_veteran == TRUE) ~ TRUE,
        # else false
        TRUE ~ FALSE
    )
    ) %>%
    mutate(daca_eligible_no_age = case_when(
        enter_under_16 == TRUE & 
            #under_31 == TRUE &
            lived_usa_2006 == TRUE &
            present_2012 == TRUE  &
            # finish_school_or_veteran == TRUE ~ TRUE,
            (finished_hs == TRUE | is_veteran == TRUE) ~ TRUE,
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
# df %>% filter(statefip <= 56) %>% nrow()

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
# i.e. need people to be aged between 26 and 35 on date DACA goes into place

sample_upper <- ceiling_date(ymd("2012-06-15"), "quarters") - years(35)
sample_lower <- ceiling_date(ymd("2012-06-15"), "quarters") - years(26)


df_filtered <-
    df %>%
    filter(between(quarter_of_birth, sample_upper, sample_lower))

#nrow(df_filtered)

# --- Construct Treatment and Control groups --- # 
df_filtered <- 
    df_filtered %>%
    mutate(
        treatment = case_when(
            (daca_eligible == TRUE & under_31 ==TRUE) ~ "TRUE",
            (daca_eligible_no_age == TRUE & under_31 ==FALSE) ~ "FALSE",
            TRUE ~ "NA"
        )
    ) %>%
    filter(treatment != "NA")

df_filtered %>%
    group_by(treatment, under_31) %>%
    count()


# --- Save Data --- # 
vroom_write(df_filtered, out_file, ",")
