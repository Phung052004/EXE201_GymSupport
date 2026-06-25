import { useEffect, useMemo, useState } from 'react'
import {
  Bar,
  BarChart,
  CartesianGrid,
  Cell,
  Legend,
  Line,
  LineChart,
  Pie,
  PieChart,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis,
} from 'recharts'
import { BadgeDollarSign, CheckCircle, Dumbbell, TrendingUp, Users } from 'lucide-react'
import StatCard from '../../components/common/StatCard.jsx'
import {
  getDashboardSummary,
  getMonthlyRevenue,
  getRevenueByPlan,
  getUserGrowth,
  getUsersBySubscription,
} from '../../services/adminDashboardService.js'

const currentYear = new Date().getFullYear()
const yearOptions = Array.from({ length: 5 }, (_, i) => currentYear - i)

const CHART_COLORS = ['#06b6d4', '#8b5cf6', '#10b981', '#f97316', '#ef4444', '#3b82f6']

const formatCurrency = (value) =>
  new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND' }).format(value ?? 0)

const normalizeData = (data) => (Array.isArray(data) ? data : [])

const CustomTooltip = ({ active, payload, label }) => {
  if (!active || !payload?.length) return null
  return (
    <div className="rounded-xl border border-slate-200 bg-white px-4 py-3 shadow-xl">
      <p className="mb-2 text-xs font-bold text-slate-400">{label}</p>
      {payload.map((p) => (
        <p key={p.name} className="text-sm font-bold" style={{ color: p.color }}>
          {p.name}:{' '}
          {typeof p.value === 'number' && p.value > 10000 ? formatCurrency(p.value) : p.value}
        </p>
      ))}
    </div>
  )
}

export default function DashboardPage() {
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState(null)
  const [selectedYear, setSelectedYear] = useState(currentYear)
  const [summary, setSummary] = useState(null)
  const [userGrowth, setUserGrowth] = useState(null)
  const [monthlyRevenue, setMonthlyRevenue] = useState(null)
  const [revenueByPlan, setRevenueByPlan] = useState(null)
  const [usersBySubscription, setUsersBySubscription] = useState(null)

  useEffect(() => {
    async function loadAll() {
      setLoading(true)
      setError(null)
      try {
        const [summaryData, subscriptionData, growthData, revenueData, planData] = await Promise.all([
          getDashboardSummary(),
          getUsersBySubscription(),
          getUserGrowth(selectedYear),
          getMonthlyRevenue(selectedYear),
          getRevenueByPlan(selectedYear),
        ])
        setSummary(summaryData)
        setUsersBySubscription(subscriptionData)
        setUserGrowth(growthData)
        setMonthlyRevenue(revenueData)
        setRevenueByPlan(planData)
      } catch (err) {
        setError(err?.status === 401 || err?.status === 403 ? 'Không có quyền truy cập.' : 'Không thể tải dữ liệu dashboard.')
      } finally {
        setLoading(false)
      }
    }
    loadAll()
  }, [selectedYear])

  const cards = useMemo(() => {
    const s = summary ?? {}
    return [
      { label: 'Tổng khách hàng', value: (s.totalCustomer ?? 0).toLocaleString(), icon: Users, color: 'blue' },
      { label: 'Khách hàng mới tháng này', value: (s.newCustomerThisMonth ?? 0).toLocaleString(), icon: TrendingUp, color: 'cyan' },
      { label: 'Subscriptions đang hoạt động', value: (s.activeSubscriptions ?? 0).toLocaleString(), icon: CheckCircle, color: 'emerald' },
      { label: 'Doanh thu tháng này', value: formatCurrency(s.revenueThisMonth), icon: BadgeDollarSign, color: 'violet' },
      { label: 'Tổng doanh thu', value: formatCurrency(s.totalRevenue), icon: BadgeDollarSign, color: 'indigo' },
      { label: 'Buổi tập hoàn thành', value: (s.completedWorkouts ?? 0).toLocaleString(), icon: Dumbbell, color: 'orange' },
    ]
  }, [summary])

  if (loading) {
    return (
      <div className="flex h-64 items-center justify-center">
        <div className="text-center">
          <div className="h-8 w-8 animate-spin rounded-full border-2 border-cyan-500 border-t-transparent mx-auto" />
          <p className="mt-3 text-sm font-medium text-slate-500">Đang tải dữ liệu...</p>
        </div>
      </div>
    )
  }

  if (error) {
    return (
      <div className="rounded-2xl border border-rose-200 bg-rose-50 p-8 text-center">
        <p className="font-semibold text-rose-700">{error}</p>
      </div>
    )
  }

  const growthData = normalizeData(userGrowth?.data)
  const revenueData = normalizeData(monthlyRevenue?.data)
  const planData = normalizeData(revenueByPlan?.data)
  const subscriptionData = normalizeData(usersBySubscription?.data)

  return (
    <div className="space-y-6 animate-fade-in">
      {/* Stat cards */}
      <section className="grid gap-4 sm:grid-cols-2 xl:grid-cols-3">
        {cards.map((card) => (
          <StatCard key={card.label} icon={card.icon} label={card.label} value={card.value} color={card.color} />
        ))}
      </section>

      {/* Year selector + charts */}
      <section className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
        <div className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
          <div>
            <h2 className="section-title">Biểu đồ theo năm</h2>
            <p className="section-subtitle">Tăng trưởng user và doanh thu theo tháng</p>
          </div>
          <label className="flex items-center gap-2 text-sm font-semibold text-slate-600">
            Năm
            <select
              className="rounded-lg border border-slate-200 bg-white px-3 py-2 text-sm font-bold text-slate-900 shadow-sm focus:border-cyan-400 focus:outline-none"
              value={selectedYear}
              onChange={(e) => setSelectedYear(Number(e.target.value))}
            >
              {yearOptions.map((y) => (
                <option key={y} value={y}>{y}</option>
              ))}
            </select>
          </label>
        </div>

        <div className="mt-6 grid gap-6 xl:grid-cols-2">
          <div className="rounded-xl border border-slate-100 p-4">
            <h3 className="text-sm font-black text-slate-700">Tăng trưởng User</h3>
            <p className="mt-0.5 text-xs text-slate-400">User mới và tổng user theo tháng</p>
            <div className="mt-4 h-72">
              <ResponsiveContainer width="100%" height="100%">
                <LineChart data={growthData}>
                  <CartesianGrid strokeDasharray="3 3" stroke="#f1f5f9" />
                  <XAxis dataKey="monthName" tick={{ fill: '#94a3b8', fontSize: 11 }} tickLine={false} axisLine={false} />
                  <YAxis tick={{ fill: '#94a3b8', fontSize: 11 }} tickLine={false} axisLine={false} />
                  <Tooltip content={<CustomTooltip />} />
                  <Legend wrapperStyle={{ fontSize: 12 }} />
                  <Line type="monotone" dataKey="newCustomer" stroke="#10b981" strokeWidth={2.5} name="Mới" dot={false} activeDot={{ r: 4 }} />
                  <Line type="monotone" dataKey="totalCustomer" stroke="#3b82f6" strokeWidth={2.5} name="Tổng" dot={false} activeDot={{ r: 4 }} />
                </LineChart>
              </ResponsiveContainer>
            </div>
          </div>

          <div className="rounded-xl border border-slate-100 p-4">
            <h3 className="text-sm font-black text-slate-700">Doanh thu theo tháng</h3>
            <p className="mt-0.5 text-xs text-slate-400">Tổng doanh thu mỗi tháng (VND)</p>
            <div className="mt-4 h-72">
              <ResponsiveContainer width="100%" height="100%">
                <BarChart data={revenueData}>
                  <CartesianGrid strokeDasharray="3 3" stroke="#f1f5f9" />
                  <XAxis dataKey="monthName" tick={{ fill: '#94a3b8', fontSize: 11 }} tickLine={false} axisLine={false} />
                  <YAxis tick={{ fill: '#94a3b8', fontSize: 11 }} tickLine={false} axisLine={false} tickFormatter={(v) => `${(v / 1000000).toFixed(0)}M`} />
                  <Tooltip content={<CustomTooltip />} />
                  <Bar dataKey="revenue" name="Doanh thu" radius={[6, 6, 0, 0]} maxBarSize={36}>
                    {revenueData.map((_, index) => (
                      <Cell key={index} fill={CHART_COLORS[index % CHART_COLORS.length]} />
                    ))}
                  </Bar>
                </BarChart>
              </ResponsiveContainer>
            </div>
          </div>
        </div>
      </section>

      {/* Pie charts */}
      <section className="grid gap-6 xl:grid-cols-2">
        <div className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
          <h3 className="section-title">User theo gói đăng ký</h3>
          <p className="section-subtitle">Phân phối subscription hiện tại</p>
          <div className="mt-4 h-72">
            {subscriptionData.length === 0 ? (
              <div className="flex h-full items-center justify-center text-sm text-slate-400">Không có dữ liệu</div>
            ) : (
              <ResponsiveContainer width="100%" height="100%">
                <PieChart>
                  <Pie
                    data={subscriptionData}
                    dataKey="count"
                    nameKey="subscription"
                    cx="50%"
                    cy="50%"
                    outerRadius={100}
                    innerRadius={45}
                    paddingAngle={3}
                  >
                    {subscriptionData.map((_, index) => (
                      <Cell key={index} fill={CHART_COLORS[index % CHART_COLORS.length]} />
                    ))}
                  </Pie>
                  <Tooltip formatter={(v) => [v, 'Users']} />
                  <Legend wrapperStyle={{ fontSize: 12 }} />
                </PieChart>
              </ResponsiveContainer>
            )}
          </div>
        </div>

        <div className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
          <h3 className="section-title">Doanh thu theo gói</h3>
          <p className="section-subtitle">So sánh doanh thu các gói subscription năm {selectedYear}</p>
          <div className="mt-4 h-72">
            {planData.length === 0 ? (
              <div className="flex h-full items-center justify-center text-sm text-slate-400">Không có dữ liệu</div>
            ) : (
              <ResponsiveContainer width="100%" height="100%">
                <BarChart data={planData}>
                  <CartesianGrid strokeDasharray="3 3" stroke="#f1f5f9" />
                  <XAxis dataKey="planName" tick={{ fill: '#94a3b8', fontSize: 11 }} tickLine={false} axisLine={false} />
                  <YAxis tick={{ fill: '#94a3b8', fontSize: 11 }} tickLine={false} axisLine={false} tickFormatter={(v) => `${(v / 1000000).toFixed(0)}M`} />
                  <Tooltip content={<CustomTooltip />} />
                  <Bar dataKey="revenue" name="Doanh thu" radius={[6, 6, 0, 0]} maxBarSize={48}>
                    {planData.map((_, index) => (
                      <Cell key={index} fill={CHART_COLORS[index % CHART_COLORS.length]} />
                    ))}
                  </Bar>
                </BarChart>
              </ResponsiveContainer>
            )}
          </div>
        </div>
      </section>
    </div>
  )
}
