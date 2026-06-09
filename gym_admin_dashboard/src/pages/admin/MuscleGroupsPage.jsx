import { Edit, Eye, Plus, Trash2 } from 'lucide-react'
import { useEffect, useState } from 'react'
import Badge from '../../components/common/Badge.jsx'
import ConfirmDialog from '../../components/common/ConfirmDialog.jsx'
import DataTable from '../../components/common/DataTable.jsx'
import FormInput from '../../components/common/FormInput.jsx'
import Modal from '../../components/common/Modal.jsx'
import { adminApi } from '../../services/adminApi.js'

const emptyForm = { name: '', category: '', description: '', imageUrl: '', status: 'Active' }

export default function MuscleGroupsPage() {
  const [rows, setRows] = useState([])
  const [loading, setLoading] = useState(true)
  const [formOpen, setFormOpen] = useState(false)
  const [detail, setDetail] = useState(null)
  const [deleteTarget, setDeleteTarget] = useState(null)
  const [form, setForm] = useState(emptyForm)

  useEffect(() => {
    adminApi.getMuscleGroups().then((data) => {
      setRows(data)
      setLoading(false)
    })
  }, [])

  const openForm = (row = null) => {
    setForm(row ?? emptyForm)
    setFormOpen(true)
  }

  const save = async () => {
    const saved = await adminApi.saveMuscleGroup(form)
    setRows((current) => form.id ? current.map((item) => item.id === form.id ? saved : item) : [saved, ...current])
    setFormOpen(false)
  }

  const remove = async () => {
    await adminApi.deleteMuscleGroup(deleteTarget.id)
    setRows((current) => current.filter((item) => item.id !== deleteTarget.id))
    setDeleteTarget(null)
  }

  const columns = [
    { key: 'name', header: 'Muscle Group Name', render: (row) => <span className="font-black text-slate-950">{row.name}</span> },
    { key: 'description', header: 'Description' },
    { key: 'status', header: 'Status', render: (row) => <Badge>{row.status}</Badge> },
    {
      key: 'actions',
      header: 'Actions',
      render: (row) => (
        <div className="flex flex-wrap gap-2">
          <button className="btn-secondary" onClick={() => setDetail(row)}><Eye size={15} /> View</button>
          <button className="btn-secondary" onClick={() => openForm(row)}><Edit size={15} /> Edit</button>
          <button className="btn-secondary" onClick={() => setDeleteTarget(row)}><Trash2 size={15} /> Delete</button>
        </div>
      ),
    },
  ]

  return (
    <div className="space-y-4">
      <div className="flex flex-col gap-3 rounded-lg border border-slate-200 bg-white p-5 shadow-sm sm:flex-row sm:items-center sm:justify-between">
        <div>
          <h2 className="text-lg font-black text-slate-950">Muscle Groups</h2>
          <p className="text-sm text-slate-500">Manage muscle taxonomy used by exercises and AI body checks.</p>
        </div>
        <button className="btn-primary" onClick={() => openForm()}><Plus size={16} /> Add Muscle Group</button>
      </div>
      <DataTable columns={columns} data={rows} loading={loading} />

      <Modal open={formOpen} title={form.id ? 'Edit Muscle Group' : 'Add Muscle Group'} onClose={() => setFormOpen(false)} footer={<div className="flex justify-end"><button className="btn-primary" onClick={save}>Save</button></div>}>
        <div className="grid gap-4">
          <FormInput label="Muscle Group Name" value={form.name} onChange={(e) => setForm({ ...form, name: e.target.value })} />
          <FormInput label="Image URL" value={form.imageUrl} onChange={(e) => setForm({ ...form, imageUrl: e.target.value })} />
          <FormInput label="Status" as="select" value={form.status} options={['Active', 'Hidden']} onChange={(e) => setForm({ ...form, status: e.target.value })} />
          <FormInput label="Category" value={form.category || form.description} onChange={(e) => setForm({ ...form, category: e.target.value, description: e.target.value })} />
        </div>
      </Modal>

      <Modal open={!!detail} title={detail?.name} onClose={() => setDetail(null)}>
        {detail ? (
          <div className="grid gap-4 md:grid-cols-[220px_1fr]">
            <img src={detail.imageUrl} alt={detail.name} className="h-48 w-full rounded-lg object-cover" />
            <div>
              <Badge>{detail.status}</Badge>
              <p className="mt-4 text-sm leading-6 text-slate-600">{detail.description}</p>
            </div>
          </div>
        ) : null}
      </Modal>

      <ConfirmDialog open={!!deleteTarget} title="Delete muscle group" message={`Delete ${deleteTarget?.name}?`} onCancel={() => setDeleteTarget(null)} onConfirm={remove} confirmText="Delete" />
    </div>
  )
}
