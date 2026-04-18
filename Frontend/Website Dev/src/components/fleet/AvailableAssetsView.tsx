"use client";

import { useState, useRef } from 'react';
import Map, { Marker } from 'react-map-gl/maplibre';
import 'maplibre-gl/dist/maplibre-gl.css';
import useSWR from 'swr';
import DiagnosticModule from '@/components/diagnose/DiagnosticModule';


const fetcher = (url: string) => fetch(url).then(res => res.json());

const SATELLITE_STYLE = {
  version: 8,
  sources: { 'sat': { type: 'raster', tiles: ['https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}'], tileSize: 256 } },
  layers: [{ id: 'sat', type: 'raster', source: 'sat', minzoom: 0, maxzoom: 20 }]
};

const TERRAIN_STYLE = {
  version: 8,
  sources: { 'ter': { type: 'raster', tiles: ['https://server.arcgisonline.com/ArcGIS/rest/services/World_Topo_Map/MapServer/tile/{z}/{y}/{x}'], tileSize: 256 } },
  layers: [{ id: 'ter', type: 'raster', source: 'ter', minzoom: 0, maxzoom: 20 }]
};

const STREET_STYLE = {
  version: 8,
  sources: { 'voy': { type: 'raster', tiles: ['https://basemaps.cartocdn.com/rastertiles/voyager_nolabels/{z}/{x}/{y}{r}.png'], tileSize: 256 } },
  layers: [{ id: 'voy', type: 'raster', source: 'voy', minzoom: 0, maxzoom: 20 }]
};

export function AvailableAssetsContent({ overview, telematics, isDarkMode }: { overview: any, telematics: any, isDarkMode: boolean }) {

  const totalUnits = overview.utilization.reduce((sum: number, u: any) => sum + parseInt(u.count), 0);
  const rentedUnits = overview.utilization.find((u: any) => u.current_status === 'Rented')?.count || 0;
  const idleUnits = overview.utilization.find((u: any) => u.current_status === 'Available')?.count || 0;

  const stats = [
    { label: 'Total Fleet', value: totalUnits.toString(), unit: 'Units' },
    { label: 'Asset Categories', value: overview.categories.length.toString(), unit: 'Types' },
    { label: 'Daily Revenue', value: `$${(overview.activeEarningRate * 24 / 1000).toFixed(1)}k`, unit: 'Est.' },
    { label: 'Usage Time', value: '5h', unit: 'Hours' },
  ];

  const distribution = overview.categories.map((c: any) => {
    let label = c.category;
    if (!label.toLowerCase().includes('tractor')) {
      label = label.toLowerCase().endsWith('y') ? label.slice(0, -1) + 'ies' : label + 's';
    }
    return {
      label: label,
      count: `${c.total} Units`,
      fill: Math.min((parseInt(c.rented_count) / parseInt(c.total)) * 100 || 0, 100),
      dot: c.category === 'Heavy Duty' ? '#facc15' : '#4ade80'
    };
  });

  const utilizationScore = Math.round((parseInt(rentedUnits) / totalUnits) * 100) || 0;

  return (
    <div className="flex flex-col gap-6">
      <div className="grid grid-cols-2 gap-6">
        <div className="grid grid-cols-2 gap-5">
          {stats.map(({ label, value, unit }) => (
            <div key={label} className="bg-white dark:bg-[#1e293b] p-5 rounded-[24px] shadow-[0_4px_20px_-4px_rgba(0,0,0,0.03)] border border-gray-50 dark:border-gray-800 flex flex-col justify-between h-32">
              <div className="flex justify-between text-gray-400 text-xs font-bold uppercase tracking-wider">{label} <span className="text-xl text-gray-300 dark:text-gray-600">..</span></div>
              <div className="text-4xl font-extrabold flex items-baseline gap-1 text-[#1c2432] dark:text-white">{value} <span className="text-sm font-semibold text-gray-400">{unit}</span></div>
            </div>
          ))}
        </div>

        {/* Diagnostic Scanner - Moved to Top Grid and Enhanced */}
        <div className="relative bg-gradient-to-br from-[#1e293b] to-[#0f172a] rounded-[24px] shadow-2xl overflow-hidden border border-green-500/20 group flex flex-col h-[280px]">
          {/* Decorative background blur */}
          <div className="absolute top-0 right-0 w-48 h-48 bg-green-500/10 blur-[50px] pointer-events-none"></div>
          
          <div className="px-6 pt-5 flex justify-between items-center relative z-10 border-b border-white/5 pb-4 bg-white/5">
            <div className="flex items-center gap-3">
               <div className="p-2 bg-green-500/20 rounded-xl">
                 <svg className="w-5 h-5 text-green-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                   <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M3 9a2 2 0 012-2h.93a2 2 0 001.664-.89l.812-1.22A2 2 0 0110.07 4h3.86a2 2 0 011.664.89l.812 1.22A2 2 0 0018.07 7H19a2 2 0 012 2v9a2 2 0 01-2 2H5a2 2 0 01-2-2V9z"></path>
                   <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M15 13a3 3 0 11-6 0 3 3 0 016 0z"></path>
                 </svg>
               </div>
               <h3 className="font-extrabold text-[15px] text-white tracking-wider">AI DIAGNOSTICS</h3>
            </div>
            <div className="flex items-center gap-2">
              <span className="relative flex h-2 w-2">
                <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-green-400 opacity-75"></span>
                <span className="relative inline-flex rounded-full h-2 w-2 bg-green-500"></span>
              </span>
              <span className="text-xs font-bold text-green-400 uppercase">SYSTEM READY</span>
            </div>
          </div>
          <div className="flex-1 min-h-0 relative z-10 bg-black/20 p-2">
            <DiagnosticModule isDarkMode={true} />
          </div>
        </div>
      </div>

      <div className="grid grid-cols-2 gap-6">
        {/* Asset Distribution */}
        <div className="bg-[#6b9d6c] px-8 py-6 rounded-[28px] text-white shadow-lg relative overflow-hidden h-[300px] flex flex-col group">
          <div className="absolute top-[-30%] right-[-10%] w-[130%] h-[130%] bg-[radial-gradient(ellipse_at_top_right,_var(--tw-gradient-stops))] from-white/30 via-transparent to-transparent opacity-90 mix-blend-overlay"></div>
          <div className="absolute inset-0 bg-gradient-to-br from-black/20 via-transparent to-black/20 pointer-events-none"></div>
          <div className="flex justify-between items-start relative z-10 mb-1">
            <h3 className="font-bold text-[17px] leading-tight tracking-tight uppercase opacity-90">Asset Distribution &<br />Maintenance Conditions</h3>
            <span className="text-xl font-bold tracking-widest leading-none opacity-60 group-hover:opacity-100 transition-opacity">•••</span>
          </div>
          <div className="flex-1 flex flex-col justify-center space-y-3 relative z-10 w-full">
            {distribution.map(({ label, count, fill, dot }: any) => (
              <div key={label} className="group/item">
                <div className="flex justify-between text-[11px] font-bold mb-1 opacity-90 group-hover/item:opacity-100 transition-opacity uppercase tracking-wider">
                  <span>{label}</span>
                  <span className="text-white/80">{count}</span>
                </div>
                <div className="w-full bg-black/25 h-3.5 rounded-full flex items-center overflow-hidden pr-2 gap-2 shadow-[inset_0_1px_2px_rgba(0,0,0,0.3)]">
                  <div className="h-full bg-gradient-to-r from-white/10 via-white/40 to-white/90 rounded-r-lg transition-all" style={{ width: `${fill}%` }}></div>
                  <div className="h-1.5 rounded-full w-[20%] drop-shadow-[0_0_4px_rgba(74,222,128,0.8)]" style={{ backgroundColor: dot }}></div>
                </div>
              </div>
            ))}
          </div>
        </div>

        {/* Logistics Tasks Card - Moved to Bottom Grid */}
        <div className="bg-white dark:bg-[#1e293b] p-8 rounded-[28px] shadow-sm border border-gray-50 dark:border-gray-800 flex flex-col h-[300px] overflow-hidden">
          <div className="flex justify-between items-start mb-6">
            <h3 className="font-extrabold text-[16px] text-gray-800 dark:text-white uppercase tracking-wider">Logistics Tasks</h3>
            <span className="text-blue-500 text-[11px] font-bold px-2.5 py-1 bg-blue-50 dark:bg-blue-500/10 rounded-full">ACTIVE QUEUE</span>
          </div>
          <div className="space-y-6 flex-1 overflow-y-auto no-scrollbar pb-2">
            {overview.tasks.slice(0, 3).map((task: any, idx: number) => (
              <div key={idx} className="flex items-center gap-4 group cursor-pointer hover:bg-gray-50/50 dark:hover:bg-white/5 p-2 -mx-2 rounded-2xl transition-all">
                <div className={`w-12 h-12 rounded-xl flex items-center justify-center flex-shrink-0 transition-transform group-hover:scale-105 shadow-sm ${task.task_state === 'Pending' ? 'bg-orange-50 text-orange-500 dark:bg-orange-500/10' : task.task_state === 'In-Progress' ? 'bg-blue-50 text-blue-500 dark:bg-blue-500/10' : 'bg-purple-50 text-purple-500 dark:bg-purple-500/10'}`}>
                  <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2.5" d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2" /></svg>
                </div>
                <div className="flex-1">
                  <div className="text-[14px] font-bold text-gray-800 dark:text-white group-hover:text-blue-500 transition-colors tracking-tight">{task.title}</div>
                  <div className="text-[12px] text-gray-500 font-medium mt-0.5">{task.subtitle}</div>
                </div>
                <div className="ml-auto flex flex-col items-end gap-1.5 min-w-[70px]">
                  <div className="text-[10px] font-black text-gray-400 dark:text-gray-500 uppercase tracking-widest">{task.task_state}</div>
                  <div className="w-12 h-1.5 bg-gray-100 dark:bg-gray-800 rounded-full overflow-hidden">
                    <div className={`h-full rounded-full transition-all duration-1000 ${task.task_state === 'Pending' ? 'w-[30%] bg-orange-400' : task.task_state === 'In-Progress' ? 'w-[75%] bg-blue-400 shadow-[0_0_8px_rgba(96,165,250,0.8)]' : 'w-full bg-purple-400'}`}></div>
                  </div>
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>

      {/* Activity Cards - Restored based on image */}
      <div className="grid grid-cols-3 gap-6 mt-auto">
        {[
          { img: 'https://images.unsplash.com/photo-1592982537447-7440770cbfc9?auto=format&fit=crop&q=80&w=400', badge: 'Done', badgeBg: 'bg-white', dot: 'bg-green-500', title: 'Tractor TRC-05', sub: 'Maintenance' },
          { img: 'https://images.unsplash.com/photo-1530267981375-f0de937f5f13?auto=format&fit=crop&get=80&w=400', badge: 'Progress', badgeBg: 'bg-[#fef08a]', dot: 'bg-yellow-500', title: 'Dispatching Harvester', sub: 'BKH-08 to South Field' },
          { img: 'https://images.unsplash.com/photo-1590682680695-43b964a3ae17?auto=format&fit=crop&q=80&w=400', badge: 'Waiting', badgeBg: 'bg-white', dot: 'bg-gray-500', title: 'Harvesting & Return', sub: 'Combine BKH-#4' },
        ].map(({ img, badge, badgeBg, dot, title, sub }) => (
          <div key={title} className="relative h-[150px] rounded-[24px] overflow-hidden group cursor-pointer shadow-sm flex items-end">
            <img src={img} className="absolute inset-0 w-full h-full object-cover transition-transform duration-700 group-hover:scale-110" />
            <div className="absolute inset-0 bg-gradient-to-t from-black/90 via-black/20 to-transparent z-10"></div>
            <div className={`absolute top-3 left-3 z-20 px-3 py-1.5 ${badgeBg} shadow-sm rounded-full text-[11px] font-extrabold text-gray-800 flex items-center gap-2`}>
              <div className={`w-2 h-2 rounded-full ${dot}`}></div>{badge}
            </div>
            <div className="relative z-20 text-white font-medium text-[15px] leading-tight p-4">{title}<br />{sub}</div>
          </div>
        ))}
      </div>
    </div>
  );
}

export function AvailableAssetsMap({ telematics, isExpanded, setIsExpanded }: { telematics: any, isExpanded: boolean, setIsExpanded: (v: boolean) => void }) {
  const mapRef = useRef<any>(null);
  const HOME_LOCATION = { longitude: 11.3705, latitude: 43.3194, zoom: 14 };
  const [viewState, setViewState] = useState(HOME_LOCATION);
  const [currentStyle, setCurrentStyle] = useState<any>(SATELLITE_STYLE);
  const [styleName, setStyleName] = useState('Satellite');
  const [showLayers, setShowLayers] = useState(false);

  const handleZoom = (delta: number) => {
    mapRef.current?.flyTo({
      center: [viewState.longitude, viewState.latitude],
      zoom: viewState.zoom + delta,
      duration: 1000,
      essential: true
    });
    setViewState(v => ({ ...v, zoom: v.zoom! + delta }));
  };

  const handleRecenter = () => {
    mapRef.current?.flyTo({
      center: [HOME_LOCATION.longitude, HOME_LOCATION.latitude],
      zoom: HOME_LOCATION.zoom,
      duration: 1500,
      essential: true
    });
    setViewState(HOME_LOCATION);
  };

  const rentedCount = telematics?.fleetLocations?.filter((t: any) => t.current_status === 'Rented').length || 0;
  const availableCount = telematics?.fleetLocations?.filter((t: any) => t.current_status === 'Available').length || 0;

  if (!telematics?.fleetLocations) return <div className="w-full h-full bg-gray-100 rounded-[32px] border-4 border-white flex items-center justify-center"><span className="text-gray-400 font-bold text-[10px] uppercase tracking-widest">Awaiting Matrix Uplink...</span></div>;

  return (
    <div className="w-full h-full relative rounded-[32px] overflow-hidden shadow-lg border-4 border-white bg-gray-100 transition-all duration-500">
      <Map
        ref={mapRef}
        {...viewState}
        onMove={evt => setViewState(evt.viewState)}
        mapStyle={currentStyle}
        style={{ width: '100%', height: '100%' }}
        attributionControl={false}
      >
        <div className="absolute top-4 left-1/2 -translate-x-1/2 z-10 flex gap-1 bg-[#1c2432]/40 backdrop-blur-xl p-1.5 rounded-[24px] border border-white/10 shadow-2xl">
          <div className="px-6 py-2 flex flex-col items-center border-r border-white/10">
            <span className="text-[10px] text-white/70 font-bold uppercase tracking-wider">Available</span>
            <span className="text-xl font-extrabold text-white">{availableCount}</span>
          </div>
          <div className="px-6 py-2 flex flex-col items-center">
            <span className="text-[10px] text-white/70 font-bold uppercase tracking-wider">Rented</span>
            <span className="text-xl font-extrabold text-white">{rentedCount}</span>
          </div>
        </div>

        <div className="absolute top-4 right-4 z-10">
          <button
            onClick={() => setIsExpanded(!isExpanded)}
            className={`p-2.5 backdrop-blur shadow-xl border rounded-xl transition-all overflow-hidden relative group active:scale-95 ${isExpanded ? 'bg-green-500 border-green-400 text-white' : 'bg-white/90 border-gray-100/50 text-gray-700'}`}
          >
            {isExpanded ? (
              <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2.5" d="M6 18L18 6M6 6l12 12" /></svg>
            ) : (
              <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2.5" d="M4 8V4m0 0h4M4 4l5 5m11-1V4m0 0h-4m4 0l-5 5M4 16v4m0 0h4m-4 0l5-5m11 5l-5-5m5 5v-4m0 4h-4" /></svg>
            )}
          </button>
        </div>

        <div className="absolute bottom-6 left-6 z-[60] flex flex-col items-center gap-2 group/layers">
          {showLayers && (
            <div className="bg-white/90 backdrop-blur-xl p-2 rounded-2xl shadow-2xl border border-gray-100 flex flex-col gap-1 mb-2 animate-in fade-in slide-in-from-bottom-2 duration-300">
              {[
                { name: 'Satellite', style: SATELLITE_STYLE },
                { name: 'Terrain', style: TERRAIN_STYLE },
                { name: 'Plain', style: STREET_STYLE },
              ].map((s) => (
                <button
                  key={s.name}
                  onClick={() => { setCurrentStyle(s.style); setStyleName(s.name); setShowLayers(false); }}
                  className={`px-4 py-2 rounded-xl text-[10px] font-black uppercase tracking-widest transition-all ${styleName === s.name ? 'bg-green-500 text-white shadow-lg' : 'text-gray-500 hover:bg-gray-100'}`}
                >
                  {s.name}
                </button>
              ))}
            </div>
          )}
          <button
            onClick={() => setShowLayers(!showLayers)}
            className={`p-3 backdrop-blur-2xl shadow-2xl border transition-all active:scale-90 rounded-2xl ${showLayers ? 'bg-green-500 border-green-400 rotate-90' : 'bg-gray-900/40 border-white/20 hover:bg-gray-900/60'}`}
          >
            <svg className="w-6 h-6 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M19 11H5m14 0a2 2 0 012 2v6a2 2 0 01-2 2H5a2 2 0 01-2-2v-6a2 2 0 012-2m14 0V9a2 2 0 00-2-2M5 11V9a2 2 0 012-2m0 0V5a2 2 0 012-2h6a2 2 0 012 2v2M7 7h10" /></svg>
          </button>
          {!showLayers && <span className="text-[10px] font-black text-white/40 group-hover/layers:text-white transition-colors uppercase tracking-[0.2em] mt-1 shadow-sm">Layers</span>}
        </div>

        <div className="absolute bottom-6 right-6 z-10 flex flex-col gap-3">
          <button onClick={handleRecenter} className="w-12 h-12 bg-white backdrop-blur shadow-xl border border-gray-100 rounded-2xl flex items-center justify-center text-gray-600 hover:text-green-600 transition-all hover:shadow-green-500/10 active:scale-90">
            <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2.5" d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z" /><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2.5" d="M15 11a3 3 0 11-6 0 3 3 0 016 0z" /></svg>
          </button>

          <div className="bg-white backdrop-blur shadow-xl border border-gray-100 rounded-2xl p-1 flex flex-col divide-y divide-gray-100">
            <button onClick={() => handleZoom(1)} className="w-10 h-10 flex items-center justify-center text-gray-600 hover:text-black transition-all group active:scale-90">
              <svg className="w-5 h-5 group-hover:scale-125 transition-transform" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="3" d="M12 4v16m8-8H4" /></svg>
            </button>
            <button onClick={() => handleZoom(-1)} className="w-10 h-10 flex items-center justify-center text-gray-600 hover:text-black transition-all group active:scale-90">
              <svg className="w-5 h-5 group-hover:scale-125 transition-transform" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="3" d="M20 12H4" /></svg>
            </button>
          </div>
        </div>

        {telematics.fleetLocations.map((m: any) => (
          <Marker key={m.id} longitude={m.longitude} latitude={m.latitude} anchor="center">
            <div className="group relative cursor-pointer">
              {/* The Marker Dot */}
              <div className={`w-3 h-3 rounded-full border-2 border-white shadow-xl transition-all group-hover:scale-150 ${m.current_status === 'Rented' ? 'bg-yellow-400' : m.current_status === 'Available' ? 'bg-green-400' : 'bg-red-500'}`}></div>

              {/* The Interactive Label (Pill) */}
              <div className="absolute left-1/2 -translate-x-1/2 top-4 pointer-events-none transition-all duration-300 group-hover:top-6 opacity-0 group-hover:opacity-100 z-50">
                <div className="bg-[#1c2432]/70 backdrop-blur-md px-3 py-1.5 rounded-full border border-white/10 shadow-2xl flex items-center gap-2 whitespace-nowrap">
                  <div className={`w-2 h-2 rounded-full ${m.current_status === 'Rented' ? 'bg-yellow-400' : m.current_status === 'Available' ? 'bg-green-400' : 'bg-red-500 animate-pulse'}`}></div>
                  <span className="text-[10px] font-extrabold text-white uppercase tracking-tighter">
                    {m.current_status} • {m.asset_tag}
                  </span>
                </div>
              </div>

              {/* Static Label (Optional, but image shows them as always visible or common) */}
              <div className="absolute left-5 top-1/2 -translate-y-1/2">
                <div className="bg-black/40 backdrop-blur-sm px-2.5 py-1 rounded-lg border border-white/10 shadow-lg flex items-center gap-2 whitespace-nowrap">
                  <div className={`w-1.5 h-1.5 rounded-full ${m.current_status === 'Rented' ? 'bg-yellow-400' : m.current_status === 'Available' ? 'bg-green-400' : 'bg-red-500'}`}></div>
                  <span className="text-[9px] font-bold text-white uppercase tracking-tight opacity-90">
                    {m.current_status} - {m.asset_tag}
                  </span>
                </div>
              </div>
            </div>
          </Marker>
        ))}
      </Map>
    </div>
  );
}

export default function AvailableAssetsView() {
  const { data: overview } = useSWR('/api/fleet/overview', fetcher, { refreshInterval: 10000 });
  const { data: telematics } = useSWR('/api/fleet/telematics', fetcher, { refreshInterval: 5000 });
  const [isExpanded, setIsExpanded] = useState(false);

  if (!overview || !telematics) return null;

  return (
    <div className="flex-1 flex gap-6 overflow-hidden mt-6 relative">
      <main className={`flex-col min-w-0 overflow-y-auto no-scrollbar gap-6 pb-4 transition-all duration-500 ease-in-out ${isExpanded ? 'hidden w-0 opacity-0 translate-x-[-100%]' : 'flex-1 flex opacity-100 translate-x-0'}`}>
        <AvailableAssetsContent overview={overview} telematics={telematics} isDarkMode={true} />
      </main>
      <div className={`h-full relative transition-all duration-500 ease-in-out ${isExpanded ? 'w-full grow' : 'w-[40%] min-w-[500px]'}`}>
        <AvailableAssetsMap telematics={telematics} isExpanded={isExpanded} setIsExpanded={setIsExpanded} />
      </div>
    </div>
  );
}
