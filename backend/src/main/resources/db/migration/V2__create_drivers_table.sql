CREATE TABLE IF NOT EXISTS drivers (
    id              BIGSERIAL PRIMARY KEY,
    username        VARCHAR(50)  NOT NULL UNIQUE,
    password        VARCHAR(255) NOT NULL,
    full_name       VARCHAR(100),
    phone           VARCHAR(20),
    email           VARCHAR(100),
    license_no      VARCHAR(50)  NOT NULL,
    plate_no        VARCHAR(30)  NOT NULL,
    toda_no         VARCHAR(50),
    profile_photo   TEXT,
    is_online       BOOLEAN      DEFAULT FALSE,
    verified_status VARCHAR(20)  NOT NULL DEFAULT 'pending'
                    CHECK (verified_status IN ('pending','verified','rejected')),
    created_at      TIMESTAMPTZ  DEFAULT NOW(),
    updated_at      TIMESTAMPTZ  DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_drivers_username ON drivers(username);