import { defineConfig } from "drizzle-kit";

const connectionString = process.env.DATABASE_URL;
if (!connectionString) {
  throw new Error("DATABASE_URL environment variable is required");
}

export default defineConfig({
  driver: "pg",
  schema: "./src/schema.ts",
  dbCredentials: {
    connectionString,
  },
	out: "./db"
});
