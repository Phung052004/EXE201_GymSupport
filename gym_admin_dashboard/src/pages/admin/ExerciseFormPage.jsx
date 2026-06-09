import { ArrowLeft, Save } from 'lucide-react'
import { useEffect, useState } from 'react'
import { Link, useNavigate, useParams } from 'react-router-dom'
import FormInput from '../../components/common/FormInput.jsx'
import { adminApi } from '../../services/adminApi.js'

const emptyExercise = {
  name: '',
  description: '',
  mainMuscleGroup: '',
  secondaryMuscleGroups: '',
  difficulty: '',
  equipment: '',
  instruction: '',
  imageUrl: '',
  videoUrl: '',
  defaultSets: '',
  defaultReps: '',
  restTime: '',
  status: 'Active',
}

export default function ExerciseFormPage() {
  const { id } = useParams()
  const navigate = useNavigate()
  const [form, setForm] = useState(emptyExercise)
  const [muscleOptions, setMuscleOptions] = useState([])
  const [errors, setErrors] = useState({})

  useEffect(() => {
    adminApi.getMuscleGroups().then((data) => {
      const names = data.map((item) => item.name)
      setMuscleOptions(names)
      setForm((current) => current.mainMuscleGroup ? current : { ...current, mainMuscleGroup: names[0] || '' })
    })
  }, [])

  useEffect(() => {
    if (!id) return
    adminApi.getExerciseById(id).then((data) => {
      if (!data) return
      setForm({
        ...data,
        secondaryMuscleGroups: data.secondaryMuscleGroups?.join(', ') || '',
      })
    })
  }, [id])

  const update = (key, value) => setForm((current) => ({ ...current, [key]: value }))

  const submit = async (event) => {
    event.preventDefault()
    const nextErrors = {}
    if (!form.name.trim()) nextErrors.name = 'Exercise name is required'
    setErrors(nextErrors)
    if (Object.keys(nextErrors).length) return

    await adminApi.saveExercise({
      ...form,
      id,
      defaultSets: Number(form.defaultSets),
      secondaryMuscleGroups: form.secondaryMuscleGroups.split(',').map((item) => item.trim()).filter(Boolean),
      muscleImpacts: [{ muscle: form.mainMuscleGroup, percent: 70 }],
    })
    navigate('/admin/exercises')
  }

  return (
    <form onSubmit={submit} className="space-y-5">
      <Link to="/admin/exercises" className="btn-secondary"><ArrowLeft size={16} /> Back</Link>
      <div className="rounded-lg border border-slate-200 bg-white p-5 shadow-sm">
        <h2 className="text-lg font-black text-slate-950">{id ? 'Edit Exercise' : 'Add Exercise'}</h2>
        <div className="mt-5 grid gap-4 md:grid-cols-2">
          <FormInput label="Exercise Name" value={form.name} onChange={(e) => update('name', e.target.value)} error={errors.name} />
          <FormInput label="Main Muscle Group" as="select" value={form.mainMuscleGroup} onChange={(e) => update('mainMuscleGroup', e.target.value)} options={muscleOptions} />
          <FormInput label="Secondary Muscle Groups" value={form.secondaryMuscleGroups} onChange={(e) => update('secondaryMuscleGroups', e.target.value)} placeholder="Triceps, Shoulders" />
          <FormInput label="Difficulty" as="select" value={form.difficulty} onChange={(e) => update('difficulty', e.target.value)} options={['Beginner', 'Intermediate', 'Advanced']} />
          <FormInput label="Equipment" value={form.equipment} onChange={(e) => update('equipment', e.target.value)} />
          <FormInput label="Default Sets" type="number" value={form.defaultSets} onChange={(e) => update('defaultSets', e.target.value)} />
          <FormInput label="Default Reps" value={form.defaultReps} onChange={(e) => update('defaultReps', e.target.value)} />
          <FormInput label="Rest Time" value={form.restTime} onChange={(e) => update('restTime', e.target.value)} />
          <FormInput label="Image URL" value={form.imageUrl} onChange={(e) => update('imageUrl', e.target.value)} />
          <FormInput label="Video URL" value={form.videoUrl} onChange={(e) => update('videoUrl', e.target.value)} />
          <FormInput label="Status" as="select" value={form.status} onChange={(e) => update('status', e.target.value)} options={['Active', 'Hidden']} />
          <div className="md:col-span-2">
            <FormInput label="Description" as="textarea" rows="3" value={form.description} onChange={(e) => update('description', e.target.value)} />
          </div>
          <div className="md:col-span-2">
            <FormInput label="Instruction" as="textarea" rows="4" value={form.instruction} onChange={(e) => update('instruction', e.target.value)} error={errors.instruction} />
          </div>
        </div>
        <div className="mt-6 flex justify-end">
          <button className="btn-primary" type="submit"><Save size={16} /> Save Exercise</button>
        </div>
      </div>
    </form>
  )
}
