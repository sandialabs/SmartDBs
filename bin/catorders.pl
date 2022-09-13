use strict; use warnings;
use Parallel::ForkManager;

my $forks = shift;
my $pm = Parallel::ForkManager->new($forks);

open OUT, ">orders/orders.txt";

$pm->run_on_finish( sub {
 my ($pid, $exit_code, $ident, $exit_signal, $core_dump, $data) = @_;
 print OUT "$data->{line}\n";
});


for my $file (glob "orders/*/*/*") {
 my $pid = $pm->start and next;
 next unless $file =~ /\/([^\/]+)$/;
 my $sp = $1;
 my @orders;
 for(`cat $file`) {
  chomp; push @orders, $_;
 }
 my $line = join("\t", ($sp, $file, join(",", @orders)));
 $pm->finish(0, {line => $line});
}
$pm->wait_all_children;
close OUT;
