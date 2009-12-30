use strict;
use warnings FATAL => 'all';

use Test::More;
use Test::Deep;
use Test::Exception;
use t::common qw( new_dbm );

use_ok( 'DBM::Deep' );

my $max_txns = 255;

my $dbm_factory = new_dbm(
    num_txns  => $max_txns,
);
while ( my $dbm_maker = $dbm_factory->() ) {
    my @dbs = ( $dbm_maker->() );
    next unless $dbs[0]->supports('transactions');

    push @dbs, grep { $_ } map {
        eval { $dbm_maker->() }
    } 2 .. $max_txns;

    cmp_ok( scalar(@dbs), '==', $max_txns, "We could open enough DB handles" );

    my %trans_ids;
    for my $n (0 .. $#dbs) {
        lives_ok {
            $dbs[$n]->begin_work
        } "DB $n can begin_work";

        my $trans_id = $dbs[$n]->_engine->trans_id;
        ok( !exists $trans_ids{ $trans_id }, "DB $n has a unique transaction ID ($trans_id)" );
        $trans_ids{ $trans_id } = $n;
    }
}

done_testing;
