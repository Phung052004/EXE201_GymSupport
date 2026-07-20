import { useEffect, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { Dumbbell, BrainCircuit, ScanEye, CalendarClock, ShieldOff, Check } from 'lucide-react'
import { getActivePlans } from '../services/subscriptionService.js'
import { useAuth } from '../context/AuthContext.jsx'

const FEATURES = [
  { icon: ShieldOff, title: 'Không quảng cáo', desc: 'Tập trung vào việc tập luyện, không bị gián đoạn.' },
  { icon: ScanEye, title: 'AI phân tích thiết bị', desc: 'Nhận diện thiết bị tại phòng gym và gợi ý bài tập phù hợp.' },
  { icon: Dumbbell, title: 'Form tập chuẩn', desc: 'Hướng dẫn form đúng cho từng bài tập, giảm rủi ro chấn thương.' },
  { icon: BrainCircuit, title: 'AI tạo lịch tập', desc: 'Lịch tập cá nhân hoá theo mục tiêu và tiến độ của bạn.' },
]

function formatVnd(amount) {
  return new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND' }).format(amount)
}

export default function Home() {
  const [plans, setPlans] = useState([])
  const { user } = useAuth()
  const navigate = useNavigate()

  useEffect(() => {
    getActivePlans().then(setPlans).catch(() => setPlans([]))
  }, [])

  return (
    <div>
      <section className="mx-auto max-w-5xl px-6 pb-16 pt-20 text-center">
        <div className="mx-auto mb-6 flex h-16 w-16 items-center justify-center rounded-2xl bg-brand-primary/15">
          <Dumbbell className="h-8 w-8 text-brand-primary" />
        </div>
        <h1 className="mb-4 text-4xl font-black tracking-tight text-brand-textPrimary sm:text-5xl">
          Theo dõi từng nhóm cơ.
          <br />
          <span className="text-brand-primary">Thấy rõ tiến bộ của bạn.</span>
        </h1>
        <p className="mx-auto mb-8 max-w-xl text-brand-textSecondary">
          GymSupport giúp bạn theo dõi tiến độ tập luyện theo từng nhóm cơ, tránh mất cân đối
          và đạt kết quả nhanh hơn — với sự hỗ trợ của AI.
        </p>
        <div className="flex items-center justify-center gap-4">
          <button
            onClick={() => navigate(user ? '/checkout' : '/register')}
            className="btn-primary px-6 py-3 text-base shadow-glow"
          >
            Bắt đầu ngay
          </button>
        </div>
      </section>

      <section className="mx-auto max-w-5xl px-6 py-16">
        <h2 className="mb-10 text-center text-2xl font-black text-brand-textPrimary">
          Tính năng Premium
        </h2>
        <div className="grid gap-6 sm:grid-cols-2 lg:grid-cols-4">
          {FEATURES.map(({ icon: Icon, title, desc }) => (
            <div key={title} className="card text-left">
              <Icon className="mb-4 h-8 w-8 text-brand-primary" />
              <h3 className="mb-2 font-bold text-brand-textPrimary">{title}</h3>
              <p className="text-sm text-brand-textSecondary">{desc}</p>
            </div>
          ))}
        </div>
      </section>

      {plans.length > 0 && (
        <section className="mx-auto max-w-5xl px-6 py-16">
          <h2 className="mb-10 text-center text-2xl font-black text-brand-textPrimary">Bảng giá</h2>
          <div className="grid gap-6 sm:grid-cols-2 lg:grid-cols-3">
            {plans.map((plan) => (
              <div key={plan.id} className="card flex flex-col">
                <CalendarClock className="mb-4 h-6 w-6 text-brand-primary" />
                <h3 className="mb-1 text-lg font-bold text-brand-textPrimary">{plan.name}</h3>
                <p className="mb-4 text-2xl font-black text-brand-primary">{formatVnd(plan.price)}</p>
                <p className="mb-6 flex items-center gap-2 text-sm text-brand-textSecondary">
                  <Check className="h-4 w-4 text-brand-success" />
                  {plan.durationMonths} tháng
                </p>
                <button
                  onClick={() => navigate(user ? '/checkout' : '/register')}
                  className="btn-outline mt-auto"
                >
                  Chọn gói
                </button>
              </div>
            ))}
          </div>
        </section>
      )}

      <footer className="border-t border-brand-outline px-6 py-8 text-center text-sm text-brand-textTertiary">
        © {new Date().getFullYear()} GymSupport. All rights reserved.
      </footer>
    </div>
  )
}
