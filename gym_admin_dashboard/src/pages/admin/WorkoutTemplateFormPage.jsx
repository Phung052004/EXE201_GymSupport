import { ArrowLeft, Plus, Save, Trash2 } from 'lucide-react'
import { useEffect, useState } from 'react'
import { Link, useNavigate, useParams } from 'react-router-dom'
import FormInput from '../../components/common/FormInput.jsx'
import { adminApi } from '../../services/adminApi.js'

const emptyTemplate = {
  userId: '',
  name: '',
  goal: '',
  experienceLevel: '',
  daysPerWeek: 0,
  description: '',
  status: 'Active',
  workoutDays: [],
}

export default function WorkoutTemplateFormPage() {
  const { id } = useParams()
  const navigate = useNavigate()
  const [form, setForm] = useState(emptyTemplate)

  useEffect(() => {
    if (!id) return
    adminApi.getWorkoutTemplateById(id).then((data) => data && setForm(data))
  }, [id])

  const setField = (key, value) => setForm((current) => ({ ...current, [key]: value }))
  const updateDay = (index, patch) => setForm((current) => ({
    ...current,
    workoutDays: current.workoutDays.map((day, i) => i === index ? { ...day, ...patch } : day),
  }))

  const updateExercise = (dayIndex, exerciseIndex, patch) => setForm((current) => ({
    ...current,
    workoutDays: current.workoutDays.map((day, i) => {
      if (i !== dayIndex) return day
      return {
        ...day,
        exercises: day.exercises.map((exercise, j) => j === exerciseIndex ? { ...exercise, ...patch } : exercise),
      }
    }),
  }))

  const addDay = () => setForm((current) => ({
    ...current,
    workoutDays: [...current.workoutDays, { dayName: '', targetMuscleGroups: [], exercises: [] }],
  }))

  const removeDay = (index) => setForm((current) => ({ ...current, workoutDays: current.workoutDays.filter((_, i) => i !== index) }))

  const addExercise = (dayIndex) => setForm((current) => ({
    ...current,
    workoutDays: current.workoutDays.map((day, index) => index === dayIndex
      ? { ...day, exercises: [...day.exercises, { exerciseId: '', exercise: '', sets: 0, reps: '', restTime: '', notes: '' }] }
      : day),
  }))

  const removeExercise = (dayIndex, exerciseIndex) => setForm((current) => ({
    ...current,
    workoutDays: current.workoutDays.map((day, index) => index === dayIndex
      ? { ...day, exercises: day.exercises.filter((_, i) => i !== exerciseIndex) }
      : day),
  }))

  const submit = async (event) => {
    event.preventDefault()
    if (!form.userId?.trim()) return
    await adminApi.saveWorkoutTemplate({ ...form, id, daysPerWeek: Number(form.daysPerWeek) })
    navigate('/admin/workout-templates')
  }

  return (
    <form onSubmit={submit} className="space-y-5">
      <Link to="/admin/workout-templates" className="btn-secondary"><ArrowLeft size={16} /> Back</Link>
      <div className="rounded-lg border border-slate-200 bg-white p-5 shadow-sm">
        <h2 className="text-lg font-black text-slate-950">{id ? 'Edit Workout Template' : 'Create Workout Template'}</h2>
        <div className="mt-5 grid gap-4 md:grid-cols-2">
          <FormInput label="Template Name" value={form.name} onChange={(e) => setField('name', e.target.value)} required />
          <FormInput label="User ID" value={form.userId} onChange={(e) => setField('userId', e.target.value)} required disabled={!!id} />
          <FormInput label="Goal" as="select" value={form.goal} onChange={(e) => setField('goal', e.target.value)} options={['Muscle Gain', 'Fat Loss', 'Strength', 'Tone & Mobility']} />
          <FormInput label="Experience Level" as="select" value={form.experienceLevel} onChange={(e) => setField('experienceLevel', e.target.value)} options={['Beginner', 'Intermediate', 'Advanced']} />
          <FormInput label="Days Per Week" type="number" value={form.daysPerWeek} onChange={(e) => setField('daysPerWeek', e.target.value)} />
          <FormInput label="Status" as="select" value={form.status} onChange={(e) => setField('status', e.target.value)} options={['Active', 'Hidden']} />
          <div className="md:col-span-2">
            <FormInput label="Description" as="textarea" rows="3" value={form.description} onChange={(e) => setField('description', e.target.value)} />
          </div>
        </div>
      </div>

      <div className="space-y-4">
        {form.workoutDays.map((day, index) => (
          <div key={index} className="rounded-lg border border-slate-200 bg-white p-5 shadow-sm">
            <div className="flex items-center justify-between">
              <h3 className="font-black text-slate-950">Workout Day {index + 1}</h3>
              <button type="button" className="btn-secondary" onClick={() => removeDay(index)}><Trash2 size={15} /> Remove</button>
            </div>
            <div className="mt-4 grid gap-4 md:grid-cols-2">
              <FormInput label="Day Name" value={day.dayName} onChange={(e) => updateDay(index, { dayName: e.target.value })} />
              <FormInput label="Target Muscle Groups" value={day.targetMuscleGroups.join(', ')} onChange={(e) => updateDay(index, { targetMuscleGroups: e.target.value.split(',').map((item) => item.trim()).filter(Boolean) })} />
            </div>
            <div className="mt-4 rounded-md bg-slate-50 p-4">
              <p className="text-sm font-black text-slate-700">Exercises</p>
              {day.exercises.map((exercise, exerciseIndex) => (
                <div key={exerciseIndex} className="mt-3 grid gap-3 md:grid-cols-[0.9fr_1.2fr_0.6fr_0.8fr_0.8fr_1fr_auto]">
                  <input className="rounded-md border border-slate-200 px-3 py-2 text-sm" value={exercise.exerciseId || ''} onChange={(e) => updateExercise(index, exerciseIndex, { exerciseId: e.target.value })} placeholder="Exercise ID" />
                  <input className="rounded-md border border-slate-200 px-3 py-2 text-sm" value={exercise.exercise} onChange={(e) => updateExercise(index, exerciseIndex, { exercise: e.target.value })} placeholder="Exercise name" />
                  <input className="rounded-md border border-slate-200 px-3 py-2 text-sm" type="number" value={exercise.sets} onChange={(e) => updateExercise(index, exerciseIndex, { sets: Number(e.target.value) })} placeholder="Sets" />
                  <input className="rounded-md border border-slate-200 px-3 py-2 text-sm" value={exercise.reps} onChange={(e) => updateExercise(index, exerciseIndex, { reps: e.target.value })} placeholder="Reps" />
                  <input className="rounded-md border border-slate-200 px-3 py-2 text-sm" value={exercise.restTime} onChange={(e) => updateExercise(index, exerciseIndex, { restTime: e.target.value })} placeholder="Rest" />
                  <input className="rounded-md border border-slate-200 px-3 py-2 text-sm" value={exercise.notes} onChange={(e) => updateExercise(index, exerciseIndex, { notes: e.target.value })} placeholder="Notes" />
                  <button type="button" className="btn-secondary px-3" onClick={() => removeExercise(index, exerciseIndex)}><Trash2 size={15} /></button>
                </div>
              ))}
              <button type="button" className="btn-secondary mt-4" onClick={() => addExercise(index)}><Plus size={15} /> Add Exercise</button>
            </div>
          </div>
        ))}
      </div>

      <div className="flex flex-col gap-3 sm:flex-row sm:justify-between">
        <button type="button" className="btn-secondary" onClick={addDay}><Plus size={16} /> Add Workout Day</button>
        <button type="submit" className="btn-primary"><Save size={16} /> Save Template</button>
      </div>
    </form>
  )
}
