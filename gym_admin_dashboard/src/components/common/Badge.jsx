// Các giá trị trạng thái nội bộ (dùng để so sánh/logic) được giữ nguyên tiếng Anh.
// Chỉ nhãn hiển thị (label) bên dưới được dịch sang tiếng Việt.
const tones = {
  Active: 'bg-emerald-50 text-emerald-700 ring-emerald-200',
  Good: 'bg-emerald-50 text-emerald-700 ring-emerald-200',
  Reviewed: 'bg-emerald-50 text-emerald-700 ring-emerald-200',
  Resolved: 'bg-emerald-50 text-emerald-700 ring-emerald-200',
  Pending: 'bg-amber-50 text-amber-700 ring-amber-200',
  'In Progress': 'bg-sky-50 text-sky-700 ring-sky-200',
  Blocked: 'bg-rose-50 text-rose-700 ring-rose-200',
  Bad: 'bg-rose-50 text-rose-700 ring-rose-200',
  Rejected: 'bg-rose-50 text-rose-700 ring-rose-200',
  Hidden: 'bg-slate-100 text-slate-600 ring-slate-200',
}

const labels = {
  Active: 'Hoạt động',
  Good: 'Tốt',
  Reviewed: 'Đã duyệt',
  Resolved: 'Đã xử lý',
  Pending: 'Đang chờ',
  'In Progress': 'Đang xử lý',
  Blocked: 'Đã khóa',
  Bad: 'Kém',
  Rejected: 'Từ chối',
  Hidden: 'Đã ẩn',
}

export default function Badge({ children }) {
  return (
    <span className={`inline-flex items-center rounded-full px-2.5 py-1 text-xs font-semibold ring-1 ${tones[children] ?? 'bg-slate-50 text-slate-700 ring-slate-200'}`}>
      {labels[children] ?? children}
    </span>
  )
}
