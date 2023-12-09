import { defineConfig } from "drizzle-kit";

const connectionString = process.env.POSTGRES_URL;
if (!connectionString) {
  throw new Error("POSTGRES_URL environment variable is required");
}

export default defineConfig({
  driver: "pg",
  schema: "./src/schema.ts",
  dbCredentials: {
    connectionString,
  },
	out: "./drizzle"
});
