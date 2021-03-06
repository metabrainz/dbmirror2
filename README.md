# dbmirror2

dbmirror is the foundation for MusicBrainz's [Live Data Feed](https://wiki.musicbrainz.org/Live_Data_Feed).  dbmirror2 is a rewrite of dbmirror in PL/pgSQL, offering the following improvements:

 * It logs operations inside cascading triggers in the correct order, so that [replication can't unexpectedly break](https://blog.metabrainz.org/2017/06/06/broken-replication-packet-fix-104949/).
 * It's written in a safe language that's easier to maintain.  The old dbmirror is 800 lines of C, a language with a lot of foot-guns attached, and tends to break with major PG upgrades (see [here](https://github.com/metabrainz/dbmirror/commit/11cbed1326a93f9934216f1cdacbdcb0687c6765) or [here](https://github.com/metabrainz/dbmirror/commit/d5bd9b63220a8da0a5df3349c8fef68e3830a66f) or [here](https://github.com/metabrainz/dbmirror/commit/070c69d523dc288067b118396ee3b7d88a6a4cbe) or [here](https://github.com/metabrainz/dbmirror/commit/f3db6336fb904605db62347580be134cc871c989) or [here](https://github.com/metabrainz/dbmirror/commit/6fdaf3c010c08186ecc49567f85cb0ef3fbced74)).
 * It stores pending data as JSON.  Any modern language has a JSON parser in the standard library.  The old dbmirror stores data in an ill-defined custom text format that must be parsed by hand.  This parsing must be re-implemented in each project or language.
 * It stores the entire row in all cases.  For updates, both the old and new versions of the row are stored.  The old dbmirror is inconsistent about what data is stored depending on whether a 'verbose' parameter is passed in, and doesn't store the old row for updates.

dbmirror2 makes it easier for projects to ingest and work with replication packets.  In musicbrainz-server, such projects include our JSON dumps and sitemaps code, but we can also envision a way to re-architecture projects like sir, which currently rely on a large number of triggers pushing changes to rabbitmq.  Instead, imagine sir simply looping over a mirror of the `dbmirror2.pending_data` table -- no additional database-wide triggers needed.

For setup information, see [INSTALL.md](INSTALL.md).

## Benchmark

The performance difference has been observed to be negligible compared to pending.c:

```
$ lscpu | grep -F Model
Model name:                      AMD Ryzen 5 2600 Six-Core Processor
Model:                           8
$ ./benchmark/run_benchmark.sh
Old (dbmirror):

real    0m1.806s
user    0m3.362s
sys     0m2.841s

New (dbmirror2):

real    0m1.928s
user    0m3.315s
sys     0m2.907s
```
