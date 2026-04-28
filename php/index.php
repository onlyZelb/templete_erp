<?php

declare(strict_types=1);

// ── Load Docker environment variables into getenv() ───────────────────────────
foreach ($_ENV as $key => $value) {
    putenv("$key=$value");
}

// ── CORS headers ──────────────────────────────────────────────────────────────
$origin = $_SERVER['HTTP_ORIGIN'] ?? '';

// Allow any localhost port (for Flutter web dev on random ports)
$allowedOrigin = 'http://localhost:3000';
if (preg_match('/^http:\/\/localhost(:\d+)?$/', $origin)) {
    $allowedOrigin = $origin;
} elseif (preg_match('/^http:\/\/192\.168\.\d+\.\d+(:\d+)?$/', $origin)) {
    $allowedOrigin = $origin;
}

header("Access-Control-Allow-Origin: $allowedOrigin");
header('Access-Control-Allow-Credentials: true');
header('Access-Control-Allow-Methods: GET, POST, PATCH, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization, Cookie');
header('Content-Type: application/json');

// Handle pre-flight
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// ── Autoloader (Composer) ─────────────────────────────────────────────────────
require_once __DIR__ . '/vendor/autoload.php';

// ── Routes ───────────────────────────────────────────────────────────────────
require_once __DIR__ . '/src/routes.php';