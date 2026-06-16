import { useNavigate } from 'react-router-dom'
import { LogOut, Menu, Search } from 'lucide-react'
import { getCurrentUser, logout } from '../../services/authService.js'

export default function Header({ title, onMenuClick }) {
  const navigate = useNavigate()
  const user = getCurrentUser()
  const displayName = user?.fullName || user?.email || 'Admin Nguyen'
  const roleLabel = user?.role || 'Super Admin'

  const handleLogout = () => {
    logout()
    navigate('/login', { replace: true })
  }

  return (
    <header className="sticky top-0 z-20 border-b border-cyan-100 bg-white/85 backdrop-blur-xl">
      <div className="flex h-16 items-center gap-4 px-4 sm:px-6">
        <button className="grid h-10 w-10 place-items-center rounded-md border border-cyan-100 bg-white lg:hidden" onClick={onMenuClick}>
          <Menu size={20} />
        </button>
        <div className="min-w-0 flex-1">
          <h1 className="truncate text-xl font-black text-slate-950">{title}</h1>
          <p className="hidden text-xs font-semibold text-slate-500 sm:block">Manage Gym AI data, safety reviews and operating content</p>
        </div>
        <div className="hidden w-72 items-center gap-2 rounded-md border border-cyan-100 bg-cyan-50/70 px-3 py-2 md:flex">
          <Search size={16} className="text-gym-600" />
          <span className="text-sm font-medium text-slate-500">Search admin data</span>
        </div>
        <div className="flex items-center gap-3">
          <div className="hidden text-right sm:block">
            <p className="text-sm font-black text-slate-950">{displayName}</p>
            <p className="text-xs font-semibold text-slate-500">{roleLabel}</p>
          </div>
          <button className="btn-secondary" onClick={handleLogout}>
            <LogOut size={16} />
            <span className="hidden sm:inline">Logout</span>
          </button>
        </div>
      </div>
    </header>
  )
}
