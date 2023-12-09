CREATE TABLE IF NOT EXISTS "player" (
	"id" text PRIMARY KEY NOT NULL,
	"address" text NOT NULL,
	"ens_name" text,
	"score" real,
	"deposit" real,
	"rolls" integer,
	"rolls_remaining" integer
);
