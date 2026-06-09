import {
  Activity,
  Bot,
  Dumbbell,
  FileText,
  Home,
  MessageSquareWarning,
  ScanFace,
  Users,
  X,
} from 'lucide-react'
import { NavLink } from 'react-router-dom'

const items = [
  { label: 'Dashboard', path: '/admin', icon: Home },
  { label: 'Users', path: '/admin/users', icon: Users },
  { label: 'Exercises', path: '/admin/exercises', icon: Dumbbell },
  { label: 'Muscle Groups', path: '/admin/muscle-groups', icon: Activity },
  { label: 'Workout Templates', path: '/admin/workout-templates', icon: FileText },
  { label: 'AI Recommendations', path: '/admin/ai-recommendations', icon: Bot },
  { label: 'Body Checks', path: '/admin/body-checks', icon: ScanFace },
  { label: 'Feedbacks', path: '/admin/feedbacks', icon: MessageSquareWarning },
]

export default function Sidebar({ open, onClose }) {
  return (
    <>
      <div className={`fixed inset-0 z-30 bg-slate-950/40 lg:hidden ${open ? 'block' : 'hidden'}`} onClick={onClose} />
      <aside className={`fixed inset-y-0 left-0 z-40 w-72 transform border-r border-slate-200 bg-white transition lg:static lg:translate-x-0 ${open ? 'translate-x-0' : '-translate-x-full'}`}>
        <div className="flex h-16 items-center justify-between border-b border-slate-200 px-5">
          <div>
            <p className="text-xl font-black text-slate-950">Gym AI Admin</p>
            <p className="text-xs font-semibold text-emerald-600">Operations Console</p>
          </div>
          <button className="grid h-9 w-9 place-items-center rounded-md hover:bg-slate-100 lg:hidden" onClick={onClose}>
            <X size={18} />
          </button>
        </div>

        <nav className="space-y-1 px-3 py-4">
          {items.map((item) => (
            <NavLink
              key={item.path}
              to={item.path}
              end={item.path === '/admin'}
              onClick={onClose}
              className={({ isActive }) =>
                `flex items-center gap-3 rounded-md px-3 py-2.5 text-sm font-bold transition ${
                  isActive
                    ? 'bg-emerald-50 text-emerald-700'
                    : 'text-slate-600 hover:bg-slate-50 hover:text-slate-950'
                }`
              }
            >
              <item.icon size={18} />
              {item.label}
            </NavLink>
          ))}
        </nav>
      </aside>
    </>
  )
}
