import { Elysia, t } from "elysia";
import { cors } from "@elysiajs/cors";
import { swagger } from "@elysiajs/swagger";
import { drizzle } from "drizzle-orm/postgres-js";
import postgres from "postgres";
import * as schema from "./schema.ts";
import { rateLimit } from "elysia-rate-limit";
import { match, P } from "ts-pattern";
import { asc, desc, eq, sql } from "drizzle-orm";
import { startArkiver } from "./arkiver.ts";

const postgresUrl = process.env["DATABASE_URL"];
if (!postgresUrl) throw new Error("DATABASE_URL not set.");

await startArkiver();

export const app = new Elysia({ prefix: "/v1" })
  .use(cors())
  .use(rateLimit({ max: 10, duration: 60 }))
  .use(
    swagger({
      documentation: {
        info: {
          title: "Fortune's Roll API",
          version: "1.0.0",
        },
      },
    })
  )
  .state("db", drizzle(postgres(postgresUrl), { schema }))
  .get(
    "/players",
    async ({ query, store: { db } }) => {
      const { limit, offset, sortBy, sortDirection } = query;

      const orderBy = match([sortBy, sortDirection])
        .with([P.string, "asc"], ([sortBy]) => [asc(schema.player[sortBy])])
        .with([P.string, "desc"], ([sortBy]) => [desc(schema.player[sortBy])])
        .with([P.string, undefined], ([sortBy]) => [asc(schema.player[sortBy])])
        .otherwise(() => undefined);

      const players = await db.query.player.findMany({
        limit,
        offset,
        orderBy,
      });

      return {
        data: players,
      };
    },
    {
      query: t.Object({
        limit: t.Optional(t.Numeric({ maximum: 100 })),
        offset: t.Optional(t.Numeric()),
        sortBy: t.Optional(
          t.Union([
            t.Literal("score"),
            t.Literal("rolls"),
            t.Literal("deposit"),
            t.Literal("lastRollTimestamp"),
          ])
        ),
        sortDirection: t.Optional(
          t.Union([t.Literal("asc"), t.Literal("desc")])
        ),
      }),
    }
  )
  .group(
    "/players/:address",
    {
      params: t.Object({
        address: t.String({
          pattern: "^0x[a-fA-F0-9]{40}$", // Ethereum address pattern
        }),
      }),
    },
    (group) =>
      group
        .get("/", async ({ params: { address }, store: { db } }) => {
          const player = await db.query.player.findFirst({
            where: eq(schema.player.address, address),
          });

          if (!player) {
            return {
              error: {
                message: "Player not found",
              },
            };
          }

          return {
            data: player,
          };
        })
        .get("/ranking", async ({ params: { address }, store: { db } }) => {
          const rankedUsers = db
            .select({
              address: schema.player.address,
              rank: sql<number>`row_number() over (order by ${schema.player.score} desc)`.as(
                "rank"
              ),
            })
            .from(schema.player)
            .as("ranked_users");

          const playerRanking = await db
            .select()
            .from(rankedUsers)
            .where(eq(rankedUsers.address, address));

          if (!playerRanking.length) {
            return {
              error: {
                message: "Player not found",
              },
            };
          }

          return {
            data: {
              address,
              rank: playerRanking[0].rank,
            },
          };
        })
  )
  .ws("/chat", {
    message(ws, msg) {
      ws.publish("chat", { msg, id: ws.data.query.id! });
    },
    open(ws) {
      const msg = `${ws.data.query.id} joined the chat}`;

      ws.subscribe("chat");
      ws.publish("chat", { msg, id: "admin" });
    },
    close(ws) {
      ws.unsubscribe("chat");
    },
    body: t.String(),
    response: t.Object({
      id: t.String(),
      msg: t.String(),
    }),
  })
  .listen({ port: 3000, hostname: "0.0.0.0" });

console.log(
  `🚀 Server is running at http://${app.server?.hostname}:${app.server?.port}`
);
