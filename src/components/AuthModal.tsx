"use client";

import React, { useState } from 'react';
import { supabase } from '@/lib/supabase';
import { X, Mail, Lock, User, Skull, Loader2 } from 'lucide-react';

interface AuthModalProps {
  isOpen: boolean;
  onClose: () => void;
}

export default function AuthModal({ isOpen, onClose }: AuthModalProps) {
  const [isLogin, setIsLogin] = useState(true);
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [fullName, setFullName] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  if (!isOpen) return null;

  const handleAuth = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setError(null);

    try {
      if (isLogin) {
        const { error } = await supabase.auth.signInWithPassword({ email, password });
        if (error) throw error;
      } else {
        const { error } = await supabase.auth.signUp({
          email,
          password,
          options: {
            data: { full_name: fullName }
          }
        });
        if (error) throw error;
        alert("Kiểm tra email của bạn để xác nhận đăng ký!");
      }
      onClose();
    } catch (err: any) {
      setError(err.message || "Đã xảy ra lỗi");
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="fixed inset-0 bg-black/80 backdrop-blur-md z-[100] flex items-center justify-center p-4">
      <div className="bg-slate-900 border border-slate-800 rounded-3xl w-full max-w-md overflow-hidden shadow-2xl relative animate-in fade-in zoom-in-95 duration-300">
        
        {/* Header with gradient */}
        <div className="bg-gradient-to-r from-amber-500 to-amber-600 px-8 py-10 flex flex-col items-center text-center relative">
          <button
            onClick={onClose}
            className="absolute top-4 right-4 w-8 h-8 rounded-full bg-black/20 hover:bg-black/40 text-white flex items-center justify-center transition-all"
          >
            <X className="w-4 h-4" />
          </button>
          
          <div className="w-16 h-16 rounded-2xl bg-white/20 backdrop-blur-xl flex items-center justify-center mb-4 shadow-xl rotate-3">
            <Skull className="w-8 h-8 text-white" />
          </div>
          
          <h2 className="text-2xl font-black text-slate-950 uppercase tracking-tight">
            {isLogin ? "Gia Nhập Đại Hải Trình" : "Đăng Ký Thủy Thủ Đoàn"}
          </h2>
          <p className="text-slate-900/70 text-xs font-bold uppercase tracking-widest mt-1">
            {isLogin ? "Đăng nhập để quản lý lệnh truy nã" : "Tạo tài khoản để bắt đầu cuộc hành trình"}
          </p>
        </div>

        <form onSubmit={handleAuth} className="p-8 flex flex-col gap-5">
          {error && (
            <div className="p-3 bg-red-950/50 border border-red-500/30 rounded-xl text-xs font-bold text-red-400 flex items-center gap-2">
              <X className="w-4 h-4 flex-shrink-0" />
              <span>{error}</span>
            </div>
          )}

          {!isLogin && (
            <div className="flex flex-col gap-1.5">
              <label className="text-[10px] font-black text-slate-400 uppercase tracking-widest ml-1">Tên Hiển Thị</label>
              <div className="relative">
                <User className="absolute left-4 top-1/2 -translate-y-1/2 w-4 h-4 text-slate-500" />
                <input
                  type="text"
                  placeholder="VD: Monkey D. Luffy"
                  required
                  value={fullName}
                  onChange={(e) => setFullName(e.target.value)}
                  className="w-full bg-slate-950 border border-slate-800 rounded-xl pl-12 pr-4 py-3 text-sm text-white focus:ring-2 focus:ring-amber-500/40 focus:border-amber-500 focus:outline-none transition-all placeholder:text-slate-600"
                />
              </div>
            </div>
          )}

          <div className="flex flex-col gap-1.5">
            <label className="text-[10px] font-black text-slate-400 uppercase tracking-widest ml-1">Email Liên Lạc</label>
            <div className="relative">
              <Mail className="absolute left-4 top-1/2 -translate-y-1/2 w-4 h-4 text-slate-500" />
              <input
                type="email"
                placeholder="pirate@grandline.com"
                required
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                className="w-full bg-slate-950 border border-slate-800 rounded-xl pl-12 pr-4 py-3 text-sm text-white focus:ring-2 focus:ring-amber-500/40 focus:border-amber-500 focus:outline-none transition-all placeholder:text-slate-600"
              />
            </div>
          </div>

          <div className="flex flex-col gap-1.5">
            <label className="text-[10px] font-black text-slate-400 uppercase tracking-widest ml-1">Mật Khẩu</label>
            <div className="relative">
              <Lock className="absolute left-4 top-1/2 -translate-y-1/2 w-4 h-4 text-slate-500" />
              <input
                type="password"
                placeholder="••••••••"
                required
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                className="w-full bg-slate-950 border border-slate-800 rounded-xl pl-12 pr-4 py-3 text-sm text-white focus:ring-2 focus:ring-amber-500/40 focus:border-amber-500 focus:outline-none transition-all placeholder:text-slate-600"
              />
            </div>
          </div>

          <button
            type="submit"
            disabled={loading}
            className="w-full bg-gradient-to-r from-amber-500 to-amber-600 hover:from-amber-400 hover:to-amber-500 text-slate-950 font-black text-sm uppercase py-4 rounded-xl shadow-lg shadow-amber-500/10 active:scale-95 transition-all mt-2 flex items-center justify-center gap-2"
          >
            {loading ? (
              <Loader2 className="w-5 h-5 animate-spin" />
            ) : (
              <span>{isLogin ? "Đăng Nhập Ngay" : "Tạo Tài Khoản"}</span>
            )}
          </button>

          <p className="text-center text-slate-400 text-xs mt-2">
            {isLogin ? "Bạn chưa có tài khoản?" : "Bạn đã có tài khoản?"}{" "}
            <button
              type="button"
              onClick={() => setIsLogin(!isLogin)}
              className="text-amber-400 font-bold hover:underline"
            >
              {isLogin ? "Đăng ký tại đây" : "Đăng nhập ngay"}
            </button>
          </p>
        </form>
      </div>
    </div>
  );
}
