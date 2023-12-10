import { eventHandler } from "arkiver";
import { FORTUNES_ABI } from "../abis/fortunes";
import * as schema from "../schema";
import { sql } from "drizzle-orm";

export const onDiceRolled = eventHandler(
  {
    abi: FORTUNES_ABI,
    batchProcess: true,
    eventName: "DiceRolled",
    schema,
  },
  async (ctx) => {
    const players: Record<string, typeof schema.player.$inferInsert> = {};

    for (const roll of ctx.events) {
      const { player, timestamp } = roll.args;

      if (players[player]) {
        players[player].rolls = (players[player].rolls ?? 0) + 1;
        players[player].lastRollTimestamp = new Date(Number(timestamp) * 1000);
      } else {
        players[player] = {
          address: player,
          rolls: 1,
          lastRollTimestamp: new Date(Number(timestamp) * 1000),
        };
      }
    }

    await ctx.db
      .insert(schema.player)
      .values(Object.values(players))
      .onConflictDoUpdate({
        target: [schema.player.address],
        set: {
          rolls: sql`${schema.player.rolls} + excluded.rolls`,
          lastRollTimestamp: sql`GREATEST(${schema.player.lastRollTimestamp}, excluded.last_roll_timestamp)`,
        },
      });

    ctx.logger.info(`Upserted ${Object.values(players).length} players`);
  }
);
