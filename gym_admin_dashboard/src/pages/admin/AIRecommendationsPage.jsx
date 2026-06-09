import { CheckCircle2, Eye, ThumbsDown, Trash2 } from 'lucide-react'
import { useEffect, useMemo, useState } from 'react'
import Badge from '../../components/common/Badge.jsx'
import ConfirmDialog from '../../components/common/ConfirmDialog.jsx'
import DataTable from '../../components/common/DataTable.jsx'
import FormInput from '../../components/common/FormInput.jsx'
import Modal from '../../components/common/Modal.jsx'
import { adminApi } from '../../services/adminApi.js'

export default function AIRecommendationsPage() {
  const [rows, setRows] = useState([])
  const [loading, setLoading] = useState(true)
  const [statusFilter, setStatusFilter] = useState('All')
  const [detail, setDetail] = useState(null)
  const [deleteTarget, setDeleteTarget] = useState(null)

  useEffect(() => {
    adminApi.getAIRecommendations().then((data) => {
      setRows(data)
      setLoading(false)
    })
  }, [])

  const filteredRows = useMemo(() => {
    if (statusFilter === 'All') return rows
    return rows.filter((item) => item.status === statusFilter)
  }, [rows, statusFilter])

  const review = async (row, status) => {
    await adminApi.reviewAIRecommendation(row.id, status)
    setRows((current) => current.map((item) => item.id === row.id ? { ...item, status } : item))
    setDetail((current) => current?.id === row.id ? { ...current, status } : current)
  }

  const remove = async () => {
    await adminApi.deleteAIRecommendation(deleteTarget.id)
    setRows((current) => current.filter((item) => item.id !== deleteTarget.id))
    setDeleteTarget(null)
    setDetail(null)
  }

  const columns = [
    { key: 'user', header: 'User', render: (row) => <span className="font-black text-slate-950">{row.user}</span> },
    { key: 'goal', header: 'Goal' },
    { key: 'experienceLevel', header: 'Level' },
    { key: 'type', header: 'Type' },
    { key: 'status', header: 'Status', render: (row) => <Badge>{row.status}</Badge> },
    { key: 'createdDate', header: 'Created' },
    {
      key: 'actions',
      header: 'Actions',
      render: (row) => (
        <div className="flex flex-wrap gap-2">
          <button className="btn-secondary" onClick={() => setDetail(row)}><Eye size={15} /> View</button>
          <button className="btn-secondary" onClick={() => review(row, 'Good')}><CheckCircle2 size={15} /> Good</button>
          <button className="btn-secondary" onClick={() => review(row, 'Bad')}><ThumbsDown size={15} /> Bad</button>
          <button className="btn-secondary" onClick={() => setDeleteTarget(row)}><Trash2 size={15} /> Delete</button>
        </div>
      ),
    },
  ]

  return (
    <div className="space-y-4">
      <div className="grid gap-4 rounded-lg border border-slate-200 bg-white p-5 shadow-sm lg:grid-cols-[1fr_220px] lg:items-end">
        <div>
          <h2 className="text-lg font-black text-slate-950">AI Recommendations</h2>
          <p className="text-sm text-slate-500">Review generated plans, nutrition guidance and body-check responses.</p>
        </div>
        <FormInput label="Status Filter" as="select" value={statusFilter} options={['All', 'Pending', 'Good', 'Bad']} onChange={(event) => setStatusFilter(event.target.value)} />
      </div>

      <DataTable columns={columns} data={filteredRows} loading={loading} />

      <Modal open={!!detail} title="AI Recommendation Detail" onClose={() => setDetail(null)}>
        {detail ? (
          <div className="space-y-5">
            <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-4">
              <div className="rounded-lg bg-slate-50 p-3">
                <p className="text-xs font-bold uppercase text-slate-500">User</p>
                <p className="mt-1 font-black text-slate-950">{detail.user}</p>
              </div>
              <div className="rounded-lg bg-slate-50 p-3">
                <p className="text-xs font-bold uppercase text-slate-500">Goal</p>
                <p className="mt-1 font-black text-slate-950">{detail.goal}</p>
              </div>
              <div className="rounded-lg bg-slate-50 p-3">
                <p className="text-xs font-bold uppercase text-slate-500">Level</p>
                <p className="mt-1 font-black text-slate-950">{detail.experienceLevel}</p>
              </div>
              <div className="rounded-lg bg-slate-50 p-3">
                <p className="text-xs font-bold uppercase text-slate-500">Status</p>
                <div className="mt-1"><Badge>{detail.status}</Badge></div>
              </div>
            </div>

            <div>
              <h3 className="text-sm font-black text-slate-950">Input</h3>
              <p className="mt-2 rounded-lg border border-slate-200 bg-white p-4 text-sm leading-6 text-slate-600">{detail.inputSummary}</p>
            </div>
            <div>
              <h3 className="text-sm font-black text-slate-950">AI Output</h3>
              <p className="mt-2 rounded-lg border border-slate-200 bg-white p-4 text-sm leading-6 text-slate-600">{detail.outputSummary}</p>
            </div>
            <div>
              <h3 className="text-sm font-black text-slate-950">Admin Review Note</h3>
              <p className="mt-2 rounded-lg bg-slate-50 p-4 text-sm leading-6 text-slate-600">{detail.adminReviewNote || 'No note yet.'}</p>
            </div>

            <div className="flex flex-wrap justify-end gap-2">
              <button className="btn-secondary" onClick={() => review(detail, 'Good')}><CheckCircle2 size={16} /> Mark Good</button>
              <button className="btn-secondary" onClick={() => review(detail, 'Bad')}><ThumbsDown size={16} /> Mark Bad</button>
            </div>
          </div>
        ) : null}
      </Modal>

      <ConfirmDialog open={!!deleteTarget} title="Delete AI record" message={`Delete recommendation for ${deleteTarget?.user}?`} onCancel={() => setDeleteTarget(null)} onConfirm={remove} confirmText="Delete" />
    </div>
  )
}
