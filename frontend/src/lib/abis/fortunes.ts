export const FORTUNES_ABI = [
	{
		type: 'constructor',
		inputs: [
			{ name: '_owner', type: 'address', internalType: 'address' },
			{ name: '_vrfCoordinator', type: 'address', internalType: 'address' },
			{ name: '_stakedAvax', type: 'address', internalType: 'address payable' },
			{ name: '_gameStart', type: 'uint256', internalType: 'uint256' },
			{ name: '_gameEnd', type: 'uint256', internalType: 'uint256' },
			{ name: '_diceRollGenerationRate', type: 'uint256', internalType: 'uint256' },
			{ name: '_diceRateDepositFactor', type: 'uint256', internalType: 'uint256' },
			{ name: '_additionMultiplier', type: 'uint256', internalType: 'uint256' },
			{ name: '_minimumFortuneToRollGrab', type: 'uint256', internalType: 'uint256' },
			{ name: '_baseDiceRolls', type: 'uint256', internalType: 'uint256' },
			{ name: 'keyHash', type: 'bytes32', internalType: 'bytes32' },
			{ name: 'subscriptionId', type: 'uint64', internalType: 'uint64' }
		],
		stateMutability: 'nonpayable'
	},
	{
		type: 'function',
		name: 'STAKED_AVAX',
		inputs: [],
		outputs: [{ name: '', type: 'address', internalType: 'contract IStakedAvax' }],
		stateMutability: 'view'
	},
	{
		type: 'function',
		name: 'additionMultiplier',
		inputs: [],
		outputs: [{ name: '', type: 'uint256', internalType: 'uint256' }],
		stateMutability: 'view'
	},
	{
		type: 'function',
		name: 'baseDiceRolls',
		inputs: [],
		outputs: [{ name: '', type: 'uint256', internalType: 'uint256' }],
		stateMutability: 'view'
	},
	{
		type: 'function',
		name: 'claimProtocolRewards',
		inputs: [],
		outputs: [],
		stateMutability: 'nonpayable'
	},
	{
		type: 'function',
		name: 'closeCurrentGrabbening',
		inputs: [],
		outputs: [],
		stateMutability: 'nonpayable'
	},
	{
		type: 'function',
		name: 'deposit',
		inputs: [{ name: 'shareAmount', type: 'uint256', internalType: 'uint256' }],
		outputs: [],
		stateMutability: 'nonpayable'
	},
	{
		type: 'function',
		name: 'diceRateDepositFactor',
		inputs: [],
		outputs: [{ name: '', type: 'uint256', internalType: 'uint256' }],
		stateMutability: 'view'
	},
	{
		type: 'function',
		name: 'diceRollGenerationRate',
		inputs: [],
		outputs: [{ name: '', type: 'uint256', internalType: 'uint256' }],
		stateMutability: 'view'
	},
	{ type: 'function', name: 'forfeit', inputs: [], outputs: [], stateMutability: 'nonpayable' },
	{
		type: 'function',
		name: 'gameEnd',
		inputs: [],
		outputs: [{ name: '', type: 'uint256', internalType: 'uint256' }],
		stateMutability: 'view'
	},
	{
		type: 'function',
		name: 'gameStart',
		inputs: [],
		outputs: [{ name: '', type: 'uint256', internalType: 'uint256' }],
		stateMutability: 'view'
	},
	{
		type: 'function',
		name: 'grabbeningGrabberTallies',
		inputs: [
			{ name: '', type: 'uint256', internalType: 'uint256' },
			{ name: '', type: 'uint256', internalType: 'uint256' }
		],
		outputs: [{ name: '', type: 'uint256', internalType: 'uint256' }],
		stateMutability: 'view'
	},
	{
		type: 'function',
		name: 'grabbeningIndex',
		inputs: [],
		outputs: [{ name: '', type: 'uint256', internalType: 'uint256' }],
		stateMutability: 'view'
	},
	{
		type: 'function',
		name: 'grabbeningRewardGroups',
		inputs: [
			{ name: '', type: 'uint256', internalType: 'uint256' },
			{ name: '', type: 'uint256', internalType: 'uint256' }
		],
		outputs: [{ name: '', type: 'uint256', internalType: 'uint256' }],
		stateMutability: 'view'
	},
	{
		type: 'function',
		name: 'grabbeningRewardGroupsLength',
		inputs: [{ name: '', type: 'uint256', internalType: 'uint256' }],
		outputs: [{ name: '', type: 'uint256', internalType: 'uint256' }],
		stateMutability: 'view'
	},
	{
		type: 'function',
		name: 'grabbeningRollToRewardGroup',
		inputs: [
			{ name: '', type: 'uint256', internalType: 'uint256' },
			{ name: '', type: 'uint256', internalType: 'uint256' }
		],
		outputs: [{ name: '', type: 'uint256', internalType: 'uint256' }],
		stateMutability: 'view'
	},
	{
		type: 'function',
		name: 'grabbeningRolls',
		inputs: [
			{ name: '', type: 'uint256', internalType: 'uint256' },
			{ name: '', type: 'address', internalType: 'address' }
		],
		outputs: [{ name: '', type: 'uint256', internalType: 'uint256' }],
		stateMutability: 'view'
	},
	{
		type: 'function',
		name: 'grabbenings',
		inputs: [{ name: '', type: 'uint256', internalType: 'uint256' }],
		outputs: [
			{ name: 'start', type: 'uint256', internalType: 'uint256' },
			{ name: 'end', type: 'uint256', internalType: 'uint256' },
			{ name: 'fee', type: 'uint256', internalType: 'uint256' },
			{ name: 'rewardSharesTotal', type: 'uint256', internalType: 'uint256' },
			{ name: 'rewardsSnapshot', type: 'uint256', internalType: 'uint256' }
		],
		stateMutability: 'view'
	},
	{
		type: 'function',
		name: 'minimumFortuneToRollGrab',
		inputs: [],
		outputs: [{ name: '', type: 'uint256', internalType: 'uint256' }],
		stateMutability: 'view'
	},
	{
		type: 'function',
		name: 'outstandingRolls',
		inputs: [],
		outputs: [{ name: '', type: 'uint256', internalType: 'uint256' }],
		stateMutability: 'view'
	},
	{
		type: 'function',
		name: 'owner',
		inputs: [],
		outputs: [{ name: '', type: 'address', internalType: 'address' }],
		stateMutability: 'view'
	},
	{
		type: 'function',
		name: 'players',
		inputs: [{ name: '', type: 'address', internalType: 'address' }],
		outputs: [
			{ name: 'fortune', type: 'uint256', internalType: 'uint256' },
			{ name: 'deposit', type: 'uint256', internalType: 'uint256' },
			{ name: 'diceRollsRemaining', type: 'uint256', internalType: 'uint256' },
			{ name: 'lastDiceRollTimestamp', type: 'uint256', internalType: 'uint256' },
			{ name: 'hasPendingRoll', type: 'bool', internalType: 'bool' }
		],
		stateMutability: 'view'
	},
	{
		type: 'function',
		name: 'potBalance',
		inputs: [],
		outputs: [{ name: '', type: 'uint256', internalType: 'uint256' }],
		stateMutability: 'view'
	},
	{
		type: 'function',
		name: 'rawFulfillRandomWords',
		inputs: [
			{ name: 'requestId', type: 'uint256', internalType: 'uint256' },
			{ name: 'randomWords', type: 'uint256[]', internalType: 'uint256[]' }
		],
		outputs: [],
		stateMutability: 'nonpayable'
	},
	{ type: 'function', name: 'redeem', inputs: [], outputs: [], stateMutability: 'nonpayable' },
	{
		type: 'function',
		name: 'rollAdd',
		inputs: [],
		outputs: [{ name: '', type: 'uint256', internalType: 'uint256' }],
		stateMutability: 'nonpayable'
	},
	{
		type: 'function',
		name: 'rollAddMultiple',
		inputs: [{ name: 'multiplier', type: 'uint256', internalType: 'uint256' }],
		outputs: [{ name: '', type: 'uint256', internalType: 'uint256' }],
		stateMutability: 'nonpayable'
	},
	{
		type: 'function',
		name: 'rollGrab',
		inputs: [],
		outputs: [{ name: '', type: 'uint256', internalType: 'uint256' }],
		stateMutability: 'nonpayable'
	},
	{
		type: 'function',
		name: 'rollMultiply',
		inputs: [{ name: 'stake', type: 'uint256', internalType: 'uint256' }],
		outputs: [{ name: '', type: 'uint256', internalType: 'uint256' }],
		stateMutability: 'nonpayable'
	},
	{
		type: 'function',
		name: 'rollingDie',
		inputs: [{ name: '', type: 'uint256', internalType: 'uint256' }],
		outputs: [
			{ name: 'player', type: 'address', internalType: 'address' },
			{ name: 'multiplyStake', type: 'uint256', internalType: 'uint256' },
			{ name: 'grabbeningIndex', type: 'uint256', internalType: 'uint256' },
			{ name: 'addMultiplier', type: 'uint256', internalType: 'uint256' },
			{ name: 'action', type: 'uint8', internalType: 'enum Fortunes.RollAction' }
		],
		stateMutability: 'view'
	},
	{
		type: 'function',
		name: 'setGrabbening',
		inputs: [
			{ name: 'index', type: 'uint256', internalType: 'uint256' },
			{ name: 'start', type: 'uint256', internalType: 'uint256' },
			{ name: 'end', type: 'uint256', internalType: 'uint256' },
			{ name: 'fee', type: 'uint256', internalType: 'uint256' },
			{ name: 'rewardGroups', type: 'uint256[]', internalType: 'uint256[]' },
			{ name: 'rollToRewardGroup', type: 'uint256[]', internalType: 'uint256[]' }
		],
		outputs: [],
		stateMutability: 'nonpayable'
	},
	{
		type: 'function',
		name: 'totalDeposited',
		inputs: [],
		outputs: [{ name: '', type: 'uint256', internalType: 'uint256' }],
		stateMutability: 'view'
	},
	{
		type: 'function',
		name: 'totalFortune',
		inputs: [],
		outputs: [{ name: '', type: 'uint256', internalType: 'uint256' }],
		stateMutability: 'view'
	},
	{
		type: 'function',
		name: 'totalProtocolRewards',
		inputs: [],
		outputs: [{ name: '', type: 'uint256', internalType: 'uint256' }],
		stateMutability: 'view'
	},
	{
		type: 'function',
		name: 'transferOwnership',
		inputs: [{ name: 'newOwner', type: 'address', internalType: 'address' }],
		outputs: [],
		stateMutability: 'nonpayable'
	},
	{ type: 'function', name: 'withdraw', inputs: [], outputs: [], stateMutability: 'nonpayable' },
	{
		type: 'event',
		name: 'Deposit',
		inputs: [
			{ name: 'player', type: 'address', indexed: true, internalType: 'address' },
			{ name: 'amount', type: 'uint256', indexed: false, internalType: 'uint256' }
		],
		anonymous: false
	},
	{
		type: 'event',
		name: 'DiceLanded',
		inputs: [
			{ name: 'player', type: 'address', indexed: true, internalType: 'address' },
			{ name: 'action', type: 'uint8', indexed: false, internalType: 'enum Fortunes.RollAction' },
			{ name: 'requestId', type: 'uint256', indexed: false, internalType: 'uint256' },
			{ name: 'multiplyStake', type: 'uint256', indexed: false, internalType: 'uint256' },
			{ name: 'grabbeningIndex', type: 'uint256', indexed: false, internalType: 'uint256' },
			{ name: 'addMultiplier', type: 'uint256', indexed: false, internalType: 'uint256' },
			{ name: 'result', type: 'uint8', indexed: false, internalType: 'uint8' }
		],
		anonymous: false
	},
	{
		type: 'event',
		name: 'DiceRolled',
		inputs: [
			{ name: 'player', type: 'address', indexed: true, internalType: 'address' },
			{ name: 'action', type: 'uint8', indexed: false, internalType: 'enum Fortunes.RollAction' },
			{ name: 'requestId', type: 'uint256', indexed: false, internalType: 'uint256' },
			{ name: 'timestamp', type: 'uint256', indexed: false, internalType: 'uint256' }
		],
		anonymous: false
	},
	{
		type: 'event',
		name: 'FortuneGained',
		inputs: [
			{ name: 'player', type: 'address', indexed: true, internalType: 'address' },
			{ name: 'fortuneGained', type: 'uint256', indexed: false, internalType: 'uint256' }
		],
		anonymous: false
	},
	{
		type: 'event',
		name: 'FortuneLost',
		inputs: [
			{ name: 'player', type: 'address', indexed: true, internalType: 'address' },
			{ name: 'fortuneLost', type: 'uint256', indexed: false, internalType: 'uint256' }
		],
		anonymous: false
	},
	{
		type: 'event',
		name: 'GrabbeningClosed',
		inputs: [
			{ name: 'grabbeningIndex', type: 'uint256', indexed: false, internalType: 'uint256' },
			{ name: 'potBalance', type: 'uint256', indexed: false, internalType: 'uint256' },
			{ name: 'totalRewards', type: 'uint256', indexed: false, internalType: 'uint256' }
		],
		anonymous: false
	},
	{
		type: 'event',
		name: 'OwnershipTransferred',
		inputs: [
			{ name: 'user', type: 'address', indexed: true, internalType: 'address' },
			{ name: 'newOwner', type: 'address', indexed: true, internalType: 'address' }
		],
		anonymous: false
	},
	{
		type: 'event',
		name: 'Withdraw',
		inputs: [
			{ name: 'player', type: 'address', indexed: true, internalType: 'address' },
			{ name: 'amount', type: 'uint256', indexed: false, internalType: 'uint256' },
			{ name: 'kind', type: 'string', indexed: false, internalType: 'string' }
		],
		anonymous: false
	},
	{
		type: 'error',
		name: 'OnlyCoordinatorCanFulfill',
		inputs: [
			{ name: 'have', type: 'address', internalType: 'address' },
			{ name: 'want', type: 'address', internalType: 'address' }
		]
	}
] as const;
