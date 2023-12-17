import pino from "pino";
import { drizzle as bsqlDrizzle } from "drizzle-orm/bun-sqlite";
import { drizzle as pgDrizzle } from "drizzle-orm/postgres-js";
import { migrate } from "drizzle-orm/postgres-js/migrator";
import Database from "bun:sqlite";
import {
  BunSqliteProvider,
  arkiveMetadata,
  chainMetadata,
  childSource,
  Arkiver,
} from "arkiver";
import { manifest } from "./manifest";
import postgres from "postgres";
import * as schema from "./schema.ts";

export async function startArkiver() {
  const postgresUrl = process.env["DATABASE_URL"];
  if (!postgresUrl) throw new Error("DATABASE_URL not set.");

  const isProduction = process.env.NODE_ENV === "production";

  const logger = pino({
    transport: { target: "pino-pretty" },
    level: isProduction ? "info" : "debug",
  });

  const sqlitePath = (() => {
    if (isProduction) {
      const sqliteUrl = process.env["SQLITE_URL"];
      if (!sqliteUrl) throw new Error("SQLITE_URL not set.");
      return new URL(sqliteUrl).pathname;
    } else {
      return "arkiver.sqlite";
    }
  })();

  const sqlite = bsqlDrizzle(new Database(sqlitePath), {
    schema: { arkiveMetadata, chainMetadata, childSource },
  });
  const dbProvider = new BunSqliteProvider({ db: sqlite, logger });

  const migrateDb = pgDrizzle(postgres(postgresUrl, { max: 1 }));
  await migrate(migrateDb, { migrationsFolder: "./db" });

  const pgDb = pgDrizzle(postgres(postgresUrl), {
    schema,
  });
  const arkiver = new Arkiver({
    dbProvider,
    logger,
    manifest: manifest.manifest,
    context: { db: pgDb },
  });

  await arkiver.start();
}
