import { session } from '../store/session'

export const BASE = import.meta.env.VITE_BFF_URL || ''

// Cliente HTTP do BFF. Erros saem sempre como { status, message }.
export async function http(method, path, body, headers = {}) {
  let res
  try {
    res = await fetch(`${BASE}/api${path}`, {
      method,
      credentials: 'include',
      headers: {
        'Content-Type': 'application/json',
        ...(session.token ? { Authorization: `Bearer ${session.token}` } : {}),
        ...headers
      },
      body: body ? JSON.stringify(body) : undefined
    })
  } catch {
    throw { status: 503, message: 'Sem conexão com o servidor.' }
  }
  const data = res.status === 204 ? null : await res.json().catch(() => null)
  if (!res.ok) throw { status: res.status, message: data?.message || 'Erro inesperado.' }
  return data
}
