BEGIN;
CREATE USER IF NOT EXISTS 'musicbrainz'@'localhost' IDENTIFIED BY 'musicbrainz';
CREATE DATABASE IF NOT EXISTS musicbrainz;
GRANT ALL PRIVILEGES ON musicbrainz.* TO 'musicbrainz'@'%' WITH GRANT OPTION;
GRANT FILE ON *.* to 'musicbrainz'@'%';
COMMIT;