import { useEffect, useState } from 'react'
import Modal from '../../components/common/Modal.jsx'
import { adminApi } from '../../services/adminApi.js'
import ReceiptList from '../../components/receipts/ReceiptList.jsx'

export default function ReceiptsPage() {
  const [rows, setRows] = useState([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState(null)

  const [detailUser, setDetailUser] = useState(null) // { userId, name, email }
  const [receipts, setReceipts] = useState([])
  const [detailLoading, setDetailLoading] = useState(false)
  const [detailError, setDetailError] = useState(null)

  useEffect(() => {
    adminApi
      .getReceiptUsers()
      .then((data) => setRows(Array.isArray(data) ? data : []))
      .catch(() => setError('Không thể tải dữ liệu. Vui lòng thử lại.'))
      .finally(() => setLoading(false))
  }, [])

  const openDetail = (row) => {
    setDetailUser(row)
    setReceipts([])
    setDetailError(null)
    setDetailLoading(true)
    adminApi
      .getUserReceipts(row.userId)
      .then((data) => setReceipts(Array.isArray(data) ? data : []))
      .catch(() => setDetailError('Không thể tải receipt. Vui lòng thử lại.'))
      .finally(() => setDetailLoading(false))
  }

  return (
    <div className="space-y-6 animate-fade-in">
      <div>
        <h2 className="text-xl font-black text-slate-900">Receipts</h2>
        <p className="mt-0.5 text-sm text-slate-500">
          Danh sách user từng thanh toán thành công và toàn bộ biên nhận của họ
        </p>
      </div>

      {error && (
        <div className="rounded-xl border border-rose-200 bg-rose-50 px-4 py-3 text-sm font-medium text-rose-700">
          {error}
        </div>
      )}

      <div className="rounded-2xl border border-slate-200 bg-white shadow-sm">
        <div className="overflow-x-auto">
          <table className="w-full text-sm">
            <thead className="bg-slate-50">
              <tr>
                <th className="px-4 py-3 text-left text-xs font-bold uppercase tracking-wide text-slate-500">Name</th>
                <th className="px-4 py-3 text-left text-xs font-bold uppercase tracking-wide text-slate-500">Email</th>
                <th className="px-4 py-3 text-right text-xs font-bold uppercase tracking-wide text-slate-500">Action</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100">
              {loading ? (
                <tr>
                  <td colSpan={3} className="px-4 py-8 text-center text-sm text-slate-400">Đang tải...</td>
                </tr>
              ) : rows.length === 0 ? (
                <tr>
                  <td colSpan={3} className="px-4 py-8 text-center text-sm text-slate-400">Chưa có giao dịch nào</td>
                </tr>
              ) : (
                rows.map((row) => (
                  <tr key={row.userId} className="hover:bg-slate-50">
                    <td className="px-4 py-3 font-semibold text-slate-800">{row.name || '—'}</td>
                    <td className="px-4 py-3 text-slate-600">{row.email || '—'}</td>
                    <td className="px-4 py-3 text-right">
                      <button className="btn-secondary" onClick={() => openDetail(row)}>
                        Xem receipt ({row.receiptCount})
                      </button>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>

      <Modal
        open={!!detailUser}
        title={detailUser ? `Receipts — ${detailUser.name || detailUser.email}` : ''}
        onClose={() => setDetailUser(null)}
      >
        <ReceiptList loading={detailLoading} error={detailError} receipts={receipts} />
      </Modal>
    </div>
  )
}
