import { eventHandler } from "arkiver";
import { FORTUNES_ABI } from "../abis/fortunes";
import * as schema from "../schema";

export const onWithdraw = eventHandler(
  {
    abi: FORTUNES_ABI,
    batchProcess: true,
    eventName: "Withdraw",
    schema,
  },
  async (ctx) => {}
);
