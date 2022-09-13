use strict; use warnings;
use Parallel::ForkManager;

my ($repo, $forks) = @ARGV;

my $pm = Parallel::ForkManager->new($forks);
for (`cat newgnms.txt`) {
 next unless /^(\d{3})(\d{3})(\d{3})$/;
 my $pid = $pm->start and next;
 my $dir = "$repo/$1/$2/$3";
 $pm->finish(0) if (-e "$dir/genome.fa.msh");
 system("mash sketch -I $1$2$3 -C '-' -o $dir/genome.fa $dir/genome.fa");
 $pm->finish(0);
}
$pm->wait_all_children;
