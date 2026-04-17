<?php
namespace App\Core;

use App\Controllers\RideController;
use App\Middleware\JwtMiddleware;
use PDO;

class Router {
    private PDO $db;

    public function __construct(PDO $db) {
        $this->db = $db;
    }

    public function dispatch(string $method, string $uri): void {
        $controller = new RideController($this->db);
        $user       = null;

        // Strip query string
        $path = strtok($uri, '?');

        // Public route — no JWT needed
        if ($method === 'GET' && $path === '/rides/fare') {
            $controller->fareEstimate();
            return;
        }

        // All other routes require a valid JWT
        $user = JwtMiddleware::authenticate();

        match (true) {
            $method === 'POST' && $path === '/rides'
                => $controller->book($user),

            $method === 'GET' && $path === '/rides'
                => $controller->history($user),

            $method === 'PATCH' && preg_match('#^/rides/(\d+)/cancel$#', $path, $m)
                => $controller->cancel($user, (int)$m[1]),

            default => $this->notFound(),
        };
    }

    private function notFound(): void {
        http_response_code(404);
        echo json_encode(['error' => 'Route not found']);
    }
}