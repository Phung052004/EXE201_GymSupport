import { useEffect, useState } from 'react'
import { Bar, BarChart, CartesianGrid, Cell, ResponsiveContainer, Tooltip, XAxis, YAxis } from 'recharts'
import { Target, Users } from 'lucide-react'
import DateRangePicker from '../../../components/common/DateRangePicker.jsx'
import StatCard from '../../../components/common/StatCard.jsx'
import { adminApi } from '../../../services/adminApi.js'

const toISO = (date) => date.toISOString().slice(0, 10)

const defaultRange = () => {
  const to = new Date()
  const from = new Date()
  from.setDate(from.getDate() - 29)
  return { from: toISO(from), to: toISO(to) }
}

const RetentionBar = ({ label, rate, retained, eligible, color }) => (
  <div className="rounded-2xl border border-slate-200 bg-white p-6">
    <div className="flex items-center justify-between">
      <p className="text-sm font-bold text-slate-500">{label}</p>
      <span
        className="rounded-full px-3 py-1 text-xs font-black"
        style={{ backgroundColor: `${color}18`, color }}
      >
        {rate}%
      </span>
    </div>
    <p className="mt-3 text-3xl font-black tabular-nums" style={{ color }}>
      {rate}%
    </p>
    <div className="mt-3 h-2 w-full overflow-hidden rounded-full bg-slate-100">
      <div
        className="h-full rounded-full transition-all duration-700"
        style={{ width: `${Math.min(rate, 100)}%`, backgroundColor: color }}
      />
    </div>
    <p className="mt-2 text-xs font-medium text-slate-400">
      {retained} / {eligible} users
    </p>
  </div>
)

const CustomTooltip = ({ active, payload, label }) => {
  if (!active || !payload?.length) return null
  return (
    <div className="rounded-xl border border-slate-200 bg-white px-4 py-3 shadow-xl">
      <p className="mb-1 text-xs font-bold text-slate-500">{label}</p>
      <p className="text-sm font-black text-indigo-600">{payload[0]?.value ?? 0}%</p>
    </div>
  )
}

export default function RetentionPage() {
  const [range, setRange] = useState(defaultRange)
  const [data, setData] = useState(null)
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState(null)

  const load = async (r) => {
    setLoading(true)
    setError(null)
    try {
      const result = await adminApi.getRetention(r.from, r.to)
      setData(result)
    } catch {
      setError('Không thể tải dữ liệu. Vui lòng thử lại.')
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => { load(range) }, [])

  const chartData = [
    { name: 'Day 1', rate: data?.day1Retention ?? 0, color: '#10b981' },
    { name: 'Day 7', rate: data?.day7Retention ?? 0, color: '#6366f1' },
    { name: 'Day 30', rate: data?.day30Retention ?? 0, color: '#f59e0b' },
  ]

  return (
    <div className="space-y-6 animate-fade-in">
      {/* Header */}
      <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <h2 className="text-xl font-black text-slate-900">Retention Analytics</h2>
          <p className="mt-0.5 text-sm text-slate-500">
            Tỉ lệ user quay lại sau khi đăng ký — cohort theo ngày xác thực email
          </p>
        </div>
        <DateRangePicker from={range.from} to={range.to} onChange={setRange} onApply={load} />
      </div>

      {error && (
        <div className="rounded-xl border border-rose-200 bg-rose-50 px-4 py-3 text-sm font-medium text-rose-700">
          {error}
        </div>
      )}

      {/* Cohort size */}
      <div className="grid gap-4 sm:grid-cols-2">
        <StatCard
          icon={Users}
          label="Cohort Size"
          value={loading ? '—' : (data?.cohortSize ?? 0)}
          helper={`Đăng ký trong ${data?.from ?? ''} → ${data?.to ?? ''}`}
          color="indigo"
        />
        <StatCard
          icon={Target}
          label="Day 1 Retained"
          value={loading ? '—' : `${data?.day1Retention ?? 0}%`}
          helper={`${data?.day1RetainedUsers ?? 0} / ${data?.cohortSize ?? 0} users`}
          color="emerald"
        />
      </div>

      {/* Retention bars */}
      <div className="grid gap-4 sm:grid-cols-3">
        <RetentionBar
          label="Day 1 Retention"
          rate={loading ? 0 : (data?.day1Retention ?? 0)}
          retained={data?.day1RetainedUsers ?? 0}
          eligible={data?.cohortSize ?? 0}
          color="#10b981"
        />
        <RetentionBar
          label="Day 7 Retention"
          rate={loading ? 0 : (data?.day7Retention ?? 0)}
          retained={data?.day7RetainedUsers ?? 0}
          eligible={data?.day7EligibleUsers ?? 0}
          color="#6366f1"
        />
        <RetentionBar
          label="Day 30 Retention"
          rate={loading ? 0 : (data?.day30Retention ?? 0)}
          retained={data?.day30RetainedUsers ?? 0}
          eligible={data?.day30EligibleUsers ?? 0}
          color="#f59e0b"
        />
      </div>

      {/* Chart */}
      <div className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
        <h3 className="section-title">So sánh tỉ lệ Retention</h3>
        <p className="section-subtitle">Day 1 / Day 7 / Day 30 — cohort đăng ký trong khoảng đã chọn</p>
        <div className="mt-6 h-64">
          <ResponsiveContainer width="100%" height="100%">
            <BarChart data={chartData} margin={{ top: 4, right: 4, bottom: 0, left: 0 }}>
              <CartesianGrid strokeDasharray="3 3" stroke="#f1f5f9" />
              <XAxis dataKey="name" tick={{ fill: '#94a3b8', fontSize: 12 }} tickLine={false} axisLine={false} />
              <YAxis
                domain={[0, 100]}
                tick={{ fill: '#94a3b8', fontSize: 12 }}
                tickLine={false}
                axisLine={false}
                tickFormatter={(v) => `${v}%`}
              />
              <Tooltip content={<CustomTooltip />} />
              <Bar dataKey="rate" radius={[8, 8, 0, 0]} maxBarSize={80}>
                {chartData.map((entry) => (
                  <Cell key={entry.name} fill={entry.color} />
                ))}
              </Bar>
            </BarChart>
          </ResponsiveContainer>
        </div>
      </div>

      {/* Info box */}
      <div className="rounded-2xl border border-blue-100 bg-blue-50 p-5">
        <h4 className="text-sm font-bold text-blue-800">Cách tính Retention</h4>
        <ul className="mt-2 space-y-1 text-xs text-blue-700">
          <li>• <strong>Day 1</strong>: User có buổi tập trong cửa sổ ngày 1–2 sau đăng ký</li>
          <li>• <strong>Day 7</strong>: User có buổi tập trong cửa sổ ngày 6–9 (chỉ tính user đăng ký ≥7 ngày trước)</li>
          <li>• <strong>Day 30</strong>: User có buổi tập trong cửa sổ ngày 28–33 (chỉ tính user đăng ký ≥30 ngày trước)</li>
          <li>• <strong>Eligible</strong>: Số user đủ thời gian để được tính vào tỉ lệ</li>
        </ul>
      </div>
    </div>
  )
}
