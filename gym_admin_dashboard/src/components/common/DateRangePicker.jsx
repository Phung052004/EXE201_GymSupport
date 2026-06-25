const PRESETS = [
  { label: '7 ngày', days: 7 },
  { label: '30 ngày', days: 30 },
  { label: '90 ngày', days: 90 },
]

const toISO = (date) => date.toISOString().slice(0, 10)

export default function DateRangePicker({ from, to, onChange, onApply }) {
  const applyPreset = (days) => {
    const now = new Date()
    const start = new Date()
    start.setDate(start.getDate() - days)
    const next = { from: toISO(start), to: toISO(now) }
    onChange(next)
    onApply?.(next)
  }

  return (
    <div className="flex flex-wrap items-center gap-2">
      {PRESETS.map((p) => (
        <button
          key={p.label}
          className="btn-secondary py-1.5 text-xs"
          onClick={() => applyPreset(p.days)}
        >
          {p.label}
        </button>
      ))}
      <div className="flex items-center gap-1.5">
        <input
          type="date"
          value={from}
          className="date-input"
          onChange={(e) => onChange({ from: e.target.value, to })}
        />
        <span className="text-slate-400">→</span>
        <input
          type="date"
          value={to}
          className="date-input"
          onChange={(e) => onChange({ from, to: e.target.value })}
        />
        {onApply && (
          <button className="btn-primary py-1.5 text-xs" onClick={() => onApply({ from, to })}>
            Áp dụng
          </button>
        )}
      </div>
    </div>
  )
}
