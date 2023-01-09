# twfe.R
#
# What this file does:
#


# --- Libraries ---#
library(vroom)
library(dplyr)
library(fixest)
library(rjson)
library(rlist)

# --- Command Line Unpacking --- # 
args <- commandArgs(trailingOnly = TRUE)

in_data        <- args[1]
model_base     <- args[2]
model_controls <- args[3]
model_fixedeff <- args[4]
data_elig      <- args[5]
data_yrs       <- args[6]
data_hs        <- args[7]
out_file       <- args[8]

# --- Load Data --- # 
message("Loading Data")
df <- vroom(in_data) 

# --- Load Model --- #
message("Loading Regression Model")
base     <- fromJSON(file = model_base) 
controls <- fromJSON(file = model_controls)
fixedeff <- fromJSON(file = model_fixedeff) 

# --- Load Data Filters --- #
message("Loading Data Filters")

elig   <- fromJSON(file = data_elig)
school <- fromJSON(file = data_hs)
yrs    <- fromJSON(file = data_yrs)

# --- Data Filtering --- #
message("Here are the Data Filtering Criteria:")
print("Eligibility:")
print(elig$KEEP_CONDITION)
print("Schooling:")
print(school$KEEP_CONDITION)
print("Years:")
print(yrs$KEEP_CONDITION)

# Filter on Eligibility if needed
if (elig$KEEP_CONDITION != "NULL") {
  df <- subset(df, eval(parse(text = elig$KEEP_CONDITION)))
}
print("Rows Remaining:")
nrow(df)

# Filter on Schooling if needed
if (school$KEEP_CONDITION != "NULL") {
  df <- subset(df, eval(parse(text = school$KEEP_CONDITION)))
}
print("Rows Remaining:")
nrow(df)

# Filter on sample year if needed
if (yrs$KEEP_CONDITION != "NULL") {
  df <- subset(df, eval(parse(text = yrs$KEEP_CONDITION)))
}
print("Rows Remaining:")
nrow(df)

# --- Construct Regression Formula --- # 
# Base Regression Formula
depvar <- base$DEPVAR 
exog   <- base$DID

reg_fmla <- paste(depvar, " ~ ", exog, sep="")

# Fixed Effects
fe <- fixedeff$VARS
reg_fmla <- paste(reg_fmla, " | ", fe, sep = "")

# Controls 
if (controls$VARS != "NULL") {
  ctrls <- controls$VARS
  reg_fmla <- paste(reg_fmla, " + ", ctrls, sep = "")
}

# --- Estimation --- #
message("the regression formula is:")
print(reg_fmla)

out_model <- feols(as.formula(reg_fmla), 
                   data = df
                )

print("Model Output:")
summary(out_model)

# --- Export Model --- # 
list.save(out_model, out_file)
