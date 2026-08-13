import { Download, GitBranch, Smartphone } from 'lucide-react'

// Luôn trỏ tới bản build mới nhất — GitHub tự redirect sang đúng file của
// release mới nhất, không cần sửa link mỗi khi có bản build mới.
const APK_DOWNLOAD_URL =
  'https://github.com/Phung052004/EXE201_GymSupport/releases/latest/download/app-release.apk'
const GITHUB_URL = 'https://github.com/Phung052004/EXE201_GymSupport'
// TODO: gắn link CH Play (Google Play) thật khi ứng dụng được phát hành.
const PLAY_STORE_URL = null

function PlaceholderCard({ icon: Icon, title }) {
  return (
    <div className="flex flex-1 flex-col items-center gap-3 rounded-lg border border-dashed border-brand-hairline py-8 opacity-60">
      <span className="flex h-12 w-12 items-center justify-center rounded-full bg-brand-canvasSoft">
        <Icon className="h-6 w-6 text-brand-inkFaint" />
      </span>
      <span className="font-semibold text-brand-inkMuted">{title}</span>
      <span className="text-sm text-brand-inkFaint">Sắp ra mắt</span>
    </div>
  )
}

function LinkCard({ href, icon: Icon, iconBg, title, subtitle }) {
  return (
    <a
      href={href}
      target="_blank"
      rel="noreferrer"
      className="feature-card flex flex-1 flex-col items-center gap-3 py-8 transition-colors hover:border-brand-primary"
    >
      <span className={`flex h-12 w-12 items-center justify-center rounded-full ${iconBg}`}>
        <Icon className="h-6 w-6 text-white" />
      </span>
      <span className="font-semibold text-brand-ink">{title}</span>
      <span className="text-sm text-brand-inkMuted">{subtitle}</span>
    </a>
  )
}

export default function GetApp() {
  return (
    <div className="mx-auto flex min-h-[70vh] max-w-lg flex-col items-center justify-center px-6 py-16 text-center">
      <span className="badge-pill mb-5 bg-brand-canvasSoft">Tải ứng dụng</span>
      <h1 className="mb-3 text-3xl font-bold tracking-tight text-brand-ink">
        Trải nghiệm GymSup trên điện thoại
      </h1>
      <p className="mb-8 text-brand-inkMuted">
        Ứng dụng GymSup hiện chạy trên di động. Tải file cài đặt Android bên dưới, hoặc chọn cách khác.
      </p>

      <a
        href={APK_DOWNLOAD_URL}
        className="mb-6 flex w-full items-center justify-center gap-3 rounded-lg bg-brand-primary py-4 font-semibold text-white shadow-sm transition-transform hover:scale-[1.01]"
      >
        <Download className="h-5 w-5" />
        Tải file APK cho Android
      </a>
      <p className="mb-8 text-xs text-brand-inkFaint">
        Luôn là bản build mới nhất từ GitHub Releases. Cần bật &quot;Cài từ nguồn không xác định&quot; trên điện thoại.
      </p>

      <div className="flex w-full flex-col gap-4 sm:flex-row">
        {GITHUB_URL ? (
          <LinkCard
            href={GITHUB_URL}
            icon={GitBranch}
            iconBg="bg-brand-ink"
            title="Xem mã nguồn trên GitHub"
            subtitle="Tự build và chạy ứng dụng từ source code"
          />
        ) : (
          <PlaceholderCard icon={GitBranch} title="GitHub" />
        )}

        {PLAY_STORE_URL ? (
          <LinkCard
            href={PLAY_STORE_URL}
            icon={Smartphone}
            iconBg="bg-sticker-green"
            title="Tải trên CH Play"
            subtitle="Google Play Store"
          />
        ) : (
          <PlaceholderCard icon={Smartphone} title="CH Play" />
        )}
      </div>
    </div>
  )
}
