CREATE TABLE IF NOT EXISTS "signs" (
	`id`	INTEGER PRIMARY KEY,
	`X` INTEGER,
	`Y` INTEGER,
	`Z` INTEGER,
	`World` TEXT,
	`Player_name` TEXT
);

CREATE TABLE IF NOT EXISTS "marker" (
	`id`	INTEGER PRIMARY KEY,
	`X` INTEGER,
	`Y` INTEGER,
	`Z` INTEGER,
	`World` TEXT,
	`Player_name` TEXT
);

CREATE TABLE IF NOT EXISTS "temptable" (
	`id`	INTEGER PRIMARY KEY,
	`X` INTEGER,
	`Y` INTEGER,
	`Z` INTEGER,
	`World` TEXT,
	`Player_name` TEXT
);

INSERT INTO "temptable" SELECT DISTINCT * FROM "signs" GROUP BY `id`;

DROP TABLE "signs";

CREATE TABLE IF NOT EXISTS "signs" (
	`id`	INTEGER PRIMARY KEY,
	`X` INTEGER,
	`Y` INTEGER,
	`Z` INTEGER,
	`World` TEXT,
	`Player_name` TEXT
);

INSERT INTO "signs" SELECT * FROM "temptable";

DROP TABLE "temptable";

CREATE TABLE IF NOT EXISTS "temptable" (
	`id`	INTEGER PRIMARY KEY,
	`X` INTEGER,
	`Y` INTEGER,
	`Z` INTEGER,
	`World` TEXT,
	`Player_name` TEXT
);

INSERT INTO "temptable" SELECT DISTINCT * FROM "marker" GROUP BY `id`;

DROP TABLE "marker";

CREATE TABLE IF NOT EXISTS "marker" (
	`id`	INTEGER PRIMARY KEY,
	`X` INTEGER,
	`Y` INTEGER,
	`Z` INTEGER,
	`World` TEXT,
	`Player_name` TEXT
);

INSERT INTO "marker" SELECT * FROM "temptable";

DROP TABLE "temptable"
