# SmartDBs

## About
TIGER is a comparative genomics program for finding mobile genetic elements in a query genome. It requires a reference genome database appropriate for the query genome. The smartDBs facilitated here are tailored for each species, yet redundant such that 3680 DBs cover all 65703 species of GTDB release 207. This pipeline has two modes, either a full update mode that freshly designs and prepares all DBs needed to cover all species in any new GTDB release, or a quick setup mode where the user chooses a subset of DBs to prepare from a precalculated DB design file. It collects required fasta files from NCBI and produces the chosen smart databases. These databases are smaller than those we used before, greatly speeding TIGER.

## Citation
Shormin F, Ghaffari N, Yu SL, Mageeney CM, Williams KP. 2022. Speeding genomic island discovery through systematic design of reference database composition, in preparation.

## Installation
```
git clone https://github.com/sandialabs/SmartDBs.git
```

## Dependencies

### GTDB Data
This a dependency for full update mode, and recommended (but not required) for quick setup mode.

Download the following files from the latest gtdb release (in this example, release 207) into a single folder. This folder should not mix files from multiple releases:
 from the outer GTDB release folder:
  1. ar53_metadata_r207.tar.gz
  2. bac120_metadata_r207.tar.gz
 from the auxillary_files subfolder:
  3. ar53_r207.sp_labels.tree
  4. bac120.sp_labels.tree
  5. sp_clusters_r207.tsv

Untar the metadata files. The program will automatically delete the .tar.gz as these files would interfere with how the program runs.

### Mash
This program requires the installation of MASH v2.0 or greater. Mash can be downloaded from: https://github.com/marbl/Mash/releases.

### Perl
This program is written Perl. Please have the latest version of Perl installed, found here: https://www.perl.org/get.html

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
In order to run either mode of the program, a config file must be created in the same directory you are running the code. The format of the configuration file is 7 lines of separated KEY=VALUE pairs. The required keys are:

```
GENOMES=path to where the genome assemblies are to be stored
GTDB=path to folder with gtdb data OR 'none'
SOFTWARE=path to where the software is installed
DBS=path to where the SmartDBs will be stored
OLDGNMSTXT=path to an old gnms.txt file OR 'none'
CORES=Maximum number of cores allowed
QUICK_SETUP='none', 'all', or specific desired DBs (see description of Quick Setup mode below)
```

None of the values for each pair can be left blank.

### Manual Downloads
In some cases, the record of the GCA may be suppressed or otherwise not available from the FTP server. If so, our software stops to allow manual download of such files from the NCBI website: look at the legacy page, access the GenBank page and download the data as a fasta file. For the gtdb207 update, this only had to be done for GCA_905332505: Fenollaria sporofastidiosus EMRHCC_24, found at: https://www.ncbi.nlm.nih.gov/nuccore/HG994861.1?report=fasta. Rerunning hte program will automatically skip to this step and check which files were downloaded. If any were not, it will remove the GCA from the list and proceed without it.

### Full Update
This mode requires download of 5 GTDB files (see above) and setting the QUICK_SETUP config key to "none". This version of the program will download all necessary assemblies from the NCBI server and designing and preparing the SmarrtDBs from scratch. Here are some sample config files.

#### Full Update, First Time Use
```
GENOMES=../gb
GTDB=../gtdb/207
SOFTWARE=../bin
OLDGNMSTXT=none
DBS=dbs207
CORES=128
QUICK_SETUP=none
```

#### Full Update, after a previous run for an earlier GTDB release (note OLDGNMSTXT)
```
GENOMES=../gb
GTDB=../gtdb/207
SOFTWARE=../bin
OLDGNMSTXT=../update202/gnms.txt
DBS=dbs207
CORES=128
QUICK_SETUP=none
```

### Quick Setup
This mode requires download of the smartsUniq500 file, reflist.txt file, and the gnms.txt file from our github repository in the folder files. (The gnms.txt file and reflist.txt file can be omitted, but then the GTDB data will be required.) The QUICK_SETUP config file value can be "all" (to make the full set of DBs) or a comma-separated list of only the desired SmartDBs. This mode will only download the assemblies used in the precalculated databases, and skip any calculations. Note: Over the course of this program, gnms.txt and reflist.txt will be changed to only include the files that were downloaded and reflect the user's file system.

#### Quick Setup of full DB set
```
GENOMES=../gb
GTDB=none
SOFTWARE=../bin
OLDGNMSTXT=none
DBS=dbs207
CORES=128
QUICK_SETUP=all
```
#### Quick Setup for limited number of DBs
```
GENOMES=../gb
GTDB=none
SOFTWARE=../bin
OLDGNMSTXT=none
DBS=dbs207
CORES=128
QUICK_SETUP=Magnetobacterium__casensis,Quinella__sp905236255

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
### Lost GCAs in Ful Update Mode
When running full update mode from a previous version, there are cases where a GCA is present in the previous version, but no longer the newest update. The program will not add such cases to teh new gnms.txt, but will noted in notinnewrelease.txt. 
