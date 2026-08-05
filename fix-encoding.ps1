# ClinForge portal - write pure-ASCII source files (encoding-proof).
# Run from INSIDE the portal folder (clinforge-portal-web).
$ErrorActionPreference = "Stop"
if (-not (Test-Path "package.json")) { Write-Host "Run this from the portal folder."; exit 1 }
$enc = New-Object System.Text.UTF8Encoding($false)   # UTF-8, no BOM
New-Item -ItemType Directory -Force -Path "app\demo" | Out-Null
New-Item -ItemType Directory -Force -Path "app\r\[token]" | Out-Null
New-Item -ItemType Directory -Force -Path "lib" | Out-Null

# ---- app\page.tsx ----
$c = @'
// Root of results.integrishds.com with no token in the URL.
// Patients always arrive via /r/<token> from their SMS, so this is just a
// friendly signpost rather than an error.

export default function Home() {
  return (
    <>
      <div className="bar">
        <div className="brand">
          <div className="mark">L</div>
          <div className="txt">
            <div className="name">ClinForge</div>
            <div className="tag">Patient Results</div>
          </div>
        </div>
      </div>
      <div className="scroll">
        <div className="screen center-screen">
          <div className="big" style={{ fontSize: 40, marginBottom: 14 }}>
            &#128279;
          </div>
          <h1>Open your results from your message</h1>
          <p className="lede" style={{ marginTop: 12 }}>
            Please use the secure link sent to your phone by the laboratory to
            view your results. If you can&apos;t find it, contact the lab that
            took your sample.
          </p>
        </div>
      </div>
    </>
  );
}

'@
[System.IO.File]::WriteAllText((Join-Path (Get-Location) "app\page.tsx"), $c, $enc)

# ---- app\layout.tsx ----
$c = @'
import type { Metadata, Viewport } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "Lab Results \u2014 ClinForge",
  description: "Securely view your laboratory results.",
  robots: { index: false, follow: false }, // never index patient links
};

export const viewport: Viewport = {
  width: "device-width",
  initialScale: 1,
  maximumScale: 1,
  themeColor: "#1a3a5c",
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <head>
        <link rel="preconnect" href="https://fonts.googleapis.com" />
        <link
          rel="preconnect"
          href="https://fonts.gstatic.com"
          crossOrigin="anonymous"
        />
        <link
          href="https://fonts.googleapis.com/css2?family=IBM+Plex+Sans:wght@400;500;600;700&family=IBM+Plex+Mono:wght@500;600&display=swap"
          rel="stylesheet"
        />
      </head>
      <body>
        <div className="device">{children}</div>
      </body>
    </html>
  );
}

'@
[System.IO.File]::WriteAllText((Join-Path (Get-Location) "app\layout.tsx"), $c, $enc)

# ---- app\demo\page.tsx ----
$c = @'
"use client";

// -------------------------------------------------------------------
// /demo -- a permanent, shareable walkthrough of the patient experience.
//
// Identical UI to the real /r/[token] flow, but running on mock data with
// NO backend calls and NO real OTP. Safe to open on any phone, anytime,
// and to show demo partners. It never touches patient data or the API.
//
// Fake code rule: any 6 digits ending in an EVEN number "verifies"
// (odd shows the error state, so both can be demonstrated).
// -------------------------------------------------------------------

import { useEffect, useRef, useState } from "react";
import { fmtDate, STRINGS, type Lang } from "@/lib/i18n";

const MASKED = "+233 ** *** 0001";
const LAB = "Integris Demo Lab";
const RELEASED_ISO = "2026-08-03T10:15:00Z";

type DemoStatus = "normal" | "attention" | "withheld";

interface DemoResult {
  code: string;
  status: DemoStatus;
  name: Record<Lang, string>;
  measures: Record<Lang, string> | null;
  value: string | null;
  valueFr?: string;
  unit: string | null;
  meaning: Record<Lang, string>;
}

const RESULTS: DemoResult[] = [
  {
    code: "MALA",
    status: "attention",
    name: { en: "Malaria Test", fr: "Test de paludisme" },
    measures: {
      en: "This checks whether you have malaria parasites in your blood.",
      fr: "Ce test v\u00E9rifie la pr\u00E9sence de parasites du paludisme dans votre sang.",
    },
    value: "Positive",
    valueFr: "Positif",
    unit: null,
    meaning: {
      en: "Malaria parasites were found. Malaria is treatable, but treatment should start quickly. Please go to your clinic today.",
      fr: "Des parasites du paludisme ont \u00E9t\u00E9 trouv\u00E9s. Le paludisme se soigne, mais le traitement doit commencer rapidement. Rendez-vous \u00E0 votre clinique aujourd'hui.",
    },
  },
  {
    code: "GLUC",
    status: "attention",
    name: { en: "Blood Sugar (Glucose)", fr: "Glyc\u00E9mie (Glucose)" },
    measures: {
      en: "This measures the amount of sugar in your blood.",
      fr: "Ce test mesure la quantit\u00E9 de sucre dans votre sang.",
    },
    value: "12.4",
    unit: "mmol/L",
    meaning: {
      en: "Your blood sugar is higher than usual. This can happen after eating, but it can also be a sign of diabetes. Your clinician will explain what it means for you.",
      fr: "Votre glyc\u00E9mie est plus \u00E9lev\u00E9e que la normale. Cela peut arriver apr\u00E8s un repas, mais peut aussi indiquer un diab\u00E8te. Votre m\u00E9decin vous expliquera ce que cela signifie.",
    },
  },
  {
    code: "CBC",
    status: "normal",
    name: { en: "Full Blood Count", fr: "Num\u00E9ration Formule Sanguine" },
    measures: {
      en: "This counts the different types of cells in your blood.",
      fr: "Ce test compte les diff\u00E9rents types de cellules dans votre sang.",
    },
    value: null,
    unit: null,
    meaning: {
      en: "This result is in the usual range.",
      fr: "Ce r\u00E9sultat se situe dans les valeurs habituelles.",
    },
  },
  {
    code: "HIV",
    status: "withheld",
    name: { en: "HIV Test", fr: "Test VIH" },
    measures: null,
    value: null,
    unit: null,
    meaning: {
      en: "One of your results needs to be explained by a health worker in person. Please contact the laboratory or your clinician today.",
      fr: "L'un de vos r\u00E9sultats doit vous \u00EAtre expliqu\u00E9 en personne par un professionnel de sant\u00E9. Veuillez contacter le laboratoire ou votre m\u00E9decin aujourd'hui.",
    },
  },
];

const SUMMARY: Record<Lang, { attention: string; normal: string }> = {
  en: {
    attention:
      "Some of your results need attention. Please read them below and contact your clinician.",
    normal: "All of your results are in the usual range.",
  },
  fr: {
    attention:
      "Certains r\u00E9sultats n\u00E9cessitent votre attention. Lisez-les ci-dessous et contactez votre m\u00E9decin.",
    normal: "Tous vos r\u00E9sultats se situent dans les valeurs habituelles.",
  },
};

const RESEND_SECONDS = 45;
type Step = "verify" | "otp" | "results";

export default function DemoPortal() {
  const [step, setStep] = useState<Step>("verify");
  const [lang, setLang] = useState<Lang>("en");
  const t = STRINGS[lang];

  return (
    <>
      <div className="bar">
        <div className="brand">
          <div className="mark">L</div>
          <div className="txt">
            <div className="name">ClinForge</div>
            <div className="tag">
              {LAB} &#183; {t.brandTag}
            </div>
          </div>
        </div>
        <div className="lang" role="group" aria-label="Language">
          <button aria-pressed={lang === "en"} onClick={() => setLang("en")}>
            EN
          </button>
          <button aria-pressed={lang === "fr"} onClick={() => setLang("fr")}>
            FR
          </button>
        </div>
      </div>

      <div
        style={{
          background: "#fbf1df",
          color: "#7a4c10",
          fontSize: 12,
          fontWeight: 600,
          textAlign: "center",
          padding: "6px 12px",
          letterSpacing: 0.3,
        }}
      >
        {lang === "fr"
          ? "D\u00C9MONSTRATION \u00B7 donn\u00E9es fictives"
          : "DEMONSTRATION \u00B7 sample data"}
      </div>

      <div className="scroll">
        {step === "verify" && <Verify t={t} onSend={() => setStep("otp")} />}
        {step === "otp" && (
          <Otp t={t} onVerified={() => setStep("results")} />
        )}
        {step === "results" && <Results lang={lang} t={t} />}
      </div>
    </>
  );
}

function Verify({
  t,
  onSend,
}: {
  t: (typeof STRINGS)["en"];
  onSend: () => void;
}) {
  return (
    <div className="screen center-verify">
      <div className="big" style={{ fontSize: 34, marginBottom: 6 }}>
        &#128274;
      </div>
      <h1>{t.v_title}</h1>
      <p className="lede">{t.v_lede}</p>
      <div className="phone-chip">
        <span className="k">{t.v_key}</span>{" "}
        <span className="mono">{MASKED}</span>
      </div>
      <div className="spacer" />
      <button className="btn btn-primary" onClick={onSend}>
        {t.v_btn} &#8594;
      </button>
      <p className="hint">
        {LAB}. {t.v_foot2}
      </p>
    </div>
  );
}

function Otp({
  t,
  onVerified,
}: {
  t: (typeof STRINGS)["en"];
  onVerified: () => void;
}) {
  const [digits, setDigits] = useState<string[]>(["", "", "", "", "", ""]);
  const [error, setError] = useState("");
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

  function verify() {
    if (code.length !== 6) return;
    // Demo rule: even last digit passes.
    if (parseInt(code[5], 10) % 2 === 0) {
      onVerified();
    } else {
      setError(t.o_err);
      setDigits(["", "", "", "", "", ""]);
      inputs.current[0]?.focus();
    }
  }

  return (
    <div className="screen">
      <h1>{t.o_title}</h1>
      <p className="lede">
        {t.o_lede_a} <b>{MASKED}</b>. {t.o_lede_b}
      </p>
      <div className={`otp${error ? " err" : ""}`}>
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
            onKeyDown={(e) => {
              if (e.key === "Backspace" && !digits[i] && i > 0)
                inputs.current[i - 1]?.focus();
            }}
          />
        ))}
      </div>
      <div className="err-msg">{error}</div>
      <button
        className="btn btn-primary"
        disabled={code.length !== 6}
        onClick={verify}
      >
        {t.o_verify}
      </button>
      <div className="resend">
        {t.o_resend}{" "}
        <button
          disabled={cooldown > 0}
          onClick={() => setCooldown(RESEND_SECONDS)}
        >
          {cooldown > 0 ? `${t.o_wait} ${cooldown}s` : t.o_resend_btn}
        </button>
      </div>
      <p className="hint" style={{ marginTop: 22 }}>
        {t.brandTag === "Patient Results"
          ? "Demo tip: any 6 digits ending in an even number will verify."
          : "Astuce : tout code \u00E0 6 chiffres se terminant par un chiffre pair fonctionne."}
      </p>
    </div>
  );
}

function Results({
  lang,
  t,
}: {
  lang: Lang;
  t: (typeof STRINGS)["en"];
}) {
  const anyAttention = RESULTS.some(
    (r) => r.status === "attention" || r.status === "withheld"
  );
  const hasWithheld = RESULTS.some((r) => r.status === "withheld");

  return (
    <div className="screen">
      <div className="rhead">
        <div className="rname">Kofi Mensah</div>
        <div className="rmeta">
          {t.accession} <span className="mono">IGL-2026-00001</span>
          <br />
          {t.released} {fmtDate(RELEASED_ISO, lang)} &#183; {t.orderedBy} Dr. Ama
          Owusu
        </div>
      </div>

      <div className={`summary ${anyAttention ? "attention" : "normal"}`}>
        <span className="ic">{anyAttention ? "\u26A0\uFE0F" : "\u2713"}</span>
        <span>{anyAttention ? SUMMARY[lang].attention : SUMMARY[lang].normal}</span>
      </div>

      {RESULTS.map((r, i) => {
        const showValue = r.value || r.status === "normal";
        const val = lang === "fr" && r.valueFr ? r.valueFr : r.value;
        return (
          <div key={i} className={`card ${r.status}`}>
            <div className="top">
              <span className="tname">{r.name[lang]}</span>
              <span className={`status ${r.status}`}>
                <span className="dot" />
                {t.r_status[r.status]}
              </span>
            </div>
            {r.measures && <div className="measures">{r.measures[lang]}</div>}
            {showValue && (
              <div className="value">
                <span className="num">{val || t.r_normal}</span>
                {r.unit && <span className="unit">{r.unit}</span>}
                <span className="lbl">{t.r_result}</span>
              </div>
            )}
            <div className="meaning">{r.meaning[lang]}</div>
          </div>
        );
      })}

      {hasWithheld ? (
        <div className="pdf blocked">
          <div className="row">
            <div className="picon">PDF</div>
            <div>
              <div className="pt">{t.pdf_block_t}</div>
              <div className="ps">{t.pdf_block_s}</div>
            </div>
          </div>
        </div>
      ) : (
        <div className="pdf">
          <div className="row">
            <div className="picon">PDF</div>
            <div>
              <div className="pt">{t.pdf_t}</div>
              <div className="ps">{t.pdf_s}</div>
            </div>
          </div>
          <button className="btn btn-primary mini">&#8595; {t.pdf_btn}</button>
        </div>
      )}

      <div className="disclaimer">
        {lang === "fr"
          ? "Ces r\u00E9sultats font partie de votre dossier m\u00E9dical. Ils ne remplacent pas l'avis de votre m\u00E9decin, qui les interpr\u00E9tera avec vos sympt\u00F4mes."
          : "These results are part of your medical record. They do not replace advice from your clinician, who will interpret them together with your symptoms."}
      </div>
      <div className="footer-note">{t.foot}</div>
    </div>
  );
}

'@
[System.IO.File]::WriteAllText((Join-Path (Get-Location) "app\demo\page.tsx"), $c, $enc)

# ---- app\r\[token]\page.tsx ----
$c = @'
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

'@
[System.IO.File]::WriteAllText((Join-Path (Get-Location) "app\r\[token]\page.tsx"), $c, $enc)

# ---- lib\api.ts ----
$c = @'
// lib/api.ts -- thin client for the ClinForge /portal endpoints.
// Every call maps 1:1 to a backend route so the flow is easy to trace.

const BASE = process.env.NEXT_PUBLIC_API_URL || "";
const P = `${BASE}/api/v1/portal`;

export class ApiError extends Error {
  status: number;
  constructor(status: number, message: string) {
    super(message);
    this.status = status;
  }
}

async function post<T>(path: string, body: unknown, bearer?: string): Promise<T> {
  const headers: Record<string, string> = { "Content-Type": "application/json" };
  if (bearer) headers["Authorization"] = `Bearer ${bearer}`;

  let resp: Response;
  try {
    resp = await fetch(`${P}${path}`, {
      method: "POST",
      headers,
      body: JSON.stringify(body),
    });
  } catch {
    throw new ApiError(0, "network");
  }

  if (!resp.ok) {
    let detail = "";
    try {
      const j = await resp.json();
      detail = typeof j.detail === "string" ? j.detail : "";
    } catch {
      /* ignore */
    }
    throw new ApiError(resp.status, detail);
  }
  return resp.json() as Promise<T>;
}

// ---- response shapes ----

export interface SessionInfo {
  masked_phone: string;
  locale: string;
  lab_name: string;
}

export interface SessionStart {
  challenge_id: string;
  masked_phone: string;
  locale: string;
  lab_name: string;
  expires_in_seconds: number;
}

export interface SessionVerify {
  session_token: string;
  expires_in_seconds: number;
}

export interface ResultItem {
  test_code: string;
  name: string;
  withheld: boolean;
  value?: string | null;
  unit?: string | null;
  flag?: string;
  is_critical?: boolean;
  measures?: string | null;
  meaning: string;
}

export interface ResultPayload {
  lab_name: string;
  patient: { name: string; mrn: string };
  accession_no: string | null;
  released_at: string | null;
  ordered_by: string | null;
  facility: string | null;
  locale: string;
  summary: string;
  results: ResultItem[];
  disclaimer: string;
  pdf_available: boolean;
}

// ---- calls ----

export const getSessionInfo = (token: string) =>
  post<SessionInfo>("/session/info", { token });

export const startSession = (token: string) =>
  post<SessionStart>("/session/start", { token });

export const resendSession = (token: string) =>
  post<SessionStart>("/session/resend", { token });

export const verifySession = (challenge_id: string, code: string) =>
  post<SessionVerify>("/session/verify", { challenge_id, code });

export async function getResult(sessionToken: string): Promise<ResultPayload> {
  const resp = await fetch(`${P}/result`, {
    headers: { Authorization: `Bearer ${sessionToken}` },
  });
  if (!resp.ok) throw new ApiError(resp.status, "");
  return resp.json();
}

// PDF needs the bearer header, so it can't be a plain <a href>. Fetch the
// blob and hand the browser a download.
export async function downloadPdf(sessionToken: string): Promise<void> {
  const resp = await fetch(`${P}/result/pdf`, {
    headers: { Authorization: `Bearer ${sessionToken}` },
  });
  if (!resp.ok) throw new ApiError(resp.status, "");
  const blob = await resp.blob();
  const url = URL.createObjectURL(blob);
  const a = document.createElement("a");
  a.href = url;
  a.download = "lab-report.pdf";
  document.body.appendChild(a);
  a.click();
  a.remove();
  URL.revokeObjectURL(url);
}

'@
[System.IO.File]::WriteAllText((Join-Path (Get-Location) "lib\api.ts"), $c, $enc)

# ---- lib\i18n.ts ----
$c = @'
// lib/i18n.ts -- UI chrome strings only.
// The clinical result copy (summaries, meanings) is produced by the backend
// in the patient's language, so it is NOT duplicated here.

export type Lang = "en" | "fr";

export const STRINGS = {
  en: {
    brandTag: "Patient Results",
    v_title: "Your lab results are ready",
    v_lede:
      "To keep your results private, we'll send a 6-digit code to the phone number on file.",
    v_key: "Code will be sent to",
    v_btn: "Send my code",
    v_foot2: "Not expecting this? Please contact the laboratory.",
    o_title: "Enter your code",
    o_lede_a: "We sent a 6-digit code to",
    o_lede_b: "It expires in 10 minutes.",
    o_err: "That code isn't right. Please check and try again.",
    o_locked: "Too many attempts. Please request a new code.",
    o_resend: "Didn't get it?",
    o_resend_btn: "Send again",
    o_wait: "Send again in",
    o_verify: "View my results",
    o_sending: "Checking\u2026",
    r_result: "Result",
    r_normal: "Normal",
    accession: "Accession",
    orderedBy: "Ordered by",
    released: "Released",
    r_status: {
      normal: "In usual range",
      attention: "Needs attention",
      withheld: "Given in person",
    },
    pdf_t: "Full laboratory report",
    pdf_s: "The complete signed report with all values and reference ranges.",
    pdf_btn: "Download report (PDF)",
    pdf_downloading: "Preparing\u2026",
    pdf_block_t: "Collect your full report at the laboratory",
    pdf_block_s:
      "Because one result must be explained in person, the full PDF is given at the lab, not online.",
    foot: "Secure link \u00B7 Do not share",
    err_expired_t: "This link has expired",
    err_expired_s:
      "For your safety, result links expire after 72 hours. Please contact the laboratory to receive a new one.",
    err_network_t: "Can't connect",
    err_network_s: "Please check your connection and try again.",
    retry: "Try again",
    loading: "Loading\u2026",
  },
  fr: {
    brandTag: "R\u00E9sultats du patient",
    v_title: "Vos r\u00E9sultats d'analyses sont pr\u00EAts",
    v_lede:
      "Pour prot\u00E9ger vos r\u00E9sultats, nous enverrons un code \u00E0 6 chiffres au num\u00E9ro enregistr\u00E9.",
    v_key: "Le code sera envoy\u00E9 \u00E0",
    v_btn: "Envoyer mon code",
    v_foot2: "Vous n'attendiez pas ce message ? Contactez le laboratoire.",
    o_title: "Entrez votre code",
    o_lede_a: "Nous avons envoy\u00E9 un code \u00E0 6 chiffres au",
    o_lede_b: "Il expire dans 10 minutes.",
    o_err: "Ce code est incorrect. Veuillez v\u00E9rifier et r\u00E9essayer.",
    o_locked: "Trop de tentatives. Veuillez demander un nouveau code.",
    o_resend: "Rien re\u00E7u ?",
    o_resend_btn: "Renvoyer",
    o_wait: "Renvoyer dans",
    o_verify: "Voir mes r\u00E9sultats",
    o_sending: "V\u00E9rification\u2026",
    r_result: "R\u00E9sultat",
    r_normal: "Normal",
    accession: "N\u00B0 d'accession",
    orderedBy: "Prescrit par",
    released: "Publi\u00E9 le",
    r_status: {
      normal: "Valeurs habituelles",
      attention: "\u00C0 surveiller",
      withheld: "Remis en personne",
    },
    pdf_t: "Rapport de laboratoire complet",
    pdf_s:
      "Le rapport sign\u00E9 complet avec toutes les valeurs et plages de r\u00E9f\u00E9rence.",
    pdf_btn: "T\u00E9l\u00E9charger le rapport (PDF)",
    pdf_downloading: "Pr\u00E9paration\u2026",
    pdf_block_t: "Retirez votre rapport complet au laboratoire",
    pdf_block_s:
      "Comme un r\u00E9sultat doit \u00EAtre expliqu\u00E9 en personne, le PDF complet est remis au laboratoire, non en ligne.",
    foot: "Lien s\u00E9curis\u00E9 \u00B7 Ne pas partager",
    err_expired_t: "Ce lien a expir\u00E9",
    err_expired_s:
      "Pour votre s\u00E9curit\u00E9, les liens expirent apr\u00E8s 72 heures. Contactez le laboratoire pour en recevoir un nouveau.",
    err_network_t: "Connexion impossible",
    err_network_s: "V\u00E9rifiez votre connexion et r\u00E9essayez.",
    retry: "R\u00E9essayer",
    loading: "Chargement\u2026",
  },
};

export type Strings = typeof STRINGS.en;

export function pickLang(raw?: string): Lang {
  return (raw || "en").toLowerCase().startsWith("fr") ? "fr" : "en";
}

export function fmtDate(iso: string | null, lang: Lang): string {
  if (!iso) return "\u2014";
  try {
    return new Date(iso).toLocaleDateString(lang === "fr" ? "fr-FR" : "en-GB", {
      day: "numeric",
      month: "short",
      year: "numeric",
    });
  } catch {
    return iso;
  }
}

'@
[System.IO.File]::WriteAllText((Join-Path (Get-Location) "lib\i18n.ts"), $c, $enc)

# ---- package.json ----
$c = @'
{
  "name": "clinforge-patient-portal",
  "version": "1.0.0",
  "private": true,
  "description": "Patient Result Portal for ClinForge \u2014 results.integrishds.com",
  "scripts": {
    "dev": "next dev -p 3100",
    "build": "next build",
    "start": "next start -p 3100",
    "lint": "next lint"
  },
  "dependencies": {
    "next": "14.2.5",
    "react": "^18.3.1",
    "react-dom": "^18.3.1"
  },
  "devDependencies": {
    "@types/node": "^20.14.0",
    "@types/react": "^18.3.3",
    "@types/react-dom": "^18.3.0",
    "typescript": "^5.5.3"
  }
}

'@
[System.IO.File]::WriteAllText((Join-Path (Get-Location) "package.json"), $c, $enc)

# ---- README.md ----
$c = @'
# ClinForge Patient Result Portal -- `results.integrishds.com`

A standalone Next.js 14 app, separate from the staff frontend on purpose:
patients never load the admin bundle or auth, and the app stays tiny
(~92 kB) for low-bandwidth handsets.

## Flow

```
SMS link  -->  /r/<token>
                  |  POST /portal/session/info   (masked phone, no OTP sent)
                  v
             Verify screen --tap--> POST /portal/session/start   (OTP sent)
                  v
             Code screen  --6 digits--> POST /portal/session/verify -> session JWT
                  v
             Results      --> GET /portal/result        (plain-language cards)
                          --> GET /portal/result/pdf     (if pdf_available)
```

The clinical copy (summaries, meanings) comes from the backend in the
patient's language -- `lib/i18n.ts` holds only UI chrome.

## Local dev

```bash
cp .env.local.example .env.local     # already points at the Railway API
npm install
npm run dev                          # http://localhost:3100
```

You need a real link token to exercise the flow. Trigger a notify (staff
side), read the raw token from the backend log, then open
`http://localhost:3100/r/<token>`.

## Deploy to Vercel

1. Push this folder to a repo (or a subdir Vercel points at).
2. New Vercel project -> framework **Next.js**.
3. Env var: `NEXT_PUBLIC_API_URL = https://lucid-magic-production.up.railway.app`
4. Add domain `results.integrishds.com` (GoDaddy CNAME -> Vercel, same as
   clinforge.integrishds.com).

## Backend prerequisites

- `PORTAL_SECRET_KEY` and `PORTAL_BASE_URL` set in Railway (PORTAL_BASE_URL =
  `https://results.integrishds.com`, since it builds the link in the SMS).
- `results.integrishds.com` present in the backend `CORS_ORIGINS` (already added).

## Notes

- `optimizeFonts: false` is set only so the build doesn't fetch Google Fonts
  at build time in restricted CI. Fonts still load at runtime via the `<link>`
  in `app/layout.tsx`. Safe to leave as-is.
- The PDF button is hidden automatically when the backend reports
  `pdf_available: false` (a withheld HIV or critical result), matching the
  "collect in person" rule enforced server-side.

'@
[System.IO.File]::WriteAllText((Join-Path (Get-Location) "README.md"), $c, $enc)

Write-Host "All 8 files written as clean ASCII."
Get-ChildItem -Recurse -File -Name | Sort-Object