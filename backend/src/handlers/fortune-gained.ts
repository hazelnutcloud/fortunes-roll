import { eventHandler } from "arkiver";
import { FORTUNES_ABI } from "../abis/fortunes";
import * as schema from "../schema";

export const onFortuneGained = eventHandler(
  {
    abi: FORTUNES_ABI,
    batchProcess: true,
    eventName: "FortuneGained",
    schema,
  },
  async (ctx) => {}
);
