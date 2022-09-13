use strict; use warnings;
my %config;
ReadConfig();
mkdir $config{GENOMES} unless -d $config{GENOMES};
mkdir $config{DBS}     unless -d $config{DBS};
my $softdir = $config{SOFTWARE};
my $cores = $config{CORES};

my $logic = ($config{QUICK_SETUP} eq "none") ? 1 : 0;

if ($config{OLDGNMS} eq "none") {
 system("touch blank");
 $config{OLDGNMS} = "blank";
}

unless ($config{GTDB} eq "none") {
 for ('ar*metadata*', 'bac*metadata*', 'ar*.sp_labels.tree', 'bac*.sp_labels.tree', 'sp_clusters*.tsv') {
  my @files = glob "$config{GTDB}/$_";
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
 die "Missing smartsUniq500 file!\n" unless (-e "smartsUniq500");
 if ($config{GTDB} eq "none") {
  die "Path to gtdb data must be included must be included when missing the gnms.txt file!\n" unless (-e "gnms.txt");
 }
 QuickSetUp();
}



sub FullUpdate {
 print STDERR "Running toget\n";
 unless (-e "neededgnms.txt") {
  die if system("perl $softdir/toget.pl $config{OLDGNMS} $config{GTDB}");
 }
 my $count = -1;
 my $prevcount = -2;
 unless (-e "rsynclog") { 
  while ($count != 0 and $count != $prevcount) {
   print STDERR "Running jobsrsync\n";
   #die if system("perl $softdir/jobsrsync.pl $config{GENOMES} $cores");
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
  print STDERR "Running jobsrsync\n";
  #die if system("perl $softdir/jobsrsync.pl $config{GENOMES} $cores");
  $count = `wc -l rsynclog`; $count =~ s/ rsynclog//;
 }
 if ($count) {
  open OUT, ">newgnms.txt";
  my (%missing);
  for (`cat rsynclog`) { chomp; $missing{$_} = 1; system("rm -rf $config{GENOMES}/$1/$2/$3") if /(\d{3})(\d{3})(\d{3})/; }
  for (`cat neededgnms.txt`) { chomp; print OUT "$_\n" unless $missing{$_}; }
  close OUT;
 }
 print STDERR "Running writemash\n";
 #die if system("perl $softdir/writemash.pl $config{GENOMES} $cores");
 print STDERR "Running newgnms\n";
 die if system("perl $softdir/newgnms.pl $config{OLDGNMS} $config{GTDB} $config{GENOMES} $cores");
 print STDERR "Running finishgca\n";
 #die if system("perl $softdir/finishgca.pl $config{GENOMES} $config{OLDGNMS} $cores");
 print STDERR "Running mashlists\n";
 #die if system("perl $softdir/mashlists.pl $config{GTDB} $cores");
 print STDERR "Running mashpaste\n";
 #die if system("perl $softdir/mashpaste.pl $config{GTDB} $softdir $cores &> mash.log");
 print STDERR "Running treeparse\n";
 #die if system("perl $softdir/treeparse.pl $config{GTDB}");
 print STDERR "Running catorders\n";
 #die if system("perl $softdir/catorders.pl $cores");
 print STDERR "Running smartdblist\n";
 #die if system("perl $softdir/smartdblist.pl $config{GTDB} $cores &> dblist.log");
 #print STDERR "Running resmart\n";
 #die if system("perl $softdir/resmart.pl $cores");
 print STDERR "Running makedbs\n";
 #die if system("perl $softdir/makedbs.pl $config{DBS} $config{GENOMES} $config{QUICK_SETUP} $cores &> makedbs.log");
 print STDERR "Running species\n";
 die if system("perl $softdir/species.pl $config{GTDB}");
}

sub QuickSetUp {
 print STDERR "Running smart2gnms\n";
 die if system("perl $softdir/smart2gnms.pl $config{GENOMES} $config{GTDB} $config{QUICK_SETUP} $cores");
 my $count = -1;
 my $prevcount = -2;
 unless (-e "rsynclog") {
  while ($count != 0 and $count != $prevcount) {
   print STDERR "Running jobsrsync\n";
   die if system("perl $softdir/jobsrsync.pl $config{GENOMES} $cores");
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
  print STDERR "Running jobsrsync\n";
  die if system("perl $softdir/jobsrsync.pl $config{GENOMES} $cores");
  $count = `wc -l rsynclog`; $count =~ s/ rsynclog//;
 }
 if ($count) {
  my %missing;
  for (`cat rsynclog`) { chomp; $missing{$_} = 1; }
  open OUT, ">tempgnms.txt";
  for (`cat gnms.txt`) { chomp; my @f = split "\t"; print OUT "$_\n" unless $missing{$f[0]}; }
  system("mv tempgnms.txt gnms.txt");
 }
 print STDERR "Running makedbs\n";
 die if system("perl $softdir/makedbs.pl $config{DBS} $config{GENOMES} $config{QUICK_SETUP} $cores &> makedbs.log");
}

sub ReadConfig {
 die "Prepare config file\n" unless -f 'config';
 for (`cat config`) {
  chomp; next unless /^([^=]+)=(\S+)/;
  $config{$1} = $2;
 }
 for (qw/GENOMES SOFTWARE DBS GTDB OLDGNMS CORES QUICK_SETUP/) {die "Config file missing $_\n" unless $config{$_}}
}

