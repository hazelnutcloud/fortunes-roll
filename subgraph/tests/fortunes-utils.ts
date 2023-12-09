import { newMockEvent } from "matchstick-as"
import { ethereum, Address, BigInt } from "@graphprotocol/graph-ts"
import {
  Deposit,
  DiceLanded,
  DiceRolled,
  FortuneGained,
  FortuneLost,
  GrabbeningClosed,
  OwnershipTransferred,
  Withdraw
} from "../generated/Fortunes/Fortunes"

export function createDepositEvent(
  player: Address,
  amount: BigInt,
  timestamp: BigInt
): Deposit {
  let depositEvent = changetype<Deposit>(newMockEvent())

  depositEvent.parameters = new Array()

  depositEvent.parameters.push(
    new ethereum.EventParam("player", ethereum.Value.fromAddress(player))
  )
  depositEvent.parameters.push(
    new ethereum.EventParam("amount", ethereum.Value.fromUnsignedBigInt(amount))
  )
  depositEvent.parameters.push(
    new ethereum.EventParam(
      "timestamp",
      ethereum.Value.fromUnsignedBigInt(timestamp)
    )
  )

  return depositEvent
}

export function createDiceLandedEvent(
  player: Address,
  action: i32,
  multiplyStake: BigInt,
  grabbeningIndex: BigInt,
  requestId: BigInt,
  diceRoll: BigInt,
  timestamp: BigInt
): DiceLanded {
  let diceLandedEvent = changetype<DiceLanded>(newMockEvent())

  diceLandedEvent.parameters = new Array()

  diceLandedEvent.parameters.push(
    new ethereum.EventParam("player", ethereum.Value.fromAddress(player))
  )
  diceLandedEvent.parameters.push(
    new ethereum.EventParam(
      "action",
      ethereum.Value.fromUnsignedBigInt(BigInt.fromI32(action))
    )
  )
  diceLandedEvent.parameters.push(
    new ethereum.EventParam(
      "multiplyStake",
      ethereum.Value.fromUnsignedBigInt(multiplyStake)
    )
  )
  diceLandedEvent.parameters.push(
    new ethereum.EventParam(
      "grabbeningIndex",
      ethereum.Value.fromUnsignedBigInt(grabbeningIndex)
    )
  )
  diceLandedEvent.parameters.push(
    new ethereum.EventParam(
      "requestId",
      ethereum.Value.fromUnsignedBigInt(requestId)
    )
  )
  diceLandedEvent.parameters.push(
    new ethereum.EventParam(
      "diceRoll",
      ethereum.Value.fromUnsignedBigInt(diceRoll)
    )
  )
  diceLandedEvent.parameters.push(
    new ethereum.EventParam(
      "timestamp",
      ethereum.Value.fromUnsignedBigInt(timestamp)
    )
  )

  return diceLandedEvent
}

export function createDiceRolledEvent(
  player: Address,
  action: i32,
  multiplyStake: BigInt,
  grabbeningIndex: BigInt,
  requestId: BigInt,
  timestamp: BigInt
): DiceRolled {
  let diceRolledEvent = changetype<DiceRolled>(newMockEvent())

  diceRolledEvent.parameters = new Array()

  diceRolledEvent.parameters.push(
    new ethereum.EventParam("player", ethereum.Value.fromAddress(player))
  )
  diceRolledEvent.parameters.push(
    new ethereum.EventParam(
      "action",
      ethereum.Value.fromUnsignedBigInt(BigInt.fromI32(action))
    )
  )
  diceRolledEvent.parameters.push(
    new ethereum.EventParam(
      "multiplyStake",
      ethereum.Value.fromUnsignedBigInt(multiplyStake)
    )
  )
  diceRolledEvent.parameters.push(
    new ethereum.EventParam(
      "grabbeningIndex",
      ethereum.Value.fromUnsignedBigInt(grabbeningIndex)
    )
  )
  diceRolledEvent.parameters.push(
    new ethereum.EventParam(
      "requestId",
      ethereum.Value.fromUnsignedBigInt(requestId)
    )
  )
  diceRolledEvent.parameters.push(
    new ethereum.EventParam(
      "timestamp",
      ethereum.Value.fromUnsignedBigInt(timestamp)
    )
  )

  return diceRolledEvent
}

export function createFortuneGainedEvent(
  player: Address,
  fortuneGained: BigInt,
  timestamp: BigInt
): FortuneGained {
  let fortuneGainedEvent = changetype<FortuneGained>(newMockEvent())

  fortuneGainedEvent.parameters = new Array()

  fortuneGainedEvent.parameters.push(
    new ethereum.EventParam("player", ethereum.Value.fromAddress(player))
  )
  fortuneGainedEvent.parameters.push(
    new ethereum.EventParam(
      "fortuneGained",
      ethereum.Value.fromUnsignedBigInt(fortuneGained)
    )
  )
  fortuneGainedEvent.parameters.push(
    new ethereum.EventParam(
      "timestamp",
      ethereum.Value.fromUnsignedBigInt(timestamp)
    )
  )

  return fortuneGainedEvent
}

export function createFortuneLostEvent(
  player: Address,
  fortuneLost: BigInt,
  timestamp: BigInt
): FortuneLost {
  let fortuneLostEvent = changetype<FortuneLost>(newMockEvent())

  fortuneLostEvent.parameters = new Array()

  fortuneLostEvent.parameters.push(
    new ethereum.EventParam("player", ethereum.Value.fromAddress(player))
  )
  fortuneLostEvent.parameters.push(
    new ethereum.EventParam(
      "fortuneLost",
      ethereum.Value.fromUnsignedBigInt(fortuneLost)
    )
  )
  fortuneLostEvent.parameters.push(
    new ethereum.EventParam(
      "timestamp",
      ethereum.Value.fromUnsignedBigInt(timestamp)
    )
  )

  return fortuneLostEvent
}

export function createGrabbeningClosedEvent(
  grabbeningIndex: BigInt,
  potBalance: BigInt,
  totalRewards: BigInt,
  timestamp: BigInt
): GrabbeningClosed {
  let grabbeningClosedEvent = changetype<GrabbeningClosed>(newMockEvent())

  grabbeningClosedEvent.parameters = new Array()

  grabbeningClosedEvent.parameters.push(
    new ethereum.EventParam(
      "grabbeningIndex",
      ethereum.Value.fromUnsignedBigInt(grabbeningIndex)
    )
  )
  grabbeningClosedEvent.parameters.push(
    new ethereum.EventParam(
      "potBalance",
      ethereum.Value.fromUnsignedBigInt(potBalance)
    )
  )
  grabbeningClosedEvent.parameters.push(
    new ethereum.EventParam(
      "totalRewards",
      ethereum.Value.fromUnsignedBigInt(totalRewards)
    )
  )
  grabbeningClosedEvent.parameters.push(
    new ethereum.EventParam(
      "timestamp",
      ethereum.Value.fromUnsignedBigInt(timestamp)
    )
  )

  return grabbeningClosedEvent
}

export function createOwnershipTransferredEvent(
  user: Address,
  newOwner: Address
): OwnershipTransferred {
  let ownershipTransferredEvent = changetype<OwnershipTransferred>(
    newMockEvent()
  )

  ownershipTransferredEvent.parameters = new Array()

  ownershipTransferredEvent.parameters.push(
    new ethereum.EventParam("user", ethereum.Value.fromAddress(user))
  )
  ownershipTransferredEvent.parameters.push(
    new ethereum.EventParam("newOwner", ethereum.Value.fromAddress(newOwner))
  )

  return ownershipTransferredEvent
}

export function createWithdrawEvent(
  player: Address,
  amount: BigInt,
  kind: string,
  timestamp: BigInt
): Withdraw {
  let withdrawEvent = changetype<Withdraw>(newMockEvent())

  withdrawEvent.parameters = new Array()

  withdrawEvent.parameters.push(
    new ethereum.EventParam("player", ethereum.Value.fromAddress(player))
  )
  withdrawEvent.parameters.push(
    new ethereum.EventParam("amount", ethereum.Value.fromUnsignedBigInt(amount))
  )
  withdrawEvent.parameters.push(
    new ethereum.EventParam("kind", ethereum.Value.fromString(kind))
  )
  withdrawEvent.parameters.push(
    new ethereum.EventParam(
      "timestamp",
      ethereum.Value.fromUnsignedBigInt(timestamp)
    )
  )

  return withdrawEvent
}
