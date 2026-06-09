export default function StatCard({ icon: Icon, label, value, helper }) {
  return (
    <div className="rounded-lg border border-slate-200 bg-white p-5 shadow-sm">
      <div className="flex items-start justify-between gap-4">
        <div>
          <p className="text-sm font-semibold text-slate-500">{label}</p>
          <p className="mt-2 text-3xl font-black text-slate-950">{value}</p>
          {helper ? <p className="mt-1 text-xs font-medium text-emerald-600">{helper}</p> : null}
        </div>
        <div className="grid h-11 w-11 place-items-center rounded-md bg-emerald-50 text-emerald-600">
          <Icon size={22} />
        </div>
      </div>
    </div>
  )
}
