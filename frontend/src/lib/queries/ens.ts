import { mainnetPublicClient } from "./public-client";

export function getEnsName(address: `0x${string}`) {
	return mainnetPublicClient.getEnsName({ address } );
}

export function getEnsAvatar(name: string) {
	return mainnetPublicClient.getEnsAvatar({ name } );
}