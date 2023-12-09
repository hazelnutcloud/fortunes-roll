import {
  Deposit as DepositEvent,
  DiceLanded as DiceLandedEvent,
  DiceRolled as DiceRolledEvent,
  FortuneGained as FortuneGainedEvent,
  FortuneLost as FortuneLostEvent,
  GrabbeningClosed as GrabbeningClosedEvent,
  OwnershipTransferred as OwnershipTransferredEvent,
  Withdraw as WithdrawEvent
} from "../generated/Fortunes/Fortunes"
import {
  Deposit,
  DiceLanded,
  DiceRolled,
  FortuneGained,
  FortuneLost,
  GrabbeningClosed,
  OwnershipTransferred,
  Withdraw
} from "../generated/schema"

export function handleDeposit(event: DepositEvent): void {
  let entity = new Deposit(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  )
  entity.player = event.params.player
  entity.amount = event.params.amount
  entity.timestamp = event.params.timestamp

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
}

export function handleDiceLanded(event: DiceLandedEvent): void {
  let entity = new DiceLanded(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  )
  entity.player = event.params.player
  entity.action = event.params.action
  entity.multiplyStake = event.params.multiplyStake
  entity.grabbeningIndex = event.params.grabbeningIndex
  entity.requestId = event.params.requestId
  entity.diceRoll = event.params.diceRoll
  entity.timestamp = event.params.timestamp

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
}

export function handleDiceRolled(event: DiceRolledEvent): void {
  let entity = new DiceRolled(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  )
  entity.player = event.params.player
  entity.action = event.params.action
  entity.multiplyStake = event.params.multiplyStake
  entity.grabbeningIndex = event.params.grabbeningIndex
  entity.requestId = event.params.requestId
  entity.timestamp = event.params.timestamp

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
}

export function handleFortuneGained(event: FortuneGainedEvent): void {
  let entity = new FortuneGained(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  )
  entity.player = event.params.player
  entity.fortuneGained = event.params.fortuneGained
  entity.timestamp = event.params.timestamp

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
}

export function handleFortuneLost(event: FortuneLostEvent): void {
  let entity = new FortuneLost(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  )
  entity.player = event.params.player
  entity.fortuneLost = event.params.fortuneLost
  entity.timestamp = event.params.timestamp

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
}

export function handleGrabbeningClosed(event: GrabbeningClosedEvent): void {
  let entity = new GrabbeningClosed(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  )
  entity.grabbeningIndex = event.params.grabbeningIndex
  entity.potBalance = event.params.potBalance
  entity.totalRewards = event.params.totalRewards
  entity.timestamp = event.params.timestamp

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
}

export function handleOwnershipTransferred(
  event: OwnershipTransferredEvent
): void {
  let entity = new OwnershipTransferred(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  )
  entity.user = event.params.user
  entity.newOwner = event.params.newOwner

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
}

export function handleWithdraw(event: WithdrawEvent): void {
  let entity = new Withdraw(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  )
  entity.player = event.params.player
  entity.amount = event.params.amount
  entity.kind = event.params.kind
  entity.timestamp = event.params.timestamp

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
}
