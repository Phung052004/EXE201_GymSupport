import { useEffect, useState } from 'react'
import {
  Area,
  AreaChart,
  CartesianGrid,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis,
} from 'recharts'
import { Activity, TrendingUp, Users } from 'lucide-react'
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

const CustomTooltip = ({ active, payload, label }) => {
  if (!active || !payload?.length) return null
  return (
    <div className="rounded-xl border border-slate-200 bg-white px-4 py-3 shadow-xl">
      <p className="mb-1 text-xs font-bold text-slate-500">{label}</p>
      <p className="text-sm font-black text-cyan-600">{payload[0]?.value ?? 0} users</p>
    </div>
  )
}

export default function ActiveUsersPage() {
  const [range, setRange] = useState(defaultRange)
  const [data, setData] = useState(null)
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState(null)

  const load = async (r) => {
    setLoading(true)
    setError(null)
    try {
      const result = await adminApi.getActiveUsers(r.from, r.to)
      setData(result)
    } catch {
      setError('Không thể tải dữ liệu. Vui lòng thử lại.')
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => { load(range) }, [])

  const chartData = (data?.dailyBreakdown ?? []).map((d) => ({
    date: d.date?.slice(5),
    users: d.activeUsers,
  }))

  return (
    <div className="space-y-6 animate-fade-in">
      {/* Header */}
      <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <h2 className="text-xl font-black text-slate-900">Active Users</h2>
          <p className="mt-0.5 text-sm text-slate-500">
            DAU · WAU · MAU — đo qua số lần bắt đầu buổi tập
          </p>
        </div>
        <DateRangePicker
          from={range.from}
          to={range.to}
          onChange={setRange}
          onApply={load}
        />
      </div>

      {error && (
        <div className="rounded-xl border border-rose-200 bg-rose-50 px-4 py-3 text-sm font-medium text-rose-700">
          {error}
        </div>
      )}

      {/* Stat Cards */}
      <div className="grid gap-4 sm:grid-cols-3">
        <StatCard
          icon={TrendingUp}
          label="Daily Active Users (DAU)"
          value={loading ? '—' : (data?.dau ?? 0)}
          helper="Trung bình user/ngày"
          color="cyan"
        />
        <StatCard
          icon={Activity}
          label="Weekly Active Users (WAU)"
          value={loading ? '—' : (data?.wau ?? 0)}
          helper="Trung bình user/tuần"
          color="blue"
        />
        <StatCard
          icon={Users}
          label="Monthly Active Users (MAU)"
          value={loading ? '—' : (data?.mau ?? 0)}
          helper={`${data?.from ?? ''} → ${data?.to ?? ''}`}
          color="violet"
        />
      </div>

      {/* Chart */}
      <div className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
        <h3 className="section-title">Daily Active Users</h3>
        <p className="section-subtitle">Số user hoạt động mỗi ngày trong khoảng thời gian đã chọn</p>

        {loading ? (
          <div className="mt-6 flex h-72 items-center justify-center text-sm font-medium text-slate-400">
            Đang tải...
          </div>
        ) : chartData.length === 0 ? (
          <div className="mt-6 flex h-72 items-center justify-center text-sm font-medium text-slate-400">
            Không có dữ liệu trong khoảng thời gian này
          </div>
        ) : (
          <div className="mt-6 h-72">
            <ResponsiveContainer width="100%" height="100%">
              <AreaChart data={chartData} margin={{ top: 4, right: 4, bottom: 0, left: 0 }}>
                <defs>
                  <linearGradient id="colorUsers" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="5%" stopColor="#06B6D4" stopOpacity={0.18} />
                    <stop offset="95%" stopColor="#06B6D4" stopOpacity={0} />
                  </linearGradient>
                </defs>
                <CartesianGrid strokeDasharray="3 3" stroke="#f1f5f9" />
                <XAxis
                  dataKey="date"
                  tick={{ fill: '#94a3b8', fontSize: 11 }}
                  tickLine={false}
                  axisLine={false}
                />
                <YAxis
                  tick={{ fill: '#94a3b8', fontSize: 11 }}
                  tickLine={false}
                  axisLine={false}
                  allowDecimals={false}
                />
                <Tooltip content={<CustomTooltip />} />
                <Area
                  type="monotone"
                  dataKey="users"
                  stroke="#06B6D4"
                  strokeWidth={2.5}
                  fill="url(#colorUsers)"
                  dot={false}
                  activeDot={{ r: 5, strokeWidth: 2, stroke: '#fff' }}
                />
              </AreaChart>
            </ResponsiveContainer>
          </div>
        )}
      </div>

      {/* Daily Breakdown Table */}
      {!loading && chartData.length > 0 && (
        <div className="rounded-2xl border border-slate-200 bg-white shadow-sm">
          <div className="border-b border-slate-100 px-6 py-4">
            <h3 className="section-title">Chi tiết theo ngày</h3>
          </div>
          <div className="max-h-80 overflow-y-auto">
            <table className="w-full text-sm">
              <thead className="sticky top-0 bg-slate-50">
                <tr>
                  <th className="px-6 py-3 text-left text-xs font-bold uppercase tracking-wide text-slate-500">
                    Ngày
                  </th>
                  <th className="px-6 py-3 text-right text-xs font-bold uppercase tracking-wide text-slate-500">
                    Active Users
                  </th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100">
                {(data?.dailyBreakdown ?? []).map((row) => (
                  <tr key={row.date} className="hover:bg-slate-50">
                    <td className="px-6 py-3 font-medium text-slate-700">{row.date}</td>
                    <td className="px-6 py-3 text-right">
                      <span className="font-bold text-cyan-700">{row.activeUsers}</span>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      )}
    </div>
  )
}
