use strict; use warnings;
use File::Spec;
use Cwd;
use Parallel::ForkManager;

die "perl $0 old-gnms-file new-gtdb-folder gca-repository [# of Cores]\n" unless @ARGV == 4;
my ($gnmsfile, $gtdbfolder, $repo, $forks) = @ARGV;
my $oldpath = File::Spec->rel2abs($gnmsfile); $oldpath =~ s/[^\/]+$//; 
my @files = ("newgnms.txt", $gnmsfile);
my $pm = Parallel::ForkManager->new($forks);
my %gnms;

#open RAW, ">RAWgnms.txt";
open OUT, ">gnms.txt";
open MISS, ">notinnewrelease.txt";
$pm->run_on_finish( sub {
 my ($pid, $exit_code, $ident, $exit_signal, $core_dump, $data) = @_;
 $ident =~ s/none//;
 $gnms{$ident} = 1;
 if ($exit_code) {
  print MISS "$ident failed! Not in sp_cluster file.\n";
  #print RAW "$data->{line}\n";
 } else {
  print OUT "$data->{line}\n";
  #print RAW "$data->{line}\n";
 }
});

for my $file (@files) {
 for (`cat $file`) {
  chomp;
  my @f = split "\t";
  my ($olddir, $oldsp, $oldgencode, $oldtax, $oldversion) = ('', '', '11', 'na', 'na');
  $olddir = $f[2] if $f[2]; $oldsp = $f[1] if $f[1]; $oldgencode = $f[3] if $f[3]; $oldtax = $f[4] if $f[4]; $oldversion = $f[5] if $f[5];
  my $gca = $f[0];
  next if $gnms{$gca};
  my $pid = $pm->start($gca) and next;
  next unless $gca =~ /(\d{3})(\d{3})(\d{3})/;
  my $dir = File::Spec->rel2abs("$repo/$1/$2/$3");
  my ($tax, $sp, $version);
  for (`egrep "GC[AF]_$gca" $gtdbfolder/sp_clusters_*`) {
   /GC[AF]_$gca\.(\d+)/; $version = $1;
   my @f = split "\t";
   $sp = $f[1]; $sp =~ s/s__(\S+) (\S+)/${1}__$2/;
   $tax = $f[2];
  }
  
  if ($sp) {
   my $gencode = `grep -w "$sp" genetic_code_odd | cut -f 4`; $gencode = 11 unless $gencode;
   chomp $gencode;
   my $line = join ("\t", $gca, $sp, $dir, $gencode, $tax, $version);
   $pm->finish(0, {line => $line});
  } else {
   my $line = join ("\t", $gca, $oldsp, $olddir, $oldgencode, $oldtax, $oldversion);
   $pm->finish(1, {line => $line});
  }
 }
}

$pm->wait_all_children;
close OUT; close MISS;
