import { eventHandler } from "arkiver";
import { FORTUNES_ABI } from "../abis/fortunes";
import * as schema from "../schema";
import { mainnetClient } from "../utils/client";
import { formatUnits } from "viem";
import { sql } from "drizzle-orm";

export const onDeposit = eventHandler(
  {
    batchProcess: true,
    abi: FORTUNES_ABI,
    eventName: "Deposit",
    schema,
  },
  async (ctx) => {
    const players: Record<string, typeof schema.player.$inferInsert> = {};

    for (const deposit of ctx.events) {
      const { amount, player } = deposit.args;

      let ensName = players[player]?.ensName;

      if (!ensName) {
        ensName = await ctx.store.retrieve(`ensName:${player}`, () =>
          mainnetClient.getEnsName({ address: player })
        );
      }

      const parsedAmount = parseFloat(formatUnits(amount, 18));

      if (players[player]) {
        players[player].deposit = (players[player].deposit ?? 0) + parsedAmount;
      } else {
        players[player] = {
          address: player,
          ensName,
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
