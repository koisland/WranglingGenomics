import os


INPUT_READS_DIR = config["data"]["paths"]["reads_dir"]
OUTPUT_DIR = config["qc"]["paths"]["output_dir"]
SAMPLES = config["data"]["sample_acc_ids"]


rule fastqc:
    input:
        rules.download_reads.output,
    output:
        html=os.path.join(OUTPUT_DIR, "{sample}-{pair_num}.html"),
        # the suffix _fastqc.zip is necessary for multiqc to find the file. If not using multiqc, you are free to choose an arbitrary filename
        zip=os.path.join(OUTPUT_DIR, "{sample}-{pair_num}_fastqc.zip"),
    params:
        extra="--quiet",
    log:
        "logs/fastqc/{sample}_{pair_num}.log",
    threads: 1
    resources:
        mem_mb=1024,
    wrapper:
        "v2.6.0/bio/fastqc"


rule join_fastqc_summaries:
    input:
        expand(rules.fastqc.output.zip, sample=SAMPLES.keys(), pair_num=[1, 2]),
    output:
        os.path.join(OUTPUT_DIR, "fastqc_summary.txt"),
    log:
        "logs/fastqc/join_summaries.log",
    shell:
        """
        for zipfile in {input};
        do
            sample_zip_fname=$(basename "${{zipfile%%.zip}}")
            unzip -p $zipfile "$sample_zip_fname/summary.txt" >> {output} 2> {log}
        done
        """


rule qc_all:
    input:
        expand(rules.fastqc.output, sample=SAMPLES.keys(), pair_num=[1, 2]),
        rules.join_fastqc_summaries.output,
