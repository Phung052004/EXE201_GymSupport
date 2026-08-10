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
    { key: 'name', header: 'Tên bài tập', render: (row) => <span className="font-black text-slate-950">{row.name}</span> },
    { key: 'mainMuscleGroup', header: 'Nhóm cơ chính' },
    { key: 'difficulty', header: 'Độ khó' },
    { key: 'equipment', header: 'Dụng cụ' },
    { key: 'defaultSets', header: 'Hiệp/Lần', render: (row) => `${row.defaultSets} x ${row.defaultReps}` },
    { key: 'status', header: 'Trạng thái', render: (row) => <Badge>{row.status}</Badge> },
    {
      key: 'actions',
      header: 'Thao tác',
      render: (row) => (
        <div className="flex flex-wrap gap-2">
          <button className="btn-secondary" onClick={() => setDetail(row)}><Eye size={15} /> Xem</button>
          <Link className="btn-secondary" to={`/admin/exercises/${row.id}`}><Edit size={15} /> Sửa</Link>
          <button className="btn-secondary" onClick={() => setDeleteTarget(row)}><Trash2 size={15} /> Ẩn</button>
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
          <h2 className="text-lg font-black text-slate-950">Thư viện bài tập</h2>
          <p className="text-sm text-slate-500">Tạo, xem và ẩn nội dung bài tập được AI và chương trình tập sử dụng.</p>
        </div>
        <Link className="btn-primary" to="/admin/exercises/new"><Plus size={16} /> Thêm bài tập</Link>
      </div>

      <div className="grid gap-3 rounded-lg border border-slate-200 bg-white p-4 shadow-sm md:grid-cols-4">
        <input value={query} onChange={(event) => setQuery(event.target.value)} placeholder="Tìm kiếm bài tập" className="rounded-md border border-slate-200 px-3 py-2 text-sm outline-none focus:border-emerald-500" />
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
              <DetailRow label="Hướng dẫn" value={detail.instruction} />
              <DetailRow label="Lưu ý an toàn" value={detail.safetyNotes} />
              <DetailRow label="Lỗi thường gặp" value={detail.commonMistakes} />
              <DetailRow label="Mẹo tập" value={detail.tips} />
              <DetailRow label="Đường dẫn video" value={detail.videoUrl} />
              <DetailRow label="Thời gian nghỉ" value={detail.restTime} />
              <div>
                <p className="mb-2 text-xs font-black uppercase text-slate-400">Mức độ tác động cơ</p>
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
        title="Ẩn bài tập"
        message={`Ẩn ${deleteTarget?.name}? Quản trị viên có thể khôi phục nội dung đã ẩn sau khi kết nối API.`}
        confirmText="Ẩn"
        onCancel={() => setDeleteTarget(null)}
        onConfirm={removeExercise}
      />
    </div>
  )
}

function Filter({ value, onChange, options }) {
  return (
    <select value={value} onChange={(event) => onChange(event.target.value)} className="rounded-md border border-slate-200 px-3 py-2 text-sm outline-none focus:border-emerald-500">
      {options.map((option) => <option key={option} value={option}>{option === 'All' ? 'Tất cả' : option}</option>)}
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
