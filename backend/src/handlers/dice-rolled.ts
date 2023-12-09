import { eventHandler } from "arkiver";
import { FORTUNES_ABI } from "../abis/fortunes";
import * as schema from "../schema";

export const onDiceRolled = eventHandler(
  {
    abi: FORTUNES_ABI,
    batchProcess: true,
    eventName: "DiceRolled",
    schema,
  },
  async (ctx) => {}
);
