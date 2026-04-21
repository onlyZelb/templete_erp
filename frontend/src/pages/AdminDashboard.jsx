import { useState, useEffect, useRef, createContext, useContext } from "react";
import logo from "../assets/logo.png";

// ─── Auth Context ─────────────────────────────────────────────────────────────
const AuthContext = createContext(null);

const ADMIN_EMAIL = "admin@pasadanow.com";
const ADMIN_PASSWORD = "admin123";

function AuthProvider({ children }) {
  const [user, setUser] = useState(null);
  const [checked, setChecked] = useState(false);

  useEffect(() => {
    const saved = sessionStorage.getItem("pn_admin");
    if (saved) {
      try {
        setUser(JSON.parse(saved));
      } catch {}
    }
    setChecked(true);
  }, []);

  const login = (email, password) => {
    if (email === ADMIN_EMAIL && password === ADMIN_PASSWORD) {
      const u = { email, role: "admin" };
      setUser(u);
      sessionStorage.setItem("pn_admin", JSON.stringify(u));
      return true;
    }
    return false;
  };

  const logout = () => {
    setUser(null);
    sessionStorage.removeItem("pn_admin");
  };

  if (!checked) return null;
  return (
    <AuthContext.Provider
      value={{ user, isAuthenticated: !!user, login, logout }}
    >
      {children}
    </AuthContext.Provider>
  );
}

function useAuth() {
  return useContext(AuthContext);
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
    search: (
      <svg
        width={size}
        height={size}
        viewBox="0 0 24 24"
        fill="none"
        stroke="currentColor"
        strokeWidth="1.8"
        strokeLinecap="round"
      >
        <circle cx="11" cy="11" r="7" />
        <line x1="21" y1="21" x2="16.65" y2="16.65" />
      </svg>
    ),
    bell: (
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
        <path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9" />
        <path d="M13.73 21a2 2 0 0 1-3.46 0" />
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
    eye: (
      <svg
        width={size}
        height={size}
        viewBox="0 0 24 24"
        fill="none"
        stroke="currentColor"
        strokeWidth="2"
      >
        <path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z" />
        <circle cx="12" cy="12" r="3" />
      </svg>
    ),
    eyeOff: (
      <svg
        width={size}
        height={size}
        viewBox="0 0 24 24"
        fill="none"
        stroke="currentColor"
        strokeWidth="2"
      >
        <path d="M17.94 17.94A10.07 10.07 0 0112 20c-7 0-11-8-11-8a18.45 18.45 0 015.06-5.94" />
        <path d="M9.9 4.24A9.12 9.12 0 0112 4c7 0 11 8 11 8a18.5 18.5 0 01-2.16 3.19" />
        <line x1="1" y1="1" x2="23" y2="23" />
      </svg>
    ),
  };
  return icons[name] || null;
};

// ─── Login Page ───────────────────────────────────────────────────────────────
function LoginPage() {
  const { login } = useAuth();
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [showPw, setShowPw] = useState(false);
  const [emailErr, setEmailErr] = useState("");
  const [pwErr, setPwErr] = useState("");
  const [loading, setLoading] = useState(false);
  const [authErr, setAuthErr] = useState("");
  const validateEmail = (v) => {
    if (!v) return "Email is required.";
    if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(v))
      return "Enter a valid email address.";
    return "";
  };
  const validatePw = (v) => {
    if (!v) return "Password is required.";
    if (v.length < 6) return "Password must be at least 6 characters.";
    return "";
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    const eErr = validateEmail(email);
    const pErr = validatePw(password);
    setEmailErr(eErr);
    setPwErr(pErr);
    if (eErr || pErr) return;
    setLoading(true);
    setAuthErr("");
    await new Promise((r) => setTimeout(r, 700));
    const ok = login(email, password);
    if (!ok) setAuthErr("Invalid email or password. Please try again.");
    setLoading(false);
  };

  return (
    <div style={s.loginRoot}>
      <style>{loginCss}</style>
      {/* Left panel */}
      <div style={s.loginLeft}>
        <div style={s.loginLeftInner}>
          <div style={s.loginLogo}>🛺</div>
          <div style={s.loginBrand}>
            <span style={{ color: "#60a5fa" }}>Pasada</span>
            <span style={{ color: "#fb923c" }}>Now</span>
          </div>
          <div style={s.loginTagline}>Tricycle Ride-Hailing Platform</div>
        </div>
      </div>

      {/* Right panel */}
      <div style={s.loginRight}>
        <form
          onSubmit={handleSubmit}
          noValidate
          style={s.loginCard}
          className="login-card"
        >
          <div style={s.loginCardLogo}>
            <span style={{ fontSize: 28 }}>🛺</span>
            <div style={s.loginCardBrand}>
              <span style={{ color: "#60a5fa" }}>Pasada</span>
              <span style={{ color: "#fb923c" }}>Now</span>
            </div>
          </div>
          <div style={s.loginSubtitle}>Admin Portal</div>
          <h1 style={s.loginHeading}>Welcome back</h1>
          <p style={s.loginDesc}>Sign in to access the admin dashboard</p>

          {authErr && (
            <div style={s.authErrBox}>
              <Icon name="x" size={14} />
              {authErr}
            </div>
          )}

          {/* Email */}
          <div style={s.fieldWrap}>
            <label style={s.label}>Email address</label>
            <div style={{ position: "relative" }}>
              <input
                type="email"
                value={email}
                onChange={(e) => {
                  setEmail(e.target.value);
                  setEmailErr("");
                  setAuthErr("");
                }}
                placeholder="admin@pasadanow.com"
                style={{ ...s.input, ...(emailErr ? s.inputErr : {}) }}
                className="pn-input"
              />
            </div>
            {emailErr && <div style={s.fieldErr}>{emailErr}</div>}
          </div>

          {/* Password */}
          <div style={s.fieldWrap}>
            <label style={s.label}>Password</label>
            <div style={{ position: "relative" }}>
              <input
                type={showPw ? "text" : "password"}
                value={password}
                onChange={(e) => {
                  setPassword(e.target.value);
                  setPwErr("");
                  setAuthErr("");
                }}
                placeholder="Enter your password"
                style={{
                  ...s.input,
                  paddingRight: 44,
                  ...(pwErr ? s.inputErr : {}),
                }}
                className="pn-input"
              />
              <button
                type="button"
                onClick={() => setShowPw((v) => !v)}
                style={s.eyeBtn}
              >
                <Icon name={showPw ? "eye" : "eyeOff"} size={17} />
              </button>
            </div>
            {pwErr && <div style={s.fieldErr}>{pwErr}</div>}
          </div>

          <div
            style={{
              fontSize: "0.72rem",
              color: "#4a7090",
              marginBottom: 20,
              textAlign: "right",
            }}
          >
            Demo credentials: admin@pasadanow.com / admin123
          </div>

          <button
            type="submit"
            disabled={loading}
            style={s.submitBtn}
            className="pn-submit"
          >
            {loading ? (
              <span
                style={{
                  display: "flex",
                  alignItems: "center",
                  justifyContent: "center",
                  gap: 8,
                }}
              >
                <svg
                  style={{
                    animation: "spin .8s linear infinite",
                    width: 16,
                    height: 16,
                  }}
                  viewBox="0 0 24 24"
                  fill="none"
                >
                  <circle
                    cx="12"
                    cy="12"
                    r="10"
                    stroke="currentColor"
                    strokeWidth="4"
                    strokeOpacity=".25"
                  />
                  <path fill="currentColor" d="M4 12a8 8 0 018-8v8z" />
                </svg>
                Signing in…
              </span>
            ) : (
              "Sign In"
            )}
          </button>

          <p style={s.loginNote}>
            Admin access only · Commuters &amp; drivers use the mobile app
          </p>
        </form>
      </div>
    </div>
  );
}

// ─── Dashboard ────────────────────────────────────────────────────────────────
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
  return new Date(s).toLocaleDateString("en-PH", {
    month: "short",
    day: "numeric",
    year: "numeric",
  });
}
function fmtDT(s) {
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
        {/* Recent Trips */}
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

        {/* Fleet Summary */}
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
                {users.filter((u) => u.status === "pending").length} driver
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
            display: "flex",
            justifyContent: "space-between",
            alignItems: "center",
          }}
        >
          <div>
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

// ─── Commuters Tab ────────────────────────────────────────────────────────────
function CommutersView({ users }) {
  const [filter, setFilter] = useState("all");
  const [page, setPage] = useState(1);

  const commuters = users.filter((u) => u.role === "commuter");
  const filtered = commuters.filter(
    (c) => filter === "all" || c.status === filter,
  );
  const total = Math.max(1, Math.ceil(filtered.length / PER));
  const cur = Math.min(page, total);
  const rows = filtered.slice((cur - 1) * PER, cur * PER);

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
                        colSpan="7"
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
                    rows.map((c) => (
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
                            <Avatar name={c.username} role="commuter" />
                            <span style={{ color: "#cce0f5", fontWeight: 500 }}>
                              {c.username}
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
                          {c.contact_no || "—"}
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
                          {c.address || "—"}
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

// ─── Drivers Tab ──────────────────────────────────────────────────────────────
function DriverModal({ user, onClose, onUpdateStatus }) {
  const [confirming, setConfirming] = useState(null);
  const handle = (action) => {
    if (confirming === action) {
      onUpdateStatus(user.id, action);
      setConfirming(null);
    } else setConfirming(action);
  };
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
          maxWidth: 560,
          maxHeight: "88vh",
          overflowY: "auto",
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
          <Avatar name={user.username} role="driver" size={46} />
          <div>
            <div
              style={{
                fontSize: "1.05rem",
                fontWeight: 700,
                color: "#e2f0ff",
                marginBottom: 5,
              }}
            >
              {user.username}
            </div>
            <div style={{ display: "flex", gap: 6 }}>
              <StatusBadge status={user.status} />
            </div>
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
          {[
            ["TODA / Org", user.organization],
            ["Plate No.", user.plate_number],
            ["License No.", user.license_no],
            ["Contact", user.contact_no],
            ["Email", user.email],
            ["Joined", fmtD(user.created_at)],
          ].map(([l, v]) => (
            <div
              key={l}
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
                {l}
              </div>
              <div
                style={{
                  fontSize: "0.77rem",
                  fontWeight: 600,
                  color: "#cce0f5",
                }}
              >
                {v || "—"}
              </div>
            </div>
          ))}
        </div>

        <div style={{ display: "flex", gap: 10, marginTop: 14 }}>
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
  const modalUser = users.find((u) => u.id === modalId);

  const updateStatus = (uid, status) => {
    setUsers((prev) => prev.map((u) => (u.id === uid ? { ...u, status } : u)));
    setModalId(null);
  };

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
                        colSpan="8"
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
                    rows.map((d) => (
                      <tr key={d.id} style={ds.tr}>
                        <td style={ds.td}>
                          <div
                            style={{
                              display: "flex",
                              alignItems: "center",
                              gap: 9,
                            }}
                          >
                            <Avatar name={d.username} role="driver" />
                            <div>
                              <div
                                style={{ color: "#cce0f5", fontWeight: 500 }}
                              >
                                {d.username}
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
                          {d.plate_number ? (
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
                              {d.plate_number}
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
                          {d.license_no || (
                            <span style={{ color: "#2a4a62" }}>—</span>
                          )}
                        </td>
                        <td style={{ ...ds.td, fontSize: "0.72rem" }}>
                          {d.organization || (
                            <span style={{ color: "#2a4a62" }}>—</span>
                          )}
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
                                d.is_available === "1" ? "#4ade80" : "#3a5a7a",
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
                            style={{
                              padding: "4px 13px",
                              background:
                                d.status === "pending"
                                  ? "rgba(251,146,60,.06)"
                                  : "rgba(255,255,255,.04)",
                              border: `1px solid ${d.status === "pending" ? "rgba(251,146,60,.3)" : "rgba(60,110,160,.18)"}`,
                              borderRadius: 7,
                              color:
                                d.status === "pending" ? "#fb923c" : "#8ab4d4",
                              fontSize: "0.63rem",
                              fontWeight: 700,
                              cursor: "pointer",
                            }}
                          >
                            {d.status === "pending" ? "⚡ Review" : "View"}
                          </button>
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
function Dashboard() {
  const { user, logout } = useAuth();
  const [view, setView] = useState("overview");
  const clock = useClock();

  // Start with empty data — replace with your API calls
  const [users, setUsers] = useState([]);
  const [trips, setTrips] = useState([]);

  const pendingDrivers = users.filter(
    (u) => u.role === "driver" && u.status === "pending",
  );

  return (
    <div style={ds.root}>
      <style>{dashCss}</style>

      {/* Sidebar */}
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
          {NAV.map((n) => (
            <button
              key={n.id}
              onClick={() => setView(n.id)}
              style={{
                ...ds.navBtn,
                ...(view === n.id ? ds.navBtnActive : {}),
              }}
              className="nav-btn"
            >
              {view === n.id && <span style={ds.navLine} />}
              <span
                style={{
                  width: 18,
                  height: 18,
                  display: "flex",
                  alignItems: "center",
                  justifyContent: "center",
                  flexShrink: 0,
                  color: view === n.id ? "#60a5fa" : undefined,
                }}
              >
                <Icon name={n.icon} size={15} />
              </span>
              {n.label}
              {n.id === "drivers" && pendingDrivers.length > 0 && (
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
                  {pendingDrivers.length}
                </span>
              )}
            </button>
          ))}
        </nav>

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
                background: "#4ade80",
                flexShrink: 0,
              }}
            />
            All systems normal
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
            className="logout-btn"
            onMouseEnter={(e) => {
              e.currentTarget.style.background = "rgba(248,113,113,.1)";
              e.currentTarget.style.borderColor = "rgba(248,113,113,.4)";
            }}
            onMouseLeave={(e) => {
              e.currentTarget.style.background = "transparent";
              e.currentTarget.style.borderColor = "rgba(248,113,113,.25)";
            }}
          >
            <Icon name="logout" size={13} /> Sign Out
          </button>
        </div>
      </aside>

      {/* Main */}
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

        <div style={{ flex: 1, overflowY: "auto", padding: "16px 20px" }}>
          {view === "overview" && <OverviewView users={users} trips={trips} />}
          {view === "trips" && <TripsView trips={trips} />}
          {view === "commuters" && <CommutersView users={users} />}
          {view === "drivers" && (
            <DriversView users={users} setUsers={setUsers} />
          )}
        </div>
      </main>
    </div>
  );
}

// ─── Root App ─────────────────────────────────────────────────────────────────
function AppInner() {
  const { isAuthenticated } = useAuth();
  return isAuthenticated ? <Dashboard /> : <LoginPage />;
}

export default function App() {
  return (
    <AuthProvider>
      <AppInner />
    </AuthProvider>
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
  navBtn: {
    display: "flex",
    alignItems: "center",
    gap: 9,
    padding: "9px 11px",
    borderRadius: 9,
    border: "1px solid transparent",
    background: "transparent",
    color: "#3a5a7a",
    fontSize: "0.78rem",
    fontWeight: 500,
    cursor: "pointer",
    textAlign: "left",
    fontFamily: "inherit",
    width: "100%",
    position: "relative",
    transition: "all .18s",
  },
  navBtnActive: {
    background: "rgba(59,130,246,.1)",
    color: "#60a5fa",
    fontWeight: 600,
    borderColor: "rgba(59,130,246,.2)",
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

const s = {
  loginRoot: {
    display: "flex",
    height: "100vh",
    overflow: "hidden",
    background: "#0b1929",
    color: "#e8f0f8",
    fontFamily: "'Inter', sans-serif",
    position: "fixed",
    inset: 0,
  },
  loginLeft: {
    flex: "0 0 48%",
    background: "linear-gradient(135deg,#0b2a4a,#0f3d66,#1a5fa8)",
    display: "flex",
    alignItems: "center",
    justifyContent: "center",
    position: "relative",
    overflow: "hidden",
  },
  loginLeftInner: {
    display: "flex",
    flexDirection: "column",
    alignItems: "center",
    gap: 10,
    userSelect: "none",
  },
  loginLogo: { fontSize: 80, lineHeight: 1 },
  loginBrand: {
    fontSize: "2.5rem",
    fontWeight: 800,
    fontFamily: "'Montserrat', sans-serif",
    letterSpacing: "-.5px",
  },
  loginTagline: {
    fontSize: "0.78rem",
    color: "rgba(255,255,255,.45)",
    letterSpacing: "3px",
    textTransform: "uppercase",
    fontWeight: 500,
  },
  loginRight: {
    flex: 1,
    display: "flex",
    alignItems: "center",
    justifyContent: "center",
    background: "#0f2236",
    padding: "40px 32px",
    overflowY: "auto",
  },
  loginCard: {
    width: "100%",
    maxWidth: 440,
    background: "#111f30",
    border: "1px solid rgba(30,74,114,.5)",
    borderRadius: 20,
    padding: "44px 44px 36px",
    boxShadow: "0 24px 64px rgba(0,0,0,.5)",
    display: "flex",
    flexDirection: "column",
    alignItems: "center",
    textAlign: "center",
  },
  loginCardLogo: {
    display: "flex",
    alignItems: "center",
    gap: 10,
    marginBottom: 4,
  },
  loginCardBrand: {
    fontSize: "1.8rem",
    fontWeight: 800,
    fontFamily: "'Montserrat', sans-serif",
    letterSpacing: "-.4px",
  },
  loginSubtitle: {
    fontSize: "0.65rem",
    fontWeight: 600,
    letterSpacing: "2.5px",
    textTransform: "uppercase",
    color: "#4a7090",
    marginBottom: 24,
  },
  loginHeading: {
    fontFamily: "'Montserrat', sans-serif",
    fontSize: "1.7rem",
    fontWeight: 800,
    color: "#e8f0f8",
    marginBottom: 6,
  },
  loginDesc: { fontSize: "0.88rem", color: "#4a7090", marginBottom: 24 },
  fieldWrap: { width: "100%", textAlign: "left", marginBottom: 14 },
  label: {
    display: "block",
    fontSize: "0.8rem",
    fontWeight: 700,
    color: "#aec8e0",
    marginBottom: 7,
  },
  input: {
    width: "100%",
    background: "#0d2035",
    border: "1px solid rgba(30,74,114,.6)",
    borderRadius: 10,
    padding: "12px 16px",
    color: "#e8f0f8",
    fontSize: "0.92rem",
    outline: "none",
    fontFamily: "inherit",
    boxSizing: "border-box",
    transition: "border-color .2s",
  },
  inputErr: { borderColor: "rgba(248,113,113,.6)" },
  eyeBtn: {
    position: "absolute",
    right: 14,
    top: "50%",
    transform: "translateY(-50%)",
    background: "none",
    border: "none",
    color: "#4a7090",
    cursor: "pointer",
    display: "flex",
    alignItems: "center",
    padding: 0,
  },
  fieldErr: {
    marginTop: 6,
    fontSize: "0.73rem",
    color: "#f87171",
    fontWeight: 600,
  },
  authErrBox: {
    display: "flex",
    alignItems: "center",
    gap: 8,
    background: "rgba(248,113,113,.08)",
    border: "1px solid rgba(248,113,113,.25)",
    borderRadius: 9,
    padding: "10px 14px",
    fontSize: "0.78rem",
    color: "#f87171",
    marginBottom: 18,
    width: "100%",
    textAlign: "left",
  },
  submitBtn: {
    width: "100%",
    padding: "14px",
    background: "linear-gradient(135deg,#2563eb,#1a5f9a)",
    border: "none",
    borderRadius: 10,
    color: "#fff",
    fontFamily: "'Montserrat', 'Inter', sans-serif",
    fontWeight: 800,
    fontSize: "1rem",
    letterSpacing: ".3px",
    cursor: "pointer",
    boxShadow: "0 4px 20px rgba(37,99,235,.4)",
    transition: "all .2s",
    marginBottom: 16,
  },
  loginNote: { fontSize: "0.74rem", color: "#2a4a6a", fontStyle: "italic" },
};

const loginCss = `
  @import url('https://fonts.googleapis.com/css2?family=Montserrat:wght@700;800&family=Inter:wght@400;500&family=Outfit:wght@400;500;600;700;800&display=swap');
  @keyframes spin { to { transform: rotate(360deg); } }
  .login-card:hover { border-color: rgba(40,120,180,.5) !important; }
  .pn-input:focus { border-color: rgba(59,130,246,.6) !important; box-shadow: 0 0 0 3px rgba(59,130,246,.15); }
  .pn-submit:hover:not(:disabled) { filter: brightness(1.1); transform: translateY(-1px); box-shadow: 0 6px 24px rgba(37,99,235,.5) !important; }
  .pn-submit:disabled { opacity: .7; cursor: not-allowed; }
`;

const dashCss = `
  @import url('https://fonts.googleapis.com/css2?family=Outfit:wght@400;500;600;700;800&display=swap');
  * { box-sizing: border-box; margin: 0; padding: 0; }
  ::-webkit-scrollbar { width: 4px; height: 4px; }
  ::-webkit-scrollbar-track { background: transparent; }
  ::-webkit-scrollbar-thumb { background: rgba(59,130,246,.15); border-radius: 4px; }
  .nav-btn:hover { background: rgba(255,255,255,.04) !important; color: #8ab4d4 !important; }
  .logout-btn:hover { background: rgba(248,113,113,.1) !important; border-color: rgba(248,113,113,.4) !important; }
`;
