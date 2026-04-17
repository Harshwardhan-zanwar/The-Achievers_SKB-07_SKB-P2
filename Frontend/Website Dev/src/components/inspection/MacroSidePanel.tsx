"use client";

/**
 * MacroSidePanel
 * ─────────────────────────────────────────────────────────────────────────────
 * The right-side panel shown in the INITIAL (pre-transition) state of the
 * Inspection Dashboard.  It displays six surveillance metric cards with mini
 * sparkbar charts, then a tabbed Messages / Notes section.
 *
 * Data wiring note:
 *  – Replace the `macroMetrics` and `messages` constants below with real API
 *    calls (e.g. fetch from /api/surveillance/macro) once the backend is ready.
 *  – Each metric card's `bars` array is the time-series sparkline data.
 */

import { useState, useEffect } from 'react';
import { Bell, Newspaper, Search, MapPin, ShieldAlert, Bug, Thermometer, Droplets } from 'lucide-react';
import type { ThemeTokens } from './themeTokens';
import DiagnosticModule from '../diagnose/DiagnosticModule';

// ─── DATA TYPES ───────────────────────────────────────────────────────────────
interface MetricCard {
  id: string;
  label: string;
  value: string;
  sub: string;
  dot: string;           // Tailwind bg-* class for the pulsing dot
  color: string;         // Tailwind gradient classes for the icons
  icon: any;             // Lucide icon component
}

interface Message {
  id: number;
  type: 'warning' | 'officer' | 'info';
  time: string;
  title: string;
  body: string;
  avatar: string | null;
}

interface NewsItem {
  id: number;
  title: string;
  source: string;
  time: string;
  image: string;
  url: string;
}

// ─── MOCK DATA ────────────────────────────────────────────────────────────────
// TODO: Replace with real API fetch
// ─── MOCK DATA (Fallback) ────────────────────────────────────────────────────────
const initialMetrics: MetricCard[] = [
  {
    id: 'scans', label: 'ACTIVE HERD SCANS', value: '...', sub: 'Loading...',
    dot: 'bg-emerald-500',
    color: 'from-emerald-400 to-green-600',
    icon: Search,
  },
  {
    id: 'hotspot', label: 'DISEASE HOTSPOTS', value: '...', sub: 'Loading...',
    dot: 'bg-blue-500',
    color: 'from-blue-400 to-blue-600',
    icon: MapPin,
  },
  {
    id: 'risk', label: 'OUTBREAK RISK', value: '...', sub: 'Loading...',
    dot: 'bg-red-500',
    color: 'from-orange-400 to-red-500',
    icon: ShieldAlert,
  },
  {
    id: 'pathogen', label: 'DOMINANT VIRUS', value: '...', sub: 'Loading...',
    dot: 'bg-amber-500',
    color: 'from-amber-400 to-orange-500',
    icon: Bug,
  },
  {
    id: 'temp', label: 'VET RESPONSE', value: '...', sub: 'Loading...',
    dot: 'bg-cyan-500',
    color: 'from-cyan-400 to-sky-500',
    icon: Thermometer,
  },
  {
    id: 'precip', label: 'HERD IMMUNITY', value: '...', sub: 'Loading...',
    dot: 'bg-indigo-400',
    color: 'from-indigo-400 to-blue-500',
    icon: Droplets,
  },
];

const news: NewsItem[] = [
  {
    id: 1, title: 'Lumpy Skin Disease (LSD) Alert: Rajasthan sees 15% rise in cases; Vaccination drive intensified.',
    source: 'DAHD India', time: '1h ago',
    image: 'https://images.unsplash.com/photo-1547496502-affa22d38842?q=80&w=120&auto=format&fit=crop',
    url: 'https://dahd.nic.in/',
  },
  {
    id: 2, title: 'AI for Animals: New edge-computing tools enable FMD detection in zero-connectivity rural zones.',
    source: 'TechRural', time: '3h ago',
    image: 'https://images.unsplash.com/photo-1596733430284-f74377612f35?q=80&w=120&auto=format&fit=crop',
    url: 'https://www.icar.org.in/',
  },
  {
    id: 3, title: 'Combating Mastitis: Dairy farmers in Punjab adopt real-time AI monitoring to reduce milk wastage.',
    source: 'Livestock World', time: '8h ago',
    image: 'https://images.unsplash.com/photo-1500595046743-cd271d694d30?q=80&w=120&auto=format&fit=crop',
    url: 'https://www.fao.org/animal-health/en/',
  },
  {
    id: 4, title: 'FMD Outbreak: Government issues inter-state transport guidelines for cattle in South India.',
    source: 'Hindustan Times', time: '12h ago',
    image: 'https://images.unsplash.com/photo-1527153355510-41e22585200b?q=80&w=120&auto=format&fit=crop',
    url: 'https://www.hindustantimes.com/india-news',
  },
  {
    id: 5, title: 'Smart Farming: How Multilingual Voice Assistance is helping rural farmers diagnose cattle health.',
    source: 'AgriTech Hub', time: '1d ago',
    image: 'https://images.unsplash.com/photo-1516467508483-a7212febe31a?q=80&w=120&auto=format&fit=crop',
    url: 'https://www.digitalindia.gov.in/',
  },
  {
    id: 6, title: 'Veterinary Services: Mobile clinics deployed in High-Risk LSD zones based on AI heatmaps.',
    source: 'The Hindu', time: '2d ago',
    image: 'https://images.unsplash.com/photo-1516467508483-a7212febe31a?q=80&w=120&auto=format&fit=crop',
    url: 'https://www.thehindu.com/sci-tech/agriculture/',
  },
];

const messages: Message[] = [
  {
    id: 1, type: 'warning', time: '5m ago',
    title: 'Outbreak Warning!',
    body: 'Heatmap detects 12 new LSD symptoms in Barmer cluster. Visual confirmation by edge-AI recommended.',
    avatar: null,
  },
  {
    id: 2, type: 'officer', time: '10m ago',
    title: 'Vet Officer – Dr. Arjun K.',
    body: 'Vaccination stock for FMD dispatched to Western Rajasthan. Please track delivery geolocation.',
    avatar: 'https://api.dicebear.com/7.x/notionists/svg?seed=Arjun',
  },
  {
    id: 3, type: 'info', time: '22m ago',
    title: 'System Update',
    body: 'Multilingual Voice Assistant now supports 5 additional regional languages for offline diagnosis.',
    avatar: null,
  },
];

// ─── COMPONENT ────────────────────────────────────────────────────────────────
interface Props {
  theme: ThemeTokens;
  isNightVision: boolean;
}

export default function MacroSidePanel({ theme, isNightVision }: Props) {
  const [activeTab, setActiveTab] = useState<'messages' | 'news'>('news');
  const [macroMetrics, setMacroMetrics] = useState<MetricCard[]>(initialMetrics);

  useEffect(() => {
    fetch('/api/analytics/national')
      .then(res => res.json())
      .then(res => {
        if (res.status === 'success') {
          const data = res.data;
          setMacroMetrics(prev => prev.map(m => {
            if (m.id === 'scans') {
              return {
                ...m,
                value: String(data.overview.total_scans_all_time || 0),
                sub: `${data.overview.national_positivity_rate_pct || 0}% Positivity`
              };
            }
            if (m.id === 'hotspot') {
              return {
                ...m,
                value: data.hotspot.primary_district || 'N/A',
                sub: `${data.hotspot.cases_in_cluster || 0} cases in cluster`
              };
            }
            if (m.id === 'risk') {
              const positivity = data.overview.national_positivity_rate_pct || 0;
              const growth = Math.min(Math.max(data.velocity.week_over_week_growth_pct || 0, -100), 100);

              // Composite Risk Score: weights Positivity (70%) and Growth (30%)
              const score = Math.min(Math.round((positivity * 0.7) + ((growth + 100) / 2 * 0.3)), 100);

              let label = "LOW";
              if (score > 75) label = "CRITICAL";
              else if (score > 50) label = "HIGH";
              else if (score > 25) label = "MODERATE";

              return {
                ...m,
                value: `${label} (${score})`,
                sub: `Velocity: ${growth > 0 ? '+' : ''}${growth}%`
              };
            }
            if (m.id === 'pathogen') {
              return {
                ...m,
                value: data.overview.dominant_pathogen || 'Unknown',
                sub: 'Dominant Strain'
              };
            }
            if (m.id === 'temp') {
              return {
                ...m,
                value: String(data.overview.scans_last_7_days || 0),
                sub: 'Scans this week'
              };
            }
            if (m.id === 'precip') {
              return {
                ...m,
                value: `${data.area.total_affected_area_sq_km || 0} km²`,
                sub: 'Geographic Area'
              };
            }
            return m;
          }));
        }
      })
      .catch(err => {
        console.error("Fetch Error:", err);
      });
  }, []);

  return (
    <div className={`flex-1 flex flex-col h-full overflow-hidden rounded-[24px] border ${theme.cardBorder} ${theme.sidePanel} shadow-[0_4px_30px_rgba(16,185,129,0.06)]`}>

      {/* ── Section label ─────────────────────────────────────────────────── */}
      <div className="px-5 pt-6 pb-4 shrink-0">
        <p className={`text-[14px] font-black uppercase tracking-[0.2em] ${theme.sectionLabel}`}>
          INDIA · LIVESTOCK SURVEILLANCE METRICS
        </p>
      </div>

      {/* ── 2×3 Metric card grid ──────────────────────────────────────────── */}
      <div className="px-4 grid grid-cols-2 gap-3 shrink-0">
        {macroMetrics.map(m => (
          <div
            key={m.id}
            className={`${theme.cardBg} ${theme.cardBorder} rounded-2xl p-4 flex items-center justify-between hover:shadow-lg transition-all duration-300 group`}
          >
            <div className="min-w-0 mr-2">
              <p className={`text-[9px] font-black uppercase tracking-widest ${theme.sectionLabel} mb-2 flex items-center gap-1.5 truncate`}>
                {m.label}
                <span className={`w-1.5 h-1.5 rounded-full inline-block shrink-0 ${m.dot} animate-pulse`} />
              </p>
              <p className={`text-base font-black ${theme.value} leading-tight truncate`}>{m.value}</p>
              <p className={`text-[10px] ${theme.subText} mt-0.5 truncate`}>{m.sub}</p>
            </div>
            <div className={`w-11 h-11 rounded-2xl flex items-center justify-center bg-gradient-to-br ${m.color} shadow-lg shadow-emerald-500/10 group-hover:scale-110 transition-transform duration-300`}>
              <m.icon className="w-5 h-5 text-white" />
            </div>
          </div>
        ))}
      </div>

      {/* ── Crop Diagnostic Scanner ────────────────────────────────────────── */}
      {/* <div className="px-4 mt-4 shrink-0">
        <div className={`${theme.cardBg} ${theme.cardBorder} rounded-3xl overflow-hidden shadow-sm border h-[240px] flex flex-col`}>
           <div className="px-6 pt-5 flex justify-between items-center">
              <h3 className={`font-bold text-sm ${theme.value} flex items-center gap-2`}>
                 <Search className="w-4 h-4 text-emerald-500" />
                 Instant Crop Scan
              </h3>
              <span className="text-[10px] font-bold text-emerald-500 px-2 py-0.5 bg-emerald-50 dark:bg-emerald-500/10 rounded-full">AI READY</span>
           </div>
           <div className="flex-1 min-h-0">
              <DiagnosticModule isDarkMode={isNightVision} />
           </div>
        </div>
      </div> */}

      {/* ── Messages / Notes tabs ──────────────────────────────────────────── */}
      <div className="flex-1 flex flex-col overflow-hidden px-4 mt-4 pb-4 min-h-0">

        {/* Tab bar */}
        <div className={`flex gap-4 border-b ${theme.accentBorder} mb-3 shrink-0`}>
          {(['messages', 'news'] as const).map(tab => (
            <button
              key={tab}
              onClick={() => setActiveTab(tab)}
              className={`pb-2 text-[14px] font-extrabold uppercase tracking-widest transition-all ${activeTab === tab ? theme.tabActive : theme.tabInactive
                }`}
            >
              {tab === 'messages' ? (
                <span className="flex items-center gap-1.5">
                  <Bell className="w-3 h-3" />
                  Messages
                </span>
              ) : (
                <span className="flex items-center gap-1.5">
                  <Newspaper className="w-3 h-3" />
                  News
                </span>
              )}
            </button>
          ))}
        </div>

        {/* Scrollable message/news list */}
        <div className="flex-1 h-0 overflow-y-auto flex flex-col gap-2.5">
          {activeTab === 'messages' ? (
            messages.map(msg => (
              <div key={msg.id} className={`rounded-[16px] p-3.5 ${theme.msgCard} flex gap-3 items-start shrink-0`}>
                {/* Avatar or pulse dot */}
                {msg.avatar ? (
                  <img
                    src={msg.avatar}
                    alt={msg.title}
                    className="w-9 h-9 rounded-full shrink-0 border border-white/20 object-cover"
                  />
                ) : (
                  <div className={`w-9 h-9 rounded-full shrink-0 flex items-center justify-center ${msg.type === 'warning' ? 'bg-red-100 dark:bg-red-950/40' : 'bg-blue-100'
                    }`}>
                    <div className={`w-2.5 h-2.5 rounded-full ${msg.type === 'warning' ? 'bg-red-500 animate-pulse' : 'bg-blue-400'
                      }`} />
                  </div>
                )}
                <div className="flex-1 min-w-0">
                  <div className="flex justify-between items-start gap-2">
                    <p className={`text-[11px] font-bold ${theme.msgText} leading-tight`}>{msg.title}</p>
                    <span className={`text-[9px] font-bold shrink-0 ${theme.msgSub}`}>{msg.time}</span>
                  </div>
                  <p className={`text-[10px] leading-relaxed mt-1 ${theme.msgSub}`}>{msg.body}</p>
                </div>
              </div>
            ))
          ) : (
            news.map(item => (
              <a
                key={item.id}
                href={item.url}
                target="_blank"
                rel="noopener noreferrer"
                className={`rounded-[16px] overflow-hidden ${theme.msgCard} flex items-center gap-3 p-2 hover:bg-white/10 transition-colors group border border-transparent hover:border-emerald-500/20 shrink-0`}
              >
                <div className="w-20 h-20 rounded-xl overflow-hidden shrink-0">
                  <img src={item.image} className="w-full h-full object-cover group-hover:scale-110 transition-transform duration-500" alt="news" />
                </div>
                <div className="flex-1 min-w-0 pr-1">
                  <div className="flex justify-between items-center mb-1.5">
                    <span className={`text-[10px] font-black uppercase text-emerald-500 tracking-wider`}>{item.source}</span>
                    <span className={`text-[10px] font-bold ${theme.msgSub}`}>{item.time}</span>
                  </div>
                  <p className={`text-[13px] font-bold ${theme.msgText} leading-snug line-clamp-3 overflow-hidden`}>
                    {item.title}
                  </p>
                </div>
              </a>
            ))
          )}
        </div>
      </div>
    </div>
  );
}
