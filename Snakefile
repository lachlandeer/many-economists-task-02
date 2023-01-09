# manyeconomists
#
# @lachlandeer

# --- Variable Declarations ---# 
runR = "Rscript --no-save --no-restore --verbose"

# --- TWFE Models --- # 

rule twfe:
    input: 
        script      = "src/analysis/twfe.R",
        data        = "out/data/estimation_sample.csv",
        model_base  = "src/model-specs/twfe/twfe_main.json",
        model_fe    = "src/model-specs/twfe/twfe_fe_simple.json",
        model_ctrl  = "src/model-specs/twfe/twfe_controls_none.json", 
        subset_elig = "src/data-specs/twfe/eligibility_age_enter.json",
        subset_yrs  = "src/data-specs/twfe/years_all.json",
        subset_hs   = "src/data-specs/twfe/school_all.json", 
    output:
        model = "out/analysis/twfe_testing.Rda",
    log:
        "log/analysis/twfe_testing.Rda"
    shell: 
        "{runR} {input.script} {input.data} \
            {input.model_base} {input.model_fe} {input.model_ctrl} \
            {input.subset_elig} {input.subset_yrs} {input.subset_hs} \
            {output.model} > {log} 2>&1"

# --- Data Cleaning --- # 

rule clean_estimation_sample:
    input: 
        script = "src/data-mgt/clean_daca_sample.R",
        data = "out/data/acs_ethnic_born_mexicans.csv",
    output:
        data = "out/data/estimation_sample.csv",
    log:
        "log/data-mgt/clean_daca_sample.Rout"
    shell:
        "{runR} {input.script} {input.data} {output.data}  > {log} 2>&1"

rule filter_ethnic_mex:
    input:
        script = "src/data-mgt/filter_ethnic_born_mexicans.R",
        data = "src/data/usa_00001.csv.gz",
    output:
        data = "out/data/acs_ethnic_born_mexicans.csv",
    log:
        "log/data-mgt/filter_ethnic_born_mexicans.Rout"
    shell:
        "{runR} {input.script} {input.data} {output.data}  > {log} 2>&1"

# --- Sub Rules --- #
# Include all other Snakefiles that contain rules that are part of the project
include: "renv.smk"

