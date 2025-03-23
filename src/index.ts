const server = Bun.serve({
  async fetch(req: Request) {
    if (req.method !== "GET") {
      return new Response("Method not allowed", { status: 405 });
    }

    return new Response(JSON.stringify({ message: "Hello via Bun!" }), {
      status: 200,
      headers: { "Content-Type": "application/json" },
    });
  },
});

console.log(`Server listening on port ${server.port}`);
