import { useEffect, useMemo, useState } from 'react'
import Badge from '../../components/common/Badge.jsx'
import DataTable from '../../components/common/DataTable.jsx'
import { adminApi } from '../../services/adminApi.js'

const STATUS_FILTERS = ['All', 'Active', 'Expired', 'Cancelled']

const fmtDate = (raw) => {
  if (!raw) return 'N/A'
  try {
    const d = new Date(raw)
    return `${String(d.getDate()).padStart(2, '0')}/${String(d.getMonth() + 1).padStart(2, '0')}/${d.getFullYear()}`
  } catch {
    return 'N/A'
  }
}

const fmtPrice = (price) =>
  price != null ? Number(price).toLocaleString('vi-VN') + ' đ' : 'N/A'

const statusBadge = (status) => {
  const map = { active: 'Active', expired: 'Hidden', cancelled: 'Blocked' }
  return <Badge>{map[status?.toLowerCase()] ?? status}</Badge>
}

export default function UserSubscriptionsPage() {
  const [subs, setSubs]       = useState([])
  const [loading, setLoading] = useState(true)
  const [filter, setFilter]   = useState('All')

  useEffect(() => {
    adminApi.getUserSubscriptions().then((data) => {
      setSubs(Array.isArray(data) ? data : [])
      setLoading(false)
    })
  }, [])

  const counts = useMemo(
    () => ({
      All: subs.length,
      Active: subs.filter((s) => s.status?.toLowerCase() === 'active').length,
      Expired: subs.filter((s) => s.status?.toLowerCase() === 'expired').length,
      Cancelled: subs.filter((s) => s.status?.toLowerCase() === 'cancelled').length,
    }),
    [subs]
  )

  const filtered = useMemo(
    () =>
      filter === 'All'
        ? subs
        : subs.filter((s) => s.status?.toLowerCase() === filter.toLowerCase()),
    [subs, filter]
  )

  const columns = [
    {
      key: 'userEmail',
      header: 'Email',
      render: (row) => (
        <div>
          <p className="font-semibold text-slate-900">{row.userEmail || '—'}</p>
          {row.userName && (
            <p className="text-xs text-slate-500">{row.userName}</p>
          )}
        </div>
      ),
    },
    {
      key: 'planName',
      header: 'Gói',
      render: (row) => <span className="font-bold text-cyan-700">{row.planName}</span>,
    },
    {
      key: 'price',
      header: 'Giá',
      render: (row) => fmtPrice(row.price),
    },
    {
      key: 'status',
      header: 'Trạng thái',
      render: (row) => statusBadge(row.status),
    },
    {
      key: 'startDate',
      header: 'Bắt đầu',
      render: (row) => fmtDate(row.startDate),
    },
    {
      key: 'endDate',
      header: 'Hết hạn',
      render: (row) => fmtDate(row.endDate),
    },
    {
      key: 'daysRemaining',
      header: 'Còn lại',
      render: (row) =>
        row.status?.toLowerCase() === 'active' ? (
          <span className="font-semibold text-emerald-600">{row.daysRemaining} ngày</span>
        ) : (
          <span className="text-slate-400">—</span>
        ),
    },
  ]

  return (
    <div className="space-y-4">
      {/* Header */}
      <div className="rounded-lg border border-slate-200 bg-white p-5 shadow-sm">
        <h2 className="text-lg font-black text-slate-950">Đăng ký người dùng</h2>
        <p className="mt-1 text-sm text-slate-500">
          Danh sách tất cả subscription của người dùng trong hệ thống.
        </p>
      </div>

      {/* Filter tabs */}
      <div className="flex gap-2">
        {STATUS_FILTERS.map((f) => (
          <button
            key={f}
            onClick={() => setFilter(f)}
            className={`rounded-lg border px-4 py-2 text-sm font-semibold transition-all ${
              filter === f
                ? 'border-cyan-400 bg-cyan-500/10 text-cyan-700'
                : 'border-slate-200 bg-white text-slate-500 hover:bg-slate-50'
            }`}
          >
            {f}
            <span
              className={`ml-2 rounded-full px-1.5 py-0.5 text-xs font-bold ${
                filter === f ? 'bg-cyan-100 text-cyan-700' : 'bg-slate-100 text-slate-500'
              }`}
            >
              {counts[f]}
            </span>
          </button>
        ))}
      </div>

      <DataTable columns={columns} data={filtered} loading={loading} />
    </div>
  )
}
