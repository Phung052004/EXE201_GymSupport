import { Navigate, useLocation } from 'react-router-dom'
import { isAuthenticated, isAdmin, logout } from '../services/authService.js'

export default function ProtectedRoute({ children }) {
  const location = useLocation()

  if (!isAuthenticated()) {
    return <Navigate to="/login" replace state={{ from: location }} />
  }

  if (!isAdmin()) {
    logout()
    return <Navigate to="/login" replace state={{ from: location }} />
  }

  return children
}
