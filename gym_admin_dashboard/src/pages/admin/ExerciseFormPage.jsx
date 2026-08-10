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
  const [uploading, setUploading] = useState({ image: false, video: false })

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

  const uploadMedia = async (file, kind) => {
    if (!file) return
    setUploading((current) => ({ ...current, [kind]: true }))
    setErrors((current) => ({ ...current, [kind]: '' }))
    try {
      const result = await adminApi.uploadMedia(file)
      update(kind === 'image' ? 'imageUrl' : 'videoUrl', result.url)
    } catch (error) {
      setErrors((current) => ({ ...current, [kind]: error.message }))
    } finally {
      setUploading((current) => ({ ...current, [kind]: false }))
    }
  }

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
    if (!form.name.trim()) nextErrors.name = 'Vui lòng nhập tên bài tập'
    if (!form.muscleImpacts.length) nextErrors.muscleImpacts = 'Cần chọn ít nhất một nhóm cơ'
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
      <Link to="/admin/exercises" className="btn-secondary"><ArrowLeft size={16} /> Quay lại</Link>
      <div className="rounded-lg border border-slate-200 bg-white p-5 shadow-sm">
        <h2 className="text-lg font-black text-slate-950">{id ? 'Sửa bài tập' : 'Thêm bài tập'}</h2>
        <div className="mt-5 grid gap-4 md:grid-cols-2">
          <FormInput label="Tên bài tập" value={form.name} onChange={(e) => update('name', e.target.value)} error={errors.name} />
          <FormInput label="Độ khó" as="select" value={form.difficulty} onChange={(e) => update('difficulty', e.target.value)} options={['Beginner', 'Intermediate', 'Advanced']} />
          <FormInput label="Dụng cụ" value={form.equipment} onChange={(e) => update('equipment', e.target.value)} />
          <FormInput label="Số hiệp mặc định" type="number" value={form.defaultSets} onChange={(e) => update('defaultSets', e.target.value)} />
          <FormInput label="Số lần mặc định" value={form.defaultReps} onChange={(e) => update('defaultReps', e.target.value)} />
          <FormInput label="Thời gian nghỉ (giây)" type="number" value={form.restTimeSeconds} onChange={(e) => update('restTimeSeconds', e.target.value)} />
          <div>
            <label className="mb-1 block text-sm font-semibold text-slate-950">Hình ảnh bài tập</label>
            <input type="file" accept="image/jpeg,image/png,image/webp" disabled={uploading.image} onChange={(e) => uploadMedia(e.target.files?.[0], 'image')} className="w-full rounded border border-slate-300 px-3 py-2 text-sm" />
            {uploading.image && <p className="mt-1 text-sm text-slate-500">Đang tải ảnh lên...</p>}
            {errors.image && <p className="mt-1 text-sm text-red-600">{errors.image}</p>}
            {form.imageUrl && <img src={form.imageUrl} alt="Xem trước bài tập" className="mt-2 h-32 w-full rounded object-cover" />}
          </div>
          <div>
            <label className="mb-1 block text-sm font-semibold text-slate-950">Video bài tập</label>
            <input type="file" accept="video/mp4,video/quicktime,video/webm" disabled={uploading.video} onChange={(e) => uploadMedia(e.target.files?.[0], 'video')} className="w-full rounded border border-slate-300 px-3 py-2 text-sm" />
            {uploading.video && <p className="mt-1 text-sm text-slate-500">Đang tải video lên...</p>}
            {errors.video && <p className="mt-1 text-sm text-red-600">{errors.video}</p>}
            {form.videoUrl && <video src={form.videoUrl} controls className="mt-2 h-32 w-full rounded bg-black object-contain" />}
          </div>
          <div className="md:col-span-2">
            <FormInput label="Mô tả" as="textarea" rows="3" value={form.description} onChange={(e) => update('description', e.target.value)} />
          </div>
          <div className="md:col-span-2">
            <FormInput label="Hướng dẫn" as="textarea" rows="4" value={form.instruction} onChange={(e) => update('instruction', e.target.value)} error={errors.instruction} />
          </div>
          <div className="md:col-span-2">
            <FormInput label="Lưu ý an toàn" as="textarea" rows="3" value={form.safetyNotes} onChange={(e) => update('safetyNotes', e.target.value)} placeholder="Các lưu ý quan trọng, cảnh báo chấn thương, hướng dẫn tư thế..." />
          </div>
          <div className="md:col-span-2">
            <FormInput label="Lỗi thường gặp" as="textarea" rows="3" value={form.commonMistakes} onChange={(e) => update('commonMistakes', e.target.value)} />
          </div>
          <div className="md:col-span-2">
            <FormInput label="Mẹo tập" as="textarea" rows="3" value={form.tips} onChange={(e) => update('tips', e.target.value)} />
          </div>
        </div>

        {/* Muscle Impacts Section */}
        <div className="mt-6 border-t pt-6">
          <div className="mb-4 flex items-center justify-between">
            <label className="text-sm font-semibold text-slate-950">Mức độ tác động cơ</label>
            <button type="button" onClick={addMuscleImpact} className="btn-secondary flex items-center gap-2 text-sm">
              <Plus size={16} /> Thêm nhóm cơ
            </button>
          </div>
          {errors.muscleImpacts && <p className="mb-3 text-sm text-red-600">{errors.muscleImpacts}</p>}

          <div className="space-y-3">
            {form.muscleImpacts.length === 0 ? (
              <p className="text-sm text-slate-500">Chưa có nhóm cơ nào được thêm. Bấm "Thêm nhóm cơ" để bắt đầu.</p>
            ) : (
              form.muscleImpacts.map((impact, index) => (
                <div key={index} className="flex gap-3 rounded-lg border border-slate-200 bg-slate-50 p-3">
                  <select
                    value={impact.muscleId}
                    onChange={(e) => updateMuscleImpact(index, 'muscleId', e.target.value)}
                    className="flex-1 rounded border border-slate-300 px-2 py-2 text-sm"
                  >
                    <option value="">Chọn nhóm cơ</option>
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
                    placeholder="Tỷ lệ phần trăm"
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
          <button className="btn-primary" type="submit" disabled={uploading.image || uploading.video}><Save size={16} /> Lưu bài tập</button>
        </div>
      </div>
    </form>
  )
}
