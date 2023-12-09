import { eventHandler } from "arkiver";
import { FORTUNES_ABI } from "../abis/fortunes";
import * as schema from "../schema";
import { sql } from "drizzle-orm";
import { formatUnits } from "viem";

export const onFortuneLost = eventHandler(
  {
    abi: FORTUNES_ABI,
    batchProcess: true,
    eventName: "FortuneLost",
    schema,
  },
  async (ctx) => {
    const players: Record<string, typeof schema.player.$inferInsert> = {};

    for (const fortuneLoss of ctx.events) {
      const { fortuneLost, player } = fortuneLoss.args;

      const parsedAmount = -parseFloat(formatUnits(fortuneLost, 6));

      if (players[player]) {
        players[player].score = (players[player].score ?? 0) + parsedAmount;
      } else {
        players[player] = {
          address: player,
          score: parsedAmount,
        };
      }
    }

    await ctx.db
      .insert(schema.player)
      .values(Object.values(players))
      .onConflictDoUpdate({
        target: [schema.player.address],
        set: {
          score: sql`${schema.player.score} + excluded.score`,
        },
      });

    ctx.logger.info(`Upserted ${Object.values(players).length} players`);
  }
);
