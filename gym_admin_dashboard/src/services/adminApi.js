const API_BASE_URL = (import.meta.env.VITE_API_BASE_URL || 'http://localhost:5028/api').replace(/\/$/, '')

const tokenKeys = ['token', 'authToken', 'accessToken', 'jwt']

const getToken = () => tokenKeys.map((key) => localStorage.getItem(key)).find(Boolean)

const clearAuthTokens = () => {
  tokenKeys.forEach((key) => localStorage.removeItem(key))
}

async function request(path, { method = 'GET', body, optional = false, emptyValue = null } = {}) {
  try {
    const headers = {}
    const token = getToken()

    if (body !== undefined) headers['Content-Type'] = 'application/json'
    if (token) headers.Authorization = `Bearer ${token}`

    const response = await fetch(`${API_BASE_URL}${path}`, {
      method,
      headers,
      body: body === undefined ? undefined : JSON.stringify(body),
    })

    if ([401, 403].includes(response.status)) {
      clearAuthTokens()
    }

    if (optional && [401, 403, 404].includes(response.status)) return emptyValue
    if (response.status === 204) return null

    const text = await response.text()
    const payload = text ? JSON.parse(text) : null

    if (!response.ok) {
      throw new Error(payload?.message || `API ${method} ${path} failed with ${response.status}`)
    }

    return payload
  } catch (error) {
    if (optional) return emptyValue
    console.error(error)
    return emptyValue
  }
}

const asArray = (value) => (Array.isArray(value) ? value : [])
const formatDate = (value) => {
  if (!value) return 'N/A'
  const date = new Date(value)
  if (Number.isNaN(date.getTime())) return 'N/A'
  return date.toISOString().slice(0, 10)
}
const statusFromActive = (isActive) => (isActive === false ? 'Blocked' : 'Active')
const activeFromStatus = (status) => status !== 'Hidden' && status !== 'Blocked'
const fallback = (value) => value ?? 'N/A'

const normalizeCustomer = (customer) => customer ?? {}

const normalizeUser = (user, customer, plans = [], aiHistory = []) => {
  const profile = normalizeCustomer(customer)

  return {
    id: user.id,
    fullName: user.fullName,
    email: user.email,
    role: user.role,
    gender: fallback(profile.gender),
    age: profile.age || 'N/A',
    height: profile.heightCm || 'N/A',
    weight: profile.weightKg || 'N/A',
    bmi: profile.bmi || 'N/A',
    goal: fallback(profile.goal),
    experienceLevel: fallback(profile.experienceLevel),
    injuryNotes: fallback(profile.injuryNotes),
    subscription: fallback(profile.subscription),
    status: statusFromActive(user.isActive),
    createdDate: formatDate(user.createdAt),
    isEmailVerified: user.isEmailVerified,
    workoutHistory: plans.map((plan) => `${plan.name} (${plan.goal})`),
    bodyCheckHistory: [],
    aiRecommendationHistory: aiHistory
      .filter((message) => message.role === 'assistant')
      .map((message) => `${formatDate(message.createdAt)} - ${message.content}`),
  }
}

const normalizeMuscle = (muscle) => ({
  id: muscle.id,
  name: muscle.name,
  category: muscle.category || '',
  description: muscle.category || '',
  imageUrl: '',
  status: 'Active',
})

const buildMuscleLookup = (muscles) =>
  asArray(muscles).reduce((lookup, muscle) => {
    lookup.byId[muscle.id] = muscle
    lookup.byName[muscle.name?.toLowerCase()] = muscle
    return lookup
  }, { byId: {}, byName: {} })

const normalizeExercise = (exercise, muscleLookup = { byId: {}, byName: {} }) => {
  const impacts = asArray(exercise.muscleImpacts).map((impact) => {
    const muscle = muscleLookup.byId[impact.muscleId]
    return {
      muscleId: impact.muscleId,
      muscle: muscle?.name || impact.muscleId,
      percent: impact.percentage ?? 0,
    }
  })

  return {
    id: exercise.id,
    name: exercise.name,
    equipment: exercise.equipment,
    difficulty: exercise.difficulty,
    imageUrl: exercise.imageUrl,
    videoUrl: exercise.videoUrl,
    mainMuscleGroup: impacts[0]?.muscle || 'N/A',
    secondaryMuscleGroups: impacts.slice(1).map((impact) => impact.muscle),
    muscleImpacts: impacts,
    description: '',
    instruction: '',
    defaultSets: 'N/A',
    defaultReps: 'N/A',
    restTime: 'N/A',
    status: 'Active',
  }
}

const exercisePayload = async (payload) => {
  const muscles = await adminApi.getMuscleGroups()
  const muscleLookup = buildMuscleLookup(muscles)
  const primaryMuscle = muscleLookup.byName[payload.mainMuscleGroup?.toLowerCase()] || muscleLookup.byId[payload.mainMuscleGroup]
  const muscleImpacts = primaryMuscle
    ? [{ muscleId: primaryMuscle.id, percentage: payload.muscleImpacts?.[0]?.percent ?? 70 }]
    : []

  return {
    name: payload.name,
    equipment: payload.equipment,
    difficulty: payload.difficulty,
    imageUrl: payload.imageUrl,
    videoUrl: payload.videoUrl,
    muscleImpacts,
  }
}

const normalizeWorkoutTemplate = (plan) => ({
  id: plan.id,
  userId: plan.userId,
  name: plan.name,
  goal: plan.goal,
  experienceLevel: 'N/A',
  daysPerWeek: plan.daysPerWeek,
  description: '',
  status: plan.isActive ? 'Active' : 'Hidden',
  workoutDays: asArray(plan.sessions).map((session, index) => ({
    id: session.id,
    dayName: session.dayOfWeek || `Day ${index + 1}`,
    targetMuscleGroups: session.focus ? [session.focus] : [],
    exercises: asArray(session.exercises).map((exercise) => ({
      exerciseId: exercise.exerciseId,
      exercise: exercise.exerciseName || exercise.exerciseId,
      sets: exercise.sets,
      reps: exercise.reps,
      restTime: 'N/A',
      notes: exercise.notes || '',
    })),
  })),
})

const sessionsPayload = (workoutDays) =>
  asArray(workoutDays).map((day, index) => ({
    id: day.id || crypto.randomUUID(),
    dayOfWeek: day.dayName || `Day ${index + 1}`,
    focus: asArray(day.targetMuscleGroups).join(', '),
    exercises: asArray(day.exercises)
      .filter((exercise) => exercise.exerciseId || exercise.exercise)
      .map((exercise) => ({
        exerciseId: exercise.exerciseId || exercise.exercise,
        exerciseName: exercise.exercise,
        sets: Number(exercise.sets) || 0,
        reps: exercise.reps || '',
        notes: exercise.notes || '',
      })),
  }))

const normalizeDashboard = (data) => ({
  stats: {
    totalUsers: data?.stats?.totalUsers ?? 0,
    newUsersThisMonth: data?.stats?.newUsersThisMonth ?? 0,
    totalExercises: data?.stats?.totalExercises ?? 0,
    totalWorkoutTemplates: data?.stats?.totalWorkoutTemplates ?? 0,
    totalWorkoutSessions: data?.stats?.totalWorkoutSessions ?? 0,
    completedWorkouts: data?.stats?.completedWorkouts ?? 0,
    totalAIRecommendations: data?.stats?.totalAIRecommendations ?? 0,
    aiUsageCount: data?.stats?.aiUsageCount ?? 0,
    totalBodyChecks: data?.stats?.totalBodyChecks ?? 0,
    totalFeedbacks: data?.stats?.totalFeedbacks ?? 0,
  },
  popularMuscleGroups: asArray(data?.popularMuscleGroups),
  aiUsageTrend: asArray(data?.aiUsageTrend),
})

export const adminApi = {
  getDashboard: async () => normalizeDashboard(await request('/admin/dashboard', { emptyValue: {} })),

  getUsers: async () => {
    const [users, customers, plans] = await Promise.all([
      request('/User', { emptyValue: [] }),
      request('/admin/customers', { emptyValue: [] }),
      request('/workoutplans', { emptyValue: [] }),
    ])
    const customersByUser = Object.fromEntries(asArray(customers).map((customer) => [customer.userId, customer]))
    const plansByUser = asArray(plans).reduce((groups, plan) => {
      groups[plan.userId] = [...(groups[plan.userId] || []), plan]
      return groups
    }, {})

    return asArray(users).map((user) => normalizeUser(user, customersByUser[user.id], plansByUser[user.id] || []))
  },
  getUserById: async (id) => {
    const [user, customer, plans, aiHistory] = await Promise.all([
      request(`/User/${id}`, { emptyValue: null }),
      request(`/Customer/user/${id}`, { optional: true, emptyValue: null }),
      request(`/workoutplans/user/${id}`, { emptyValue: [] }),
      request(`/ai/history/${id}`, { optional: true, emptyValue: [] }),
    ])
    return user ? normalizeUser(user, customer, plans, aiHistory) : null
  },
  blockUser: async (id) => {
    await request(`/User/${id}/deactivate`, { method: 'POST' })
    return { id, status: 'Blocked' }
  },
  unblockUser: async (id) => {
    await request(`/User/${id}/activate`, { method: 'POST' })
    return { id, status: 'Active' }
  },

  getExercises: async () => {
    const [exercises, muscles] = await Promise.all([
      request('/exercises', { emptyValue: [] }),
      request('/muscles', { emptyValue: [] }),
    ])
    return asArray(exercises).map((exercise) => normalizeExercise(exercise, buildMuscleLookup(muscles)))
  },
  getExerciseById: async (id) => {
    const [exercise, muscles] = await Promise.all([
      request(`/exercises/${id}`, { emptyValue: null }),
      request('/muscles', { emptyValue: [] }),
    ])
    return exercise ? normalizeExercise(exercise, buildMuscleLookup(muscles)) : null
  },
  saveExercise: async (payload) => {
    const body = await exercisePayload(payload)
    const saved = payload.id
      ? await request(`/exercises/${payload.id}`, { method: 'PUT', body })
      : await request('/exercises', { method: 'POST', body })
    const muscles = await request('/muscles', { emptyValue: [] })
    return normalizeExercise(saved, buildMuscleLookup(muscles))
  },
  deleteExercise: (id) => request(`/exercises/${id}`, { method: 'DELETE' }),

  getMuscleGroups: async () => asArray(await request('/muscles', { emptyValue: [] })).map(normalizeMuscle),
  saveMuscleGroup: async (payload) => {
    const body = { name: payload.name, category: payload.category || payload.description || '' }
    const saved = payload.id
      ? await request(`/muscles/${payload.id}`, { method: 'PUT', body })
      : await request('/muscles', { method: 'POST', body })
    return normalizeMuscle(saved)
  },
  deleteMuscleGroup: (id) => request(`/muscles/${id}`, { method: 'DELETE' }),

  getWorkoutTemplates: async () =>
    asArray(await request('/workoutplans', { emptyValue: [] })).map(normalizeWorkoutTemplate),
  getWorkoutTemplateById: async (id) => {
    const plan = await request(`/workoutplans/${id}`, { emptyValue: null })
    return plan ? normalizeWorkoutTemplate(plan) : null
  },
  saveWorkoutTemplate: async (payload) => {
    const rootPayload = {
      userId: payload.userId,
      name: payload.name,
      goal: payload.goal,
      daysPerWeek: Number(payload.daysPerWeek),
      isActive: activeFromStatus(payload.status),
      sessions: sessionsPayload(payload.workoutDays),
    }

    if (payload.id) {
      const saved = await request(`/workoutplans/${payload.id}`, { method: 'PUT', body: rootPayload })
      return normalizeWorkoutTemplate(saved)
    }

    const created = await request('/workoutplans', { method: 'POST', body: rootPayload })
    const saved = await request(`/workoutplans/${created.id}`, { method: 'PUT', body: rootPayload })
    return normalizeWorkoutTemplate(saved)
  },
  deleteWorkoutTemplate: (id) => request(`/workoutplans/${id}`, { method: 'DELETE' }),

  getAIRecommendations: () => request('/admin/ai-recommendations', { emptyValue: [] }),
  reviewAIRecommendation: (id, status) => Promise.resolve({ id, status }),
  deleteAIRecommendation: (id) => Promise.resolve({ id }),

  getBodyChecks: () => request('/admin/body-checks', { emptyValue: [] }),
  reviewBodyCheck: (id) => Promise.resolve({ id, status: 'Reviewed' }),
  deleteBodyCheck: (id) => Promise.resolve({ id }),

  getFeedbacks: () => request('/admin/feedbacks', { emptyValue: [] }),
  updateFeedbackStatus: (id, status) => Promise.resolve({ id, status }),
  deleteFeedback: (id) => Promise.resolve({ id }),
}
