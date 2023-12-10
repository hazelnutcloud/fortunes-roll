export function truncateAddress(address: string) {
	return `${address.slice(0, 6)}...${address.slice(-4)}`
}

export function findAndTruncateAddress(input: string): string {
	// Regular expression to match Ethereum address
	const ethAddressRegex = /0x[a-fA-F0-9]{40}/g;

	// Replace each Ethereum address in the string with its truncated version
	return input.replace(ethAddressRegex, truncateAddress);
}
