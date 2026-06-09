import { Eye, Trash2 } from 'lucide-react'
import { useEffect, useMemo, useState } from 'react'
import Badge from '../../components/common/Badge.jsx'
import ConfirmDialog from '../../components/common/ConfirmDialog.jsx'
import DataTable from '../../components/common/DataTable.jsx'
import FormInput from '../../components/common/FormInput.jsx'
import Modal from '../../components/common/Modal.jsx'
import { adminApi } from '../../services/adminApi.js'

export default function FeedbacksPage() {
  const [rows, setRows] = useState([])
  const [loading, setLoading] = useState(true)
  const [statusFilter, setStatusFilter] = useState('All')
  const [detail, setDetail] = useState(null)
  const [deleteTarget, setDeleteTarget] = useState(null)

  useEffect(() => {
    adminApi.getFeedbacks().then((data) => {
      setRows(data)
      setLoading(false)
    })
  }, [])

  const filteredRows = useMemo(() => {
    if (statusFilter === 'All') return rows
    return rows.filter((item) => item.status === statusFilter)
  }, [rows, statusFilter])

  const updateStatus = async (row, status) => {
    await adminApi.updateFeedbackStatus(row.id, status)
    setRows((current) => current.map((item) => item.id === row.id ? { ...item, status } : item))
    setDetail((current) => current?.id === row.id ? { ...current, status } : current)
  }

  const remove = async () => {
    await adminApi.deleteFeedback(deleteTarget.id)
    setRows((current) => current.filter((item) => item.id !== deleteTarget.id))
    setDeleteTarget(null)
    setDetail(null)
  }

  const columns = [
    { key: 'user', header: 'User', render: (row) => <span className="font-black text-slate-950">{row.user}</span> },
    { key: 'type', header: 'Type' },
    { key: 'relatedFeature', header: 'Feature' },
    { key: 'status', header: 'Status', render: (row) => <Badge>{row.status}</Badge> },
    { key: 'createdDate', header: 'Created' },
    {
      key: 'actions',
      header: 'Actions',
      render: (row) => (
        <div className="flex flex-wrap gap-2">
          <button className="btn-secondary" onClick={() => setDetail(row)}><Eye size={15} /> View</button>
          <button className="btn-secondary" onClick={() => setDeleteTarget(row)}><Trash2 size={15} /> Delete</button>
        </div>
      ),
    },
  ]

  return (
    <div className="space-y-4">
      <div className="grid gap-4 rounded-lg border border-slate-200 bg-white p-5 shadow-sm lg:grid-cols-[1fr_220px] lg:items-end">
        <div>
          <h2 className="text-lg font-black text-slate-950">Feedbacks</h2>
          <p className="text-sm text-slate-500">Track app issues, AI reports and content corrections from users.</p>
        </div>
        <FormInput label="Status Filter" as="select" value={statusFilter} options={['All', 'Pending', 'In Progress', 'Resolved']} onChange={(event) => setStatusFilter(event.target.value)} />
      </div>

      <DataTable columns={columns} data={filteredRows} loading={loading} />

      <Modal open={!!detail} title="Feedback Detail" onClose={() => setDetail(null)}>
        {detail ? (
          <div className="space-y-5">
            <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-4">
              <div className="rounded-lg bg-slate-50 p-3">
                <p className="text-xs font-bold uppercase text-slate-500">User</p>
                <p className="mt-1 font-black text-slate-950">{detail.user}</p>
              </div>
              <div className="rounded-lg bg-slate-50 p-3">
                <p className="text-xs font-bold uppercase text-slate-500">Type</p>
                <p className="mt-1 font-black text-slate-950">{detail.type}</p>
              </div>
              <div className="rounded-lg bg-slate-50 p-3">
                <p className="text-xs font-bold uppercase text-slate-500">Feature</p>
                <p className="mt-1 font-black text-slate-950">{detail.relatedFeature}</p>
              </div>
              <div className="rounded-lg bg-slate-50 p-3">
                <p className="text-xs font-bold uppercase text-slate-500">Status</p>
                <div className="mt-1"><Badge>{detail.status}</Badge></div>
              </div>
            </div>

            <div>
              <h3 className="text-sm font-black text-slate-950">Message</h3>
              <p className="mt-2 rounded-lg border border-slate-200 bg-white p-4 text-sm leading-6 text-slate-600">{detail.message}</p>
            </div>
            <div>
              <h3 className="text-sm font-black text-slate-950">Reply Note</h3>
              <p className="mt-2 rounded-lg bg-slate-50 p-4 text-sm leading-6 text-slate-600">{detail.replyNote || 'No reply note yet.'}</p>
            </div>
            <div className="flex flex-col gap-3 sm:flex-row sm:items-end sm:justify-between">
              <div className="w-full sm:max-w-xs">
                <FormInput label="Update Status" as="select" value={detail.status} options={['Pending', 'In Progress', 'Resolved']} onChange={(event) => updateStatus(detail, event.target.value)} />
              </div>
              <button className="btn-danger" onClick={() => setDeleteTarget(detail)}><Trash2 size={16} /> Delete Feedback</button>
            </div>
          </div>
        ) : null}
      </Modal>

      <ConfirmDialog open={!!deleteTarget} title="Delete feedback" message={`Delete feedback from ${deleteTarget?.user}?`} onCancel={() => setDeleteTarget(null)} onConfirm={remove} confirmText="Delete" />
    </div>
  )
}
