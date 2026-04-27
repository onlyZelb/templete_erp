import { useState, useEffect } from "react";
import logo from "../assets/logo.png";
import { useAuth } from "../hooks/useAuth";

// ─── Config ───────────────────────────────────────────────────────────────────
const DJANGO_URL =
  import.meta.env.VITE_DJANGO_API_URL || "http://localhost:8082";

// ─── Helper: get token from localStorage (no cookies) ────────────────────────
function getAuthToken() {
  return (
    localStorage.getItem("token") ||
    localStorage.getItem("access_token") ||
    localStorage.getItem("authToken") ||
    null
  );
}

// ─── Helper: build fetch options WITHOUT sending cookies ──────────────────────
function authFetch(url, options = {}) {
  const token = getAuthToken();
  return fetch(url, {
    ...options,
    credentials: "omit",
    headers: {
      "Content-Type": "application/json",
      Accept: "application/json",
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
      ...(options.headers || {}),
    },
  });
}

// ─── SVG Icons ────────────────────────────────────────────────────────────────
const Icon = ({ name, size = 16 }) => {
  const icons = {
    grid: (
      <svg
        width={size}
        height={size}
        viewBox="0 0 24 24"
        fill="none"
        stroke="currentColor"
        strokeWidth="1.8"
        strokeLinecap="round"
        strokeLinejoin="round"
      >
        <rect x="3" y="3" width="7" height="7" rx="1" />
        <rect x="14" y="3" width="7" height="7" rx="1" />
        <rect x="3" y="14" width="7" height="7" rx="1" />
        <rect x="14" y="14" width="7" height="7" rx="1" />
      </svg>
    ),
    clock: (
      <svg
        width={size}
        height={size}
        viewBox="0 0 24 24"
        fill="none"
        stroke="currentColor"
        strokeWidth="1.8"
        strokeLinecap="round"
      >
        <circle cx="12" cy="12" r="9" />
        <polyline points="12 7 12 12 15.5 14" />
      </svg>
    ),
    users: (
      <svg
        width={size}
        height={size}
        viewBox="0 0 24 24"
        fill="none"
        stroke="currentColor"
        strokeWidth="1.8"
        strokeLinecap="round"
        strokeLinejoin="round"
      >
        <path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2" />
        <circle cx="9" cy="7" r="4" />
        <path d="M23 21v-2a4 4 0 0 0-3-3.87" />
        <path d="M16 3.13a4 4 0 0 1 0 7.75" />
      </svg>
    ),
    tricycle: (
      <svg
        width={size}
        height={size}
        viewBox="0 0 24 24"
        fill="none"
        stroke="currentColor"
        strokeWidth="1.8"
        strokeLinecap="round"
        strokeLinejoin="round"
      >
        <circle cx="5" cy="17" r="2.5" />
        <circle cx="17" cy="17" r="2.5" />
        <path d="M5 17H3V9l4-4h7l3 5 2 1v6h-2" />
        <path d="M9 5v6h8" />
      </svg>
    ),
    logout: (
      <svg
        width={size}
        height={size}
        viewBox="0 0 24 24"
        fill="none"
        stroke="currentColor"
        strokeWidth="1.8"
        strokeLinecap="round"
        strokeLinejoin="round"
      >
        <path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4" />
        <polyline points="16 17 21 12 16 7" />
        <line x1="21" y1="12" x2="9" y2="12" />
      </svg>
    ),
    check: (
      <svg
        width={size}
        height={size}
        viewBox="0 0 24 24"
        fill="none"
        stroke="currentColor"
        strokeWidth="2.5"
        strokeLinecap="round"
        strokeLinejoin="round"
      >
        <polyline points="20 6 9 17 4 12" />
      </svg>
    ),
    x: (
      <svg
        width={size}
        height={size}
        viewBox="0 0 24 24"
        fill="none"
        stroke="currentColor"
        strokeWidth="2.2"
        strokeLinecap="round"
      >
        <line x1="18" y1="6" x2="6" y2="18" />
        <line x1="6" y1="6" x2="18" y2="18" />
      </svg>
    ),
    refresh: (
      <svg
        width={size}
        height={size}
        viewBox="0 0 24 24"
        fill="none"
        stroke="currentColor"
        strokeWidth="1.8"
        strokeLinecap="round"
        strokeLinejoin="round"
      >
        <polyline points="23 4 23 10 17 10" />
        <path d="M20.49 15a9 9 0 1 1-2.12-9.36L23 10" />
      </svg>
    ),
  };
  return icons[name] || null;
};

// ─── Nav config ───────────────────────────────────────────────────────────────
const NAV = [
  { id: "overview", label: "Overview", icon: "grid" },
  { id: "trips", label: "Trip Records", icon: "clock" },
  { id: "commuters", label: "Commuters", icon: "users" },
  { id: "drivers", label: "Partner Drivers", icon: "tricycle" },
];

const TITLES = {
  overview: "Command Center",
  drivers: "Partner Drivers",
  commuters: "Commuters",
  trips: "Trip Records",
};

// ─── Field resolution helpers ─────────────────────────────────────────────────
function getDisplayName(u) {
  return u?.full_name || u?.fullName || u?.name || u?.username || "?";
}
function getPhone(u) {
  return u?.phone || u?.contact_no || u?.contactNo || u?.contact_number || "—";
}
function getPlateNo(u) {
  return u?.plate_no || u?.plate_number || u?.plateNo || u?.plateNumber || null;
}
function getLicenseNo(u) {
  return u?.license_no || u?.license_number || u?.licenseNo || null;
}
function getOrganization(u) {
  return u?.toda_no || u?.organization || u?.todaNo || u?.branch || null;
}
function getAddress(u) {
  return u?.address || u?.home_address || u?.homeAddress || null;
}
function ini(n) {
  const p = (n || "?").trim().split(" ");
  return (p[0][0] + (p[1] ? p[1][0] : "")).toUpperCase();
}
function fmtP(n) {
  return (
    "₱" + Number(n || 0).toLocaleString("en-PH", { minimumFractionDigits: 2 })
  );
}
function fmtD(s) {
  if (!s) return "—";
  return new Date(s).toLocaleDateString("en-PH", {
    month: "short",
    day: "numeric",
    year: "numeric",
  });
}
function fmtDT(s) {
  if (!s) return "—";
  return new Date(s).toLocaleDateString("en-PH", {
    month: "short",
    day: "numeric",
    year: "numeric",
    hour: "2-digit",
    minute: "2-digit",
  });
}

function useClock() {
  const [clock, setClock] = useState("");
  useEffect(() => {
    const tick = () => {
      const now = new Date();
      const D = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];
      const M = [
        "Jan",
        "Feb",
        "Mar",
        "Apr",
        "May",
        "Jun",
        "Jul",
        "Aug",
        "Sep",
        "Oct",
        "Nov",
        "Dec",
      ];
      let h = now.getHours();
      const ap = h >= 12 ? "PM" : "AM";
      h = h % 12 || 12;
      setClock(
        `${D[now.getDay()]}, ${M[now.getMonth()]} ${now.getDate()} · ${h}:${String(now.getMinutes()).padStart(2, "0")}:${String(now.getSeconds()).padStart(2, "0")} ${ap}`,
      );
    };
    tick();
    const id = setInterval(tick, 1000);
    return () => clearInterval(id);
  }, []);
  return clock;
}

// ─── Shared verify API call ───────────────────────────────────────────────────
async function callVerify(uid, role, newStatus, setUsers, setModalId) {
  try {
    const res = await authFetch(`${DJANGO_URL}/api/admin/users/${uid}/verify`, {
      method: "PATCH",
      body: JSON.stringify({ role, action: newStatus }),
    });
    if (!res.ok) throw new Error(`HTTP ${res.status}`);
    setUsers((prev) =>
      prev.map((u) =>
        u.id === uid && u.role === role
          ? { ...u, status: newStatus, verified_status: newStatus }
          : u,
      ),
    );
    setModalId(null);
  } catch (e) {
    console.error("Verify failed:", e);
    alert("Could not update status. Is Django running on port 8082?");
  }
}

// ─── Photo helpers ────────────────────────────────────────────────────────────
// FIX: The old code had `val.startsWith("http") || val.startsWith("/")` which
// incorrectly treated base64 JPEG strings (which start with "/9j/") as URL
// paths, causing the browser to request http://localhost:3000/9j/4AAQ...
// and blow past the 8KB header limit (HTTP 431).
// Now we only treat genuine http:// / https:// strings as URLs.
function toImgSrc(val) {
  if (!val) return null;
  if (typeof val !== "string") return null;
  // Already a data URI — use as-is
  if (val.startsWith("data:")) return val;
  // Genuine absolute URL — use as-is
  if (val.startsWith("http://") || val.startsWith("https://")) return val;
  // Guard against broken/too-short strings (not real base64 images)
  if (val.length < 100) return null;
  // Everything else is raw base64 — wrap it properly
  return `data:image/jpeg;base64,${val}`;
}

// ─── Shared Components ────────────────────────────────────────────────────────
function Avatar({ name, role, size = 32 }) {
  return (
    <div
      style={{
        width: size,
        height: size,
        borderRadius: "50%",
        display: "flex",
        alignItems: "center",
        justifyContent: "center",
        fontSize: size * 0.3 + "px",
        fontWeight: 700,
        color: "#fff",
        flexShrink: 0,
        background:
          role === "driver"
            ? "linear-gradient(135deg,#f97316,#c2410c)"
            : "linear-gradient(135deg,#3b82f6,#1d4ed8)",
      }}
    >
      {ini(name)}
    </div>
  );
}

function StatusBadge({ status }) {
  const map = {
    completed: {
      bg: "rgba(74,222,128,.08)",
      color: "#4ade80",
      dot: "#4ade80",
      border: "rgba(74,222,128,.2)",
    },
    pending: {
      bg: "rgba(250,204,21,.08)",
      color: "#facc15",
      dot: "#facc15",
      border: "rgba(250,204,21,.2)",
    },
    cancelled: {
      bg: "rgba(248,113,113,.08)",
      color: "#f87171",
      dot: "#f87171",
      border: "rgba(248,113,113,.2)",
    },
    active: {
      bg: "rgba(96,165,250,.08)",
      color: "#60a5fa",
      dot: "#60a5fa",
      border: "rgba(96,165,250,.2)",
    },
    verified: {
      bg: "rgba(74,222,128,.08)",
      color: "#4ade80",
      dot: "#4ade80",
      border: "rgba(74,222,128,.2)",
    },
    rejected: {
      bg: "rgba(248,113,113,.08)",
      color: "#f87171",
      dot: "#f87171",
      border: "rgba(248,113,113,.2)",
    },
  };
  const c = map[status] || map.active;
  return (
    <span
      style={{
        display: "inline-flex",
        alignItems: "center",
        gap: 5,
        padding: "3px 9px",
        borderRadius: 20,
        fontSize: "0.58rem",
        fontWeight: 700,
        background: c.bg,
        color: c.color,
        border: `1px solid ${c.border}`,
      }}
    >
      <span
        style={{
          width: 5,
          height: 5,
          borderRadius: "50%",
          background: c.dot,
          flexShrink: 0,
        }}
      />
      {status.charAt(0).toUpperCase() + status.slice(1)}
    </span>
  );
}

function StatCard({ icon, value, label, color = "blue" }) {
  const colors = {
    blue: { icon: "rgba(59,130,246,.12)", iconColor: "#60a5fa" },
    green: { icon: "rgba(74,222,128,.1)", iconColor: "#4ade80" },
    orange: { icon: "rgba(251,146,60,.1)", iconColor: "#fb923c" },
    yellow: { icon: "rgba(250,204,21,.1)", iconColor: "#facc15" },
    red: { icon: "rgba(248,113,113,.1)", iconColor: "#f87171" },
    purple: { icon: "rgba(192,132,252,.1)", iconColor: "#c084fc" },
  };
  const c = colors[color] || colors.blue;
  return (
    <div style={ds.statCard}>
      <div
        style={{
          display: "flex",
          justifyContent: "space-between",
          alignItems: "flex-start",
          marginBottom: 12,
        }}
      >
        <div
          style={{
            width: 34,
            height: 34,
            borderRadius: 9,
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
            background: c.icon,
            color: c.iconColor,
          }}
        >
          <Icon name={icon} size={17} />
        </div>
      </div>
      <div
        style={{
          fontSize: "1.3rem",
          fontWeight: 800,
          color: "#d4e8ff",
          marginBottom: 3,
          letterSpacing: "-.3px",
        }}
      >
        {value}
      </div>
      <div
        style={{
          fontSize: "0.54rem",
          textTransform: "uppercase",
          letterSpacing: "1.8px",
          color: "#2a4a6a",
          fontWeight: 700,
        }}
      >
        {label}
      </div>
    </div>
  );
}

function EmptyState({ icon, title, desc }) {
  return (
    <div style={{ textAlign: "center", padding: "60px 20px" }}>
      <div style={{ fontSize: 40, marginBottom: 14, opacity: 0.4 }}>
        <Icon name={icon} size={40} />
      </div>
      <div
        style={{
          fontSize: "0.88rem",
          fontWeight: 600,
          color: "#3a5a7a",
          marginBottom: 6,
        }}
      >
        {title}
      </div>
      <div style={{ fontSize: "0.75rem", color: "#1e3a52" }}>{desc}</div>
    </div>
  );
}

function InfoItem({ label, value }) {
  return (
    <div
      style={{
        background: "rgba(0,0,0,.25)",
        border: "1px solid rgba(60,110,160,.1)",
        borderRadius: 8,
        padding: "9px 11px",
      }}
    >
      <div
        style={{
          fontSize: "0.54rem",
          fontWeight: 700,
          textTransform: "uppercase",
          color: "#1e5a8a",
          letterSpacing: "1.2px",
          marginBottom: 3,
        }}
      >
        {label}
      </div>
      <div style={{ fontSize: "0.77rem", fontWeight: 600, color: "#cce0f5" }}>
        {value || "—"}
      </div>
    </div>
  );
}

function reviewBtnStyle(status) {
  const pending = status === "pending";
  return {
    padding: "4px 13px",
    background: pending ? "rgba(251,146,60,.06)" : "rgba(255,255,255,.04)",
    border: `1px solid ${pending ? "rgba(251,146,60,.3)" : "rgba(60,110,160,.18)"}`,
    borderRadius: 7,
    color: pending ? "#fb923c" : "#8ab4d4",
    fontSize: "0.63rem",
    fontWeight: 700,
    cursor: "pointer",
  };
}

// ─── Credential Photo ─────────────────────────────────────────────────────────
function CredentialPhoto({ label, value }) {
  const [expanded, setExpanded] = useState(false);
  const [failed, setFailed] = useState(false);
  const src = toImgSrc(value);
  const showImage = src && !failed;

  return (
    <div style={{ display: "flex", flexDirection: "column", gap: 6 }}>
      <div
        style={{
          fontSize: "0.54rem",
          fontWeight: 700,
          textTransform: "uppercase",
          color: "#1e5a8a",
          letterSpacing: "1.2px",
        }}
      >
        {label}
      </div>
      {showImage ? (
        <>
          <div
            onClick={() => setExpanded(true)}
            style={{
              width: "100%",
              aspectRatio: "4/3",
              borderRadius: 8,
              overflow: "hidden",
              cursor: "zoom-in",
              position: "relative",
              border: "1px solid rgba(60,110,160,.18)",
              background: "rgba(0,0,0,.35)",
            }}
          >
            <img
              src={src}
              alt={label}
              onError={() => setFailed(true)}
              style={{
                width: "100%",
                height: "100%",
                objectFit: "cover",
                display: "block",
              }}
            />
            <div
              className="photo-hover-overlay"
              style={{
                position: "absolute",
                inset: 0,
                display: "flex",
                alignItems: "center",
                justifyContent: "center",
                opacity: 0,
                transition: "opacity .18s",
                background: "rgba(0,0,0,.5)",
              }}
            >
              <span
                style={{
                  fontSize: "0.6rem",
                  color: "#fff",
                  fontWeight: 700,
                  background: "rgba(0,0,0,.6)",
                  padding: "3px 9px",
                  borderRadius: 5,
                }}
              >
                🔍 Expand
              </span>
            </div>
          </div>
          {expanded && (
            <div
              onClick={() => setExpanded(false)}
              style={{
                position: "fixed",
                inset: 0,
                zIndex: 200,
                background: "rgba(0,0,0,.93)",
                backdropFilter: "blur(8px)",
                display: "flex",
                flexDirection: "column",
                alignItems: "center",
                justifyContent: "center",
                padding: 24,
                cursor: "zoom-out",
              }}
            >
              <div
                style={{
                  fontSize: "0.62rem",
                  fontWeight: 700,
                  textTransform: "uppercase",
                  letterSpacing: "2px",
                  color: "#3a5a7a",
                  marginBottom: 16,
                }}
              >
                {label}
              </div>
              <img
                src={src}
                alt={label}
                style={{
                  maxWidth: "88vw",
                  maxHeight: "80vh",
                  objectFit: "contain",
                  borderRadius: 10,
                  boxShadow: "0 30px 80px rgba(0,0,0,.9)",
                }}
              />
              <div
                style={{ marginTop: 16, fontSize: "0.63rem", color: "#2a4a6a" }}
              >
                click anywhere to close
              </div>
            </div>
          )}
        </>
      ) : (
        <div
          style={{
            width: "100%",
            aspectRatio: "4/3",
            borderRadius: 8,
            border: "1px dashed rgba(60,110,160,.18)",
            background: "rgba(0,0,0,.15)",
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
            fontSize: "0.65rem",
            color: "#1e3a52",
          }}
        >
          {failed ? "Failed to load" : "Not uploaded"}
        </div>
      )}
    </div>
  );
}

// ─── Overview Tab ─────────────────────────────────────────────────────────────
function OverviewView({ users, trips }) {
  const drivers = users.filter((u) => u.role === "driver");
  const commuters = users.filter((u) => u.role === "commuter");
  const revenue = trips
    .filter((t) => t.status === "completed")
    .reduce((a, t) => a + t.fare, 0);
  return (
    <>
      <div
        style={{
          display: "grid",
          gridTemplateColumns: "repeat(4,1fr)",
          gap: 10,
          marginBottom: 14,
        }}
      >
        <StatCard
          icon="clock"
          value={trips.length}
          label="Total Bookings"
          color="blue"
        />
        <StatCard
          icon="tricycle"
          value={drivers.length}
          label="Active Drivers"
          color="green"
        />
        <StatCard
          icon="users"
          value={commuters.length}
          label="Total Commuters"
          color="purple"
        />
        <StatCard
          icon="check"
          value={fmtP(revenue)}
          label="Total Revenue"
          color="orange"
        />
      </div>
      <div
        style={{ display: "grid", gridTemplateColumns: "1.6fr .4fr", gap: 10 }}
      >
        <div style={ds.tableCard}>
          <div style={ds.tcHead}>
            <div style={ds.tcTitle}>
              <span style={ds.dotPulse} />
              Recent Trips
            </div>
          </div>
          {trips.length === 0 ? (
            <EmptyState
              icon="clock"
              title="No trips yet"
              desc="Trip records will appear here once bookings are made."
            />
          ) : (
            <div style={{ overflowX: "auto" }}>
              <table style={{ width: "100%", borderCollapse: "collapse" }}>
                <thead>
                  <tr>
                    {[
                      "Trip ID",
                      "Commuter",
                      "Driver",
                      "Route",
                      "Fare",
                      "Status",
                    ].map((h) => (
                      <th key={h} style={ds.th}>
                        {h}
                      </th>
                    ))}
                  </tr>
                </thead>
                <tbody>
                  {trips.slice(0, 5).map((t) => (
                    <tr key={t.id} style={ds.tr}>
                      <td style={ds.td}>
                        <span style={ds.tripId}>#{t.id}</span>
                      </td>
                      <td
                        style={{ ...ds.td, color: "#cce0f5", fontWeight: 500 }}
                      >
                        {t.commuter_name}
                      </td>
                      <td style={{ ...ds.td, color: "#8ab4d4" }}>
                        {t.driver_name}
                      </td>
                      <td
                        style={{
                          ...ds.td,
                          fontSize: "0.68rem",
                          color: "#5a8ab0",
                        }}
                      >
                        {t.origin} → {t.destination}
                      </td>
                      <td
                        style={{ ...ds.td, color: "#4ade80", fontWeight: 700 }}
                      >
                        {fmtP(t.fare)}
                      </td>
                      <td style={ds.td}>
                        <StatusBadge status={t.status} />
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </div>
        <div style={{ ...ds.tableCard, padding: 14 }}>
          <div style={ds.tcTitle}>
            <span style={ds.dotPulse} />
            Fleet Summary
          </div>
          <div
            style={{
              borderTop: "1px solid rgba(60,110,160,.08)",
              marginTop: 12,
              paddingTop: 10,
            }}
          >
            {[
              ["Total Drivers", drivers.length, null],
              ["Total Commuters", commuters.length, null],
              ["Total Bookings", trips.length, null],
              [
                "Verified Users",
                users.filter((u) => u.status === "verified").length,
                "#4ade80",
              ],
              ["Total Revenue", fmtP(revenue), "#fb923c"],
            ].map(([l, v, col]) => (
              <div
                key={l}
                style={{
                  display: "flex",
                  justifyContent: "space-between",
                  alignItems: "center",
                  padding: "8px 0",
                  borderBottom: "1px solid rgba(60,110,160,.05)",
                  fontSize: "0.73rem",
                  color: "#3a5a7a",
                }}
              >
                <span>{l}</span>
                <span style={{ fontWeight: 700, color: col || "#aec8e0" }}>
                  {v}
                </span>
              </div>
            ))}
          </div>
          {users.filter((u) => u.status === "pending").length > 0 && (
            <div
              style={{
                marginTop: 14,
                padding: "10px 12px",
                background: "rgba(251,146,60,.06)",
                border: "1px solid rgba(251,146,60,.18)",
                borderRadius: 9,
              }}
            >
              <div
                style={{
                  fontSize: "0.56rem",
                  fontWeight: 700,
                  textTransform: "uppercase",
                  color: "#fb923c",
                  letterSpacing: "1.2px",
                }}
              >
                ⚠ Pending Action
              </div>
              <div
                style={{ fontSize: "0.72rem", color: "#ffd699", marginTop: 3 }}
              >
                {users.filter((u) => u.status === "pending").length} user
                {users.filter((u) => u.status === "pending").length !== 1
                  ? "s"
                  : ""}{" "}
                awaiting verification
              </div>
            </div>
          )}
        </div>
      </div>
    </>
  );
}

// ─── Trips Tab ────────────────────────────────────────────────────────────────
const PER = 8;

function TripsView({ trips }) {
  const [filter, setFilter] = useState("all");
  const [page, setPage] = useState(1);
  const filtered = trips.filter((t) => filter === "all" || t.status === filter);
  const total = Math.max(1, Math.ceil(filtered.length / PER));
  const cur = Math.min(page, total);
  const rows = filtered.slice((cur - 1) * PER, cur * PER);
  const revenue = trips
    .filter((t) => t.status === "completed")
    .reduce((a, t) => a + t.fare, 0);
  const statuses = ["all", "completed", "active", "pending", "cancelled"];
  return (
    <>
      <div
        style={{
          display: "grid",
          gridTemplateColumns: "repeat(5,1fr)",
          gap: 10,
          marginBottom: 14,
        }}
      >
        <StatCard
          icon="grid"
          value={trips.length}
          label="Total Trips"
          color="blue"
        />
        <StatCard
          icon="check"
          value={trips.filter((t) => t.status === "completed").length}
          label="Completed"
          color="green"
        />
        <StatCard
          icon="clock"
          value={trips.filter((t) => t.status === "active").length}
          label="Active"
          color="blue"
        />
        <StatCard
          icon="clock"
          value={trips.filter((t) => t.status === "pending").length}
          label="Pending"
          color="yellow"
        />
        <StatCard
          icon="x"
          value={trips.filter((t) => t.status === "cancelled").length}
          label="Cancelled"
          color="red"
        />
      </div>
      {trips.length > 0 && (
        <div
          style={{
            background: "rgba(251,146,60,.06)",
            border: "1px solid rgba(251,146,60,.18)",
            borderRadius: 12,
            padding: "14px 20px",
            marginBottom: 14,
          }}
        >
          <div
            style={{
              fontSize: "0.56rem",
              fontWeight: 700,
              textTransform: "uppercase",
              color: "#b06030",
              letterSpacing: "1.5px",
              marginBottom: 4,
            }}
          >
            Total Revenue · Completed Trips
          </div>
          <div
            style={{
              fontSize: "1.6rem",
              fontWeight: 800,
              color: "#fb923c",
              letterSpacing: "-.5px",
            }}
          >
            {fmtP(revenue)}
          </div>
        </div>
      )}
      <div style={ds.tableCard}>
        <div style={{ ...ds.tcHead, flexWrap: "wrap", gap: 8 }}>
          <div style={ds.tcTitle}>
            <span style={ds.dotPulse} />
            All Trips
          </div>
          <div style={{ display: "flex", gap: 4, flexWrap: "wrap" }}>
            {statuses.map((st) => (
              <button
                key={st}
                onClick={() => {
                  setFilter(st);
                  setPage(1);
                }}
                style={{ ...ds.pill, ...(filter === st ? ds.pillActive : {}) }}
              >
                {st.charAt(0).toUpperCase() + st.slice(1)}
              </button>
            ))}
          </div>
        </div>
        {trips.length === 0 ? (
          <EmptyState
            icon="clock"
            title="No trip records"
            desc="All bookings will be listed here."
          />
        ) : (
          <>
            <div style={{ overflowX: "auto" }}>
              <table style={{ width: "100%", borderCollapse: "collapse" }}>
                <thead>
                  <tr>
                    {[
                      "Trip ID",
                      "Commuter",
                      "Driver",
                      "Origin",
                      "Destination",
                      "Fare",
                      "Date",
                      "Status",
                    ].map((h) => (
                      <th key={h} style={ds.th}>
                        {h}
                      </th>
                    ))}
                  </tr>
                </thead>
                <tbody>
                  {rows.length === 0 ? (
                    <tr>
                      <td
                        colSpan="8"
                        style={{
                          textAlign: "center",
                          padding: "40px",
                          color: "#1e3a52",
                          fontSize: "0.78rem",
                        }}
                      >
                        No trips match this filter.
                      </td>
                    </tr>
                  ) : (
                    rows.map((t) => (
                      <tr key={t.id} style={ds.tr}>
                        <td style={ds.td}>
                          <span style={ds.tripId}>#{t.id}</span>
                        </td>
                        <td
                          style={{
                            ...ds.td,
                            color: "#cce0f5",
                            fontWeight: 500,
                          }}
                        >
                          {t.commuter_name}
                        </td>
                        <td style={{ ...ds.td, color: "#8ab4d4" }}>
                          {t.driver_name}
                        </td>
                        <td
                          style={{
                            ...ds.td,
                            fontSize: "0.7rem",
                            color: "#8ab4d4",
                          }}
                        >
                          {t.origin}
                        </td>
                        <td style={{ ...ds.td, fontSize: "0.7rem" }}>
                          {t.destination}
                        </td>
                        <td
                          style={{
                            ...ds.td,
                            color: "#4ade80",
                            fontWeight: 700,
                          }}
                        >
                          {fmtP(t.fare)}
                        </td>
                        <td
                          style={{
                            ...ds.td,
                            fontSize: "0.65rem",
                            color: "#5a8ab0",
                          }}
                        >
                          {fmtDT(t.created_at)}
                        </td>
                        <td style={ds.td}>
                          <StatusBadge status={t.status} />
                        </td>
                      </tr>
                    ))
                  )}
                </tbody>
              </table>
            </div>
            {total > 1 && (
              <div style={ds.pager}>
                <span style={{ fontSize: "0.62rem", color: "#1e3a52" }}>
                  {filtered.length} records · page {cur}/{total}
                </span>
                <div style={{ display: "flex", gap: 3 }}>
                  <button
                    style={ds.pgBtn}
                    disabled={cur <= 1}
                    onClick={() => setPage((p) => p - 1)}
                  >
                    ‹ Prev
                  </button>
                  <button
                    style={ds.pgBtn}
                    disabled={cur >= total}
                    onClick={() => setPage((p) => p + 1)}
                  >
                    Next ›
                  </button>
                </div>
              </div>
            )}
          </>
        )}
      </div>
    </>
  );
}

// ─── Commuter Modal ───────────────────────────────────────────────────────────
function CommutterModal({ user, onClose, onUpdateStatus }) {
  const [confirming, setConfirming] = useState(null);
  const handle = (action) => {
    if (confirming === action) {
      onUpdateStatus(user.id, action);
      setConfirming(null);
    } else setConfirming(action);
  };
  const name = getDisplayName(user);
  return (
    <div
      onClick={(e) => e.target === e.currentTarget && onClose()}
      style={{
        position: "fixed",
        inset: 0,
        background: "rgba(0,0,0,.85)",
        backdropFilter: "blur(5px)",
        zIndex: 100,
        display: "flex",
        alignItems: "center",
        justifyContent: "center",
        padding: 20,
      }}
    >
      <div
        style={{
          background: "linear-gradient(145deg,#0e1f33,#0a1724)",
          border: "1px solid rgba(60,110,160,.22)",
          borderRadius: 16,
          width: "100%",
          maxWidth: 480,
          padding: 26,
          boxShadow: "0 40px 100px rgba(0,0,0,.8)",
        }}
      >
        <div
          style={{
            display: "flex",
            justifyContent: "space-between",
            alignItems: "flex-start",
            marginBottom: 20,
            paddingBottom: 14,
            borderBottom: "1px solid rgba(60,110,160,.12)",
          }}
        >
          <div
            style={{ fontSize: "0.98rem", fontWeight: 700, color: "#d4e8ff" }}
          >
            Commuter Verification
          </div>
          <button
            onClick={onClose}
            style={{
              background: "rgba(255,255,255,.04)",
              border: "1px solid rgba(60,110,160,.18)",
              borderRadius: 8,
              color: "#3a5a7a",
              cursor: "pointer",
              width: 32,
              height: 32,
              display: "flex",
              alignItems: "center",
              justifyContent: "center",
            }}
          >
            <Icon name="x" size={14} />
          </button>
        </div>
        <div
          style={{
            display: "flex",
            alignItems: "center",
            gap: 13,
            marginBottom: 18,
            padding: "13px 14px",
            background: "rgba(255,255,255,.025)",
            border: "1px solid rgba(60,110,160,.12)",
            borderRadius: 11,
          }}
        >
          <Avatar name={name} role="commuter" size={46} />
          <div>
            <div
              style={{
                fontSize: "1.05rem",
                fontWeight: 700,
                color: "#e2f0ff",
                marginBottom: 5,
              }}
            >
              {name}
            </div>
            <StatusBadge status={user.status} />
          </div>
        </div>
        <div
          style={{
            display: "grid",
            gridTemplateColumns: "1fr 1fr",
            gap: 8,
            marginBottom: 16,
          }}
        >
          <InfoItem label="Email" value={user.email} />
          <InfoItem label="Phone" value={getPhone(user)} />
          <InfoItem label="Address" value={getAddress(user)} />
          <InfoItem label="Joined" value={fmtD(user.created_at)} />
        </div>
        <div style={{ display: "flex", gap: 10 }}>
          <button
            onClick={() => handle("verified")}
            style={{
              flex: 1,
              padding: 10,
              background: "linear-gradient(135deg,#2563eb,#1d4ed8)",
              border: "none",
              borderRadius: 9,
              color: "#fff",
              fontSize: "0.78rem",
              fontWeight: 700,
              cursor: "pointer",
              display: "flex",
              alignItems: "center",
              justifyContent: "center",
              gap: 7,
            }}
          >
            <Icon name="check" size={14} />
            {confirming === "verified"
              ? "Confirm Approve?"
              : "Approve Commuter"}
          </button>
          <button
            onClick={() => handle("rejected")}
            style={{
              flex: 1,
              padding: 10,
              background: "rgba(239,68,68,.07)",
              border: "1px solid rgba(239,68,68,.22)",
              borderRadius: 9,
              color: "#f87171",
              fontSize: "0.78rem",
              fontWeight: 700,
              cursor: "pointer",
              display: "flex",
              alignItems: "center",
              justifyContent: "center",
              gap: 7,
            }}
          >
            <Icon name="x" size={14} />
            {confirming === "rejected" ? "Confirm Reject?" : "Reject"}
          </button>
        </div>
        {confirming && (
          <div
            style={{
              fontSize: "0.63rem",
              color: "#facc15",
              textAlign: "center",
              marginTop: 6,
              fontWeight: 600,
            }}
          >
            ⚠ Click again to confirm your action
          </div>
        )}
      </div>
    </div>
  );
}

// ─── Commuters Tab ────────────────────────────────────────────────────────────
function CommutersView({ users, setUsers }) {
  const [filter, setFilter] = useState("all");
  const [page, setPage] = useState(1);
  const [modalId, setModalId] = useState(null);
  const commuters = users.filter((u) => u.role === "commuter");
  const filtered = commuters.filter(
    (c) => filter === "all" || c.status === filter,
  );
  const total = Math.max(1, Math.ceil(filtered.length / PER));
  const cur = Math.min(page, total);
  const rows = filtered.slice((cur - 1) * PER, cur * PER);
  const modalUser = users.find(
    (u) => u.id === modalId && u.role === "commuter",
  );
  const updateStatus = (uid, newStatus) =>
    callVerify(uid, "commuter", newStatus, setUsers, setModalId);
  return (
    <>
      <div
        style={{
          display: "grid",
          gridTemplateColumns: "repeat(3,1fr)",
          gap: 10,
          marginBottom: 14,
        }}
      >
        <StatCard
          icon="users"
          value={commuters.length}
          label="Total Commuters"
          color="blue"
        />
        <StatCard
          icon="clock"
          value={commuters.filter((c) => c.status === "pending").length}
          label="Pending"
          color="yellow"
        />
        <StatCard
          icon="check"
          value={commuters.filter((c) => c.status === "verified").length}
          label="Verified"
          color="green"
        />
      </div>
      <div style={ds.tableCard}>
        <div style={{ ...ds.tcHead, flexWrap: "wrap", gap: 8 }}>
          <div style={ds.tcTitle}>
            <span style={ds.dotPulse} />
            Commuter Registry
          </div>
          <div style={{ display: "flex", gap: 4, flexWrap: "wrap" }}>
            {["all", "pending", "verified", "rejected"].map((st) => (
              <button
                key={st}
                onClick={() => {
                  setFilter(st);
                  setPage(1);
                }}
                style={{ ...ds.pill, ...(filter === st ? ds.pillActive : {}) }}
              >
                {st.charAt(0).toUpperCase() + st.slice(1)}
                <span
                  style={{
                    marginLeft: 4,
                    background: "rgba(255,255,255,.06)",
                    padding: "1px 5px",
                    borderRadius: 10,
                    fontSize: "0.55rem",
                  }}
                >
                  {st === "all"
                    ? commuters.length
                    : commuters.filter((c) => c.status === st).length}
                </span>
              </button>
            ))}
          </div>
        </div>
        {commuters.length === 0 ? (
          <EmptyState
            icon="users"
            title="No commuters yet"
            desc="Registered commuters will appear here."
          />
        ) : (
          <>
            <div style={{ overflowX: "auto" }}>
              <table style={{ width: "100%", borderCollapse: "collapse" }}>
                <thead>
                  <tr>
                    {[
                      "#",
                      "Name",
                      "Email",
                      "Phone",
                      "Address",
                      "Status",
                      "Joined",
                      "Action",
                    ].map((h) => (
                      <th key={h} style={ds.th}>
                        {h}
                      </th>
                    ))}
                  </tr>
                </thead>
                <tbody>
                  {rows.length === 0 ? (
                    <tr>
                      <td
                        colSpan="8"
                        style={{
                          textAlign: "center",
                          padding: "40px",
                          color: "#1e3a52",
                          fontSize: "0.78rem",
                        }}
                      >
                        No commuters match this filter.
                      </td>
                    </tr>
                  ) : (
                    rows.map((c) => {
                      const name = getDisplayName(c);
                      return (
                        <tr key={c.id} style={ds.tr}>
                          <td
                            style={{
                              ...ds.td,
                              fontSize: "0.65rem",
                              color: "#3a5a7a",
                            }}
                          >
                            #{c.id}
                          </td>
                          <td style={ds.td}>
                            <div
                              style={{
                                display: "flex",
                                alignItems: "center",
                                gap: 9,
                              }}
                            >
                              <Avatar name={name} role="commuter" />
                              <span
                                style={{ color: "#cce0f5", fontWeight: 500 }}
                              >
                                {name}
                              </span>
                            </div>
                          </td>
                          <td
                            style={{
                              ...ds.td,
                              fontSize: "0.72rem",
                              color: "#8ab4d4",
                            }}
                          >
                            {c.email || "—"}
                          </td>
                          <td style={{ ...ds.td, fontSize: "0.72rem" }}>
                            {getPhone(c)}
                          </td>
                          <td
                            style={{
                              ...ds.td,
                              maxWidth: 130,
                              overflow: "hidden",
                              textOverflow: "ellipsis",
                              whiteSpace: "nowrap",
                              fontSize: "0.72rem",
                              color: "#8ab4d4",
                            }}
                          >
                            {getAddress(c) || "—"}
                          </td>
                          <td style={ds.td}>
                            <StatusBadge status={c.status} />
                          </td>
                          <td
                            style={{
                              ...ds.td,
                              fontSize: "0.65rem",
                              color: "#5a8ab0",
                            }}
                          >
                            {fmtD(c.created_at)}
                          </td>
                          <td style={ds.td}>
                            <button
                              onClick={() => setModalId(c.id)}
                              style={reviewBtnStyle(c.status)}
                            >
                              {c.status === "pending" ? "⚡ Review" : "View"}
                            </button>
                          </td>
                        </tr>
                      );
                    })
                  )}
                </tbody>
              </table>
            </div>
            {total > 1 && (
              <div style={ds.pager}>
                <span style={{ fontSize: "0.62rem", color: "#1e3a52" }}>
                  {filtered.length} records · page {cur}/{total}
                </span>
                <div style={{ display: "flex", gap: 3 }}>
                  <button
                    style={ds.pgBtn}
                    disabled={cur <= 1}
                    onClick={() => setPage((p) => p - 1)}
                  >
                    ‹ Prev
                  </button>
                  <button
                    style={ds.pgBtn}
                    disabled={cur >= total}
                    onClick={() => setPage((p) => p + 1)}
                  >
                    Next ›
                  </button>
                </div>
              </div>
            )}
          </>
        )}
      </div>
      {modalUser && (
        <CommutterModal
          user={modalUser}
          onClose={() => setModalId(null)}
          onUpdateStatus={updateStatus}
        />
      )}
    </>
  );
}

// ─── Driver Modal ─────────────────────────────────────────────────────────────
function DriverModal({ user, onClose, onUpdateStatus }) {
  const [confirming, setConfirming] = useState(null);
  const [photos, setPhotos] = useState(null);
  const [photosLoading, setPhotosLoading] = useState(true);

  useEffect(() => {
    let cancelled = false;
    setPhotosLoading(true);
    authFetch(`${DJANGO_URL}/api/admin/users/${user.id}/photos`)
      .then((r) => {
        if (!r.ok) throw new Error(`HTTP ${r.status}`);
        return r.json();
      })
      .then((data) => {
        if (!cancelled) {
          setPhotos(data);
          setPhotosLoading(false);
        }
      })
      .catch(() => {
        if (!cancelled) {
          setPhotos({
            photo_license: user.photo_license ?? user.photoLicense ?? null,
            photo_plate: user.photo_plate ?? user.photoPlate ?? null,
            photo_toda: user.photo_toda ?? user.photoToda ?? null,
            profile_photo: user.profile_photo ?? user.profilePhoto ?? null,
          });
          setPhotosLoading(false);
        }
      });
    return () => {
      cancelled = true;
    };
  }, [user.id]);

  const handle = (action) => {
    if (confirming === action) {
      onUpdateStatus(user.id, action);
      setConfirming(null);
    } else setConfirming(action);
  };

  const name = getDisplayName(user);
  const licensePhoto = photos?.photo_license ?? photos?.photoLicense ?? null;
  const platePhoto = photos?.photo_plate ?? photos?.photoPlate ?? null;
  const todaPhoto = photos?.photo_toda ?? photos?.photoToda ?? null;
  const profilePhoto = photos?.profile_photo ?? photos?.profilePhoto ?? null;
  const hasPhotos = licensePhoto || platePhoto || todaPhoto;

  return (
    <div
      onClick={(e) => e.target === e.currentTarget && onClose()}
      style={{
        position: "fixed",
        inset: 0,
        background: "rgba(0,0,0,.85)",
        backdropFilter: "blur(5px)",
        zIndex: 100,
        display: "flex",
        alignItems: "center",
        justifyContent: "center",
        padding: 20,
      }}
    >
      <div
        style={{
          background: "linear-gradient(145deg,#0e1f33,#0a1724)",
          border: "1px solid rgba(60,110,160,.22)",
          borderRadius: 16,
          width: "100%",
          maxWidth: 600,
          maxHeight: "90vh",
          overflowY: "auto",
          padding: 26,
          boxShadow: "0 40px 100px rgba(0,0,0,.8)",
        }}
      >
        {/* Header */}
        <div
          style={{
            display: "flex",
            justifyContent: "space-between",
            alignItems: "flex-start",
            marginBottom: 20,
            paddingBottom: 14,
            borderBottom: "1px solid rgba(60,110,160,.12)",
          }}
        >
          <div
            style={{ fontSize: "0.98rem", fontWeight: 700, color: "#d4e8ff" }}
          >
            Driver Verification
          </div>
          <button
            onClick={onClose}
            style={{
              background: "rgba(255,255,255,.04)",
              border: "1px solid rgba(60,110,160,.18)",
              borderRadius: 8,
              color: "#3a5a7a",
              cursor: "pointer",
              width: 32,
              height: 32,
              display: "flex",
              alignItems: "center",
              justifyContent: "center",
            }}
          >
            <Icon name="x" size={14} />
          </button>
        </div>

        {/* Identity row */}
        <div
          style={{
            display: "flex",
            alignItems: "center",
            gap: 13,
            marginBottom: 18,
            padding: "13px 14px",
            background: "rgba(255,255,255,.025)",
            border: "1px solid rgba(60,110,160,.12)",
            borderRadius: 11,
          }}
        >
          {profilePhoto ? (
            <img
              src={toImgSrc(profilePhoto)}
              alt="Profile"
              onError={(e) => {
                e.currentTarget.style.display = "none";
              }}
              style={{
                width: 46,
                height: 46,
                borderRadius: "50%",
                objectFit: "cover",
                flexShrink: 0,
                border: "2px solid rgba(249,115,22,.4)",
              }}
            />
          ) : (
            <Avatar name={name} role="driver" size={46} />
          )}
          <div>
            <div
              style={{
                fontSize: "1.05rem",
                fontWeight: 700,
                color: "#e2f0ff",
                marginBottom: 5,
              }}
            >
              {name}
            </div>
            <StatusBadge status={user.status} />
          </div>
        </div>

        {/* Info grid */}
        <div
          style={{
            display: "grid",
            gridTemplateColumns: "1fr 1fr",
            gap: 8,
            marginBottom: 18,
          }}
        >
          <InfoItem label="TODA / Org" value={getOrganization(user)} />
          <InfoItem label="Plate No." value={getPlateNo(user)} />
          <InfoItem label="License No." value={getLicenseNo(user)} />
          <InfoItem label="Contact" value={getPhone(user)} />
          <InfoItem label="Email" value={user.email} />
          <InfoItem label="Address" value={getAddress(user)} />
          <InfoItem label="Joined" value={fmtD(user.created_at)} />
        </div>

        {/* Credential Photos */}
        <div
          style={{
            marginBottom: 18,
            padding: "14px 14px 16px",
            background: "rgba(0,0,0,.2)",
            border: "1px solid rgba(60,110,160,.12)",
            borderRadius: 11,
          }}
        >
          <div
            style={{
              display: "flex",
              alignItems: "center",
              gap: 7,
              marginBottom: 14,
              fontSize: "0.6rem",
              fontWeight: 700,
              textTransform: "uppercase",
              letterSpacing: "1.8px",
              color: "#1e5a8a",
            }}
          >
            <svg
              width={11}
              height={11}
              viewBox="0 0 24 24"
              fill="none"
              stroke="currentColor"
              strokeWidth="2"
              strokeLinecap="round"
            >
              <rect x="3" y="3" width="18" height="18" rx="2" />
              <circle cx="8.5" cy="8.5" r="1.5" />
              <polyline points="21 15 16 10 5 21" />
            </svg>
            Credential Documents
          </div>
          {photosLoading ? (
            <div
              style={{
                textAlign: "center",
                padding: "20px 0",
                fontSize: "0.7rem",
                color: "#2a4a62",
              }}
            >
              <svg
                style={{
                  animation: "spin .8s linear infinite",
                  width: 18,
                  height: 18,
                  color: "#3b82f6",
                  display: "inline-block",
                }}
                viewBox="0 0 24 24"
                fill="none"
              >
                <circle
                  cx="12"
                  cy="12"
                  r="10"
                  stroke="currentColor"
                  strokeWidth="3"
                  strokeOpacity=".2"
                />
                <path fill="currentColor" d="M4 12a8 8 0 018-8v8z" />
              </svg>
              <span style={{ marginLeft: 8 }}>Loading documents…</span>
            </div>
          ) : hasPhotos ? (
            <div
              style={{
                display: "grid",
                gridTemplateColumns: "1fr 1fr 1fr",
                gap: 10,
              }}
            >
              <CredentialPhoto label="Driver's License" value={licensePhoto} />
              <CredentialPhoto label="Vehicle / Plate" value={platePhoto} />
              <CredentialPhoto label="TODA Clearance" value={todaPhoto} />
            </div>
          ) : (
            <div
              style={{
                padding: "16px 0",
                textAlign: "center",
                fontSize: "0.7rem",
                color: "#2a4a62",
              }}
            >
              No credential photos found.{" "}
              <span style={{ color: "#3a5a7a" }}>
                Make sure{" "}
                <code style={{ color: "#5a8ab0", fontSize: "0.65rem" }}>
                  /api/admin/users/{"{id}"}/photos
                </code>{" "}
                returns{" "}
                <code style={{ color: "#5a8ab0", fontSize: "0.65rem" }}>
                  photo_license
                </code>
                ,{" "}
                <code style={{ color: "#5a8ab0", fontSize: "0.65rem" }}>
                  photo_plate
                </code>
                ,{" "}
                <code style={{ color: "#5a8ab0", fontSize: "0.65rem" }}>
                  photo_toda
                </code>
                .
              </span>
            </div>
          )}
        </div>

        {/* Action buttons */}
        <div style={{ display: "flex", gap: 10 }}>
          <button
            onClick={() => handle("verified")}
            style={{
              flex: 1,
              padding: 10,
              background: "linear-gradient(135deg,#2563eb,#1d4ed8)",
              border: "none",
              borderRadius: 9,
              color: "#fff",
              fontSize: "0.78rem",
              fontWeight: 700,
              cursor: "pointer",
              display: "flex",
              alignItems: "center",
              justifyContent: "center",
              gap: 7,
            }}
          >
            <Icon name="check" size={14} />
            {confirming === "verified" ? "Confirm Approve?" : "Approve Driver"}
          </button>
          <button
            onClick={() => handle("rejected")}
            style={{
              flex: 1,
              padding: 10,
              background: "rgba(239,68,68,.07)",
              border: "1px solid rgba(239,68,68,.22)",
              borderRadius: 9,
              color: "#f87171",
              fontSize: "0.78rem",
              fontWeight: 700,
              cursor: "pointer",
              display: "flex",
              alignItems: "center",
              justifyContent: "center",
              gap: 7,
            }}
          >
            <Icon name="x" size={14} />
            {confirming === "rejected" ? "Confirm Reject?" : "Reject"}
          </button>
        </div>
        {confirming && (
          <div
            style={{
              fontSize: "0.63rem",
              color: "#facc15",
              textAlign: "center",
              marginTop: 6,
              fontWeight: 600,
            }}
          >
            ⚠ Click again to confirm your action
          </div>
        )}
      </div>
    </div>
  );
}

// ─── Drivers Tab ──────────────────────────────────────────────────────────────
function DriversView({ users, setUsers }) {
  const [filter, setFilter] = useState("all");
  const [page, setPage] = useState(1);
  const [modalId, setModalId] = useState(null);
  const drivers = users.filter((u) => u.role === "driver");
  const filtered = drivers.filter(
    (d) => filter === "all" || d.status === filter,
  );
  const total = Math.max(1, Math.ceil(filtered.length / PER));
  const cur = Math.min(page, total);
  const rows = filtered.slice((cur - 1) * PER, cur * PER);
  const modalUser = users.find((u) => u.id === modalId && u.role === "driver");
  const updateStatus = (uid, newStatus) =>
    callVerify(uid, "driver", newStatus, setUsers, setModalId);
  return (
    <>
      <div
        style={{
          display: "grid",
          gridTemplateColumns: "repeat(4,1fr)",
          gap: 10,
          marginBottom: 14,
        }}
      >
        <StatCard
          icon="tricycle"
          value={drivers.length}
          label="Total Drivers"
          color="blue"
        />
        <StatCard
          icon="grid"
          value={drivers.filter((d) => d.is_available === "1").length}
          label="Online Now"
          color="green"
        />
        <StatCard
          icon="clock"
          value={drivers.filter((d) => d.status === "pending").length}
          label="Pending Review"
          color="yellow"
        />
        <StatCard
          icon="check"
          value={drivers.filter((d) => d.status === "verified").length}
          label="Verified"
          color="green"
        />
      </div>
      <div style={ds.tableCard}>
        <div style={{ ...ds.tcHead, flexWrap: "wrap", gap: 8 }}>
          <div style={ds.tcTitle}>
            <span style={ds.dotPulse} />
            Driver Registry
          </div>
          <div style={{ display: "flex", gap: 4, flexWrap: "wrap" }}>
            {["all", "pending", "verified", "rejected"].map((st) => (
              <button
                key={st}
                onClick={() => {
                  setFilter(st);
                  setPage(1);
                }}
                style={{ ...ds.pill, ...(filter === st ? ds.pillActive : {}) }}
              >
                {st.charAt(0).toUpperCase() + st.slice(1)}
                <span
                  style={{
                    marginLeft: 4,
                    background: "rgba(255,255,255,.06)",
                    padding: "1px 5px",
                    borderRadius: 10,
                    fontSize: "0.55rem",
                  }}
                >
                  {st === "all"
                    ? drivers.length
                    : drivers.filter((d) => d.status === st).length}
                </span>
              </button>
            ))}
          </div>
        </div>
        {drivers.length === 0 ? (
          <EmptyState
            icon="tricycle"
            title="No drivers yet"
            desc="Partner drivers will appear here once they register."
          />
        ) : (
          <>
            <div style={{ overflowX: "auto" }}>
              <table style={{ width: "100%", borderCollapse: "collapse" }}>
                <thead>
                  <tr>
                    {[
                      "Driver",
                      "Plate No.",
                      "License",
                      "TODA / Org",
                      "Contact",
                      "Availability",
                      "Status",
                      "Joined",
                      "Action",
                    ].map((h) => (
                      <th key={h} style={ds.th}>
                        {h}
                      </th>
                    ))}
                  </tr>
                </thead>
                <tbody>
                  {rows.length === 0 ? (
                    <tr>
                      <td
                        colSpan="9"
                        style={{
                          textAlign: "center",
                          padding: "40px",
                          color: "#1e3a52",
                          fontSize: "0.78rem",
                        }}
                      >
                        No drivers match this filter.
                      </td>
                    </tr>
                  ) : (
                    rows.map((d) => {
                      const name = getDisplayName(d);
                      const plateNo = getPlateNo(d);
                      const licenseNo = getLicenseNo(d);
                      const organization = getOrganization(d);
                      return (
                        <tr key={d.id} style={ds.tr}>
                          <td style={ds.td}>
                            <div
                              style={{
                                display: "flex",
                                alignItems: "center",
                                gap: 9,
                              }}
                            >
                              <Avatar name={name} role="driver" />
                              <div>
                                <div
                                  style={{ color: "#cce0f5", fontWeight: 500 }}
                                >
                                  {name}
                                </div>
                                <div
                                  style={{
                                    fontSize: "0.62rem",
                                    color: "#4a6a88",
                                  }}
                                >
                                  {d.email}
                                </div>
                              </div>
                            </div>
                          </td>
                          <td style={ds.td}>
                            {plateNo ? (
                              <span
                                style={{
                                  background: "#0a1f0a",
                                  border: "1px solid rgba(74,222,128,.2)",
                                  color: "#6ee7a0",
                                  padding: "2px 9px",
                                  borderRadius: 5,
                                  fontSize: "0.67rem",
                                  fontWeight: 700,
                                  fontFamily: "monospace",
                                }}
                              >
                                {plateNo}
                              </span>
                            ) : (
                              <span style={{ color: "#2a4a62" }}>—</span>
                            )}
                          </td>
                          <td
                            style={{
                              ...ds.td,
                              fontSize: "0.7rem",
                              color: "#8ab4d4",
                            }}
                          >
                            {licenseNo || (
                              <span style={{ color: "#2a4a62" }}>—</span>
                            )}
                          </td>
                          <td style={{ ...ds.td, fontSize: "0.72rem" }}>
                            {organization || (
                              <span style={{ color: "#2a4a62" }}>—</span>
                            )}
                          </td>
                          <td
                            style={{
                              ...ds.td,
                              fontSize: "0.72rem",
                              color: "#8ab4d4",
                            }}
                          >
                            {getPhone(d)}
                          </td>
                          <td style={ds.td}>
                            <span
                              style={{
                                display: "inline-flex",
                                alignItems: "center",
                                gap: 5,
                                padding: "3px 9px",
                                borderRadius: 20,
                                fontSize: "0.58rem",
                                fontWeight: 700,
                                background:
                                  d.is_available === "1"
                                    ? "rgba(74,222,128,.07)"
                                    : "rgba(255,255,255,.04)",
                                color:
                                  d.is_available === "1"
                                    ? "#4ade80"
                                    : "#3a5a7a",
                                border: `1px solid ${d.is_available === "1" ? "rgba(74,222,128,.18)" : "rgba(60,110,160,.15)"}`,
                              }}
                            >
                              <span
                                style={{
                                  width: 5,
                                  height: 5,
                                  borderRadius: "50%",
                                  background:
                                    d.is_available === "1"
                                      ? "#4ade80"
                                      : "#3a5a7a",
                                }}
                              />
                              {d.is_available === "1" ? "Online" : "Offline"}
                            </span>
                          </td>
                          <td style={ds.td}>
                            <StatusBadge status={d.status} />
                          </td>
                          <td
                            style={{
                              ...ds.td,
                              fontSize: "0.65rem",
                              color: "#5a8ab0",
                            }}
                          >
                            {fmtD(d.created_at)}
                          </td>
                          <td style={ds.td}>
                            <button
                              onClick={() => setModalId(d.id)}
                              style={reviewBtnStyle(d.status)}
                            >
                              {d.status === "pending" ? "⚡ Review" : "View"}
                            </button>
                          </td>
                        </tr>
                      );
                    })
                  )}
                </tbody>
              </table>
            </div>
            {total > 1 && (
              <div style={ds.pager}>
                <span style={{ fontSize: "0.62rem", color: "#1e3a52" }}>
                  {filtered.length} records · page {cur}/{total}
                </span>
                <div style={{ display: "flex", gap: 3 }}>
                  <button
                    style={ds.pgBtn}
                    disabled={cur <= 1}
                    onClick={() => setPage((p) => p - 1)}
                  >
                    ‹ Prev
                  </button>
                  <button
                    style={ds.pgBtn}
                    disabled={cur >= total}
                    onClick={() => setPage((p) => p + 1)}
                  >
                    Next ›
                  </button>
                </div>
              </div>
            )}
          </>
        )}
      </div>
      {modalUser && (
        <DriverModal
          user={modalUser}
          onClose={() => setModalId(null)}
          onUpdateStatus={updateStatus}
        />
      )}
    </>
  );
}

// ─── Dashboard Shell ──────────────────────────────────────────────────────────
export default function Dashboard() {
  const { user, logout } = useAuth();
  const [view, setView] = useState("overview");
  const clock = useClock();
  const [users, setUsers] = useState([]);
  const [trips, setTrips] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  const loadData = async () => {
    setLoading(true);
    setError(null);
    try {
      const res = await authFetch(`${DJANGO_URL}/api/admin/users`);
      if (!res.ok) throw new Error(`Users API returned ${res.status}`);
      const data = await res.json();
      setUsers(
        data.map((u) => ({
          ...u,
          status: u.verified_status ?? u.status ?? "pending",
        })),
      );
    } catch (e) {
      console.error("Failed to load users:", e);
      setError(
        "Could not connect to Django. Make sure it is running on port 8082.",
      );
    }
    try {
      const res = await authFetch(`${DJANGO_URL}/api/admin/trips`);
      if (res.ok) setTrips(await res.json());
    } catch (e) {
      console.error("Failed to load trips:", e);
    }
    setLoading(false);
  };

  useEffect(() => {
    loadData();
  }, []);

  const pendingDrivers = users.filter(
    (u) => u.role === "driver" && u.status === "pending",
  ).length;
  const pendingCommuters = users.filter(
    (u) => u.role === "commuter" && u.status === "pending",
  ).length;

  return (
    <div style={ds.root}>
      <style>{dashCss}</style>

      {/* ── Sidebar ── */}
      <aside style={ds.sidebar}>
        <div style={ds.logo}>
          <img src={logo} alt="Logo" style={{ width: 32, height: "auto" }} />
          <div>
            <div
              style={{
                fontSize: "1.1rem",
                fontWeight: 800,
                letterSpacing: "-.4px",
              }}
            >
              <span style={{ color: "#60a5fa" }}>Pasada</span>
              <span style={{ color: "#fb923c" }}>Now</span>
            </div>
            <div
              style={{
                fontSize: "0.5rem",
                color: "#3a5a7a",
                fontWeight: 500,
                textTransform: "uppercase",
                letterSpacing: "2.5px",
              }}
            >
              Admin Console
            </div>
          </div>
        </div>

        <div style={ds.navSection}>Navigation</div>
        <nav
          style={{
            display: "flex",
            flexDirection: "column",
            gap: 2,
            padding: "4px 8px",
          }}
        >
          {NAV.map((n) => {
            const isActive = view === n.id;
            const badge =
              n.id === "drivers"
                ? pendingDrivers
                : n.id === "commuters"
                  ? pendingCommuters
                  : 0;
            return (
              <button
                key={n.id}
                onClick={() => setView(n.id)}
                className="nav-btn"
                style={{
                  display: "flex",
                  alignItems: "center",
                  gap: 9,
                  padding: "9px 11px",
                  borderRadius: 9,
                  border: isActive
                    ? "1px solid rgba(59,130,246,.2)"
                    : "1px solid transparent",
                  background: isActive ? "rgba(59,130,246,.1)" : "transparent",
                  color: isActive ? "#60a5fa" : "#3a5a7a",
                  fontSize: "0.78rem",
                  fontWeight: isActive ? 600 : 500,
                  cursor: "pointer",
                  textAlign: "left",
                  fontFamily: "inherit",
                  width: "100%",
                  position: "relative",
                  transition: "all .18s",
                }}
              >
                {isActive && <span style={ds.navLine} />}
                <span
                  style={{
                    width: 18,
                    height: 18,
                    display: "flex",
                    alignItems: "center",
                    justifyContent: "center",
                    flexShrink: 0,
                    color: isActive ? "#60a5fa" : undefined,
                  }}
                >
                  <Icon name={n.icon} size={15} />
                </span>
                {n.label}
                {badge > 0 && (
                  <span
                    style={{
                      marginLeft: "auto",
                      background: "linear-gradient(135deg,#f97316,#ea580c)",
                      color: "#fff",
                      fontSize: "0.5rem",
                      fontWeight: 800,
                      padding: "2px 7px",
                      borderRadius: 20,
                      boxShadow: "0 2px 6px rgba(249,115,22,.4)",
                    }}
                  >
                    {badge}
                  </span>
                )}
              </button>
            );
          })}
        </nav>

        <div style={{ padding: "8px 8px 0" }}>
          <button
            onClick={loadData}
            style={{
              display: "flex",
              alignItems: "center",
              justifyContent: "center",
              gap: 6,
              width: "100%",
              padding: "7px 10px",
              borderRadius: 8,
              background: "rgba(59,130,246,.06)",
              border: "1px solid rgba(59,130,246,.15)",
              color: "#3a6a9a",
              fontSize: "0.65rem",
              fontWeight: 600,
              cursor: "pointer",
              fontFamily: "inherit",
            }}
          >
            <Icon name="refresh" size={12} /> Refresh Data
          </button>
        </div>

        <div
          style={{
            margin: "8px 8px 0",
            padding: "10px 12px",
            background: "rgba(74,222,128,.04)",
            border: "1px solid rgba(74,222,128,.1)",
            borderRadius: 9,
          }}
        >
          <div
            style={{
              fontSize: "0.5rem",
              fontWeight: 700,
              textTransform: "uppercase",
              letterSpacing: "1.5px",
              color: "#2a6a4a",
              marginBottom: 5,
            }}
          >
            System Status
          </div>
          <div
            style={{
              display: "flex",
              alignItems: "center",
              gap: 7,
              fontSize: "0.7rem",
              color: "#aec8e0",
            }}
          >
            <span
              style={{
                width: 7,
                height: 7,
                borderRadius: "50%",
                background: error ? "#f87171" : "#4ade80",
                flexShrink: 0,
              }}
            />
            {error
              ? "Django unreachable"
              : loading
                ? "Loading…"
                : "All systems normal"}
          </div>
        </div>

        <div
          style={{
            marginTop: "auto",
            padding: 12,
            borderTop: "1px solid rgba(60,110,160,.1)",
          }}
        >
          <div
            style={{
              display: "flex",
              alignItems: "center",
              gap: 9,
              padding: "10px 11px",
              background: "rgba(255,255,255,.025)",
              border: "1px solid rgba(60,110,160,.12)",
              borderRadius: 9,
              marginBottom: 8,
            }}
          >
            <div
              style={{
                width: 32,
                height: 32,
                borderRadius: "50%",
                background: "linear-gradient(135deg,#3b82f6,#1d4ed8)",
                display: "flex",
                alignItems: "center",
                justifyContent: "center",
                fontSize: "0.72rem",
                fontWeight: 800,
                color: "#fff",
                flexShrink: 0,
              }}
            >
              A
            </div>
            <div>
              <div
                style={{
                  fontSize: "0.78rem",
                  fontWeight: 700,
                  color: "#cce0f5",
                }}
              >
                Admin
              </div>
              <div style={{ fontSize: "0.6rem", color: "#2a4a6a" }}>
                {user?.email}
              </div>
            </div>
          </div>
          <button
            onClick={logout}
            className="logout-btn"
            style={{
              display: "flex",
              alignItems: "center",
              justifyContent: "center",
              gap: 7,
              width: "100%",
              padding: "8px 10px",
              borderRadius: 8,
              background: "transparent",
              border: "1px solid rgba(248,113,113,.25)",
              color: "#f87171",
              fontSize: "0.7rem",
              fontWeight: 600,
              cursor: "pointer",
              fontFamily: "inherit",
              transition: "all .18s",
            }}
          >
            <Icon name="logout" size={13} /> Sign Out
          </button>
        </div>
      </aside>

      {/* ── Main ── */}
      <main
        style={{
          flex: 1,
          display: "flex",
          flexDirection: "column",
          overflow: "hidden",
          height: "100%",
        }}
      >
        <header style={ds.header}>
          <div>
            <div
              style={{
                fontSize: "0.5rem",
                fontWeight: 700,
                textTransform: "uppercase",
                letterSpacing: "2px",
                color: "#2a4a6a",
                marginBottom: 1,
              }}
            >
              PasadaNow
            </div>
            <div
              style={{ fontSize: "0.92rem", fontWeight: 700, color: "#cce0f5" }}
            >
              {TITLES[view]}
            </div>
          </div>
          <div style={{ flex: 1 }} />
          <div
            style={{
              fontSize: "0.66rem",
              color: "#5a8ab0",
              background: "#091524",
              border: "1px solid rgba(60,110,160,.12)",
              padding: "6px 11px",
              borderRadius: 7,
              fontVariantNumeric: "tabular-nums",
              fontWeight: 500,
              whiteSpace: "nowrap",
            }}
          >
            {clock}
          </div>
        </header>

        {error && (
          <div
            style={{
              background: "rgba(248,113,113,.08)",
              border: "1px solid rgba(248,113,113,.2)",
              borderRadius: 8,
              margin: "12px 20px 0",
              padding: "10px 14px",
              fontSize: "0.75rem",
              color: "#f87171",
              display: "flex",
              alignItems: "center",
              gap: 8,
            }}
          >
            <Icon name="x" size={14} /> {error}
          </div>
        )}

        <div style={{ flex: 1, overflowY: "auto", padding: "16px 20px" }}>
          {loading ? (
            <div
              style={{
                display: "flex",
                alignItems: "center",
                justifyContent: "center",
                height: "60%",
                flexDirection: "column",
                gap: 12,
              }}
            >
              <svg
                style={{
                  animation: "spin .8s linear infinite",
                  width: 28,
                  height: 28,
                  color: "#3b82f6",
                }}
                viewBox="0 0 24 24"
                fill="none"
              >
                <circle
                  cx="12"
                  cy="12"
                  r="10"
                  stroke="currentColor"
                  strokeWidth="3"
                  strokeOpacity=".2"
                />
                <path fill="currentColor" d="M4 12a8 8 0 018-8v8z" />
              </svg>
              <div style={{ fontSize: "0.78rem", color: "#3a5a7a" }}>
                Loading data from Django…
              </div>
            </div>
          ) : (
            <>
              {view === "overview" && (
                <OverviewView users={users} trips={trips} />
              )}
              {view === "trips" && <TripsView trips={trips} />}
              {view === "commuters" && (
                <CommutersView users={users} setUsers={setUsers} />
              )}
              {view === "drivers" && (
                <DriversView users={users} setUsers={setUsers} />
              )}
            </>
          )}
        </div>
      </main>
    </div>
  );
}

// ─── Styles ───────────────────────────────────────────────────────────────────
const ds = {
  root: {
    display: "flex",
    width: "100vw",
    height: "100vh",
    background: "#07111f",
    color: "#aec8e0",
    fontFamily: "'Outfit', 'Inter', sans-serif",
    fontSize: 13,
    overflow: "hidden",
    position: "fixed",
    top: 0,
    left: 0,
  },
  sidebar: {
    width: 220,
    background: "linear-gradient(180deg,#0b1829 0%,#091423 100%)",
    borderRight: "1px solid rgba(60,110,160,.15)",
    display: "flex",
    flexDirection: "column",
    flexShrink: 0,
    height: "100%",
  },
  logo: {
    display: "flex",
    alignItems: "center",
    gap: 11,
    padding: "20px 16px 18px",
    borderBottom: "1px solid rgba(60,110,160,.12)",
  },
  navSection: {
    padding: "16px 16px 5px",
    fontSize: "0.5rem",
    fontWeight: 700,
    textTransform: "uppercase",
    letterSpacing: "2.5px",
    color: "#253d56",
  },
  navLine: {
    position: "absolute",
    left: -8,
    top: "50%",
    transform: "translateY(-50%)",
    width: 3,
    height: "60%",
    background: "linear-gradient(180deg,#3b82f6,#60a5fa)",
    borderRadius: "0 3px 3px 0",
  },
  header: {
    background: "#0b1829",
    borderBottom: "1px solid rgba(60,110,160,.15)",
    padding: "10px 18px",
    display: "flex",
    alignItems: "center",
    gap: 12,
    flexShrink: 0,
  },
  statCard: {
    background: "linear-gradient(145deg,#0d1e30,#0a1724)",
    border: "1px solid rgba(60,110,160,.15)",
    borderRadius: 12,
    padding: "15px 15px 14px",
    position: "relative",
    overflow: "hidden",
  },
  tableCard: {
    background: "linear-gradient(145deg,#0d1e30,#0a1724)",
    border: "1px solid rgba(60,110,160,.12)",
    borderRadius: 12,
    overflow: "hidden",
    marginBottom: 12,
  },
  tcHead: {
    display: "flex",
    alignItems: "center",
    justifyContent: "space-between",
    padding: "12px 16px",
    borderBottom: "1px solid rgba(60,110,160,.1)",
  },
  tcTitle: {
    display: "flex",
    alignItems: "center",
    gap: 8,
    fontSize: "0.8rem",
    fontWeight: 600,
    color: "#cce0f5",
  },
  dotPulse: {
    width: 7,
    height: 7,
    borderRadius: "50%",
    background: "#3b82f6",
    flexShrink: 0,
    display: "inline-block",
  },
  th: {
    padding: "8px 14px",
    textAlign: "left",
    fontSize: "0.54rem",
    fontWeight: 700,
    textTransform: "uppercase",
    letterSpacing: "1.8px",
    color: "#1e3a52",
    background: "#07111f",
    whiteSpace: "nowrap",
    borderBottom: "1px solid rgba(60,110,160,.08)",
  },
  td: {
    padding: "10px 14px",
    fontSize: "0.74rem",
    color: "#5a8ab0",
    verticalAlign: "middle",
    borderBottom: "1px solid rgba(60,110,160,.05)",
  },
  tr: {},
  tripId: {
    background: "rgba(59,130,246,.08)",
    color: "#60a5fa",
    padding: "2px 8px",
    borderRadius: 5,
    fontSize: "0.68rem",
    fontWeight: 700,
    border: "1px solid rgba(59,130,246,.15)",
  },
  pager: {
    display: "flex",
    alignItems: "center",
    justifyContent: "space-between",
    padding: "9px 16px",
    borderTop: "1px solid rgba(60,110,160,.08)",
  },
  pgBtn: {
    padding: "4px 10px",
    fontSize: "0.62rem",
    border: "1px solid rgba(60,110,160,.14)",
    background: "#070f1c",
    color: "#2a4a6a",
    borderRadius: 6,
    cursor: "pointer",
    fontFamily: "inherit",
    transition: "all .15s",
  },
  pill: {
    padding: "4px 11px",
    fontSize: "0.62rem",
    fontWeight: 600,
    border: "1px solid rgba(60,110,160,.14)",
    background: "#070f1c",
    color: "#2a4a6a",
    borderRadius: 6,
    cursor: "pointer",
    fontFamily: "inherit",
    transition: "all .15s",
    display: "flex",
    alignItems: "center",
  },
  pillActive: {
    background: "rgba(59,130,246,.12)",
    borderColor: "rgba(59,130,246,.35)",
    color: "#60a5fa",
  },
};

const dashCss = `
  @import url('https://fonts.googleapis.com/css2?family=Outfit:wght@400;500;600;700;800&display=swap');
  * { box-sizing: border-box; margin: 0; padding: 0; }
  ::-webkit-scrollbar { width: 4px; height: 4px; }
  ::-webkit-scrollbar-track { background: transparent; }
  ::-webkit-scrollbar-thumb { background: rgba(59,130,246,.15); border-radius: 4px; }
  .nav-btn:hover { background: rgba(255,255,255,.04) !important; color: #8ab4d4 !important; }
  .logout-btn:hover { background: rgba(248,113,113,.1) !important; border-color: rgba(248,113,113,.4) !important; }
  .photo-hover-overlay:hover { opacity: 1 !important; }
  @keyframes spin { to { transform: rotate(360deg); } }
`;
