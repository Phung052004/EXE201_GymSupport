import apiClient from './apiClient.js'

const LOGIN_PATHS = new Set([
  import.meta.env.VITE_AUTH_LOGIN_PATH || '/api/auth/login',
  '/api/Auth/login',
])

function getPayload(response) {
  return response?.data ?? response
}

function extractToken(payload) {
  return (
    payload?.token ||
    payload?.accessToken ||
    payload?.jwtToken ||
    payload?.data?.token ||
    payload?.data?.accessToken ||
    payload?.data?.jwtToken ||
    null
  )
}

function extractUser(payload) {
  const maybeUser = payload?.user || payload?.data?.user
  if (maybeUser && typeof maybeUser === 'object') {
    return maybeUser
  }

  if (payload?.role) {
    return payload
  }

  return null
}

export async function login(email, password) {
  if (!email || !password) {
    throw new Error('Email and password are required.')
  }

  let lastError
  for (const path of LOGIN_PATHS) {
    try {
      const response = await apiClient.post(path, { email, password })
      const payload = getPayload(response)
      const token = extractToken(payload)

      if (!token) {
        throw new Error('Login response did not contain a valid JWT token.')
      }

      localStorage.setItem('token', token)

      const user = extractUser(payload)
      if (user) {
        localStorage.setItem('user', JSON.stringify(user))
      }

      return { token, user }
    } catch (error) {
      if (error.response?.status === 404) {
        lastError = error
        continue
      }
      throw error
    }
  }

  throw lastError || new Error('Login request failed.')
}

export function logout() {
  localStorage.removeItem('token')
  localStorage.removeItem('user')
}

export function getCurrentUser() {
  const raw = localStorage.getItem('user')
  if (!raw) return null

  try {
    return JSON.parse(raw)
  } catch {
    return null
  }
}

export function isAuthenticated() {
  return Boolean(localStorage.getItem('token'))
}

export function isAdmin() {
  const user = getCurrentUser()
  if (!user) return true

  const role = user.role == null ? '' : String(user.role).trim().toLowerCase()
  return role === 'admin' || role === 'administrator' || role.includes('admin')
}
