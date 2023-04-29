use strict; use warnings;

my %config;
ReadConfig();
mkdir $config{GENOME_DIR} unless -d $config{GENOME_DIR};
mkdir $config{DB_DIR}     unless -d $config{DB_DIR};
my $softdir = $config{SOFTWARE_DIR};
my $cores = $config{CORES};
my $gtdb = $config{GTDB_DIR};

my $logic = ($config{QUICK_SETUP} eq "no") ? 1 : 0;

if ($config{PREV_GNMS} eq "none") {
 system("touch blank");
 $config{PREV_GNMS} = "blank";
}

unless ($gtdb eq "none") {
 for ('ar*metadata*', 'bac*metadata*', 'ar*.sp_labels.tree', 'bac*.sp_labels.tree', 'sp_clusters*.tsv') {
  my @files = glob "$gtdb/$_";
  my $flag; for (@files) {$flag ++ unless /tar.gz$/}
  unless ($flag) {die "Missing GTDB file $_ required for FULL UPDATE; untar any GTDB .tar.gz files)\n"}
  for (@files) {unlink $_ if /tar.gz$/}
 }
}

if ($logic) {
 print STDERR "FULL UPDATE MODE\n";
 FullUpdate();
} else {
 print STDERR "QUICK SETUP MODE\n";
 die "Missing smartsUniq$config{DB_SIZE} file!\n" unless (-e "smartsUniq$config{DB_SIZE}");
 if ($gtdb eq "none") {
  die "Path to gtdb data must be included must be included when missing the gnms.txt file!\n" unless (-e "gnms.txt");
 }
 QuickSetUp();
}

unlink "blank" if (-e "blank");
mkdir "log"; system("mv *log log/;");
system("mv newgnms.txt neededgnms.txt");

sub FullUpdate {
 RunCommand("perl $softdir/toget.pl $config{PREV_GNMS} $gtdb", "neededgnms.txt");
 my $count = -1;
 my $prevcount = -2;
 unless (-e "rsynclog") { 
  while ($count != 0 and $count != $prevcount) {
   RunCommand("perl $softdir/jobsrsync.pl $config{GENOME_DIR} $cores &> rsync.log", "");
   $prevcount = $count;
   $count = `wc -l rsynclog`; $count =~ s/ rsynclog//;
   print "$count\n";
  }
  if ($count > 0) {
   print "Some GCAs must be manaully downloaded:\n";
   system("cat rsynclog");
   print "This list can be found in the file rsynclog. You can find some of these GCAs on the main NCBI website. Rerun the program to continue. Note: When the program continues, it will do so without using any of the missing GCAs and these can not be added later.\n"; 
   exit;
  }
 } else {
  RunCommand("perl $softdir/jobsrsync.pl $config{GENOME_DIR} $cores &> rsync.log", "");
  $count = `wc -l rsynclog`; $count =~ s/ rsynclog//;
 }
 open OUT, ">newgnms.txt";
 my (%missing);
 for (`cat rsynclog`) { chomp; $missing{$_} = 1; system("rm -rf $config{GENOMES}/$1/$2/$3") if /(\d{3})(\d{3})(\d{3})/; }
 for (`cat neededgnms.txt`) { chomp; print OUT "$_\n" unless $missing{$_}; }
 close OUT;
 RunCommand("perl $softdir/gencode.pl $gtdb/sp_clusters*.tsv", "genetic_code_odd");
 RunCommand("perl $softdir/newgnms.pl $config{PREV_GNMS} $gtdb $config{GENOME_DIR} $cores", "notinnewrelease.txt");
 RunCommand("perl $softdir/links.pl $config{GENOME_DIR} $config{PREV_GNMS} $cores", "");
 RunCommand("perl $softdir/sketch.pl $config{GENOME_DIR} $cores", "");
 RunCommand("perl $softdir/gnmlists.pl $gtdb $cores", "lists");
 RunCommand("perl $softdir/mash.pl $gtdb $softdir $cores &> mash.log", "msh");
 RunCommand("perl $softdir/treeparse.pl $gtdb", "nodelists");
 RunCommand("perl $softdir/catorders.pl $cores", "orders/orders.txt");
 RunCommand("perl $softdir/dbdesign.pl $gtdb $config{DB_SIZE} $config{OFFSPECIES} $config{TOP_ORDER} $cores &> dblist.log", "smartsUniq$config{DB_SIZE}");
 if ($config{BUILD} eq "yes") {
  RunCommand("perl $softdir/makedbs.pl $config{DB_DIR} $config{GENOME_DIR} $config{SPECIES} $config{DB_SIZE} $cores &> makedbs.log". "");
 }
 RunCommand("perl $softdir/repdb.pl $config{GENOME_DIR} $gtdb $config{SPECIES}", "reps.msh");
}

sub QuickSetUp {
 RunCommand("perl $softdir/smartQuick.pl $config{GENOME_DIR} $gtdb $config{SPECIES} $config{DB_SIZE} $cores", "");
 my $count = -1;
 my $prevcount = -2;
 unless (-e "rsynclog") {
  while ($count != 0 and $count != $prevcount) {
   RunCommand("perl $softdir/jobsrsync.pl $config{GENOME_DIR} $cores", "");
   $prevcount = $count;
   $count = `wc -l rsynclog`; $count =~ s/ rsynclog//;
   print "$count\n";
  }
  if ($count > 0) {
   print "Some GCAs must be manaully downloaded:\n";
   system("cat rsynclog");
   print "This list can be found in the file rsynclog. You can find some of these GCAs on the main NCBI website. Rerun the program to continue. Note: Any undownloaded files with be not used in the dbs.\n";
   exit;
  }
 } else {
  RunCommand("perl $softdir/jobsrsync.pl $config{GENOME_DIR} $cores", "");
  $count = `wc -l rsynclog`; $count =~ s/ rsynclog//;
 }
 if ($count) {
  my %missing;
  for (`cat rsynclog`) { chomp; $missing{$_} = 1; }
  open OUT, ">tempgnms.txt";
  for (`cat gnms.txt`) { chomp; my @f = split "\t"; print OUT "$_\n" unless $missing{$f[0]}; }
  system("mv tempgnms.txt gnms.txt");
 }
 if ($config{BUILD} eq "yes") {
  RunCommand("perl $softdir/makedbs.pl $config{DB_DIR} $config{GENOME_DIR} $config{SPECIES} $config{DB_SIZE} $cores &> makedbs.log", "");
 }
 RunCommand("perl $softdir/repdb.pl $config{GENOME_DIR} $gtdb $config{SPECIES}", "reps.msh");
}

sub ReadConfig {
 die "Prepare config file\n" unless -f 'config';
 for (`cat config`) {
  chomp; next unless /^([^=]+)=(\S+)/;
  $config{$1} = $2;
 }
 $config{PREV_GNMS} = 'none' unless $config{PREV_GNMS};
 $config{DB_SIZE} = 500 unless $config{DB_DIR};
 $config{PREV_GNMS} = "none" unless $config{PREV_GNMS};
 $config{CORES} = 1 unless $config{CORES};
 $config{QUICK_SETUP} = "no" unless $config{QUICK_SETUP};
 $config{SPECIES} = "all" unless $config{SPECIES};
 $config{BUILD} = "yes" unless $config{BUILD};
 $config{OFFSPECIES} = 0 unless $config{OFFSPECIES};
 $config{TOP_ORDER} = "o" unless $config{TOP_ORDER};
 for (qw/GENOME_DIR SOFTWARE_DIR DB_DIR GTDB_DIR DB_SIZE PREV_GNMS CORES QUICK_SETUP SPECIES BUILD OFFSPECIES TOP_ORDER/) {die "Config file missing $_\n" unless defined $config{$_}}
}

sub RunCommand {
 my ($cmd, $check) = @_;
 if ($check) { if (-e $check) { warn "Skipping $cmd, $check exists\n"; return } }
 warn "Running $cmd\n";
 die "$cmd failed!\n" if system("$cmd");
}
