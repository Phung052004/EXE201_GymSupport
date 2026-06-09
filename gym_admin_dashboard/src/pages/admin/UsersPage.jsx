import { Eye, Lock, Unlock } from 'lucide-react'
import { useEffect, useState } from 'react'
import { Link } from 'react-router-dom'
import Badge from '../../components/common/Badge.jsx'
import DataTable from '../../components/common/DataTable.jsx'
import { adminApi } from '../../services/adminApi.js'

export default function UsersPage() {
  const [users, setUsers] = useState([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    adminApi.getUsers().then((data) => {
      setUsers(data)
      setLoading(false)
    })
  }, [])

  const updateStatus = async (user) => {
    const result = user.status === 'Blocked'
      ? await adminApi.unblockUser(user.id)
      : await adminApi.blockUser(user.id)
    setUsers((current) => current.map((item) => item.id === user.id ? { ...item, status: result.status } : item))
  }

  const columns = [
    { key: 'fullName', header: 'Name', render: (row) => <span className="font-bold text-slate-950">{row.fullName}</span> },
    { key: 'email', header: 'Email' },
    { key: 'goal', header: 'Goal' },
    { key: 'experienceLevel', header: 'Experience Level' },
    { key: 'status', header: 'Status', render: (row) => <Badge>{row.status}</Badge> },
    { key: 'createdDate', header: 'Created Date' },
    {
      key: 'actions',
      header: 'Actions',
      render: (row) => (
        <div className="flex flex-wrap gap-2">
          <Link className="btn-secondary" to={`/admin/users/${row.id}`}><Eye size={15} /> Detail</Link>
          <button className="btn-secondary" onClick={() => updateStatus(row)}>
            {row.status === 'Blocked' ? <Unlock size={15} /> : <Lock size={15} />}
            {row.status === 'Blocked' ? 'Unblock' : 'Block'}
          </button>
        </div>
      ),
    },
  ]

  return (
    <div className="space-y-4">
      <div className="rounded-lg border border-slate-200 bg-white p-5 shadow-sm">
        <h2 className="text-lg font-black text-slate-950">User Management</h2>
        <p className="mt-1 text-sm text-slate-500">Review user profiles, body data, goals and account status.</p>
      </div>
      <DataTable columns={columns} data={users} loading={loading} />
    </div>
  )
}
