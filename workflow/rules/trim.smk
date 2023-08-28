import os

INPUT_READS_DIR = config["data"]["paths"]["reads_dir"]
OUTPUT_DIR = os.path.join(config["qc"]["paths"]["output_dir"], "trimmed")
SAMPLES = config["data"]["sample_acc_ids"]


rule download_adapters:
    output:
        os.path.join(OUTPUT_DIR, "NexteraPE-PE.fa"),
    params:
        url="https://raw.githubusercontent.com/timflutre/trimmomatic/master/adapters/NexteraPE-PE.fa",
    log:
        "logs/trimmomatic/download_adapters.log",
    shell:
        """
        curl -o {output} {params.url}
        """


# Note: The input for the tutorial doesn't included untrimmed reads.
rule trimmomatic:
    """
    params:
        trimmer:
            Window of size 4 that will remove bases if their phred score is below 20.
            We will also discard any reads that do not have at least 25 bases remaining after this trimming step.
            ILLUMINACLIP, three additional numbers tell Trimmimatic how to handle sequence matches to the Nextera adapters
    """
    input:
        r1=os.path.join(INPUT_READS_DIR, "{sample}-1.fastq.gz"),
        r2=os.path.join(INPUT_READS_DIR, "{sample}-2.fastq.gz"),
        adapters=rules.download_adapters.output,
    output:
        r1=os.path.join(OUTPUT_DIR, "{sample}-1.fastq.gz"),
        r2=os.path.join(OUTPUT_DIR, "{sample}-2.fastq.gz"),
        # reads where trimming entirely removed the mate
        r1_unpaired=os.path.join(OUTPUT_DIR, "{sample}-1.unpaired.fastq.gz"),
        r2_unpaired=os.path.join(OUTPUT_DIR, "{sample}-2.unpaired.fastq.gz"),
    log:
        "logs/trimmomatic/{sample}.log",
    params:
        trimmer=lambda wc, input: [
            "SLIDINGWINDOW:4:20",
            "MINLEN:25",
            f"ILLUMINACLIP:{input.adapters}:2:40:15",
        ],
        # optional parameters
        extra="",
        # optional compression levels from -0 to -9 and -11
        compression_level="-9",
    threads: 4
    # optional specification of memory usage of the JVM that snakemake will respect with global
    # resource restrictions (https://snakemake.readthedocs.io/en/latest/snakefiles/rules.html#resources)
    # and which can be used to request RAM during cluster job submission as `{resources.mem_mb}`:
    # https://snakemake.readthedocs.io/en/latest/executing/cluster.html#job-properties
    resources:
        mem_mb=1024,
    wrapper:
        "v2.6.0/bio/trimmomatic/pe"


# Check the trimmed reads.
use rule fastqc as fastqc_post_trim with:
    input:
        os.path.join(OUTPUT_DIR, "{sample}-{pair_num}.fastq.gz"),
    output:
        html=os.path.join(OUTPUT_DIR, "{sample}-{pair_num}.html"),
        # the suffix _fastqc.zip is necessary for multiqc to find the file. If not using multiqc, you are free to choose an arbitrary filename
        zip=os.path.join(OUTPUT_DIR, "{sample}-{pair_num}_fastqc.zip"),
    log:
        "logs/fastqc/post_trim_{sample}_{pair_num}.log",


use rule join_fastqc_summaries as join_fastqc_post_trim_summaries with:
    input:
        expand(
            rules.fastqc_post_trim.output.zip, sample=SAMPLES.keys(), pair_num=[1, 2]
        ),
    output:
        os.path.join(OUTPUT_DIR, "fastqc_post_trim_summary.txt"),


rule trim_all:
    input:
        expand(rules.trimmomatic.output, sample=SAMPLES.keys()),
        expand(rules.fastqc_post_trim.output, sample=SAMPLES.keys(), pair_num=[1, 2]),
        rules.join_fastqc_post_trim_summaries.output,
