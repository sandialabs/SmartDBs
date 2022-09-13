use strict; use warnings;
use Parallel::ForkManager;
use File::Spec;
my ($repo, $gnmsfile, $forks) = @ARGV;
my $old = $gnmsfile; $old =~ s/\/[^\/]+$//;
my $pm = Parallel::ForkManager->new($forks);

for (`cut -f 1 gnms.txt`) {
 chomp;
 my $gca = $_;
 my $pid = $pm->start and next;
 next unless /(\d{3})(\d{3})(\d{3})/;
 my $dir = File::Spec->rel2abs("$repo/$1/$2/$3");
 mkdir("$repo/$1") unless (-e "$repo/$1");
 mkdir("$repo/$1/$2") unless (-e "$repo/$1/$2");
 mkdir("$repo/$1/$2/$3") unless (-e "$repo/$1/$2/$3");
 for (`grep -w "^$gca" $gnmsfile | cut -f 3`) {
  chomp; my $path = File::Spec->rel2abs("$old/$_");
  system("cp -s $path/genome.fa $dir") unless (-e "$dir/genome.fa");
  system("cp -s $path/genome.fa.msh $dir") unless (-e "$dir/genome.fa.msh");
  if (-e "$path/genome.gff") {system("cp -s $path/genome.gff $dir") unless (-e "$dir/genome.gff")};
 }
 $pm->finish(0);
}
$pm->wait_all_children;
