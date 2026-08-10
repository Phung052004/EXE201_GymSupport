import { ChevronDown, Crown } from 'lucide-react'
import { useEffect, useRef, useState } from 'react'
import Modal from '../../../components/common/Modal.jsx'
import { adminApi } from '../../../services/adminApi.js'

const FEATURES = [
  { countKey: 'equipmentInfoCount', feature: 'EquipmentInfo', label: 'Phân tích máy tập' },
  { countKey: 'bodyCheckCount', feature: 'BodyCheck', label: 'Phân tích thể hình' },
  { countKey: 'formCheckVideoCount', feature: 'FormCheckVideo', label: 'Phân tích form' },
  { countKey: 'generateWorkoutPlanCount', feature: 'GenerateWorkoutPlan', label: 'Tạo lịch AI' },
]

const fmtDateTime = (raw) => {
  if (!raw) return '—'
  try {
    const d = new Date(raw)
    return `${String(d.getDate()).padStart(2, '0')}/${String(d.getMonth() + 1).padStart(2, '0')}/${d.getFullYear()} ${String(d.getHours()).padStart(2, '0')}:${String(d.getMinutes()).padStart(2, '0')}`
  } catch {
    return '—'
  }
}

const REQUEST_FIELD_LABELS = {
  goal: 'Mục tiêu',
  experienceLevel: 'Kinh nghiệm',
  daysPerWeek: 'Số buổi/tuần',
  trainingDays: 'Ngày tập',
  intensity: 'Cường độ',
  trainingCondition: 'Điều kiện tập',
  healthIssues: 'Vấn đề sức khỏe',
}

function RequestSnapshotView({ json }) {
  let parsed = null
  try {
    parsed = JSON.parse(json)
  } catch {
    return <p className="text-xs text-slate-500 whitespace-pre-wrap">{json}</p>
  }
  const entries = Object.entries(parsed).filter(([, v]) => v !== null && v !== '' && !(Array.isArray(v) && v.length === 0))
  if (entries.length === 0) return null
  return (
    <div className="grid grid-cols-2 gap-x-4 gap-y-1 rounded-lg bg-slate-50 p-3 text-xs">
      {entries.map(([key, value]) => (
        <div key={key}>
          <span className="font-semibold text-slate-500">{REQUEST_FIELD_LABELS[key] ?? key}: </span>
          <span className="text-slate-800">{Array.isArray(value) ? value.join(', ') : String(value)}</span>
        </div>
      ))}
    </div>
  )
}

export default function PremiumFeatureUsagePage() {
  const [rows, setRows] = useState([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState(null)
  const [openDropdownFor, setOpenDropdownFor] = useState(null)
  const dropdownRef = useRef(null)

  const [detail, setDetail] = useState(null) // { userId, userName, feature, featureLabel }
  const [detailItems, setDetailItems] = useState([])
  const [detailLoading, setDetailLoading] = useState(false)
  const [detailError, setDetailError] = useState(null)

  useEffect(() => {
    adminApi
      .getPremiumUsersUsage()
      .then((data) => setRows(Array.isArray(data) ? data : []))
      .catch(() => setError('Không thể tải dữ liệu. Vui lòng thử lại.'))
      .finally(() => setLoading(false))
  }, [])

  useEffect(() => {
    const onClickOutside = (e) => {
      if (dropdownRef.current && !dropdownRef.current.contains(e.target)) setOpenDropdownFor(null)
    }
    document.addEventListener('mousedown', onClickOutside)
    return () => document.removeEventListener('mousedown', onClickOutside)
  }, [])

  const openDetail = (row, featureCfg) => {
    setOpenDropdownFor(null)
    setDetail({ userId: row.userId, userName: row.name || row.email, feature: featureCfg.feature, featureLabel: featureCfg.label })
    setDetailItems([])
    setDetailError(null)
    setDetailLoading(true)
    adminApi
      .getPremiumUserFeatureDetail(row.userId, featureCfg.feature)
      .then((data) => setDetailItems(Array.isArray(data) ? data : []))
      .catch(() => setDetailError('Không thể tải chi tiết. Vui lòng thử lại.'))
      .finally(() => setDetailLoading(false))
  }

  return (
    <div className="space-y-6 animate-fade-in">
      {/* Header */}
      <div>
        <h2 className="text-xl font-black text-slate-900">Người dùng Premium</h2>
        <p className="mt-0.5 text-sm text-slate-500">
          Danh sách người dùng đã từng mua Premium (kể cả đã hết hạn) và số lần dùng từng tính năng AI
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
                <th className="px-4 py-3 text-left text-xs font-bold uppercase tracking-wide text-slate-500">Họ tên</th>
                <th className="px-4 py-3 text-left text-xs font-bold uppercase tracking-wide text-slate-500">Email</th>
                {FEATURES.map((f) => (
                  <th key={f.feature} className="px-4 py-3 text-right text-xs font-bold uppercase tracking-wide text-slate-500">
                    {f.label}
                  </th>
                ))}
                <th className="px-4 py-3 text-right text-xs font-bold uppercase tracking-wide text-slate-500">Thao tác</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100">
              {loading ? (
                <tr>
                  <td colSpan={7} className="px-4 py-8 text-center text-sm text-slate-400">Đang tải...</td>
                </tr>
              ) : rows.length === 0 ? (
                <tr>
                  <td colSpan={7} className="px-4 py-8 text-center text-sm text-slate-400">Chưa có người dùng Premium nào</td>
                </tr>
              ) : (
                rows.map((row) => (
                  <tr key={row.userId} className="hover:bg-slate-50">
                    <td className="px-4 py-3">
                      <div className="flex items-center gap-2">
                        {row.isCurrentlyPremium && <Crown size={13} className="text-amber-500" />}
                        <span className="font-semibold text-slate-800">{row.name || '—'}</span>
                      </div>
                    </td>
                    <td className="px-4 py-3 text-slate-600">{row.email}</td>
                    {FEATURES.map((f) => (
                      <td key={f.feature} className="px-4 py-3 text-right font-bold text-slate-900">
                        {row[f.countKey]}
                      </td>
                    ))}
                    <td className="px-4 py-3 text-right">
                      <div className="relative inline-block" ref={openDropdownFor === row.userId ? dropdownRef : null}>
                        <button
                          className="btn-secondary"
                          onClick={() => setOpenDropdownFor(openDropdownFor === row.userId ? null : row.userId)}
                        >
                          Chi tiết <ChevronDown size={14} />
                        </button>
                        {openDropdownFor === row.userId && (
                          <div className="absolute right-0 z-10 mt-1 w-56 rounded-lg border border-slate-200 bg-white py-1 shadow-xl">
                            {FEATURES.map((f) => (
                              <button
                                key={f.feature}
                                onClick={() => openDetail(row, f)}
                                className="flex w-full items-center justify-between px-3 py-2 text-left text-sm text-slate-700 hover:bg-slate-50"
                              >
                                {f.label}
                                <span className="text-xs font-bold text-slate-400">{row[f.countKey]}</span>
                              </button>
                            ))}
                          </div>
                        )}
                      </div>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>

      <Modal
        open={!!detail}
        title={detail ? `${detail.featureLabel} — ${detail.userName}` : ''}
        onClose={() => setDetail(null)}
      >
        {detailLoading ? (
          <p className="py-8 text-center text-sm text-slate-400">Đang tải...</p>
        ) : detailError ? (
          <p className="py-8 text-center text-sm text-rose-600">{detailError}</p>
        ) : detailItems.length === 0 ? (
          <p className="py-8 text-center text-sm text-slate-400">Chưa có lượt dùng nào</p>
        ) : (
          <div className="space-y-3">
            {detailItems.map((item, idx) => (
              <div key={idx} className="rounded-lg border border-slate-200 p-3">
                <p className="mb-2 text-xs font-bold text-slate-400">{fmtDateTime(item.createdAt)}</p>
                {item.requestSnapshot && (
                  <div className="mb-2">
                    <p className="mb-1 text-xs font-bold uppercase text-slate-500">Dữ liệu đầu vào</p>
                    <RequestSnapshotView json={item.requestSnapshot} />
                  </div>
                )}
                <div>
                  {item.requestSnapshot && (
                    <p className="mb-1 text-xs font-bold uppercase text-slate-500">Câu trả lời AI</p>
                  )}
                  <p className="whitespace-pre-wrap text-sm leading-6 text-slate-700">{item.responseSummary || '—'}</p>
                </div>
              </div>
            ))}
          </div>
        )}
      </Modal>
    </div>
  )
}
