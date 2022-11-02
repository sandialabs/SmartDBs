use strict; use warnings;
use Parallel::ForkManager;

my ($repo, $gtdbfolder, $sps) = @ARGV;
open REF, ">reflist.txt";
my $lists = '';
my $count = 0;
my $ct = 0;
if ($gtdbfolder ne "none") {
 for (`grep -v Rep $gtdbfolder/sp_clusters_*.tsv | cut -f 1,2,4`) {
  /GC[AF]_(\d+).*s__(\S+ \S+)\t(\S+)/;
  my ($gca, $id, $circum) = ($1, $2, $3);
  $gca =~ /(\d{3})(\d{3})(\d{3})/;
  my $path = "$repo/$1/$2/$3";
  $id =~ s/(\S+) (\S+)/${1}_$2/;
  print REF "$gca\t$id\t$circum\n";
  die "No reference" unless (-e "$path/genome.fa.msh");
  $lists .= " $path/genome.fa.msh"; $count ++;
  if ($count == 500) { system("mash paste temp$ct$lists"); $ct ++; $count = 0;  $lists = ''; }
 }
} else {
 system("mv reflist.txt reflist.txtOLD");
 for (`cat reflist.txtOLD`) {
  /(\S+)\t(\S+)\t(\S+)/;
  my ($gca, $id, $circum) = ($1, $2, $3);
  $gca =~ /(\d{3})(\d{3})(\d{3})/;
  my $path = "$repo/$1/$2/$3";
  next unless (-e "$path/genome.fa");
  print REF "$gca\t$id\t$circum\n";
  die "No reference" unless (-e "$path/genome.fa.msh");
  $lists .= " $path/genome.fa.msh"; $count ++;
  if ($count == 500) { system("mash paste temp$ct$lists"); $ct ++; $count = 0;  $lists = ''; }
 }
 system("rm reflist.txtOLD");
}
close REF;
system("mash paste temp$ct$lists");
system("mash paste reps temp*");
system("rm temp*");
