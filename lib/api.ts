// lib/api.ts — thin client for the LabFlow /portal endpoints.
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
