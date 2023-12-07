# 🎲🎲 Fortune's Roll

![Fortune's Roll Banner](banner.png)

**Fortune's Roll** is an asynchronous, zero-loss game of dice where players strategically grow their points through high-risk bets, communal pool gains, and safe point accumulation. It combines elements of chance, strategy, and player interaction.

## Play Now

The game is currently deployed on the Avalanche C-Chain using sAVAX as the deposit token. You can play it here: [https://fortunes-roll.vercel.app/](https://fortunes-roll.vercel.app/)

## How it Works

### Core Concept

Players deposit yield bearing tokens into the game's pool to play. Yield accumulated during the course of a game is distributed to players at the end of the game proportional to their final score.

### Earning Points

There are three ways to earn points in Fortune's Roll, each of them involving a dice roll and with their own risk/reward profile:

1. **Add** - In this action, players roll the die and add the result to their score with no risk of losing points. The amount of points added is equal to the result of the die roll multiplied by 100. For example, if a player rolls a 3, they will add 300 points to their score.
2. **Multiply** - In this action, players choose a number between 1 and 12 and roll the die. They will win if they roll a number higher than or equal to their chosen number and lose otherwise.
   The amount of points won or lost is equal to a proportion of their current score. This proportion is equal to their chosen number divided by 12. For example, if a player chooses 6 and rolls a 7, they will win 50% of their current score. If they roll a 5, they will lose 50% of their current score. Higher numbers are riskier but have higher rewards.
3. **Grab** - Points lost by players in the Multiply action are added to the communal pool. Throughout the game, there will be opportunities for players to roll die to grab points from the communal pool at the cost of a portion of their current score. This cost is also added to the communal pool.
   During a Grabbing opening, each die roll is assigned a percentage of the communal pool. At the end of each opening, the communal pool is distributed to players who rolled the die in proportion to the percentage they were assigned. For example, if a player rolls a 3 and is assigned 10% of the communal pool, they will share 10% of the communal pool at the end of the opening with other players who rolled a 3. Charging a percentage of their current score to roll this action means that players with lower scores will benefit more from Grabbing compared to players with higher scores, which can act as a balancing mechanism.

### Generating Die Rolls

Players generate die rolls every second based on the amount of tokens they have deposited into the game's pool. The more tokens they have deposited, the faster they will generate die rolls. This means that players who deposit more tokens will have more opportunities to earn points.

### Withdrawals

Players can withdraw their tokens from the game's pool at any time. However, if they withdraw before the game ends, they forfeit all of the yield their tokens have accumulated during the game and will also forfeit their score. At the end of the game, players can withdraw their tokens and their share of the yield accumulated during the game proportional to their final score. This is what makes Fortune's Roll a zero-loss game.

## Going Further

With the core game logic in place, Fortune's Roll can be extended in many ways and unlocks a lot of use cases. Here are some ideas:

- **Gamified Launchpad** - Fortune's Roll can be used as a gamified launchpad for new projects. For example, a new project can launch a game of Fortune's Roll and distribute their tokens to players proportional to their final score. This can be used as a more fun alternative to a traditional airdrop.
- **Gamified Yield Farming** - Fortune's Roll can be used as a gamified yield farming platform. For example, a protocol can attract capital by gamifying their yield farming program through Fortune's Roll.
- **Powerups and Rare Items** - Fortune's Roll can be extended to include powerups and rare items that players can use to boost their gameplay. For example, a player can use a powerup to double their score or use a rare item to increase their chances of winning in the Multiply action. Powerups can be obtained randomly thoughout playing the game or bought in the open market.
- **Many More** - The possibilities are endless! Fortune's Roll can be extended in many ways to create a fun and engaging experience for players.

## Features Roadmap

- [x] Core game logic
- [ ] Player profiles
- [ ] Collectibles
- [ ] Referrals
- [ ] ...and more!

## Inspiration

Fortune's Roll is inspired by the following projects:

- [Blast L2](https://blast.io/en)
- [PoolTogether](https://pooltogether.com/)

## Tech Stack

Fortune's Roll is built using the following technologies:

- [Chainlink VRF](https://docs.chain.link/docs/chainlink-vrf/) - For generating verifiable random numbers securely on-chain.
- [Avalanche](https://www.avalabs.org/) - For the blockchain infrastructure.
- [Sveltekit](https://kit.svelte.dev/) - For the frontend.
- [Foundry](https://getfoundry.sh) - For the smart contract development environment.
- [Graph Protocol](https://thegraph.com/) - For indexing on-chain data.
