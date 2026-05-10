"use client";

import React, { useState, useEffect } from "react";
import { 
  Search, 
  Plus, 
  Compass, 
  Trash2, 
  Info, 
  Database, 
  TrendingUp, 
  Users, 
  Skull, 
  X, 
  HelpCircle, 
  Calendar, 
  Ruler, 
  Heart, 
  Sparkles,
  ExternalLink,
  ChevronRight
} from "lucide-react";
import { getCharacters, addCharacter, deleteCharacter, isSupabaseConfigured, resyncDefaultImages } from "@/lib/supabase";

export default function Home() {
  const [characters, setCharacters] = useState<Character[]>([]);
  const [loading, setLoading] = useState<boolean>(true);
  const [searchTerm, setSearchTerm] = useState<string>("");
  const [selectedAffiliation, setSelectedAffiliation] = useState<string>("Tất cả");
  const [sortBy, setSortBy] = useState<string>("bounty_desc");
  
  // Modals state
  const [selectedCharacter, setSelectedCharacter] = useState<Character | null>(null);
  const [isCreateOpen, setIsCreateOpen] = useState<boolean>(false);
  const [isGuideOpen, setIsGuideOpen] = useState<boolean>(false);

  // Form State
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

  const [formError, setFormError] = useState<string>("");

  // Load characters on mount
  useEffect(() => {
    async function loadData() {
      setLoading(true);
      const data = await getCharacters();
      setCharacters(data);
      setLoading(false);
    }
    loadData();
  }, []);

  const [syncing, setSyncing] = useState<boolean>(false);

  const handleSyncImages = async () => {
    setSyncing(true);
    try {
      const success = await resyncDefaultImages();
      if (success) {
        const data = await getCharacters();
        setCharacters(data);
        alert("🎉 Đồng bộ dữ liệu và ảnh chân dung thành công! Toàn bộ dữ liệu nhân vật mới nhất đã được cập nhật lên Supabase.");
      } else {
        alert("Không thể đồng bộ. Vui lòng kiểm tra lại cấu hình kết nối Supabase của bạn.");
      }
    } catch (e) {
      console.error(e);
      alert("Đã xảy ra lỗi khi thực hiện đồng bộ.");
    } finally {
      setSyncing(false);
    }
  };

  // Format currency Belly
  const formatBounty = (num: number) => {
    if (num <= 0) return "???";
    return new Intl.NumberFormat("vi-VN").format(num) + " ฿";
  };

  // Fix object-positioning for characters with unique shapes (tall hair/heads)
  const getObjectPos = (name: string) => {
    if (name === "Vegapunk" || name === "Emporio Ivankov") return "object-center";
    return "object-top";
  };

  // Predefined lists
  const affiliations = [
    "Tất cả",
    "Băng Mũ Rơm",
    "Băng Tóc Đỏ",
    "Băng Râu Trắng",
    "Băng Râu Đen",
    "Cross Guild",
    "Quân Cách Mạng",
    "Hải Quân",
    "Băng Roger",
    "Băng Bách Thú",
    "Băng Big Mom",
    "Băng Trái Tim",
    "Băng Kid",
    "Băng Donquixote",
    "Băng Bonney",
    "Cướp biển Thriller Bark",
    "Baroque Works",
    "Băng Mặt Trời",
    "Băng Rocks",
    "Zou (Tộc Mink)",
    "Băng Arlong",
    "Tộc Người Cá"
  ];

  // Suggestions for character avatar images
  const imagePresets = [
    { name: "Luffy Gear 5", url: "https://images.unsplash.com/photo-1607604276583-eef5d076aa5f?w=400" },
    { name: "Zoro", url: "https://images.unsplash.com/photo-1578632767115-351597cf2477?w=400" },
    { name: "Sử thi", url: "https://images.unsplash.com/photo-1534447677768-be436bb09401?w=400" },
    { name: "Bảo tàng cổ", url: "https://images.unsplash.com/photo-1518709268805-4e9042af9f23?w=400" },
    { name: "Thám hiểm", url: "https://images.unsplash.com/photo-1509198397868-475647b2a1e5?w=400" }
  ];

  // Filter & Sort Logic
  const filteredCharacters = characters
    .filter(char => {
      const matchSearch = 
        char.name.toLowerCase().includes(searchTerm.toLowerCase()) || 
        char.alias?.toLowerCase().includes(searchTerm.toLowerCase()) ||
        char.devil_fruit?.toLowerCase().includes(searchTerm.toLowerCase());
      
      const matchAffiliation = selectedAffiliation === "Tất cả" || char.affiliation.includes(selectedAffiliation);
      
      return matchSearch && matchAffiliation;
    })
    .sort((a, b) => {
      if (sortBy === "bounty_desc") return b.bounty - a.bounty;
      if (sortBy === "bounty_asc") return a.bounty - b.bounty;
      if (sortBy === "age_desc") return (b.age || 0) - (a.age || 0);
      if (sortBy === "age_asc") return (a.age || 0) - (b.age || 0);
      if (sortBy === "height_desc") return (b.height || 0) - (a.height || 0);
      return 0;
    });

  // Handle Form Input Change
  const handleInputChange = (e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement | HTMLTextAreaElement>) => {
    const { name, value } = e.target;
    setFormData(prev => ({ ...prev, [name]: value }));
  };

  // Handle Create Character Submission
  const handleCreateCharacter = async (e: React.FormEvent) => {
    e.preventDefault();
    setFormError("");

    if (!formData.name || !formData.bounty) {
      setFormError("Vui lòng nhập Tên và Tiền truy nã!");
      return;
    }

    const bountyNum = parseInt(formData.bounty.replace(/\D/g, ""));
    if (isNaN(bountyNum) || bountyNum < 0) {
      setFormError("Tiền truy nã phải là một số dương hợp lệ!");
      return;
    }

    const ageNum = formData.age ? parseInt(formData.age) : undefined;
    const heightNum = formData.height ? parseInt(formData.height) : undefined;

    // Default image if empty
    const finalImageUrl = formData.image_url || "https://images.unsplash.com/photo-1534447677768-be436bb09401?w=400";

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
      image_url: finalImageUrl
    };

    try {
      const addedChar = await addCharacter(newCharData);
      setCharacters(prev => [addedChar, ...prev].sort((a, b) => b.bounty - a.bounty));
      
      // Reset Form & Close Modal
      setFormData({
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
      setIsCreateOpen(false);
    } catch (err) {
      setFormError("Không thể thêm nhân vật. Đã xảy ra lỗi!");
      console.error(err);
    }
  };

  // Handle Delete Character
  const handleDelete = async (id: number, e: React.MouseEvent) => {
    e.stopPropagation(); // Ngăn mở chi tiết nhân vật khi bấm nút xóa
    if (confirm("Bạn có chắc chắn muốn gỡ bỏ lệnh truy nã này?")) {
      const success = await deleteCharacter(id);
      if (success) {
        setCharacters(prev => prev.filter(c => c.id !== id));
        if (selectedCharacter?.id === id) {
          setSelectedCharacter(null);
        }
      } else {
        alert("Không thể xóa nhân vật này!");
      }
    }
  };

  // Calculations for Stats Bar
  const totalBounty = characters.reduce((sum, char) => sum + char.bounty, 0);
  const highestBountyChar = characters.length > 0 
    ? [...characters].sort((a,b) => b.bounty - a.bounty)[0] 
    : null;
  const customCount = characters.filter(c => c.is_custom).length;

  return (
    <div className="flex-1 flex flex-col relative overflow-hidden pb-16">
      
      {/* BACKGROUND GRAPHIC ORNAMENTS */}
      <div className="absolute top-20 left-[-10%] w-[50%] h-[500px] bg-sky-500/5 blur-[120px] rounded-full pointer-events-none"></div>
      <div className="absolute bottom-20 right-[-10%] w-[50%] h-[500px] bg-amber-500/5 blur-[120px] rounded-full pointer-events-none"></div>

      {/* HEADER SECTION */}
      <header className="border-b border-amber-500/20 bg-slate-950/80 backdrop-blur-md sticky top-0 z-40">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-4 flex flex-col md:flex-row items-center justify-between gap-4">
          
          {/* Logo & Title */}
          <div className="flex items-center gap-3 group cursor-pointer">
            <div className="w-12 h-12 rounded-xl bg-gradient-to-br from-amber-400 to-amber-600 flex items-center justify-center shadow-lg shadow-amber-500/20 group-hover:rotate-12 transition-transform duration-300">
              <Compass className="w-7 h-7 text-slate-950 animate-spin-slow" />
            </div>
            <div>
              <h1 className="font-serif text-2xl font-black tracking-wider text-amber-400 gold-glow flex items-center gap-2">
                GRAND LINE <span className="text-white font-sans text-sm font-light px-2 py-0.5 rounded-md bg-amber-500/20 border border-amber-500/30">WANTED</span>
              </h1>
              <p className="text-xs text-slate-400 font-medium uppercase tracking-widest">Hệ Thống Quản Lý Truy Nã Hải Tặc</p>
            </div>
          </div>

          {/* Action Buttons */}
          <div className="flex items-center gap-3 w-full md:w-auto justify-end flex-wrap">
            {isSupabaseConfigured && (
              <button
                onClick={handleSyncImages}
                disabled={syncing}
                className="flex items-center gap-2 px-4 py-2 rounded-xl bg-amber-500/10 border border-amber-500/20 text-amber-400 hover:bg-amber-500/20 hover:border-amber-500/40 transition-all font-medium text-sm disabled:opacity-50 cursor-pointer"
                title="Cập nhật toàn bộ ảnh cũ trên Supabase thành ảnh anime chính thức"
              >
                <Sparkles className="w-4 h-4 text-amber-400 animate-pulse" />
                <span>{syncing ? "Đang đồng bộ..." : "Đồng bộ lại ảnh Anime"}</span>
              </button>
            )}

            <button
              onClick={() => setIsGuideOpen(true)}
              className="flex items-center gap-2 px-4 py-2 rounded-xl bg-slate-900 border border-slate-800 text-slate-300 hover:text-amber-400 hover:border-amber-500/30 transition-all font-medium text-sm"
            >
              <Database className="w-4 h-4 text-amber-500" />
              <span>Kết nối Supabase</span>
            </button>
            
            <button
              onClick={() => setIsCreateOpen(true)}
              className="flex items-center gap-2 px-5 py-2.5 rounded-xl bg-gradient-to-r from-amber-500 to-amber-600 text-slate-950 hover:from-amber-400 hover:to-amber-500 transition-all font-bold text-sm shadow-lg shadow-amber-500/10 active:scale-95"
            >
              <Plus className="w-4 h-4 stroke-[3px]" />
              <span>Tạo Lệnh Truy Nã</span>
            </button>
          </div>
        </div>
      </header>

      <main className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 pt-8 flex-1 w-full flex flex-col gap-8">
        
        {/* STATS OVERVIEW DASHBOARD */}
        <section className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
          
          {/* Total Bounty */}
          <div className="glass-panel rounded-2xl p-5 flex items-center gap-4 relative overflow-hidden group">
            <div className="absolute top-0 right-0 p-3 opacity-5 group-hover:scale-110 transition-transform duration-300">
              <TrendingUp className="w-24 h-24 text-amber-400" />
            </div>
            <div className="w-12 h-12 rounded-xl bg-amber-500/10 border border-amber-500/20 flex items-center justify-center">
              <TrendingUp className="w-6 h-6 text-amber-400" />
            </div>
            <div>
              <p className="text-xs font-semibold text-slate-400 uppercase tracking-wider">Tổng Tiền Truy Nã</p>
              <p className="text-xl font-extrabold text-amber-400 mt-1">{formatBounty(totalBounty)}</p>
            </div>
          </div>

          {/* Pirates Count */}
          <div className="glass-panel rounded-2xl p-5 flex items-center gap-4 relative overflow-hidden group">
            <div className="absolute top-0 right-0 p-3 opacity-5 group-hover:scale-110 transition-transform duration-300">
              <Skull className="w-24 h-24 text-rose-500" />
            </div>
            <div className="w-12 h-12 rounded-xl bg-rose-500/10 border border-rose-500/20 flex items-center justify-center">
              <Skull className="w-6 h-6 text-rose-400" />
            </div>
            <div>
              <p className="text-xs font-semibold text-slate-400 uppercase tracking-wider">Lực Lượng Theo Dõi</p>
              <p className="text-xl font-extrabold text-rose-400 mt-1">{characters.length} Đại Hải Tặc</p>
            </div>
          </div>

          {/* Highest Bounty */}
          <div className="glass-panel rounded-2xl p-5 flex items-center gap-4 relative overflow-hidden group col-span-1 sm:col-span-1 lg:col-span-1">
            <div className="absolute top-0 right-0 p-3 opacity-5 group-hover:scale-110 transition-transform duration-300">
              <Sparkles className="w-24 h-24 text-yellow-400" />
            </div>
            <div className="w-12 h-12 rounded-xl bg-yellow-500/10 border border-yellow-500/20 flex items-center justify-center">
              <Sparkles className="w-6 h-6 text-yellow-400" />
            </div>
            <div className="truncate max-w-[200px]">
              <p className="text-xs font-semibold text-slate-400 uppercase tracking-wider truncate">Kẻ Nguy Hiểm Nhất</p>
              <p className="text-md font-bold text-slate-200 mt-1 truncate">{highestBountyChar ? highestBountyChar.name : "N/A"}</p>
              <p className="text-xs font-extrabold text-amber-400">{highestBountyChar ? formatBounty(highestBountyChar.bounty) : ""}</p>
            </div>
          </div>

          {/* User Created */}
          <div className="glass-panel rounded-2xl p-5 flex items-center gap-4 relative overflow-hidden group">
            <div className="absolute top-0 right-0 p-3 opacity-5 group-hover:scale-110 transition-transform duration-300">
              <Users className="w-24 h-24 text-sky-400" />
            </div>
            <div className="w-12 h-12 rounded-xl bg-sky-500/10 border border-sky-500/20 flex items-center justify-center">
              <Users className="w-6 h-6 text-sky-400" />
            </div>
            <div>
              <p className="text-xs font-semibold text-slate-400 uppercase tracking-wider">Hải Tặc Bạn Tạo</p>
              <p className="text-xl font-extrabold text-sky-400 mt-1">
                {customCount} {isSupabaseConfigured ? "(Đồng bộ DB)" : "(Lưu Trữ Local)"}
              </p>
            </div>
          </div>

        </section>

        {/* CONTROLS: SEARCH & FILTERS */}
        <section className="glass-panel rounded-2xl p-6 flex flex-col gap-6">
          <div className="flex flex-col lg:flex-row gap-4 items-center justify-between">
            
            {/* Search Input */}
            <div className="relative w-full lg:max-w-md">
              <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                <Search className="h-5 w-5 text-slate-500" />
              </div>
              <input
                type="text"
                placeholder="Tìm hải tặc, biệt danh, trái ác quỷ..."
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
                className="block w-full pl-10 pr-10 py-3 border border-slate-800 rounded-xl bg-slate-950/80 text-slate-100 placeholder-slate-500 focus:outline-none focus:ring-2 focus:ring-amber-500/50 focus:border-amber-500 transition-all text-sm"
              />
              {searchTerm && (
                <button 
                  onClick={() => setSearchTerm("")}
                  className="absolute inset-y-0 right-0 pr-3 flex items-center text-slate-500 hover:text-slate-300"
                >
                  <X className="w-4 h-4" />
                </button>
              )}
            </div>

            {/* Sort Selector */}
            <div className="flex items-center gap-3 w-full lg:w-auto justify-end">
              <span className="text-xs font-semibold text-slate-400 uppercase tracking-wider whitespace-nowrap">Sắp xếp:</span>
              <select
                value={sortBy}
                onChange={(e) => setSortBy(e.target.value)}
                className="bg-slate-950 border border-slate-800 text-slate-200 py-2 px-4 pr-8 rounded-xl focus:outline-none focus:ring-2 focus:ring-amber-500/50 text-sm font-medium cursor-pointer"
              >
                <option value="bounty_desc">Bounty (Cao → Thấp)</option>
                <option value="bounty_asc">Bounty (Thấp → Cao)</option>
                <option value="age_desc">Tuổi (Lớn → Nhỏ)</option>
                <option value="age_asc">Tuổi (Nhỏ → Lớn)</option>
                <option value="height_desc">Chiều cao (Cao nhất)</option>
              </select>
            </div>
          </div>

          {/* Affiliation Tabs */}
          <div className="flex flex-wrap gap-2 border-t border-slate-800/60 pt-4">
            {affiliations.map((tab) => (
              <button
                key={tab}
                onClick={() => setSelectedAffiliation(tab)}
                className={`px-4 py-2 rounded-xl text-xs font-semibold tracking-wider uppercase transition-all duration-300 ${
                  selectedAffiliation === tab
                    ? "bg-amber-500 text-slate-950 font-bold shadow-lg shadow-amber-500/10"
                    : "bg-slate-900/60 border border-slate-800/80 text-slate-400 hover:text-slate-100 hover:bg-slate-900"
                }`}
              >
                {tab}
              </button>
            ))}
          </div>
        </section>

        {/* PIRATES WANTED BOUNTY BOARD GRID */}
        {loading ? (
          <div className="flex flex-col items-center justify-center py-20 gap-4">
            <div className="w-12 h-12 rounded-full border-4 border-amber-500/30 border-t-amber-500 animate-spin"></div>
            <p className="text-sm font-semibold tracking-widest text-amber-500 uppercase">Đang giong buồm tìm kiếm thông tin...</p>
          </div>
        ) : filteredCharacters.length === 0 ? (
          <div className="text-center py-20 glass-panel rounded-2xl flex flex-col items-center gap-4">
            <Compass className="w-16 h-16 text-slate-600 animate-pulse" />
            <div>
              <p className="text-lg font-bold text-slate-300">Không tìm thấy hải tặc nào phù hợp!</p>
              <p className="text-sm text-slate-500 mt-1">Hãy thử tìm kiếm với từ khóa khác hoặc tự tạo lệnh truy nã mới.</p>
            </div>
            <button
              onClick={() => { setSearchTerm(""); setSelectedAffiliation("Tất cả"); }}
              className="mt-2 px-5 py-2 rounded-xl bg-slate-900 border border-slate-800 text-slate-300 hover:text-amber-400 hover:border-amber-500/30 transition-all text-xs font-bold"
            >
              Đặt lại bộ lọc
            </button>
          </div>
        ) : (
          <section className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-8">
            {filteredCharacters.map((char) => (
              <div
                key={char.id}
                onClick={() => setSelectedCharacter(char)}
                className="wanted-poster rounded-xl overflow-hidden cursor-pointer flex flex-col items-center p-6 text-center shadow-2xl transition-all duration-300 hover:scale-[1.03] hover:rotate-1 group relative shine-effect"
              >
                {/* Delete button for custom ones */}
                {char.is_custom && (
                  <button
                    onClick={(e) => handleDelete(char.id, e)}
                    className="absolute top-3 right-3 z-10 w-8 h-8 rounded-full bg-red-950/90 hover:bg-red-700/100 text-red-400 hover:text-white flex items-center justify-center transition-all border border-red-500/30 shadow-md"
                    title="Xóa lệnh truy nã"
                  >
                    <Trash2 className="w-4 h-4" />
                  </button>
                )}

                {/* Poster Header */}
                <span className="font-serif text-3xl font-black tracking-widest text-[#3b240e] block border-b-2 border-[#543518] pb-1 w-full uppercase">
                  WANTED
                </span>
                <span className="font-serif text-[10px] font-bold tracking-[0.25em] text-[#543518] mt-1.5 block uppercase">
                  DEAD OR ALIVE
                </span>

                {/* Pirate Portrait */}
                <div className="w-full aspect-[4/3] bg-[#d3bc8d] border-4 border-[#3b240e] mt-4 relative overflow-hidden shadow-inner group-hover:brightness-105 transition-all">
                  {/* Overlay vignette */}
                  <div className="absolute inset-0 bg-gradient-to-t from-black/40 via-transparent to-black/10 pointer-events-none z-10"></div>
                  {/* Image fallback if fails */}
                  <img
                    src={char.image_url}
                    alt={char.name}
                    className={`w-full h-full object-cover ${getObjectPos(char.name)} grayscale-[30%] sepia-[40%] contrast-[110%] group-hover:scale-110 transition-transform duration-500`}
                    referrerPolicy="no-referrer"
                    onError={(e) => {
                      (e.target as HTMLImageElement).src = "https://images.unsplash.com/photo-1534447677768-be436bb09401?w=400";
                    }}
                  />
                </div>

                {/* Pirate Name */}
                <h3 className="font-serif text-xl font-black text-[#1a0f00] tracking-wider mt-5 line-clamp-1 uppercase group-hover:text-red-900 transition-colors">
                  {char.name}
                </h3>
                
                {/* Epithet / Alias */}
                <p className="font-serif text-[11px] font-bold text-[#5c3e1e] italic uppercase tracking-wider min-h-[16px] mt-1">
                  &quot;{char.alias || "Vô danh"}&quot;
                </p>

                {/* Bounty Value */}
                <div className="mt-4 w-full bg-[#3b240e]/5 py-2 px-1 border-t border-b border-[#3b240e]/20 flex flex-col items-center">
                  <span className="font-serif text-[9px] font-bold tracking-widest text-[#5c3e1e]/80 uppercase">BOUNTY</span>
                  <span className="font-serif text-lg font-black text-[#36220f] mt-0.5 tracking-wider">
                    {formatBounty(char.bounty)}
                  </span>
                </div>

                {/* Footer Authority */}
                <div className="mt-4 flex justify-between items-center w-full text-[9px] font-serif font-extrabold tracking-widest text-[#5c3e1e] border-t border-[#3b240e]/10 pt-2">
                  <span>MARINE</span>
                  <span className="flex items-center gap-1 group-hover:text-[#1a0f00]">
                    CHI TIẾT <ChevronRight className="w-3 h-3 stroke-[3]" />
                  </span>
                </div>
              </div>
            ))}
          </section>
        )}

      </main>

      {/* CHARACTER DETAILS MODAL */}
      {selectedCharacter && (
        <div className="fixed inset-0 bg-black/85 backdrop-blur-sm z-50 flex items-center justify-center p-4">
          <div className="wanted-poster rounded-2xl w-full max-w-2xl overflow-hidden shadow-2xl relative flex flex-col md:flex-row animate-in fade-in zoom-in-95 duration-300">
            
            {/* Close Button */}
            <button
              onClick={() => setSelectedCharacter(null)}
              className="absolute top-4 right-4 z-20 w-10 h-10 rounded-full bg-[#3b240e] hover:bg-red-900 text-amber-100 hover:text-white flex items-center justify-center transition-all border border-[#543518] shadow-lg"
            >
              <X className="w-5 h-5" />
            </button>

            {/* Left Column: Poster Visuals */}
            <div className="w-full md:w-1/2 p-8 flex flex-col items-center justify-center border-b md:border-b-0 md:border-r border-[#3b240e]/20 bg-[#ebd39a]/30">
              <span className="font-serif text-3xl font-black tracking-widest text-[#3b240e] uppercase">WANTED</span>
              <span className="font-serif text-[9px] font-bold tracking-[0.2em] text-[#543518] mt-1 uppercase">DEAD OR ALIVE</span>
              
              <div className="w-full aspect-[4/3] bg-[#d3bc8d] border-4 border-[#3b240e] mt-4 relative overflow-hidden shadow-md">
                <img
                  src={selectedCharacter.image_url}
                  alt={selectedCharacter.name}
                  className={`w-full h-full object-cover ${getObjectPos(selectedCharacter.name)} grayscale-[20%] sepia-[30%]`}
                  referrerPolicy="no-referrer"
                  onError={(e) => {
                    (e.target as HTMLImageElement).src = "https://images.unsplash.com/photo-1534447677768-be436bb09401?w=400";
                  }}
                />
              </div>

              <h3 className="font-serif text-2xl font-black text-[#1a0f00] mt-4 tracking-wide text-center uppercase">{selectedCharacter.name}</h3>
              <p className="font-serif text-xs font-bold text-[#5c3e1e] italic mt-0.5">({selectedCharacter.alias})</p>

              <div className="mt-4 w-full bg-[#3b240e]/10 py-3 rounded-lg flex flex-col items-center">
                <span className="font-serif text-[9px] font-black tracking-widest text-[#5c3e1e]">TIỀN TRUY NÃ</span>
                <span className="font-serif text-xl font-black text-red-950 mt-1">{formatBounty(selectedCharacter.bounty)}</span>
              </div>
            </div>

            {/* Right Column: Character Specs & Bio */}
            <div className="w-full md:w-1/2 p-8 flex flex-col justify-between overflow-y-auto max-h-[85vh] md:max-h-none text-[#1a0f00]">
              <div>
                <h4 className="font-serif text-lg font-bold border-b-2 border-[#3b240e]/20 pb-1.5 mb-4 text-[#3b240e] flex items-center gap-2">
                  <Skull className="w-5 h-5 text-red-800" /> THÔNG TIN TRUY NÃ
                </h4>

                {/* Specs List */}
                <div className="grid grid-cols-2 gap-y-3.5 gap-x-2 text-xs">
                  <div>
                    <span className="text-[#5c3e1e]/70 block font-bold text-[10px] uppercase">Thế Lực:</span>
                    <span className="font-serif font-bold text-[#1a0f00] text-sm leading-tight">{selectedCharacter.affiliation}</span>
                  </div>
                  <div>
                    <span className="text-[#5c3e1e]/70 block font-bold text-[10px] uppercase">Chức Vụ:</span>
                    <span className="font-serif font-bold text-[#1a0f00] text-sm leading-tight">{selectedCharacter.role || "Chưa rõ"}</span>
                  </div>
                  <div>
                    <span className="text-[#5c3e1e]/70 block font-bold text-[10px] uppercase">Trái Ác Quỷ:</span>
                    <span className="font-serif font-bold text-[#1a0f00] text-sm truncate block" title={selectedCharacter.devil_fruit}>
                      {selectedCharacter.devil_fruit}
                    </span>
                  </div>
                  <div>
                    <span className="text-[#5c3e1e]/70 block font-bold text-[10px] uppercase">Hệ Trái Ác Quỷ:</span>
                    <span className="font-serif font-bold text-amber-950 text-sm">{selectedCharacter.devil_fruit_type || "Không"}</span>
                  </div>
                  <div className="flex items-center gap-2">
                    <Calendar className="w-4 h-4 text-[#5c3e1e]/70" />
                    <div>
                      <span className="text-[#5c3e1e]/70 block font-bold text-[9px] uppercase">Tuổi:</span>
                      <span className="font-serif font-bold text-[#1a0f00]">{selectedCharacter.age ? `${selectedCharacter.age} tuổi` : "Chưa rõ"}</span>
                    </div>
                  </div>
                  <div className="flex items-center gap-2">
                    <Ruler className="w-4 h-4 text-[#5c3e1e]/70" />
                    <div>
                      <span className="text-[#5c3e1e]/70 block font-bold text-[9px] uppercase">Chiều Cao:</span>
                      <span className="font-serif font-bold text-[#1a0f00]">{selectedCharacter.height ? `${selectedCharacter.height} cm` : "Chưa rõ"}</span>
                    </div>
                  </div>
                  <div className="col-span-2">
                    <span className="text-[#5c3e1e]/70 block font-bold text-[10px] uppercase">Quê Quán:</span>
                    <span className="font-serif font-bold text-[#1a0f00] text-sm">{selectedCharacter.hometown || "Chưa rõ"}</span>
                  </div>
                  <div className="col-span-2">
                    <span className="text-[#5c3e1e]/70 block font-bold text-[10px] uppercase">Trạng Thái Chính Phủ:</span>
                    <span className={`inline-flex items-center gap-1.5 px-2.5 py-0.5 rounded-full text-[10px] font-bold uppercase border mt-1 font-serif ${
                      selectedCharacter.status === "Còn sống"
                        ? "bg-green-100 border-green-300 text-green-800"
                        : "bg-red-100 border-red-300 text-red-800"
                    }`}>
                      <Heart className="w-3 h-3 fill-current" /> {selectedCharacter.status}
                    </span>
                  </div>
                </div>

                {/* Lore / Bio */}
                <div className="mt-6">
                  <span className="text-[#5c3e1e]/70 block font-bold text-[10px] uppercase mb-1">Hồ Sơ Tội Phạm / Tiểu Sử:</span>
                  <p className="font-serif italic text-sm text-[#2a1a08] leading-relaxed bg-[#f3e5ab]/40 p-3 rounded-lg border border-[#3b240e]/10">
                    &ldquo;{selectedCharacter.description}&rdquo;
                  </p>
                </div>
              </div>

              {/* Card Footer Warning */}
              <div className="mt-8 pt-4 border-t border-[#3b240e]/15 text-[9px] font-serif font-black tracking-wider text-[#5c3e1e]/80 text-center uppercase">
                Bất cứ ai cung cấp thông tin dẫn tới việc bắt giữ đối tượng này sẽ được trao thưởng đầy đủ như ghi nhận tại Lệnh Truy Nã.
              </div>
            </div>

          </div>
        </div>
      )}

      {/* CREATE NEW BOUNTY MODAL */}
      {isCreateOpen && (
        <div className="fixed inset-0 bg-black/85 backdrop-blur-sm z-50 flex items-center justify-center p-4">
          <div className="bg-slate-900 border border-slate-800 rounded-2xl w-full max-w-2xl overflow-hidden shadow-2xl relative animate-in fade-in zoom-in-95 duration-300">
            
            {/* Header */}
            <div className="border-b border-slate-800 bg-slate-950 px-6 py-4 flex items-center justify-between">
              <div className="flex items-center gap-2">
                <Compass className="w-5 h-5 text-amber-400" />
                <h3 className="text-lg font-bold text-amber-400 font-serif tracking-wide uppercase">Thiết Kế Lệnh Truy Nã</h3>
              </div>
              <button
                onClick={() => setIsCreateOpen(false)}
                className="w-8 h-8 rounded-full bg-slate-900 hover:bg-slate-800 text-slate-400 hover:text-white flex items-center justify-center transition-all"
              >
                <X className="w-4 h-4" />
              </button>
            </div>

            {/* Form */}
            <form onSubmit={handleCreateCharacter} className="p-6 overflow-y-auto max-h-[80vh] flex flex-col gap-5">
              
              {formError && (
                <div className="p-3 bg-red-950/80 border border-red-500/40 rounded-xl text-xs font-bold text-red-300 flex items-center gap-2">
                  <Skull className="w-4 h-4 text-red-400" /> {formError}
                </div>
              )}

              {/* Row 1: Name and Alias */}
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                <div>
                  <label className="block text-xs font-bold text-slate-400 uppercase tracking-wider mb-1.5">Tên Hải Tặc *</label>
                  <input
                    type="text"
                    name="name"
                    required
                    placeholder="VD: Portgas D. Ace"
                    value={formData.name}
                    onChange={handleInputChange}
                    className="w-full bg-slate-950 border border-slate-800 rounded-xl px-4 py-2.5 text-slate-200 text-sm focus:ring-2 focus:ring-amber-500/40 focus:border-amber-500 focus:outline-none"
                  />
                </div>
                <div>
                  <label className="block text-xs font-bold text-slate-400 uppercase tracking-wider mb-1.5">Biệt Danh / Băng Hiệu</label>
                  <input
                    type="text"
                    name="alias"
                    placeholder="VD: Hỏa Quyền"
                    value={formData.alias}
                    onChange={handleInputChange}
                    className="w-full bg-slate-950 border border-slate-800 rounded-xl px-4 py-2.5 text-slate-200 text-sm focus:ring-2 focus:ring-amber-500/40 focus:border-amber-500 focus:outline-none"
                  />
                </div>
              </div>

              {/* Row 2: Bounty and Affiliation */}
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                <div>
                  <label className="block text-xs font-bold text-slate-400 uppercase tracking-wider mb-1.5">Tiền Truy Nã (Belly) *</label>
                  <input
                    type="text"
                    name="bounty"
                    required
                    placeholder="VD: 550,000,000"
                    value={formData.bounty}
                    onChange={(e) => {
                      const cleanVal = e.target.value.replace(/\D/g, "");
                      const formatted = cleanVal ? parseInt(cleanVal).toLocaleString("vi-VN") : "";
                      setFormData(prev => ({ ...prev, bounty: formatted }));
                    }}
                    className="w-full bg-slate-950 border border-slate-800 rounded-xl px-4 py-2.5 text-slate-200 text-sm focus:ring-2 focus:ring-amber-500/40 focus:border-amber-500 focus:outline-none"
                  />
                </div>
                <div>
                  <label className="block text-xs font-bold text-slate-400 uppercase tracking-wider mb-1.5">Thế Lực / Băng Hải Tặc</label>
                  <select
                    name="affiliation"
                    value={formData.affiliation}
                    onChange={handleInputChange}
                    className="w-full bg-slate-950 border border-slate-800 rounded-xl px-4 py-2.5 text-slate-200 text-sm focus:ring-2 focus:ring-amber-500/40 focus:border-amber-500 focus:outline-none"
                  >
                    <option value="Băng Mũ Rơm">Băng Mũ Rơm</option>
                    <option value="Băng Tóc Đỏ">Băng Tóc Đỏ</option>
                    <option value="Băng Râu Trắng">Băng Râu Trắng</option>
                    <option value="Băng Râu Đen">Băng Râu Đen</option>
                    <option value="Cross Guild">Cross Guild</option>
                    <option value="Quân Cách Mạng">Quân Cách Mạng</option>
                    <option value="Hải Quân">Hải Quân</option>
                    <option value="Khác">Lực lượng khác</option>
                  </select>
                </div>
              </div>

              {/* Row 3: Role and Hometown */}
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                <div>
                  <label className="block text-xs font-bold text-slate-400 uppercase tracking-wider mb-1.5">Chức Vụ / Vai Trò</label>
                  <input
                    type="text"
                    name="role"
                    placeholder="VD: Thuyền trưởng, Hoa tiêu..."
                    value={formData.role}
                    onChange={handleInputChange}
                    className="w-full bg-slate-950 border border-slate-800 rounded-xl px-4 py-2.5 text-slate-200 text-sm focus:ring-2 focus:ring-amber-500/40 focus:border-amber-500 focus:outline-none"
                  />
                </div>
                <div>
                  <label className="block text-xs font-bold text-slate-400 uppercase tracking-wider mb-1.5">Quê Quán</label>
                  <input
                    type="text"
                    name="hometown"
                    placeholder="VD: Đảo Spada, Biển Đông"
                    value={formData.hometown}
                    onChange={handleInputChange}
                    className="w-full bg-slate-950 border border-slate-800 rounded-xl px-4 py-2.5 text-slate-200 text-sm focus:ring-2 focus:ring-amber-500/40 focus:border-amber-500 focus:outline-none"
                  />
                </div>
              </div>

              {/* Row 4: Devil Fruit & Devil Fruit Type */}
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                <div>
                  <label className="block text-xs font-bold text-slate-400 uppercase tracking-wider mb-1.5">Trái Ác Quỷ Sở Hữu</label>
                  <input
                    type="text"
                    name="devil_fruit"
                    placeholder="VD: Mera Mera no Mi"
                    value={formData.devil_fruit}
                    onChange={handleInputChange}
                    className="w-full bg-slate-950 border border-slate-800 rounded-xl px-4 py-2.5 text-slate-200 text-sm focus:ring-2 focus:ring-amber-500/40 focus:border-amber-500 focus:outline-none"
                  />
                </div>
                <div>
                  <label className="block text-xs font-bold text-slate-400 uppercase tracking-wider mb-1.5">Hệ Trái Ác Quỷ</label>
                  <select
                    name="devil_fruit_type"
                    value={formData.devil_fruit_type}
                    onChange={handleInputChange}
                    className="w-full bg-slate-950 border border-slate-800 rounded-xl px-4 py-2.5 text-slate-200 text-sm focus:ring-2 focus:ring-amber-500/40 focus:border-amber-500 focus:outline-none"
                  >
                    <option value="Không có">Không sở hữu</option>
                    <option value="Paramecia">Paramecia (Siêu nhân)</option>
                    <option value="Logia">Logia (Tự nhiên)</option>
                    <option value="Zoan">Zoan (Động vật)</option>
                    <option value="Zoan Thần Thoại">Zoan Thần Thoại</option>
                    <option value="Chưa xác định">Chưa xác định / Khác</option>
                  </select>
                </div>
              </div>

              {/* Row 5: Age, Height, Status */}
              <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
                <div>
                  <label className="block text-xs font-bold text-slate-400 uppercase tracking-wider mb-1.5">Tuổi</label>
                  <input
                    type="number"
                    name="age"
                    placeholder="VD: 20"
                    value={formData.age}
                    onChange={handleInputChange}
                    className="w-full bg-slate-950 border border-slate-800 rounded-xl px-4 py-2.5 text-slate-200 text-sm focus:ring-2 focus:ring-amber-500/40 focus:border-amber-500 focus:outline-none"
                  />
                </div>
                <div>
                  <label className="block text-xs font-bold text-slate-400 uppercase tracking-wider mb-1.5">Chiều cao (cm)</label>
                  <input
                    type="number"
                    name="height"
                    placeholder="VD: 185"
                    value={formData.height}
                    onChange={handleInputChange}
                    className="w-full bg-slate-950 border border-slate-800 rounded-xl px-4 py-2.5 text-slate-200 text-sm focus:ring-2 focus:ring-amber-500/40 focus:border-amber-500 focus:outline-none"
                  />
                </div>
                <div>
                  <label className="block text-xs font-bold text-slate-400 uppercase tracking-wider mb-1.5">Trạng thái chính phủ</label>
                  <select
                    name="status"
                    value={formData.status}
                    onChange={handleInputChange}
                    className="w-full bg-slate-950 border border-slate-800 rounded-xl px-4 py-2.5 text-slate-200 text-sm focus:ring-2 focus:ring-amber-500/40 focus:border-amber-500 focus:outline-none"
                  >
                    <option value="Còn sống">Còn sống (ALIVE)</option>
                    <option value="Đã mất">Đã mất (DEAD)</option>
                  </select>
                </div>
              </div>

              {/* Row 6: Image URL and Presets */}
              <div className="flex flex-col gap-2">
                <label className="block text-xs font-bold text-slate-400 uppercase tracking-wider">Đường Dẫn Ảnh Chân Dung (Image URL)</label>
                <input
                  type="url"
                  name="image_url"
                  placeholder="VD: https://images.unsplash.com/... hoặc chọn gợi ý bên dưới"
                  value={formData.image_url}
                  onChange={handleInputChange}
                  className="w-full bg-slate-950 border border-slate-800 rounded-xl px-4 py-2.5 text-slate-200 text-sm focus:ring-2 focus:ring-amber-500/40 focus:border-amber-500 focus:outline-none"
                />
                
                {/* Image Presets Suggestions */}
                <div className="flex flex-wrap items-center gap-1.5 mt-1">
                  <span className="text-[10px] font-bold text-slate-500 uppercase tracking-wider mr-1">Ảnh gợi ý:</span>
                  {imagePresets.map((preset) => (
                    <button
                      key={preset.name}
                      type="button"
                      onClick={() => setFormData(prev => ({ ...prev, image_url: preset.url }))}
                      className={`text-[10px] px-2.5 py-1 rounded-lg border font-semibold transition-all ${
                        formData.image_url === preset.url
                          ? "bg-amber-500/20 border-amber-500 text-amber-400"
                          : "bg-slate-950 border-slate-800 text-slate-400 hover:text-slate-200 hover:border-slate-700"
                      }`}
                    >
                      {preset.name}
                    </button>
                  ))}
                </div>
              </div>

              {/* Row 7: Description */}
              <div>
                <label className="block text-xs font-bold text-slate-400 uppercase tracking-wider mb-1.5">Mô tả hành vi phạm tội / Tiểu sử</label>
                <textarea
                  name="description"
                  rows={3}
                  placeholder="VD: Là con trai của Vua Hải Tặc Roger, đội trưởng đội 2 băng Râu Trắng, sở hữu trái ác quỷ lửa..."
                  value={formData.description}
                  onChange={handleInputChange}
                  className="w-full bg-slate-950 border border-slate-800 rounded-xl px-4 py-2.5 text-slate-200 text-sm focus:ring-2 focus:ring-amber-500/40 focus:border-amber-500 focus:outline-none resize-none"
                ></textarea>
              </div>

              {/* Submit Buttons */}
              <div className="flex items-center justify-end gap-3 border-t border-slate-800/80 pt-5 mt-2">
                <button
                  type="button"
                  onClick={() => setIsCreateOpen(false)}
                  className="px-5 py-2.5 rounded-xl bg-slate-900 border border-slate-800 hover:border-slate-700 text-slate-300 font-bold text-sm transition-all"
                >
                  Hủy bỏ
                </button>
                <button
                  type="submit"
                  className="px-6 py-2.5 rounded-xl bg-gradient-to-r from-amber-500 to-amber-600 hover:from-amber-400 hover:to-amber-500 text-slate-950 font-black text-sm shadow-lg shadow-amber-500/10 transition-all"
                >
                  Gửi Chính Phủ / Phát Hành
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* SUPABASE CONNECTION GUIDE MODAL */}
      {isGuideOpen && (
        <div className="fixed inset-0 bg-black/85 backdrop-blur-sm z-50 flex items-center justify-center p-4">
          <div className="bg-slate-900 border border-slate-800 rounded-2xl w-full max-w-2xl overflow-hidden shadow-2xl relative animate-in fade-in zoom-in-95 duration-300">
            
            {/* Header */}
            <div className="border-b border-slate-800 bg-slate-950 px-6 py-4 flex items-center justify-between">
              <div className="flex items-center gap-2">
                <Database className="w-5 h-5 text-amber-400" />
                <h3 className="text-lg font-bold text-amber-400 font-serif tracking-wide uppercase">Cấu Hình Kết Nối Supabase</h3>
              </div>
              <button
                onClick={() => setIsGuideOpen(false)}
                className="w-8 h-8 rounded-full bg-slate-900 hover:bg-slate-800 text-slate-400 hover:text-white flex items-center justify-center transition-all"
              >
                <X className="w-4 h-4" />
              </button>
            </div>

            {/* Guide Content */}
            <div className="p-6 overflow-y-auto max-h-[80vh] flex flex-col gap-5 text-slate-300 text-sm leading-relaxed">
              
              <div className="p-4 rounded-xl bg-amber-500/5 border border-amber-500/10 flex gap-3">
                <Info className="w-5 h-5 text-amber-400 shrink-0 mt-0.5" />
                <div>
                  <h4 className="font-bold text-amber-400">Ứng dụng hoạt động thông minh hai chế độ!</h4>
                  <p className="text-xs text-slate-400 mt-1">
                    Hệ thống đang chạy chế độ <strong>Local Fallback</strong>: mọi thao tác tạo mới hay xóa lệnh truy nã đều hoạt động tức thì thông qua <strong>LocalStorage</strong> và <strong>Mock Data</strong>. Khi bạn cung cấp các khóa của Supabase, hệ thống sẽ tự động chuyển sang lưu trữ đám mây!
                  </p>
                </div>
              </div>

              <div>
                <h4 className="font-bold text-slate-100 flex items-center gap-1.5 mb-2">
                  <span className="w-5 h-5 rounded-full bg-amber-500/10 border border-amber-500/20 text-amber-400 flex items-center justify-center text-xs">1</span>
                  Tạo Cơ Sở Dữ Liệu Trên Supabase
                </h4>
                <p className="text-slate-400 text-xs mb-3">
                  Đăng nhập vào <a href="https://supabase.com" target="_blank" rel="noopener noreferrer" className="text-amber-400 underline inline-flex items-center gap-0.5">Supabase Console <ExternalLink className="w-3 h-3" /></a>, tạo một Project mới. Vào mục <strong>SQL Editor</strong> và dán nội dung trong file sau để tạo bảng và nạp dữ liệu:
                </p>
                <div className="bg-slate-950 rounded-xl border border-slate-800 p-3 flex justify-between items-center">
                  <span className="text-xs font-mono text-slate-400">/supabase-schema.sql</span>
                  <span className="text-xs font-bold text-amber-400">Đã có sẵn tại gốc dự án</span>
                </div>
              </div>

              <div>
                <h4 className="font-bold text-slate-100 flex items-center gap-1.5 mb-2">
                  <span className="w-5 h-5 rounded-full bg-amber-500/10 border border-amber-500/20 text-amber-400 flex items-center justify-center text-xs">2</span>
                  Thiết Lập Biến Môi Trường
                </h4>
                <p className="text-slate-400 text-xs mb-3">
                  Tạo một tệp tin tên là <code className="text-amber-400 font-mono">.env.local</code> ở thư mục gốc của dự án (<code className="font-mono">/one-piece-app/.env.local</code>) và điền thông số từ mục <strong>Project Settings → API</strong> của Supabase:
                </p>
                <pre className="bg-slate-950 p-4 rounded-xl border border-slate-800 text-xs font-mono text-amber-200 overflow-x-auto whitespace-pre">
{`NEXT_PUBLIC_SUPABASE_URL=your_supabase_project_url
NEXT_PUBLIC_SUPABASE_ANON_KEY=your_supabase_anon_key`}
                </pre>
              </div>

              <div>
                <h4 className="font-bold text-slate-100 flex items-center gap-1.5 mb-2">
                  <span className="w-5 h-5 rounded-full bg-amber-500/10 border border-amber-500/20 text-amber-400 flex items-center justify-center text-xs">3</span>
                  Chạy Ứng Dụng Đã Kết Nối
                </h4>
                <p className="text-slate-400 text-xs">
                  Sau khi thêm tệp <code className="font-mono">.env.local</code>, hãy khởi động lại môi trường dev server (<code className="font-mono">npm run dev</code>). Hệ thống sẽ phát hiện cấu hình và tự động đồng bộ dữ liệu hai chiều trực tiếp tới Supabase của bạn!
                </p>
              </div>

              <div className="border-t border-slate-800/80 pt-4 flex justify-end">
                <button
                  onClick={() => setIsGuideOpen(false)}
                  className="px-5 py-2.5 rounded-xl bg-amber-500 text-slate-950 font-bold text-xs hover:bg-amber-400 transition-all uppercase tracking-wider"
                >
                  Tôi đã hiểu!
                </button>
              </div>

            </div>
          </div>
        </div>
      )}

      {/* FOOTER */}
      <footer className="mt-auto max-w-7xl mx-auto px-4 text-center text-xs text-slate-500 border-t border-slate-900 pt-8 w-full flex flex-col md:flex-row items-center justify-between gap-4">
        <p>© 2026 Grand Line Bounty Board. Được thiết kế lấy cảm hứng từ tác phẩm huyền thoại One Piece của Eiichiro Oda.</p>
        <p className="flex items-center gap-1.5">
          <Database className="w-3.5 h-3.5 text-amber-500" />
          <span>Đồng bộ hóa cơ sở dữ liệu: {isSupabaseConfigured ? "Đã bật Supabase" : "Chế độ Local Offline"}</span>
        </p>
      </footer>

    </div>
  );
}
