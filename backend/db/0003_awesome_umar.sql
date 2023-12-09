ALTER TABLE "player" ADD COLUMN "last_roll_timestamp" timestamp;--> statement-breakpoint
ALTER TABLE "player" DROP COLUMN IF EXISTS "rolls_remaining";