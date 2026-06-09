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
}

export default function AdminLayout() {
  const [sidebarOpen, setSidebarOpen] = useState(false)
  const location = useLocation()
  const title = useMemo(() => {
    if (location.pathname.startsWith('/admin/users/')) return 'User Detail'
    if (location.pathname.startsWith('/admin/exercises/') && location.pathname !== '/admin/exercises/new') return 'Edit Exercise'
    if (location.pathname.startsWith('/admin/workout-templates/') && location.pathname !== '/admin/workout-templates/new') return 'Edit Workout Template'
    return titles[location.pathname] ?? 'Gym AI Admin'
  }, [location.pathname])

  return (
    <div className="min-h-screen bg-slate-100 lg:flex">
      <Sidebar open={sidebarOpen} onClose={() => setSidebarOpen(false)} />
      <div className="min-w-0 flex-1">
        <Header title={title} onMenuClick={() => setSidebarOpen(true)} />
        <main className="p-4 sm:p-6">
          <Outlet />
        </main>
      </div>
    </div>
  )
}
