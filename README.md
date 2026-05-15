# Microservice Demo

A beginner-friendly project that demonstrates how multiple independent services work together to form a simple application. Built for students learning microservice architecture.

---

## What is a Microservice?

A traditional app puts everything — login, products, UI — into one codebase. A **microservice** architecture splits those responsibilities into small, independent services that each do one thing well and communicate over HTTP.

This project has three services:

```
┌─────────────────────────────────────────────────────────┐
│                     Browser (React)                     │
│              http://localhost:3000                      │
└────────────────┬────────────────┬───────────────────────┘
                 │                │
        Login/Register        Get Products
                 │                │
                 ▼                ▼
┌───────────────────┐    ┌─────────────────────┐
│   Spring Boot     │    │     PHP API         │
│  (Auth Service)   │    │  (Products Service) │
│  localhost:8080   │    │  localhost:8081     │
└────────┬──────────┘    └──────────┬──────────┘
         │                          │
         └──────────┬───────────────┘
                    ▼
         ┌─────────────────┐
         │   PostgreSQL    │
         │   (Database)    │
         │  localhost:5434 │
         └─────────────────┘
```

| Service | Technology | Responsibility |
|---|---|---|
| `sb/` | Spring Boot (Java) | User registration, login, JWT issuing |
| `php/` | PHP + Apache | Product catalog, JWT validation |
| `react/` | React + Vite | Frontend UI |
| `db` | PostgreSQL | Shared database |

---

## How Authentication Works Across Services

This is the key concept of the project. Notice that **PHP never handles login** — it just trusts the token that Spring Boot issued.

```
1. User logs in via React
        ↓
2. React sends credentials to Spring Boot (POST /api/auth/login)
        ↓
3. Spring Boot verifies password, creates a JWT token, and stores it
   in an HttpOnly cookie named "jwt" (browser can't read it via JS)
        ↓
4. User visits the Product Catalog
        ↓
5. React calls PHP API (GET /products)
   Browser automatically sends the "jwt" cookie with the request
        ↓
6. PHP reads the cookie, verifies the JWT signature using the
   same shared secret key, and returns the products
```

The shared secret (`JWT_SECRET`) is the trust bridge between Spring Boot and PHP. Both services must have the exact same value.

---

## Prerequisites

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) installed and running
- That's it — no Java, PHP, or Node.js needed on your machine

---

## Running the Project

From the project root (where `docker-compose.yml` is):

```bash
# First time — pulls images and installs all dependencies
docker compose up -d

# View logs from all services
docker compose logs -f

# View logs from one service
docker compose logs -f php

# Stop everything
docker compose down

# Stop and delete the database volume (full reset)
docker compose down -v
```

Once running, open your browser at **http://localhost:3000**

---

## Service URLs

| URL | What it is |
|---|---|
| http://localhost:3000 | React frontend |
| http://localhost:8080 | Spring Boot auth API |
| http://localhost:8081 | PHP products API |
| http://localhost:5434 | PostgreSQL (connect with a DB client) |

---

## Quick API Test (without the UI)

```bash
# 1. Register a user
curl -c cookies.txt -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"student","password":"password123"}'

# 2. Use the saved cookie to call the PHP service
curl -b cookies.txt http://localhost:8081/products
```

---

## Project Structure

```
/
├── docker-compose.yml   ← Defines and connects all services
├── react/               ← Frontend (React + Vite + Tailwind)
├── sb/                  ← Auth microservice (Spring Boot)
└── php/                 ← Products microservice (PHP)
```

Each folder has its own `README.md` with a deeper explanation of that service.

---

## Key Concepts to Study

- **JWT (JSON Web Token)** — a signed token that proves who you are without needing a session
- **HttpOnly Cookie** — a cookie the browser sends automatically but JavaScript cannot read (safer than localStorage)
- **CORS** — browser security that controls which origins can call your API
- **Docker Compose** — a tool to run multiple containers as one application
- **Shared Secret** — how two services trust each other without direct communication
