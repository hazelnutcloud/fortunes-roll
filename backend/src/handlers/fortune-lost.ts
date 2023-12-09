import { eventHandler } from "arkiver";
import { FORTUNES_ABI } from "../abis/fortunes";
import * as schema from "../schema";

export const onFortuneLost = eventHandler(
  {
    abi: FORTUNES_ABI,
    batchProcess: true,
    eventName: "FortuneLost",
    schema,
  },
  async (ctx) => {}
);
