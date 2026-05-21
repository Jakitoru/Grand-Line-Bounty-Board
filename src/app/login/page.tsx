import { login, signup } from './actions'
import { Anchor } from 'lucide-react'

export default async function LoginPage({
  searchParams,
}: {
  searchParams: Promise<{ message: string }>
}) {
  const params = await searchParams;
  const message = params?.message;

  return (
    <div className="flex-1 flex flex-col w-full px-8 sm:max-w-md justify-center gap-2 items-center min-h-[80vh] mx-auto">
      <div className="bg-amber-900/40 p-8 rounded-xl border border-amber-700/50 backdrop-blur-md w-full shadow-2xl">
        <div className="flex justify-center mb-6 text-amber-400">
          <Anchor size={48} className="drop-shadow-lg" />
        </div>
        <h1 className="text-2xl font-cinzel text-amber-100 text-center mb-8 font-bold">
          Truy Cập Hệ Thống <br /> Hải Quân
        </h1>

        <form className="flex-1 flex flex-col w-full justify-center gap-4 text-foreground">
          <div className="flex flex-col gap-1">
            <label className="text-amber-200/80 text-sm font-medium" htmlFor="email">
              Email xác thực
            </label>
            <input
              className="rounded-md px-4 py-2 bg-amber-950/50 border border-amber-700/50 text-amber-100 placeholder-amber-700 focus:outline-none focus:border-amber-500 focus:ring-1 focus:ring-amber-500 transition-colors"
              name="email"
              placeholder="marine@world.gov"
              required
            />
          </div>
          <div className="flex flex-col gap-1">
            <label className="text-amber-200/80 text-sm font-medium" htmlFor="password">
              Mã bảo mật
            </label>
            <input
              className="rounded-md px-4 py-2 bg-amber-950/50 border border-amber-700/50 text-amber-100 placeholder-amber-700 focus:outline-none focus:border-amber-500 focus:ring-1 focus:ring-amber-500 transition-colors"
              type="password"
              name="password"
              placeholder="••••••••"
              required
            />
          </div>
          
          <div className="flex flex-col gap-3 mt-4">
            <button
              formAction={login}
              className="bg-amber-600 hover:bg-amber-500 text-white font-bold rounded-md px-4 py-2 transition-colors border border-amber-500/50 shadow-lg shadow-amber-900/20"
            >
              Đăng Nhập
            </button>
            <button
              formAction={signup}
              className="bg-transparent hover:bg-amber-900/30 text-amber-300 font-medium rounded-md px-4 py-2 border border-amber-700/50 transition-colors"
            >
              Cấp Quyền Mới (Đăng Ký)
            </button>
          </div>

          {message && (
            <div className="mt-4 p-3 bg-amber-950/80 border border-amber-500/30 text-amber-200 text-sm rounded-md text-center">
              {message}
            </div>
          )}
        </form>
      </div>
    </div>
  )
}
