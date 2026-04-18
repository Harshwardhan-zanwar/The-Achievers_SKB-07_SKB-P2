"use client";

import React, { useState, useRef } from 'react';
import {
    AlertTriangle, CheckCircle2, ChevronRight, Cloud,
    DollarSign, Microscope, RefreshCw, ShoppingCart,
    Smartphone, Zap, Mic, Play, ArrowLeft, MoreVertical
} from 'lucide-react';

interface DiagnosisResultProps {
    isDarkMode: boolean;
    result: any;
    image: string | null;
    onReset: () => void;
}

export default function DiagnosisResult({ isDarkMode, result, image, onReset }: DiagnosisResultProps) {
    const [selectedTab, setSelectedTab] = useState<'overview' | 'advice'>('overview');

    // Voice Recording State
    const [isRecording, setIsRecording] = useState(false);
    const [audioBlob, setAudioBlob] = useState<Blob | null>(null);
    const [isProcessingVoice, setIsProcessingVoice] = useState(false);
    const [audioUrl, setAudioUrl] = useState<string | null>(null);
    const [transcript, setTranscript] = useState<string | null>(null);

    const mediaRecorderRef = useRef<MediaRecorder | null>(null);
    const audioChunksRef = useRef<Blob[]>([]);

    const startRecording = async () => {
        try {
            const stream = await navigator.mediaDevices.getUserMedia({ audio: true });
            const mediaRecorder = new MediaRecorder(stream);
            mediaRecorderRef.current = mediaRecorder;
            audioChunksRef.current = [];

            mediaRecorder.ondataavailable = (event) => {
                if (event.data.size > 0) {
                    audioChunksRef.current.push(event.data);
                }
            };

            mediaRecorder.onstop = () => {
                const blob = new Blob(audioChunksRef.current, { type: 'audio/webm' });
                setAudioBlob(blob);
            };

            mediaRecorder.start();
            setIsRecording(true);
            setAudioBlob(null);
            setTranscript(null);
            setAudioUrl(null);
        } catch (error) {
            console.error("Mic error:", error);
            alert("Please allow microphone permissions.");
        }
    };

    const stopRecording = () => {
        if (mediaRecorderRef.current && isRecording) {
            mediaRecorderRef.current.stop();
            setIsRecording(false);
            mediaRecorderRef.current.stream.getTracks().forEach(track => track.stop());
        }
    };

    const submitVoice = async () => {
        if (!audioBlob) return;
        setIsProcessingVoice(true);
        try {
            const formData = new FormData();
            formData.append('file', audioBlob, 'question.webm');
            formData.append('disease_json', JSON.stringify(result));

            const req = await fetch('http://localhost:8000/api/v1/voice/chatbot-pipeline', {
                method: 'POST',
                body: formData,
            });

            if (!req.ok) throw new Error("Backend failed");
            const data = await req.json();

            setTranscript(data.transcript);
            if (data.audio_download_url) {
                setAudioUrl(`http://localhost:8000/api/v1${data.audio_download_url}`);
            }
        } catch (e) {
            console.error(e);
            alert("Failed to process voice request. Ensure backend is running.");
        } finally {
            setIsProcessingVoice(false);
        }
    };

    // Utility for confidence color
    const getConfidenceColor = (conf: number) => {
        if (conf > 80) return 'text-green-400';
        if (conf > 50) return 'text-amber-400';
        return 'text-red-400';
    };

    return (
        <div className="flex-1 flex flex-col h-full bg-[#111] text-white overflow-y-auto [&::-webkit-scrollbar]:hidden scroll-smooth">

            {/* Header / Nav */}
            <div className="flex items-center justify-between p-6 sticky top-0 bg-[#111]/90 backdrop-blur-xl z-30 border-b border-white/5">
                <button onClick={onReset} className="p-3 bg-white/5 hover:bg-white/10 rounded-2xl transition-all active:scale-95 shadow-lg">
                    <ArrowLeft className="w-5 h-5 text-green-500" />
                </button>
                <div className="flex flex-col items-center">
                    <h1 className="text-lg font-black tracking-tighter uppercase text-white/90">Detailed Diagnosis</h1>
                    <span className="text-[10px] font-bold text-gray-500 tracking-widest uppercase">Report ID: #AS-{Math.floor(1000 + Math.random() * 9000)}</span>
                </div>
                <button className="p-3 bg-white/5 hover:bg-white/10 rounded-2xl transition-all">
                    <ShoppingCart className="w-5 h-5 text-gray-400" />
                </button>
            </div>

            {/* Main Content */}
            <div className="px-4 pb-12 space-y-6">

                {/* Result Image Overlay Card */}
                <div className="relative rounded-[2.5rem] overflow-hidden group shadow-2xl">
                    {image && <img src={image} alt="Crop" className="w-full aspect-[4/3] object-cover" />}
                    <div className="absolute inset-x-0 bottom-0 bg-gradient-to-t from-black/90 via-black/40 to-transparent p-6 pt-12">
                        <div className="flex items-center justify-between">
                            <span className="text-sm font-medium text-white/70">Scan record</span>
                            <span className="text-sm font-medium text-white/70">{result.timestamp}</span>
                        </div>
                    </div>
                </div>

                {/* Primary Result Card */}
                <div className="bg-[#221c1c] border border-red-900/30 rounded-[2.5rem] p-6 shadow-xl relative overflow-hidden">
                    <div className="absolute top-0 right-0 w-32 h-32 bg-red-500/5 blur-3xl rounded-full"></div>

                    <div className="flex items-start gap-4 mb-6">
                        <div className="p-4 bg-red-500/10 rounded-2xl">
                            <AlertTriangle className="w-8 h-8 text-red-500" />
                        </div>
                        <div className="flex-1">
                            <div className="flex justify-between items-start">
                                <div>
                                    <h3 className="text-gray-400 text-sm font-medium mb-1">Diagnosis result</h3>
                                    <h2 className="text-2xl font-black text-red-500 leading-tight mb-2">
                                        {result.disease} <br />
                                        <span className="text-xs font-normal text-red-400/70 italic">({result.scientific_name})</span>
                                    </h2>
                                </div>
                                <div className="bg-[#2a2626] border border-white/5 p-3 rounded-2xl text-center min-w-[80px]">
                                    <div className="text-[10px] text-gray-500 uppercase tracking-widest font-bold mb-1">Confidence</div>
                                    <div className={`text-lg font-black ${getConfidenceColor(result.confidence)}`}>{result.confidence}%</div>
                                </div>
                            </div>
                            <div className="text-sm text-red-400/80 font-medium">{result.confidence}% confidence</div>
                        </div>
                    </div>

                    {/* Progress indicator */}
                    <div className="mb-6">
                        <div className="w-full bg-white/5 h-2 rounded-full overflow-hidden">
                            <div className="bg-red-500 h-full transition-all duration-1000" style={{ width: `${result.confidence}%` }}></div>
                        </div>
                    </div>

                    {/* Urgency Banner */}
                    {result.urgency && (
                        <div className="mb-8">
                            <div className={`p-4 rounded-[1.5rem] border flex items-start gap-4 ${result.urgency.level === 'CRITICAL' ? 'bg-red-500/20 border-red-500/50 shadow-[0_0_30px_rgba(239,68,68,0.2)]' :
                                result.urgency.level === 'HIGH' ? 'bg-orange-500/20 border-orange-500/50 shadow-[0_0_20px_rgba(249,115,22,0.1)]' :
                                    result.urgency.level === 'MODERATE' ? 'bg-amber-500/20 border-amber-500/50' :
                                        'bg-green-500/20 border-green-500/50'
                                }`}>
                                <div className={`p-3 rounded-full shrink-0 ${result.urgency.level === 'CRITICAL' ? 'bg-red-500/20 animate-pulse' :
                                    result.urgency.level === 'HIGH' ? 'bg-orange-500/20' :
                                        result.urgency.level === 'MODERATE' ? 'bg-amber-500/20' :
                                            'bg-green-500/20'
                                    }`}>
                                    {result.urgency.level === 'ROUTINE' ? (
                                        <CheckCircle2 className="w-6 h-6 text-green-500" />
                                    ) : (
                                        <AlertTriangle className={`w-6 h-6 ${result.urgency.level === 'CRITICAL' ? 'text-red-500' :
                                            result.urgency.level === 'HIGH' ? 'text-orange-500' :
                                                'text-amber-500'
                                            }`} />
                                    )}
                                </div>
                                <div className="flex-1">
                                    <h4 className={`text-xs font-black tracking-widest uppercase mb-1 ${result.urgency.level === 'CRITICAL' ? 'text-red-500' :
                                        result.urgency.level === 'HIGH' ? 'text-orange-500' :
                                            result.urgency.level === 'MODERATE' ? 'text-amber-500' :
                                                'text-green-500'
                                        }`}>
                                        {result.urgency.level} • {result.urgency.timeline}
                                    </h4>
                                    <p className="text-[13px] font-medium text-white/90 leading-snug">
                                        {result.urgency.reason}
                                    </p>

                                    {(result.urgency.level === 'CRITICAL' || result.urgency.level === 'HIGH') && (
                                        <button className="mt-3 w-full py-2 bg-red-600 hover:bg-red-500 text-white text-xs font-bold uppercase tracking-widest rounded-xl transition-colors">
                                            Emergency: Find Nearest Vet
                                        </button>
                                    )}
                                </div>
                            </div>
                        </div>
                    )}

                    {/* Meta info chips */}
                    <div className="space-y-3">
                        <div className="flex items-center gap-3 bg-white/5 p-3 rounded-2xl border border-white/5">
                            <Zap className="w-4 h-4 text-green-500" />
                            <span className="text-sm font-semibold">Animal: {result.animal || result.crop}</span>
                        </div>
                        <div className="flex items-center gap-3 bg-white/5 p-3 rounded-2xl border border-white/5">
                            <AlertTriangle className="w-4 h-4 text-amber-500" />
                            <span className="text-xs font-bold text-amber-500/80 uppercase tracking-widest leading-none">
                                <span className="inline-block w-2 h-2 rounded-full bg-green-500 mr-2"></span>
                                {result.severity} — Early-stage detection.
                            </span>
                        </div>
                        <div className="flex items-center gap-3 bg-white/5 p-3 rounded-2xl border border-white/5">
                            <Microscope className="w-4 h-4 text-green-500" />
                            <span className="text-sm font-semibold">Type: {result.type}</span>
                        </div>
                        <div className="flex items-center gap-3 bg-white/5 p-3 rounded-2xl border border-white/5">
                            <CheckCircle2 className="w-4 h-4 text-green-500" />
                            <span className="text-sm font-semibold">Positive: YES</span>
                        </div>
                    </div>
                </div>

                {/* First-aid remedy section */}
                <div className="space-y-4">
                    <h3 className="text-lg font-bold text-green-500 px-2 flex items-center gap-2">
                        First-aid remedy
                    </h3>
                    <div className="bg-[#24211d] border border-amber-900/20 rounded-[2.5rem] p-6 shadow-lg">
                        <div className="flex gap-3 mb-4">
                            <AlertTriangle className="w-5 h-5 text-amber-500 shrink-0 mt-1" />
                            <p className="text-sm leading-relaxed text-gray-300">
                                {result.confidence < 70 && (
                                    <span className="font-bold text-white uppercase tracking-tighter mr-1 underline decoration-amber-500">
                                        Low Confidence ({result.confidence}%):
                                    </span>
                                )}
                                {result.remedy}
                            </p>
                        </div>
                        <div className="bg-white/5 p-4 rounded-2xl border border-white/5 flex items-center gap-3">
                            <div className="p-2 bg-green-500/10 rounded-xl">
                                <Smartphone className="w-4 h-4 text-green-500" />
                            </div>
                            <span className="text-xs text-gray-400 font-medium font-mono">Scan location: {result.location}</span>
                        </div>
                    </div>
                </div>

                {/* Action Plan Section */}
                <div className="space-y-4">
                    <h3 className="text-lg font-bold text-green-500 px-2">Action plan</h3>
                    <div className="bg-[#221c1c] border border-red-900/10 rounded-[2.5rem] p-6 shadow-lg">
                        <ul className="space-y-4">
                            {result.action_plan.map((item: string, idx: number) => (
                                <li key={idx} className="flex gap-4">
                                    <div className="w-1.5 h-1.5 rounded-full bg-red-500 shrink-0 mt-2"></div>
                                    <p className="text-sm text-gray-300 leading-snug">{item}</p>
                                </li>
                            ))}
                        </ul>
                    </div>
                </div>

                {/* Weather Advice */}
                <div className="space-y-4">
                    <h3 className="text-lg font-bold text-green-500 px-2">Weather-contextual advice</h3>
                    <div className="bg-[#1a211b] border border-green-900/10 rounded-[2.5rem] p-6 shadow-lg flex gap-4">
                        <Cloud className="w-6 h-6 text-sky-400 shrink-0" />
                        <p className="text-sm text-gray-300 leading-relaxed">{result.weather_advice}</p>
                    </div>
                </div>

                {/* Economic Impact */}
                {/* <div className="space-y-4">
                    <h3 className="text-lg font-bold text-green-500 px-2">Yield & economic impact</h3>
                    <div className="bg-[#221c1c] border border-red-900/10 rounded-[2.5rem] p-6 shadow-lg">
                        <p className="text-gray-300 font-medium">
                            Yield loss: <span className="text-white font-black">{result.yield_loss}</span> •
                            Est. loss: <span className="text-white font-black">{result.economic_loss}</span> •
                            Per acre: <span className="text-white font-black">{result.economic_loss}</span>
                        </p>
                    </div>
                </div> */}

                {/* Marketplace Routing */}
                <div className="space-y-4">
                    <h3 className="text-lg font-bold text-green-500 px-2">Marketplace routing</h3>
                    <div className="bg-[#212421] border border-white/5 rounded-[2.5rem] p-6 shadow-lg space-y-4">
                        <p className="text-sm text-gray-400">Medicine & Vaccines</p>
                        <div className="flex flex-wrap gap-2">
                            {result.marketplace.map((item: string, idx: number) => (
                                <button key={idx} className="px-4 py-3 bg-[#2a2e2a] border border-white/5 rounded-2xl text-sm font-bold text-green-100 hover:bg-[#323832] transition-colors shadow-sm">
                                    {item}
                                </button>
                            ))}
                        </div>
                        <p className="text-xs text-gray-500 italic pt-2 border-t border-white/5">
                            Contact your nearest Veterinary Clinic or Animal Health Center for availability.
                        </p>
                    </div>
                </div>

                {/* Voice Interaction Placeholder */}
                <div className="space-y-4">
                    <h1 className="text-2xl font-black px-2 mt-8">Ask about this scan</h1>
                    <p className="text-sm text-gray-500 px-2">
                        Uses your diagnosis JSON + voice sends this screen's report plus your audio and returns a spoken answer.
                    </p>

                    <div className="bg-[#1a211b] border border-white/5 rounded-[2.5rem] p-6 shadow-2xl space-y-8">
                        <h3 className="text-xl font-bold">Speak your question</h3>

                        <div className="flex items-center gap-6">
                            {isRecording ? (
                                <button onClick={stopRecording} className="flex-1 flex items-center justify-center gap-3 bg-red-500 text-white py-4 rounded-3xl font-bold shadow-[0_0_20px_rgba(239,68,68,0.4)] animate-pulse transition-all">
                                    <span className="w-3 h-3 bg-white rounded-full"></span> Stop Recording
                                </button>
                            ) : (
                                <button onClick={startRecording} className="flex-1 flex items-center justify-center gap-3 bg-[#528956] text-white py-4 rounded-3xl font-bold shadow-lg shadow-green-900/30 active:scale-95 transition-all">
                                    <Mic className="w-5 h-5 fill-white" /> Record
                                </button>
                            )}
                        </div>

                        {audioBlob && (
                            <div className="flex flex-col gap-3 justify-center">
                                <div className="text-green-500 font-bold text-center text-sm">Audio Captured! Ready to send.</div>
                            </div>
                        )}

                        {(transcript || isProcessingVoice) && (
                            <div className="bg-[#121412] p-6 rounded-3xl border border-green-500/20 text-gray-300 text-sm italic font-medium leading-relaxed">
                                {isProcessingVoice ? "Processing audio... Please wait." : (
                                    <>
                                        <span className="text-green-500 font-bold block mb-2">Transcription (You said):</span>
                                        "{transcript}"
                                    </>
                                )}
                            </div>
                        )}

                        {audioUrl && (
                            <div className="mt-4">
                                <span className="text-green-500 font-bold block mb-2 text-sm">AI Response Output:</span>
                                <audio controls src={audioUrl} className="w-full rounded-full" autoPlay></audio>
                            </div>
                        )}

                        <button
                            disabled={!audioBlob || isProcessingVoice}
                            onClick={submitVoice}
                            className={`w-full py-5 rounded-full font-black text-lg shadow-xl active:scale-95 transition-all flex items-center justify-center gap-3 
                                ${!audioBlob || isProcessingVoice ? 'bg-gray-800 text-gray-500 cursor-not-allowed' : 'bg-[#528956] text-white shadow-green-900/40'}`}
                        >
                            <Zap className={`w-6 h-6 ${!audioBlob || isProcessingVoice ? 'fill-gray-500' : 'fill-white'}`} />
                            {isProcessingVoice ? "Loading AI Response..." : "Get AI advice (Voice Request)"}
                        </button>
                    </div>
                </div>

                {/* Marketplace Action */}
                <div className="space-y-4 pt-6">
                    <h3 className="text-lg font-bold text-green-500 px-2">Vet Marketplace</h3>
                    <p className="text-sm text-gray-500 px-2 mt-[-8px]">Reserve vaccines or book a veterinarian near you.</p>
                    <button className="w-full py-5 bg-[#528956] text-white rounded-full font-black text-lg shadow-xl shadow-green-900/40 active:scale-95 transition-all">
                        Book Vet Consultation
                    </button>
                </div>
            </div>
        </div>
    );
}
