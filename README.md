# MusicBrainz MySQL

MusicBrainz                |  MySQL
:-------------------------:|:-------------------------:
![MusicBrainz](https://raw.githubusercontent.com/mikeblum/musicbrainz-mysql/master/images/MusicBrainz_Logo.png)  |  ![MySQL](https://raw.githubusercontent.com/mikeblum/musicbrainz-mysql/master/images/logo-mysql-170x115.png)


## Overview

Since the canonical MusicBrainz database only works on PostgresQL currently, I've taken the inititive of making MusicBrainz run on MySQL.

## Deploying MusicBrainz to MySQL

Tested on MySQL 5.7 

Download a copy for your respective OS here: [Download MySQL](https://www.mysql.com/downloads/) if you haven't already.

1. Download a dump of the MusicBrainz database here: [MusicBrainz Dump](http://ftp.musicbrainz.org/pub/musicbrainz/data/fullexport/). Grab a :coffee:, this will take a while.
2. Explode it into its `mbdump` directory.
3. Create the MusicBrainz database first:
	`mysql -u root --password={{ root password }} < MySQLCreateMusicBrainzTables.sql`
4. Import the MusicBrianz data into your freshly created database and tables.
	`mysqlimport -u root --password={{ root password }} musicbrainz {{ path to mbdump}}/mbdump/*`

There are millions of rows so grab another cup of :coffeee:. This will take a while as well.

## Differences between Postgres and MySQL

There are a few differences between Postgres and MySQL that made the original CreateTables.sql (found [here](https://github.com/metabrainz/musicbrainz-server/blob/master/admin/sql/CreateTables.sql)) script incompatible with MySQL.

Use your favorite `diff` tool  - I'm partial to [meld]() to see the transition from postgresql to mysql:

`meld CreateTables.sql MySQLCreateMusicBrainzTables.sql`

1\. Comments in MySQL need a space between -- and it's text:

```diff
- CREATE TABLE area_alias ( -- replicate (verbose)
-    id                  SERIAL, --PK
+ CREATE TABLE IF NOT EXISTS area_alias ( -- replicate (verbose)
+    id                  SERIAL, -- PK
```

2\. UUIDs aren't supported in MySQL

```diff
- CREATE TABLE area_gid_redirect ( -- replicate (verbose)
-    gid                 UUID NOT NULL, -- PK
+ CREATE TABLE IF NOT EXISTS area_gid_redirect ( -- replicate (verbose)
+    gid                 CHAR(36) NOT NULL, -- PK
```

3\. `release` is a reserved word in MySQL

The full list can be found here: [MySQL 5.7 Reserved Words](https://dev.mysql.com/doc/refman/5.7/en/keywords.html) 

These columns are escaped with a back-tick (`) like this:

```diff
CREATE TABLE cdtoc_raw ( -- replicate
    id                  SERIAL, -- PK
-     release             INTEGER NOT NULL, -- references release_raw.id
    discid              CHAR(28) NOT NULL,
    track_count          INTEGER NOT NULL,
    leadout_offset       INTEGER NOT NULL,
    track_offset         INTEGER[] NOT NULL
);

CREATE TABLE IF NOT EXISTS cdtoc_raw ( -- replicate
    id                      SERIAL, -- PK
+    `release`               INTEGER NOT NULL, -- references release_raw.id
    discid                  CHAR(28) NOT NULL,
    track_count             INTEGER NOT NULL,
    leadout_offset          INTEGER NOT NULL,
    track_offset            JSON NOT NULL
);
```

4\. Timestamps in MySQL are different

```diff
- last_updated        TIMESTAMP WITH TIME ZONE DEFAULT NOW()
+ last_updated        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
```

5\. Geo points and `cube` are difficult in MySQL

Copped out and put these troublesome columns into `VARCHAR`

6\. Custom TYPES aren't supported in MySQL

Most of these are `enums` so we can do something like this:

```diff
- CREATE TYPE cover_art_presence AS ENUM ('absent', 'present', 'darkened');
CREATE TABLE release_meta ( -- replicate (verbose)
    id                  INTEGER NOT NULL, -- PK, references release.id CASCADE
    date_added          TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    info_url            VARCHAR(255),
    amazon_asin         VARCHAR(10),
    amazon_store        VARCHAR(20),
+    cover_art_presence  cover_art_presence NOT NULL DEFAULT 'absent'
);
```

7\. CJK support

Unfortunantly the default table encoding is `latin1` and the collation is set to `latin1_swedish_ci` which makes a hash of Chinese, Japanese, and Korean (CJK). Setting each table to support UTF-8 is as easy as adding:

```diff
CREATE TABLE IF NOT EXISTS artist_meta ( -- replicate
    id                  INTEGER NOT NULL, -- PK, references artist.id CASCADE
    rating              SMALLINT CHECK (rating >= 0 AND rating <= 100),
    rating_count        INTEGER
-);
CREATE TABLE IF NOT EXISTS artist_meta ( -- replicate
    id                  INTEGER NOT NULL, -- PK, references artist.id CASCADE
    rating              SMALLINT CHECK (rating >= 0 AND rating <= 100),
    rating_count        INTEGER
+ ) CHARACTER SET utf8 COLLATE utf8_general_ci;
```

to each table.

## Next Steps

* Replication - the default build of MusicBrainz offers seamless replication to PostgresQL
* Indexes - the default build of MusicBrainz creates a lucene index. I think either Solr or Elasticsearch would be good here.
* Triggers
* Stored Procedutes

## Feedback

See something that can be improved? Feel free to open a PR and I'll happily merge it in.
