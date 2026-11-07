/**
 * 婴儿脚本 · 发卡接口（Cloudflare Worker）
 *
 * 功能：
 *   GET  /quiz?n=3          领一组随机题（题库在服务端，前端看不到答案）
 *   POST /claim             提交答案，全对才发卡，同一 IP 24 小时限领 1 张
 *   GET  /verify?key=XXX    主脚本验卡（7 天有效期内有效）
 *   GET  /ping              健康检查
 *
 * 部署：Cloudflare → Workers & Pages → Create Worker → 粘贴本文件 → 改 SECRET → Deploy
 * 部署后把 https://xxx.workers.dev 写进仓库 api.txt 第一行。
 */

const SECRET = "baby-script-change-this-to-your-own-random-string"; // ★ 改成你自己的随机字符串
const VALID_DAYS = 7;                    // 卡密有效天数
const LIMIT_HOURS = 24;                  // 同一 IP 多少小时内只能领 1 张
const ALPHA = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"; // 去掉易混字符 I O 0 1

/* ---------- 题库（答案只在服务端） ---------- */
const QUESTIONS = [
  { id: "q1",  q: "Roblox 里用来创建零件实例的函数是？",   o: ["Instance.new", "game.Create", "Part.build", "workspace.add"], a: 0 },
  { id: "q2",  q: "Lua 里表示「不等于」的运算符是？",        o: ["!=", "~=", "<>", "=/="], a: 1 },
  { id: "q3",  q: "Roblox 中玩家角色的根部件通常叫？",      o: ["Torso", "Head", "HumanoidRootPart", "UpperTorso"], a: 2 },
  { id: "q4",  q: "下面哪个是 Roblox 的服务（Service）？",   o: ["Players", "Parts", "Scripts", "Models"], a: 0 },
  { id: "q5",  q: "Lua 里字符串拼接用哪个符号？",            o: ["+", "&", "..", "::"], a: 2 },
  { id: "q6",  q: "让脚本等待 1 秒，最常用的是？",           o: ["wait(1)", "task.wait(1)", "delay(1)", "sleep(1)"], a: 1 },
  { id: "q7",  q: "CFrame 主要用来表示什么？",               o: ["颜色", "位置和旋转", "大小", "材质"], a: 1 },
  { id: "q8",  q: "Roblox 中获取本地玩家的写法是？",         o: ["Players.LocalPlayer", "game.Player", "workspace.Me", "Players.Me"], a: 0 },
  { id: "q9",  q: "下面哪个不是 Roblox 的数据类型？",        o: ["Vector3", "Color3", "UDim2", "Number3"], a: 3 },
  { id: "q10", q: "Lua 里表的长度运算符是？",                o: ["#", "$", "len()", "%"], a: 0 },
  { id: "q11", q: "Roblox 脚本里 pcall 的作用是？",          o: ["循环", "保护调用、捕获错误", "打印日志", "创建线程"], a: 1 },
  { id: "q12", q: "下面哪个是 Roblox 的物理服务？",           o: ["PhysicsService", "MathService", "PartService", "MoveService"], a: 0 },
];

/* ---------- 工具 ---------- */
const enc = new TextEncoder();
const JSONH = { "Content-Type": "application/json; charset=utf-8", "Access-Control-Allow-Origin": "*" };

function json(obj, status = 200) {
  return new Response(JSON.stringify(obj), { status, headers: JSONH });
}

async function hmac(text) {
  const key = await crypto.subtle.importKey(
    "raw", enc.encode(SECRET), { name: "HMAC", hash: "SHA-256" }, false, ["sign"]
  );
  const buf = await crypto.subtle.sign("HMAC", key, enc.encode(text));
  const bytes = new Uint8Array(buf);
  let out = "";
  for (let i = 0; i < bytes.length; i++) out += ALPHA[bytes[i] % ALPHA.length];
  return out;
}

function dayStr(offset = 0) {
  const d = new Date(Date.now() + offset * 86400000);
  return d.toISOString().slice(0, 10);
}

function randStr(n) {
  let s = "";
  const rnd = crypto.getRandomValues(new Uint8Array(n));
  for (let i = 0; i < n; i++) s += ALPHA[rnd[i] % ALPHA.length];
  return s;
}

/* 卡密格式：BOAT-XXXX-XXXX，后 4 位是 HMAC(前4位|签发日期) 的截断 */
async function issue() {
  const body = randStr(4);
  const date = dayStr(0);
  const sig = (await hmac(body + "|" + date)).slice(0, 4);
  return { key: `BOAT-${body}-${sig}`, exp: dayStr(VALID_DAYS) };
}

async function verify(key) {
  const m = /^BOAT-([A-Z0-9]{4})-([A-Z0-9]{4})$/i.exec((key || "").trim().toUpperCase());
  if (!m) return { ok: false, msg: "卡密格式不对" };
  for (let i = 0; i <= VALID_DAYS; i++) {
    const date = dayStr(-i);
    const sig = (await hmac(m[1] + "|" + date)).slice(0, 4);
    if (sig === m[2]) return { ok: true, exp: dayStr(VALID_DAYS - i) };
  }
  return { ok: false, msg: "卡密无效或已过期" };
}

/* IP 限领：有 KV 用 KV，没有就用内存（够用，重启会清零） */
const memRate = new Map();

async function tooSoon(ip, env) {
  const now = Date.now();
  const win = LIMIT_HOURS * 3600 * 1000;
  if (env && env.RATE) {
    const last = await env.RATE.get("ip:" + ip);
    if (last && now - Number(last) < win) return true;
    await env.RATE.put("ip:" + ip, String(now), { expirationTtl: LIMIT_HOURS * 3600 });
    return false;
  }
  const last = memRate.get(ip) || 0;
  if (now - last < win) return true;
  memRate.set(ip, now);
  return false;
}

/* ---------- 路由 ---------- */
export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    const path = url.pathname.replace(/\/+$/, "") || "/";
    const cors = {
      "Access-Control-Allow-Origin": "*",
      "Access-Control-Allow-Methods": "GET,POST,OPTIONS",
      "Access-Control-Allow-Headers": "Content-Type",
    };
    if (request.method === "OPTIONS") return new Response(null, { headers: cors });

    if (path === "/ping") return json({ ok: true, time: Date.now() });

    if (path === "/quiz") {
      const n = Math.min(Math.max(Number(url.searchParams.get("n")) || 3, 1), 5);
      const pool = QUESTIONS.slice();
      const picked = [];
      while (picked.length < n && pool.length) {
        picked.push(pool.splice(Math.floor(Math.random() * pool.length), 1)[0]);
      }
      return json({
        ok: true,
        questions: picked.map((q) => ({ id: q.id, q: q.q, o: q.o })),
      });
    }

    if (path === "/claim") {
      let body = {};
      try { body = await request.json(); } catch (e) { body = {}; }
      const answers = body.answers || {};
      const ids = Object.keys(answers);
      if (!ids.length) return json({ ok: false, msg: "没有收到答案" }, 400);

      let right = 0;
      for (const id of ids) {
        const q = QUESTIONS.find((x) => x.id === id);
        if (q && Number(answers[id]) === q.a) right++;
      }
      if (right < ids.length) {
        return json({ ok: false, msg: `答对 ${right}/${ids.length} 题，全对才能领卡` });
      }

      const ip = request.headers.get("CF-Connecting-IP") || "unknown";
      if (await tooSoon(ip, env)) {
        return json({ ok: false, msg: `同一网络 ${LIMIT_HOURS} 小时内只能领 1 张，请明天再来` });
      }

      const k = await issue();
      return json({ ok: true, key: k.key, exp: k.exp });
    }

    if (path === "/verify") {
      const key = url.searchParams.get("key") || "";
      const r = await verify(key);
      return json(r, r.ok ? 200 : 403);
    }

    return json({ ok: false, msg: "not found" }, 404);
  },
};
