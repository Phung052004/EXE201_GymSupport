import { ArrowLeft, Save, Plus, Trash2 } from 'lucide-react'
import { useEffect, useState } from 'react'
import { Link, useNavigate, useParams } from 'react-router-dom'
import FormInput from '../../components/common/FormInput.jsx'
import { adminApi } from '../../services/adminApi.js'

const emptyExercise = {
  name: '',
  description: '',
  difficulty: '',
  equipment: '',
  instruction: '',
  safetyNotes: '',
  commonMistakes: '',
  tips: '',
  imageUrl: '',
  videoUrl: '',
  defaultSets: 0,
  defaultReps: '',
  restTimeSeconds: 0,
  muscleImpacts: [],
}

export default function ExerciseFormPage() {
  const { id } = useParams()
  const navigate = useNavigate()
  const [form, setForm] = useState(emptyExercise)
  const [muscleOptions, setMuscleOptions] = useState([])
  const [errors, setErrors] = useState({})

  useEffect(() => {
    adminApi.getMuscleGroups().then((data) => {
      setMuscleOptions(data)
    })
  }, [])

  useEffect(() => {
    if (!id) return
    adminApi.getExerciseById(id).then((data) => {
      if (!data) return
      setForm({
        name: data.name || '',
        description: data.description || '',
        difficulty: data.difficulty || '',
        equipment: data.equipment || '',
        instruction: data.instruction || '',
        safetyNotes: data.safetyNotes || '',
        commonMistakes: data.commonMistakes || '',
        tips: data.tips || '',
        imageUrl: data.imageUrl || '',
        videoUrl: data.videoUrl || '',
        defaultSets: data.defaultSets || 0,
        defaultReps: data.defaultReps || '',
        restTimeSeconds: data.restTimeSeconds || 0,
        muscleImpacts: data.muscleImpacts || [],
      })
    })
  }, [id])

  const update = (key, value) => setForm((current) => ({ ...current, [key]: value }))

  const addMuscleImpact = () => {
    setForm((current) => ({
      ...current,
      muscleImpacts: [...current.muscleImpacts, { muscleId: '', percentage: 0 }],
    }))
  }

  const removeMuscleImpact = (index) => {
    setForm((current) => ({
      ...current,
      muscleImpacts: current.muscleImpacts.filter((_, i) => i !== index),
    }))
  }

  const updateMuscleImpact = (index, key, value) => {
    setForm((current) => ({
      ...current,
      muscleImpacts: current.muscleImpacts.map((impact, i) =>
        i === index ? { ...impact, [key]: key === 'percentage' ? Number(value) : value } : impact
      ),
    }))
  }

  const submit = async (event) => {
    event.preventDefault()
    const nextErrors = {}
    if (!form.name.trim()) nextErrors.name = 'Exercise name is required'
    if (!form.muscleImpacts.length) nextErrors.muscleImpacts = 'At least one muscle group is required'
    setErrors(nextErrors)
    if (Object.keys(nextErrors).length) return

    await adminApi.saveExercise({
      name: form.name,
      description: form.description,
      difficulty: form.difficulty,
      equipment: form.equipment,
      instruction: form.instruction,
      safetyNotes: form.safetyNotes,
      commonMistakes: form.commonMistakes,
      tips: form.tips,
      imageUrl: form.imageUrl,
      videoUrl: form.videoUrl,
      defaultSets: Number(form.defaultSets),
      defaultReps: form.defaultReps,
      restTimeSeconds: Number(form.restTimeSeconds),
      muscleImpacts: form.muscleImpacts,
      ...(id && { id }),
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
          <FormInput label="Difficulty" as="select" value={form.difficulty} onChange={(e) => update('difficulty', e.target.value)} options={['Beginner', 'Intermediate', 'Advanced']} />
          <FormInput label="Equipment" value={form.equipment} onChange={(e) => update('equipment', e.target.value)} />
          <FormInput label="Default Sets" type="number" value={form.defaultSets} onChange={(e) => update('defaultSets', e.target.value)} />
          <FormInput label="Default Reps" value={form.defaultReps} onChange={(e) => update('defaultReps', e.target.value)} />
          <FormInput label="Rest Time (seconds)" type="number" value={form.restTimeSeconds} onChange={(e) => update('restTimeSeconds', e.target.value)} />
          <FormInput label="Image URL" value={form.imageUrl} onChange={(e) => update('imageUrl', e.target.value)} />
          <FormInput label="Video URL" value={form.videoUrl} onChange={(e) => update('videoUrl', e.target.value)} />
          <div className="md:col-span-2">
            <FormInput label="Description" as="textarea" rows="3" value={form.description} onChange={(e) => update('description', e.target.value)} />
          </div>
          <div className="md:col-span-2">
            <FormInput label="Instruction" as="textarea" rows="4" value={form.instruction} onChange={(e) => update('instruction', e.target.value)} error={errors.instruction} />
          </div>
          <div className="md:col-span-2">
            <FormInput label="Safety Notes" as="textarea" rows="3" value={form.safetyNotes} onChange={(e) => update('safetyNotes', e.target.value)} placeholder="Important cues, injury cautions, setup warnings..." />
          </div>
          <div className="md:col-span-2">
            <FormInput label="Common Mistakes" as="textarea" rows="3" value={form.commonMistakes} onChange={(e) => update('commonMistakes', e.target.value)} />
          </div>
          <div className="md:col-span-2">
            <FormInput label="Tips" as="textarea" rows="3" value={form.tips} onChange={(e) => update('tips', e.target.value)} />
          </div>
        </div>

        {/* Muscle Impacts Section */}
        <div className="mt-6 border-t pt-6">
          <div className="mb-4 flex items-center justify-between">
            <label className="text-sm font-semibold text-slate-950">Muscle Impacts</label>
            <button type="button" onClick={addMuscleImpact} className="btn-secondary flex items-center gap-2 text-sm">
              <Plus size={16} /> Add Muscle Group
            </button>
          </div>
          {errors.muscleImpacts && <p className="mb-3 text-sm text-red-600">{errors.muscleImpacts}</p>}
          
          <div className="space-y-3">
            {form.muscleImpacts.length === 0 ? (
              <p className="text-sm text-slate-500">No muscle groups added yet. Click "Add Muscle Group" to get started.</p>
            ) : (
              form.muscleImpacts.map((impact, index) => (
                <div key={index} className="flex gap-3 rounded-lg border border-slate-200 bg-slate-50 p-3">
                  <select
                    value={impact.muscleId}
                    onChange={(e) => updateMuscleImpact(index, 'muscleId', e.target.value)}
                    className="flex-1 rounded border border-slate-300 px-2 py-2 text-sm"
                  >
                    <option value="">Select muscle group</option>
                    {muscleOptions.map((muscle) => (
                      <option key={muscle.id || muscle.name} value={muscle.id || muscle.name}>
                        {muscle.name}
                      </option>
                    ))}
                  </select>
                  <input
                    type="number"
                    min="0"
                    max="100"
                    value={impact.percentage}
                    onChange={(e) => updateMuscleImpact(index, 'percentage', e.target.value)}
                    placeholder="Percentage"
                    className="w-24 rounded border border-slate-300 px-2 py-2 text-sm"
                  />
                  <span className="flex items-center text-sm font-medium text-slate-600">%</span>
                  <button
                    type="button"
                    onClick={() => removeMuscleImpact(index)}
                    className="rounded bg-red-100 p-2 text-red-600 hover:bg-red-200"
                  >
                    <Trash2 size={16} />
                  </button>
                </div>
              ))
            )}
          </div>
        </div>

        <div className="mt-6 flex justify-end">
          <button className="btn-primary" type="submit"><Save size={16} /> Save Exercise</button>
        </div>
      </div>
    </form>
  )
}
