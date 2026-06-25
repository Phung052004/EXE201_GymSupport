import { useEffect, useState } from 'react'
import {
  Bar,
  BarChart,
  CartesianGrid,
  Cell,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis,
} from 'recharts'
import { Activity, CheckCircle, Clock, Dumbbell, Flame, Medal, Users } from 'lucide-react'
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
      <p className="mb-1 text-xs font-bold text-slate-500 truncate max-w-[160px]">{label}</p>
      <p className="text-sm font-black text-orange-600">{payload[0]?.value?.toLocaleString()}</p>
    </div>
  )
}

export default function WorkoutAnalyticsPage() {
  const [range, setRange] = useState(defaultRange)
  const [data, setData] = useState(null)
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState(null)

  const load = async (r) => {
    setLoading(true)
    setError(null)
    try {
      const result = await adminApi.getWorkoutAnalytics(r.from, r.to)
      setData(result)
    } catch {
      setError('Không thể tải dữ liệu. Vui lòng thử lại.')
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => { load(range) }, [])

  const exercises = (data?.mostPopularExercises ?? []).slice(0, 10)
  const muscles = (data?.mostTrainedMuscles ?? []).slice(0, 10)
  const users = (data?.mostConsistentUsers ?? []).slice(0, 10)

  const EXERCISE_COLORS = ['#06b6d4', '#0891b2', '#0e7490', '#155e75', '#164e63', '#1e40af', '#1d4ed8', '#2563eb', '#3b82f6', '#60a5fa']
  const MUSCLE_COLORS = ['#f97316', '#ea580c', '#dc2626', '#b91c1c', '#991b1b', '#c2410c', '#d97706', '#b45309', '#92400e', '#78350f']

  return (
    <div className="space-y-6 animate-fade-in">
      {/* Header */}
      <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <h2 className="text-xl font-black text-slate-900">Workout Analytics</h2>
          <p className="mt-0.5 text-sm text-slate-500">
            Hành vi tập luyện — bài tập phổ biến, nhóm cơ, user chăm chỉ
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
          icon={Dumbbell}
          label="Buổi tập bắt đầu"
          value={loading ? '—' : (data?.totalSessionsStarted ?? 0).toLocaleString()}
          helper="trong khoảng đã chọn"
          color="cyan"
        />
        <StatCard
          icon={CheckCircle}
          label="Buổi tập hoàn thành"
          value={loading ? '—' : (data?.totalSessionsCompleted ?? 0).toLocaleString()}
          helper="có ghi nhận EndTime"
          color="emerald"
        />
        <StatCard
          icon={Flame}
          label="Tỉ lệ hoàn thành"
          value={loading ? '—' : `${data?.completionRate ?? 0}%`}
          helper="completed / started"
          color="orange"
        />
        <StatCard
          icon={Clock}
          label="Thời lượng TB"
          value={loading ? '—' : `${data?.averageDurationMinutes ?? 0} phút`}
          helper="buổi tập hoàn thành"
          color="violet"
        />
      </div>

      {/* Charts */}
      <div className="grid gap-6 xl:grid-cols-2">
        {/* Top Exercises */}
        <div className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
          <div className="flex items-center gap-2">
            <Dumbbell size={16} className="text-cyan-500" />
            <h3 className="section-title">Top 10 Bài tập phổ biến</h3>
          </div>
          <p className="section-subtitle">Số lần xuất hiện trong các buổi tập</p>
          {loading ? (
            <div className="mt-6 flex h-96 items-center justify-center text-sm text-slate-400">Đang tải...</div>
          ) : exercises.length === 0 ? (
            <div className="mt-6 flex h-96 items-center justify-center text-sm text-slate-400">Không có dữ liệu</div>
          ) : (
            <div className="mt-6 h-96">
              <ResponsiveContainer width="100%" height="100%">
                <BarChart
                  layout="vertical"
                  data={exercises.map((e, i) => ({
                    name: e.exerciseName.length > 20 ? e.exerciseName.slice(0, 19) + '…' : e.exerciseName,
                    fullName: e.exerciseName,
                    count: e.count,
                    color: EXERCISE_COLORS[i],
                  }))}
                  margin={{ top: 0, right: 20, bottom: 0, left: 8 }}
                >
                  <CartesianGrid strokeDasharray="3 3" stroke="#f1f5f9" horizontal={false} />
                  <XAxis type="number" tick={{ fill: '#94a3b8', fontSize: 11 }} tickLine={false} axisLine={false} />
                  <YAxis
                    type="category"
                    dataKey="name"
                    width={140}
                    tick={{ fill: '#475569', fontSize: 11 }}
                    tickLine={false}
                    axisLine={false}
                    interval={0}
                  />
                  <Tooltip
                    formatter={(value, _, props) => [value.toLocaleString() + ' lần', props.payload?.fullName ?? '']}
                    contentStyle={{ borderRadius: 12, border: '1px solid #e2e8f0', fontSize: 12 }}
                  />
                  <Bar dataKey="count" radius={[0, 6, 6, 0]} maxBarSize={26}>
                    {exercises.map((_, i) => (
                      <Cell key={i} fill={EXERCISE_COLORS[i]} />
                    ))}
                  </Bar>
                </BarChart>
              </ResponsiveContainer>
            </div>
          )}
        </div>

        {/* Top Muscles */}
        <div className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
          <div className="flex items-center gap-2">
            <Activity size={16} className="text-orange-500" />
            <h3 className="section-title">Top 10 Nhóm cơ</h3>
          </div>
          <p className="section-subtitle">Tổng EXP tích lũy theo nhóm cơ</p>
          {loading ? (
            <div className="mt-6 flex h-96 items-center justify-center text-sm text-slate-400">Đang tải...</div>
          ) : muscles.length === 0 ? (
            <div className="mt-6 flex h-96 items-center justify-center text-sm text-slate-400">Không có dữ liệu</div>
          ) : (
            <div className="mt-6 h-96">
              <ResponsiveContainer width="100%" height="100%">
                <BarChart
                  layout="vertical"
                  data={muscles.map((m, i) => ({
                    name: m.muscleName.length > 20 ? m.muscleName.slice(0, 19) + '…' : m.muscleName,
                    fullName: m.muscleName,
                    exp: m.totalExpGained,
                    color: MUSCLE_COLORS[i],
                  }))}
                  margin={{ top: 0, right: 20, bottom: 0, left: 8 }}
                >
                  <CartesianGrid strokeDasharray="3 3" stroke="#f1f5f9" horizontal={false} />
                  <XAxis type="number" tick={{ fill: '#94a3b8', fontSize: 11 }} tickLine={false} axisLine={false} />
                  <YAxis
                    type="category"
                    dataKey="name"
                    width={140}
                    tick={{ fill: '#475569', fontSize: 11 }}
                    tickLine={false}
                    axisLine={false}
                    interval={0}
                  />
                  <Tooltip
                    formatter={(value, _, props) => [value.toLocaleString() + ' EXP', props.payload?.fullName ?? '']}
                    contentStyle={{ borderRadius: 12, border: '1px solid #e2e8f0', fontSize: 12 }}
                  />
                  <Bar dataKey="exp" radius={[0, 6, 6, 0]} maxBarSize={26}>
                    {muscles.map((_, i) => (
                      <Cell key={i} fill={MUSCLE_COLORS[i]} />
                    ))}
                  </Bar>
                </BarChart>
              </ResponsiveContainer>
            </div>
          )}
        </div>
      </div>

      {/* Most Consistent Users */}
      <div className="rounded-2xl border border-slate-200 bg-white shadow-sm">
        <div className="flex items-center gap-2 border-b border-slate-100 px-6 py-4">
          <Medal size={16} className="text-amber-500" />
          <h3 className="section-title">Top 10 User chăm chỉ nhất</h3>
        </div>
        {loading ? (
          <div className="flex h-32 items-center justify-center text-sm text-slate-400">Đang tải...</div>
        ) : users.length === 0 ? (
          <div className="flex h-32 items-center justify-center text-sm text-slate-400">Không có dữ liệu</div>
        ) : (
          <table className="w-full text-sm">
            <thead className="bg-slate-50">
              <tr>
                <th className="px-6 py-3 text-left text-xs font-bold uppercase tracking-wide text-slate-500">#</th>
                <th className="px-6 py-3 text-left text-xs font-bold uppercase tracking-wide text-slate-500">User</th>
                <th className="px-6 py-3 text-right text-xs font-bold uppercase tracking-wide text-slate-500">Buổi tập</th>
                <th className="px-6 py-3 text-right text-xs font-bold uppercase tracking-wide text-slate-500">Hoàn thành</th>
                <th className="px-6 py-3 text-right text-xs font-bold uppercase tracking-wide text-slate-500">Tỉ lệ</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100">
              {users.map((u, index) => {
                const rate = u.sessionCount > 0 ? ((u.completedSessions / u.sessionCount) * 100).toFixed(0) : 0
                const medal = index === 0 ? '🥇' : index === 1 ? '🥈' : index === 2 ? '🥉' : null
                return (
                  <tr key={u.userId} className="hover:bg-slate-50">
                    <td className="px-6 py-3 font-black text-slate-300">
                      {medal ? <span>{medal}</span> : <span className="text-slate-400">{index + 1}</span>}
                    </td>
                    <td className="px-6 py-3">
                      <div className="flex items-center gap-2.5">
                        <div className="flex h-7 w-7 items-center justify-center rounded-lg bg-gradient-to-br from-slate-200 to-slate-300 text-xs font-black text-slate-600">
                          {(u.userName || 'U')[0].toUpperCase()}
                        </div>
                        <div>
                          <p className="font-semibold text-slate-700">{u.userName || 'Unknown'}</p>
                          <p className="text-[10px] text-slate-400 font-mono">{u.userId.slice(-8)}</p>
                        </div>
                      </div>
                    </td>
                    <td className="px-6 py-3 text-right font-black text-slate-900">{u.sessionCount}</td>
                    <td className="px-6 py-3 text-right font-semibold text-emerald-600">{u.completedSessions}</td>
                    <td className="px-6 py-3 text-right">
                      <span className="rounded-full bg-orange-50 px-2 py-0.5 text-xs font-bold text-orange-600">
                        {rate}%
                      </span>
                    </td>
                  </tr>
                )
              })}
            </tbody>
          </table>
        )}
      </div>
    </div>
  )
}
