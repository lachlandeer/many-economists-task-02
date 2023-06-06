# manyeconomists
#
# researcher_id: 579

# --- Variable Declarations ---# 
runR = "Rscript --no-save --no-restore --verbose"

# For TWFE
FIXEFF        = glob_wildcards("src/model-specs/twfe/twfe_fe_{fname}.json").fname
CTRLS         = glob_wildcards("src/model-specs/twfe/twfe_controls_{fname}.json").fname
#SUBSET_ELIG   = glob_wildcards("src/data-specs/twfe/eligibility_{fname}.json").fname 
#SUBSET_SCHOOL = glob_wildcards("src/data-specs/twfe/school_{fname}.json").fname
SUBSET_YRS    = glob_wildcards("src/data-specs/twfe/years_{fname}.json").fname

# For DiD ala CSA(2021)
DID_CTRLS         = glob_wildcards("src/model-specs/did/model_controls_{fname}.json").fname
DID_ANTIC         = glob_wildcards("src/model-specs/did/model_anticip_{fname}.json").fname
DID_SUBSET_ELIG   = glob_wildcards("src/data-specs/did/eligibility_{fname}.json").fname 
DID_SUBSET_SCHOOL = glob_wildcards("src/data-specs/did/school_{fname}.json").fname

#--- all --- 

rule all: 
    input: 
        did = expand("out/analysis/did/did_antic_{iAntic}_ctrl_{iCtrl}_elig_{iElig}_school_{iSchool}.rds",
                iAntic = DID_ANTIC,
                iCtrl = DID_CTRLS,
                iElig = DID_SUBSET_ELIG,
                iSchool = DID_SUBSET_SCHOOL
                ),
        twfe =  expand("out/analysis/twfe/twfe_fe_{iFE}_ctrl_{iControl}_yr_{iYrs}.rds",
                iFE = FIXEFF,
                iControl = CTRLS,
                #iElig = SUBSET_ELIG,
                iYrs = SUBSET_YRS
                #iSchool = SUBSET_SCHOOL
                )



# ---- MODELLING ---- #

# --- DID ala CSA(2021) ---# 
rule estimate_did:
    input:
        expand("out/analysis/did/did_antic_{iAntic}_ctrl_{iCtrl}_elig_{iElig}_school_{iSchool}.rds",
                iAntic = DID_ANTIC,
                iCtrl = DID_CTRLS,
                iElig = DID_SUBSET_ELIG,
                iSchool = DID_SUBSET_SCHOOL
                )

rule did:
    input: 
        script        = "src/analysis/did_csa.R",
        data          = "out/data/estimation_sample.csv",
        model_base    = "src/model-specs/did/model_base.json",
        model_anticip = "src/model-specs/did/model_anticip_{iAntic}.json",
        model_ctrl    = "src/model-specs/did/model_controls_{iCtrl}.json", 
        subset_elig   = "src/data-specs/did/eligibility_{iElig}.json",
        subset_hs     = "src/data-specs/did/school_{iSchool}.json"
    output:
        model = "out/analysis/did/did_antic_{iAntic}_ctrl_{iCtrl}_elig_{iElig}_school_{iSchool}.rds"
    log:
        "log/analysis/did/did_antic_{iAntic}_ctrl_{iCtrl}_elig_{iElig}_school_{iSchool}.Rout"
    shell: 
        "{runR} {input.script} {input.data} \
            {input.model_base} {input.model_ctrl} {input.model_anticip} \
            {input.subset_elig} {input.subset_hs} \
            {output.model} > {log} 2>&1"

# --- TWFE Models --- # 
rule estimate_twfe:
    input:
        expand("out/analysis/twfe/twfe_fe_{iFE}_ctrl_{iControl}_yr_{iYrs}.rds",
                iFE = FIXEFF,
                iControl = CTRLS,
                #iElig = SUBSET_ELIG,
                iYrs = SUBSET_YRS
                #iSchool = SUBSET_SCHOOL
                )

rule twfe:
    input: 
        script      = "src/analysis/twfe.R",
        data        = "out/data/estimation_sample.csv",
        model_base  = "src/model-specs/twfe/twfe_main.json",
        model_fe    = "src/model-specs/twfe/twfe_fe_{iFE}.json",
        model_ctrl  = "src/model-specs/twfe/twfe_controls_{iControl}.json", 
        #subset_elig = "src/data-specs/twfe/eligibility_{iElig}.json",
        subset_yrs  = "src/data-specs/twfe/years_{iYrs}.json",
        #subset_hs   = "src/data-specs/twfe/school_{iSchool}.json", 
    output:
        model = "out/analysis/twfe/twfe_fe_{iFE}_ctrl_{iControl}_yr_{iYrs}.rds"
    log:
        "log/analysis/twfe/twfe_fe_{iFE}_ctrl_{iControl}_yr_{iYrs}.Rout"
    shell: 
        "{runR} {input.script} {input.data} \
            {input.model_base} {input.model_fe} {input.model_ctrl} \
            {input.subset_yrs} \
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
        data = "src/data/usa_00002.csv.gz",
    output:
        data = "out/data/acs_ethnic_born_mexicans.csv",
    log:
        "log/data-mgt/filter_ethnic_born_mexicans.Rout"
    shell:
        "{runR} {input.script} {input.data} {output.data}  > {log} 2>&1"

# --- Sub Rules --- #
# Include all other Snakefiles that contain rules that are part of the project
include: "renv.smk"

# --- Workflow Viz --- # 
## rulegraph          : create the graph of how rules piece together 
rule rulegraph:
    input:
        "Snakefile"
    output:
        "rulegraph.pdf"
    shell:
        "snakemake --rulegraph | dot -Tpdf > {output}"

## rulegraph_to_png
rule rulegraph_to_png:
    input:
        "rulegraph.pdf"
    output:
        "rulegraph.png"
    shell:
        "pdftoppm -png {input} > {output}"

## dag                : create the DAG as a pdf from the Snakefile
rule dag:
    input:
        "Snakefile"
    output:
        "dag.pdf"
    shell:
        "snakemake --dag | dot -Tpdf > {output}"
