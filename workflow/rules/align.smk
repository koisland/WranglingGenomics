import os

REF_DIR = config["data"]["paths"]["ref_dir"]
OUTPUT_DIR = config["align"]["paths"]["output_dir"]


# Index the reference genome.
rule bwa_index:
    input:
        rules.download_ref_genome.output,
    output:
        idx=multiext(
            os.path.join(OUTPUT_DIR, "{genome}"),
            ".amb",
            ".ann",
            ".bwt",
            ".pac",
            ".sa",
        ),
    log:
        "logs/bwa_index/{genome}.log",
    params:
        algorithm="bwtsw",
    wrapper:
        "v2.6.0/bio/bwa/index"


# Align reads to reference and sort by chr coord.
rule bwa_mem:
    input:
        reads=[rules.trimmomatic.output.r1, rules.trimmomatic.output.r2],
        idx=rules.bwa_index.output,
    output:
        os.path.join(OUTPUT_DIR, "{sample}-{genome}.bam"),
    log:
        "logs/bwa_mem/{sample}-{genome}.log",
    params:
        extra=r"-R '@RG\tID:{sample}\tSM:{sample}'",
        sorting=config["align"]["sorting"],  # Can be 'none', 'samtools' or 'picard'.
        sort_order="coordinate",  # Can be 'queryname' or 'coordinate'.
        sort_extra="",  # Extra args for samtools/picard.
    threads: 8
    wrapper:
        "v2.6.0/bio/bwa/mem"


rule align_all:
    input:
        expand(rules.bwa_index.output, genome=config["data"]["ref_url"].keys()),
        expand(
            rules.bwa_mem.output,
            genome=config["data"]["ref_url"].keys(),
            sample=config["data"]["sample_acc_ids"].keys(),
        ),
