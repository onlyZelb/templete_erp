import { useState, useEffect, useRef, useCallback } from "react";

// ─── Mock Data ────────────────────────────────────────────────────────────────
const MOCK_USERS = [
  {
    id: 1,
    username: "Juan dela Cruz",
    email: "juan@email.com",
    role: "driver",
    contact_no: "09171234567",
    plate_number: "ABC 123",
    license_no: "N03-26-123456",
    organization: "Baguio TODA",
    is_available: "1",
    address: "",
    created_at: "2026-04-15T08:22:00Z",
    status: "pending",
  },
  {
    id: 2,
    username: "Maria Santos",
    email: "maria@email.com",
    role: "commuter",
    contact_no: "09281234567",
    plate_number: "",
    license_no: "",
    organization: "",
    is_available: "0",
    address: "Burnham, Baguio",
    created_at: "2026-04-15T09:45:00Z",
    status: "pending",
  },
  {
    id: 3,
    username: "Pedro Reyes",
    email: "pedro@email.com",
    role: "driver",
    contact_no: "09391234567",
    plate_number: "XYZ 789",
    license_no: "N03-25-654321",
    organization: "Magsaysay TODA",
    is_available: "1",
    address: "",
    created_at: "2026-04-14T14:10:00Z",
    status: "verified",
  },
  {
    id: 4,
    username: "Ana Lim",
    email: "ana@email.com",
    role: "commuter",
    contact_no: "09451234567",
    plate_number: "",
    license_no: "",
    organization: "",
    is_available: "0",
    address: "Session Rd",
    created_at: "2026-04-13T11:00:00Z",
    status: "rejected",
  },
  {
    id: 5,
    username: "Carlo Bautista",
    email: "carlo@email.com",
    role: "driver",
    contact_no: "09561234567",
    plate_number: "DEF 456",
    license_no: "N03-26-999888",
    organization: "Loakan TODA",
    is_available: "0",
    address: "",
    created_at: "2026-04-16T07:05:00Z",
    status: "pending",
  },
  {
    id: 6,
    username: "Rosa Mendoza",
    email: "rosa@email.com",
    role: "commuter",
    contact_no: "09671234567",
    plate_number: "",
    license_no: "",
    organization: "",
    is_available: "0",
    address: "Gibraltar Rd",
    created_at: "2026-04-16T08:30:00Z",
    status: "verified",
  },
  {
    id: 7,
    username: "Ben Torres",
    email: "ben@email.com",
    role: "driver",
    contact_no: "09781234567",
    plate_number: "GHI 101",
    license_no: "N03-26-111222",
    organization: "Baguio TODA",
    is_available: "1",
    address: "",
    created_at: "2026-04-12T10:00:00Z",
    status: "verified",
  },
];

const MOCK_TRIPS = [
  {
    id: 1001,
    commuter_name: "Maria Santos",
    driver_name: "Juan dela Cruz",
    origin: "Burnham Park",
    destination: "SM City Baguio",
    fare: 45,
    status: "completed",
    created_at: "2026-04-16T09:10:00Z",
  },
  {
    id: 1002,
    commuter_name: "Ana Lim",
    driver_name: "Pedro Reyes",
    origin: "Session Road",
    destination: "Mines View",
    fare: 60,
    status: "pending",
    created_at: "2026-04-16T09:30:00Z",
  },
  {
    id: 1003,
    commuter_name: "Rosa Mendoza",
    driver_name: "Ben Torres",
    origin: "Loakan",
    destination: "Baguio City Hall",
    fare: 55,
    status: "completed",
    created_at: "2026-04-16T10:00:00Z",
  },
  {
    id: 1004,
    commuter_name: "Maria Santos",
    driver_name: "Carlo Bautista",
    origin: "SM City Baguio",
    destination: "Teachers Camp",
    fare: 35,
    status: "cancelled",
    created_at: "2026-04-16T10:45:00Z",
  },
  {
    id: 1005,
    commuter_name: "Ana Lim",
    driver_name: "Juan dela Cruz",
    origin: "Mines View",
    destination: "Burnham Park",
    fare: 70,
    status: "active",
    created_at: "2026-04-16T11:00:00Z",
  },
  {
    id: 1006,
    commuter_name: "Rosa Mendoza",
    driver_name: "Pedro Reyes",
    origin: "Baguio City Hall",
    destination: "Session Road",
    fare: 40,
    status: "completed",
    created_at: "2026-04-15T14:00:00Z",
  },
  {
    id: 1007,
    commuter_name: "Maria Santos",
    driver_name: "Ben Torres",
    origin: "Teachers Camp",
    destination: "Loakan",
    fare: 80,
    status: "completed",
    created_at: "2026-04-15T16:30:00Z",
  },
];

// ─── Helpers ──────────────────────────────────────────────────────────────────
const fmt = (n) => Number(n || 0).toLocaleString();
const fmtP = (n) =>
  "₱" + Number(n || 0).toLocaleString("en-PH", { minimumFractionDigits: 2 });
const fmtD = (s) =>
  new Date(s).toLocaleDateString("en-PH", {
    month: "short",
    day: "numeric",
    year: "numeric",
  });
const fmtDT = (s) =>
  new Date(s).toLocaleDateString("en-PH", {
    month: "short",
    day: "numeric",
    year: "numeric",
    hour: "2-digit",
    minute: "2-digit",
  });
const ini = (n) => {
  const p = (n || "?").trim().split(" ");
  return (p[0][0] + (p[1] ? p[1][0] : "")).toUpperCase();
};

const BADGE = {
  completed: "bg-green-500/10 text-green-400",
  pending: "bg-yellow-500/10 text-yellow-400",
  cancelled: "bg-red-500/10 text-red-400",
  active: "bg-blue-500/10 text-blue-400",
};
const tripBadge = (s) => BADGE[s?.toLowerCase()] || BADGE.active;

// ─── Sub-Components ───────────────────────────────────────────────────────────
function StatCard({ icon, value, label, accent }) {
  const colors = {
    blue: { icon: "bg-blue-500/10 text-blue-400", glow: "bg-blue-500" },
    orange: { icon: "bg-orange-500/10 text-orange-400", glow: "bg-orange-500" },
    green: { icon: "bg-green-500/10 text-green-400", glow: "bg-green-500" },
    yellow: { icon: "bg-yellow-500/10 text-yellow-400", glow: "bg-yellow-500" },
    red: { icon: "bg-red-500/10 text-red-400", glow: "bg-red-500" },
    purple: { icon: "bg-purple-500/10 text-purple-400", glow: "bg-purple-500" },
  };
  const c = colors[accent] || colors.blue;
  return (
    <div className="relative bg-[#0f1f35] border border-[rgba(99,160,220,0.15)] rounded-xl p-5 overflow-hidden hover:border-[rgba(99,160,220,0.35)] transition-all">
      <div
        className={`w-9 h-9 rounded-lg flex items-center justify-center mb-3 ${c.icon}`}
      >
        {icon}
      </div>
      <div className="text-2xl font-bold text-[#cce0f5] leading-tight mb-1">
        {value}
      </div>
      <div className="text-[0.65rem] uppercase tracking-widest text-[#6a9cbf] font-semibold">
        {label}
      </div>
      <div
        className={`absolute -bottom-5 -right-5 w-20 h-20 rounded-full opacity-[0.07] ${c.glow}`}
      />
    </div>
  );
}

function NavBtn({ icon, label, active, onClick }) {
  return (
    <button
      onClick={onClick}
      className={`flex items-center gap-2.5 w-[calc(100%-20px)] mx-[10px] px-4 py-2.5 rounded-lg text-sm font-medium text-left transition-all border
        ${
          active
            ? "bg-blue-500/10 text-blue-400 font-semibold border-[rgba(99,160,220,0.35)]"
            : "bg-transparent text-[#6a9cbf] border-transparent hover:bg-white/[0.04] hover:text-[#cce0f5]"
        }`}
    >
      <span className="opacity-80">{icon}</span>
      {label}
      {active && (
        <span className="ml-auto w-1.5 h-1.5 rounded-full bg-blue-400 shadow-[0_0_6px_#3b8ee8]" />
      )}
    </button>
  );
}

function MiniAvatar({ name, role }) {
  return (
    <div
      className={`w-8 h-8 rounded-full flex items-center justify-center text-[0.65rem] font-bold text-white flex-shrink-0
      ${role === "driver" ? "bg-gradient-to-br from-orange-400 to-orange-700" : "bg-gradient-to-br from-blue-400 to-blue-800"}`}
    >
      {ini(name)}
    </div>
  );
}

function RoleBadge({ role }) {
  return (
    <span
      className={`inline-block px-2 py-0.5 rounded-full text-[0.62rem] font-bold uppercase
      ${role === "driver" ? "bg-orange-500/10 text-orange-400" : "bg-blue-500/10 text-blue-400"}`}
    >
      {role}
    </span>
  );
}

function StatusBadge({ status }) {
  return (
    <span
      className={`inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-[0.65rem] font-bold ${tripBadge(status)}`}
    >
      ● {status?.charAt(0).toUpperCase() + status?.slice(1)}
    </span>
  );
}

function Pagination({ page, total, onPage }) {
  const pages = [];
  for (let p = Math.max(1, page - 2); p <= Math.min(total, page + 2); p++)
    pages.push(p);
  return (
    <div className="flex items-center justify-between px-4 py-3 border-t border-[rgba(99,160,220,0.15)]">
      <span className="text-[0.72rem] text-[#6a9cbf]">
        Page {page} of {total}
      </span>
      <div className="flex gap-1">
        <button
          disabled={page <= 1}
          onClick={() => onPage(page - 1)}
          className="px-2.5 py-1 text-[0.72rem] rounded border border-[rgba(99,160,220,0.15)] bg-[#132540] text-[#6a9cbf] disabled:opacity-30 hover:bg-blue-500 hover:border-blue-500 hover:text-white transition"
        >
          ← Prev
        </button>
        {pages.map((p) => (
          <button
            key={p}
            onClick={() => onPage(p)}
            className={`px-2.5 py-1 text-[0.72rem] rounded border transition
              ${p === page ? "bg-blue-500 border-blue-500 text-white" : "border-[rgba(99,160,220,0.15)] bg-[#132540] text-[#6a9cbf] hover:bg-blue-500 hover:border-blue-500 hover:text-white"}`}
          >
            {p}
          </button>
        ))}
        <button
          disabled={page >= total}
          onClick={() => onPage(page + 1)}
          className="px-2.5 py-1 text-[0.72rem] rounded border border-[rgba(99,160,220,0.15)] bg-[#132540] text-[#6a9cbf] disabled:opacity-30 hover:bg-blue-500 hover:border-blue-500 hover:text-white transition"
        >
          Next →
        </button>
      </div>
    </div>
  );
}

function TableCard({ title, count, children, pagination }) {
  return (
    <div className="bg-[#0f1f35] border border-[rgba(99,160,220,0.15)] rounded-xl overflow-hidden">
      <div className="flex items-center justify-between px-5 py-4 border-b border-[rgba(99,160,220,0.15)]">
        <div className="flex items-center gap-2 text-[0.875rem] font-semibold text-[#cce0f5]">
          <span className="w-1.5 h-1.5 rounded-full bg-blue-400 shadow-[0_0_6px_#3b8ee8]" />
          {title}
        </div>
        <span className="text-[0.75rem] text-[#6a9cbf]">{count}</span>
      </div>
      <div className="overflow-x-auto">{children}</div>
      {pagination}
    </div>
  );
}

const TH = ({ children }) => (
  <th className="px-4 py-2.5 text-left text-[0.65rem] font-bold uppercase tracking-widest text-[#6a9cbf] bg-[#132540] whitespace-nowrap sticky top-0 z-10">
    {children}
  </th>
);
const TD = ({ children, className = "" }) => (
  <td
    className={`px-4 py-3 text-[#6a9cbf] align-middle text-[0.8rem] ${className}`}
  >
    {children}
  </td>
);
const EmptyRow = ({ cols }) => (
  <tr>
    <td colSpan={cols} className="text-center py-10 text-[#6a9cbf] text-sm">
      No records found.
    </td>
  </tr>
);

// ─── Views ─────────────────────────────────────────────────────────────────────
function OverviewView({ users, trips, onGoTrips }) {
  const drivers = users.filter((u) => u.role === "driver");
  const commuters = users.filter((u) => u.role === "commuter");
  const revenue = trips
    .filter((t) => t.status === "completed")
    .reduce((a, t) => a + t.fare, 0);
  const recent = trips.slice(0, 10);

  return (
    <div className="animate-[fadeUp_0.25s_ease]">
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-3 mb-5">
        <StatCard
          icon={<span className="text-lg">🛺</span>}
          value={fmt(trips.length)}
          label="Total Bookings"
          accent="blue"
        />
        <StatCard
          icon={<span className="text-lg">👤</span>}
          value={fmt(drivers.length)}
          label="Active Drivers"
          accent="green"
        />
        <StatCard
          icon={<span className="text-lg">👥</span>}
          value={fmt(commuters.length)}
          label="Total Commuters"
          accent="purple"
        />
        <StatCard
          icon={<span className="text-lg font-bold">₱</span>}
          value={fmtP(revenue)}
          label="Daily Earnings"
          accent="orange"
        />
      </div>

      <div className="grid grid-cols-1 xl:grid-cols-[1.4fr_0.6fr] gap-4">
        {/* Recent Trips */}
        <div className="bg-[#0f1f35] border border-[rgba(99,160,220,0.15)] rounded-xl overflow-hidden">
          <div className="flex items-center justify-between px-5 py-4 border-b border-[rgba(99,160,220,0.15)]">
            <div className="flex items-center gap-2 text-sm font-semibold text-[#cce0f5]">
              <span className="w-1.5 h-1.5 rounded-full bg-blue-400 shadow-[0_0_6px_#3b8ee8]" />{" "}
              Recent Trips
            </div>
            <button
              onClick={onGoTrips}
              className="text-blue-400 text-[0.75rem] hover:opacity-75 transition"
            >
              View All History →
            </button>
          </div>
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead>
                <tr>
                  <TH>Trip ID</TH>
                  <TH>Commuter</TH>
                  <TH>Driver</TH>
                  <TH>Origin</TH>
                  <TH>Destination</TH>
                  <TH>Fare</TH>
                  <TH>Status</TH>
                </tr>
              </thead>
              <tbody>
                {recent.length === 0 ? (
                  <EmptyRow cols={7} />
                ) : (
                  recent.map((t) => (
                    <tr
                      key={t.id}
                      className="border-b border-[rgba(99,160,220,0.08)] hover:bg-blue-500/[0.04] transition"
                    >
                      <TD className="!text-blue-400 font-bold">#{t.id}</TD>
                      <TD className="!text-[#cce0f5]">
                        {t.commuter_name || "—"}
                      </TD>
                      <TD>{t.driver_name || "—"}</TD>
                      <TD>{t.origin}</TD>
                      <TD>{t.destination}</TD>
                      <TD className="!text-green-400 font-semibold">
                        {fmtP(t.fare)}
                      </TD>
                      <TD>
                        <StatusBadge status={t.status} />
                      </TD>
                    </tr>
                  ))
                )}
              </tbody>
            </table>
          </div>
        </div>

        {/* Fleet Summary */}
        <div className="bg-[#0f1f35] border border-[rgba(99,160,220,0.15)] rounded-xl p-5">
          <div className="flex items-center gap-2 text-sm font-semibold text-[#cce0f5] mb-4">
            <span className="w-1.5 h-1.5 rounded-full bg-green-400 shadow-[0_0_6px_#22c55e]" />{" "}
            Fleet Summary
          </div>
          <p className="text-[0.7rem] uppercase tracking-widest text-[#6a9cbf] font-bold mb-3 pb-2 border-b border-[rgba(99,160,220,0.15)]">
            System Overview
          </p>
          {[
            ["Total Drivers", fmt(drivers.length)],
            ["Total Commuters", fmt(commuters.length)],
            ["Total Bookings", fmt(trips.length)],
            ["Daily Revenue", fmtP(revenue), "!text-green-400"],
          ].map(([label, val, cls = ""]) => (
            <div
              key={label}
              className="flex justify-between items-center py-2 border-b border-[rgba(99,160,220,0.08)] last:border-0"
            >
              <span className="text-[0.8rem] text-[#6a9cbf]">{label}</span>
              <span className={`text-[0.8rem] font-bold text-[#cce0f5] ${cls}`}>
                {val}
              </span>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}

function TripsView({ trips }) {
  const [search, setSearch] = useState("");
  const [statusFilter, setStatusFilter] = useState("");
  const [page, setPage] = useState(1);
  const PER = 10;

  const filtered = trips.filter((t) => {
    const q = search.toLowerCase();
    const matchS = !statusFilter || t.status === statusFilter;
    const matchQ =
      !q ||
      [t.commuter_name, t.driver_name, t.origin, t.destination].some((f) =>
        f?.toLowerCase().includes(q),
      );
    return matchS && matchQ;
  });
  const pages = Math.max(1, Math.ceil(filtered.length / PER));
  const rows = filtered.slice((page - 1) * PER, page * PER);

  const completed = trips.filter((t) => t.status === "completed");
  const revenue = completed.reduce((a, t) => a + t.fare, 0);

  return (
    <div className="animate-[fadeUp_0.25s_ease]">
      <div className="grid grid-cols-2 lg:grid-cols-5 gap-3 mb-5">
        <StatCard
          icon={<span>🗂</span>}
          value={fmt(trips.length)}
          label="Total Trips"
          accent="blue"
        />
        <StatCard
          icon={<span>✅</span>}
          value={fmt(completed.length)}
          label="Completed"
          accent="green"
        />
        <StatCard
          icon={<span>⏳</span>}
          value={fmt(trips.filter((t) => t.status === "pending").length)}
          label="Pending"
          accent="yellow"
        />
        <StatCard
          icon={<span>❌</span>}
          value={fmt(trips.filter((t) => t.status === "cancelled").length)}
          label="Cancelled"
          accent="red"
        />
        <StatCard
          icon={<span className="font-bold text-lg">₱</span>}
          value={fmtP(revenue)}
          label="Total Revenue"
          accent="orange"
        />
      </div>

      <div className="flex flex-wrap gap-2 mb-4">
        <input
          value={search}
          onChange={(e) => {
            setSearch(e.target.value);
            setPage(1);
          }}
          placeholder="Search commuter, driver, or route…"
          className="flex-1 min-w-[180px] bg-[#132540] border border-[rgba(99,160,220,0.15)] rounded-lg px-3 py-2 text-[0.82rem] text-[#cce0f5] placeholder-[#6a9cbf] outline-none focus:border-blue-400 transition"
        />
        <select
          value={statusFilter}
          onChange={(e) => {
            setStatusFilter(e.target.value);
            setPage(1);
          }}
          className="bg-[#132540] border border-[rgba(99,160,220,0.15)] rounded-lg px-3 py-2 text-[0.82rem] text-[#cce0f5] outline-none cursor-pointer"
        >
          <option value="">All Statuses</option>
          <option value="completed">Completed</option>
          <option value="pending">Pending</option>
          <option value="cancelled">Cancelled</option>
          <option value="active">Active</option>
        </select>
        <button
          onClick={() => {
            setSearch("");
            setStatusFilter("");
            setPage(1);
          }}
          className="px-4 py-2 bg-[#132540] border border-[rgba(99,160,220,0.15)] rounded-lg text-[0.8rem] text-[#6a9cbf] font-semibold hover:border-[rgba(99,160,220,0.35)] hover:text-[#cce0f5] transition"
        >
          Clear
        </button>
      </div>

      <TableCard
        title="All Trips"
        count={`${fmt(filtered.length)} record${filtered.length !== 1 ? "s" : ""}`}
        pagination={<Pagination page={page} total={pages} onPage={setPage} />}
      >
        <table className="w-full text-sm">
          <thead>
            <tr>
              <TH>Trip ID</TH>
              <TH>Commuter</TH>
              <TH>Driver</TH>
              <TH>Origin</TH>
              <TH>Destination</TH>
              <TH>Fare</TH>
              <TH>Date</TH>
              <TH>Status</TH>
            </tr>
          </thead>
          <tbody>
            {rows.length === 0 ? (
              <EmptyRow cols={8} />
            ) : (
              rows.map((t) => (
                <tr
                  key={t.id}
                  className="border-b border-[rgba(99,160,220,0.08)] hover:bg-blue-500/[0.04] transition"
                >
                  <TD className="!text-blue-400 font-bold">#{t.id}</TD>
                  <TD className="!text-[#cce0f5]">{t.commuter_name || "—"}</TD>
                  <TD>{t.driver_name || "—"}</TD>
                  <TD>{t.origin}</TD>
                  <TD>{t.destination}</TD>
                  <TD className="!text-green-400 font-semibold">
                    {fmtP(t.fare)}
                  </TD>
                  <TD className="!text-[0.72rem]">{fmtDT(t.created_at)}</TD>
                  <TD>
                    <StatusBadge status={t.status} />
                  </TD>
                </tr>
              ))
            )}
          </tbody>
        </table>
      </TableCard>
    </div>
  );
}

function CommutersView({ users }) {
  const commuters = users.filter((u) => u.role === "commuter");
  const [search, setSearch] = useState("");
  const [page, setPage] = useState(1);
  const PER = 10;

  const filtered = commuters.filter((c) => {
    const q = search.toLowerCase();
    return (
      !q ||
      [c.username, c.email, c.contact_no, c.address].some((f) =>
        f?.toLowerCase().includes(q),
      )
    );
  });
  const pages = Math.max(1, Math.ceil(filtered.length / PER));
  const rows = filtered.slice((page - 1) * PER, page * PER);

  return (
    <div className="animate-[fadeUp_0.25s_ease]">
      <div className="grid grid-cols-1 md:grid-cols-3 gap-3 mb-5">
        <StatCard
          icon={<span>👥</span>}
          value={fmt(commuters.length)}
          label="Total Commuters"
          accent="blue"
        />
        <StatCard
          icon={<span>🆕</span>}
          value={fmt(
            commuters.filter(
              (c) =>
                new Date(c.created_at).toDateString() ===
                new Date().toDateString(),
            ).length,
          )}
          label="Joined Today"
          accent="green"
        />
        <StatCard
          icon={<span>📍</span>}
          value={fmt(commuters.filter((c) => c.status === "verified").length)}
          label="Verified"
          accent="orange"
        />
      </div>

      <div className="flex flex-wrap gap-2 mb-4">
        <input
          value={search}
          onChange={(e) => {
            setSearch(e.target.value);
            setPage(1);
          }}
          placeholder="Search by name, email, phone, or address…"
          className="flex-1 min-w-[200px] bg-[#132540] border border-[rgba(99,160,220,0.15)] rounded-lg px-3 py-2 text-[0.82rem] text-[#cce0f5] placeholder-[#6a9cbf] outline-none focus:border-blue-400 transition"
        />
        <button
          onClick={() => {
            setSearch("");
            setPage(1);
          }}
          className="px-4 py-2 bg-[#132540] border border-[rgba(99,160,220,0.15)] rounded-lg text-[0.8rem] text-[#6a9cbf] font-semibold hover:border-[rgba(99,160,220,0.35)] hover:text-[#cce0f5] transition"
        >
          Clear
        </button>
      </div>

      <TableCard
        title="Commuter Registry"
        count={`${fmt(filtered.length)} record${filtered.length !== 1 ? "s" : ""}`}
        pagination={<Pagination page={page} total={pages} onPage={setPage} />}
      >
        <table className="w-full text-sm">
          <thead>
            <tr>
              <TH>ID</TH>
              <TH>Name</TH>
              <TH>Email</TH>
              <TH>Phone</TH>
              <TH>Address</TH>
              <TH>Status</TH>
              <TH>Joined</TH>
            </tr>
          </thead>
          <tbody>
            {rows.length === 0 ? (
              <EmptyRow cols={7} />
            ) : (
              rows.map((c) => (
                <tr
                  key={c.id}
                  className="border-b border-[rgba(99,160,220,0.08)] hover:bg-blue-500/[0.04] transition"
                >
                  <TD className="!text-[0.72rem]">#{c.id}</TD>
                  <TD>
                    <div className="flex items-center gap-2.5">
                      <MiniAvatar name={c.username} role="commuter" />
                      <span className="text-[#cce0f5] font-medium">
                        {c.username}
                      </span>
                    </div>
                  </TD>
                  <TD>{c.email || "—"}</TD>
                  <TD>{c.contact_no || "—"}</TD>
                  <TD className="max-w-[140px] truncate">{c.address || "—"}</TD>
                  <TD>
                    <span
                      className={`inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-[0.65rem] font-bold
                    ${c.status === "verified" ? "bg-green-500/10 text-green-400" : c.status === "rejected" ? "bg-red-500/10 text-red-400" : "bg-yellow-500/10 text-yellow-400"}`}
                    >
                      ● {c.status?.charAt(0).toUpperCase() + c.status?.slice(1)}
                    </span>
                  </TD>
                  <TD className="!text-[0.72rem]">{fmtD(c.created_at)}</TD>
                </tr>
              ))
            )}
          </tbody>
        </table>
      </TableCard>
    </div>
  );
}

function DriversView({ users }) {
  const drivers = users.filter((u) => u.role === "driver");
  const [search, setSearch] = useState("");
  const [page, setPage] = useState(1);
  const PER = 10;

  const filtered = drivers.filter((d) => {
    const q = search.toLowerCase();
    return (
      !q ||
      [
        d.username,
        d.email,
        d.contact_no,
        d.plate_number,
        d.organization,
        d.license_no,
      ].some((f) => f?.toLowerCase().includes(q))
    );
  });
  const pages = Math.max(1, Math.ceil(filtered.length / PER));
  const rows = filtered.slice((page - 1) * PER, page * PER);

  return (
    <div className="animate-[fadeUp_0.25s_ease]">
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-3 mb-5">
        <StatCard
          icon={<span>🛺</span>}
          value={fmt(drivers.length)}
          label="Total Drivers"
          accent="blue"
        />
        <StatCard
          icon={<span>🟢</span>}
          value={fmt(drivers.filter((d) => d.is_available === "1").length)}
          label="Online Now"
          accent="green"
        />
        <StatCard
          icon={<span>🆕</span>}
          value={fmt(
            drivers.filter(
              (d) =>
                new Date(d.created_at).toDateString() ===
                new Date().toDateString(),
            ).length,
          )}
          label="Joined Today"
          accent="yellow"
        />
        <StatCard
          icon={<span className="font-bold text-lg">₱</span>}
          value={fmtP(0)}
          label="Total Revenue"
          accent="orange"
        />
      </div>

      <div className="flex flex-wrap gap-2 mb-4">
        <input
          value={search}
          onChange={(e) => {
            setSearch(e.target.value);
            setPage(1);
          }}
          placeholder="Search by name, plate, TODA, license, or contact…"
          className="flex-1 min-w-[200px] bg-[#132540] border border-[rgba(99,160,220,0.15)] rounded-lg px-3 py-2 text-[0.82rem] text-[#cce0f5] placeholder-[#6a9cbf] outline-none focus:border-blue-400 transition"
        />
        <button
          onClick={() => {
            setSearch("");
            setPage(1);
          }}
          className="px-4 py-2 bg-[#132540] border border-[rgba(99,160,220,0.15)] rounded-lg text-[0.8rem] text-[#6a9cbf] font-semibold hover:border-[rgba(99,160,220,0.35)] hover:text-[#cce0f5] transition"
        >
          Clear
        </button>
      </div>

      <TableCard
        title="Driver Registry"
        count={`${fmt(filtered.length)} record${filtered.length !== 1 ? "s" : ""}`}
        pagination={<Pagination page={page} total={pages} onPage={setPage} />}
      >
        <table className="w-full text-sm">
          <thead>
            <tr>
              <TH>Driver</TH>
              <TH>Contact</TH>
              <TH>Plate No.</TH>
              <TH>License No.</TH>
              <TH>TODA / Org.</TH>
              <TH>Status</TH>
              <TH>Joined</TH>
            </tr>
          </thead>
          <tbody>
            {rows.length === 0 ? (
              <EmptyRow cols={7} />
            ) : (
              rows.map((d) => (
                <tr
                  key={d.id}
                  className="border-b border-[rgba(99,160,220,0.08)] hover:bg-blue-500/[0.04] transition"
                >
                  <TD>
                    <div className="flex items-center gap-2.5">
                      <MiniAvatar name={d.username} role="driver" />
                      <div>
                        <div className="text-[#cce0f5] font-medium">
                          {d.username}
                        </div>
                        <div className="text-[0.68rem] text-[#6a9cbf]">
                          {d.email}
                        </div>
                      </div>
                    </div>
                  </TD>
                  <TD>{d.contact_no || "—"}</TD>
                  <TD>
                    {d.plate_number ? (
                      <span className="inline-block bg-orange-500/10 border border-orange-500/30 text-orange-400 rounded-md px-2 py-0.5 text-[0.7rem] font-bold">
                        {d.plate_number}
                      </span>
                    ) : (
                      "—"
                    )}
                  </TD>
                  <TD>{d.license_no || "—"}</TD>
                  <TD>{d.organization || "—"}</TD>
                  <TD>
                    <span
                      className={`inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-[0.65rem] font-bold
                    ${d.is_available === "1" ? "bg-green-500/10 text-green-400" : "bg-red-500/10 text-red-400"}`}
                    >
                      ● {d.is_available === "1" ? "Online" : "Offline"}
                    </span>
                  </TD>
                  <TD className="!text-[0.72rem]">{fmtD(d.created_at)}</TD>
                </tr>
              ))
            )}
          </tbody>
        </table>
      </TableCard>
    </div>
  );
}

// ─── Global Search Dropdown ───────────────────────────────────────────────────
function SearchDropdown({ users, open, query, tab, onTabChange, onClose }) {
  const q = query.toLowerCase();
  const results = users
    .filter((u) => {
      const matchTab = tab === "all" || u.role === tab;
      const matchQ =
        !q ||
        [
          u.username,
          u.email,
          u.contact_no,
          u.plate_number,
          u.organization,
          u.license_no,
          u.address,
        ].some((f) => f?.toLowerCase().includes(q));
      return matchTab && matchQ;
    })
    .slice(0, 50);

  const hl = (text) => {
    if (!q || !text) return text || "";
    const idx = text.toLowerCase().indexOf(q);
    if (idx === -1) return text;
    return (
      <>
        {text.slice(0, idx)}
        <mark className="bg-blue-500/25 text-blue-300 rounded-sm">
          {text.slice(idx, idx + q.length)}
        </mark>
        {text.slice(idx + q.length)}
      </>
    );
  };

  if (!open) return null;
  return (
    <div className="absolute top-[calc(100%+10px)] left-0 w-[480px] bg-[#0f1f35] border border-[rgba(99,160,220,0.35)] rounded-xl shadow-2xl z-[9999] overflow-hidden animate-[fadeUp_0.17s_ease]">
      <div className="flex border-b border-[rgba(99,160,220,0.15)]">
        {["all", "commuter", "driver"].map((t) => (
          <button
            key={t}
            onClick={() => onTabChange(t)}
            className={`flex-1 py-2.5 text-[0.7rem] font-bold uppercase tracking-wide transition border-b-2
              ${tab === t ? "text-blue-400 border-blue-400" : "text-[#6a9cbf] border-transparent hover:text-[#cce0f5]"}`}
          >
            {t === "all"
              ? "All Users"
              : t === "commuter"
                ? "Commuters"
                : "Drivers"}
          </button>
        ))}
      </div>
      <div className="max-h-[300px] overflow-y-auto">
        {!q ? (
          <div className="text-center py-8 text-[0.78rem] text-[#6a9cbf]">
            Type to search the fleet database...
          </div>
        ) : results.length === 0 ? (
          <div className="text-center py-8 text-[0.78rem] text-[#6a9cbf]">
            No matches found for "{query}"
          </div>
        ) : (
          results.map((u) => (
            <div
              key={u.id}
              className="flex items-center gap-3 px-4 py-3 border-b border-[rgba(99,160,220,0.08)] hover:bg-blue-500/10 cursor-pointer transition"
            >
              <div
                className={`w-9 h-9 rounded-full flex items-center justify-center text-[0.72rem] font-bold text-white flex-shrink-0
                ${u.role === "driver" ? "bg-gradient-to-br from-orange-400 to-orange-700" : "bg-gradient-to-br from-blue-400 to-blue-800"}`}
              >
                {ini(u.username)}
              </div>
              <div className="flex-1 min-w-0">
                <div className="text-[0.82rem] font-semibold text-[#cce0f5] truncate">
                  {hl(u.username)}
                </div>
                <div className="text-[0.7rem] text-[#6a9cbf] mt-0.5 truncate">
                  {u.role === "driver" ? (
                    <>
                      <b>{hl(u.plate_number) || "No plate"}</b> ·{" "}
                      {hl(u.organization) || "—"} · License:{" "}
                      {hl(u.license_no) || "—"}
                    </>
                  ) : (
                    hl(u.email)
                  )}
                </div>
              </div>
              <div className="text-right flex-shrink-0">
                <RoleBadge role={u.role} />
                <div className="text-[0.64rem] text-[#6a9cbf] mt-1">
                  #{u.id}
                </div>
              </div>
            </div>
          ))
        )}
      </div>
      {q && (
        <div className="flex justify-between items-center px-4 py-2 bg-[#132540] border-t border-[rgba(99,160,220,0.15)]">
          <span className="text-[0.68rem] text-[#6a9cbf]">
            {results.length} result{results.length !== 1 ? "s" : ""}
          </span>
          <span className="text-[0.68rem] text-[#6a9cbf]">
            pasadanow · registry
          </span>
        </div>
      )}
    </div>
  );
}

// ─── Main Dashboard ───────────────────────────────────────────────────────────
const VIEWS = ["overview", "trips", "commuters", "drivers"];
const VIEW_TITLES = {
  overview: "PasadaNow Command Center",
  trips: "Trip Records",
  commuters: "Commuters",
  drivers: "Partner Drivers",
};
const NAV_ITEMS = [
  { id: "overview", label: "Overview", icon: "⊞" },
  { id: "trips", label: "Trip Records", icon: "🕐" },
  { id: "commuters", label: "Commuters", icon: "👤" },
  { id: "drivers", label: "Partner Drivers", icon: "🛺" },
];

export default function AdminDashboard() {
  const [view, setView] = useState("overview");
  const [clock, setClock] = useState("");
  const [searchQ, setSearchQ] = useState("");
  const [searchOpen, setSearchOpen] = useState(false);
  const [searchTab, setSearchTab] = useState("all");
  const searchRef = useRef(null);

  // Clock
  useEffect(() => {
    const tick = () => {
      const now = new Date();
      const days = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];
      const months = [
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
      let h = now.getHours(),
        ampm = h >= 12 ? "PM" : "AM";
      h = h % 12 || 12;
      setClock(
        `${days[now.getDay()]}, ${months[now.getMonth()]} ${now.getDate()}, ${h}:${String(now.getMinutes()).padStart(2, "0")}:${String(now.getSeconds()).padStart(2, "0")} ${ampm}`,
      );
    };
    tick();
    const id = setInterval(tick, 1000);
    return () => clearInterval(id);
  }, []);

  // Close search on outside click
  useEffect(() => {
    const handler = (e) => {
      if (searchRef.current && !searchRef.current.contains(e.target))
        setSearchOpen(false);
    };
    document.addEventListener("mousedown", handler);
    return () => document.removeEventListener("mousedown", handler);
  }, []);

  return (
    <div className="flex h-screen overflow-hidden bg-[#0a1628] text-[#cce0f5] font-['Outfit',sans-serif]">
      <style>{`
        @import url('https://fonts.googleapis.com/css2?family=Outfit:wght@300;400;500;600;700;800&display=swap');
        @keyframes fadeUp { from { opacity:0; transform:translateY(8px); } to { opacity:1; transform:translateY(0); } }
        ::-webkit-scrollbar { width: 4px; height: 4px; }
        ::-webkit-scrollbar-thumb { background: rgba(99,160,220,0.25); border-radius: 4px; }
      `}</style>

      {/* ── Sidebar ── */}
      <aside className="w-[230px] bg-[#0f1f35] border-r border-[rgba(99,160,220,0.15)] flex flex-col flex-shrink-0">
        {/* Logo */}
        <div className="flex items-center gap-2.5 px-5 py-[22px] border-b border-[rgba(99,160,220,0.15)]">
          <div className="w-9 h-9 rounded-lg bg-gradient-to-br from-blue-400 to-orange-500 flex items-center justify-center text-white text-lg shadow">
            🛺
          </div>
          <div className="text-[1.25rem] font-black leading-none">
            <span className="text-blue-400">Pasada</span>
            <span className="text-orange-400">Now</span>
          </div>
        </div>

        {/* Nav */}
        <div className="mt-4 mb-1 px-5 text-[0.6rem] font-bold uppercase tracking-[1.5px] text-[#6a9cbf]">
          Admin Control
        </div>
        <nav className="flex flex-col gap-0.5 mt-1">
          {NAV_ITEMS.map((item) => (
            <NavBtn
              key={item.id}
              icon={<span>{item.icon}</span>}
              label={item.label}
              active={view === item.id}
              onClick={() => setView(item.id)}
            />
          ))}
        </nav>

        {/* Footer */}
        <div className="mt-auto p-4 border-t border-[rgba(99,160,220,0.15)]">
          <div className="flex items-center gap-2.5 p-2 rounded-lg bg-[#132540] mb-3">
            <div className="w-8 h-8 rounded-full bg-gradient-to-br from-blue-400 to-blue-800 flex items-center justify-center text-xs font-bold text-white flex-shrink-0">
              A
            </div>
            <div className="flex-1 min-w-0">
              <div className="text-[0.8rem] font-semibold truncate">Admin</div>
              <div className="text-[0.65rem] text-[#6a9cbf]">System Admin</div>
            </div>
          </div>
          <a
            href="/login"
            className="flex items-center gap-2 text-red-400 text-[0.8rem] font-medium px-2 py-1.5 rounded-md hover:bg-red-500/10 transition"
          >
            <span>→</span> Sign Out
          </a>
        </div>
      </aside>

      {/* ── Main ── */}
      <main className="flex-1 flex flex-col overflow-hidden">
        {/* Topbar */}
        <header className="bg-[#0f1f35] border-b border-[rgba(99,160,220,0.15)] px-7 py-3.5 flex items-center gap-4 flex-shrink-0">
          <h2 className="text-[1.1rem] font-bold flex-shrink-0">
            {VIEW_TITLES[view]}
          </h2>

          {/* Search */}
          <div className="flex-1 flex items-center justify-center gap-2">
            <div className="relative w-[360px]" ref={searchRef}>
              <div
                className={`flex items-center bg-[#132540] border rounded-lg px-3.5 py-2 gap-2 transition ${searchOpen ? "border-blue-400" : "border-[rgba(99,160,220,0.15)]"}`}
              >
                <svg
                  className="w-3.5 h-3.5 text-[#6a9cbf] flex-shrink-0"
                  viewBox="0 0 24 24"
                  fill="none"
                  stroke="currentColor"
                  strokeWidth="2"
                >
                  <circle cx="11" cy="11" r="8" />
                  <line x1="21" y1="21" x2="16.65" y2="16.65" />
                </svg>
                <input
                  value={searchQ}
                  onChange={(e) => {
                    setSearchQ(e.target.value);
                    setSearchOpen(true);
                  }}
                  onFocus={() => setSearchOpen(true)}
                  placeholder="Search plate, license, name, or TODA..."
                  className="bg-transparent outline-none text-[#cce0f5] text-[0.8rem] w-full placeholder-[#6a9cbf]"
                />
                {searchQ && (
                  <button
                    onClick={() => {
                      setSearchQ("");
                      setSearchOpen(false);
                    }}
                    className="text-[#6a9cbf] hover:text-red-400 transition text-xs"
                  >
                    ✕
                  </button>
                )}
              </div>
              <SearchDropdown
                users={MOCK_USERS}
                open={searchOpen}
                query={searchQ}
                tab={searchTab}
                onTabChange={setSearchTab}
                onClose={() => setSearchOpen(false)}
              />
            </div>
            <button
              onClick={() => setSearchOpen(true)}
              className="bg-blue-500 hover:opacity-90 text-white text-[0.8rem] font-semibold px-4 py-2 rounded-lg transition"
            >
              Search
            </button>
          </div>

          <div className="flex items-center gap-4">
            <span className="text-[0.78rem] text-[#6a9cbf] whitespace-nowrap">
              {clock}
            </span>
            <button className="relative bg-[#132540] border border-[rgba(99,160,220,0.15)] rounded-lg w-9 h-9 flex items-center justify-center text-[#6a9cbf]">
              🔔
              <span className="absolute -top-1 -right-1 w-3.5 h-3.5 bg-orange-500 text-white text-[0.5rem] font-bold rounded-full flex items-center justify-center">
                0
              </span>
            </button>
          </div>
        </header>

        {/* Content */}
        <div className="flex-1 overflow-y-auto p-6 px-7">
          {view === "overview" && (
            <OverviewView
              users={MOCK_USERS}
              trips={MOCK_TRIPS}
              onGoTrips={() => setView("trips")}
            />
          )}
          {view === "trips" && <TripsView trips={MOCK_TRIPS} />}
          {view === "commuters" && <CommutersView users={MOCK_USERS} />}
          {view === "drivers" && <DriversView users={MOCK_USERS} />}
        </div>
      </main>
    </div>
  );
}
