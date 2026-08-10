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
    { key: 'user', header: 'Người dùng', render: (row) => <span className="font-black text-slate-950">{row.user}</span> },
    { key: 'type', header: 'Loại' },
    { key: 'relatedFeature', header: 'Tính năng' },
    { key: 'status', header: 'Trạng thái', render: (row) => <Badge>{row.status}</Badge> },
    { key: 'createdDate', header: 'Ngày tạo' },
    {
      key: 'actions',
      header: 'Thao tác',
      render: (row) => (
        <div className="flex flex-wrap gap-2">
          <button className="btn-secondary" onClick={() => setDetail(row)}><Eye size={15} /> Xem</button>
          <button className="btn-secondary" onClick={() => setDeleteTarget(row)}><Trash2 size={15} /> Xóa</button>
        </div>
      ),
    },
  ]

  return (
    <div className="space-y-4">
      <div className="grid gap-4 rounded-lg border border-slate-200 bg-white p-5 shadow-sm lg:grid-cols-[1fr_220px] lg:items-end">
        <div>
          <h2 className="text-lg font-black text-slate-950">Phản hồi</h2>
          <p className="text-sm text-slate-500">Theo dõi lỗi ứng dụng, báo cáo AI và các phản ánh nội dung từ người dùng.</p>
        </div>
        <FormInput label="Lọc theo trạng thái" as="select" value={statusFilter} options={[{ value: 'All', label: 'Tất cả' }, { value: 'Pending', label: 'Đang chờ' }, { value: 'In Progress', label: 'Đang xử lý' }, { value: 'Resolved', label: 'Đã xử lý' }]} onChange={(event) => setStatusFilter(event.target.value)} />
      </div>

      <DataTable columns={columns} data={filteredRows} loading={loading} />

      <Modal open={!!detail} title="Chi tiết phản hồi" onClose={() => setDetail(null)}>
        {detail ? (
          <div className="space-y-5">
            <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-4">
              <div className="rounded-lg bg-slate-50 p-3">
                <p className="text-xs font-bold uppercase text-slate-500">Người dùng</p>
                <p className="mt-1 font-black text-slate-950">{detail.user}</p>
              </div>
              <div className="rounded-lg bg-slate-50 p-3">
                <p className="text-xs font-bold uppercase text-slate-500">Loại</p>
                <p className="mt-1 font-black text-slate-950">{detail.type}</p>
              </div>
              <div className="rounded-lg bg-slate-50 p-3">
                <p className="text-xs font-bold uppercase text-slate-500">Tính năng</p>
                <p className="mt-1 font-black text-slate-950">{detail.relatedFeature}</p>
              </div>
              <div className="rounded-lg bg-slate-50 p-3">
                <p className="text-xs font-bold uppercase text-slate-500">Trạng thái</p>
                <div className="mt-1"><Badge>{detail.status}</Badge></div>
              </div>
            </div>

            <div>
              <h3 className="text-sm font-black text-slate-950">Nội dung</h3>
              <p className="mt-2 rounded-lg border border-slate-200 bg-white p-4 text-sm leading-6 text-slate-600">{detail.message}</p>
            </div>
            <div>
              <h3 className="text-sm font-black text-slate-950">Ghi chú phản hồi</h3>
              <p className="mt-2 rounded-lg bg-slate-50 p-4 text-sm leading-6 text-slate-600">{detail.replyNote || 'Chưa có ghi chú phản hồi.'}</p>
            </div>
            <div className="flex flex-col gap-3 sm:flex-row sm:items-end sm:justify-between">
              <div className="w-full sm:max-w-xs">
                <FormInput label="Cập nhật trạng thái" as="select" value={detail.status} options={[{ value: 'Pending', label: 'Đang chờ' }, { value: 'In Progress', label: 'Đang xử lý' }, { value: 'Resolved', label: 'Đã xử lý' }]} onChange={(event) => updateStatus(detail, event.target.value)} />
              </div>
              <button className="btn-danger" onClick={() => setDeleteTarget(detail)}><Trash2 size={16} /> Xóa phản hồi</button>
            </div>
          </div>
        ) : null}
      </Modal>

      <ConfirmDialog open={!!deleteTarget} title="Xóa phản hồi" message={`Xóa phản hồi từ ${deleteTarget?.user}?`} onCancel={() => setDeleteTarget(null)} onConfirm={remove} confirmText="Xóa" />
    </div>
  )
}
