import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json; charset=utf-8" },
  });
}

function clean(value: unknown, max = 2000) {
  return typeof value === "string" ? value.trim().slice(0, max) : "";
}

function isValidPhone(phone: string) {
  return /^[+()\d\s-]{7,40}$/.test(phone);
}

function isValidEmail(email: string) {
  return !email || /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
}

async function sha256(value: string) {
  const bytes = new TextEncoder().encode(value);
  const digest = await crypto.subtle.digest("SHA-256", bytes);
  return Array.from(new Uint8Array(digest))
    .map((byte) => byte.toString(16).padStart(2, "0"))
    .join("");
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return json({ ok: false, error: "method_not_allowed" }, 405);
  }

  try {
    const raw = await req.text();
    if (!raw || raw.length > 20_000) {
      return json({ ok: false, error: "invalid_payload" }, 400);
    }

    let payload: Record<string, unknown>;
    try {
      payload = JSON.parse(raw);
    } catch {
      return json({ ok: false, error: "invalid_json" }, 400);
    }

    // Honeypot field: real users never fill it.
    if (clean(payload.website, 200)) {
      return json({ ok: true, accepted: true });
    }

    const name = clean(payload.name, 120);
    const phone = clean(payload.phone, 40);
    const email = clean(payload.email, 320);
    const city = clean(payload.city, 120);
    const message = clean(payload.message, 2000);
    const source = clean(payload.source, 80) || "website";
    const pageUrl = clean(payload.page_url, 1000);

    if (name.length < 2) {
      return json({ ok: false, error: "name_required", message: "Вкажіть імʼя." }, 422);
    }
    if (!isValidPhone(phone)) {
      return json({ ok: false, error: "phone_invalid", message: "Перевірте номер телефону." }, 422);
    }
    if (!isValidEmail(email)) {
      return json({ ok: false, error: "email_invalid", message: "Перевірте email." }, 422);
    }

    const forwarded = req.headers.get("x-forwarded-for")?.split(",")[0]?.trim();
    const directIp =
      forwarded ||
      req.headers.get("cf-connecting-ip") ||
      req.headers.get("x-real-ip") ||
      "";
    const userAgent = (req.headers.get("user-agent") || "").slice(0, 400);
    const referer = (req.headers.get("referer") || "").slice(0, 1000);
    const rateLimitIdentity = directIp || `fallback|${userAgent}|${referer}`;
    const ipHash = await sha256(rateLimitIdentity);

    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
    if (!supabaseUrl || !serviceRoleKey) {
      console.error("Missing Supabase server environment");
      return json({ ok: false, error: "server_config" }, 500);
    }

    const supabase = createClient(supabaseUrl, serviceRoleKey, {
      auth: { persistSession: false, autoRefreshToken: false },
    });

    const { data: allowed, error: rateError } = await supabase.rpc(
      "consume_website_lead_rate_limit",
      { p_ip_hash: ipHash, p_limit: 6, p_window_seconds: 3600 },
    );

    if (rateError) {
      console.error("Rate limit error", rateError);
      return json({ ok: false, error: "rate_limit_check_failed" }, 500);
    }

    if (!allowed) {
      return json(
        { ok: false, error: "rate_limited", message: "Забагато заявок. Спробуйте трохи пізніше." },
        429,
      );
    }

    const metadata = {
      page_url: pageUrl || null,
      user_agent: userAgent,
      referer,
      ip_available: Boolean(directIp),
    };

    const { data, error } = await supabase
      .from("website_leads")
      .insert({
        name,
        phone,
        email: email || null,
        city: city || null,
        message: message || null,
        source,
        ip_hash: ipHash,
        metadata,
      })
      .select("id, created_at")
      .single();

    if (error) {
      console.error("Lead insert failed", error);
      return json({ ok: false, error: "save_failed" }, 500);
    }

    return json({ ok: true, accepted: true, id: data.id, created_at: data.created_at }, 201);
  } catch (error) {
    console.error("Unhandled submit-lead error", error);
    return json({ ok: false, error: "internal_error" }, 500);
  }
});
