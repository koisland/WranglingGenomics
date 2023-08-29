SAMPLES = config["data"]["sample_acc_ids"]
REFS = config["data"]["ref_url"]
READS_DIR = config["data"]["paths"]["reads_dir"]
REF_DIR = config["data"]["paths"]["ref_dir"]


rule download_all:
    input:
        expand(
            os.path.join(READS_DIR, "{sample}-{pair_num}.fastq.gz"),
            sample=SAMPLES.keys(),
            pair_num=[1, 2],
        ),
        expand(os.path.join(REF_DIR, "{genome}.fasta"), genome=REFS.keys()),


# Metadata https://github.com/datacarpentry/wrangling-genomics/blob/main/episodes/files/Ecoli_metadata_composite.csv
rule download_reads:
    output:
        os.path.join(READS_DIR, "{sample}-{pair_num}.fastq.gz"),
    params:
        url=lambda wc: config["data"]["sample_base_url"].format(
            id=SAMPLES[wc.sample], sample=wc.sample, pair_num=wc.pair_num
        ),
    log:
        "logs/data/download_{sample}_{pair_num}.log",
    shell:
        """
        curl -L -o {output} {params.url} &> {log}
        """


rule download_ref_genome:
    output:
        os.path.join(REF_DIR, "{genome}.fasta"),
    params:
        url=lambda wc: REFS[wc.genome],
    log:
        "logs/data/download_{genome}.log",
    shell:
        """
        curl -L -o {output}.gz {params.url} &> {log}
        gunzip {output}.gz
        """
