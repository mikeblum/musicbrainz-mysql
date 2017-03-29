#!/bin/bash
mysql -u root --password=root < CreateMusicBrainzDatabase.sql
mysql -u root --password=root musicbrainz < MySQLCreateMusicBrainzTables.sql
mysqlimport -u root --password=root musicbrainz /Users/mblum/Workspaces/neo4j/musicbrainz/mbdump/*
