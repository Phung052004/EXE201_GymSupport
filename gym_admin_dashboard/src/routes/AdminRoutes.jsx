import { Navigate, Route, Routes } from 'react-router-dom'
import AdminLayout from '../components/layout/AdminLayout.jsx'
import AIRecommendationsPage from '../pages/admin/AIRecommendationsPage.jsx'
import BodyChecksPage from '../pages/admin/BodyChecksPage.jsx'
import DashboardPage from '../pages/admin/DashboardPage.jsx'
import ExerciseFormPage from '../pages/admin/ExerciseFormPage.jsx'
import ExercisesPage from '../pages/admin/ExercisesPage.jsx'
import FeedbacksPage from '../pages/admin/FeedbacksPage.jsx'
import MuscleGroupsPage from '../pages/admin/MuscleGroupsPage.jsx'
import UserDetailPage from '../pages/admin/UserDetailPage.jsx'
import UsersPage from '../pages/admin/UsersPage.jsx'
import WorkoutTemplateFormPage from '../pages/admin/WorkoutTemplateFormPage.jsx'
import WorkoutTemplatesPage from '../pages/admin/WorkoutTemplatesPage.jsx'

export default function AdminRoutes() {
  return (
    <Routes>
      <Route path="/" element={<Navigate to="/admin" replace />} />
      <Route path="/admin" element={<AdminLayout />}>
        <Route index element={<DashboardPage />} />
        <Route path="users" element={<UsersPage />} />
        <Route path="users/:id" element={<UserDetailPage />} />
        <Route path="exercises" element={<ExercisesPage />} />
        <Route path="exercises/new" element={<ExerciseFormPage />} />
        <Route path="exercises/:id" element={<ExerciseFormPage />} />
        <Route path="muscle-groups" element={<MuscleGroupsPage />} />
        <Route path="workout-templates" element={<WorkoutTemplatesPage />} />
        <Route path="workout-templates/new" element={<WorkoutTemplateFormPage />} />
        <Route path="workout-templates/:id" element={<WorkoutTemplateFormPage />} />
        <Route path="ai-recommendations" element={<AIRecommendationsPage />} />
        <Route path="body-checks" element={<BodyChecksPage />} />
        <Route path="feedbacks" element={<FeedbacksPage />} />
      </Route>
      <Route path="*" element={<Navigate to="/admin" replace />} />
    </Routes>
  )
}
