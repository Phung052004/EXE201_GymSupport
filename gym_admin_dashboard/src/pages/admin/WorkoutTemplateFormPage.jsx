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
      <Link to="/admin/workout-templates" className="btn-secondary"><ArrowLeft size={16} /> Quay lại</Link>
      <div className="rounded-lg border border-slate-200 bg-white p-5 shadow-sm">
        <h2 className="text-lg font-black text-slate-950">{id ? 'Sửa chương trình tập mẫu' : 'Tạo chương trình tập mẫu'}</h2>
        <div className="mt-5 grid gap-4 md:grid-cols-2">
          <FormInput label="Tên chương trình" value={form.name} onChange={(e) => setField('name', e.target.value)} required />
          <FormInput label="Mã người dùng" value={form.userId} onChange={(e) => setField('userId', e.target.value)} required disabled={!!id} />
          <FormInput label="Mục tiêu" as="select" value={form.goal} onChange={(e) => setField('goal', e.target.value)} options={['Muscle Gain', 'Fat Loss', 'Strength', 'Tone & Mobility']} />
          <FormInput label="Trình độ" as="select" value={form.experienceLevel} onChange={(e) => setField('experienceLevel', e.target.value)} options={['Beginner', 'Intermediate', 'Advanced']} />
          <FormInput label="Số buổi/tuần" type="number" value={form.daysPerWeek} onChange={(e) => setField('daysPerWeek', e.target.value)} />
          <FormInput label="Trạng thái" as="select" value={form.status} onChange={(e) => setField('status', e.target.value)} options={[{ value: 'Active', label: 'Hoạt động' }, { value: 'Hidden', label: 'Đã ẩn' }]} />
          <div className="md:col-span-2">
            <FormInput label="Mô tả" as="textarea" rows="3" value={form.description} onChange={(e) => setField('description', e.target.value)} />
          </div>
        </div>
      </div>

      <div className="space-y-4">
        {form.workoutDays.map((day, index) => (
          <div key={index} className="rounded-lg border border-slate-200 bg-white p-5 shadow-sm">
            <div className="flex items-center justify-between">
              <h3 className="font-black text-slate-950">Buổi tập {index + 1}</h3>
              <button type="button" className="btn-secondary" onClick={() => removeDay(index)}><Trash2 size={15} /> Xóa</button>
            </div>
            <div className="mt-4 grid gap-4 md:grid-cols-2">
              <FormInput label="Tên buổi tập" value={day.dayName} onChange={(e) => updateDay(index, { dayName: e.target.value })} />
              <FormInput label="Nhóm cơ mục tiêu" value={day.targetMuscleGroups.join(', ')} onChange={(e) => updateDay(index, { targetMuscleGroups: e.target.value.split(',').map((item) => item.trim()).filter(Boolean) })} />
            </div>
            <div className="mt-4 rounded-md bg-slate-50 p-4">
              <p className="text-sm font-black text-slate-700">Bài tập</p>
              {day.exercises.map((exercise, exerciseIndex) => (
                <div key={exerciseIndex} className="mt-3 grid gap-3 md:grid-cols-[0.9fr_1.2fr_0.6fr_0.8fr_0.8fr_1fr_auto]">
                  <input className="rounded-md border border-slate-200 px-3 py-2 text-sm" value={exercise.exerciseId || ''} onChange={(e) => updateExercise(index, exerciseIndex, { exerciseId: e.target.value })} placeholder="Mã bài tập" />
                  <input className="rounded-md border border-slate-200 px-3 py-2 text-sm" value={exercise.exercise} onChange={(e) => updateExercise(index, exerciseIndex, { exercise: e.target.value })} placeholder="Tên bài tập" />
                  <input className="rounded-md border border-slate-200 px-3 py-2 text-sm" type="number" value={exercise.sets} onChange={(e) => updateExercise(index, exerciseIndex, { sets: Number(e.target.value) })} placeholder="Số hiệp" />
                  <input className="rounded-md border border-slate-200 px-3 py-2 text-sm" value={exercise.reps} onChange={(e) => updateExercise(index, exerciseIndex, { reps: e.target.value })} placeholder="Số lần" />
                  <input className="rounded-md border border-slate-200 px-3 py-2 text-sm" value={exercise.restTime} onChange={(e) => updateExercise(index, exerciseIndex, { restTime: e.target.value })} placeholder="Nghỉ" />
                  <input className="rounded-md border border-slate-200 px-3 py-2 text-sm" value={exercise.notes} onChange={(e) => updateExercise(index, exerciseIndex, { notes: e.target.value })} placeholder="Ghi chú" />
                  <button type="button" className="btn-secondary px-3" onClick={() => removeExercise(index, exerciseIndex)}><Trash2 size={15} /></button>
                </div>
              ))}
              <button type="button" className="btn-secondary mt-4" onClick={() => addExercise(index)}><Plus size={15} /> Thêm bài tập</button>
            </div>
          </div>
        ))}
      </div>

      <div className="flex flex-col gap-3 sm:flex-row sm:justify-between">
        <button type="button" className="btn-secondary" onClick={addDay}><Plus size={16} /> Thêm buổi tập</button>
        <button type="submit" className="btn-primary"><Save size={16} /> Lưu chương trình</button>
      </div>
    </form>
  )
}
