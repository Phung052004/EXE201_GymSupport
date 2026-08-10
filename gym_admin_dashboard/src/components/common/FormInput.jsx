export default function FormInput({ label, as = 'input', options = [], error, ...props }) {
  const baseClass = 'mt-1 w-full rounded-md border border-slate-200 bg-white px-3 py-2 text-sm text-slate-900 outline-none transition focus:border-emerald-500 focus:ring-2 focus:ring-emerald-100'
  const Field = as

  return (
    <label className="block">
      <span className="text-sm font-bold text-slate-700">{label}</span>
      {as === 'select' ? (
        <select className={baseClass} {...props}>
          {options.map((option) => {
            const opt = typeof option === 'object' && option !== null ? option : { value: option, label: option }
            return (
              <option key={opt.value} value={opt.value}>{opt.label}</option>
            )
          })}
        </select>
      ) : (
        <Field className={baseClass} {...props} />
      )}
      {error ? <span className="mt-1 block text-xs font-semibold text-rose-600">{error}</span> : null}
    </label>
  )
}
