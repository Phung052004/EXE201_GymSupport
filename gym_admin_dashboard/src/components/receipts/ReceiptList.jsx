import Badge from '../common/Badge.jsx'

const fmtDateTime = (raw) => {
  if (!raw) return '—'
  try {
    const d = new Date(raw)
    return `${String(d.getDate()).padStart(2, '0')}/${String(d.getMonth() + 1).padStart(2, '0')}/${d.getFullYear()} ${String(d.getHours()).padStart(2, '0')}:${String(d.getMinutes()).padStart(2, '0')}`
  } catch {
    return '—'
  }
}

const fmtAmount = (amount, currency) =>
  amount != null ? `${Number(amount).toLocaleString('vi-VN')} ${currency || 'VND'}` : '—'

const EMAIL_STATUS_LABEL = { Sent: 'Đã gửi mail', Failed: 'Gửi mail lỗi', Pending: 'Đang gửi' }

export default function ReceiptList({ loading, error, receipts }) {
  if (loading) return <p className="py-8 text-center text-sm text-slate-400">Đang tải...</p>
  if (error) return <p className="py-8 text-center text-sm text-rose-600">{error}</p>
  if (!receipts?.length) return <p className="py-8 text-center text-sm text-slate-400">Chưa có hóa đơn nào</p>

  return (
    <div className="space-y-3">
      {receipts.map((r) => (
        <div key={r.id} className="rounded-lg border border-slate-200 p-3">
          <div className="flex flex-wrap items-center justify-between gap-2">
            <p className="font-bold text-slate-900">#{r.receiptNumber}</p>
            <Badge>{EMAIL_STATUS_LABEL[r.emailStatus] ?? r.emailStatus}</Badge>
          </div>
          <div className="mt-2 grid grid-cols-2 gap-x-4 gap-y-1 text-xs">
            <div><span className="font-semibold text-slate-500">Gói: </span><span className="text-slate-800">{r.planName}</span></div>
            <div><span className="font-semibold text-slate-500">Số tiền: </span><span className="font-bold text-emerald-600">{fmtAmount(r.amount, r.currency)}</span></div>
            <div><span className="font-semibold text-slate-500">Phương thức: </span><span className="text-slate-800">{r.paymentMethod}</span></div>
            <div><span className="font-semibold text-slate-500">Mã đơn: </span><span className="text-slate-800">{r.orderId}</span></div>
            <div><span className="font-semibold text-slate-500">Mã giao dịch: </span><span className="text-slate-800">{r.transactionId || '—'}</span></div>
            <div><span className="font-semibold text-slate-500">Thanh toán lúc: </span><span className="text-slate-800">{fmtDateTime(r.paidAt)}</span></div>
          </div>
        </div>
      ))}
    </div>
  )
}
