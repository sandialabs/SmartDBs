use strict; use warnings;
# reserve 10% of worst quality, then go by diversity

my ($target, $worst) = (500, 0.1);  # Desired database size, Fraction reserved for same genus other species
die "Usage: perl $0 gtdbClass gtdbFamily gtdbSpecies new-gtdb-folder\n" unless @ARGV == 4;
my (%avail, %gnms, @order, %dists, %outs, $rep);
my ($c, $o, $sp, $gtdb) = @ARGV;
warn "Ranking $sp\n";
$sp =~ /(\S+)__(\S+)/; my $gtdbsp = "s__$1 $2";
Getmeta();
for (`grep -w '$gtdbsp' $gtdb/sp_cluster* | cut -f 1`) {
 next unless /^\S+_(\d{9})\.\d+/;
 $rep = $1;
}
die "Couldn't find representative for $sp\n" unless $rep;
$gnms{$rep}[2] = 1;
for (`cat gnms.txt`) {my @f = split "\t"; next unless $gnms{$f[0]}; $avail{$f[0]} = $f[2]}
my $count = scalar keys %avail;
my $keep = int((1-$worst) * $count);
my @good = sort {$gnms{$b}[2] <=> $gnms{$a}[2] ||
                 $gnms{$b}[0] <=> $gnms{$a}[0] ||
                 $gnms{$a}[1] <=> $gnms{$b}[1] 
 } keys %avail;  # Representative first, then sort by MIMAG then scaffs
my @bad = splice @good, $keep, $count-$keep;
for (`cat dists/$c/$o/$sp.mx`) {
 chomp; my @f = split "\t";
 my $t = shift @f;
 for my $i (@order) { my $val = shift @f; $dists{$t}{$i} = $val; $dists{$i}{$t} = $val; }
 push @order, $t;
}
my %sumdists;
my $last = $good[0];
for (@good) {print STDERR "$_\n"; $sumdists{$_} = 0}
#open OUT, ">orders/$c/$o/$sp";
open OUT, ">$sp";
while (keys %sumdists) {
 #next unless defined $sumdists{$_};
 $outs{$last} ++;
 print OUT "$last\n";
 delete $sumdists{$last};
 for my $cand (keys %sumdists) {die "Missing dist for $c/$o/$sp: $last to $cand\n" unless defined $dists{$last}{$cand}; $sumdists{$cand} += $dists{$last}{$cand}}
 $last = (sort {$sumdists{$b} <=> $sumdists{$a}} keys %sumdists)[0];  # Most distant from all previous
}
for (@bad) {print OUT "$_\n"}
close OUT;

sub Getmeta {
 my %cats = qw/accession 1 gtdb_taxonomy 1 mimag_high_quality 1 mimag_medium_quality 1 scaffold_count 1/;
 my $name = ";$gtdbsp";
 for my $file (glob "$gtdb/*_metadata_*") {
  #warn "Using $file for $name\n";
  my ($ct, %key) = (0);
  open IN, $file;
  my $head = <IN>;
  chomp $head;
  for (split "\t", $head) {$key{$_} = $ct if $cats{$_}; $ct ++}
  for (<IN>) {
   chomp; my @f = split "\t";
   next unless $f[$key{gtdb_taxonomy}] =~ /$name$/;
   my $mimag = 0;
   if ($f[$key{mimag_medium_quality}] eq 't'){$mimag = 1}
   elsif ($f[$key{mimag_high_quality}] eq 't'){$mimag = 2}
   die unless $f[$key{accession}] =~ s/.*_(\d{9})\..*/$1/;
   @{$gnms{$f[$key{accession}]}} = ($mimag, $f[$key{scaffold_count}], 0);
  }
 }
}
