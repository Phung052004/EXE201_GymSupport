import { useEffect, useState } from 'react'
import { ChevronDown, Zap } from 'lucide-react'
import { adminApi } from '../../../services/adminApi.js'

const FUNNEL_COLORS = [
  { bg: 'bg-cyan-500', text: 'text-cyan-700', light: 'bg-cyan-50 border-cyan-200' },
  { bg: 'bg-blue-500', text: 'text-blue-700', light: 'bg-blue-50 border-blue-200' },
  { bg: 'bg-indigo-500', text: 'text-indigo-700', light: 'bg-indigo-50 border-indigo-200' },
  { bg: 'bg-violet-500', text: 'text-violet-700', light: 'bg-violet-50 border-violet-200' },
  { bg: 'bg-purple-500', text: 'text-purple-700', light: 'bg-purple-50 border-purple-200' },
]

const FUNNEL_OPTIONS = [
  { value: 'onboarding_to_workout', label: 'Onboarding → Workout' },
]

function FunnelStep({ step, index, maxCount, isLast }) {
  const c = FUNNEL_COLORS[index] || FUNNEL_COLORS[0]
  const barWidth = maxCount > 0 ? (step.count / maxCount) * 100 : 0

  return (
    <div className="relative">
      <div className={`rounded-2xl border p-5 ${c.light}`}>
        <div className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
          <div className="flex items-center gap-3">
            <div className={`flex h-8 w-8 items-center justify-center rounded-xl ${c.bg} text-sm font-black text-white shadow`}>
              {index + 1}
            </div>
            <div>
              <p className={`text-sm font-black ${c.text}`}>{step.label}</p>
              <p className="text-xs text-slate-500 font-mono">{step.step}</p>
            </div>
          </div>

          <div className="flex flex-wrap items-center gap-4 text-right">
            <div>
              <p className="text-2xl font-black text-slate-900 tabular-nums">{step.count.toLocaleString()}</p>
              <p className="text-xs font-medium text-slate-400">users</p>
            </div>
            {index > 0 && (
              <>
                <div>
                  <p className={`text-lg font-black tabular-nums ${c.text}`}>
                    {step.conversionFromPrevious}%
                  </p>
                  <p className="text-xs font-medium text-slate-400">từ bước trước</p>
                </div>
                <div>
                  <p className="text-lg font-black tabular-nums text-slate-600">
                    {step.conversionFromStart}%
                  </p>
                  <p className="text-xs font-medium text-slate-400">từ đầu</p>
                </div>
              </>
            )}
          </div>
        </div>

        {/* Progress bar */}
        <div className="mt-4 h-2 w-full overflow-hidden rounded-full bg-white/60">
          <div
            className={`h-full rounded-full transition-all duration-700 ${c.bg}`}
            style={{ width: `${barWidth}%` }}
          />
        </div>

        {/* Drop-off */}
        {index > 0 && step.droppedFromPrevious > 0 && (
          <p className="mt-2 text-xs font-semibold text-rose-500">
            − {step.droppedFromPrevious.toLocaleString()} users rớt khỏi bước này
          </p>
        )}
      </div>

      {!isLast && (
        <div className="flex justify-center py-1">
          <ChevronDown size={18} className="text-slate-300" />
        </div>
      )}
    </div>
  )
}

export default function FunnelPage() {
  const [funnelName, setFunnelName] = useState('onboarding_to_workout')
  const [data, setData] = useState(null)
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState(null)

  const load = async (name) => {
    setLoading(true)
    setError(null)
    try {
      const result = await adminApi.getFunnel(name)
      setData(result)
    } catch {
      setError('Không thể tải dữ liệu funnel.')
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => { load(funnelName) }, [funnelName])

  const steps = data?.steps ?? []
  const maxCount = steps[0]?.count ?? 0
  const overallConversion = maxCount > 0 && steps.length > 0
    ? steps[steps.length - 1].conversionFromStart
    : 0

  return (
    <div className="space-y-6 animate-fade-in">
      {/* Header */}
      <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <h2 className="text-xl font-black text-slate-900">Funnel Analytics</h2>
          <p className="mt-0.5 text-sm text-slate-500">
            Phân tích tỉ lệ chuyển đổi qua từng bước trong hành trình người dùng
          </p>
        </div>
        <div className="flex items-center gap-2">
          <Zap size={16} className="text-amber-500" />
          <select
            className="rounded-lg border border-slate-200 bg-white px-3 py-2 text-sm font-semibold text-slate-700 shadow-sm focus:border-cyan-400 focus:outline-none focus:ring-2 focus:ring-cyan-400/20"
            value={funnelName}
            onChange={(e) => setFunnelName(e.target.value)}
          >
            {FUNNEL_OPTIONS.map((opt) => (
              <option key={opt.value} value={opt.value}>
                {opt.label}
              </option>
            ))}
          </select>
        </div>
      </div>

      {error && (
        <div className="rounded-xl border border-rose-200 bg-rose-50 px-4 py-3 text-sm font-medium text-rose-700">
          {error}
        </div>
      )}

      {/* Summary */}
      {!loading && steps.length > 0 && (
        <div className="grid gap-4 sm:grid-cols-3">
          <div className="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm">
            <p className="stat-label">Tổng đầu vào</p>
            <p className="mt-2 text-2xl font-black text-slate-900">{maxCount.toLocaleString()}</p>
            <p className="mt-1 text-xs text-slate-400">users đã đăng ký thành công</p>
          </div>
          <div className="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm">
            <p className="stat-label">Đầu ra</p>
            <p className="mt-2 text-2xl font-black text-slate-900">
              {(steps[steps.length - 1]?.count ?? 0).toLocaleString()}
            </p>
            <p className="mt-1 text-xs text-slate-400">users hoàn thành toàn bộ funnel</p>
          </div>
          <div className="rounded-2xl border border-violet-100 bg-gradient-to-br from-violet-50 to-purple-50 p-5">
            <p className="stat-label text-violet-600">Overall Conversion</p>
            <p className="mt-2 text-3xl font-black text-violet-700">{overallConversion}%</p>
            <p className="mt-1 text-xs text-violet-400">từ bước 1 đến cuối funnel</p>
          </div>
        </div>
      )}

      {/* Funnel Steps */}
      <div className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
        <h3 className="section-title">Funnel: {data?.name ?? funnelName}</h3>
        <p className="section-subtitle">Click từng bước để xem chi tiết tỉ lệ chuyển đổi</p>

        <div className="mt-6">
          {loading ? (
            <div className="flex h-48 items-center justify-center text-sm font-medium text-slate-400">
              Đang tải dữ liệu funnel...
            </div>
          ) : steps.length === 0 ? (
            <div className="flex h-48 items-center justify-center text-sm font-medium text-slate-400">
              Không có dữ liệu
            </div>
          ) : (
            <div className="space-y-0">
              {steps.map((step, index) => (
                <FunnelStep
                  key={step.step}
                  step={step}
                  index={index}
                  maxCount={maxCount}
                  isLast={index === steps.length - 1}
                />
              ))}
            </div>
          )}
        </div>
      </div>

      {/* Conversion table */}
      {!loading && steps.length > 0 && (
        <div className="rounded-2xl border border-slate-200 bg-white shadow-sm">
          <div className="border-b border-slate-100 px-6 py-4">
            <h3 className="section-title">Bảng tỉ lệ chuyển đổi</h3>
          </div>
          <table className="w-full text-sm">
            <thead className="bg-slate-50">
              <tr>
                <th className="px-6 py-3 text-left text-xs font-bold uppercase tracking-wide text-slate-500">#</th>
                <th className="px-6 py-3 text-left text-xs font-bold uppercase tracking-wide text-slate-500">Bước</th>
                <th className="px-6 py-3 text-right text-xs font-bold uppercase tracking-wide text-slate-500">Users</th>
                <th className="px-6 py-3 text-right text-xs font-bold uppercase tracking-wide text-slate-500">Từ bước trước</th>
                <th className="px-6 py-3 text-right text-xs font-bold uppercase tracking-wide text-slate-500">Từ đầu</th>
                <th className="px-6 py-3 text-right text-xs font-bold uppercase tracking-wide text-slate-500">Rớt</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100">
              {steps.map((step, index) => (
                <tr key={step.step} className="hover:bg-slate-50">
                  <td className="px-6 py-3 font-bold text-slate-400">{index + 1}</td>
                  <td className="px-6 py-3 font-semibold text-slate-700">{step.label}</td>
                  <td className="px-6 py-3 text-right font-bold text-slate-900">{step.count.toLocaleString()}</td>
                  <td className="px-6 py-3 text-right font-bold text-cyan-600">{step.conversionFromPrevious}%</td>
                  <td className="px-6 py-3 text-right font-bold text-slate-600">{step.conversionFromStart}%</td>
                  <td className="px-6 py-3 text-right">
                    {step.droppedFromPrevious > 0 ? (
                      <span className="font-bold text-rose-500">−{step.droppedFromPrevious.toLocaleString()}</span>
                    ) : (
                      <span className="text-slate-300">—</span>
                    )}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  )
}
