use strict; use warnings;
use Parallel::ForkManager;

my ($repo, $gtdbfolder, $sps) = @ARGV;

if ($sps eq "all" or $sps eq "none") {
 for my $list (`cut -f 4 smartsUniq500`) {
  chomp $list;
  for (split(',', $list) {
   $use{$_} = 1;
  }
 }
} else {
 for my $sp (split ",", $sps) {
  chomp $sp;
  for my $list (`grep -w "$sp" smartsUniq500 | cut -f 4`) {
   for (split(',', $list) {
    $use{$_} = 1;
   }
  }
}


open REF, ">reflist.txt";
my $list;
my $count = 0;
my $ct = 0;
if ($gtdbfolder ne "none") {
 for (`grep -v Rep $gtdbfolder/sp_clusters_*.tsv | cut -f 1,2,4`) {
  /GC[AF]_(\d+).*s__(\S+ \S+)\t(\S+)/;
  my ($gca, $id, $circum) = ($1, $2, $3);
  $gca =~ /(\d{3})(\d{3})(\d{3})/;
  my $path = "$repo/$1/$2/$3";
  $id =~ s/(\S+) (\S+)/${1}_$2/;
  next unless $use{$id};
  print REF "$gca\t$id\t$circum\n";
  die "No reference" unless (-e "$path/genome.fa.msh");
  $list .= " $path/genome.fa.msh"; $count ++;
  if ($count == 500) { system("mash paste temp$ct$list"); $ct ++; $count = 0;  $list = ''; }
 }
} else {
 system("mv reflist.txt reflist.txtOLD");
 for (`cat reflist.txtOLD`) {
  /(\S+)\t(\S+)\t(\S+)/;
  my ($gca, $id, $circum) = ($1, $2, $3);
  $gca =~ /(\d{3})(\d{3})(\d{3})/;
  my $path = "$repo/$1/$2/$3";
  next unless $use{$id};
  print REF "$gca\t$id\t$circum\n";
  die "No reference" unless (-e "$path/genome.fa.msh");
  $list .= " $path/genome.fa.msh"; $count ++;
  if ($count == 500) { system("mash paste temp$ct$list"); $ct ++; $count = 0;  $list = ''; }
 }
 system("rm reflist.txtOLD");
}
close REF;
system("mash paste temp$ct$list");
system("mash paste reps temp*");
system("rm temp*");
