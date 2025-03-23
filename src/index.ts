import { JWT } from "google-auth-library";
import { google } from "googleapis";

const CALENDAR_ID = process.env.CALENDAR_ID!;
const SERVICE_ACCOUNT_KEY = JSON.parse(process.env.SERVICE_ACCOUNT_KEY!);


const server = Bun.serve({
  async fetch(req: Request) {
    if (req.method !== "GET") {
      return new Response("Method not allowed", { status: 405 });
    }
    
    const jwt = new JWT({
      email: SERVICE_ACCOUNT_KEY.client_email,
      key: SERVICE_ACCOUNT_KEY.private_key,
      scopes: [
        "https://www.googleapis.com/auth/calendar",
        "https://www.googleapis.com/auth/calendar.events",
      ],
    });

    await jwt.authorize();
    
    const client = google.calendar({ version: "v3", auth: jwt });

    await client.events.insert({
      calendarId: CALENDAR_ID,
      requestBody: {
        summary: "Test Event",
        start: { dateTime: new Date().toISOString(), timeZone: "Europe/London" },
        end: { dateTime: new Date().toISOString(), timeZone: "Europe/London" },
      }
    });

    return new Response(JSON.stringify({ message: "Prayer times created successfully" }), {
      status: 200,
      headers: { "Content-Type": "application/json" },
    });
  },
});

console.log(`Server listening on port ${server.port}`);
