# API DOCUMENTATION

## User & Authentication

### Register User

### POST /register

Request body:
```
{
  "name": "John Doe",
  "email": "john@example.com",
  "password": "securePassword123",
  "role": "homeowner", // or "tradesman"
  "address": "123 Main St, City, ZIP" // optional for tradesman
}

```
Response:
```
{
  "user_id": "uuid",
  "name": "John Doe",
  "email": "john@example.com",
  "role": "homeowner",
  "status": "active"
}
```

### Login User

### POST /login

Request body:
```
{
  "email": "john@example.com",
  "password": "securePassword123"
}


```
Response:
```
{
  "access_token": "jwt_token",
  "token_type": "Bearer"
}

```

### Get Profile

### GET /profile/{user_id}

Response:
```
{
  "user_id": "uuid",
  "name": "John Doe",
  "email": "john@example.com",
  "role": "tradesman",
  "address": "123 Main St, City, ZIP",
  "profile": {
    "license_number": "ABC123",
    "trade": "plumber",
    "experience": 5,
    "rating": 4.8
  }
}


```

### Update Profile

### PUT /profile/{user_id}

Request body:
```
{
  "name": "John D.",
  "address": "456 Elm St",
  "profile": {
    "experience": 6
  }
}

```
Response:
```
{
  "message": "Profile updated successfully"
}


```

## Search Tradesman

### Tradesman Availability & Scheduling

### GET /tradesmen?trade=plumber&location=ZIP

Response:
```
[
  {
    "user_id": "uuid",
    "name": "Jane Smith",
    "trade": "plumber",
    "rating": 4.9,
    "distance": "2 miles"
  }
]


```

### Get Tradesman Schedule

### GET /tradesman/{id}/schedule

Response:
```
[
  {
    "schedule_id": "uuid",
    "date": "2025-10-25",
    "start_time": "09:00",
    "end_time": "11:00",
    "status": "available"
  }
]

```

### Request Appointment

### POST /appointments

Request body:
```
{
  "homeowner_id": "uuid",
  "tradesman_id": "uuid",
  "scheduled_start": "2025-10-25T09:00:00",
  "scheduled_end": "2025-10-25T11:00:00",
  "job_description": "Leaking kitchen sink"
}



```
Response:
```
{
  "appointment_id": "uuid",
  "status": "pending"
}


```

### Cancel Appointment

### PUT /appointments/{id}/cancel

Response:
```
{
  "message": "Appointment canceled"
}

```



## Messaging

## Get Messages

### GET /messages/{conversation_id}

Response:

```
[
  {
    "message_id": "uuid",
    "sender_id": "uuid",
    "receiver_id": "uuid",
    "content": "Hello, I have a leak",
    "timestamp": "2025-10-23T12:00:00"
  }
]
```
### Send Message

### POST /messages

Request body:

```
{
  "sender_id": "uuid",
  "receiver_id": "uuid",
  "appointment_id": "uuid", // optional
  "content": "I can fix it tomorrow",
  "attachment_url": null
}

```
Response:

```
{
  "message_id": "uuid",
  "timestamp": "2025-10-23T12:05:00"
}
```

## Reviews

### Leave Review

### POST /reviews

Request body:

```
{
  "homeowner_id": "uuid",
  "tradesman_id": "uuid",
  "appointment_id": "uuid",
  "rating": 5,
  "comment": "Fixed my sink quickly and professionally"
}


```
Response:

```
{
  "message": "Review submitted successfully"
}

```

### Get Tradesman Reviews

### GET /reviews/{tradesman_id}

Response:

```
[
  {
    "review_id": "uuid",
    "homeowner_id": "uuid",
    "rating": 5,
    "comment": "Excellent work",
    "timestamp": "2025-10-20T15:00:00"
  }
]

```

## Tradesman Profile

### Create Tradesman Profile

### POST /tradesman/profile

Request body:

```
{
  "user_id": "uuid",
  "trade": "plumber",
  "license_number": "ABC123",
  "business_name": "John's Plumbing",
  "experience": 5,
  "location": "ZIP"
}

```

Response:

```
{
  "message": "Tradesman profile saved successfully"
}
```


