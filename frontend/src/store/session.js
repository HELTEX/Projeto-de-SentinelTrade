import { reactive } from 'vue'

// Token em sessionStorage so para a demonstracao.
// Na versao real, prefira cookie httpOnly emitido pelo BFF (ver docs/backend-e-bff.md).
const ler = (k) => { try { return sessionStorage.getItem(k) } catch { return null } }
const gravar = (k, v) => { try { v == null ? sessionStorage.removeItem(k) : sessionStorage.setItem(k, v) } catch {} }

export const session = reactive({
  token: ler('st_token'),
  user: JSON.parse(ler('st_user') || 'null'),
  mfaToken: null,
  email: ''
})

export function setSession(token, user) {
  session.token = token; session.user = user; session.mfaToken = null
  gravar('st_token', token); gravar('st_user', JSON.stringify(user))
}

export function clearSession() {
  session.token = null; session.user = null; session.mfaToken = null
  gravar('st_token', null); gravar('st_user', null)
}
