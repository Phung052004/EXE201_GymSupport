import { CheckCircle2, Eye, Trash2 } from 'lucide-react'
import { useEffect, useState } from 'react'
import Badge from '../../components/common/Badge.jsx'
import ConfirmDialog from '../../components/common/ConfirmDialog.jsx'
import DataTable from '../../components/common/DataTable.jsx'
import Modal from '../../components/common/Modal.jsx'
import { adminApi } from '../../services/adminApi.js'

export default function BodyChecksPage() {
  const [rows, setRows] = useState([])
  const [loading, setLoading] = useState(true)
  const [detail, setDetail] = useState(null)
  const [deleteTarget, setDeleteTarget] = useState(null)

  useEffect(() => {
    adminApi.getBodyChecks().then((data) => {
      setRows(data)
      setLoading(false)
    })
  }, [])

  const review = async (row) => {
    await adminApi.reviewBodyCheck(row.id)
    setRows((current) => current.map((item) => item.id === row.id ? { ...item, status: 'Reviewed' } : item))
    setDetail((current) => current?.id === row.id ? { ...current, status: 'Reviewed' } : current)
  }

  const remove = async () => {
    await adminApi.deleteBodyCheck(deleteTarget.id)
    setRows((current) => current.filter((item) => item.id !== deleteTarget.id))
    setDeleteTarget(null)
    setDetail(null)
  }

  const columns = [
    {
      key: 'image',
      header: 'Image',
      render: (row) => <img src={row.image} alt={row.user} className="h-14 w-20 rounded-md object-cover" />,
    },
    { key: 'user', header: 'User', render: (row) => <span className="font-black text-slate-950">{row.user}</span> },
    { key: 'aiResultSummary', header: 'AI Result Summary' },
    { key: 'status', header: 'Status', render: (row) => <Badge>{row.status}</Badge> },
    { key: 'createdDate', header: 'Created' },
    {
      key: 'actions',
      header: 'Actions',
      render: (row) => (
        <div className="flex flex-wrap gap-2">
          <button className="btn-secondary" onClick={() => setDetail(row)}><Eye size={15} /> View</button>
          <button className="btn-secondary" onClick={() => review(row)}><CheckCircle2 size={15} /> Reviewed</button>
          <button className="btn-secondary" onClick={() => setDeleteTarget(row)}><Trash2 size={15} /> Delete</button>
        </div>
      ),
    },
  ]

  return (
    <div className="space-y-4">
      <div className="rounded-lg border border-slate-200 bg-white p-5 shadow-sm">
        <h2 className="text-lg font-black text-slate-950">Body Checks</h2>
        <p className="text-sm text-slate-500">Monitor uploaded scan images, AI summaries and suggested training focus.</p>
      </div>

      <DataTable columns={columns} data={rows} loading={loading} />

      <Modal open={!!detail} title="Body Check Detail" onClose={() => setDetail(null)}>
        {detail ? (
          <div className="grid gap-5 lg:grid-cols-[280px_1fr]">
            <img src={detail.image} alt={detail.user} className="h-72 w-full rounded-lg object-cover" />
            <div className="space-y-4">
              <div className="flex flex-wrap items-center justify-between gap-3">
                <div>
                  <p className="text-xs font-bold uppercase text-slate-500">User</p>
                  <h3 className="text-xl font-black text-slate-950">{detail.user}</h3>
                </div>
                <Badge>{detail.status}</Badge>
              </div>
              <p className="rounded-lg border border-amber-200 bg-amber-50 p-3 text-sm font-semibold leading-6 text-amber-800">
                Body scan data should be reviewed as fitness guidance only. Escalate medical concerns outside the admin workflow.
              </p>
              <div>
                <h4 className="text-sm font-black text-slate-950">AI Result</h4>
                <p className="mt-2 text-sm leading-6 text-slate-600">{detail.aiResultSummary}</p>
              </div>
              <div>
                <h4 className="text-sm font-black text-slate-950">Suggested Muscle Groups</h4>
                <div className="mt-2 flex flex-wrap gap-2">
                  {detail.suggestedMuscleGroups.map((item) => <Badge key={item}>{item}</Badge>)}
                </div>
              </div>
              <div>
                <h4 className="text-sm font-black text-slate-950">Suggested Exercises</h4>
                <div className="mt-2 grid gap-2 sm:grid-cols-2">
                  {detail.suggestedExercises.map((item) => (
                    <div key={item} className="rounded-md bg-slate-50 px-3 py-2 text-sm font-semibold text-slate-700">{item}</div>
                  ))}
                </div>
              </div>
              <div className="flex justify-end">
                <button className="btn-primary" onClick={() => review(detail)}><CheckCircle2 size={16} /> Mark Reviewed</button>
              </div>
            </div>
          </div>
        ) : null}
      </Modal>

      <ConfirmDialog open={!!deleteTarget} title="Delete body check" message={`Delete body check for ${deleteTarget?.user}?`} onCancel={() => setDeleteTarget(null)} onConfirm={remove} confirmText="Delete" />
    </div>
  )
}
