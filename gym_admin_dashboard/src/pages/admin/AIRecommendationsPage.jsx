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
    { key: 'user', header: 'Người dùng', render: (row) => <span className="font-black text-slate-950">{row.user}</span> },
    { key: 'goal', header: 'Mục tiêu' },
    { key: 'experienceLevel', header: 'Trình độ' },
    { key: 'type', header: 'Loại' },
    { key: 'status', header: 'Trạng thái', render: (row) => <Badge>{row.status}</Badge> },
    { key: 'createdDate', header: 'Ngày tạo' },
    {
      key: 'actions',
      header: 'Thao tác',
      render: (row) => (
        <div className="flex flex-wrap gap-2">
          <button className="btn-secondary" onClick={() => setDetail(row)}><Eye size={15} /> Xem</button>
          <button className="btn-secondary" onClick={() => review(row, 'Good')}><CheckCircle2 size={15} /> Tốt</button>
          <button className="btn-secondary" onClick={() => review(row, 'Bad')}><ThumbsDown size={15} /> Kém</button>
          <button className="btn-secondary" onClick={() => setDeleteTarget(row)}><Trash2 size={15} /> Xóa</button>
        </div>
      ),
    },
  ]

  return (
    <div className="space-y-4">
      <div className="grid gap-4 rounded-lg border border-slate-200 bg-white p-5 shadow-sm lg:grid-cols-[1fr_220px] lg:items-end">
        <div>
          <h2 className="text-lg font-black text-slate-950">Đề xuất AI</h2>
          <p className="text-sm text-slate-500">Xem lại các chương trình được tạo, hướng dẫn dinh dưỡng và phản hồi kiểm tra vóc dáng.</p>
        </div>
        <FormInput label="Lọc theo trạng thái" as="select" value={statusFilter} options={[{ value: 'All', label: 'Tất cả' }, { value: 'Pending', label: 'Đang chờ' }, { value: 'Good', label: 'Tốt' }, { value: 'Bad', label: 'Kém' }]} onChange={(event) => setStatusFilter(event.target.value)} />
      </div>

      <DataTable columns={columns} data={filteredRows} loading={loading} />

      <Modal open={!!detail} title="Chi tiết đề xuất AI" onClose={() => setDetail(null)}>
        {detail ? (
          <div className="space-y-5">
            <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-4">
              <div className="rounded-lg bg-slate-50 p-3">
                <p className="text-xs font-bold uppercase text-slate-500">Người dùng</p>
                <p className="mt-1 font-black text-slate-950">{detail.user}</p>
              </div>
              <div className="rounded-lg bg-slate-50 p-3">
                <p className="text-xs font-bold uppercase text-slate-500">Mục tiêu</p>
                <p className="mt-1 font-black text-slate-950">{detail.goal}</p>
              </div>
              <div className="rounded-lg bg-slate-50 p-3">
                <p className="text-xs font-bold uppercase text-slate-500">Trình độ</p>
                <p className="mt-1 font-black text-slate-950">{detail.experienceLevel}</p>
              </div>
              <div className="rounded-lg bg-slate-50 p-3">
                <p className="text-xs font-bold uppercase text-slate-500">Trạng thái</p>
                <div className="mt-1"><Badge>{detail.status}</Badge></div>
              </div>
            </div>

            <div>
              <h3 className="text-sm font-black text-slate-950">Dữ liệu đầu vào</h3>
              <p className="mt-2 rounded-lg border border-slate-200 bg-white p-4 text-sm leading-6 text-slate-600">{detail.inputSummary}</p>
            </div>
            <div>
              <h3 className="text-sm font-black text-slate-950">Kết quả AI</h3>
              <p className="mt-2 rounded-lg border border-slate-200 bg-white p-4 text-sm leading-6 text-slate-600">{detail.outputSummary}</p>
            </div>
            <div>
              <h3 className="text-sm font-black text-slate-950">Ghi chú của quản trị viên</h3>
              <p className="mt-2 rounded-lg bg-slate-50 p-4 text-sm leading-6 text-slate-600">{detail.adminReviewNote || 'Chưa có ghi chú.'}</p>
            </div>

            <div className="flex flex-wrap justify-end gap-2">
              <button className="btn-secondary" onClick={() => review(detail, 'Good')}><CheckCircle2 size={16} /> Đánh dấu Tốt</button>
              <button className="btn-secondary" onClick={() => review(detail, 'Bad')}><ThumbsDown size={16} /> Đánh dấu Kém</button>
            </div>
          </div>
        ) : null}
      </Modal>

      <ConfirmDialog open={!!deleteTarget} title="Xóa bản ghi AI" message={`Xóa đề xuất AI cho ${deleteTarget?.user}?`} onCancel={() => setDeleteTarget(null)} onConfirm={remove} confirmText="Xóa" />
    </div>
  )
}
