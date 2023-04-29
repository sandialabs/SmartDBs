use strict; use warnings;
use Parallel::ForkManager;
use File::Spec;

die "perl $0 gca-repository new-gtdb-folder species-list [max size] softdir [# of cores]\n" unless @ARGV == 6;
my ($repo, $gtdbfolder, $sps, $max, $softdir, $forks) = @ARGV;
my $pm = Parallel::ForkManager->new($forks);
my %gnms;
my %use;

if ($sps eq "all") {
 for (`cut -f 1 smartsUniq$max`) { chomp; $use{$_} = 1; }
} else {
 for (split ",", $sps) {chomp; $use{$_} = 1; }
}

open OUT, ">neededgnms.txt";
open GNMS, ">tempgnms.txt";
$pm->run_on_finish( sub {
 my ($pid, $exit_code, $ident, $exit_signal, $core_dump, $data) = @_;
 $ident =~ s/none//;
 $gnms{$ident} = 1;
 print GNMS "$data->{line}\n";
 print OUT "$ident\n";
});

for (`cut -f 1,3 smartsUniq$max`) {
 chomp; my ($sp, $list) = split "\t";
 next unless $use{$sp};
 for my $gca (split ",", $list) {
  next if $gnms{$gca};
  my $pid = $pm->start($gca) and next;
  my $line = GetLine($gca);
  $pm->finish(0, {line => $line});
 }
}
$pm->wait_all_children;
close OUT; close GNMS;
system("mv gnms.txt original_gnms.txt");
system("mv tempgnms.txt gnms.txt");

sub GetLine {
 my $gca = shift;
 next unless $gca =~ /(\d{3})(\d{3})(\d{3})/;
 my $dir = File::Spec->rel2abs("$repo/$1/$2/$3");
 my ($sp, $gencode, $tax, $version);
 if (-e "gnms.txt") {
  for (`grep "$gca" gnms.txt | cut -f 2,4,5,6`) {
   chomp; ($sp, $gencode, $tax, $version) = split "\t";
  }
 } else {
  for (`egrep "GC[AF]_$gca" $gtdbfolder/sp_clusters_*.tsv`) {
   chomp; my @f = split "\t";
   ($sp, $tax) = ($f[1], $f[2]);
   $sp =~ s/s__(\S+) (\S+)/${1}__$2/;
   $f[9] =~ /GC[AF]_$gca\.(\d+)/;
   $version = $1;
  }
  system("perl $softdir/gencode.pl $gtdbfolder/sp_cliuters_*.tsv;");
  $gencode = `grep -w "$sp" genetic_code_odd | cut -f 4`; $gencode = 11 unless $gencode;
  chomp $gencode;
 }
 my $line = join ("\t", $gca, $sp, $dir, $gencode, $tax, $version);
 return $line;
}
