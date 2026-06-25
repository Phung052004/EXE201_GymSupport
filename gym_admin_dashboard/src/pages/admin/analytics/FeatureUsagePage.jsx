import { useEffect, useState } from 'react'
import {
  Bar,
  BarChart,
  CartesianGrid,
  Cell,
  Legend,
  Pie,
  PieChart,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis,
} from 'recharts'
import { BarChart2, Bot, Dumbbell, Salad, ScanFace, Sparkles, User, Zap } from 'lucide-react'
import DateRangePicker from '../../../components/common/DateRangePicker.jsx'
import { adminApi } from '../../../services/adminApi.js'

const toISO = (date) => date.toISOString().slice(0, 10)

const defaultRange = () => {
  const to = new Date()
  const from = new Date()
  from.setDate(from.getDate() - 29)
  return { from: toISO(from), to: toISO(to) }
}

const FEATURE_CONFIG = {
  Workout: { icon: Dumbbell, color: '#06b6d4' },
  'AI Coach': { icon: Bot, color: '#8b5cf6' },
  'Scan Equipment': { icon: ScanFace, color: '#f59e0b' },
  'Generate Plan': { icon: Sparkles, color: '#10b981' },
  Nutrition: { icon: Salad, color: '#f97316' },
  Subscription: { icon: Zap, color: '#3b82f6' },
  Profile: { icon: User, color: '#64748b' },
}

const CustomBarTooltip = ({ active, payload, label }) => {
  if (!active || !payload?.length) return null
  return (
    <div className="rounded-xl border border-slate-200 bg-white px-4 py-3 shadow-xl">
      <p className="mb-2 text-xs font-bold text-slate-500">{label}</p>
      {payload.map((p) => (
        <p key={p.name} className="text-sm font-black" style={{ color: p.color }}>
          {p.name}: {p.value.toLocaleString()}
        </p>
      ))}
    </div>
  )
}

const RADIAN = Math.PI / 180
const renderPieLabel = ({ cx, cy, midAngle, innerRadius, outerRadius, percent, name }) => {
  if (percent < 0.04) return null
  const radius = innerRadius + (outerRadius - innerRadius) * 0.5
  const x = cx + radius * Math.cos(-midAngle * RADIAN)
  const y = cy + radius * Math.sin(-midAngle * RADIAN)
  return (
    <text x={x} y={y} fill="white" textAnchor="middle" dominantBaseline="central" fontSize={10} fontWeight="bold">
      {(percent * 100).toFixed(0)}%
    </text>
  )
}

export default function FeatureUsagePage() {
  const [range, setRange] = useState(defaultRange)
  const [data, setData] = useState(null)
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState(null)

  const load = async (r) => {
    setLoading(true)
    setError(null)
    try {
      const result = await adminApi.getFeatureUsage(r.from, r.to)
      setData(result)
    } catch {
      setError('Không thể tải dữ liệu. Vui lòng thử lại.')
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => { load(range) }, [])

  const features = data?.features ?? []
  const barData = features.map((f) => ({
    name: f.feature,
    'Lượt dùng': f.usageCount,
    'User duy nhất': f.uniqueUsers,
    color: FEATURE_CONFIG[f.feature]?.color ?? '#94a3b8',
  }))
  const pieData = features.filter((f) => f.usageCount > 0).map((f) => ({
    name: f.feature,
    value: f.usageCount,
    color: FEATURE_CONFIG[f.feature]?.color ?? '#94a3b8',
  }))

  const totalUsage = features.reduce((s, f) => s + f.usageCount, 0)
  const totalUsers = features.reduce((s, f) => s + f.uniqueUsers, 0)
  const topFeature = features.reduce((max, f) => (f.usageCount > (max?.usageCount ?? 0) ? f : max), null)

  return (
    <div className="space-y-6 animate-fade-in">
      {/* Header */}
      <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <h2 className="text-xl font-black text-slate-900">Feature Usage</h2>
          <p className="mt-0.5 text-sm text-slate-500">
            Thống kê lượt sử dụng và số user cho từng tính năng
          </p>
        </div>
        <DateRangePicker from={range.from} to={range.to} onChange={setRange} onApply={load} />
      </div>

      {error && (
        <div className="rounded-xl border border-rose-200 bg-rose-50 px-4 py-3 text-sm font-medium text-rose-700">
          {error}
        </div>
      )}

      {/* Summary */}
      <div className="grid gap-4 sm:grid-cols-3">
        <div className="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm">
          <p className="stat-label">Tổng lượt dùng</p>
          <p className="mt-2 text-2xl font-black text-slate-900">{loading ? '—' : totalUsage.toLocaleString()}</p>
          <p className="mt-1 text-xs text-slate-400">tất cả tính năng</p>
        </div>
        <div className="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm">
          <p className="stat-label">Tổng user tham gia</p>
          <p className="mt-2 text-2xl font-black text-slate-900">{loading ? '—' : totalUsers.toLocaleString()}</p>
          <p className="mt-1 text-xs text-slate-400">không loại trùng qua tính năng</p>
        </div>
        <div className="rounded-2xl border border-cyan-100 bg-gradient-to-br from-cyan-50 to-blue-50 p-5">
          <p className="stat-label text-cyan-600">Tính năng nổi bật</p>
          <p className="mt-2 text-xl font-black text-cyan-700">{loading ? '—' : (topFeature?.feature ?? '—')}</p>
          <p className="mt-1 text-xs text-cyan-400">{topFeature?.usageCount.toLocaleString() ?? 0} lượt</p>
        </div>
      </div>

      {/* Charts */}
      <div className="grid gap-6 xl:grid-cols-2">
        {/* Bar chart */}
        <div className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
          <h3 className="section-title">Lượt dùng & User duy nhất</h3>
          <p className="section-subtitle">So sánh tổng lượt dùng và số user unique cho từng tính năng</p>
          {loading ? (
            <div className="mt-6 flex h-64 items-center justify-center text-sm text-slate-400">Đang tải...</div>
          ) : (
            <div className="mt-6 h-64">
              <ResponsiveContainer width="100%" height="100%">
                <BarChart data={barData} margin={{ top: 4, right: 4, bottom: 0, left: 0 }}>
                  <CartesianGrid strokeDasharray="3 3" stroke="#f1f5f9" />
                  <XAxis dataKey="name" tick={{ fill: '#94a3b8', fontSize: 10 }} tickLine={false} axisLine={false} />
                  <YAxis tick={{ fill: '#94a3b8', fontSize: 11 }} tickLine={false} axisLine={false} />
                  <Tooltip content={<CustomBarTooltip />} />
                  <Legend wrapperStyle={{ fontSize: 12 }} />
                  <Bar dataKey="Lượt dùng" radius={[4, 4, 0, 0]} maxBarSize={32}>
                    {barData.map((entry) => (
                      <Cell key={entry.name} fill={entry.color} />
                    ))}
                  </Bar>
                  <Bar dataKey="User duy nhất" radius={[4, 4, 0, 0]} fill="#e2e8f0" maxBarSize={32} />
                </BarChart>
              </ResponsiveContainer>
            </div>
          )}
        </div>

        {/* Pie chart */}
        <div className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
          <h3 className="section-title">Phân phối lượt dùng</h3>
          <p className="section-subtitle">Tỉ lệ phần trăm mỗi tính năng trong tổng số lượt dùng</p>
          {loading ? (
            <div className="mt-6 flex h-64 items-center justify-center text-sm text-slate-400">Đang tải...</div>
          ) : pieData.length === 0 ? (
            <div className="mt-6 flex h-64 items-center justify-center text-sm text-slate-400">
              Không có dữ liệu
            </div>
          ) : (
            <div className="mt-6 h-64">
              <ResponsiveContainer width="100%" height="100%">
                <PieChart>
                  <Pie
                    data={pieData}
                    dataKey="value"
                    nameKey="name"
                    cx="50%"
                    cy="50%"
                    outerRadius={95}
                    labelLine={false}
                    label={renderPieLabel}
                  >
                    {pieData.map((entry) => (
                      <Cell key={entry.name} fill={entry.color} />
                    ))}
                  </Pie>
                  <Tooltip formatter={(v) => [v.toLocaleString(), 'Lượt dùng']} />
                  <Legend wrapperStyle={{ fontSize: 12 }} />
                </PieChart>
              </ResponsiveContainer>
            </div>
          )}
        </div>
      </div>

      {/* Detailed table */}
      {!loading && features.length > 0 && (
        <div className="rounded-2xl border border-slate-200 bg-white shadow-sm">
          <div className="border-b border-slate-100 px-6 py-4">
            <h3 className="section-title">Chi tiết từng tính năng</h3>
          </div>
          <table className="w-full text-sm">
            <thead className="bg-slate-50">
              <tr>
                <th className="px-6 py-3 text-left text-xs font-bold uppercase tracking-wide text-slate-500">
                  Tính năng
                </th>
                <th className="px-6 py-3 text-right text-xs font-bold uppercase tracking-wide text-slate-500">
                  Lượt dùng
                </th>
                <th className="px-6 py-3 text-right text-xs font-bold uppercase tracking-wide text-slate-500">
                  User duy nhất
                </th>
                <th className="px-6 py-3 text-right text-xs font-bold uppercase tracking-wide text-slate-500">
                  % tổng
                </th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100">
              {features
                .sort((a, b) => b.usageCount - a.usageCount)
                .map((f) => {
                  const cfg = FEATURE_CONFIG[f.feature] || {}
                  const IconComp = cfg.icon
                  const pct = totalUsage > 0 ? ((f.usageCount / totalUsage) * 100).toFixed(1) : '0.0'
                  return (
                    <tr key={f.feature} className="hover:bg-slate-50">
                      <td className="px-6 py-3">
                        <div className="flex items-center gap-2.5">
                          <div
                            className="grid h-7 w-7 place-items-center rounded-lg text-white"
                            style={{ backgroundColor: cfg.color ?? '#94a3b8' }}
                          >
                            {IconComp && <IconComp size={13} />}
                          </div>
                          <span className="font-semibold text-slate-700">{f.feature}</span>
                        </div>
                      </td>
                      <td className="px-6 py-3 text-right font-bold text-slate-900">
                        {f.usageCount.toLocaleString()}
                      </td>
                      <td className="px-6 py-3 text-right font-semibold text-slate-600">
                        {f.uniqueUsers.toLocaleString()}
                      </td>
                      <td className="px-6 py-3 text-right">
                        <span
                          className="rounded-full px-2 py-0.5 text-xs font-bold"
                          style={{
                            backgroundColor: `${cfg.color ?? '#94a3b8'}18`,
                            color: cfg.color ?? '#94a3b8',
                          }}
                        >
                          {pct}%
                        </span>
                      </td>
                    </tr>
                  )
                })}
            </tbody>
          </table>
        </div>
      )}
    </div>
  )
}
