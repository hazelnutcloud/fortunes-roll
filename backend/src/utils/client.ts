import { HttpTransport, PublicClient, createPublicClient, http } from "viem";
import { mainnet } from "viem/chains";

export const mainnetClient: PublicClient<HttpTransport, typeof mainnet> =
  createPublicClient({
    chain: mainnet,
    transport: http(),
    batch: {
      multicall: true,
    },
  });
