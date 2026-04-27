<?php

namespace App\Controllers;

use PDO;

class RideController
{
    private PDO $db;

    public function __construct(PDO $db)
    {
        $this->db = $db;
    }

    public function book(object $user): void
    {
        $data = json_decode(file_get_contents('php://input'), true);

        $commuterId = $this->getCommuterId($user->sub);

        $fare = $this->computeFare(
            $data['pickup_location'],
            $data['destination']
        );

        $stmt = $this->db->prepare("
            INSERT INTO rides (commuter_id, pickup_location, destination, fare, status)
            VALUES (:commuter_id, :pickup, :destination, :fare, 'pending')
            RETURNING id, commuter_id, pickup_location, destination, fare, status, created_at
        ");

        $stmt->execute([
            'commuter_id' => $commuterId,
            'pickup'      => $data['pickup_location'],
            'destination' => $data['destination'],
            'fare'        => $fare,
        ]);

        $ride = $stmt->fetch(PDO::FETCH_ASSOC);
        http_response_code(201);
        echo json_encode($ride);
    }

    public function history(object $user): void
    {
        $commuterId = $this->getCommuterId($user->sub);

        $stmt = $this->db->prepare("
            SELECT r.*, d.username AS driver_username
            FROM rides r
            LEFT JOIN drivers d ON d.id = r.driver_id
            WHERE r.commuter_id = :commuter_id
            ORDER BY r.created_at DESC
        ");
        $stmt->execute(['commuter_id' => $commuterId]);
        echo json_encode($stmt->fetchAll(PDO::FETCH_ASSOC));
    }

    public function cancel(object $user, int $id): void
    {
        $commuterId = $this->getCommuterId($user->sub);

        $stmt = $this->db->prepare("
            UPDATE rides SET status = 'cancelled'
            WHERE id = :id AND commuter_id = :commuter_id AND status = 'pending'
            RETURNING *
        ");
        $stmt->execute(['id' => $id, 'commuter_id' => $commuterId]);
        $ride = $stmt->fetch(PDO::FETCH_ASSOC);

        if (!$ride) {
            http_response_code(404);
            echo json_encode(['error' => 'Ride not found or cannot be cancelled']);
            return;
        }
        echo json_encode($ride);
    }

    public function fareEstimate(): void
    {
        $pickup      = $_GET['pickup'] ?? '';
        $destination = $_GET['destination'] ?? '';
        $fare        = $this->computeFare($pickup, $destination);
        echo json_encode(['fare' => $fare]);
    }

    private function getCommuterId(string $username): int
    {
        $stmt = $this->db->prepare("
            SELECT id FROM commuters WHERE username = :username
        ");
        $stmt->execute(['username' => $username]);
        $commuter = $stmt->fetch(PDO::FETCH_ASSOC);

        if (!$commuter) {
            http_response_code(403);
            echo json_encode(['error' => 'Only commuters can book rides']);
            exit();
        }

        return (int) $commuter['id'];
    }

    private function computeFare(string $pickup, string $destination): float
    {
        $baseFare    = 15.00;
        $ratePerKm   = 3.50;
        $estimatedKm = 3.0;
        return round($baseFare + ($ratePerKm * $estimatedKm), 2);
    }
}