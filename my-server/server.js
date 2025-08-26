// server.js
require('dotenv').config();
const express = require('express');
const cors = require('cors');
const mysql = require('mysql2/promise');

const app = express();
app.use(cors({ origin: true, credentials: true }));
app.use(express.json());

// 로그(요청 들어오는지 확인)
app.use((req,res,next)=>{
  console.log(`${req.method} ${req.url}`);
  next();
});

// DB 풀 (없으면 null)
let pool = null;
(async () => {
  try {
    pool = await mysql.createPool({
      host: process.env.DB_HOST,
      user: process.env.DB_USER,
      password: process.env.DB_PASS,
      database: process.env.DB_NAME,
      waitForConnections: true, connectionLimit: 10
    });
    console.log('✅ DB 연결 준비 완료');
  } catch (e) {
    console.log('⚠️ DB 연결 실패(더미 데이터로 동작):', e.message);
  }
})();

// 헬스체크
app.get('/health', (req, res) => res.json({ ok: true, t: Date.now() }));

/* ===== 더미 데이터 (DB 실패 시 폴백) ===== */
const STOPS = [
  { stop_id: '123', stop_name: '건국대 정문', lat: 36.95, lng: 127.90 },
  { stop_id: '124', stop_name: '충주역',     lat: 36.97, lng: 127.93 },
  { stop_id: '125', stop_name: '도서관',     lat: 36.96, lng: 127.91 },
  { stop_id: '126', stop_name: '후문',       lat: 36.951, lng: 127.905 },
];
const ROUTES_BY_STOP = {
  '123': [
    { route_id: '100', route_name: '100번', direction: 0 },
    { route_id: '100', route_name: '100번', direction: 1 },
    { route_id: '500', route_name: '500번', direction: 0 },
  ],
  '124': [ { route_id: '500', route_name: '500번', direction: 0 } ],
  '125': [ { route_id: '100', route_name: '100번', direction: 0 } ],
  '126': [ { route_id: '100', route_name: '100번', direction: 1 } ],
};
const TIMETABLE = {
  '100|123|WEEKDAY|0': ['07:10','07:30','08:00','09:00','10:00'],
  '100|123|WEEKDAY|1': ['07:20','07:50','08:20','09:20'],
  '500|123|WEEKDAY|0': ['07:05','08:05','09:05'],
  '500|124|WEEKDAY|0': ['07:15','08:15','09:15'],
  '100|123|SAT|0': ['08:00','09:00'],
  '100|123|SUN|0': ['09:30','10:30'],
};
const ttKey = (routeId, stopId, day, dir) => `${routeId}|${stopId}|${day}|${dir}`;

/* ========== ① 정류장 검색 ========== */
// GET /api/bus/stops/search?q=검색어
app.get('/api/bus/stops/search', async (req, res) => {
  const q = (req.query.q || '').toString().trim();
  if (!q) return res.json({ success: true, data: [] });

  // DB 우선 시도
  if (pool) {
    try {
      // ⚠️ 실제 레포 테이블/컬럼명에 맞춰 수정 필요
      const [rows] = await pool.execute(
        "SELECT stop_id, stop_name, lat, lng FROM bus_stops WHERE stop_name LIKE ? LIMIT 30",
        [`%${q}%`]
      );
      return res.json({ success: true, data: rows });
    } catch (e) {
      console.log('DB 정류장검색 실패, 더미로:', e.message);
    }
  }

  // 폴백: 더미
  const lc = q.toLowerCase();
  const results = STOPS.filter(s => s.stop_name.toLowerCase().includes(lc)).slice(0,30);
  return res.json({ success: true, data: results });
});

/* ========== ② 정류장→노선 ========== */
// GET /api/bus/routes/by-stop?stopId=123
app.get('/api/bus/routes/by-stop', async (req, res) => {
  const stopId = (req.query.stopId || '').toString();
  if (!stopId) return res.json({ success: true, data: [] });

  if (pool) {
    try {
      // ⚠️ 실제 레포 스키마로 수정
      const [rows] = await pool.execute(
        `SELECT r.route_id, r.route_name, rs.direction
         FROM route_stops rs
         JOIN bus_routes r ON r.route_id = rs.route_id
         WHERE rs.stop_id = ?
         ORDER BY r.route_name`,
        [stopId]
      );
      return res.json({ success: true, data: rows });
    } catch (e) {
      console.log('DB 노선조회 실패, 더미로:', e.message);
    }
  }

  return res.json({ success: true, data: ROUTES_BY_STOP[stopId] || [] });
});

/* ========== ③ 시간표 ========== */
// GET /api/bus/timetable?routeId=100&stopId=123&day=WEEKDAY&direction=0
app.get('/api/bus/timetable', async (req, res) => {
  const routeId = (req.query.routeId || '').toString();
  const stopId = (req.query.stopId || '').toString();
  const day = (req.query.day || 'WEEKDAY').toString().toUpperCase();
  const direction = parseInt(req.query.direction || '0', 10) || 0;

  if (pool) {
    try {
      // ⚠️ 실제 레포 스키마로 수정
      const [rows] = await pool.execute(
        `SELECT depart_time
         FROM bus_timetable
         WHERE route_id=? AND stop_id=? AND service_day=? AND direction=?
         ORDER BY depart_time`,
        [routeId, stopId, day, direction]
      );
      return res.json({ success: true, data: rows });
    } catch (e) {
      console.log('DB 시간표 실패, 더미로:', e.message);
    }
  }

  const list = TIMETABLE[ttKey(routeId, stopId, day, direction)] || [];
  const data = list.map(hhmm => ({ depart_time: `${hhmm}:00` }));
  return res.json({ success: true, data });
});

// 루트/404 정리(선택)
app.get('/', (req,res)=>res.send('OK: /health, /api/bus/...'));
app.use((req,res)=>res.status(404).json({ success:false, message:'Not Found' }));

const PORT = process.env.PORT || 3000;
app.listen(PORT, '0.0.0.0', () => console.log(`🚏 Bus API on http://localhost:${PORT}`));
