package com.pasadanow.FinalProject.repository;

import com.pasadanow.FinalProject.model.Driver;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.Optional;

public interface DriverRepository extends JpaRepository<Driver, Long> {
    Optional<Driver> findByUsername(String username);

    boolean existsByUsername(String username);
}