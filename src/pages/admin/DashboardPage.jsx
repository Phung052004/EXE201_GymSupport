import { Bot, Dumbbell, MessageSquare, ScanFace, Timer, Users, Workflow } from 'lucide-react'
import { useEffect, useState } from 'react'
import StatCard from '../../components/common/StatCard.jsx'
import { adminApi } from '../../services/adminApi.js'

export default function DashboardPage() {
  const [data, setData] = useState(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    adminApi.getDashboard().then((result) => {
      setData(result)
      setLoading(false)
    })
  }, [])

  if (loading) return <div className="rounded-lg bg-white p-8 text-slate-500">Loading dashboard...</div>

  const stats = data.stats
  const maxAIUsage = Math.max(...data.aiUsageTrend.map((item) => item.value), 1)
  const cards = [
    { label: 'Total Users', value: stats.totalUsers, icon: Users, helper: `+${stats.newUsersThisMonth} this month` },
    { label: 'Total Exercises', value: stats.totalExercises, icon: Dumbbell },
    { label: 'Workout Templates', value: stats.totalWorkoutTemplates, icon: Workflow },
    { label: 'Workout Sessions', value: stats.totalWorkoutSessions, icon: Timer, helper: `${stats.completedWorkouts} completed` },
    { label: 'AI Recommendations', value: stats.totalAIRecommendations, icon: Bot, helper: `${stats.aiUsageCount} AI calls` },
    { label: 'Body Checks', value: stats.totalBodyChecks, icon: ScanFace },
    { label: 'Feedbacks', value: stats.totalFeedbacks, icon: MessageSquare },
  ]

  return (
    <div className="space-y-6">
      <section className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
        {cards.map((card) => (
          <StatCard key={card.label} {...card} />
        ))}
      </section>

      <section className="grid gap-6 xl:grid-cols-[1.4fr_1fr]">
        <div className="rounded-lg border border-slate-200 bg-white p-5 shadow-sm">
          <div className="flex items-center justify-between">
            <div>
              <h2 className="text-lg font-black text-slate-950">AI Usage Trend</h2>
              <p className="text-sm font-medium text-slate-500">Weekly AI interactions from backend chat history</p>
            </div>
            <span className="rounded-full bg-emerald-50 px-3 py-1 text-xs font-bold text-emerald-700">Healthy</span>
          </div>
          <div className="mt-8 flex h-56 items-end gap-3">
            {data.aiUsageTrend.map((item) => (
              <div key={item.label} className="flex flex-1 flex-col items-center gap-2">
                <div className="w-full rounded-t-md bg-emerald-500" style={{ height: `${Math.max((item.value / maxAIUsage) * 100, item.value ? 8 : 2)}%` }} />
                <span className="text-xs font-bold text-slate-400">{item.label}</span>
              </div>
            ))}
          </div>
        </div>

        <div className="rounded-lg border border-slate-200 bg-white p-5 shadow-sm">
          <h2 className="text-lg font-black text-slate-950">Popular Muscle Groups</h2>
          <p className="text-sm font-medium text-slate-500">Based on generated plans and completed sessions</p>
          <div className="mt-5 space-y-4">
            {data.popularMuscleGroups.map((item) => (
              <div key={item.name}>
                <div className="mb-1 flex items-center justify-between text-sm font-bold">
                  <span>{item.name}</span>
                  <span className="text-slate-500">{item.value}%</span>
                </div>
                <div className="h-2 rounded-full bg-slate-100">
                  <div className="h-2 rounded-full bg-emerald-500" style={{ width: `${item.value}%` }} />
                </div>
              </div>
            ))}
          </div>
        </div>
      </section>
    </div>
  )
}
