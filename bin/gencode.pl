use strict; use warnings;
# Attempts to reconcile Shulgina,Eddy,2021/GTDBr202 analysis with subsequent GTDB updates
# Presumes each species has a uniform genetic code
# Script may need revision with future GTDB updates, already had to split former g__UBA4855 into component genomes

die "Usage: $0 sp_clusters_file\nRequires a sp_clusters_XXX file from GTDB\n" unless @ARGV and -s $ARGV[0];
my $infile = $ARGV[0];
my (%codes, %excludes, %hits, %spp);
my %codons = (4 => 'UGA>W', 11 => 'standard', 25 => 'UGA>G', 34 => 'AGG>M',
 35 => 'CGG>Q', 36 => 'CGG>W', 37 => 'UGA>G,CGA>W,CGG>W');
for (qw/o__Mycoplasmatales g__Zinderia g__Stammera g__Hodgkinia g__Nasuia/) {$codes{$_}	= 4}
$codes{'o__BD1-5'} = 25;
for (qw/900549915 002404995 002297045/) {$codes{$_} = 34}
$codes{g__Peptacetobacter} = 35;
for (qw/g__Anaerococcus 900540395 900754135 004558005 900540365 002399785 900545015/) {$codes{$_} = 36}
$codes{o__Absconditabacterales}	= 37;
for (qw/f__UBA3375 002451465/) {$codes{$_} = 11; $excludes{$_} ++}

for my $line (`cut -f 2,3,10 $infile`) {
#for (`grep -v '^Repre' ../gtdb/sp_* | cut -f 2,3,10`) {
 for my $term (keys %codes) {
  if ($line =~ /$term/) {
   my $pass = 1;
   for (keys %excludes) {next unless $line =~ /$_/; $hits{$_} ++; $pass = 0}
   next unless $pass;
   $hits{$term} ++;
   chomp $line;
   $line =~ s/^s__(\S+) (\S+)/${1}__$2/;
   $line =~ s/GB_GCA_([0-9]{9})\.\d+/$1/g;
   $line =~ s/RS_GCF_([0-9]{9})\.\d+/$1/g;
   push @{$spp{$codes{$term}}{$term}}, "$line\t$codes{$term}\n";
   last
  }
 }
}
warn "Genetic code analysis by $0\n";
open OUT, ">genetic_code_odd";
for my $code (sort {$a <=> $b} keys %spp) {
 warn "\nGencode $code: $codons{$code}\n";
 for my $term (sort {scalar(@{$spp{$code}{$b}}) <=> scalar(@{$spp{$code}{$a}})} keys %{$spp{$code}}) {
  print OUT join('', @{$spp{$code}{$term}});
  warn "$term\t", scalar (@{$spp{$code}{$term}}), " species\n";
 }
}
close OUT;
warn "\nNotes\n";

for my $term (keys %codes) {
 next if $hits{$term} or $term !~ /[a-z]/;  # Some genome ID searches may be prevented by conspecifics
 if ($term =~ /(Hodgkinia|Nasuia)/) {
  warn "Didn't find taxon $term (code $codes{$term}: $codons{$codes{$term}}), as expected from GTDB's exclusion of such small genomes\n"
 } else {
  warn "**WARNING** Former taxon $term (code $codes{$term}: $codons{$codes{$term}}) not found, may have been revised - search manually?\n" unless $hits{$term}
 }
}
warn "\nGenetic code analysis complete\n\n";

__END__
Analysis of GTDB r202 from "A computational screen for alternative genetic codes in over 250,000 genomes" (Shulgina/Eddy,2021)

All tested genera use the standard code 11, except
4  UGA>W : o__Mycoplasmatales(except f__UBA3375), g__Zinderia, g__Stammera, g__Hodgkinia, g__Nasuia
25 UGA>G : o__BD1-5
34 AGG>M : sp900549915,sp002404995,sp002297045 (but not others in g__UBA7642)
35 CGG>Q : g__Peptacetobacter
36 CGG>W : g__Anaerococcus, g__UBA4855(except sp002451465)
37 UGA>G,CGA>W,CGG>W : o__Absconditabacterales
Note: Hodgkinia, Nasuia not (yet) treated by GTDB, too short

