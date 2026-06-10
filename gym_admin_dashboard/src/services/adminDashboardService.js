import apiClient from './apiClient.js'

export async function getDashboardSummary() {
  const response = await apiClient.get('/api/admin/dashboard/summary')
  return response.data
}

export async function getUserGrowth(year) {
  const response = await apiClient.get('/api/admin/dashboard/user-growth', {
    params: { year },
  })
  return response.data
}

export async function getMonthlyRevenue(year) {
  const response = await apiClient.get('/api/admin/dashboard/revenue/monthly', {
    params: { year },
  })
  return response.data
}

export async function getRevenueByPlan(year) {
  const response = await apiClient.get('/api/admin/dashboard/revenue/by-plan', {
    params: { year },
  })
  return response.data
}

export async function getUsersBySubscription() {
  const response = await apiClient.get('/api/admin/dashboard/users/by-subscription')
  return response.data
}
