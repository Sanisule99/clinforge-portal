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
