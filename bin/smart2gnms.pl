use strict; use warnings;
use Parallel::ForkManager;
use File::Spec;

my ($repo, $gtdbfolder, $sps, $forks) = @ARGV;
my $pm = Parallel::ForkManager->new($forks);
my %gnms;
my %use;

if ($sps eq "all") {
 for (`cut -f 1 smartsUniq500`) { chomp; $use{$_} = 1; }
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

for (`cut -f 1,3 smartsUniq500`) {
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
system("mv tempgnms.txt gnms.txt");

sub GetLine {
 my $gca = shift;
 next unless $gca =~ /(\d{3})(\d{3})(\d{3})/;
 my $dir = File::Spec->rel2abs("$repo/$1/$2/$3");
 my ($sp, $tax, $version);
 if (-e "gnms.txt") {
  for (`grep "$gca" gnms.txt | cut -f 2,4,5`) {
   chomp; ($sp, $version, $tax) = split "\t";
  }
 } else {
  for (`egrep "GC[AF]_$gca" $gtdbfolder/sp_clusters_*`) {
   chomp; my @f = split "\t";
   ($sp, $tax) = ($f[1], $f[2]);
   $sp =~ s/s__(\S+) (\S+)/${1}__$2/;
   $f[9] =~ /GC[AF]_$gca\.(\d+)/;
   $version = $1;
  }
 }
 for (`grep -w "$sp" smartsUniq500`) {
  chomp; my @f = split "\t";
  $sp = $f[0];
 }
 my $line = join ("\t", $gca, $sp, $dir, $version, $tax);
 return $line;
}
