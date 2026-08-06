import { useEffect, useState } from 'react'
import { Bar, BarChart, CartesianGrid, Cell, Legend, ResponsiveContainer, Tooltip, XAxis, YAxis } from 'recharts'
import { Crown, Dumbbell, ScanFace, Sparkles, UserCheck } from 'lucide-react'
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

const FEATURE_CONFIG = {
  EquipmentInfo: { icon: ScanFace, color: '#f59e0b' },
  BodyCheck: { icon: ScanFace, color: '#8b5cf6' },
  FormCheckVideo: { icon: Dumbbell, color: '#06b6d4' },
  GenerateWorkoutPlan: { icon: Sparkles, color: '#10b981' },
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

export default function PremiumFeatureUsagePage() {
  const [range, setRange] = useState(defaultRange)
  const [data, setData] = useState(null)
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState(null)

  const load = async (r) => {
    setLoading(true)
    setError(null)
    try {
      const result = await adminApi.getPremiumFeatureUsage(r.from, r.to)
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
    name: f.label,
    Premium: f.premiumUsageCount,
    Free: f.freeUsageCount,
    color: FEATURE_CONFIG[f.feature]?.color ?? '#94a3b8',
  }))

  const totalUsage = data?.totalUsageCount ?? 0
  const totalUsers = data?.totalUniqueUsers ?? 0
  const totalPremiumCalls = features.reduce((s, f) => s + f.premiumUsageCount, 0)
  const leakRate = totalUsage > 0 ? (((totalUsage - totalPremiumCalls) / totalUsage) * 100).toFixed(1) : '0.0'

  return (
    <div className="space-y-6 animate-fade-in">
      {/* Header */}
      <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <h2 className="text-xl font-black text-slate-900">Premium Feature Usage</h2>
          <p className="mt-0.5 text-sm text-slate-500">
            Lượt dùng tính năng AI Premium: phân tích máy tập, thể hình, form video, tạo lịch tập AI
          </p>
        </div>
        <DateRangePicker from={range.from} to={range.to} onChange={setRange} onApply={load} />
      </div>

      {error && (
        <div className="rounded-xl border border-rose-200 bg-rose-50 px-4 py-3 text-sm font-medium text-rose-700">
          {error}
        </div>
      )}

      {/* Stat Cards */}
      <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
        <StatCard
          icon={Crown}
          label="Tổng lượt dùng"
          value={loading ? '—' : totalUsage.toLocaleString()}
          helper="4 tính năng Premium"
          color="violet"
        />
        <StatCard
          icon={UserCheck}
          label="User duy nhất"
          value={loading ? '—' : totalUsers.toLocaleString()}
          helper="không loại trùng qua tính năng"
          color="cyan"
        />
        <StatCard
          icon={Sparkles}
          label="Lượt dùng bởi Premium"
          value={loading ? '—' : totalPremiumCalls.toLocaleString()}
          helper="user đang có gói Premium"
          color="emerald"
        />
        <StatCard
          icon={ScanFace}
          label="Tỉ lệ gọi khi chưa Premium"
          value={loading ? '—' : `${leakRate}%`}
          helper="đáng chú ý nếu > 0% — cần soát lại chặn quyền phía client"
          color="orange"
        />
      </div>

      {/* Chart */}
      <div className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
        <h3 className="section-title">Premium vs Free theo tính năng</h3>
        <p className="section-subtitle">Số lượt gọi tách theo trạng thái Premium của user tại thời điểm dùng</p>
        {loading ? (
          <div className="mt-6 flex h-72 items-center justify-center text-sm text-slate-400">Đang tải...</div>
        ) : features.length === 0 ? (
          <div className="mt-6 flex h-72 items-center justify-center text-sm text-slate-400">Không có dữ liệu</div>
        ) : (
          <div className="mt-6 h-72">
            <ResponsiveContainer width="100%" height="100%">
              <BarChart data={barData} margin={{ top: 4, right: 4, bottom: 0, left: 0 }}>
                <CartesianGrid strokeDasharray="3 3" stroke="#f1f5f9" />
                <XAxis dataKey="name" tick={{ fill: '#94a3b8', fontSize: 10 }} tickLine={false} axisLine={false} />
                <YAxis tick={{ fill: '#94a3b8', fontSize: 11 }} tickLine={false} axisLine={false} />
                <Tooltip content={<CustomBarTooltip />} />
                <Legend wrapperStyle={{ fontSize: 12 }} />
                <Bar dataKey="Premium" stackId="usage" fill="#8b5cf6" radius={[0, 0, 0, 0]} maxBarSize={40} />
                <Bar dataKey="Free" stackId="usage" fill="#e2e8f0" radius={[4, 4, 0, 0]} maxBarSize={40} />
              </BarChart>
            </ResponsiveContainer>
          </div>
        )}
      </div>

      {/* Detailed table */}
      {!loading && features.length > 0 && (
        <div className="rounded-2xl border border-slate-200 bg-white shadow-sm">
          <div className="border-b border-slate-100 px-6 py-4">
            <h3 className="section-title">Chi tiết từng tính năng Premium</h3>
          </div>
          <table className="w-full text-sm">
            <thead className="bg-slate-50">
              <tr>
                <th className="px-6 py-3 text-left text-xs font-bold uppercase tracking-wide text-slate-500">
                  Tính năng
                </th>
                <th className="px-6 py-3 text-right text-xs font-bold uppercase tracking-wide text-slate-500">
                  Tổng lượt dùng
                </th>
                <th className="px-6 py-3 text-right text-xs font-bold uppercase tracking-wide text-slate-500">
                  User duy nhất
                </th>
                <th className="px-6 py-3 text-right text-xs font-bold uppercase tracking-wide text-slate-500">
                  Premium
                </th>
                <th className="px-6 py-3 text-right text-xs font-bold uppercase tracking-wide text-slate-500">
                  Free
                </th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100">
              {features
                .slice()
                .sort((a, b) => b.usageCount - a.usageCount)
                .map((f) => {
                  const cfg = FEATURE_CONFIG[f.feature] || {}
                  const IconComp = cfg.icon
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
                          <span className="font-semibold text-slate-700">{f.label}</span>
                        </div>
                      </td>
                      <td className="px-6 py-3 text-right font-bold text-slate-900">
                        {f.usageCount.toLocaleString()}
                      </td>
                      <td className="px-6 py-3 text-right font-semibold text-slate-600">
                        {f.uniqueUsers.toLocaleString()}
                      </td>
                      <td className="px-6 py-3 text-right">
                        <span className="rounded-full bg-violet-50 px-2 py-0.5 text-xs font-bold text-violet-600">
                          {f.premiumUsageCount.toLocaleString()}
                        </span>
                      </td>
                      <td className="px-6 py-3 text-right">
                        <span className="rounded-full bg-slate-100 px-2 py-0.5 text-xs font-bold text-slate-500">
                          {f.freeUsageCount.toLocaleString()}
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
