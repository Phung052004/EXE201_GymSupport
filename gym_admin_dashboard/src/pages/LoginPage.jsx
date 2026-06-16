import { useState } from 'react'
import { useLocation, useNavigate } from 'react-router-dom'
import { login } from '../services/authService.js'

export default function LoginPage() {
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [error, setError] = useState('')
  const [loading, setLoading] = useState(false)
  const navigate = useNavigate()
  const location = useLocation()
  const from = location.state?.from?.pathname || '/admin'

  const handleSubmit = async (event) => {
    event.preventDefault()
    setError('')

    if (!email.trim() || !password) {
      setError('Please enter both email and password.')
      return
    }

    setLoading(true)

    try {
      await login(email.trim(), password)
      navigate(from, { replace: true })
    } catch (err) {
      setError(err?.response?.data?.message || err?.message || 'Login failed. Please try again.')
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="flex min-h-screen items-center justify-center bg-[radial-gradient(circle_at_top,rgba(34,211,238,0.22),transparent_36%),linear-gradient(180deg,#f8fdff_0%,#e8f7f8_100%)] p-4">
      <div className="w-full max-w-md rounded-3xl border border-cyan-100 bg-white/95 p-8 shadow-soft backdrop-blur">
        <div className="space-y-3 text-center">
          <h1 className="text-3xl font-black text-slate-950">Admin Login</h1>
          <p className="text-sm text-slate-500">Enter your admin credentials to access the dashboard.</p>
        </div>

        {error ? (
          <div className="mt-6 rounded-2xl bg-red-50 p-4 text-sm font-semibold text-red-700">{error}</div>
        ) : null}

        <form className="mt-6 space-y-4" onSubmit={handleSubmit}>
          <label className="block text-sm font-semibold text-slate-700">
            Email
            <input
              type="email"
              value={email}
              onChange={(event) => setEmail(event.target.value)}
              required
              className="mt-2 w-full rounded-2xl border border-cyan-100 bg-cyan-50/50 px-4 py-3 text-sm outline-none transition focus:border-gym-500 focus:ring-4 focus:ring-cyan-100"
            />
          </label>

          <label className="block text-sm font-semibold text-slate-700">
            Password
            <input
              type="password"
              value={password}
              onChange={(event) => setPassword(event.target.value)}
              required
              className="mt-2 w-full rounded-2xl border border-cyan-100 bg-cyan-50/50 px-4 py-3 text-sm outline-none transition focus:border-gym-500 focus:ring-4 focus:ring-cyan-100"
            />
          </label>

          <button
            type="submit"
            disabled={loading}
            className="inline-flex w-full items-center justify-center rounded-2xl bg-gym-600 px-4 py-3 text-sm font-semibold text-white shadow-sm shadow-cyan-900/10 transition hover:bg-gym-700 disabled:cursor-not-allowed disabled:opacity-60"
          >
            {loading ? 'Signing in...' : 'Sign in'}
          </button>
        </form>
      </div>
    </div>
  )
}
