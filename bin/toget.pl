use strict; use warnings;
die "perl $0 old-gnms-file new-gtdb-folder\n" unless @ARGV == 2;
my ($gnmsfile, $gtdbfolder) = @ARGV;
my (%gnms, %qs, %toget, %spp, $tot);
for (`cut -f 1,3 $gnmsfile`) {chomp; my ($gnm, $dir) = split "\t"; $gnms{$gnm} = $dir}
for (`grep -v '^Repre' $gtdbfolder/sp_clusters_*.tsv | cut -f 2,10`) {
 my ($ct, @miss) = (0);
 chomp; my ($sp, $list) = split "\t";
 $sp =~ s/s__(\S+) (\S+)/${1}__$2/;
 for (split ',', $list) {die "$list\n" unless /_(\d{9})\./; $spp{$sp}{ct} ++; $toget{$sp}{$1} ++ unless $gnms{$1};}
}
Getmeta();
open OUT, ">neededgnms.txt";
for my $sp (keys %toget) {
 next if $spp{$sp}{ct} - scalar(keys %{$toget{$sp}}) >= 500;
 if ($spp{$sp}{ct} >=500) {
  my @order = sort {$qs{$b}[0] <=> $qs{$a}[0] || $qs{$a}[1] <=> $qs{$b}[1]} keys %{$toget{$sp}};
  my $n = scalar(@order);
  for my $i (500 + $n - $spp{$sp}{ct} .. $n-1) {delete $toget{$sp}{$order[$i]}}
 }
 for (sort keys %{$toget{$sp}}) {print OUT "$_\n"}
}
close OUT;

sub Getmeta {
 my %cats = qw/accession 1 gtdb_taxonomy 1 mimag_high_quality 1 mimag_medium_quality 1 scaffold_count 1/;
 #$sp =~ /(.*)__(.*)/;
 #my $name = ";s__$1 $2";
 for my $file (glob "$gtdbfolder/*_metadata_*tsv") {
  my ($ct, %key) = (0);
  open IN, $file || die "Can’t open $file\n";
  my $head = <IN>;
  chomp $head;
  for (split "\t", $head) {$key{$_} = $ct if $cats{$_}; $ct ++}
  for (<IN>) {
   chomp; my @f = split "\t";
   #$f[$key{gtdb_taxonomy}] =~ /s__(\S+) (\S+)/; my $sp = "${1}__$2"
   #next unless $f[$key{gtdb_taxonomy}] =~ /$name$/;
   my $mimag = 0;
   if ($f[$key{mimag_medium_quality}] eq 't'){$mimag = 1}
   elsif ($f[$key{mimag_high_quality}] eq 't'){$mimag = 2}
   die unless $f[$key{accession}] =~ s/.*_(\d{9})\..*/$1/;
   @{$qs{$f[$key{accession}]}} = ($mimag, $f[$key{scaffold_count}]);
  }
 }
}
