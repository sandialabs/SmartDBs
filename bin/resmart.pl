use strict; use warnings;
use Parallel::ForkManager;

my $forks = shift;
my $pm = Parallel::ForkManager->new($forks);
my %comps;

$pm->run_on_finish( sub {
 my ($pid, $exit_code, $ident, $exit_signal, $core_dump, $data) = @_;
 push @{$comps{$data->{comp}}}, $data->{sp};
});

for my $line (`cat smarts500`) {
 my $pid = $pm->start and next;
 chomp $line;
 $line =~ /^(\S+)\t(.*)/;
 my ($sp, $comp) = ($1, $2);
 $pm->finish(0, {comp => $comp, sp => $sp});
}
for my $comp (sort keys %comps) {
 my (@names, @desigs);
 for (@{$comps{$comp}}) {if (/^[A-Z][a-z_]+$/) {push @names, $_} else {push @desigs, $_}}
 delete $comps{$comp};
 for my $sp (sort(@names), sort(@desigs)) { my $pid = $pm->start and next; $pm->finish(0, {comp => $comp, sp => $sp}); }
}
open OUT, ">smartsUniq500";
for my $comp (sort {$comps{$a}[0] cmp $comps{$b}[0]} keys %comps) {
 print OUT join("\t", $comps{$comp}[0], $comp, join(',', @{$comps{$comp}})) . "\n";
}
close OUT;
