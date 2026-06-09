import Modal from './Modal.jsx'

export default function ConfirmDialog({ open, title, message, onCancel, onConfirm, confirmText = 'Confirm' }) {
  return (
    <Modal
      open={open}
      title={title}
      onClose={onCancel}
      footer={
        <div className="flex justify-end gap-3">
          <button className="btn-secondary" onClick={onCancel}>Cancel</button>
          <button className="btn-danger" onClick={onConfirm}>{confirmText}</button>
        </div>
      }
    >
      <p className="text-sm leading-6 text-slate-600">{message}</p>
    </Modal>
  )
}
