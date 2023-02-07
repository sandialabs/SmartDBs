#!/usr/bin/perl
use strict; use warnings;
use File::Spec; use Cwd;
# maps genome to GTDB species, perhaps failing (ND), partially so (closest ND:x or transitive TR:x), or detecting gross cross-genus mixture (MIX:x|y)
# currently misses ~150 of 173652 vs GTDBr202 (remeasure)
# retry mash at d=.29 if d=.1 fails; some genomes (001255495) get mash >0.1 but ani >95% !

die "Usage: perl $0 query_genome_file outfolder smartDB_gtdb_folder genome_assembly_repository_folder [genomeid]\n" unless @ARGV > 3;
my ($gfile, $outdir, $projdir, $repo, $genomeid) = @ARGV;
for ($gfile, $outdir, $projdir, $repo) {$_ = File::Spec->rel2abs($_)}
mkdir $outdir; chdir $outdir;
$genomeid = $gfile unless $genomeid;
open LOG, ">log";
Run("mash dist -d 0.1  $projdir/reps.msh $gfile | sort -k3,3n > mash", 'mash');
Run("mash dist -d 0.29 $projdir/reps.msh $gfile | sort -k3,3n > mash", '') unless -s 'mash';  # Genome 001255495 gets mash >0.1 but ani>95%!

open OUT, ">cands";
my ($top, $call, $extra, %ani, %in, @out, %cands, $sum) = ('', '', '');
my @sim = ('', '', '');
my %cts = (mash => 0, in => 0);
for (`cat mash`) {
 $cts{mash} ++;
 my @f = split "\t"; 
 $f[4] =~ /^(\d+)/;
 my $hashct = $1;
 my $sp;
 for (`grep "$f[0]" $projdir/reflist.txt`) {
  my @t = split "\t";
  $sp = $t[1];
 }
 @{$ani{$sp}}{qw/mash hashct entry in/} = (sprintf("%.5f", 100 * (1-$f[2])), $hashct, '', 0);
 die unless $f[0] =~ /(\d{3})(\d{3})(\d{3})/;
 my $repfile = "$repo/$1/$2/$3/genome.fa";
 print OUT "$repfile\n";
 $cands{$repfile} = $sp;
 print LOG "$sp file = $repfile\n";
}
close OUT;
print LOG scalar(keys %cands), " candidates from Mash\n";
Run("fastANI -q $gfile --rl cands -o q.reps &> q.reps.log", 'q.reps');
Run("fastANI -r $gfile --ql cands -o reps.q &> reps.q.log", 'reps.q');
if (-f 'q.reps') {for (`cat q.reps`) {/\t(\S+)/; Load($1, $_)}}
if (-f 'reps.q') {for (`cat reps.q`) { /^(\S+)/; Load($1, $_)}}
for (`cat $projdir/reflist.txt`) {
 chomp; my @f = split "\t"; next unless $ani{$f[1]}; $f[2] =~ s/\.*0+$//; $ani{$f[1]}{circ} = $f[2]
}
for my $r (keys %ani) {
 @{$ani{$r}}{qw/ani af/} = (0,0) unless $ani{$r}{ani};
 $ani{$r}{entry} = sprintf "%.4f", $ani{$r}{ani} - $ani{$r}{circ};  # Entry into rep's circumference rather than closeness to rep
}
open OUT, ">sum"; print OUT join("\t", qw/Representative ANI AF Circumf Penetration Mash HashCt In/), "\n";
for my $r (sort {$ani{$b}{ani} <=> $ani{$a}{ani} || $ani{$b}{mash} <=> $ani{$a}{mash}} keys %ani) {
 unless ($top) {$top = $r; @sim = @{$ani{$r}}{qw/ani af circ/}}
 if ($ani{$r}{af} >= 50 and $ani{$r}{entry} >= 0) {
  $cts{in} ++;
  $ani{$r}{in} = 'in';
  ($call, @sim) = ($r, @{$ani{$r}}{qw/ani af circ/}) unless %in;
  $r =~ /(\S+)__/;
  my $genus = $1;
  @{$in{$genus}} = ($ani{$r}{ani}, $r) unless $in{$genus}[0] and $in{$genus}[0] >= $ani{$r}{ani};
 } else {@out = ($ani{$r}{ani}, $r) unless @out and $out[0] >= $ani{$r}{ani}}
 print OUT join("\t", $r, @{$ani{$r}}{qw/ani af circ entry mash hashct in/}), "\n";
}
close OUT;
if (scalar keys %in == 1) {$extra = "TR:$out[1]" if $out[0] and $out[0] > $ani{$top}{ani}}
elsif (scalar keys %in > 1) {my @mix; for (keys %in) {push @mix, $in{$_}[1]} $extra = "MIX:" . join('|', @mix)}
else {$extra = 'ND:'; $call = $top if $top}
my $gencode = 11;
for (`grep -w $call $projdir/genetic_code_odd | cut -f 4`) {chomp; $gencode = $_}
open OUT, ">species";
print OUT join("\n", 
 "query genome = $genomeid",
 "species call = $call",
 "genetic code =  $gencode",
 "smartDB folder = $projdir", 
 "note = $extra",
 "Average Nucleotide Identity to species representative = $sim[0]",
 "Alignment Fraction = $sim[1]",
 "species circumference from GTDB = $sim[2]",
 "species hit by Mash = $cts{mash}",
 "species falling within GTDB circumferences (see 'sum' file) = $cts{in}"
), "\n";
close OUT;

sub Run {
 my ($job, $chkfile) = @_;
 if ($chkfile and -f $chkfile) {print LOG "Found checkfile $chkfile; not running $job\n"}
 else {print LOG "Running $job\n"; system $job}
}
sub Load {
 my ($repfile, $line) = ($_[0], $_[1]);
 my $sp = $cands{$repfile}; 
 die "No species for $repfile\n$line\n" unless $sp;
 chomp $line;
 my @f = split "\t", $line;
 my $af = sprintf "%.2f", 100*$f[3]/$f[4];
 print LOG "Loading species $sp: ani=$f[2], af=$af\n";
 $ani{$sp}{ani} = $f[2] unless $ani{$sp}{ani} and $ani{$sp}{ani} >= $f[2];
 $ani{$sp}{af}  = $af   unless $ani{$sp}{af}  and $ani{$sp}{af} >= $af;
}
