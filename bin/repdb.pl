use strict; use warnings;
use Parallel::ForkManager;

die "perl $0 gca-repository new-gtdb-folder species-list\n" unless @ARGV == 3;
my ($repo, $gtdbfolder, $sps) = @ARGV;
open REF, ">reflist.txt";
my $lists = '';
my $count = 0;
my $ct = 0;
if ($gtdbfolder ne "none") {
 for (`grep -v '^Repre' $gtdbfolder/sp_clusters_*.tsv | cut -f 1,2,4`) {
  /GC[AF]_(\d+).*s__(\S+ \S+)\t(\S+)/;
  my ($gca, $id, $circum) = ($1, $2, $3);
  $gca =~ /(\d{3})(\d{3})(\d{3})/;
  my $path = "$repo/$1/$2/$3";
  $id =~ s/(\S+) (\S+)/${1}__$2/;
  print REF "$gca\t$id\t$circum\n";
  die "No reference" unless (-e "$path/genome.fa.msh");
  $lists .= " $path/genome.fa.msh"; $count ++;
  if ($count == 500) { system("mash paste temp$ct$lists"); $ct ++; $count = 0;  $lists = ''; }
 }
} else {
 for (`cat reflist.txt`) {
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
}
close REF;
system("mash paste temp$ct$lists");
system("mash paste reps temp*");
system("rm temp*");
