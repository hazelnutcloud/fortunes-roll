import { eventHandler } from "arkiver";
import { FORTUNES_ABI } from "../abis/fortunes";
import * as schema from "../schema";
import { formatUnits } from "viem";
import { sql } from "drizzle-orm";

export const onWithdraw = eventHandler(
  {
    abi: FORTUNES_ABI,
    batchProcess: true,
    eventName: "Withdraw",
    schema,
  },
  async (ctx) => {
    const players: Record<string, typeof schema.player.$inferInsert> = {};

    for (const withdrawal of ctx.events) {
      const { amount, player } = withdrawal.args;

      const parsedAmount = -parseFloat(formatUnits(amount, 18));

      if (players[player]) {
        players[player].deposit = (players[player].deposit ?? 0) + parsedAmount;
      } else {
        players[player] = {
          address: player,
          deposit: parsedAmount,
        };
      }
    }

    await ctx.db
      .insert(schema.player)
      .values(Object.values(players))
      .onConflictDoUpdate({
        target: [schema.player.address],
        set: {
          deposit: sql`${schema.player.deposit} + excluded.deposit`,
        },
      });

    ctx.logger.info(`Upserted ${Object.values(players).length} players`);
  }
);
