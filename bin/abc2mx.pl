my %scos;
while (<>) {
 next unless /^(\S+)\t(\S+)\t(\S+)/;
 my ($i, $j) = sort ($1, $2);
 next if $scos{$i}{$j};
 $scos{$i}{$j} = $3;
}
#die "$scos{'000018625'}{'000756465'}\n";
my @order;
for my $i (sort keys %scos) {
 print $i;
 for (@order) {if (defined $scos{$_}{$i}) {print "\t$scos{$_}{$i}"} else {print "\t1"}}
 print "\n";
 push @order, $i;
}
