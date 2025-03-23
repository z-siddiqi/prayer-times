import { JWT } from "google-auth-library";
import { google } from "googleapis";

import type { PrayerTimes } from "./types";

const CALENDAR_ID = process.env.CALENDAR_ID!;
const SERVICE_ACCOUNT_KEY = JSON.parse(process.env.SERVICE_ACCOUNT_KEY!);

async function fetchPrayerTimes(
  filter: string = "today"
): Promise<PrayerTimes> {
  const response = await fetch(`https://centralmosque.co.uk/?rest_route=/dpt/v1/prayertime&filter=${filter}`);
  return (await response.json())[0];
}

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

    const prayerTimes = await fetchPrayerTimes();
    const date = prayerTimes.d_date;

    const prayers = [
      { name: "fajr", time: prayerTimes["fajr_begins"] },
      { name: "dhuhr", time: prayerTimes["zuhr_begins"] },
      { name: "asr", time: prayerTimes["asr_mithl_2"] },
      { name: "maghrib", time: prayerTimes["maghrib_begins"] },
      { name: "isha", time: prayerTimes["isha_begins"] },
    ];

    for (const { name, time } of prayers) {
      try {
        const startTime = new Date(`${date}T${time}`);
        const endTime = new Date(startTime.getTime() + 15 * 60 * 1000);

        await client.events.insert({
          calendarId: CALENDAR_ID,
          requestBody: {
            summary: name,
            start: {
              dateTime: startTime.toISOString(),
              timeZone: "Europe/London",
            },
            end: {
              dateTime: endTime.toISOString(),
              timeZone: "Europe/London",
            },
          },
        });
      } catch (error) {
        console.error(`Error creating event for ${name}: ${error}`);
      }
    }

    return new Response(JSON.stringify({ message: "Prayer times created successfully" }), {
      status: 200,
      headers: { "Content-Type": "application/json" },
    });
  },
});

console.log(`Server listening on port ${server.port}`);
