#!/bin/bash

##  activate the environment for this downstream analysis
eval "$(conda shell.bash hook)";
conda activate NGS-emu;

workdir="$PWD";

## last edit: 2024-04-04
## added combine reports

ls "$FASTA"/*.fa > emu-fasta.lst;

# create output directories
mkdir -p logs;
mkdir -p 00b_analysis_metadata;
mkdir -p 04b_emu_abundance_reports;

FILE=emu-fasta.lst;

DBpath=/mnt/lely_DB/EMU_DB_march2024/;
NODES=24;
METRICS=00b_analysis_metadata/readCountMetrics.tsv;
FASTA=03a_fasta_trim_reads;
OUTDIR=04a_emu-out;
REPORTS=04b_emu_abundance_reports;

# create run meta data file
echo -e "No.\tsampleName\tassignedReads\tunAssignedReads\tPercentage" > "$METRICS";

count0=1
countF=$(cat "$FILE" | wc -l);

while [ $count0 -le $countF ];do

	FILEin=$(cat "$FILE" | awk 'NR=='$count0 );

short=$(basename $FILEin .$extension); 

echo "$short";
echo "$FILEin";
LOG=logs/"$short".emu.log;

# emu analysis
	emu abundance --type map-ont --db "$DBpath" --K 16000 --N 50 --threads "$NODES" --output-dir "$OUTDIR" --keep-counts --output-basename "$short" "$FILEin" > "$LOG" 2>&1;

# parse log file & append data to a metrics table

ASSIGNED=$(cat "$LOG" | grep "Assigned read count:" | cut -f2 -d':');
UNASSIGNED=$(cat "$LOG" | grep "Unassigned read count:" | cut -f2 -d':');
READS=$((ASSIGNED+UNASSIGNED));
PERC=$((READS*100/TOTAL));

echo -e "$count0\t$short\t$ASSIGNED\t$UNASSIGNED\t$READS\t$PERC" >> "$METRICS";

count0=$((count0+1));

done


# copy specific files to new directory for combine outputs into 1 file for downstream processing
cp "$OUTDIR"/*_rel-abundance.tsv "$REPORTS";


# construct 2 output files [combined abundance and combined count table]
emu combine-outputs --split-tables --counts "$REPORTS"/ tax_id;


exit 1


##### emu
#
#usage: emu [-h] [--version]
#           {abundance,build-database,collapse-taxonomy,combine-outputs} ...
#
#positional arguments:
#  {abundance,build-database,collapse-taxonomy,combine-outputs}
#                        sub-commands
#    abundance           Generate relative abundance estimates
#    build-database      Build custom Emu database
#    collapse-taxonomy   Collapse emu output at specified taxonomic rank
#    combine-outputs     Combine Emu rel abundance outputs to a single table
#
#optional arguments:
#  -h, --help            show this help message and exit
#  --version, -v         show program's version number and exit
#
#####

##### emu abundance
#
#usage: emu abundance [-h] [--type {map-ont,map-pb,sr}]
#                     [--min-abundance MIN_ABUNDANCE] [--db DB] [--N N] [--K K]
#                     [--output-dir OUTPUT_DIR]
#                     [--output-basename OUTPUT_BASENAME] [--keep-files]
#                     [--keep-counts] [--keep-read-assignments]
#                     [--output-unclassified] [--threads THREADS]
#                     input_file [input_file ...]
#
#####

##### emu combine-outputs 
#
#usage: emu combine-outputs [-h] [--split-tables] [--counts] dir_path rank
#
#positional arguments:
#  dir_path        path to directory containing Emu output files
#  rank            taxonomic rank to include in combined table [tax_id, species, genus, family, order, class, phylum, superkingdom]
#
#optional arguments:
#  -h, --help      show this help message and exit
#  --split-tables  two output tables:abundances and taxonomy lineages
#  --counts        counts rather than abundances in output table
#
#####





