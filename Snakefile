# manyeconomists
#
# @lachlandeer

# --- Variable Declarations ---# 
runR = "Rscript --no-save --no-restore --verbose"

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

