"use client";

import { useCallback, useEffect, useRef, useState } from "react";
import {
  ApiError,
  downloadPdf,
  getResult,
  getSessionInfo,
  resendSession,
  startSession,
  verifySession,
  type ResultItem,
  type ResultPayload,
} from "@/lib/api";
import { fmtDate, pickLang, STRINGS, type Lang, type Strings } from "@/lib/i18n";

type Step = "loading" | "verify" | "otp" | "results" | "expired" | "offline";

const RESEND_SECONDS = 45;

export default function PortalFlow({ params }: { params: { token: string } }) {
  const token = params.token;

  const [step, setStep] = useState<Step>("loading");
  const [lang, setLang] = useState<Lang>("en");
  const [labName, setLabName] = useState("ClinForge");
  const [maskedPhone, setMaskedPhone] = useState("");
  const [challengeId, setChallengeId] = useState<string | null>(null);
  const [result, setResult] = useState<ResultPayload | null>(null);
  const [sessionToken, setSessionToken] = useState<string | null>(null);
  const t = STRINGS[lang];

  // ---- initial load: fetch link metadata without sending an OTP ----
  useEffect(() => {
    let alive = true;
    (async () => {
      try {
        const info = await getSessionInfo(token);
        if (!alive) return;
        setLabName(info.lab_name);
        setMaskedPhone(info.masked_phone);
        setLang(pickLang(info.locale));
        setStep("verify");
      } catch (e) {
        if (!alive) return;
        if (e instanceof ApiError && e.status === 0) setStep("offline");
        else setStep("expired");
      }
    })();
    return () => {
      alive = false;
    };
  }, [token]);

  const sendCode = useCallback(async () => {
    try {
      const s = await startSession(token);
      setChallengeId(s.challenge_id);
      setMaskedPhone(s.masked_phone);
      setLang(pickLang(s.locale));
      setStep("otp");
    } catch (e) {
      setStep(e instanceof ApiError && e.status === 0 ? "offline" : "expired");
    }
  }, [token]);

  const onVerified = useCallback(async (tok: string) => {
    try {
      const r = await getResult(tok);
      setSessionToken(tok);
      setResult(r);
      setLang(pickLang(r.locale));
      setStep("results");
    } catch {
      setStep("expired");
    }
  }, []);

  return (
    <>
      <TopBar
        labName={labName}
        lang={lang}
        setLang={setLang}
        tag={t.brandTag}
      />
      <div className="scroll">
        {step === "loading" && <Loading text={t.loading} />}
        {step === "verify" && (
          <Verify t={t} maskedPhone={maskedPhone} labName={labName} onSend={sendCode} />
        )}
        {step === "otp" && challengeId && (
          <Otp
            t={t}
            lang={lang}
            token={token}
            challengeId={challengeId}
            maskedPhone={maskedPhone}
            onChallenge={setChallengeId}
            onVerified={onVerified}
          />
        )}
        {step === "results" && result && (
          <Results t={t} lang={lang} data={result} sessionToken={sessionToken} />
        )}
        {step === "expired" && (
          <ErrorScreen icon="\u23F3" title={t.err_expired_t} sub={t.err_expired_s} />
        )}
        {step === "offline" && (
          <ErrorScreen
            icon="\uD83D\uDCE1"
            title={t.err_network_t}
            sub={t.err_network_s}
            action={{ label: t.retry, onClick: () => location.reload() }}
          />
        )}
      </div>
    </>
  );
}

// ------------------------------------------------------------------
// Top bar with language toggle
// ------------------------------------------------------------------

function TopBar({
  labName,
  lang,
  setLang,
  tag,
}: {
  labName: string;
  lang: Lang;
  setLang: (l: Lang) => void;
  tag: string;
}) {
  return (
    <div className="bar">
      <div className="brand">
        <div className="mark">L</div>
        <div className="txt">
          <div className="name">ClinForge</div>
          <div className="tag">
            {labName} &#183; {tag}
          </div>
        </div>
      </div>
      <div className="lang" role="group" aria-label="Language">
        <button
          aria-pressed={lang === "en"}
          onClick={() => setLang("en")}
        >
          EN
        </button>
        <button
          aria-pressed={lang === "fr"}
          onClick={() => setLang("fr")}
        >
          FR
        </button>
      </div>
    </div>
  );
}

// ------------------------------------------------------------------
// Loading
// ------------------------------------------------------------------

function Loading({ text }: { text: string }) {
  return (
    <div className="load-wrap">
      <div className="spinner" />
      <div>{text}</div>
    </div>
  );
}

// ------------------------------------------------------------------
// Verify (landing)
// ------------------------------------------------------------------

function Verify({
  t,
  maskedPhone,
  labName,
  onSend,
}: {
  t: Strings;
  maskedPhone: string;
  labName: string;
  onSend: () => Promise<void>;
}) {
  const [busy, setBusy] = useState(false);
  return (
    <div className="screen center-verify">
      <div className="big" style={{ fontSize: 34, marginBottom: 6 }}>
        &#128274;
      </div>
      <h1>{t.v_title}</h1>
      <p className="lede">{t.v_lede}</p>
      <div className="phone-chip">
        <span className="k">{t.v_key}</span>{" "}
        <span className="mono">{maskedPhone}</span>
      </div>
      <div className="spacer" />
      <button
        className="btn btn-primary"
        disabled={busy}
        onClick={async () => {
          setBusy(true);
          await onSend();
          setBusy(false);
        }}
      >
        {t.v_btn} &#8594;
      </button>
      <p className="hint">
        {labName}. {t.v_foot2}
      </p>
    </div>
  );
}

// ------------------------------------------------------------------
// OTP
// ------------------------------------------------------------------

function Otp({
  t,
  lang,
  token,
  challengeId,
  maskedPhone,
  onChallenge,
  onVerified,
}: {
  t: Strings;
  lang: Lang;
  token: string;
  challengeId: string;
  maskedPhone: string;
  onChallenge: (id: string) => void;
  onVerified: (sessionToken: string) => Promise<void>;
}) {
  const [digits, setDigits] = useState<string[]>(["", "", "", "", "", ""]);
  const [error, setError] = useState("");
  const [busy, setBusy] = useState(false);
  const [cooldown, setCooldown] = useState(RESEND_SECONDS);
  const inputs = useRef<Array<HTMLInputElement | null>>([]);

  useEffect(() => {
    inputs.current[0]?.focus();
  }, []);

  useEffect(() => {
    if (cooldown <= 0) return;
    const id = setInterval(() => setCooldown((c) => c - 1), 1000);
    return () => clearInterval(id);
  }, [cooldown]);

  const code = digits.join("");

  function setDigit(i: number, v: string) {
    const clean = v.replace(/[^0-9]/g, "");
    setError("");
    setDigits((prev) => {
      const next = [...prev];
      next[i] = clean.slice(-1);
      return next;
    });
    if (clean && i < 5) inputs.current[i + 1]?.focus();
  }

  function onKeyDown(i: number, e: React.KeyboardEvent<HTMLInputElement>) {
    if (e.key === "Backspace" && !digits[i] && i > 0) {
      inputs.current[i - 1]?.focus();
    }
  }

  function onPaste(e: React.ClipboardEvent) {
    const text = e.clipboardData.getData("text").replace(/[^0-9]/g, "").slice(0, 6);
    if (!text) return;
    e.preventDefault();
    const next = ["", "", "", "", "", ""];
    for (let i = 0; i < text.length; i++) next[i] = text[i];
    setDigits(next);
    inputs.current[Math.min(text.length, 5)]?.focus();
  }

  async function verify() {
    if (code.length !== 6 || busy) return;
    setBusy(true);
    try {
      const v = await verifySession(challengeId, code);
      await onVerified(v.session_token);
    } catch (e) {
      const locked = e instanceof ApiError && e.status === 429;
      setError(locked ? t.o_locked : t.o_err);
      setDigits(["", "", "", "", "", ""]);
      inputs.current[0]?.focus();
    } finally {
      setBusy(false);
    }
  }

  async function resend() {
    if (cooldown > 0) return;
    try {
      const s = await resendSession(token);
      onChallenge(s.challenge_id);
      setCooldown(RESEND_SECONDS);
      setDigits(["", "", "", "", "", ""]);
      setError("");
      inputs.current[0]?.focus();
    } catch {
      /* leave the current challenge in place */
    }
  }

  return (
    <div className="screen">
      <h1>{t.o_title}</h1>
      <p className="lede">
        {t.o_lede_a} <b>{maskedPhone}</b>. {t.o_lede_b}
      </p>
      <div className={`otp${error ? " err" : ""}`} onPaste={onPaste}>
        {digits.map((d, i) => (
          <input
            key={i}
            ref={(el) => {
              inputs.current[i] = el;
            }}
            inputMode="numeric"
            maxLength={1}
            aria-label={`Digit ${i + 1}`}
            value={d}
            onChange={(e) => setDigit(i, e.target.value)}
            onKeyDown={(e) => onKeyDown(i, e)}
          />
        ))}
      </div>
      <div className="err-msg">{error}</div>
      <button
        className="btn btn-primary"
        disabled={code.length !== 6 || busy}
        onClick={verify}
      >
        {busy ? t.o_sending : t.o_verify}
      </button>
      <div className="resend">
        {t.o_resend}{" "}
        <button disabled={cooldown > 0} onClick={resend}>
          {cooldown > 0 ? `${t.o_wait} ${cooldown}s` : t.o_resend_btn}
        </button>
      </div>
    </div>
  );
}

// ------------------------------------------------------------------
// Results
// ------------------------------------------------------------------

function statusOf(item: ResultItem): "normal" | "attention" | "withheld" {
  if (item.withheld) return "withheld";
  if (item.is_critical) return "attention";
  const f = (item.flag || "normal").toLowerCase();
  if (f === "normal" || f === "negative") return "normal";
  return "attention";
}

function Results({
  t,
  lang,
  data,
  sessionToken,
}: {
  t: Strings;
  lang: Lang;
  data: ResultPayload;
  sessionToken: string | null;
}) {
  const [downloading, setDownloading] = useState(false);

  const anyAttention = data.results.some(
    (r) => statusOf(r) === "attention" || statusOf(r) === "withheld"
  );

  async function onDownload() {
    if (!sessionToken || downloading) return;
    setDownloading(true);
    try {
      await downloadPdf(sessionToken);
    } catch {
      /* swallow -- button returns to idle */
    } finally {
      setDownloading(false);
    }
  }

  return (
    <div className="screen">
      <div className="rhead">
        <div className="rname">{data.patient.name}</div>
        <div className="rmeta">
          {t.accession} <span className="mono">{data.accession_no || "\u2014"}</span>
          <br />
          {t.released} {fmtDate(data.released_at, lang)}
          {data.ordered_by ? ` \u00B7 ${t.orderedBy} ${data.ordered_by}` : ""}
        </div>
      </div>

      <div className={`summary ${anyAttention ? "attention" : "normal"}`}>
        <span className="ic">{anyAttention ? "\u26A0\uFE0F" : "\u2713"}</span>
        <span>{data.summary}</span>
      </div>

      {data.results.map((r, i) => {
        const s = statusOf(r);
        const showValue = r.value || s === "normal";
        return (
          <div key={i} className={`card ${s}`}>
            <div className="top">
              <span className="tname">{r.name}</span>
              <span className={`status ${s}`}>
                <span className="dot" />
                {t.r_status[s]}
              </span>
            </div>
            {r.measures && <div className="measures">{r.measures}</div>}
            {showValue && (
              <div className="value">
                <span className="num">{r.value || t.r_normal}</span>
                {r.unit && <span className="unit">{r.unit}</span>}
                <span className="lbl">{t.r_result}</span>
              </div>
            )}
            <div className="meaning">{r.meaning}</div>
          </div>
        );
      })}

      {data.pdf_available ? (
        <div className="pdf">
          <div className="row">
            <div className="picon">PDF</div>
            <div>
              <div className="pt">{t.pdf_t}</div>
              <div className="ps">{t.pdf_s}</div>
            </div>
          </div>
          <button
            className="btn btn-primary mini"
            disabled={downloading}
            onClick={onDownload}
          >
            {downloading ? t.pdf_downloading : `\u2193 ${t.pdf_btn}`}
          </button>
        </div>
      ) : (
        <div className="pdf blocked">
          <div className="row">
            <div className="picon">PDF</div>
            <div>
              <div className="pt">{t.pdf_block_t}</div>
              <div className="ps">{t.pdf_block_s}</div>
            </div>
          </div>
        </div>
      )}

      <div className="disclaimer">{data.disclaimer}</div>
      <div className="footer-note">{t.foot}</div>
    </div>
  );
}

// ------------------------------------------------------------------
// Error screen
// ------------------------------------------------------------------

function ErrorScreen({
  icon,
  title,
  sub,
  action,
}: {
  icon: string;
  title: string;
  sub: string;
  action?: { label: string; onClick: () => void };
}) {
  return (
    <div className="screen center-screen">
      <div className="big">{icon}</div>
      <h1>{title}</h1>
      <p className="lede" style={{ marginTop: 12 }}>
        {sub}
      </p>
      {action && (
        <>
          <div className="spacer" />
          <button className="btn btn-ghost" onClick={action.onClick}>
            {action.label}
          </button>
        </>
      )}
    </div>
  );
}
