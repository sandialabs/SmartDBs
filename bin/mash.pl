use strict; use warnings;
use Parallel::ForkManager;

die "perl $0 new-gtdb-folder softdir [# of cores]\n" unless @ARGV == 3;
my ($gtdbfolder, $softdir, $forks) = @ARGV;

my $pm = Parallel::ForkManager->new($forks);

for (qw/msh dists orders/) {mkdir $_}
for my $file (glob "lists/*/*/*") {
 $file =~ /\/([^\/]+)\/([^\/]+)\/([^\/]+)$/;
 my ($c, $f, $sp) = ($1, $2, $3);
 my $pid = $pm->start and next;
 for (qw/msh dists orders/) { mkdir "$_/$c"; mkdir "$_/$c/$f"; }
 system("mash paste msh/$c/$f/$sp -l $file; mash dist msh/$c/$f/$sp.msh -d 0.29 -l $file | perl $softdir/abc2mx.pl > dists/$c/$f/$sp.mx; perl $softdir/rankgnms.pl $c $f $sp $gtdbfolder;");
 $pm->finish(0);
}
$pm->wait_all_children;

