const colorMap = {
  cyan: {
    icon: 'bg-gradient-to-br from-cyan-400 to-cyan-600 shadow-cyan-500/25',
    badge: 'text-cyan-600',
  },
  blue: {
    icon: 'bg-gradient-to-br from-blue-400 to-blue-600 shadow-blue-500/25',
    badge: 'text-blue-600',
  },
  emerald: {
    icon: 'bg-gradient-to-br from-emerald-400 to-emerald-600 shadow-emerald-500/25',
    badge: 'text-emerald-600',
  },
  violet: {
    icon: 'bg-gradient-to-br from-violet-400 to-violet-600 shadow-violet-500/25',
    badge: 'text-violet-600',
  },
  orange: {
    icon: 'bg-gradient-to-br from-orange-400 to-orange-600 shadow-orange-500/25',
    badge: 'text-orange-600',
  },
  rose: {
    icon: 'bg-gradient-to-br from-rose-400 to-rose-600 shadow-rose-500/25',
    badge: 'text-rose-600',
  },
  amber: {
    icon: 'bg-gradient-to-br from-amber-400 to-amber-600 shadow-amber-500/25',
    badge: 'text-amber-600',
  },
  indigo: {
    icon: 'bg-gradient-to-br from-indigo-400 to-indigo-600 shadow-indigo-500/25',
    badge: 'text-indigo-600',
  },
}

export default function StatCard({ icon: Icon, label, value, helper, color = 'cyan' }) {
  const c = colorMap[color] || colorMap.cyan

  return (
    <div className="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm transition-all hover:shadow-md">
      <div className="flex items-start justify-between gap-4">
        <div className="min-w-0">
          <p className="text-xs font-semibold uppercase tracking-wide text-slate-400">{label}</p>
          <p className="mt-2 text-2xl font-black text-slate-900 tabular-nums">{value}</p>
          {helper && <p className={`mt-1 text-xs font-semibold ${c.badge}`}>{helper}</p>}
        </div>
        {Icon && (
          <div
            className={`grid h-11 w-11 shrink-0 place-items-center rounded-xl ${c.icon} text-white shadow-lg`}
          >
            <Icon size={20} />
          </div>
        )}
      </div>
    </div>
  )
}
