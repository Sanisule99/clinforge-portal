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
