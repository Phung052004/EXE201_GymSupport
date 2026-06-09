import { ArrowLeft } from 'lucide-react'
import { useEffect, useState } from 'react'
import { Link, useParams } from 'react-router-dom'
import Badge from '../../components/common/Badge.jsx'
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

  useEffect(() => {
    adminApi.getUserById(id).then(setUser)
  }, [id])

  if (!user) return <div className="rounded-lg bg-white p-8 text-slate-500">Loading user detail...</div>

  return (
    <div className="space-y-5">
      <Link to="/admin/users" className="btn-secondary"><ArrowLeft size={16} /> Back to users</Link>

      <Section title="Basic Info">
        <div className="mb-4 flex flex-wrap items-center gap-3">
          <h1 className="text-2xl font-black text-slate-950">{user.fullName}</h1>
          <Badge>{user.status}</Badge>
        </div>
        <InfoGrid
          items={[
            { label: 'Full Name', value: user.fullName },
            { label: 'Email', value: user.email },
            { label: 'Gender', value: user.gender },
            { label: 'Age', value: user.age },
            { label: 'Created', value: user.createdDate },
            { label: 'Status', value: user.status },
          ]}
        />
      </Section>

      <Section title="Body Profile">
        <InfoGrid
          items={[
            { label: 'Height', value: `${user.height} cm` },
            { label: 'Weight', value: `${user.weight} kg` },
            { label: 'BMI', value: user.bmi },
            { label: 'Injury Notes', value: user.injuryNotes },
          ]}
        />
      </Section>

      <div className="grid gap-5 xl:grid-cols-2">
        <Section title="Fitness Goal">
          <InfoGrid items={[{ label: 'Goal', value: user.goal }, { label: 'Experience Level', value: user.experienceLevel }]} />
        </Section>
        <Section title="Workout History"><ListBlock items={user.workoutHistory} /></Section>
        <Section title="Body Check History"><ListBlock items={user.bodyCheckHistory} /></Section>
        <Section title="AI Recommendation History"><ListBlock items={user.aiRecommendationHistory} /></Section>
      </div>
    </div>
  )
}
