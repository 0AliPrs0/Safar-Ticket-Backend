# ✈️ SafarTicket - Backend & API

## 🌟 Overview
This document provides a comprehensive overview of the **SafarTicket Backend Server**, developed for Phase 3 of the project. This phase focuses on the implementation of a secure and scalable server using **Django**, which exposes a full suite of **RESTful APIs** for client-side applications to consume. The backend handles user authentication, travel searching, ticket reservation, and administrative tasks, all while interacting directly with a **MySQL** database and using **Redis** for caching. The entire infrastructure is containerized with **Docker** for easy setup and deployment.

---

## 📖 Table of Contents
- [⚙️ Setup & Installation](#️-setup--installation)
- [🔧 Configuration & Security](#-configuration--security)
- [🚀 Running the Project](#-running-the-project)
- [🔌 API Endpoints Documentation](#-api-endpoints-documentation)
  - [User & Authentication](#user--authentication)
  - [Travel & Tickets](#travel--tickets)
  - [Reservations & Payments](#reservations--payments)
  - [Admin & Support](#admin--support)
- [✅ Design Notes](#-design-notes)
- [📌 Future Improvements](#-future-improvements)

---

## ⚙️ Setup & Installation
The entire backend environment is managed by Docker and Docker Compose, eliminating manual dependency management.

### **Prerequisites**
- [Docker](https://docs.docker.com/get-docker/)
- [Docker Compose](https://docs.docker.com/compose/install/)

### **Installation Steps**
1.  **Clone the Repository:**
    ```bash
    git clone [https://github.com/0AliPrs0/Safar-Ticket-Backend.git](https://github.com/0AliPrs0/Safar-Ticket-Backend.git)
    cd Safar-Ticket-Backend
    ```

2.  **Build and Run Containers:**
    This single command will build the necessary images and start all services (`db`, `redis`, `backend`, `cron`).
    ```bash
    docker-compose up --build -d
    ```
The backend server will be accessible at `http://localhost:8000`.

---

## 🔧 Configuration & Security
All necessary configurations are defined within `docker-compose.yml`.

- **Services:**
  - `db` (MySQL): The database password and name are set via environment variables. The `init.sql` script is automatically executed on the first run to initialize the schema and data.
  - `redis`: Used for caching and OTP storage.
  - `backend`: The Django application server.
  - `cron`: A dedicated container to run periodic tasks, such as cleaning up expired reservations.


---

## 🚀 Running the Project
After executing `docker-compose up`, the backend API will be available at `http://localhost:8000`.

- **View Service Logs:**
  ```bash
  docker-compose logs -f
  ```

- **Stop All Services:**
  ```bash
  docker-compose down
  ```

---

## 🔌 API Endpoints Documentation
Here is a comprehensive list of all available APIs in the SafarTicket backend.

### **User & Authentication**
---
#### 1. User Signup
- **Endpoint:** `POST /api/signup/`
- **Description:** Registers a new user and sends a verification OTP to their email. The email includes the OTP code and a direct verification link for a better user experience.
- **Request Body:**
  ```json
  {
      "first_name": "John",
      "last_name": "Doe",
      "email": "john.doe@example.com",
      "phone_number": "9123456789",
      "password": "AstrongPassword123!"
  }
  ```
- **Success Response (200):**
  ```json
  {
      "message": "OTP sent to your email for account verification."
  }
  ```
---
#### 2. Verify OTP
- **Endpoint:** `POST /api/verify-otp/`
- **Description:** Activates a new user's account by verifying the OTP.
- **Request Body:**
  ```json
  {
      "email": "john.doe@example.com",
      "otp": "123456"
  }
  ```
- **Success Response (201):**
  ```json
  {
      "message": "Account activated successfully. You can now log in."
  }
  ```
---
#### 3. User Login
- **Endpoint:** `POST /api/login/`
- **Description:** Authenticates a user and returns JWT access and refresh tokens.
- **Request Body:**
  ```json
  {
      "email": "john.doe@example.com",
      "password": "AstrongPassword123!"
  }
  ```
- **Success Response (200):**
  ```json
  {
      "access": "ey...",
      "refresh": "ey..."
  }
  ```
---
#### 4. Refresh Access Token
- **Endpoint:** `POST /api/refresh-token/`
- **Description:** Issues a new access token using a valid refresh token.
- **Request Body:**
  ```json
  {
      "refresh": "ey..."
  }
  ```
- **Success Response (200):**
  ```json
  {
      "access": "ey..."
  }
  ```
---
#### 5. Update User Profile
- **Endpoint:** `PUT /api/update-profile/`
- **Description:** Allows an authenticated user to update their profile information.
- **Auth:** Requires JWT Bearer Token.
- **Request Body (Example):**
  ```json
  {
      "first_name": "Johnny",
      "phone_number": "9121112233",
      "city_name": "Tehran"
  }
  ```
- **Success Response (200):**
  ```json
  {
      "message": "Profile updated successfully"
  }
  ```

### **Travel & Tickets**
---
#### 6. Get Cities List
- **Endpoint:** `GET /api/cities/`
- **Description:** Retrieves a list of all available cities in the system.
- **Auth:** Requires JWT Bearer Token.
- **Success Response (200):**
  ```json
  [
      { "city_id": 1, "province_name": "Tehran", "city_name": "Tehran" },
      { "city_id": 2, "province_name": "Razavi Khorasan", "city_name": "Mashhad" }
  ]
  ```
---
#### 7. Search Tickets
- **Endpoint:** `POST /api/search-tickets/`
- **Description:** Searches for available travels based on specified criteria. Results are cached in Redis.
- **Auth:** Requires JWT Bearer Token.
- **Request Body:**
  ```json
  {
      "origin_city_name": "Tehran",
      "destination_city_name": "Mashhad",
      "travel_date": "2025-07-10",
      "transport_type": "train",
      "min_price": 500000,
      "max_price": 1200000
  }
  ```
- **Success Response (200):** A list of matching travels.
  ```json
  [
      {
          "travel_id": 21,
          "transport_type": "train",
          "departure_city_name": "Tehran",
          "departure_time": "2025-07-10T22:00:00",
          "remaining_capacity": 50,
          "price": 800000
      }
  ]
  ```
---
#### 8. Get Ticket Details
- **Endpoint:** `GET /api/ticket/<int:ticket_id>/`
- **Description:** Retrieves detailed information for a specific ticket, including seat number.
- **Auth:** Requires JWT Bearer Token.
- **Success Response (200):**
  ```json
  {
    "ticket_id": 11,
    "seat_number": 1,
    "departure_city": "Tehran",
    "transport_type": "plane",
    "facilities": { "wifi": true, "meal": "snack" }
  }
  ```

### **Reservations & Payments**
---
#### 9. Reserve Ticket
- **Endpoint:** `POST /api/reserve-ticket/`
- **Description:** Creates a temporary reservation (10-minute validity) for a chosen seat. After reservation, a payment reminder email is sent to the user, containing the ticket details, expiration time, and a direct link to the payment page.
- **Auth:** Requires JWT Bearer Token.
- **Request Body:**
  ```json
  {
      "travel_id": 21,
      "seat_number": 15
  }
  ```
- **Success Response (201):**
  ```json
  {
      "message": "Ticket reserved successfully. Please complete the payment.",
      "reservation_id": 312,
      "ticket_id": 345,
      "seat_number": 15,
      "expires_at": "2025-06-12T10:45:00.000Z"
  }
  ```
---
#### 10. Pay for Ticket
- **Endpoint:** `POST /api/payment-ticket/`
- **Description:** Finalizes a reservation by processing the payment.
- **Auth:** Requires JWT Bearer Token.
- **Request Body:**
  ```json
  {
      "reservation_id": 312,
      "payment_method": "wallet"
  }
  ```
- **Success Response (200):**
  ```json
  {
      "message": "Payment completed and reservation confirmed."
  }
  ```
---
#### 11. Check Cancellation Penalty
- **Endpoint:** `POST /api/check-penalty/`
- **Description:** Calculates and returns the cancellation penalty for a paid ticket.
- **Auth:** Requires JWT Bearer Token.
- **Request Body:**
  ```json
  {
      "reservation_id": 312
  }
  ```
- **Success Response (200):**
  ```json
  {
      "reservation_id": 312,
      "penalty_percent": 50,
      "penalty_amount": 600000,
      "refund_amount": 600000
  }
  ```
---
#### 12. Cancel Ticket & Refund
- **Endpoint:** `POST /api/cancel-ticket/`
- **Description:** Cancels a paid ticket and processes the refund to the user's wallet.
- **Auth:** Requires JWT Bearer Token.
- **Request Body:**
  ```json
  {
      "reservation_id": 312
  }
  ```
- **Success Response (200):**
  ```json
  {
      "message": "Ticket canceled and refund initiated"
  }
  ```
---
#### 13. Get User Bookings
- **Endpoint:** `GET /api/user-booking/`
- **Description:** Fetches a list of all bookings for the authenticated user, filterable by status.
- **Auth:** Requires JWT Bearer Token.
- **Query Parameters:** `status` (`future`, `used`, `canceled`)
- **Success Response (200):**
  ```json
  {
    "bookings": [
      {
        "reservation_id": 312,
        "reservation_status": "paid",
        "seat_number": 15,
        "departure_time": "2025-07-10T22:00:00"
      }
    ]
  }
  ```

### **Admin & Support**
---
#### 14. Admin Ticket Management
- **Endpoint:** `POST /api/ticket-management/`
- **Description:** Allows an admin to approve, cancel, or modify a reservation.
- **Auth:** Requires Admin JWT Bearer Token.
- **Request Body (Example):**
  ```json
  {
      "reservation_id": 312,
      "action": "approve"
  }
  ```
- **Success Response (200):**
  ```json
  {
      "message": "Reservation action 'approve' performed successfully."
  }
  ```
---
#### 15. Report Ticket Issue
- **Endpoint:** `POST /api/report-ticket/`
- **Description:** Allows a user to submit a report regarding an issue.
- **Auth:** Requires JWT Bearer Token.
- **Request Body:**
  ```json
  {
      "ticket_id": 345,
      "report_category": "travel_delay",
      "report_text": "The train was delayed by over 2 hours."
  }
  ```
- **Success Response (201):**
  ```json
  {
      "message": "Report submitted successfully"
  }
  ```
---
#### 16. Admin Review Report
- **Endpoint:** `POST /api/review-report/`
- **Description:** Allows an admin to review and respond to a submitted report.
- **Auth:** Requires Admin JWT Bearer Token.
- **Request Body:**
  ```json
  {
      "report_id": 15,
      "response_text": "We apologize for the delay and have credited your account."
  }
  ```
- **Success Response (200):**
  ```json
  {
      "message": "Report reviewed and response saved"
  }
  ```

---

## ✅ Design Notes
- **Stateless Authentication:** The API uses **JSON Web Tokens (JWT)** for authentication, ensuring the backend remains stateless and scalable.
- **Single Responsibility:** Each API endpoint is designed to perform one specific task, adhering to the Single Responsibility Principle for clean and maintainable code.
- **Direct SQL Queries:** As per project requirements, the backend avoids using Django's ORM. All database interactions are performed using raw, parameterized SQL queries through the `MySQLdb` library to prevent SQL injection.
- **Performance:** **Redis** is used strategically to cache frequently accessed data, such as the list of cities and search results, significantly reducing database load and improving response times.
- **Cron Job:** A separate container runs a cron job to periodically execute `cancel_expired_reservations.py`, which cleans up stale reservations and releases seats, ensuring data integrity.
