import { useState } from 'react'
import { Link, useNavigate } from 'react-router-dom'
import { useAuth } from '../context/AuthContext.jsx'

export default function Register() {
  const { registerCustomer } = useAuth()
  const navigate = useNavigate()
  const [fullName, setFullName] = useState('')
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [error, setError] = useState('')
  const [success, setSuccess] = useState(false)
  const [submitting, setSubmitting] = useState(false)

  async function handleSubmit(e) {
    e.preventDefault()
    setError('')
    setSubmitting(true)
    try {
      await registerCustomer(fullName, email, password)
      setSuccess(true)
    } catch (err) {
      setError(err.response?.data?.message || 'Đăng ký thất bại. Vui lòng thử lại.')
    } finally {
      setSubmitting(false)
    }
  }

  if (success) {
    return (
      <div className="mx-auto flex min-h-[70vh] max-w-md flex-col items-center justify-center px-6 py-12 text-center">
        <h1 className="mb-3 text-2xl font-black text-brand-textPrimary">Đăng ký thành công</h1>
        <p className="mb-6 text-brand-textSecondary">
          Vui lòng kiểm tra email để xác thực tài khoản trước khi đăng nhập.
        </p>
        <button onClick={() => navigate('/login')} className="btn-primary">
          Đến trang đăng nhập
        </button>
      </div>
    )
  }

  return (
    <div className="mx-auto flex min-h-[70vh] max-w-md flex-col justify-center px-6 py-12">
      <h1 className="mb-6 text-2xl font-black text-brand-textPrimary">Tạo tài khoản</h1>

      <form onSubmit={handleSubmit} className="space-y-4">
        <div>
          <label className="mb-1 block text-sm font-semibold text-brand-textSecondary">Họ và tên</label>
          <input
            required
            value={fullName}
            onChange={(e) => setFullName(e.target.value)}
            className="w-full rounded-lg border border-brand-outlineStrong bg-brand-surface2 px-3 py-2 text-brand-textPrimary outline-none focus:border-brand-primary"
          />
        </div>
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
            minLength={6}
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            className="w-full rounded-lg border border-brand-outlineStrong bg-brand-surface2 px-3 py-2 text-brand-textPrimary outline-none focus:border-brand-primary"
          />
        </div>

        {error && <p className="text-sm text-brand-danger">{error}</p>}

        <button type="submit" disabled={submitting} className="btn-primary w-full">
          {submitting ? 'Đang đăng ký...' : 'Đăng ký'}
        </button>
      </form>

      <p className="mt-6 text-center text-sm text-brand-textSecondary">
        Đã có tài khoản?{' '}
        <Link to="/login" className="font-semibold text-brand-primary hover:underline">
          Đăng nhập
        </Link>
      </p>
    </div>
  )
}
