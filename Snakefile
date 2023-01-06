# manyeconomists
#
# @lachlandeer

# --- Data Cleaning --- # 

rule filter_ethnic_mex:
    input:
        script = "src/data-mgt/filter_ethnic_born_mexicans.R",
        data = "src/data/usa_00001.csv.gz",
    output:
        data = "out/data/acs_ethnic_born_mexicans.csv",
    log:
        "log/data-mgt/filter_ethnic_born_mexicans.Rout"
    script:
        "Rscript {input.script} {input.data} {output.data}  > {log} 2>&1"
