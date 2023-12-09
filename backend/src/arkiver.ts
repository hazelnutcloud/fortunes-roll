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

const postgresUrl = process.env["POSTGRES_URL"];
if (!postgresUrl) throw new Error("POSTGRES_URL not set.");

const logger = pino({
  transport: { target: "pino-pretty" },
  level: "debug",
});

const sqlite = bsqlDrizzle(new Database("arkiver.sqlite"), {
  schema: { arkiveMetadata, chainMetadata, childSource },
});
const dbProvider = new BunSqliteProvider({ db: sqlite, logger });

const migrateDb = pgDrizzle(postgres(postgresUrl, { max: 1 }));
await migrate(migrateDb, { migrationsFolder: "./drizzle" });


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
