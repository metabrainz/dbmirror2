#!/usr/bin/env perl

# This file is part of MusicBrainz, the open internet music database.
# Copyright (C) 2021 MetaBrainz Foundation
# Licensed under the GPL version 2, or (at your option) any later version:
# http://www.gnu.org/licenses/gpl-2.0.txt

use strict;
use warnings;

use DBI;
use Getopt::Long;
use JSON::XS;

my $database = '';
my $username = '';

GetOptions(
    'database=s' => \$database,
    'username=s' => \$username,
);

die 'database not specified' unless $database;
die 'username not specified' unless $username;

my $dbh = DBI->connect("dbi:Pg:dbname=$database", $username, '', {
    AutoCommit => 0,
    RaiseError => 1,
});

my $json = JSON::XS->new->allow_nonref;

sub get_columns_and_values {
    my $data = $_[0];

    return unless defined $data;

    my @columns = sort { $a cmp $b } keys %{$data};

    my @values = map {
        my $value = $data->{$_};
        ref($value) ? $json->encode($value) : $value;
    } @columns;

    return (\@columns, \@values);
}

$dbh->do(q{
    DECLARE csr1 CURSOR WITH HOLD FOR
     SELECT xid
       FROM dbmirror2.pending_data
      GROUP BY xid
      ORDER BY max(seqid)
});
$dbh->commit;

my $sth_cursor = $dbh->prepare('FETCH 100 FROM csr1');

my $sth_pending = $dbh->prepare(q{
    SELECT pd.seqid, pd.tablename, pd.op, pd.olddata, pd.newdata, pk.keys
      FROM dbmirror2.pending_data pd
      JOIN dbmirror2.pending_keys pk ON pk.tablename = pd.tablename
     WHERE pd.xid = ?
     ORDER BY pd.seqid ASC
});

my $sth_delete_xid = $dbh->prepare(
    'DELETE FROM dbmirror2.pending_data WHERE xid = ?');

my $sth_table_exists = $dbh->prepare(
    'SELECT 1 FROM pg_catalog.pg_class WHERE oid = ?::regclass');

while (1) {
    $sth_cursor->execute;
    last unless $sth_cursor->rows;

    while (my $row1 = $sth_cursor->fetchrow_hashref) {
        $dbh->do('SET TRANSACTION ISOLATION LEVEL SERIALIZABLE');
        $dbh->do('SET CONSTRAINTS ALL DEFERRED');

        $sth_pending->execute($row1->{xid});

        while (my $row2 = $sth_pending->fetchrow_arrayref) {
            my ($seq_id, $table_name, $op, $old_data_json, $new_data_json, $keys) = @{$row2};

            my $old_data = defined $old_data_json ? $json->decode($old_data_json) : undef;
            my $new_data = defined $new_data_json ? $json->decode($new_data_json) : undef;

            $sth_table_exists->execute($table_name);
            my ($table_exists) = @{ $sth_table_exists->fetchrow_arrayref // [] };
            unless ($table_exists) {
                print 'Warning: ';
                next;
            }

            my ($old_columns, $old_values) = get_columns_and_values($old_data);
            my ($new_columns, $new_values) = get_columns_and_values($new_data);

            if ($op eq 'i') {
                my $columns = join q(, ),
                    map { $dbh->quote_identifier($_) } @$new_columns;
                my $placholders = join q(, ), (('?') x @$new_columns);

                $dbh->do(
                    "INSERT INTO $table_name ($columns) VALUES ($placholders)",
                    undef,
                    @$new_values,
                );

                next;
            }

            my $conditions = join ' AND ',
                map { $dbh->quote_identifier($_) . ' = ?' }
                @$keys;
            my @key_data = map { $old_data->{$_} } @$keys;

            if ($op eq 'u') {
                my $updates = join q(, ),
                    map { $dbh->quote_identifier($_) . ' = ?' }
                    @$new_columns;

                $dbh->do(
                    "UPDATE $table_name SET $updates WHERE $conditions",
                    undef,
                    @$new_values,
                    @key_data,
                );

            } elsif ($op eq 'd') {
                $dbh->do(
                    "DELETE FROM $table_name WHERE $conditions",
                    undef,
                    @key_data,
                );
            }
        }

        $sth_delete_xid->execute($row1->{xid});
        $dbh->commit;
    }
}

$dbh->do('CLOSE csr1');
$sth_table_exists->finish;
$sth_delete_xid->finish;
$sth_pending->finish;
$sth_cursor->finish;
$dbh->disconnect;
