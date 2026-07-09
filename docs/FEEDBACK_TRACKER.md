# Feedback & Issue Tracker

Internal feedback system at `/admin/feedbacks` for bugs, feature requests, improvements, and general team input.

## Roles

| Role | Permissions |
|------|-------------|
| **Employee** | Create feedback, edit own items while `pending`, view own submissions |
| **Admin** | View all feedback, update priority/status/admin notes |
| **Super Admin** | Full CRUD, resolve, close, delete |

## Feedback types

- `bug` — requires steps to reproduce, expected result, and actual result
- `feature_request`
- `improvement`
- `ui_ux`
- `performance`
- `documentation`
- `general`

## Workflow

1. Any authenticated user submits feedback from **Feedback → Submit Feedback**
2. New items start as `pending` with priority `medium`
3. Admins triage via the index quick actions or edit form
4. Super admins can **Resolve** (completed) or **Close** feedback
5. Creators receive email when **status** changes

## Screenshots

Attach up to 5 images (PNG, JPG, WEBP, GIF) when submitting or editing pending feedback.

## Dashboard

The admin dashboard shows global feedback totals for all roles:

- Total, Pending, In Progress, Completed, Critical, Feature Requests, Bugs

## Notifications

- **No email** is sent to super admins on new submissions
- **Creator email** is sent when status changes via `FeedbackMailer#status_changed`

## Key files

- Model: `app/models/feedback.rb`
- Controller: `app/controllers/admin/feedbacks_controller.rb`
- Services: `FeedbackSubmissionService`, `FeedbackUpdateService`, `Admin::FeedbackStats`
- Mailer: `app/mailers/feedback_mailer.rb`
