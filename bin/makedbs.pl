use strict; use warnings;
use Parallel::ForkManager;
use File::Spec;

die "perl $0 database-repository gca-repository species-list [max size] [# of cores]\n" unless @ARGV == 5;
my ($dbsdir, $repo, $dblist, $max, $fork) = @ARGV;
warn "$dbsdir, $repo, $dblist, $fork\n";
my $pm = Parallel::ForkManager->new($fork);
my (%dirs, %tax, %compos, %dbs);
my %dbsused;
if ($dblist eq "all" or $dblist eq "none") {
 for (`cut -f 1 smartsUniq$max`) {
  chomp; $dbsused{$_} = 1;
 }
} else {
 for (split(",", $dblist)) {
  $dbsused{$_} = 1;
 }
}
for (`cat smartsUniq$max`) {
 chomp; my ($db, $tot, $list, $spp) = split "\t";
 for (split ',', $list) {$compos{$_} = $db; $dbs{$db}{$_} ++}
}
for (`cut -f 1,2,3,5 gnms.txt`) {/^(\S+)\t(\S+)\t(\S+)\t(\S+)/; next unless $compos{$1}; $dirs{$1} = $3; $tax{$2} = $4; }
for my $db (keys %dbs) {
 next unless $dbsused{$db};
 my $pid = $pm->start and next;
 $tax{$db} =~ /c__([^;]+);o__[^;]+;f__([^;]+);/; my ($c, $f) = ($1, $2); mkdir "$dbsdir/$c"; mkdir "$dbsdir/$c/$f";
 system("rm $dbsdir/$c/$f/$db.fa;") if (-e "$dbsdir/$c/$f/$db.fa");
 for my $gnm (sort keys %{$dbs{$db}}) {
  system("cat $dirs{$gnm}/genome.fa >> $dbsdir/$c/$f/$db.fa") if (-e "$dirs{$gnm}/genome.fa");
 }
 system("makeblastdb -parse_seqids -in $dbsdir/$c/$f/$db.fa -dbtype nucl -out $dbsdir/$c/$f/$db");
 $pm->finish(0);
}
$pm->wait_all_children;
