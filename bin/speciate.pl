#!/usr/bin/perl
use strict; use warnings;
# maps genome to GTDB species, perhaps failing (ND), partially so (closest ND:x or transitive TR:x), or detecting gross cross-genus mixture (MIX:x|y)
# currently misses ~150 of 173652 vs GTDB (remeasure)
# new: retry mash at d=.29 if d=.1 fails; some genomes (001255495) get mash >0.1 but ani >95% !


die "Usage: perl $0 gnmfile outfolder [genomeid]\n" unless @ARGV > 1;
use File::Spec;
use Cwd;
my $projdir = getcwd();
my $gfile = File::Spec->rel2abs($ARGV[0]);
mkdir $ARGV[1]; chdir $ARGV[1];

$gfile =~ /([^\/]+)$/;
my $base = $1;
my $genomeid = $base; $genomeid = $ARGV[2] if $ARGV[2];
#mkdir "$outdir/$base";
#chdir "$projdir/species/$base";

unless (-f 'mash') {
 `mash dist -d 0.1 $projdir/reps.msh $gfile | sort -k3,3n > mash`;
 `mash dist -d 0.29 $projdir/reps.msh $gfile | sort -k3,3n > mash` unless -s 'mash';  # Genome 001255495 gets mash >0.1 but ani>95%!
}
open OUT, ">cands";
my ($top, $call, $extra, $sim, %ani, %in, @out, %cands, $sum) = ('', '', '', "\t\t");
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
 $cands{$f[0]} = $sp;
 @{$ani{$sp}}{qw/mash hashct entry in/} = (sprintf("%.5f", 100 * (1-$f[2])), $hashct, '', 0);
 print OUT "$projdir/$1/$2/$3/genome.fa\n";
}
close OUT;
`fastANI -q $gfile --rl cands -o q.reps &> /dev/null` unless -f 'q.reps';
`fastANI -r $gfile --ql cands -o reps.q &> /dev/null` unless -f 'reps.q';
if (-f 'q.reps') {for (`cat q.reps`) {/\t\S+\/(\S+)/; Load($1, $_)}}
if (-f 'reps.q') {for (`cat reps.q`) { /^\S+\/(\S+)/; Load($1, $_)}}
for (`cat $projdir/reflist.txt`) {chomp; my @f = split "\t"; next unless $ani{$f[1]}; $f[2] =~ s/\.*0+$//; $ani{$f[1]}{circ} = $f[2]}
for my $r (keys %ani) {
 @{$ani{$r}}{qw/ani af/} = (0,0) unless $ani{$r}{ani};
 $ani{$r}{entry} = sprintf "%.4f", $ani{$r}{ani} - $ani{$r}{circ};  # Entry into rep's circumference rather than closeness to rep
}
open OUT, ">sum";
for my $r (sort {$ani{$b}{ani} <=> $ani{$a}{ani} || $ani{$b}{mash} <=> $ani{$a}{mash}} keys %ani) {
 unless ($top) {$top = $r; $sim = join("\t", @{$ani{$r}}{qw/ani af circ/})}
 if ($ani{$r}{af} >= 50 and $ani{$r}{entry} >= 0) {
  $cts{in} ++;
  $ani{$r}{in} = 'in';
  ($call, $sim) = ($r, join("\t", @{$ani{$r}}{qw/ani af circ/})) unless %in;
  $r =~ /(\S+)__/;
  my $genus = $1;
  @{$in{$genus}} = ($ani{$r}{ani}, $r) unless $in{$genus}[0] and $in{$genus}[0] >= $ani{$r}{ani};
 } else {@out = ($ani{$r}{ani}, $r) unless @out and $out[0] >= $ani{$r}{ani}}
 print OUT join("\t", $r, @{$ani{$r}}{qw/ani af circ entry mash hashct in/}), "\n";
}
close OUT;
if (scalar keys %in == 1) {$extra = "TR:$out[1]" if $out[0] and $out[0] > $ani{$top}{ani}}
elsif (scalar keys %in > 1) {my @mix; for (keys %in) {push @mix, $in{$_}[1]} $extra = "MIX:" . join('|', @mix)}
else {$extra = 'ND'; $call = $top if $top}
open OUT, ">species"; print OUT join("\t", $genomeid, $call, $extra, $sim, $cts{mash}, $cts{in}), "\n"; close OUT;

sub Load {
 my ($g, $l) = ($cands{$_[0]}, $_[1]);
 chomp $l;
 my @f = split "\t", $l;
 my $af = sprintf "%.2f", 100*$f[3]/$f[4];
 $ani{$g}{ani} = $f[2] unless $ani{$g}{ani} and $ani{$g}{ani} >= $f[2];
 $ani{$g}{af}  = $af   unless $ani{$g}{af}  and $ani{$g}{af} >= $af;
}
