use strict; use warnings;
use Parallel::ForkManager;
use File::Spec;

my %gnms;
die "perl $0 new-gtdb-folder [# of cores]\n" unless @ARGV == 2;
my ($gtdbfolder, $forks) = @ARGV;

my $pm = Parallel::ForkManager->new($forks);

$pm->run_on_finish( sub {
 my ($pid, $exit_code, $ident, $exit_signal, $core_dump, $data) = @_;
 die "$data->{debug}\n" if $exit_code;
});

mkdir "lists";
for (`cut -f 1,3 gnms.txt`) {chomp; my ($gnm, $dir) = split "\t"; $gnms{$gnm} = $dir}
for (`grep -v '^Repre' $gtdbfolder/sp_clusters_*.tsv | cut -f 2,3,10`) {
 my @order;
 chomp; my ($sp, $tax, $list) = split "\t";
 $tax =~ /c__([^;]+);o__[^;]+;f__([^;]+);/; my ($c, $f) = ($1, $2);
 $sp =~ s/s__(\S+) (\S+)/${1}__$2/;
 my $pid = $pm->start and next;
 for (split ',', $list) {
  die "$list\n" unless /_(\d{9})\./;
  next unless $gnms{$1};
  push @order, "$gnms{$1}/genome.fa.msh";
 }
 $pm->finish(1, {debug => "ERROR::No orders list for $sp"}) unless @order;
 mkdir("lists/$c"); mkdir("lists/$c/$f"); open OUT, ">lists/$c/$f/$sp"; for (sort @order) {print OUT "$_\n"} close OUT;
 $pm->finish(0);
}
$pm->wait_all_children;
