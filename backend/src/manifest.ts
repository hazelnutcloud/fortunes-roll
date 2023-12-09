import { Manifest } from "arkiver";
import * as schema from "./schema";
import { avalanche } from "viem/chains";
import { FORTUNES_ABI } from "./abis/fortunes";
import {
  onDeposit,
  onFortuneGained,
  onFortuneLost,
  onWithdraw,
} from "./handlers";
import { onDiceRolled } from "./handlers/dice-rolled";

export const manifest = new Manifest("fortunes-roll")
  .schema(schema)
  .chain("avalanche", (chain) =>
    chain
      .setOptions({
        rpcUrls: [
          "https://avalanche.infura.io/v3/4883ecdf99f84bd3a4351502ea662fe2",
          ...avalanche.rpcUrls.public.http,
        ],
      })
      .contract({
        abi: FORTUNES_ABI,
        name: "Fortunes",
        sources: {
          "0x8dD38f0f21A4d88e52BE1fEB662e530144acAC97": 38818574n,
        },
        eventHandlers: {
          Deposit: onDeposit,
          Withdraw: onWithdraw,
          FortuneGained: onFortuneGained,
          FortuneLost: onFortuneLost,
          DiceRolled: onDiceRolled,
        },
      })
  );
