import { LogOut, Menu, Search } from 'lucide-react'

export default function Header({ title, onMenuClick }) {
  return (
    <header className="sticky top-0 z-20 border-b border-slate-200 bg-white/95 backdrop-blur">
      <div className="flex h-16 items-center gap-4 px-4 sm:px-6">
        <button className="grid h-10 w-10 place-items-center rounded-md border border-slate-200 lg:hidden" onClick={onMenuClick}>
          <Menu size={20} />
        </button>
        <div className="min-w-0 flex-1">
          <h1 className="truncate text-xl font-black text-slate-950">{title}</h1>
          <p className="hidden text-xs font-semibold text-slate-500 sm:block">Manage Gym AI data, safety reviews and operating content</p>
        </div>
        <div className="hidden w-72 items-center gap-2 rounded-md border border-slate-200 bg-slate-50 px-3 py-2 md:flex">
          <Search size={16} className="text-slate-400" />
          <span className="text-sm font-medium text-slate-400">Search admin data</span>
        </div>
        <div className="flex items-center gap-3">
          <div className="hidden text-right sm:block">
            <p className="text-sm font-black text-slate-950">Admin Nguyen</p>
            <p className="text-xs font-semibold text-slate-500">Super Admin</p>
          </div>
          <button className="btn-secondary">
            <LogOut size={16} />
            <span className="hidden sm:inline">Logout</span>
          </button>
        </div>
      </div>
    </header>
  )
}
