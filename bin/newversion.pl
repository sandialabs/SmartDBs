use strict; use warnings;

my $dir = $ARGV[0];
my @files = glob "$dir/GCA_[0-9]*[0-9]_genomic.fna.gz";
exit unless @files > 1;
my @top;
for (@files) {
 warn "No version number found for $_\n" unless /^$dir\/GCA_\d+\.(\d+)/;
 @top = ($1, $_) unless $top[0] and $top[0] > $1;
}
for (@files) {unlink $_ unless $_ eq $top[1]}
