"use client";

import React, { useState, useEffect } from "react";
import { 
  Search, 
  Plus, 
  Compass, 
  Trash2, 
  Skull, 
  X, 
  Calendar, 
  Ruler, 
  Heart, 
  Sparkles,
  ChevronRight,
  Users,
  LogOut,
  Upload,
  Loader2,
  Edit2,
  Info
} from "lucide-react";
import { 
  getCharacters, 
  addCharacter, 
  updateCharacter, 
  deleteCharacter, 
  supabase, 
  uploadCharacterImage,
  Character 
} from "@/lib/supabase";
import { DEFAULT_CHARACTERS } from "@/lib/data";
import AuthModal from "@/components/AuthModal";
import { User as SupabaseUser } from '@supabase/supabase-js';

export default function Home() {
  const [characters, setCharacters] = useState<Character[]>([]);
  const [loading, setLoading] = useState<boolean>(true);
  const [searchTerm, setSearchTerm] = useState<string>("");
  const [selectedAffiliation, setSelectedAffiliation] = useState<string>("Tất cả");
  const [sortBy, setSortBy] = useState<string>("bounty_desc");
  
  // Modals state
  const [selectedCharacter, setSelectedCharacter] = useState<Character | null>(null);
  const [isCreateOpen, setIsCreateOpen] = useState<boolean>(false);
  const [isAuthOpen, setIsAuthOpen] = useState<boolean>(false);
  const [isEditMode, setIsEditMode] = useState<boolean>(false);
  const [isConfirmingDelete, setIsConfirmingDelete] = useState<boolean>(false);
  const [isAIProofOpen, setIsAIProofOpen] = useState<boolean>(false);

  // Auth State
  const [user, setUser] = useState<SupabaseUser | null>(null);
  const [isAdmin, setIsAdmin] = useState<boolean>(false);
  const [uploading, setUploading] = useState<boolean>(false);

  // Form States
  const [formData, setFormData] = useState({
    name: "",
    alias: "",
    bounty: "",
    affiliation: "Băng Mũ Rơm",
    role: "",
    devil_fruit: "Không có",
    devil_fruit_type: "Không có",
    hometown: "",
    age: "",
    height: "",
    status: "Còn sống",
    description: "",
    image_url: ""
  });

  const [editFormData, setEditFormData] = useState<any>(null);
  const [formError, setFormError] = useState<string>("");

  // Auto-reset confirmation state
  useEffect(() => {
    setIsConfirmingDelete(false);
    setIsEditMode(false);
  }, [selectedCharacter]);

  // Auth Listener
  useEffect(() => {
    async function checkAuth() {
      const { data: { session } } = await supabase.auth.getSession();
      const currentUser = session?.user ?? null;
      setUser(currentUser);
      if (currentUser) {
        const { data } = await supabase.from('profiles').select('role').eq('id', currentUser.id).single();
        setIsAdmin(data?.role === 'admin');
      } else {
        setIsAdmin(false);
      }
    }
    checkAuth();

    const { data: { subscription } } = supabase.auth.onAuthStateChange(async (_event, session) => {
      const currentUser = session?.user ?? null;
      setUser(currentUser);
      if (currentUser) {
        const { data } = await supabase.from('profiles').select('role').eq('id', currentUser.id).single();
        setIsAdmin(data?.role === 'admin');
      } else {
        setIsAdmin(false);
      }
    });

    return () => subscription.unsubscribe();
  }, []);

  // Load characters
  useEffect(() => {
    async function loadData() {
      setLoading(true);
      const data = await getCharacters();
      setCharacters(data);
      setLoading(false);
    }
    loadData();
  }, []);

  const handleLogout = async () => {
    await supabase.auth.signOut();
    alert("Hẹn gặp lại bạn trên đại hải trình!");
  };

  const handleFileUpload = async (e: React.ChangeEvent<HTMLInputElement>, isEdit: boolean = false) => {
    const file = e.target.files?.[0];
    if (!file) return;

    setUploading(true);
    try {
      const publicUrl = await uploadCharacterImage(file);
      if (publicUrl) {
        if (isEdit) {
          setEditFormData((prev: any) => ({ ...prev, image_url: publicUrl }));
        } else {
          setFormData(prev => ({ ...prev, image_url: publicUrl }));
        }
      }
    } catch (err) {
      alert("Lỗi khi tải ảnh lên!");
    } finally {
      setUploading(false);
    }
  };

  const startEditing = () => {
    if (!selectedCharacter) return;
    setEditFormData({ ...selectedCharacter });
    setIsEditMode(true);
  };

  // Format currency Belly
  const formatBounty = (num: number) => {
    if (num <= 0) return "???";
    return new Intl.NumberFormat("vi-VN").format(num) + " ฿";
  };

  // Get short name (usually the last part of the name)
  const getShortName = (fullName: string) => {
    if (!fullName) return "";
    const parts = fullName.trim().split(/\s+/);
    return parts[parts.length - 1];
  };

  const affiliations = [
    "Tất cả", "Băng Mũ Rơm", "Băng Tóc Đỏ", "Băng Râu Trắng", "Băng Râu Đen", 
    "Cross Guild", "Quân Cách Mạng", "Hải Quân", "Tộc Người Cá", "Khác"
  ];

  // Filter & Sort Logic
  const filteredCharacters = characters
    .filter(char => {
      const matchSearch = 
        char.name.toLowerCase().includes(searchTerm.toLowerCase()) || 
        char.alias?.toLowerCase().includes(searchTerm.toLowerCase());
      const matchAffiliation = selectedAffiliation === "Tất cả" || char.affiliation.includes(selectedAffiliation);
      return matchSearch && matchAffiliation;
    })
    .sort((a, b) => {
      if (sortBy === "bounty_desc") return b.bounty - a.bounty;
      if (sortBy === "bounty_asc") return a.bounty - b.bounty;
      if (sortBy === "age_desc") return (b.age || 0) - (a.age || 0);
      if (sortBy === "age_asc") return (a.age || 0) - (b.age || 0);
      return 0;
    });

  const handleInputChange = (e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement | HTMLTextAreaElement>) => {
    const { name, value } = e.target;
    setFormData(prev => ({ ...prev, [name]: value }));
  };

  const handleCreateCharacter = async (e: React.FormEvent) => {
    e.preventDefault();
    setFormError("");

    if (!user) {
      window.location.href = '/login';
      return;
    }

    const bountyNum = parseInt(formData.bounty.replace(/\D/g, ""));
    const ageNum = formData.age ? parseInt(formData.age) : undefined;
    const heightNum = formData.height ? parseInt(formData.height) : undefined;

    const newCharData = {
      name: formData.name,
      alias: formData.alias || "Vô danh",
      bounty: bountyNum,
      affiliation: formData.affiliation,
      role: formData.role || "Thủy thủ",
      devil_fruit: formData.devil_fruit || "Không có",
      devil_fruit_type: formData.devil_fruit_type || "Không có",
      hometown: formData.hometown || "Tân Thế Giới",
      age: ageNum,
      height: heightNum,
      status: formData.status,
      description: formData.description || `Hải tặc khét tiếng thuộc thế lực ${formData.affiliation}.`,
      image_url: formData.image_url || "https://images.unsplash.com/photo-1534447677768-be436bb09401?w=400"
    };

    try {
      const addedChar = await addCharacter(newCharData);
      if (addedChar) {
        setCharacters(prev => [addedChar, ...prev].sort((a, b) => b.bounty - a.bounty));
        setIsCreateOpen(false);
        setFormData({
          name: "", alias: "", bounty: "", affiliation: "Băng Mũ Rơm", role: "",
          devil_fruit: "Không có", devil_fruit_type: "Không có", hometown: "",
          age: "", height: "", status: "Còn sống", description: "", image_url: ""
        });
      }
    } catch (err) {
      setFormError("Lỗi hệ thống khi thêm nhân vật.");
    }
  };

  const handleSyncData = async () => {
    // Gỡ bỏ yêu cầu đăng nhập để cứu cánh khi bị lỗi rate limit email
    if (!confirm("Bạn có muốn đồng bộ toàn bộ 53 đại hải tặc lên hệ thống không? (Dữ liệu trùng sẽ được bỏ qua)")) return;

    setLoading(true);
    try {
      let syncCount = 0;
      // Bước 1: Làm sạch tuyệt đối database (Xóa tất cả nhân vật để reset hoàn toàn)
      console.log("Đang làm sạch database...");
      const { error: deleteError } = await supabase.from('characters').delete().neq('id', 0); // Xóa tất cả các hàng
      if (deleteError) {
        console.error("Lỗi xóa:", deleteError);
        throw deleteError;
      }

      // Bước 2: Chuẩn bị dữ liệu nạp lại
      const charactersToInsert = DEFAULT_CHARACTERS.map(char => ({
        name: char.name,
        alias: char.alias,
        bounty: char.bounty,
        affiliation: char.affiliation,
        role: char.role,
        devil_fruit: char.devil_fruit,
        devil_fruit_type: char.devil_fruit_type,
        hometown: char.hometown,
        age: char.age,
        height: char.height,
        status: char.status,
        description: char.description,
        image_url: char.image_url,
        is_custom: false
      }));

      console.log(`Đang nạp lại ${charactersToInsert.length} nhân vật...`);
      const { error: insertError } = await supabase.from('characters').insert(charactersToInsert);
      
      if (insertError) {
        console.error("Lỗi insert:", insertError);
        throw insertError;
      }

      syncCount = charactersToInsert.length;
      
      const refreshedData = await getCharacters();
      setCharacters(refreshedData);
      alert(`✅ Đồng bộ thành công ${syncCount} nhân vật mới!`);
    } catch (err) {
      alert("Lỗi khi đồng bộ dữ liệu!");
    } finally {
      setLoading(false);
    }
  };

  const handleUpdateCharacter = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!selectedCharacter || !editFormData) return;

    try {
      const updated = await updateCharacter(selectedCharacter.id, editFormData);
      if (updated) {
        setCharacters(prev => prev.map(c => c.id === updated.id ? updated : c));
        setSelectedCharacter(updated);
        setIsEditMode(false);
        alert("✅ Cập nhật thành công!");
      }
    } catch (err) {
      alert("Lỗi khi cập nhật!");
    }
  };

  const handleDelete = async (id: number) => {
    const success = await deleteCharacter(id);
    if (success) {
      setCharacters(prev => prev.filter(c => c.id !== id));
      setSelectedCharacter(null);
      alert("✅ Đã gỡ bỏ lệnh truy nã!");
    } else {
      alert("❌ Lỗi khi xóa!");
    }
  };

  return (
    <div className="min-h-screen bg-slate-950 text-slate-200 flex flex-col selection:bg-amber-500/30">
      
      <AuthModal isOpen={isAuthOpen} onClose={() => setIsAuthOpen(false)} />

      {/* HEADER */}
      <header className="border-b border-amber-500/10 bg-slate-950/80 backdrop-blur-xl sticky top-0 z-50">
        <div className="max-w-7xl mx-auto px-4 py-4 flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-xl bg-gradient-to-br from-amber-400 to-amber-600 flex items-center justify-center shadow-lg shadow-amber-500/20">
              <Compass className="w-6 h-6 text-slate-950" />
            </div>
            <div className="hidden sm:block">
              <h1 className="font-serif text-xl font-black text-amber-400 tracking-tighter">GRAND LINE WANTED</h1>
              <p className="text-[10px] text-slate-500 uppercase tracking-widest font-bold">Quản lý truy nã hải tặc</p>
            </div>
          </div>

          <div className="flex items-center gap-4">
            <button 
              onClick={() => setIsAIProofOpen(true)}
              className="text-slate-400 hover:text-amber-400 transition-colors text-xs font-bold flex items-center gap-1 px-3 py-2 rounded-lg bg-slate-900 border border-slate-800"
            >
              <Sparkles className="w-3.5 h-3.5" />
              AI Proof
            </button>

            <button 
              onClick={handleSyncData}
              className="flex items-center gap-2 px-4 py-2.5 rounded-xl bg-indigo-500/10 border border-indigo-500/20 text-indigo-400 hover:bg-indigo-500/20 transition-all text-xs font-bold"
            >
              <Loader2 className={`w-3.5 h-3.5 ${loading ? 'animate-spin' : ''}`} />
              Sync Data
            </button>

            {user ? (
              <div className="flex items-center gap-3">
                <div className="flex flex-col items-end">
                  <span className="text-[10px] font-bold text-amber-500/70 uppercase">
                    {isAdmin ? 'Đô Đốc (Admin)' : 'Thuyền Viên'}
                  </span>
                  <span className="text-xs font-black text-white max-w-[100px] truncate">{user.user_metadata?.full_name || user.email}</span>
                </div>
                <button onClick={handleLogout} className="p-2.5 rounded-xl bg-slate-900 border border-slate-800 text-slate-500 hover:text-red-400 transition-all">
                  <LogOut className="w-4 h-4" />
                </button>
                <button onClick={() => setIsCreateOpen(true)} className="bg-amber-500 hover:bg-amber-400 text-slate-950 px-4 py-2.5 rounded-xl font-bold text-sm flex items-center gap-2 shadow-lg shadow-amber-500/10 active:scale-95 transition-all">
                  <Plus className="w-4 h-4" />
                  <span className="hidden md:inline">Tạo Lệnh</span>
                </button>
              </div>
            ) : (
              <button onClick={() => window.location.href = '/login'} className="bg-amber-500 hover:bg-amber-400 text-slate-950 px-6 py-2.5 rounded-xl font-bold text-sm shadow-lg shadow-amber-500/10 active:scale-95 transition-all">
                Gia Nhập
              </button>
            )}
          </div>
        </div>
      </header>

      <main className="max-w-7xl mx-auto px-4 py-8 flex-1 w-full">
        
        {/* STATS & SEARCH */}
        <div className="flex flex-col gap-6 mb-12">
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            <div className="bg-slate-900/50 border border-slate-800 p-5 rounded-2xl flex items-center gap-4">
              <div className="w-12 h-12 rounded-xl bg-rose-500/10 flex items-center justify-center border border-rose-500/20 text-rose-500">
                <Skull className="w-6 h-6" />
              </div>
              <div>
                <p className="text-[10px] font-bold text-slate-500 uppercase tracking-widest">Tổng Hải Tặc</p>
                <p className="text-xl font-black text-white">{characters.length}</p>
              </div>
            </div>
            <div className="bg-slate-900/50 border border-slate-800 p-5 rounded-2xl flex items-center gap-4">
              <div className="w-12 h-12 rounded-xl bg-amber-500/10 flex items-center justify-center border border-amber-500/20 text-amber-500">
                <Sparkles className="w-6 h-6" />
              </div>
              <div>
                <p className="text-[10px] font-bold text-slate-500 uppercase tracking-widest">Cao Nhất</p>
                <p className="text-xl font-black text-white">{formatBounty(characters[0]?.bounty || 0)}</p>
              </div>
            </div>
            <div className="relative group">
              <Search className="absolute left-4 top-1/2 -translate-y-1/2 w-5 h-5 text-slate-600 group-focus-within:text-amber-500 transition-colors" />
              <input 
                type="text" 
                placeholder="Tìm tên hải tặc..."
                value={searchTerm}
                onChange={e => setSearchTerm(e.target.value)}
                className="w-full bg-slate-900 border border-slate-800 rounded-2xl pl-12 pr-4 py-4 focus:ring-2 focus:ring-amber-500/40 focus:border-amber-500 focus:outline-none transition-all placeholder:text-slate-600"
              />
            </div>
          </div>

          <div className="flex flex-wrap gap-2">
            {affiliations.map(tab => (
              <button 
                key={tab}
                onClick={() => setSelectedAffiliation(tab)}
                className={`px-4 py-2 rounded-xl text-[10px] font-black uppercase tracking-widest transition-all ${selectedAffiliation === tab ? 'bg-amber-500 text-slate-950 shadow-lg shadow-amber-500/20' : 'bg-slate-900 text-slate-500 hover:text-slate-200 border border-slate-800'}`}
              >
                {tab}
              </button>
            ))}
          </div>
        </div>

        {/* GRID */}
        {loading ? (
          <div className="flex flex-col items-center justify-center py-32 gap-4">
            <Loader2 className="w-10 h-10 text-amber-500 animate-spin" />
            <p className="text-xs font-bold text-slate-500 uppercase tracking-widest">Đang giong buồm...</p>
          </div>
        ) : (
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-8">
            {filteredCharacters.map(char => (
              <div 
                key={char.id} 
                onClick={() => setSelectedCharacter(char)}
                className="wanted-poster group cursor-pointer hover:scale-[1.03] transition-all duration-500 p-6 flex flex-col items-center shadow-2xl relative"
              >
                <div className="absolute top-0 left-0 w-full h-full bg-[#ebd39a]/10 pointer-events-none group-hover:bg-transparent transition-colors"></div>
                <h2 className="font-serif text-3xl font-black text-[#3b240e] border-b-2 border-[#3b240e] w-full text-center pb-1 uppercase tracking-widest mb-1">WANTED</h2>
                <p className="text-[10px] font-black text-[#3b240e] uppercase tracking-[0.3em] mb-4">Dead or Alive</p>
                
                <div className="w-full aspect-[4/3] bg-[#d3bc8d] border-4 border-[#3b240e] relative overflow-hidden shadow-inner">
                  <img 
                    src={char.image_url} 
                    alt={char.name} 
                    style={{ 
                      position: 'absolute', 
                      inset: 0, 
                      width: '100%', 
                      height: '100%', 
                      objectFit: 'cover',
                      objectPosition: 'top',
                      display: 'block'
                    }}
                    className="grayscale-[20%] sepia-[40%] contrast-[110%] group-hover:scale-110 transition-transform duration-700"
                  />
                  <div className="absolute inset-0 bg-gradient-to-t from-black/20 to-transparent pointer-events-none"></div>
                </div>

                <h3 className="font-serif text-2xl font-black text-[#1a0f00] mt-5 uppercase tracking-tighter line-clamp-1">{getShortName(char.name)}</h3>
                <p className="text-[10px] font-bold text-[#5c3e1e] italic mt-1">&quot;{char.alias}&quot;</p>

                <div className="mt-5 pt-3 border-t border-[#3b240e]/20 w-full flex flex-col items-center">
                  <span className="text-[9px] font-black text-[#5c3e1e] uppercase tracking-widest opacity-60">Bounty</span>
                  <span className="text-xl font-black text-[#3b240e] mt-1">{formatBounty(char.bounty)}</span>
                </div>
              </div>
            ))}
          </div>
        )}
      </main>

      {/* CHARACTER DETAILS MODAL */}
      {selectedCharacter && (
        <div className="fixed inset-0 bg-black/90 backdrop-blur-sm z-[100] flex items-center justify-center p-4">
          <div className="wanted-poster max-w-4xl w-full flex flex-col md:flex-row overflow-hidden shadow-2xl animate-in zoom-in-95 duration-300">
            <button 
              onClick={() => setSelectedCharacter(null)}
              className="absolute top-4 right-4 z-50 p-2 bg-[#3b240e] text-amber-100 rounded-full hover:bg-red-900 transition-colors"
            >
              <X className="w-5 h-5" />
            </button>

            <div className="w-full md:w-1/2 p-10 bg-[#ebd39a]/30 border-r border-[#3b240e]/10 flex flex-col items-center justify-center">
               <h2 className="font-serif text-4xl font-black text-[#3b240e] uppercase tracking-widest mb-2">WANTED</h2>
               <div className="w-full aspect-[4/3] bg-[#d3bc8d] border-8 border-[#3b240e] shadow-2xl relative overflow-hidden">
                  <img 
                    src={selectedCharacter.image_url} 
                    alt={selectedCharacter.name} 
                    style={{ 
                      position: 'absolute', 
                      inset: 0, 
                      width: '100%', 
                      height: '100%', 
                      objectFit: 'cover',
                      objectPosition: 'top',
                      display: 'block'
                    }}
                    className="grayscale-[20%] sepia-[40%]" 
                  />
               </div>
               <h3 className="font-serif text-3xl font-black text-[#1a0f00] mt-6 uppercase">{selectedCharacter.name}</h3>
               <div className="mt-6 bg-[#3b240e]/10 py-4 px-10 rounded-xl flex flex-col items-center">
                  <span className="text-xs font-black text-[#5c3e1e] uppercase tracking-[0.2em]">Truy nã</span>
                  <span className="text-2xl font-black text-red-950">{formatBounty(selectedCharacter.bounty)}</span>
               </div>
            </div>

            <div className="w-full md:w-1/2 p-10 bg-transparent flex flex-col">
              {!isEditMode ? (
                <>
                  <h4 className="text-lg font-black text-[#3b240e] border-b-2 border-[#3b240e]/10 pb-4 mb-6 flex items-center gap-2">
                    <Skull className="w-5 h-5 text-red-800" /> HỒ SƠ TỘI PHẠM
                  </h4>
                  
                  <div className="grid grid-cols-2 gap-y-6 text-sm flex-1">
                    <div>
                      <p className="text-[10px] font-black text-[#5c3e1e]/60 uppercase tracking-widest mb-1">Thế lực</p>
                      <p className="font-black text-[#1a0f00]">{selectedCharacter.affiliation}</p>
                    </div>
                    <div>
                      <p className="text-[10px] font-black text-[#5c3e1e]/60 uppercase tracking-widest mb-1">Chức vụ</p>
                      <p className="font-black text-[#1a0f00]">{selectedCharacter.role}</p>
                    </div>
                    <div>
                      <p className="text-[10px] font-black text-[#5c3e1e]/60 uppercase tracking-widest mb-1">Trái ác quỷ</p>
                      <p className="font-black text-[#1a0f00]">{selectedCharacter.devil_fruit}</p>
                    </div>
                    <div>
                      <p className="text-[10px] font-black text-[#5c3e1e]/60 uppercase tracking-widest mb-1">Hệ trái</p>
                      <p className="font-black text-[#1a0f00]">{selectedCharacter.devil_fruit_type}</p>
                    </div>
                    <div>
                      <p className="text-[10px] font-black text-[#5c3e1e]/60 uppercase tracking-widest mb-1">Quê quán</p>
                      <p className="font-black text-[#1a0f00]">{selectedCharacter.hometown}</p>
                    </div>
                    <div>
                      <p className="text-[10px] font-black text-[#5c3e1e]/60 uppercase tracking-widest mb-1">Trạng thái</p>
                      <span className={`px-2 py-1 rounded text-[10px] font-black uppercase ${selectedCharacter.status === 'Còn sống' ? 'bg-green-100 text-green-700' : 'bg-red-100 text-red-700'}`}>{selectedCharacter.status}</span>
                    </div>
                    <div>
                      <p className="text-[10px] font-black text-[#5c3e1e]/60 uppercase tracking-widest mb-1">Tuổi</p>
                      <p className="font-black text-[#1a0f00]">{selectedCharacter.age ? `${selectedCharacter.age} tuổi` : '???'}</p>
                    </div>
                    <div>
                      <p className="text-[10px] font-black text-[#5c3e1e]/60 uppercase tracking-widest mb-1">Chiều cao</p>
                      <p className="font-black text-[#1a0f00]">{selectedCharacter.height ? `${selectedCharacter.height} cm` : '???'}</p>
                    </div>
                    <div className="col-span-2">
                      <p className="text-[10px] font-black text-[#5c3e1e]/60 uppercase tracking-widest mb-1">Tiểu sử</p>
                      <p className="text-sm italic leading-relaxed text-[#2a1a08] bg-white/30 p-4 rounded-xl border border-[#3b240e]/5">
                        &ldquo;{selectedCharacter.description}&rdquo;
                      </p>
                    </div>
                  </div>

                  {user && (selectedCharacter.user_id === user.id || isAdmin) && (
                    <div className="mt-8 pt-8 border-t border-[#3b240e]/10 flex gap-4">
                      <button onClick={startEditing} className="flex-1 bg-amber-600 hover:bg-amber-500 text-slate-950 py-4 rounded-xl font-black uppercase text-[10px] tracking-widest transition-all shadow-lg active:scale-95 flex items-center justify-center gap-2">
                        <Edit2 className="w-3.5 h-3.5" /> Chỉnh sửa
                      </button>
                      <button onClick={() => setIsConfirmingDelete(true)} className="flex-1 bg-red-950 hover:bg-red-900 text-white py-4 rounded-xl font-black uppercase text-[10px] tracking-widest transition-all shadow-lg active:scale-95 flex items-center justify-center gap-2">
                        <Trash2 className="w-3.5 h-3.5" /> Xóa bỏ
                      </button>
                    </div>
                  )}
                  
                  {isConfirmingDelete && (
                    <div className="fixed inset-0 bg-black/60 flex items-center justify-center p-4 z-[110]">
                      <div className="bg-slate-900 p-8 rounded-3xl border border-slate-800 max-w-xs w-full text-center">
                        <Skull className="w-12 h-12 text-red-500 mx-auto mb-4" />
                        <h5 className="text-white font-black mb-2">XÁC NHẬN XÓA?</h5>
                        <p className="text-slate-400 text-xs mb-6">Lệnh truy nã này sẽ biến mất vĩnh viễn khỏi đại hải trình!</p>
                        <div className="flex gap-3">
                          <button onClick={() => setIsConfirmingDelete(false)} className="flex-1 py-3 bg-slate-800 text-white rounded-xl text-[10px] font-bold uppercase">Hủy</button>
                          <button onClick={() => handleDelete(selectedCharacter.id)} className="flex-1 py-3 bg-red-600 text-white rounded-xl text-[10px] font-bold uppercase">Xác nhận</button>
                        </div>
                      </div>
                    </div>
                  )}
                </>
              ) : (
                /* EDIT MODE */
                <form onSubmit={handleUpdateCharacter} className="flex flex-col h-full">
                  <h4 className="text-lg font-black text-[#3b240e] border-b-2 border-[#3b240e]/10 pb-4 mb-6 uppercase">Cập nhật thông tin</h4>
                  <div className="flex flex-col gap-5 flex-1 overflow-y-auto pr-2">
                    <div className="flex flex-col gap-1.5">
                      <label className="text-[10px] font-black uppercase text-[#5c3e1e]/60 tracking-widest">Tên hải tặc</label>
                      <input 
                        type="text" 
                        value={editFormData.name} 
                        onChange={e => setEditFormData({...editFormData, name: e.target.value})}
                        className="bg-white/50 border border-[#3b240e]/10 rounded-xl px-4 py-3 text-sm focus:outline-none focus:ring-2 focus:ring-amber-500"
                      />
                    </div>
                    <div className="grid grid-cols-2 gap-4">
                      <div className="flex flex-col gap-1.5">
                        <label className="text-[10px] font-black uppercase text-[#5c3e1e]/60 tracking-widest">Truy nã (฿)</label>
                        <input 
                          type="number" 
                          value={editFormData.bounty} 
                          onChange={e => setEditFormData({...editFormData, bounty: parseInt(e.target.value)})}
                          className="bg-white/50 border border-[#3b240e]/10 rounded-xl px-4 py-3 text-sm focus:outline-none focus:ring-2 focus:ring-amber-500"
                        />
                      </div>
                      <div className="flex flex-col gap-1.5">
                        <label className="text-[10px] font-black uppercase text-[#5c3e1e]/60 tracking-widest">Trạng thái</label>
                        <select 
                          value={editFormData.status} 
                          onChange={e => setEditFormData({...editFormData, status: e.target.value})}
                          className="bg-white/50 border border-[#3b240e]/10 rounded-xl px-4 py-3 text-sm focus:outline-none focus:ring-2 focus:ring-amber-500"
                        >
                          <option>Còn sống</option>
                          <option>Đã mất</option>
                          <option>Bị giam giữ</option>
                        </select>
                      </div>
                    </div>
                    <div className="flex flex-col gap-1.5">
                      <label className="text-[10px] font-black uppercase text-[#5c3e1e]/60 tracking-widest">Ảnh chân dung</label>
                      <div className="flex items-center gap-4 bg-white/40 p-4 rounded-2xl border border-dashed border-[#3b240e]/20">
                        {uploading ? <Loader2 className="w-5 h-5 animate-spin text-amber-600" /> : <Upload className="w-5 h-5 text-amber-700" />}
                        <input type="file" accept="image/*" onChange={e => handleFileUpload(e, true)} className="text-[10px] flex-1" />
                      </div>
                    </div>
                    <div className="flex flex-col gap-1.5 flex-1">
                      <label className="text-[10px] font-black uppercase text-[#5c3e1e]/60 tracking-widest">Tiểu sử</label>
                      <textarea 
                        value={editFormData.description} 
                        onChange={e => setEditFormData({...editFormData, description: e.target.value})}
                        className="bg-white/50 border border-[#3b240e]/10 rounded-xl px-4 py-3 text-sm flex-1 min-h-[120px] focus:outline-none focus:ring-2 focus:ring-amber-500"
                      />
                    </div>
                  </div>
                  <div className="mt-8 flex gap-3">
                    <button type="button" onClick={() => setIsEditMode(false)} className="flex-1 py-4 bg-slate-900 text-white rounded-xl text-[10px] font-black uppercase tracking-widest">Hủy</button>
                    <button type="submit" className="flex-1 py-4 bg-green-800 text-white rounded-xl text-[10px] font-black uppercase tracking-widest">Lưu lại</button>
                  </div>
                </form>
              )}
            </div>
          </div>
        </div>
      )}

      {/* CREATE MODAL */}
      {isCreateOpen && (
        <div className="fixed inset-0 bg-black/95 backdrop-blur-md z-[100] flex items-center justify-center p-4">
          <div className="bg-slate-900 border border-slate-800 rounded-[2.5rem] w-full max-w-2xl overflow-hidden shadow-2xl relative animate-in slide-in-from-bottom-8 duration-500">
            <div className="bg-gradient-to-r from-amber-500 to-amber-600 p-8 flex items-center justify-between">
              <div className="flex items-center gap-3">
                <Skull className="w-8 h-8 text-slate-950" />
                <h3 className="text-xl font-black text-slate-950 uppercase tracking-tighter">THIẾT KẾ LỆNH TRUY NÃ MỚI</h3>
              </div>
              <button onClick={() => setIsCreateOpen(false)} className="w-10 h-10 rounded-full bg-black/10 hover:bg-black/20 text-slate-950 flex items-center justify-center transition-all"><X className="w-5 h-5" /></button>
            </div>

            <form onSubmit={handleCreateCharacter} className="p-10 flex flex-col gap-6 max-h-[75vh] overflow-y-auto custom-scrollbar">
              <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                <div className="flex flex-col gap-2">
                  <label className="text-[10px] font-black text-slate-400 uppercase tracking-widest ml-1">Tên Hải Tặc *</label>
                  <input type="text" name="name" required value={formData.name} onChange={handleInputChange} className="bg-slate-950 border border-slate-800 rounded-2xl px-5 py-4 text-sm focus:ring-2 focus:ring-amber-500/40 focus:border-amber-500 focus:outline-none" />
                </div>
                <div className="flex flex-col gap-2">
                  <label className="text-[10px] font-black text-slate-400 uppercase tracking-widest ml-1">Biệt Danh</label>
                  <input type="text" name="alias" value={formData.alias} onChange={handleInputChange} className="bg-slate-950 border border-slate-800 rounded-2xl px-5 py-4 text-sm focus:ring-2 focus:ring-amber-500/40 focus:border-amber-500 focus:outline-none" />
                </div>
                <div className="flex flex-col gap-2">
                  <label className="text-[10px] font-black text-slate-400 uppercase tracking-widest ml-1">Tiền Truy Nã (฿) *</label>
                  <input type="text" name="bounty" required value={formData.bounty} onChange={e => {
                    const val = e.target.value.replace(/\D/g, "");
                    setFormData({...formData, bounty: val ? parseInt(val).toLocaleString('vi-VN') : ""});
                  }} className="bg-slate-950 border border-slate-800 rounded-2xl px-5 py-4 text-sm focus:ring-2 focus:ring-amber-500/40 focus:border-amber-500 focus:outline-none" />
                </div>
                <div className="flex flex-col gap-2">
                  <label className="text-[10px] font-black text-slate-400 uppercase tracking-widest ml-1">Thế Lực</label>
                  <select name="affiliation" value={formData.affiliation} onChange={handleInputChange} className="bg-slate-950 border border-slate-800 rounded-2xl px-5 py-4 text-sm focus:ring-2 focus:ring-amber-500/40 focus:border-amber-500 focus:outline-none">
                    {affiliations.filter(a => a !== 'Tất cả').map(a => <option key={a} value={a}>{a}</option>)}
                  </select>
                </div>
              </div>

              <div className="flex flex-col gap-2">
                <label className="text-[10px] font-black text-slate-400 uppercase tracking-widest ml-1">Ảnh Chân Dung</label>
                <div className="bg-slate-950 border border-slate-800 rounded-3xl p-6 flex flex-col sm:flex-row items-center gap-6">
                  <div className="w-32 h-32 rounded-2xl bg-slate-900 border border-slate-800 overflow-hidden flex-shrink-0 shadow-xl">
                    <img src={formData.image_url || "https://images.unsplash.com/photo-1534447677768-be436bb09401?w=400"} className="w-full h-full object-cover grayscale sepia brightness-75" alt="Preview" />
                  </div>
                  <div className="flex-1 w-full">
                    <div className="relative group">
                       <input type="file" accept="image/*" onChange={e => handleFileUpload(e, false)} className="absolute inset-0 opacity-0 cursor-pointer z-10" />
                       <div className="w-full border-2 border-dashed border-slate-800 group-hover:border-amber-500/40 group-hover:bg-amber-500/5 rounded-2xl py-8 flex flex-col items-center justify-center gap-2 transition-all">
                          <Upload className="w-6 h-6 text-slate-500 group-hover:text-amber-500 transition-colors" />
                          <span className="text-[10px] font-black text-slate-500 group-hover:text-amber-400 uppercase tracking-widest">Tải ảnh lên hoặc kéo thả</span>
                       </div>
                    </div>
                    {uploading && <div className="flex items-center gap-2 mt-3 text-amber-500 text-[10px] font-black animate-pulse uppercase"><Sparkles className="w-3 h-3" /> Đang cập nhật tệp tin...</div>}
                  </div>
                </div>
              </div>

              <div className="flex flex-col gap-2">
                <label className="text-[10px] font-black text-slate-400 uppercase tracking-widest ml-1">Mô Tả Tội Trạng</label>
                <textarea name="description" rows={3} value={formData.description} onChange={handleInputChange} className="bg-slate-950 border border-slate-800 rounded-2xl px-5 py-4 text-sm focus:ring-2 focus:ring-amber-500/40 focus:border-amber-500 focus:outline-none resize-none" placeholder="Lý do truy nã, sức mạnh đặc biệt..."></textarea>
              </div>

              <button type="submit" className="w-full bg-gradient-to-r from-amber-500 to-amber-600 hover:from-amber-400 hover:to-amber-500 text-slate-950 font-black py-5 rounded-2xl shadow-xl shadow-amber-500/10 active:scale-95 transition-all uppercase tracking-widest text-xs mt-4 flex items-center justify-center gap-2">
                <Skull className="w-5 h-5" /> PHÁT HÀNH LỆNH TRUY NÃ
              </button>
            </form>
          </div>
        </div>
      )}

      {/* AI PROOF MODAL */}
      {isAIProofOpen && (
        <div className="fixed inset-0 bg-black/95 backdrop-blur-md z-[110] flex items-center justify-center p-4">
          <div className="bg-slate-900 border border-slate-800 rounded-3xl w-full max-w-4xl max-h-[85vh] overflow-hidden shadow-2xl flex flex-col">
            <div className="p-8 border-b border-slate-800 flex items-center justify-between bg-slate-950">
              <div className="flex items-center gap-3">
                <Sparkles className="w-6 h-6 text-amber-500" />
                <h3 className="text-xl font-black text-white uppercase tracking-tighter">AI DEVELOPMENT EVIDENCE</h3>
              </div>
              <button onClick={() => setIsAIProofOpen(false)} className="text-slate-500 hover:text-white transition-colors"><X className="w-6 h-6" /></button>
            </div>
            <div className="p-8 overflow-y-auto flex flex-col gap-8 custom-scrollbar">
               <div className="bg-amber-500/5 border border-amber-500/20 p-6 rounded-2xl flex gap-4">
                  <Info className="w-6 h-6 text-amber-500 shrink-0" />
                  <div>
                    <h4 className="font-black text-amber-400 text-sm uppercase mb-1 tracking-tight">AI TRONG QUÁ TRÌNH PHÁT TRIỂN (Requirement 6)</h4>
                    <p className="text-xs text-slate-400 leading-relaxed">Dự án này được hỗ trợ bởi <strong>Antigravity (Gemini Flash 2.0)</strong> để tối ưu hóa UI/UX và xử lý logic phức tạp. Dưới đây là các minh chứng prompts quan trọng.</p>
                  </div>
               </div>

               <div className="grid grid-cols-1 gap-6">
                  <div className="bg-slate-950 border border-slate-800 p-6 rounded-2xl">
                     <p className="text-[10px] font-black text-amber-500 uppercase tracking-widest mb-3">Prompt #1: Kiến trúc dữ liệu</p>
                     <p className="text-sm font-bold text-slate-200 mb-4 italic">&quot;Hãy thiết kế schema Supabase cho bảng characters bao gồm các thông số đặc thù của One Piece như Tiền truy nã, Trái ác quỷ, và trạng thái 'Còn sống' hoặc 'Đã mất'.&quot;</p>
                     <div className="p-4 bg-slate-900 rounded-xl border border-slate-800 text-[11px] text-slate-400">
                        <span className="text-green-500 font-bold">Kết quả:</span> AI đã tạo ra file SQL schema hoàn chỉnh với RLS policies, giúp triển khai backend chỉ trong vài giây.
                     </div>
                  </div>

                  <div className="bg-slate-950 border border-slate-800 p-6 rounded-2xl">
                     <p className="text-[10px] font-black text-amber-500 uppercase tracking-widest mb-3">Prompt #2: UI Design</p>
                     <p className="text-sm font-bold text-slate-200 mb-4 italic">&quot;Viết CSS và Tailwind để tạo component 'Wanted Poster' mang phong cách cổ điển, có hiệu ứng sepia và texture giấy cũ như trong anime.&quot;</p>
                     <div className="p-4 bg-slate-900 rounded-xl border border-slate-800 text-[11px] text-slate-400">
                        <span className="text-green-500 font-bold">Kết quả:</span> Tạo ra giao diện Wanted Poster đặc trưng, có hiệu ứng hover mượt mà và bóng đổ chuyên nghiệp.
                     </div>
                  </div>

                  <div className="bg-slate-950 border border-slate-800 p-6 rounded-2xl">
                     <p className="text-[10px] font-black text-amber-500 uppercase tracking-widest mb-3">Prompt #3: Logic Authentication</p>
                     <p className="text-sm font-bold text-slate-200 mb-4 italic">&quot;Triển khai logic đăng nhập và bảo mật RLS sao cho mỗi người dùng chỉ có quyền chỉnh sửa hoặc xóa nhân vật do chính họ tạo ra.&quot;</p>
                     <div className="p-4 bg-slate-900 rounded-xl border border-slate-800 text-[11px] text-slate-400">
                        <span className="text-green-500 font-bold">Kết quả:</span> Tích hợp Supabase Auth thành công, đáp ứng tiêu chí bảo mật dữ liệu của đồ án.
                     </div>
                  </div>
               </div>
            </div>
          </div>
        </div>
      )}

      {/* FOOTER */}
      <footer className="max-w-7xl mx-auto px-4 py-12 border-t border-slate-900 w-full flex flex-col md:flex-row items-center justify-between gap-6">
        <div className="flex items-center gap-3 opacity-50">
           <Skull className="w-5 h-5" />
           <span className="text-[10px] font-bold uppercase tracking-widest">Grand Line Bounty System v2.0</span>
        </div>
        <p className="text-[10px] text-slate-600 font-bold uppercase tracking-widest">© 2026 Toàn bộ dữ liệu được bảo vệ bởi Chính phủ thế giới (Marine)</p>
        <div className="flex gap-4">
           <div className="w-8 h-8 rounded-lg bg-slate-900 border border-slate-800 flex items-center justify-center text-slate-500"><Info className="w-4 h-4" /></div>
        </div>
      </footer>

    </div>
  );
}
