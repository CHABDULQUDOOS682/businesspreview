# Business DevDeBizz

Rails admin app for managing business leads, preview landing pages, SMS/call communications, developer task integrations, and Stripe invoice collection.

## Core Flow

- Admins manage businesses by lifecycle segment: nurture, website sale, or subscription.
- A business with `subscription` enabled or a `subscription_fee` generates a monthly subscription invoice.
- Otherwise, invoice creation uses the business `sold_price` as a one-time website sale invoice.
- Stripe invoices are finalized by the app, then the app sends its own email/SMS payment link.
- Customer payment links use `/pay/:token` so the app can mark invoices as opened before redirecting to Stripe.
- When Stripe sends invoice webhooks, the app updates invoice status and stores invoice/receipt snapshots after payment.
- Follow-up emails are scheduled 1 day before the 7-day invoice due date.

## Setup

```bash
bundle install
bin/rails db:prepare
```

Start development:

```bash
bin/dev
```

Development uses the async Active Job adapter. Staging and production use Solid Queue.

## Deployment Environments

This app now has three Rails environments:

- `development`: local development.
- `staging`: Render deployment. It mirrors production behavior so deploy issues are caught before release.
- `production`: DigitalOcean droplet deployment.

Render staging should set:

```bash
RAILS_ENV=staging
RAILS_MASTER_KEY=...
DATABASE_URL=...
APP_HOST=your-render-staging-domain.onrender.com
APP_PROTOCOL=https
APP_HOSTS=your-render-staging-domain.onrender.com
SOLID_QUEUE_IN_PUMA=true
```

DigitalOcean production should set:

```bash
RAILS_ENV=production
RAILS_MASTER_KEY=...
DATABASE_URL=postgres://user:password@host:5432/database_name
APP_HOST=your-production-domain.com
APP_PROTOCOL=https
APP_HOSTS=your-production-domain.com,www.your-production-domain.com
SOLID_QUEUE_IN_PUMA=true
```

Run database preparation after deploy for both staging and production:

```bash
bin/rails db:prepare
```

## Environment

Required for Stripe payments:

```bash
STRIPE_SECRET_KEY=sk_test_...
STRIPE_WEBHOOK_SECRET=whsec_...
```

Required for SMS/calls:

```bash
TWILIO_ACCOUNT_SID=...
TWILIO_AUTH_TOKEN=...
TWILIO_PHONE_NUMBER=...
```

Required for real email delivery:

```bash
APP_HOST=your-domain.com
APP_PROTOCOL=https
MAILER_FROM=billing@your-domain.com
SMTP_ADDRESS=smtp.example.com
SMTP_PORT=587
SMTP_USERNAME=...
SMTP_PASSWORD=...
```

Without SMTP in development, emails open through `letter_opener`.

## Stripe Webhook

Configure Stripe to post invoice events to:

```text
https://your-domain.com/stripe/webhooks
```

Important events include invoice finalized/sent, paid, failed, voided, and marked uncollectible.

## Tests

Run the full RSpec suite:

```bash
bundle exec rspec
```

Run focused service specs:

```bash
bundle exec rspec spec/services/stripe_payment_invoice_service_spec.rb spec/services/developer_tasks/client_spec.rb
```

SimpleCov writes coverage output to `coverage/index.html`.
