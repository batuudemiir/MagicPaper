// Resend HTTP API ile gönderim (FAZ 18). Anahtar Secret Manager'da
// (RESEND_API_KEY); burada yalnızca istek kurulur.

export const RESEND_ENDPOINT = 'https://api.resend.com/emails';

export async function sendWithResend({ apiKey, from, to, subject, text, html, unsubscribe }, fetchImpl = fetch) {
  const response = await fetchImpl(RESEND_ENDPOINT, {
    method: 'POST',
    headers: { Authorization: `Bearer ${apiKey}`, 'Content-Type': 'application/json' },
    body: JSON.stringify({
      from,
      to: [to],
      subject,
      text,
      html,
      headers: {
        'List-Unsubscribe': `<${unsubscribe}>`,
        'List-Unsubscribe-Post': 'List-Unsubscribe=One-Click',
      },
    }),
  });
  if (!response.ok) {
    // Yanıt gövdesi alıcı adresini içerebilir: loga yalnızca durum kodu.
    throw new Error(`resend ${response.status}`);
  }
  return response.json();
}
