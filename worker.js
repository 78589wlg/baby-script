/**
 * 婴儿脚本 · 自动发卡接口（Cloudflare Worker）
 *
 * 部署方式见 worker部署说明.md
 * 只需改下面 SECRET 和 EXPIRE 两个值。
 */

const SECRET = "baby-script-change-this-to-your-own-random-string";
const EXPIRE = "2027-12-31";        // 所有卡密的统一到期日
const ALPHA  = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"; // 去掉易混字符 I O 0 1

/* ---------- 工具 ---------- */
const enc = new TextEncoder();

async function hmac(text) {
  const key = await crypto.subtle.importKey(
    "raw", enc.encode(SECRET),
    { name: "HMAC", hash: "SHA-256" },
    false, ["sign"]
  );
  const sig = await crypto.subtle.sign("HMAC", key, enc.encode(text));
  return new Uint8Array(sig);
}

function toBase32(bytes, chars) {
  let bits = 0, value = 0, out = "";
  for (const b of bytes) {
    value = (value << 8) | b;
    bits += 8;
    while (bits >= 5) {
      out += ALPHA[(value >>> (bits - 5)) & 31];
      bits -= 5;
      if (out.length >= chars) return out;
    }
  }
  return out.padEnd(chars, ALPHA[0]);
}

function today() {
  return new Date().toISOString().slice(0, 10);
}

function json(obj, status = 200) {
  return new Response(JSON.stringify(obj), {
    status,
    headers: {
      "Content-Type": "application/json; charset=utf-8",
      "Access-Control-Allow-Origin": "*",
      "Access-Control-Allow-Methods": "GET,POST,OPTIONS",
      "Access-Control-Allow-Headers": "Content-Type",
      "Cache-Control": "no-store"
    }
  });
}

/* ---------- 发卡 ---------- */
async function issue() {
  const rnd = crypto.getRandomValues(new Uint8Array(8));
  const body = toBase32(rnd, 4);
  const sig = toBase32(await hmac(body + "|" + EXPIRE), 4);
  return `BOAT-${body}-${sig}`;
}

/* ---------- 验卡 ---------- */
async function verify(key) {
  const k = String(key || "").trim().toUpperCase();
  const m = k.match(/^BOAT-([A-Z0-9]{4})-([A-Z0-9]{4})$/);
  if (!m) return { ok: false, msg: "卡密格式不正确" };

  const sig = toBase32(await hmac(m[1] + "|" + EXPIRE), 4);
  if (sig !== m[2]) return { ok: false, msg: "卡密无效" };

  if (today() > EXPIRE) return { ok: false, msg: `卡密已于 ${EXPIRE} 过期` };
  return { ok: true, msg: "验证通过", exp: EXPIRE };
}

/* ---------- 路由 ---------- */
export default {
  async fetch(request) {
    const url = new URL(request.url);
    const path = url.pathname.replace(/\/+$/, "") || "/";

    if (request.method === "OPTIONS") return json({ ok: true });

    try {
      // 发卡
      if (path === "/claim" || path === "/") {
        const key = await issue();
        return json({ ok: true, key, exp: EXPIRE });
      }

      // 验卡
      if (path === "/verify") {
        const key = url.searchParams.get("key") || "";
        const res = await verify(key);
        return json(res);
      }

      // 健康检查
      if (path === "/ping") {
        return json({ ok: true, pong: Date.now(), exp: EXPIRE });
      }

      return json({ ok: false, msg: "接口不存在" }, 404);
    } catch (e) {
      return json({ ok: false, msg: "服务错误: " + e.message });
    }
  }
};
