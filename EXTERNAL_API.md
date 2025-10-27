# External APIs Needed by User Stories

## 1. Authentication & User Verification APIs

| **External API** | **Description** | **Used By** | **Required For User Stories** |
|------------------|-----------------|--------------|--------------------------------|
| `POST /auth/verify-license` | Validates a tradesman’s license number and status against the **state licensing authority database**. | External government or verification API | - “As a roofer, I want to upload photos of my past roofing projects while signing up…”  <br> - “As a master electrician, I need to be able to find opportunities to pull contracts…” <br> - “As a site administrator, I want to review and verify new tradesman registrations…” |
| `POST /auth/verify-email` | Sends and validates email verification links to confirm user email addresses. | External email verification service (e.g., SendGrid, AWS SES) | All registration-related stories (Tradesman, Contractor, Homeowner) |
| `POST /auth/login-oauth` | Provides optional third-party login (Google, Apple, etc.) | OAuth provider | Optional user convenience — applies to all user roles |

---

## 2. Media & File Upload APIs

| **External API** | **Description** | **Used By** | **Required For User Stories** |
|------------------|-----------------|--------------|--------------------------------|
| `POST /media/upload` | Handles uploading and secure storage of photos, videos, or documents. Uses cloud storage (e.g., AWS S3, Cloudinary). | External file storage microservice | - “As a roofer, I want to upload photos of my past roofing projects while signing up…” |
| `GET /media/{file_id}` | Retrieves uploaded media for display in profiles or job listings. | Same as above | - Homeowners viewing tradesman profiles or past project galleries |

---

## 3. Notifications & Messaging APIs

| **External API** | **Description** | **Used By** | **Required For User Stories** |
|------------------|-----------------|--------------|--------------------------------|
| `POST /notifications/push` | Sends real-time push notifications to mobile or web devices. Integrates with Firebase Cloud Messaging (FCM) or OneSignal. | External notification service | - “As a tradesman, I want to get notified instantly when a homeowner cancels an appointment…” <br> - “As a homeowner, I want to receive confirmation within 5 minutes after scheduling an appointment…” <br> - “As a homeowner, I want to receive a push notification 1 day before my scheduled appointment…” <br> - “As a contractor, I want to receive notifications within 1 minute of new bids being placed…” |
| `POST /notifications/email` | Sends transactional email confirmations (appointment confirmations, cancellations, bid alerts). | External email service | All user types receiving email confirmations |
| `POST /notifications/sms` | Sends SMS notifications for urgent changes (optional). | Twilio / MessageBird | - Homeowner or tradesman cancellations <br> - Time-sensitive contractor bids |

---

## 4. Geolocation & Mapping APIs

| **External API** | **Description** | **Used By** | **Required For User Stories** |
|------------------|-----------------|--------------|--------------------------------|
| `GET /geocode` | Converts an address to latitude/longitude for distance-based searching. | Google Maps API / Mapbox | - “As a tradesman, I want to set my preferred service area radius…” <br> - “As a homeowner, I want to filter available tradesmen by distance…” |
| `GET /distance-matrix` | Calculates distances and estimated travel times between tradesman and homeowner addresses. | Google Distance Matrix API | - “As a homeowner, I want to compare multiple worker profiles by distance…” <br> - “As a tradesman, I want to find local residential plumbing jobs…” |

---

## 5. Payments & Cost Estimate APIs

| **External API** | **Description** | **Used By** | **Required For User Stories** |
|------------------|-----------------|--------------|--------------------------------|
| `POST /payments/estimate` | Calculates or updates job cost estimates based on tradesman input. | External payment/estimation microservice | - “As a tradesman, I want to update the cost estimate based on chatting…” <br> - “As a homeowner, I want to receive an updated cost estimate within 10 minutes…” |
| `POST /payments/process` | Processes deposits or final payments securely using a payment gateway (Stripe/PayPal). | External payment provider | Future sprint or integration with job acceptance |
| `GET /payments/status/{transaction_id}` | Retrieves payment transaction or refund status. | Payment gateway API | Appointment confirmations, cancellations, or refunds |

---

## 6. Scheduling & Calendar Integration APIs

| **External API** | **Description** | **Used By** | **Required For User Stories** |
|------------------|-----------------|--------------|--------------------------------|
| `POST /calendar/sync` | Syncs a tradesman’s availability with external calendars (Google Calendar, Outlook). | Calendar provider API | - “As a tradesman, I want to update my availability schedule weekly…” <br> - “As a tradesman, I want to avoid double bookings…” |
| `GET /calendar/availability` | Retrieves upcoming bookings and available slots. | External or shared scheduling service | Tradesmen and homeowners scheduling appointments |

---

## 7. Reviews & Rating APIs

| **External API** | **Description** | **Used By** | **Required For User Stories** |
|------------------|-----------------|--------------|--------------------------------|
| `POST /reviews/sentiment` | (Optional) Runs sentiment analysis on review text for moderation or fraud detection. | External AI moderation API | - “As a homeowner, I want to leave a star rating and written review…” <br> - “As the site administrator, I need to manage bad actors…” |

---

## 8. Bidding & Project Management APIs

| **External API** | **Description** | **Used By** | **Required For User Stories** |
|------------------|-----------------|--------------|--------------------------------|
| `POST /projects` | Creates new contractor job listings and publishes them on the platform. | External contractor management microservice | - “As a contractor, I want to create a new job listing within 10 minutes…” |
| `GET /projects/{id}/bids` | Retrieves all bids for a project. | External bidding system | - “As a contractor, I want to see all open bids and worker ratings…” |
| `POST /bids` | Tradesmen submit bids for contractor projects. | External bidding system | - “As a tradesman, I want to search for job contracts published by contractors…” |
| `POST /notifications/bid` | Notifies contractor when a new bid is placed. | External notification system | - “As a contractor, I want to receive notifications within 1 minute of new bids…” |

---

## Summary of External Dependencies

| **Category** | **External Provider / API** | **Purpose** |
|---------------|-----------------------------|--------------|
| Authentication | Gov license verification, Email/OAuth providers | Verify tradesmen & user identities |
| Media Storage | AWS S3 / Cloudinary | Photo & document uploads |
| Notifications | Firebase / OneSignal / Twilio | Real-time alerts & updates |
| Geolocation | Google Maps / Mapbox | Distance, area radius, and filtering |
| Payments | Stripe / PayPal | Estimate updates and secure payments |
| Calendar | Google Calendar / Outlook | Sync availability and appointments |
| Reviews Moderation | OpenAI / Google AI | Prevent fraudulent or toxic reviews |
| Contractor Bidding | External project microservice | Enable job listing and bid management |

---