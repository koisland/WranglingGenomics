import os

OUTPUT_DIR = config["variant_call"]["paths"]["output_dir"]


rule bcftools_mpileup:
    input:
        alignments=rules.bwa_mem.output,
        ref=rules.download_ref_genome.output,
    output:
        pileup=os.path.join(OUTPUT_DIR, "pileups", "{sample}-{genome}.pileup.bcf"),
    params:
        uncompressed_bcf=False,
        extra="--max-depth 100 --min-BQ 15",
    log:
        "logs/bcftools_mpileup/{sample}-{genome}.log",
    wrapper:
        "v2.6.0/bio/bcftools/mpileup"


rule bcftools_call:
    input:
        pileup=os.path.join(OUTPUT_DIR, "pileups", "{sample}-{genome}.pileup.bcf"),
    output:
        calls=os.path.join(OUTPUT_DIR, "call", "{sample}-{genome}.calls.vcf"),
    params:
        uncompressed_bcf=False,
        # Multiallelic and rare-variant calling
        caller="-m",
        # E. coli has haploid genome.
        # Variant sites only.
        extra="--ploidy 1 -v",
    log:
        "logs/bcftools_call/{sample}-{genome}.log",
    wrapper:
        "v2.6.0/bio/bcftools/call"


# perl script to filter is not documented.


rule variant_call_all:
    input:
        expand(
            rules.bcftools_mpileup.output,
            genome=config["data"]["ref_url"].keys(),
            sample=config["data"]["sample_acc_ids"].keys(),
        ),
        expand(
            rules.bcftools_call.output,
            genome=config["data"]["ref_url"].keys(),
            sample=config["data"]["sample_acc_ids"].keys(),
        ),
