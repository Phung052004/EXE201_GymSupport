import { useState } from 'react'
import { Link, useNavigate } from 'react-router-dom'
import { Dumbbell, Sparkles } from 'lucide-react'
import { useAuth } from '../../context/AuthContext.jsx'
import UpgradeModal from '../UpgradeModal.jsx'

export default function Header() {
  const { user, isPremium, loading, logout } = useAuth()
  const [showUpgrade, setShowUpgrade] = useState(false)
  const navigate = useNavigate()

  return (
    <>
      <header className="sticky top-0 z-40 border-b border-brand-outline bg-brand-background/90 backdrop-blur">
        <div className="mx-auto flex max-w-6xl items-center justify-between px-6 py-4">
          <Link to="/" className="flex items-center gap-2 text-lg font-black tracking-tight">
            <Dumbbell className="h-6 w-6 text-brand-primary" />
            <span className="text-brand-textPrimary">Gym</span>
            <span className="text-brand-primary">Support</span>
          </Link>

          <div className="flex items-center gap-3">
            {loading ? null : user ? (
              <>
                {!isPremium && (
                  <button
                    onClick={() => setShowUpgrade(true)}
                    className="btn-accent"
                  >
                    <Sparkles className="h-4 w-4" />
                    Nâng cấp
                  </button>
                )}
                <span className="text-sm font-semibold text-brand-textPrimary">
                  {user.fullName || user.email}
                </span>
                <button onClick={logout} className="text-sm text-brand-textSecondary hover:text-brand-textPrimary">
                  Đăng xuất
                </button>
              </>
            ) : (
              <>
                <button onClick={() => navigate('/login')} className="btn-outline">
                  Đăng nhập
                </button>
                <button onClick={() => navigate('/register')} className="btn-primary">
                  Đăng ký
                </button>
              </>
            )}
          </div>
        </div>
      </header>

      <UpgradeModal open={showUpgrade} onClose={() => setShowUpgrade(false)} />
    </>
  )
}
