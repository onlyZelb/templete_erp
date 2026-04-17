<?php
namespace App\Controllers;

use App\Core\Router;
use PDO;

class RideController {
    private PDO $db;

    public function __construct(PDO $db) {
        $this->db = $db;
    }

    // POST /rides — create a new booking
    public function book(array $user): void {
        $data = json_decode(file_get_contents('php://input'), true);

        $stmt = $this->db->prepare("
            INSERT INTO rides (passenger_id, pickup_location, destination, status, fare)
            VALUES (:passenger_id, :pickup, :destination, 'pending', :fare)
            RETURNING id, passenger_id, pickup_location, destination, fare, status, created_at
        ");

        $fare = $this->computeFare($data['pickup_location'], $data['destination']);

        $stmt->execute([
            'passenger_id'  => $user['id'],
            'pickup'        => $data['pickup_location'],
            'destination'   => $data['destination'],
            'fare'          => $fare,
        ]);

        $ride = $stmt->fetch(PDO::FETCH_ASSOC);
        http_response_code(201);
        echo json_encode($ride);
    }

    // GET /rides — ride history for the current user
    public function history(array $user): void {
        $stmt = $this->db->prepare("
            SELECT r.*, u.name AS driver_name
            FROM rides r
            LEFT JOIN users u ON u.id = r.driver_id
            WHERE r.passenger_id = :id
            ORDER BY r.created_at DESC
        ");
        $stmt->execute(['id' => $user['id']]);
        echo json_encode($stmt->fetchAll(PDO::FETCH_ASSOC));
    }

    // PATCH /rides/{id}/cancel
    public function cancel(array $user, int $id): void {
        $stmt = $this->db->prepare("
            UPDATE rides SET status = 'cancelled'
            WHERE id = :id AND passenger_id = :passenger_id AND status = 'pending'
            RETURNING *
        ");
        $stmt->execute(['id' => $id, 'passenger_id' => $user['id']]);
        $ride = $stmt->fetch(PDO::FETCH_ASSOC);

        if (!$ride) {
            http_response_code(404);
            echo json_encode(['error' => 'Ride not found or cannot be cancelled']);
            return;
        }
        echo json_encode($ride);
    }

    // GET /rides/fare?pickup=...&destination=...
    public function fareEstimate(): void {
        $pickup      = $_GET['pickup'] ?? '';
        $destination = $_GET['destination'] ?? '';
        $fare        = $this->computeFare($pickup, $destination);
        echo json_encode(['fare' => $fare]);
    }

    // Basic flat-rate fare logic — update as needed
    private function computeFare(string $pickup, string $destination): float {
        $baseFare    = 15.00;   // PHP pesos base flag-down
        $ratePerKm   = 3.50;
        $estimatedKm = 3.0;     // placeholder until GPS integration
        return round($baseFare + ($ratePerKm * $estimatedKm), 2);
    }
}