# did_csa.R
#
# What this file does:
#


# --- Libraries ---#
library(vroom)
library(dplyr)
library(did)
library(rjson)
library(readr)

# --- Command Line Unpacking --- # 
args <- commandArgs(trailingOnly = TRUE)

in_data        <- args[1]
model_base     <- args[2]
model_controls <- args[3]
model_anticip  <- args[4]
data_elig      <- args[5]
data_hs        <- args[6]
out_file       <- args[7]

# --- Load Data --- # 
message("Loading Data")
df <- vroom(in_data) 

# --- Load Model --- #
message("Loading Regression Model")
base     <- fromJSON(file = model_base) 
controls <- fromJSON(file = model_controls)
anticip  <- fromJSON(file = model_anticip) 

# --- Load Data Filters --- #
message("Loading Data Filters")

elig   <- fromJSON(file = data_elig)
schl   <- fromJSON(file = data_hs)

# --- Data Filtering --- #
message("We are Starting with ", nrow(df), " rows of data")
message("Here are the Data Filtering Criteria:")

# eligibility
print("Eligibility:")
print(elig$KEEP_CONDITION)

# Filter on Eligibility if needed
if (!setequal(elig$KEEP_CONDITION, "NULL")) {
  df <- subset(df, eval(parse(text = elig$KEEP_CONDITION)))
}
print("Rows Remaining:")
print(nrow(df))

# School
print("Schooling:")
print(schl$KEEP_CONDITION)

# Filter on Schooling if needed
if (!setequal(schl$KEEP_CONDITION, "NULL")) {
  df <- subset(df, eval(parse(text = schl$KEEP_CONDITION)))
}
print("Rows Remaining:")
print(nrow(df))


# --- Estimation --- #
message("Running Callaway & Sant'Anna's DiD Strategy")
# reformat data for did package structure
df <-
    df %>%
    tibble::rownames_to_column() %>%
    mutate(daca_eligible = as.numeric(daca_eligible),
           rowname = as.numeric(rowname),
           after_2013 = as.numeric(after_2013),
           after = 2013 * daca_eligible
           )

# run the model
out_model <-
    att_gt(
        yname = base$DEPVAR,
        tname = base$T,
        idname = base$UNITID,
        gname = base$AFTER,
        data = df ,
        panel = FALSE, 
        xformla = as.formula(controls$VARS), 
        anticipation = as.numeric(anticip$ANTICIP)
    )

message("Model Output:")
summary(out_model)

message("Simple ATT")
aggte(out_model, type = "simple", na.rm = TRUE)
message("Dynamic ATT")
aggte(out_model, type = "dynamic", na.rm = TRUE)
message("Calendar Time ATT")
aggte(out_model, type = "calendar", na.rm = TRUE)

# # --- Export Model --- # 
write_rds(out_model, out_file)