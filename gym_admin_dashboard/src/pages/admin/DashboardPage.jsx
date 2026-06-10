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
import StatCard from '../../components/common/StatCard.jsx'
import {
  getDashboardSummary,
  getMonthlyRevenue,
  getRevenueByPlan,
  getUserGrowth,
  getUsersBySubscription,
} from '../../services/adminDashboardService.js'

const currentYear = new Date().getFullYear()
const yearOptions = Array.from({ length: 5 }, (_, index) => currentYear - index)
const revenueByPlanColors = ['#0ea5e9', '#7c3aed', '#22c55e', '#f97316', '#ef4444']

const formatCurrency = (value) =>
  new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND' }).format(value ?? 0)

const normalizeData = (data) => Array.isArray(data) ? data : []

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
    async function loadDashboard() {
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
        const status = err?.status
        if (status === 401 || status === 403) {
          setError('You are not authorized to view this dashboard.')
        } else {
          setError('Failed to load dashboard data')
        }
      } finally {
        setLoading(false)
      }
    }

    loadDashboard()
  }, [selectedYear])

  useEffect(() => {
    async function loadYearlyData() {
      setLoading(true)
      setError(null)

      try {
        const [growthData, revenueData, planData] = await Promise.all([
          getUserGrowth(selectedYear),
          getMonthlyRevenue(selectedYear),
          getRevenueByPlan(selectedYear),
        ])

        setUserGrowth(growthData)
        setMonthlyRevenue(revenueData)
        setRevenueByPlan(planData)
      } catch (err) {
        const status = err?.status
        if (status === 401 || status === 403) {
          setError('You are not authorized to view this dashboard.')
        } else {
          setError('Failed to load dashboard data')
        }
      } finally {
        setLoading(false)
      }
    }

    if (summary) {
      loadYearlyData()
    }
  }, [selectedYear, summary])

  const cards = useMemo(() => {
    const summaryValues = summary ?? {}
    return [
      {
        label: 'Total Customers',
        value: summaryValues.totalCustomer ?? 0,
      },
      {
        label: 'New Customers This Month',
        value: summaryValues.newCustomerThisMonth ?? 0,
      },
      {
        label: 'Active Subscriptions',
        value: summaryValues.activeSubscriptions ?? 0,
      },
      {
        label: 'Revenue This Month',
        value: formatCurrency(summaryValues.revenueThisMonth),
      },
      {
        label: 'Total Revenue',
        value: formatCurrency(summaryValues.totalRevenue),
      },
      {
        label: 'Completed Workouts',
        value: summaryValues.completedWorkouts ?? 0,
      },
    ]
  }, [summary])

  if (loading) {
    return <div className="rounded-lg bg-white p-8 text-slate-500">Loading dashboard...</div>
  }

  if (error) {
    return <div className="rounded-lg bg-white p-8 text-slate-700">{error}</div>
  }

  const growthData = normalizeData(userGrowth?.data)
  const revenueData = normalizeData(monthlyRevenue?.data)
  const planData = normalizeData(revenueByPlan?.data)
  const subscriptionData = normalizeData(usersBySubscription?.data)

  return (
    <div className="space-y-6">
      <section className="grid gap-4 sm:grid-cols-2 xl:grid-cols-3">
        {cards.map((card) => (
          <StatCard key={card.label} {...card} />
        ))}
      </section>

      <section className="space-y-6 rounded-lg border border-slate-200 bg-white p-5 shadow-sm">
        <div className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
          <div>
            <h2 className="text-lg font-black text-slate-950">Yearly Dashboard</h2>
            <p className="text-sm font-medium text-slate-500">Select a year to update the growth and revenue charts.</p>
          </div>
          <label className="flex items-center gap-3 text-sm font-medium text-slate-700">
            <span>Year</span>
            <select
              className="rounded-lg border border-slate-300 bg-white px-3 py-2 text-sm text-slate-900 shadow-sm focus:border-slate-500 focus:outline-none"
              value={selectedYear}
              onChange={(event) => setSelectedYear(Number(event.target.value))}
            >
              {yearOptions.map((year) => (
                <option key={year} value={year}>
                  {year}
                </option>
              ))}
            </select>
          </label>
        </div>

        <div className="grid gap-6 xl:grid-cols-[1.3fr_1fr]">
          <div className="rounded-lg border border-slate-200 bg-white p-5 shadow-sm">
            <h3 className="text-base font-black text-slate-950">User Growth</h3>
            <p className="mt-1 text-sm text-slate-500">New customers and total customers by month.</p>
            <div className="mt-6 h-80">
              <ResponsiveContainer width="100%" height="100%">
                <LineChart data={growthData}>
                  <CartesianGrid strokeDasharray="3 3" />
                  <XAxis dataKey="monthName" tick={{ fill: '#475569' }} />
                  <YAxis tick={{ fill: '#475569' }} />
                  <Tooltip formatter={(value) => [value, 'Count']} />
                  <Legend />
                  <Line type="monotone" dataKey="newCustomer" stroke="#22c55e" strokeWidth={3} name="New Customer" />
                  <Line type="monotone" dataKey="totalCustomer" stroke="#2563eb" strokeWidth={3} name="Total Customer" />
                </LineChart>
              </ResponsiveContainer>
            </div>
          </div>

          <div className="rounded-lg border border-slate-200 bg-white p-5 shadow-sm">
            <h3 className="text-base font-black text-slate-950">Monthly Revenue</h3>
            <p className="mt-1 text-sm text-slate-500">Revenue by month, with transaction counts.</p>
            <div className="mt-6 h-80">
              <ResponsiveContainer width="100%" height="100%">
                <BarChart data={revenueData}>
                  <CartesianGrid strokeDasharray="3 3" />
                  <XAxis dataKey="monthName" tick={{ fill: '#475569' }} />
                  <YAxis tick={{ fill: '#475569' }} tickFormatter={(value) => `${value}`} />
                  <Tooltip
                    formatter={(value) => formatCurrency(value)}
                    labelFormatter={(label) => `Month: ${label}`}
                    contentStyle={{ borderRadius: 12 }}
                  />
                  <Bar dataKey="revenue" fill="#0ea5e9" name="Revenue">
                    {revenueData.map((entry, index) => (
                      <Cell key={entry.monthName || index} fill={revenueByPlanColors[index % revenueByPlanColors.length]} />
                    ))}
                  </Bar>
                </BarChart>
              </ResponsiveContainer>
            </div>
          </div>
        </div>
      </section>

      <section className="grid gap-6 xl:grid-cols-2">
        <div className="rounded-lg border border-slate-200 bg-white p-5 shadow-sm">
          <h3 className="text-base font-black text-slate-950">Users By Subscription</h3>
          <p className="mt-1 text-sm text-slate-500">Subscription counts for users.</p>
          <div className="mt-6 h-80">
            {subscriptionData.length === 0 ? (
              <div className="flex h-full items-center justify-center text-sm font-medium text-slate-500">
                No subscription data available
              </div>
            ) : (
              <ResponsiveContainer width="100%" height="100%">
                <PieChart>
                  <Pie data={subscriptionData} dataKey="count" nameKey="subscription" cx="50%" cy="50%" outerRadius={110} fill="#22c55e" label />
                  <Tooltip formatter={(value) => [value, 'Users']} />
                </PieChart>
              </ResponsiveContainer>
            )}
          </div>
        </div>

        <div className="rounded-lg border border-slate-200 bg-white p-5 shadow-sm">
          <h3 className="text-base font-black text-slate-950">Revenue By Plan</h3>
          <p className="mt-1 text-sm text-slate-500">Revenue by plan for the selected year.</p>
          <div className="mt-6 h-80">
            {planData.length === 0 ? (
              <div className="flex h-full items-center justify-center text-sm font-medium text-slate-500">
                No revenue by plan data available
              </div>
            ) : (
              <ResponsiveContainer width="100%" height="100%">
                <BarChart data={planData}>
                  <CartesianGrid strokeDasharray="3 3" />
                  <XAxis dataKey="planName" tick={{ fill: '#475569' }} />
                  <YAxis tick={{ fill: '#475569' }} tickFormatter={(value) => `${value}`} />
                  <Tooltip formatter={(value) => formatCurrency(value)} labelFormatter={(label) => `Plan: ${label}`} />
                  <Legend />
                  <Bar dataKey="revenue" fill="#f97316" name="Revenue">
                    {planData.map((entry, index) => (
                      <Cell key={entry.planName || index} fill={revenueByPlanColors[index % revenueByPlanColors.length]} />
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
