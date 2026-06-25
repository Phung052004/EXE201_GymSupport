import { useMemo, useState } from 'react'
import { Outlet, useLocation } from 'react-router-dom'
import Header from './Header.jsx'
import Sidebar from './Sidebar.jsx'

const titles = {
  '/admin': 'Dashboard Overview',
  '/admin/users': 'User Management',
  '/admin/exercises': 'Exercise Management',
  '/admin/exercises/new': 'Create Exercise',
  '/admin/muscle-groups': 'Muscle Group Management',
  '/admin/workout-templates': 'Workout Template Management',
  '/admin/workout-templates/new': 'Create Workout Template',
  '/admin/ai-recommendations': 'AI Recommendation Management',
  '/admin/body-checks': 'Body Check Management',
  '/admin/feedbacks': 'Feedback / Report Management',
  '/admin/analytics/active-users': 'Active Users Analytics',
  '/admin/analytics/retention': 'Retention Analytics',
  '/admin/analytics/funnel': 'Funnel Analytics',
  '/admin/analytics/feature-usage': 'Feature Usage Analytics',
  '/admin/analytics/workouts': 'Workout Behavior Analytics',
}

export default function AdminLayout() {
  const [sidebarOpen, setSidebarOpen] = useState(false)
  const location = useLocation()

  const title = useMemo(() => {
    if (location.pathname.startsWith('/admin/users/')) return 'User Detail'
    if (location.pathname.startsWith('/admin/exercises/') && location.pathname !== '/admin/exercises/new')
      return 'Edit Exercise'
    if (
      location.pathname.startsWith('/admin/workout-templates/') &&
      location.pathname !== '/admin/workout-templates/new'
    )
      return 'Edit Workout Template'
    return titles[location.pathname] ?? 'GymSupport Admin'
  }, [location.pathname])

  return (
    <div className="flex h-screen overflow-hidden bg-slate-50">
      <Sidebar open={sidebarOpen} onClose={() => setSidebarOpen(false)} />
      <div className="flex min-w-0 flex-1 flex-col overflow-hidden">
        <Header title={title} onMenuClick={() => setSidebarOpen(true)} />
        <main className="flex-1 overflow-y-auto p-4 sm:p-6">
          <Outlet />
        </main>
      </div>
    </div>
  )
}
