import { useMemo, useState } from 'react'
import { Outlet, useLocation } from 'react-router-dom'
import Header from './Header.jsx'
import Sidebar from './Sidebar.jsx'

const titles = {
  '/admin': 'Tổng quan bảng điều khiển',
  '/admin/users': 'Quản lý người dùng',
  '/admin/exercises': 'Quản lý bài tập',
  '/admin/exercises/new': 'Thêm bài tập',
  '/admin/muscle-groups': 'Quản lý nhóm cơ',
  '/admin/workout-templates': 'Quản lý chương trình tập mẫu',
  '/admin/workout-templates/new': 'Thêm chương trình tập mẫu',
  '/admin/ai-recommendations': 'Quản lý đề xuất AI',
  '/admin/body-checks': 'Quản lý kiểm tra vóc dáng',
  '/admin/feedbacks': 'Quản lý phản hồi / báo cáo',
  '/admin/analytics/active-users': 'Phân tích người dùng hoạt động',
  '/admin/analytics/retention': 'Phân tích tỷ lệ giữ chân',
  '/admin/analytics/funnel': 'Phân tích phễu chuyển đổi',
  '/admin/analytics/feature-usage': 'Phân tích mức sử dụng tính năng',
  '/admin/analytics/workouts': 'Phân tích hành vi tập luyện',
}

export default function AdminLayout() {
  const [sidebarOpen, setSidebarOpen] = useState(false)
  const location = useLocation()

  const title = useMemo(() => {
    if (location.pathname.startsWith('/admin/users/')) return 'Chi tiết người dùng'
    if (location.pathname.startsWith('/admin/exercises/') && location.pathname !== '/admin/exercises/new')
      return 'Sửa bài tập'
    if (
      location.pathname.startsWith('/admin/workout-templates/') &&
      location.pathname !== '/admin/workout-templates/new'
    )
      return 'Sửa chương trình tập mẫu'
    return titles[location.pathname] ?? 'Quản trị GymSupport'
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
