import { pgTable, text, real, integer } from "drizzle-orm/pg-core";
import crypto from "node:crypto";

export const player = pgTable("player", {
  id: text("id")
    .$defaultFn(() => `player_${crypto.randomUUID()}`)
    .primaryKey(),
  address: text("address").notNull().unique(),
  ensName: text("ens_name"),
  score: real("score").default(0),
  deposit: real("deposit").default(0),
  rolls: integer("rolls").default(0),
  rollsRemaining: integer("rolls_remaining").default(0),
});
