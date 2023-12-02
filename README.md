# Fortune's Roll 🎲🎲
![Fortune's Roll Banner](banner.png)

## Overview

Fortune's Roll is a captivative game where players' strategic acumen meets the unpredictability of fate. Upon joining, players make an initial deposit to the collective pool, which is then used to generate yield over the course of the game. As they roll the dice, players earn points, choosing either to safely accumulate or to take calculated risks to multiply their scores.

A key feature of the game is the communal pot, fueled by points lost during high-stakes rolls. Players can pay a portion of their points to take a chance at claiming a portion of this pot, adding a thrilling strategic element.

The game's climax is as exciting as its progression: at the end, the generated yield from the initial deposit pool is distributed among players based on their final positions in the points leaderboard. While the initial deposits are secure, ensuring a zero-loss experience, the points earned through gameplay determine each player’s share of the yield. This setup offers a perfect blend of risk-free participation and the exhilarating potential of high-reward strategies, making every roll a critical step in the journey to the top of the leaderboard.

## TODO

- [x] Change deposit to sAVAX directly instead of AVAX
- [x] ~~Fix bug where seizure rolls can land after seizure period ends~~ This was not a bug, false alarm
- [x] Fix bug where depositing more does not update the player's remaining dice rolls. This opens up an exploit where players can deposit more to incorrectly get more rolls.
- [x] Fix bug where roll multiply does not take into account the users' fortune received from grabbings.
- [x] Write tests
- [x] Write deployment scripts
- [ ] Add frontend
- [ ] Add referral system

