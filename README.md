# Wrangling Genomics
Based on https://datacarpentry.org/wrangling-genomics/01-background.html.


## Usage
```bash
# Download files.
snakemake --configfile config/config.yaml -c1 -np -U extract_data
# Then run.
snakemake --configfile config/config.yaml --use-conda -c 1 -np
```
