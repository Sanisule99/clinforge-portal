// lib/i18n.ts — UI chrome strings only.
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
    o_sending: "Checking…",
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
    pdf_downloading: "Preparing…",
    pdf_block_t: "Collect your full report at the laboratory",
    pdf_block_s:
      "Because one result must be explained in person, the full PDF is given at the lab, not online.",
    foot: "Secure link · Do not share",
    err_expired_t: "This link has expired",
    err_expired_s:
      "For your safety, result links expire after 72 hours. Please contact the laboratory to receive a new one.",
    err_network_t: "Can't connect",
    err_network_s: "Please check your connection and try again.",
    retry: "Try again",
    loading: "Loading…",
  },
  fr: {
    brandTag: "Résultats du patient",
    v_title: "Vos résultats d'analyses sont prêts",
    v_lede:
      "Pour protéger vos résultats, nous enverrons un code à 6 chiffres au numéro enregistré.",
    v_key: "Le code sera envoyé à",
    v_btn: "Envoyer mon code",
    v_foot2: "Vous n'attendiez pas ce message ? Contactez le laboratoire.",
    o_title: "Entrez votre code",
    o_lede_a: "Nous avons envoyé un code à 6 chiffres au",
    o_lede_b: "Il expire dans 10 minutes.",
    o_err: "Ce code est incorrect. Veuillez vérifier et réessayer.",
    o_locked: "Trop de tentatives. Veuillez demander un nouveau code.",
    o_resend: "Rien reçu ?",
    o_resend_btn: "Renvoyer",
    o_wait: "Renvoyer dans",
    o_verify: "Voir mes résultats",
    o_sending: "Vérification…",
    r_result: "Résultat",
    r_normal: "Normal",
    accession: "N° d'accession",
    orderedBy: "Prescrit par",
    released: "Publié le",
    r_status: {
      normal: "Valeurs habituelles",
      attention: "À surveiller",
      withheld: "Remis en personne",
    },
    pdf_t: "Rapport de laboratoire complet",
    pdf_s:
      "Le rapport signé complet avec toutes les valeurs et plages de référence.",
    pdf_btn: "Télécharger le rapport (PDF)",
    pdf_downloading: "Préparation…",
    pdf_block_t: "Retirez votre rapport complet au laboratoire",
    pdf_block_s:
      "Comme un résultat doit être expliqué en personne, le PDF complet est remis au laboratoire, non en ligne.",
    foot: "Lien sécurisé · Ne pas partager",
    err_expired_t: "Ce lien a expiré",
    err_expired_s:
      "Pour votre sécurité, les liens expirent après 72 heures. Contactez le laboratoire pour en recevoir un nouveau.",
    err_network_t: "Connexion impossible",
    err_network_s: "Vérifiez votre connexion et réessayez.",
    retry: "Réessayer",
    loading: "Chargement…",
  },
};

export type Strings = typeof STRINGS.en;

export function pickLang(raw?: string): Lang {
  return (raw || "en").toLowerCase().startsWith("fr") ? "fr" : "en";
}

export function fmtDate(iso: string | null, lang: Lang): string {
  if (!iso) return "—";
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
