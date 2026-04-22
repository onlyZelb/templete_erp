CREATE TABLE IF NOT EXISTS rides (
    id               BIGSERIAL PRIMARY KEY,
    commuter_id      BIGINT NOT NULL REFERENCES commuters(id),
    driver_id        BIGINT REFERENCES drivers(id),
    pickup_location  TEXT   NOT NULL,
    destination      TEXT   NOT NULL,
    fare             NUMERIC(8,2) NOT NULL DEFAULT 0,
    status           VARCHAR(20)  NOT NULL DEFAULT 'pending'
                     CHECK (status IN ('pending','accepted','ongoing','completed','cancelled')),
    created_at       TIMESTAMPTZ DEFAULT NOW(),
    updated_at       TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_rides_commuter ON rides(commuter_id);
CREATE INDEX IF NOT EXISTS idx_rides_driver   ON rides(driver_id);
CREATE INDEX IF NOT EXISTS idx_rides_status   ON rides(status);