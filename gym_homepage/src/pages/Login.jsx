import { useState } from 'react'
import { Link, useNavigate, useLocation } from 'react-router-dom'
import { useAuth } from '../context/AuthContext.jsx'

export default function Login() {
  const { login } = useAuth()
  const navigate = useNavigate()
  const location = useLocation()
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [error, setError] = useState('')
  const [submitting, setSubmitting] = useState(false)

  async function handleSubmit(e) {
    e.preventDefault()
    setError('')
    setSubmitting(true)
    try {
      await login(email, password)
      navigate(location.state?.from?.pathname || '/', { replace: true })
    } catch (err) {
      setError(err.response?.data?.message || 'Đăng nhập thất bại. Kiểm tra lại email/mật khẩu.')
    } finally {
      setSubmitting(false)
    }
  }

  return (
    <div className="mx-auto flex min-h-[70vh] max-w-md flex-col justify-center px-6 py-12">
      <h1 className="mb-6 text-2xl font-black text-brand-textPrimary">Đăng nhập</h1>

      <form onSubmit={handleSubmit} className="space-y-4">
        <div>
          <label className="mb-1 block text-sm font-semibold text-brand-textSecondary">Email</label>
          <input
            type="email"
            required
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            className="w-full rounded-lg border border-brand-outlineStrong bg-brand-surface2 px-3 py-2 text-brand-textPrimary outline-none focus:border-brand-primary"
          />
        </div>
        <div>
          <label className="mb-1 block text-sm font-semibold text-brand-textSecondary">Mật khẩu</label>
          <input
            type="password"
            required
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            className="w-full rounded-lg border border-brand-outlineStrong bg-brand-surface2 px-3 py-2 text-brand-textPrimary outline-none focus:border-brand-primary"
          />
        </div>

        {error && <p className="text-sm text-brand-danger">{error}</p>}

        <button type="submit" disabled={submitting} className="btn-primary w-full">
          {submitting ? 'Đang đăng nhập...' : 'Đăng nhập'}
        </button>
      </form>

      <p className="mt-6 text-center text-sm text-brand-textSecondary">
        Chưa có tài khoản?{' '}
        <Link to="/register" className="font-semibold text-brand-primary hover:underline">
          Đăng ký
        </Link>
      </p>
    </div>
  )
}
