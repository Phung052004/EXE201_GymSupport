import { Pencil, Plus, PowerOff, Trash2, Zap } from 'lucide-react'
import { useEffect, useState } from 'react'
import Badge from '../../components/common/Badge.jsx'
import ConfirmDialog from '../../components/common/ConfirmDialog.jsx'
import DataTable from '../../components/common/DataTable.jsx'
import Modal from '../../components/common/Modal.jsx'
import { adminApi } from '../../services/adminApi.js'

const EMPTY_FORM = { name: '', price: '', durationMonths: '1', isActive: true }

const fmtPrice = (price) => {
  if (!price && price !== 0) return 'N/A'
  return Number(price).toLocaleString('vi-VN') + ' đ'
}

export default function SubscriptionPlansPage() {
  const [plans, setPlans]         = useState([])
  const [loading, setLoading]     = useState(true)
  const [modal, setModal]         = useState(false)
  const [form, setForm]           = useState(EMPTY_FORM)
  const [saving, setSaving]       = useState(false)
  const [deleteTarget, setDeleteTarget] = useState(null)
  const [error, setError]         = useState('')

  const load = () => {
    setLoading(true)
    adminApi.getSubscriptionPlans().then((data) => {
      setPlans(Array.isArray(data) ? data : [])
      setLoading(false)
    })
  }

  useEffect(load, [])

  const openCreate = () => {
    setForm(EMPTY_FORM)
    setError('')
    setModal(true)
  }

  const openEdit = (plan) => {
    setForm({
      id: plan.id,
      name: plan.name ?? '',
      price: String(plan.price ?? ''),
      durationMonths: String(plan.durationMonths ?? 1),
      isActive: plan.isActive ?? true,
    })
    setError('')
    setModal(true)
  }

  const handleSave = async () => {
    if (!form.name.trim()) { setError('Tên gói không được để trống'); return }
    const price = parseFloat(form.price)
    const duration = parseInt(form.durationMonths, 10)
    if (isNaN(price) || price < 0) { setError('Giá không hợp lệ'); return }
    if (isNaN(duration) || duration < 1) { setError('Thời hạn phải ≥ 1 tháng'); return }

    setSaving(true)
    setError('')
    try {
      await adminApi.saveSubscriptionPlan({
        id: form.id,
        name: form.name.trim(),
        price,
        durationMonths: duration,
        isActive: form.isActive,
      })
      setModal(false)
      load()
    } catch (e) {
      setError(e.message || 'Có lỗi xảy ra')
    } finally {
      setSaving(false)
    }
  }

  const handleToggleStatus = async (plan) => {
    await adminApi.updateSubscriptionPlanStatus(plan.id, !plan.isActive)
    load()
  }

  const handleDelete = async () => {
    if (!deleteTarget) return
    await adminApi.deleteSubscriptionPlan(deleteTarget.id)
    setDeleteTarget(null)
    load()
  }

  const columns = [
    {
      key: 'name',
      header: 'Tên gói',
      render: (row) => <span className="font-bold text-slate-900">{row.name}</span>,
    },
    {
      key: 'price',
      header: 'Giá',
      render: (row) => <span className="font-semibold text-cyan-700">{fmtPrice(row.price)}</span>,
    },
    {
      key: 'durationMonths',
      header: 'Thời hạn',
      render: (row) => `${row.durationMonths} tháng`,
    },
    {
      key: 'isActive',
      header: 'Trạng thái',
      render: (row) => <Badge>{row.isActive ? 'Active' : 'Hidden'}</Badge>,
    },
    {
      key: 'actions',
      header: 'Thao tác',
      render: (row) => (
        <div className="flex flex-wrap gap-2">
          <button className="btn-secondary" onClick={() => openEdit(row)}>
            <Pencil size={14} /> Sửa
          </button>
          <button
            className="btn-secondary"
            title={row.isActive ? 'Vô hiệu hoá' : 'Kích hoạt'}
            onClick={() => handleToggleStatus(row)}
          >
            {row.isActive ? <PowerOff size={14} /> : <Zap size={14} />}
            {row.isActive ? 'Tắt' : 'Bật'}
          </button>
          <button
            className="btn-secondary !text-rose-600 hover:!bg-rose-50"
            onClick={() => setDeleteTarget(row)}
          >
            <Trash2 size={14} /> Xoá
          </button>
        </div>
      ),
    },
  ]

  return (
    <div className="space-y-4">
      {/* Header */}
      <div className="flex items-center justify-between rounded-lg border border-slate-200 bg-white p-5 shadow-sm">
        <div>
          <h2 className="text-lg font-black text-slate-950">Gói Subscription</h2>
          <p className="mt-1 text-sm text-slate-500">Tạo, chỉnh sửa và quản lý các gói dịch vụ.</p>
        </div>
        <button className="btn-primary flex items-center gap-2" onClick={openCreate}>
          <Plus size={16} /> Tạo gói mới
        </button>
      </div>

      <DataTable columns={columns} data={plans} loading={loading} />

      {/* Create / Edit modal */}
      <Modal
        open={modal}
        title={form.id ? 'Chỉnh sửa gói' : 'Tạo gói mới'}
        onClose={() => setModal(false)}
        footer={
          <div className="flex justify-end gap-3">
            <button className="btn-secondary" onClick={() => setModal(false)} disabled={saving}>
              Huỷ
            </button>
            <button className="btn-primary" onClick={handleSave} disabled={saving}>
              {saving ? 'Đang lưu…' : form.id ? 'Lưu thay đổi' : 'Tạo gói'}
            </button>
          </div>
        }
      >
        <div className="space-y-4">
          {error && (
            <div className="rounded-md bg-rose-50 px-4 py-2 text-sm font-medium text-rose-700 ring-1 ring-rose-200">
              {error}
            </div>
          )}

          <div>
            <label className="mb-1.5 block text-sm font-semibold text-slate-700">Tên gói *</label>
            <input
              className="w-full rounded-md border border-slate-200 bg-white px-3 py-2 text-sm text-slate-900 outline-none transition focus:border-cyan-500 focus:ring-2 focus:ring-cyan-100"
              placeholder="vd. Premium 1 tháng"
              value={form.name}
              onChange={(e) => setForm((f) => ({ ...f, name: e.target.value }))}
            />
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="mb-1.5 block text-sm font-semibold text-slate-700">Giá (VND) *</label>
              <input
                className="w-full rounded-md border border-slate-200 bg-white px-3 py-2 text-sm text-slate-900 outline-none transition focus:border-cyan-500 focus:ring-2 focus:ring-cyan-100"
                type="number"
                min="0"
                placeholder="vd. 99000"
                value={form.price}
                onChange={(e) => setForm((f) => ({ ...f, price: e.target.value }))}
              />
            </div>
            <div>
              <label className="mb-1.5 block text-sm font-semibold text-slate-700">Thời hạn (tháng) *</label>
              <input
                className="w-full rounded-md border border-slate-200 bg-white px-3 py-2 text-sm text-slate-900 outline-none transition focus:border-cyan-500 focus:ring-2 focus:ring-cyan-100"
                type="number"
                min="1"
                placeholder="vd. 1"
                value={form.durationMonths}
                onChange={(e) => setForm((f) => ({ ...f, durationMonths: e.target.value }))}
              />
            </div>
          </div>

          <div className="flex items-center gap-3">
            <label className="relative inline-flex cursor-pointer items-center">
              <input
                type="checkbox"
                className="peer sr-only"
                checked={form.isActive}
                onChange={(e) => setForm((f) => ({ ...f, isActive: e.target.checked }))}
              />
              <div className="peer h-6 w-11 rounded-full bg-slate-200 transition peer-checked:bg-cyan-500 after:absolute after:left-[2px] after:top-[2px] after:h-5 after:w-5 after:rounded-full after:bg-white after:transition after:content-[''] peer-checked:after:translate-x-full" />
            </label>
            <span className="text-sm font-semibold text-slate-700">
              {form.isActive ? 'Đang hoạt động' : 'Không hoạt động'}
            </span>
          </div>
        </div>
      </Modal>

      {/* Delete confirm */}
      <ConfirmDialog
        open={!!deleteTarget}
        title="Xoá gói subscription?"
        message={`Bạn có chắc muốn xoá gói "${deleteTarget?.name}"? Hành động này không thể hoàn tác.`}
        confirmText="Xoá"
        onConfirm={handleDelete}
        onCancel={() => setDeleteTarget(null)}
      />
    </div>
  )
}
