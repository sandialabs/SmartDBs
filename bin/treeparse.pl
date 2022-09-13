use strict; use warnings;
die "perl $0 new-gtdb-folder\n" unless @ARGV == 1;
my ($gtdbfolder) = @ARGV;
my ($serial, %leafs, %nodes, %treefiles) = (1);
for my $div (qw/bac ar/) {for (`ls $gtdbfolder/$div*sp_labels.tree`) {chomp; $treefiles{$div} = $_}}
for my $tree (`cat $treefiles{bac} $treefiles{ar}`) {
#for my $tree (`cat $gtdbfolder/*.sp_labels.tree`) {
# die "hi\n";
 chomp $tree; $tree =~ s/;$//;
 while ($tree =~ s/\'s__(\S+) ([^\']+)\':([^\(\),:]+)/!$serial/) {
  my ($label, $dist) = ("${1}__$2", $3);
  $nodes{$serial}{dist} = $dist;
  push @{$nodes{$serial}{members}}, $label;
  $serial ++;
 }
 while ($tree =~ s/\(!(\d+),!(\d+)\)([^,\)]+)/!$serial/) {
  #print "$serial $1 $2 $3\n";
  my ($l, $r, $info) = ($1, $2, $3);
  for (@{$nodes{$l}{members}}, @{$nodes{$r}{members}}) {push @{$nodes{$serial}{members}}, $_}
  if ($info =~ /^\'([\d\.]+):([^\']+)\':(.+)/) {
   @{$nodes{$serial}}{qw/dist supp label/} = ($3, $1, $2)
  }
  elsif ($info =~ /^([\d\.]+):(.+)/) {
   @{$nodes{$serial}}{qw/dist supp/} = ($2, $1)
  }
  else {$nodes{$serial}{label} = $info}
  $serial ++;
 }
 #die "$tree\n$serial\n";
 #last
}
open OUT, ">nodedists";
for my $i (sort {$a <=> $b} keys %nodes) {
 for (qw/dist supp label/) {$nodes{$i}{$_} = '' unless defined $nodes{$i}{$_}}
 print OUT join("\t", $i, @{$nodes{$i}}{qw/dist supp label/}), "\n";
 #die "$i\n" unless @{$nodes{$i}{members}};
 for (@{$nodes{$i}{members}}) {push @{$leafs{$_}}, $i}
}
close OUT;
open OUT, ">nodelists";
for my $leaf (sort keys %leafs) {print OUT join("\t", $leaf, @{$leafs{$leaf}}), "\n"}
close OUT;
