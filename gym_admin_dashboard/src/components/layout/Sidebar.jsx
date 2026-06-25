import {
  Activity,
  BarChart2,
  Bot,
  ChevronRight,
  CreditCard,
  Dumbbell,
  FileText,
  Flame,
  Home,
  MessageSquareWarning,
  Receipt,
  ScanFace,
  Target,
  TrendingUp,
  Users,
  X,
  Zap,
} from 'lucide-react'
import { NavLink } from 'react-router-dom'

const navGroups = [
  {
    label: 'Main',
    items: [{ label: 'Dashboard', path: '/admin', icon: Home, end: true }],
  },
  {
    label: 'Analytics',
    items: [
      { label: 'Active Users', path: '/admin/analytics/active-users', icon: TrendingUp },
      { label: 'Retention', path: '/admin/analytics/retention', icon: Target },
      { label: 'Funnel', path: '/admin/analytics/funnel', icon: Zap },
      { label: 'Feature Usage', path: '/admin/analytics/feature-usage', icon: BarChart2 },
      { label: 'Workout Analytics', path: '/admin/analytics/workouts', icon: Flame },
    ],
  },
  {
    label: 'Content',
    items: [
      { label: 'Exercises', path: '/admin/exercises', icon: Dumbbell },
      { label: 'Muscle Groups', path: '/admin/muscle-groups', icon: Activity },
      { label: 'Workout Templates', path: '/admin/workout-templates', icon: FileText },
    ],
  },
  {
    label: 'Subscriptions',
    items: [
      { label: 'Gói dịch vụ', path: '/admin/subscriptions/plans', icon: CreditCard },
      { label: 'Đăng ký người dùng', path: '/admin/subscriptions/users', icon: Receipt },
    ],
  },
  {
    label: 'Community',
    items: [
      { label: 'Users', path: '/admin/users', icon: Users },
      { label: 'AI Recommendations', path: '/admin/ai-recommendations', icon: Bot },
      { label: 'Body Checks', path: '/admin/body-checks', icon: ScanFace },
      { label: 'Feedbacks', path: '/admin/feedbacks', icon: MessageSquareWarning },
    ],
  },
]

export default function Sidebar({ open, onClose }) {
  return (
    <>
      <div
        className={`fixed inset-0 z-30 bg-slate-950/60 backdrop-blur-sm lg:hidden ${open ? 'block' : 'hidden'}`}
        onClick={onClose}
      />
      <aside
        className={`fixed inset-y-0 left-0 z-40 flex w-64 flex-col border-r border-slate-700/50 bg-slate-900 transition-transform duration-300 lg:static lg:translate-x-0 ${
          open ? 'translate-x-0' : '-translate-x-full'
        }`}
      >
        {/* Logo */}
        <div className="flex h-16 shrink-0 items-center justify-between border-b border-slate-700/50 px-4">
          <div className="flex items-center gap-3">
            <div className="flex h-8 w-8 items-center justify-center rounded-lg bg-gradient-to-br from-cyan-400 to-cyan-600 shadow-lg shadow-cyan-500/30">
              <Dumbbell size={15} className="text-white" />
            </div>
            <div>
              <p className="text-sm font-black text-white tracking-tight">GymSupport</p>
              <p className="text-[10px] font-bold uppercase tracking-widest text-cyan-400">
                Admin Console
              </p>
            </div>
          </div>
          <button
            className="grid h-8 w-8 place-items-center rounded-lg text-slate-400 transition hover:bg-slate-800 hover:text-white lg:hidden"
            onClick={onClose}
          >
            <X size={15} />
          </button>
        </div>

        {/* Nav */}
        <nav className="flex-1 overflow-y-auto px-3 py-4">
          {navGroups.map((group) => (
            <div key={group.label} className="mb-5">
              <p className="mb-1.5 px-2 text-[10px] font-bold uppercase tracking-widest text-slate-500">
                {group.label}
              </p>
              <div className="space-y-0.5">
                {group.items.map((item) => (
                  <NavLink
                    key={item.path}
                    to={item.path}
                    end={item.end}
                    onClick={onClose}
                    className={({ isActive }) =>
                      `group flex items-center gap-3 rounded-lg px-3 py-2.5 text-[13px] font-semibold transition-all ${
                        isActive
                          ? 'border-l-2 border-cyan-400 bg-cyan-500/10 text-cyan-300 pl-[10px]'
                          : 'border-l-2 border-transparent text-slate-400 hover:bg-slate-800 hover:text-slate-200'
                      }`
                    }
                  >
                    {({ isActive }) => (
                      <>
                        <item.icon
                          size={15}
                          className={isActive ? 'text-cyan-400' : 'text-slate-500 group-hover:text-slate-300'}
                        />
                        <span className="flex-1">{item.label}</span>
                        {isActive && <ChevronRight size={12} className="text-cyan-500" />}
                      </>
                    )}
                  </NavLink>
                ))}
              </div>
            </div>
          ))}
        </nav>

        {/* Footer */}
        <div className="shrink-0 border-t border-slate-700/50 p-3">
          <div className="rounded-lg border border-cyan-500/20 bg-gradient-to-r from-cyan-500/10 to-blue-500/10 p-3">
            <p className="text-xs font-bold text-slate-300">GymSupport v1.0</p>
            <p className="mt-0.5 text-[10px] text-slate-500">Management Console</p>
          </div>
        </div>
      </aside>
    </>
  )
}
