import { Edit, Eye, Plus, Trash2 } from 'lucide-react'
import { useEffect, useMemo, useState } from 'react'
import { Link } from 'react-router-dom'
import Badge from '../../components/common/Badge.jsx'
import ConfirmDialog from '../../components/common/ConfirmDialog.jsx'
import DataTable from '../../components/common/DataTable.jsx'
import Modal from '../../components/common/Modal.jsx'
import { adminApi } from '../../services/adminApi.js'

export default function ExercisesPage() {
  const [rows, setRows] = useState([])
  const [loading, setLoading] = useState(true)
  const [query, setQuery] = useState('')
  const [muscle, setMuscle] = useState('All')
  const [difficulty, setDifficulty] = useState('All')
  const [equipment, setEquipment] = useState('All')
  const [detail, setDetail] = useState(null)
  const [deleteTarget, setDeleteTarget] = useState(null)

  useEffect(() => {
    adminApi.getExercises().then((data) => {
      setRows(data)
      setLoading(false)
    })
  }, [])

  const filtered = useMemo(() => {
    return rows.filter((item) => {
      const text = `${item.name} ${item.description}`.toLowerCase()
      return (
        text.includes(query.toLowerCase()) &&
        (muscle === 'All' || item.mainMuscleGroup === muscle) &&
        (difficulty === 'All' || item.difficulty === difficulty) &&
        (equipment === 'All' || item.equipment === equipment)
      )
    })
  }, [rows, query, muscle, difficulty, equipment])

  const optionValues = (key) => ['All', ...new Set(rows.map((item) => item[key]))]

  const columns = [
    { key: 'name', header: 'Exercise Name', render: (row) => <span className="font-black text-slate-950">{row.name}</span> },
    { key: 'mainMuscleGroup', header: 'Main Muscle' },
    { key: 'difficulty', header: 'Difficulty' },
    { key: 'equipment', header: 'Equipment' },
    { key: 'defaultSets', header: 'Sets/Reps', render: (row) => `${row.defaultSets} x ${row.defaultReps}` },
    { key: 'status', header: 'Status', render: (row) => <Badge>{row.status}</Badge> },
    {
      key: 'actions',
      header: 'Actions',
      render: (row) => (
        <div className="flex flex-wrap gap-2">
          <button className="btn-secondary" onClick={() => setDetail(row)}><Eye size={15} /> View</button>
          <Link className="btn-secondary" to={`/admin/exercises/${row.id}`}><Edit size={15} /> Edit</Link>
          <button className="btn-secondary" onClick={() => setDeleteTarget(row)}><Trash2 size={15} /> Hide</button>
        </div>
      ),
    },
  ]

  const removeExercise = async () => {
    await adminApi.deleteExercise(deleteTarget.id)
    setRows((current) => current.filter((item) => item.id !== deleteTarget.id))
    setDeleteTarget(null)
  }

  return (
    <div className="space-y-4">
      <div className="flex flex-col gap-3 rounded-lg border border-slate-200 bg-white p-5 shadow-sm lg:flex-row lg:items-center lg:justify-between">
        <div>
          <h2 className="text-lg font-black text-slate-950">Exercise Library</h2>
          <p className="text-sm text-slate-500">Create, review and hide exercise content used by AI and routines.</p>
        </div>
        <Link className="btn-primary" to="/admin/exercises/new"><Plus size={16} /> Add Exercise</Link>
      </div>

      <div className="grid gap-3 rounded-lg border border-slate-200 bg-white p-4 shadow-sm md:grid-cols-4">
        <input value={query} onChange={(event) => setQuery(event.target.value)} placeholder="Search exercises" className="rounded-md border border-slate-200 px-3 py-2 text-sm outline-none focus:border-emerald-500" />
        <Filter value={muscle} onChange={setMuscle} options={optionValues('mainMuscleGroup')} />
        <Filter value={difficulty} onChange={setDifficulty} options={optionValues('difficulty')} />
        <Filter value={equipment} onChange={setEquipment} options={optionValues('equipment')} />
      </div>

      <DataTable columns={columns} data={filtered} loading={loading} />

      <Modal open={!!detail} title={detail?.name} onClose={() => setDetail(null)}>
        {detail ? (
          <div className="grid gap-5 lg:grid-cols-[220px_1fr]">
            <img src={detail.imageUrl} alt={detail.name} className="h-56 w-full rounded-lg object-cover" />
            <div className="space-y-4 text-sm text-slate-700">
              <p>{detail.description}</p>
              <DetailRow label="Instruction" value={detail.instruction} />
              <DetailRow label="Video URL" value={detail.videoUrl} />
              <DetailRow label="Rest Time" value={detail.restTime} />
              <div>
                <p className="mb-2 text-xs font-black uppercase text-slate-400">Muscle Impacts</p>
                <div className="space-y-2">
                  {detail.muscleImpacts.map((impact) => (
                    <div key={impact.muscle}>
                      <div className="mb-1 flex justify-between font-bold"><span>{impact.muscle}</span><span>{impact.percent}%</span></div>
                      <div className="h-2 rounded-full bg-slate-100"><div className="h-2 rounded-full bg-emerald-500" style={{ width: `${impact.percent}%` }} /></div>
                    </div>
                  ))}
                </div>
              </div>
            </div>
          </div>
        ) : null}
      </Modal>

      <ConfirmDialog
        open={!!deleteTarget}
        title="Hide exercise"
        message={`Hide ${deleteTarget?.name}? Admin can restore hidden content later when API is connected.`}
        confirmText="Hide"
        onCancel={() => setDeleteTarget(null)}
        onConfirm={removeExercise}
      />
    </div>
  )
}

function Filter({ value, onChange, options }) {
  return (
    <select value={value} onChange={(event) => onChange(event.target.value)} className="rounded-md border border-slate-200 px-3 py-2 text-sm outline-none focus:border-emerald-500">
      {options.map((option) => <option key={option}>{option}</option>)}
    </select>
  )
}

function DetailRow({ label, value }) {
  return (
    <div>
      <p className="text-xs font-black uppercase text-slate-400">{label}</p>
      <p className="mt-1 font-semibold text-slate-800">{value}</p>
    </div>
  )
}
