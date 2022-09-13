use strict; use warnings;
use Parallel::ForkManager;
my ($repo, $forks) = @ARGV;
$forks = 30 if $forks > 30;
my $pm = Parallel::ForkManager->new($forks);
my %remaining;

$pm->run_on_finish( sub {
 my ($pid, $exit_code, $ident, $exit_signal, $core_dump, $data) = @_;
 #system("$data->{cmd}");
 $ident =~ s/none//;
 $remaining{$ident} = 1 unless $data->{skip};
 #die if $exit_code;
});

for (`cat neededgnms.txt`) {
 chomp;
 my $pid = $pm->start($_) and next;
 /^(\d{3})(\d{3})(\d{3})$/;
 my $dir = "$repo/$1/$2/$3";
 $pm->finish(0, {skip => 1, cmd => ""}) if (-e "$dir/genome.fa");
 my ($f, $s, $t) = ($1, $2, $3);
 my %assemblies;
 for (`rsync --list-only rsync://ftp.ncbi.nlm.nih.gov/genomes/all/GCA/$f/$s/$t/ | tail -n +18`) {
  my @l = split " ";
  $l[-1] =~ /^\S+\.(\d+)_\S+$/; my $version = $1;
  $assemblies{$l[-1]} = {time => $l[-2], date => $l[-3], version => $version};
  warn "ERROR::No version found for $dir!\n" unless $version;
 }
 $pm->finish(1, {cmd => "echo \"ERROR::No list of assemblies found\""}) if (scalar keys %assemblies == 0);
 my $assembly;
 for (keys %assemblies) {
  unless ($assembly) {
   $assembly = $_; next;
  }
  if ($assemblies{$_}{version} gt $assemblies{$assembly}{version}) {
   $assembly = $_; next;
  }
  if ($assemblies{$_}{version} eq $assemblies{$assembly}{version} and $assemblies{$_}{date} gt $assemblies{$assembly}{date}) {
   $assembly = $_; next;
  }
  if ($assemblies{$_}{version} eq $assemblies{$assembly}{version} and $assemblies{$_}{date} eq $assemblies{$assembly}{date} and $assemblies{$_}{time} gt $assemblies{$assembly}{time}) {
   $assembly = $_; next;
  }
 }
 $pm->finish(1, {cmd => "echo \"ERROR::No assembly found for $dir!\""}) unless $assembly;
 my $cmd = "mkdir '$repo/$f'; mkdir '$repo/$f/$s'; mkdir $dir; " .
  "rsync --copy-links --recursive --times --verbose rsync://ftp.ncbi.nlm.nih.gov/genomes/all/GCA/" .
  "$f/$s/$t/$assembly/$assembly" . "_genomic.fna.gz $dir; " .
  "mv $dir/$assembly" . "_genomic.fna.gz $dir/genome.fa.gz; gunzip $dir/genome.fa.gz;";
 system("$cmd");
 $pm->finish(0);
}
$pm->wait_all_children;

open OUT, ">rsynclog"; for (keys %remaining) { print OUT "$_\n"; } close OUT;
