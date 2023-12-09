import { Elysia, t } from "elysia";
import { cors } from "@elysiajs/cors";
import { swagger } from "@elysiajs/swagger";

const app = new Elysia({ prefix: "v1" })
  .group("api", (app) =>
    app
      .use(cors())
      .use(swagger())
      .get("/players", ({ query }) => "", { query: t.Object({}) })
  )
	.ws("/chat", {
		message(ws, message) {
			
		}
	})
  .listen(3000);

console.log(
  `🚀 Server is running at ${app.server?.hostname}:${app.server?.port}`
);
