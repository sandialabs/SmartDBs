# SmartDBs

## About
TIGER is a comparative genomics program for finding mobile genetic elements in a query genome. It requires a reference genome database appropriate for the query genome. The set of SMART DBs whose production is facilitated here are tailored for each species, yet redundant such that 3680 DBs cover all 65703 species of GTDB release 207. This pipeline has two modes, either a full update mode that freshly designs and prepares all DBs needed to cover all species in any new GTDB release, or a quick setup mode where the user chooses a subset of DBs to prepare from a precalculated DB design file. It collects required fasta files from NCBI and produces the chosen SMART DBs. These databases are smaller than those we used before, greatly speeding TIGER.

## Citation
Yu SL, Mageeney CM, Shormin F, Ghaffari N, Williams KP. 2023. Speeding genomic island discovery through systematic design of reference database composition, in preparation.

## Installation
```
git clone https://github.com/sandialabs/SmartDBs.git
```

## Dependencies

### Mash
This program requires the installation of MASH v2.0 or greater. Mash can be downloaded from: https://github.com/marbl/Mash/releases.

### Perl
This program is written Perl. Please have the latest version of Perl installed, found here: https://www.perl.org/get.html

### GTDB Data
This a dependency for full update mode, but not for quick setup mode.

Download the following files from the latest gtdb release (in this example, release 207) into a single folder. This folder should not mix files from multiple releases:
 from the outer GTDB release folder:
  1. ar53_metadata_r207.tar.gz
  2. bac120_metadata_r207.tar.gz
 and from the auxillary_files subfolder:
  3. ar53_r207.sp_labels.tree
  4. bac120.sp_labels.tree
  5. sp_clusters_r207.tsv

Untar the metadata files. The program will automatically delete the .tar.gz; check this, as these files would interfere with how the program runs.

Please also have these packages installed as well:
 * Perl Core: List::Util, File::Spec, Cwd, Getopt::Long
 * Perl Noncore: Parallel::ForkManager

## Suggested Set Up

```
smartdbs
|
|__bin (our scripts)
|
|__gb (auto-filled storage of genome fasta files and mash files)
|
|__gtdb (subfolders for each release, each containing 5 required files, if using full update mode)
|
|__update202 (user-setup, with config file, and smartsUniq500, gnms.txt files for quick-setup mode (see below))
|
|__update207 (user-setup for new update)
```

## Running

### Config files
In order to run either mode of the program, a config file must be created in the same directory you are running the code. The format of the configuration file is line-separated KEY=VALUE pairs. The first four keys are required; others are optional if default values are acceptable:

```
GENOME_DIR=Path to where the genome assemblies are to be stored
GTDB_DIR=Path to folder with gtdb data OR 'none'
SOFTWARE_DIR=Path to where the software is installed
DB_DIR=Path to where the SmartDBs will be stored
DB_SIZE=Size of the database; default 500
PREV_GNMS=Path to an old gnms.txt file; default 'none'
CORES=Maximum number of cores allowed; default 1
QUICK_SETUP=Determine if in Quick Setup mode; 'no' or 'yes'; default 'no' 
SPECIES=Determine which species to include in Quick Setup Mode; 'all' or specific; default 'all'
    *See Quick Setup below
BUILD=Determine whether or not to build DBs; 'yes' or 'no'; default no
OFFSPECIES=Percent of DB reserved for genome outside the species; default 0
TOP_ORDER=Top rank the DB searches for closely related genomes; 'o', 'c', 'f', or 'g'; default 'o'
```

### Manual Downloads
In some cases, the record of the GCA may be unavailable from the FTP server. If so, our software stops to allow manual download of such files from the NCBI website: look at the legacy page, access the GenBank page and download the data as a fasta file. For the gtdb207 update, only one manual download was required, for GCA_905332505: Fenollaria sporofastidiosus EMRHCC_24, found at: https://www.ncbi.nlm.nih.gov/nuccore/HG994861.1?report=fasta. Rerunning the program will automatically skip to this step and check which files were downloaded. If any were not, it will remove the GCA from the list and proceed without it.

### Full Update
This mode requires download of 5 GTDB files (see above) and the default value of the QUICK_SETUP config key: "no". This version of the program will download all necessary assemblies from the NCBI server and design and prepare the SMART DBs from scratch. Here are some sample config files.

#### Full Update, First Time Use
```
GENOME_DIR=../gb
SOFTWARE_DIR=../bin
DB_DIR=../dbs/202o300
GTDB_DIR=../gtdb
DB_SIZE=300
PREV_GNMS=none
CORES=128
QUICK_SETUP=no
SPECIES=all
BUILD=yes
OFFSPECIES=0
TOP_ORDER=o
```

#### Full Update, after a previous run for an earlier GTDB release (note OLDGNMSTXT)
```
GENOME_DIR=../gb
SOFTWARE_DIR=../bin
DB_DIR=../dbs/202o300
GTDB_DIR=../gtdb
DB_SIZE=300
PREV_GNMS=../update202/gnms.txt
CORES=128
QUICK_SETUP=no
SPECIES=all
BUILD=yes
OFFSPECIES=0
TOP_ORDER=o
```

### Quick Setup
This mode requires download of the smartsUniq file for the desired DB size, and the reflist.txt and gnms.txt files from our github repository in the folder "files". The SPECIES config file value can be "all" (to make the full set of DBs) or a comma-separated list of only the desired SMART DBs. This mode will only download the assemblies named in the precalculated databases, and skip any calculations. Note: Over the course of this program, gnms.txt and reflist.txt will be changed to only include the files that were downloaded and reflect the user's file system.

#### Quick Setup of full DB set
```
GENOME_DIR=../gb
SOFTWARE_DIR=../bin
DB_DIR=../dbs/202o500
GTDB_DIR=none
DB_SIZE=500
PREV_GNMS=none
CORES=128
QUICK_SETUP=yes
SPECIES=all
BUILD=yes
OFFSPECIES=0
TOP_ORDER=o
```
#### Quick Setup for limited number of DBs
```
GENOME_DIR=../gb
SOFTWARE_DIR=../bin
DB_DIR=../dbs/202o500
GTDB_DIR=none
DB_SIZE=500
PREV_GNMS=none
CORES=128
QUICK_SETUP=yes
SPECIES=Magnetobacterium__casensis,Quinella__sp905236255
BUILD=yes
OFFSPECIES=0
TOP_ORDER=o
```
## Notes
### RSYNC
If the rsync jobs are not working, please check if you have the environment variable RSYNC_PROXY set to the same proxy as HTTP_PROXY. In some systems, this variable is not defined, but causing rsync to fail with the errors:
```
rsync: failed to connect to ftp.ncbi.nlm.nih.gov (130.14.250.13): Connection timed out (110)
rsync: failed to connect to ftp.ncbi.nlm.nih.gov (130.14.250.11): Connection timed out (110)
rsync: failed to connect to ftp.ncbi.nlm.nih.gov (2607:f220:41e:250::11): Network is unreachable (101)
rsync: failed to connect to ftp.ncbi.nlm.nih.gov (2607:f220:41f:250::230): Network is unreachable (101)
rsync error: error in socket IO (code 10) at clientserver.c(125) [Receiver=3.1.2]
```
### Deprecated GCAs in Full Update Mode
When running full update mode from a previous version, there are cases where a GCA is present in the previous version, but no longer the newest update. The program will not add such cases to the new gnms.txt, but they will be noted in "notinnewrelease.txt".

### Skipped Commands
Please note that certain commands will be skipped when the product file is already present. There is a warning in the log file if the command is skipped. The files that trigger skipping are detailed below:
```
toget: neededgnms.txt
jobsrsync: always runs
gencode: genetic_code_odd
newgnms: notinnewrelease.txt
links: always runs
sketch: always runs
gnmlists: the folder list
mash: the folder msh
treeparse: nodelists
catorders: orders/orders.txt
dbdesign: the corresponding smartsUniq file
makedbs: always runs if BUILD is yes
repdb: reps.msh
```
### The "Speciate" Utility Script
Speciate.pl is not strictly part of the SMART DBs pipeline, but is useful when studying a new genome. It quickly applies GTDB criteria for determining the species, in preparation for programs like TIGER. 


