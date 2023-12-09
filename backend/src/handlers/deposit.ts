import { eventHandler } from "arkiver";
import { FORTUNES_ABI } from "../abis/fortunes";
import * as schema from "../schema";
import { mainnetClient } from "../utils/client";

export const onDeposit = eventHandler(
  {
    batchProcess: true,
    abi: FORTUNES_ABI,
    eventName: "Deposit",
    schema,
  },
  async (ctx) => {
		console.log(ctx.events)
    // const players: Record<string, typeof schema.player.$inferInsert> = {};

    // for (const deposit of ctx.events) {
    //   const { amount, player } = deposit.args;

    //   let ensName = players[player]?.ensName;

    //   if (!ensName) {
    //     ensName = await ctx.store.retrieve(`ensName:${player}`, () =>
    //       mainnetClient.getEnsName({ address: player })
    //     );
    //   }
    // }
  }
);
