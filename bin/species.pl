use strict; use warnings;
use Parallel::ForkManager;

my $gtdbfolder = shift;
open REF, ">reflist.txt";
open SP, ">specieslist";
my $cmd = "mash paste -l specieslist reps.msh";
for (`grep -v Rep $gtdbfolder/sp_clusters_*.tsv | cut -f 1,2,4`) {
 /GC[AF]_(\d+).*s__(\S+ \S+)/;
 my ($gca, $id, $circum) = ($1, $2, $4);
 $gca =~ /(\d{3})(\d{3})(\d{3})/;
 my $path = "$repo/$1/$2/$3";
 print REF "$gca\t$id\t$circum\n";
 print SP "$path/genome.fa.msh\n";
}
system("cmd");
close REF;
close SP;
