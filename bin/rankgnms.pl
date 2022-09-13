use strict; use warnings;
# reserve 10% of worst quality, then go by diversity

my ($target, $worst) = (500, 0.1);  # Desired database size, Fraction reserved for same genus other species
die "Usage: perl $0 gtdbClass gtdbFamily gtdbSpecies new-gtdb-folder\n" unless @ARGV == 4;
my (%avail, %gnms, @order, %dists, %outs);
my ($c, $o, $sp, $gtdb) = @ARGV;
warn "Ranking $sp\n";
Getmeta();
#for (`cat gnms.txt`) {my @f = split "\t"; next if $f[1] ne $sp or not $gnms{$f[0]}; $avail{$f[0]} = $f[2]}
for (`cat gnms.txt`) {my @f = split "\t"; next unless $gnms{$f[0]}; $avail{$f[0]} = $f[2]}
my $count = scalar keys %avail;
my $keep = int((1-$worst) * $count);
#for (keys %avail) {warn "$_ "} for (keys %gnms) {warn "$_ "}
#die scalar (keys %gnms), " gnms; $count avail, keep $keep\n";
#if ($count < $target) {for (keys %gnms) {warn "$_\n" unless $avail{$_}}}
my @good = sort {$gnms{$b}[0] <=> $gnms{$a}[0] || $gnms{$a}[1] <=> $gnms{$b}[1]} keys %avail;  # MIMAG then scaffs
my @bad = splice @good, $keep, $count-$keep;
#for (`cat dists/$sp 001363095.sal 001362415.sal`) {chomp; my @f = split "\t"; $dists{$f[0]}{$f[1]} = $f[2]; $dists{$f[1]}{$f[0]} = $f[2]}
for (`cat dists/$c/$o/$sp.mx`) {
 chomp; my @f = split "\t";
 my $t = shift @f;
 for my $i (@order) { my $val = shift @f; $dists{$t}{$i} = $val; $dists{$i}{$t} = $val; }
 push @order, $t;
 #print STDERR "$t\n";
}
my %sumdists;
my $last = $good[0];
for (@good) {print STDERR "$_\n"; $sumdists{$_} = 0}
open OUT, ">orders/$c/$o/$sp";
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
 $sp =~ /(.*)__(.*)/;
 my $name = ";s__$1 $2";
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
   @{$gnms{$f[$key{accession}]}} = ($mimag, $f[$key{scaffold_count}]);
  }
 }
}
