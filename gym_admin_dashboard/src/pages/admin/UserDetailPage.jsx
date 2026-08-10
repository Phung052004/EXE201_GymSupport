import { ArrowLeft } from 'lucide-react'
import { useEffect, useState } from 'react'
import { Link, useParams } from 'react-router-dom'
import Badge from '../../components/common/Badge.jsx'
import ReceiptList from '../../components/receipts/ReceiptList.jsx'
import { adminApi } from '../../services/adminApi.js'

function Section({ title, children }) {
  return (
    <section className="rounded-lg border border-slate-200 bg-white p-5 shadow-sm">
      <h2 className="text-base font-black text-slate-950">{title}</h2>
      <div className="mt-4">{children}</div>
    </section>
  )
}

function InfoGrid({ items }) {
  return (
    <dl className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
      {items.map((item) => (
        <div key={item.label}>
          <dt className="text-xs font-bold uppercase tracking-wide text-slate-400">{item.label}</dt>
          <dd className="mt-1 text-sm font-bold text-slate-800">{item.value}</dd>
        </div>
      ))}
    </dl>
  )
}

function ListBlock({ items }) {
  return (
    <div className="space-y-2">
      {items.map((item) => (
        <div key={item} className="rounded-md bg-slate-50 px-3 py-2 text-sm font-semibold text-slate-700">{item}</div>
      ))}
    </div>
  )
}

export default function UserDetailPage() {
  const { id } = useParams()
  const [user, setUser] = useState(null)
  const [receipts, setReceipts] = useState([])
  const [receiptsLoading, setReceiptsLoading] = useState(true)
  const [receiptsError, setReceiptsError] = useState(null)

  useEffect(() => {
    adminApi.getUserById(id).then(setUser)
    adminApi
      .getUserReceipts(id)
      .then((data) => setReceipts(Array.isArray(data) ? data : []))
      .catch(() => setReceiptsError('Không thể tải hóa đơn. Vui lòng thử lại.'))
      .finally(() => setReceiptsLoading(false))
  }, [id])

  if (!user) return <div className="rounded-lg bg-white p-8 text-slate-500">Đang tải chi tiết người dùng...</div>

  return (
    <div className="space-y-5">
      <Link to="/admin/users" className="btn-secondary"><ArrowLeft size={16} /> Quay lại danh sách người dùng</Link>

      <Section title="Thông tin cơ bản">
        <div className="mb-4 flex flex-wrap items-center gap-3">
          <h1 className="text-2xl font-black text-slate-950">{user.fullName}</h1>
          <Badge>{user.status}</Badge>
        </div>
        <InfoGrid
          items={[
            { label: 'Họ tên', value: user.fullName },
            { label: 'Email', value: user.email },
            { label: 'Giới tính', value: user.gender },
            { label: 'Tuổi', value: user.age },
            { label: 'Ngày tạo', value: user.createdDate },
            { label: 'Trạng thái', value: <Badge>{user.status}</Badge> },
          ]}
        />
      </Section>

      <Section title="Hồ sơ thể chất">
        <InfoGrid
          items={[
            { label: 'Chiều cao', value: `${user.height} cm` },
            { label: 'Cân nặng', value: `${user.weight} kg` },
            { label: 'BMI', value: user.bmi },
            { label: 'Ghi chú chấn thương', value: user.injuryNotes },
          ]}
        />
      </Section>

      <div className="grid gap-5 xl:grid-cols-2">
        <Section title="Mục tiêu tập luyện">
          <InfoGrid items={[{ label: 'Mục tiêu', value: user.goal }, { label: 'Trình độ', value: user.experienceLevel }]} />
        </Section>
        <Section title="Lịch sử tập luyện"><ListBlock items={user.workoutHistory} /></Section>
        <Section title="Lịch sử kiểm tra vóc dáng"><ListBlock items={user.bodyCheckHistory} /></Section>
        <Section title="Lịch sử đề xuất AI"><ListBlock items={user.aiRecommendationHistory} /></Section>
      </div>

      <Section title="Hóa đơn thanh toán">
        <ReceiptList loading={receiptsLoading} error={receiptsError} receipts={receipts} />
      </Section>
    </div>
  )
}
