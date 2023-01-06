# filter_ethnic_born_mexicans.R
#
# What this file does:
#
#  - Filter rows of ACS to keep ethnically hispanic
#    respondants who are born in mexico

# --- Libraries ---#
library(vroom)
library(dplyr)
library(assertr)

#--- Command Line Args Unpacking ---# 
args <- commandArgs(trailingOnly = TRUE)

in_file  <- args[1]
out_file <- args[2]

# --- Load Data --- #
df <- 
    vroom(in_file,
          .name_repair = ~ janitor::make_clean_names(., case = "snake")
    )

# --- Select Born in Mexico and Hispanic --- #
# born in mexico, then filter them if also hispanic
df_mex_his <- 
    df %>%
    mutate(
        born_in_mexico = if_else(bpl == 200, TRUE, FALSE)
    ) %>%
    filter(born_in_mexico == TRUE, hispan == 1)

# --- Assert Filters Correct --- #
# will return 10 rows if assertions pass,
df_mex_his %>%
    verify(born_in_mexico == TRUE) %>%
    verify(hispan == 1) %>%
    head()

# --- Write Filtered File ---# 
vroom_write(df_mex_his, out_file)