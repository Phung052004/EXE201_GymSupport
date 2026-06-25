import { LogOut, Menu } from 'lucide-react'
import { useNavigate } from 'react-router-dom'
import { getCurrentUser, logout } from '../../services/authService.js'

export default function Header({ title, onMenuClick }) {
  const navigate = useNavigate()
  const user = getCurrentUser()
  const displayName = user?.fullName || user?.email || 'Admin'
  const initial = (displayName[0] || 'A').toUpperCase()
  const roleLabel = user?.role || 'Admin'

  const handleLogout = () => {
    logout()
    navigate('/login', { replace: true })
  }

  return (
    <header className="sticky top-0 z-20 border-b border-slate-200 bg-white/90 backdrop-blur-xl">
      <div className="flex h-16 items-center gap-3 px-4 sm:px-6">
        <button
          className="grid h-9 w-9 shrink-0 place-items-center rounded-lg border border-slate-200 bg-white text-slate-600 transition hover:bg-slate-50 lg:hidden"
          onClick={onMenuClick}
        >
          <Menu size={18} />
        </button>

        <div className="min-w-0 flex-1">
          <h1 className="truncate text-lg font-black text-slate-900">{title}</h1>
        </div>

        <div className="flex items-center gap-2">
          <div className="flex items-center gap-2.5 rounded-xl border border-slate-200 bg-white px-3 py-1.5 shadow-sm">
            <div className="flex h-7 w-7 shrink-0 items-center justify-center rounded-lg bg-gradient-to-br from-cyan-500 to-blue-600 text-xs font-black text-white shadow shadow-cyan-500/20">
              {initial}
            </div>
            <div className="hidden text-right sm:block">
              <p className="text-xs font-bold text-slate-900 leading-tight">{displayName}</p>
              <p className="text-[10px] font-medium text-slate-400 leading-tight">{roleLabel}</p>
            </div>
          </div>

          <button
            className="grid h-9 w-9 place-items-center rounded-lg border border-slate-200 bg-white text-slate-500 transition hover:border-rose-200 hover:bg-rose-50 hover:text-rose-600"
            onClick={handleLogout}
            title="Đăng xuất"
          >
            <LogOut size={16} />
          </button>
        </div>
      </div>
    </header>
  )
}
