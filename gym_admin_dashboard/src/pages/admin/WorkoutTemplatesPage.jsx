import { Edit, Eye, Plus, Trash2 } from 'lucide-react'
import { useEffect, useState } from 'react'
import { Link } from 'react-router-dom'
import Badge from '../../components/common/Badge.jsx'
import ConfirmDialog from '../../components/common/ConfirmDialog.jsx'
import DataTable from '../../components/common/DataTable.jsx'
import Modal from '../../components/common/Modal.jsx'
import { adminApi } from '../../services/adminApi.js'

export default function WorkoutTemplatesPage() {
  const [rows, setRows] = useState([])
  const [loading, setLoading] = useState(true)
  const [detail, setDetail] = useState(null)
  const [deleteTarget, setDeleteTarget] = useState(null)

  useEffect(() => {
    adminApi.getWorkoutTemplates().then((data) => {
      setRows(data)
      setLoading(false)
    })
  }, [])

  const remove = async () => {
    await adminApi.deleteWorkoutTemplate(deleteTarget.id)
    setRows((current) => current.filter((item) => item.id !== deleteTarget.id))
    setDeleteTarget(null)
  }

  const columns = [
    { key: 'name', header: 'Template Name', render: (row) => <span className="font-black text-slate-950">{row.name}</span> },
    { key: 'goal', header: 'Goal' },
    { key: 'experienceLevel', header: 'Experience Level' },
    { key: 'daysPerWeek', header: 'Days / Week' },
    { key: 'status', header: 'Status', render: (row) => <Badge>{row.status}</Badge> },
    {
      key: 'actions',
      header: 'Actions',
      render: (row) => (
        <div className="flex flex-wrap gap-2">
          <button className="btn-secondary" onClick={() => setDetail(row)}><Eye size={15} /> View</button>
          <Link className="btn-secondary" to={`/admin/workout-templates/${row.id}`}><Edit size={15} /> Edit</Link>
          <button className="btn-secondary" onClick={() => setDeleteTarget(row)}><Trash2 size={15} /> Hide</button>
        </div>
      ),
    },
  ]

  return (
    <div className="space-y-4">
      <div className="flex flex-col gap-3 rounded-lg border border-slate-200 bg-white p-5 shadow-sm lg:flex-row lg:items-center lg:justify-between">
        <div>
          <h2 className="text-lg font-black text-slate-950">Workout Templates</h2>
          <p className="text-sm text-slate-500">Manage reusable plans for goals, levels and weekly splits.</p>
        </div>
        <Link className="btn-primary" to="/admin/workout-templates/new"><Plus size={16} /> Create Template</Link>
      </div>
      <DataTable columns={columns} data={rows} loading={loading} />

      <Modal open={!!detail} title={detail?.name} onClose={() => setDetail(null)}>
        {detail ? (
          <div className="space-y-5">
            <p className="text-sm leading-6 text-slate-600">{detail.description}</p>
            {detail.workoutDays.map((day) => (
              <div key={day.dayName} className="rounded-lg border border-slate-200 p-4">
                <h3 className="font-black text-slate-950">{day.dayName}</h3>
                <p className="mt-1 text-sm font-semibold text-emerald-700">{day.targetMuscleGroups.join(' + ')}</p>
                <div className="mt-3 space-y-2">
                  {day.exercises.map((exercise) => (
                    <div key={`${day.dayName}-${exercise.exercise}`} className="rounded-md bg-slate-50 px-3 py-2 text-sm">
                      <span className="font-bold text-slate-900">{exercise.exercise}</span>
                      <span className="text-slate-500"> - {exercise.sets} sets x {exercise.reps}, rest {exercise.restTime}</span>
                    </div>
                  ))}
                </div>
              </div>
            ))}
          </div>
        ) : null}
      </Modal>

      <ConfirmDialog open={!!deleteTarget} title="Hide template" message={`Hide ${deleteTarget?.name}?`} onCancel={() => setDeleteTarget(null)} onConfirm={remove} confirmText="Hide" />
    </div>
  )
}
