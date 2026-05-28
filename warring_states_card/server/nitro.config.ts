export default {
  $schema: "https://json.schemastore.org/nitro-schema.json",
  preset: "node-server",
  server: "./server/index.ts",
  routeRules: {
    "/api/**": { cors: true },
    "/ws/**": { websocket: true },
  },
};
