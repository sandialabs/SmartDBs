use strict; use warnings;
my ($gtdbfolder, $forks) = @ARGV;
my ($max, $offspecies, $toprank) = (500, 0.1, 'o');  # Database size limit, Fraction reserved for other species, phylogenetic breadth allowed (o=Order)
my (%nodedists, %seen, %singletops, %tops, %topnodes, $toget);  # Singletops: because trees don't name Order for single-species Orders
my $limit = int($max * (1-$offspecies));
my %comps;

for (`cut -f 2,3 $gtdbfolder/sp_clusters*.tsv`) {
 next unless /^s__(\S+) (\S+).*(${toprank}__[^;\s]+)/; $tops{"${1}__$2"} = $3; $singletops{$3} ++
}
for (`cat nodedists`) {chomp; my @f = split "\t"; $nodedists{$f[0]} = $f[1]; $topnodes{$2} = $1 if /^(\S+)\t.*(${toprank}__[^;\s]+)/;}
open OUT, ">smartsUniq$max";
for my $spnodes (`cat nodelists`) {
 chomp $spnodes; $spnodes =~ s/^(\S+)//; my $sp = $1;
 warn "$sp\n";
 $toget = $max;
 my (%dists, %nodelists, %nodes, %spdists, @sporder, %shared, @out);
 my $top = $tops{$sp};
 my $topnode = $topnodes{$top};
 while ($spnodes =~ s/^\t(\d+)//) {
  push @sporder, $1; $shared{$1} ++; $topnode = $1 if $singletops{$top} == 1; last if $1 eq $topnode
 }
 for (`grep -w '$topnode' nodelists`) {
  chomp; s/^(\S+)//; my $s = $1; #next if $s eq $sq;
  while (s/^\t(\d+)//) {$nodes{$1}{$s} ++; push @{$nodelists{$s}}, $1; last if $shared{$1}}
 }
 my $d = 0; for (@sporder) {$spdists{$_} = $d; $d += $nodedists{$_}}  # Distances to each subtending node of target sp
 for my $s (keys %nodelists) {  # Work back up from shared node to find total distance
  $dists{$s} = $spdists{$nodelists{$s}[-1]};
  for my $i (0 .. $#{$nodelists{$s}}-1) {$dists{$s} += $nodedists{$nodelists{$s}[$i]}}
 }
 for my $s (sort {$dists{$a} <=> $dists{$b}} keys %dists) {
  last unless $toget;
  push @out, Collect($s);
 }
 my $compose = join(',', sort @out);
 my $count = scalar @out;
 $compose = "$count\t$compose";
 if ($sp =~ /[A-Z][a-z_]+/) { push @{$comps{$compose}{names}}, $sp } else { push @{$comps{$compose}{desigs}}, $sp };
}
my @lines;
for my $comp (keys %comps) {
 warn "$comp\n";
 my @sps;
 push @sps, sort(@{$comps{$comp}{names}}) if $comps{$comp}{names};
 push @sps, sort(@{$comps{$comp}{desigs}}) if $comps{$comp}{desigs};
 my $splist = join(',', @sps);
 my $line = join("\t", ($sps[0], $comp, $splist));
 push @lines, $line;
}

for (sort @lines) {print OUT "$_\n"}

close OUT;
sub Collect {
 my ($sp, @gnms) = @_;
 my $target = (sort{$a <=> $b} $limit, $toget)[0];
 for (`grep -w "$sp" orders/orders.txt | cut -f 3`) {
  chomp; push @gnms, split ",";
 }
 splice(@gnms, $target) if (scalar @gnms > $target);
 $toget -= scalar @gnms;
 return @gnms;
}
