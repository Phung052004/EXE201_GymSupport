import { X } from 'lucide-react'

export default function Modal({ open, title, children, onClose, footer }) {
  if (!open) return null

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-slate-950/45 p-4">
      <div className="max-h-[90vh] w-full max-w-3xl overflow-hidden rounded-lg bg-white shadow-2xl">
        <div className="flex items-center justify-between border-b border-slate-200 px-5 py-4">
          <h2 className="text-lg font-black text-slate-950">{title}</h2>
          <button onClick={onClose} className="grid h-9 w-9 place-items-center rounded-md hover:bg-slate-100">
            <X size={18} />
          </button>
        </div>
        <div className="max-h-[68vh] overflow-y-auto p-5">{children}</div>
        {footer ? <div className="border-t border-slate-200 px-5 py-4">{footer}</div> : null}
      </div>
    </div>
  )
}
