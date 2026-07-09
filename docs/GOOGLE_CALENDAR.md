# Google Calendar Meeting Scheduler

Employees never authenticate with Google. The Rails backend uses one OAuth refresh token per environment.

## Development vs production accounts

Use different Google accounts per environment via ENV:

| Environment | Google account | Where to configure |
|-------------|----------------|--------------------|
| **Development** | `developer.qudoos@gmail.com` | `.env` |
| **Production** | `devdebizz@gmail.com` | `.kamal/secrets` |

Both accounts must be added as **Test users** on the OAuth consent screen while the app is in Testing mode.

## 1. Google Cloud setup

1. Open [Google Cloud Console](https://console.cloud.google.com/).
2. Create or select a project.
3. Enable **Google Calendar API**.
4. Configure the OAuth consent screen (Testing mode is fine).
5. Add **Test users**:
   - `developer.qudoos@gmail.com`
   - `devdebizz@gmail.com`
6. Create OAuth credentials (Web application).
7. Add redirect URI: `http://localhost:4567/oauth2callback`

## 2. Development setup (developer.qudoos@gmail.com)

Add to `.env`:

```bash
GOOGLE_CLIENT_ID=your-client-id
GOOGLE_CLIENT_SECRET=your-client-secret
GOOGLE_COMPANY_EMAIL=developer.qudoos@gmail.com
GOOGLE_CALENDAR_ID=developer.qudoos@gmail.com
```

Generate a refresh token:

```bash
bin/rails google_calendar:authorize
```

Sign in with **developer.qudoos@gmail.com**, paste the redirect URL/code, then add the printed token:

```bash
GOOGLE_REFRESH_TOKEN=...
```

## 3. Production setup (devdebizz@gmail.com)

Add to `.kamal/secrets`:

```bash
GOOGLE_CLIENT_ID=your-client-id
GOOGLE_CLIENT_SECRET=your-client-secret
GOOGLE_COMPANY_EMAIL=devdebizz@gmail.com
GOOGLE_CALENDAR_ID=devdebizz@gmail.com
GOOGLE_CALENDAR_WEBHOOK_URL=https://devdebizz.com/webhooks/google_calendar
```

Generate a **separate** refresh token by temporarily setting production values in `.env`, running `bin/rails google_calendar:authorize` while signed in as **devdebizz@gmail.com**, then storing that token in `.kamal/secrets` as `GOOGLE_REFRESH_TOKEN`.

## 4. Environment variables

| Variable | Required | Description |
|----------|----------|-------------|
| `GOOGLE_CLIENT_ID` | Yes | OAuth client ID |
| `GOOGLE_CLIENT_SECRET` | Yes | OAuth client secret |
| `GOOGLE_REFRESH_TOKEN` | Yes | Refresh token for the account used in that environment |
| `GOOGLE_COMPANY_EMAIL` | No | Attendee + default calendar owner (defaults to `devdebizz@gmail.com`) |
| `GOOGLE_CALENDAR_ID` | No | Calendar to write events to (defaults to `GOOGLE_COMPANY_EMAIL`) |
| `GOOGLE_CALENDAR_WEBHOOK_URL` | Production | Public URL, e.g. `https://devdebizz.com/webhooks/google_calendar` |

## 5. How Meet links are generated

When a meeting is created, `GoogleCalendarService` inserts a Calendar event with:

- `conferenceData.createRequest` using `hangoutsMeet`
- `conference_data_version: 1`

Google returns a Meet URL in `conferenceData.entryPoints`. The app stores it on `meetings.google_meet_url`.

Updates preserve the existing `conferenceData` so the Meet link stays the same.

## 6. Webhooks

Google push notifications hit:

`POST /webhooks/google_calendar`

`GoogleCalendar::WebhookSyncService` syncs cancelled events back into the app.
`GoogleCalendar::RenewWatchJob` renews expired watch channels daily.

Webhook URL must be HTTPS and publicly reachable in production.

Register in production:

```bash
bin/rails google_calendar:register_watch
```

## 7. Authorization rules

- **Super Admin / Admin:** see and manage all meetings
- **Employee:** see and manage only meetings they created
- All meetings are linked to a `Business`
- Invites always include client, employee, and the configured `GOOGLE_COMPANY_EMAIL`
