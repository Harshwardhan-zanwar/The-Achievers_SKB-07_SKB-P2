"use client";

import React, { useRef, useState } from 'react';
import { Camera, Upload, Image as ImageIcon, X } from 'lucide-react';

interface ScannerComponentProps {
    isDarkMode: boolean;
    onCapture: (image: string) => void;
}

export default function ScannerComponent({ isDarkMode, onCapture }: ScannerComponentProps) {
    const fileInputRef = useRef<HTMLInputElement>(null);
    const [preview, setPreview] = useState<string | null>(null);

    const handleFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
        const file = e.target.files?.[0];
        if (file) {
            const reader = new FileReader();
            reader.onloadend = () => {
                setPreview(reader.result as string);
            };
            reader.readAsDataURL(file);
        }
    };

    const handleAnalyze = () => {
        if (preview) {
            onCapture(preview);
        }
    };

    const clearPreview = () => setPreview(null);

    return (
        <div className="flex-1 flex flex-col p-2 space-y-3 w-full max-w-full">

            <div
                className={`relative w-full h-[120px] rounded-2xl border-2 border-dashed flex flex-col items-center justify-center overflow-hidden transition-all ${preview
                    ? 'border-green-500'
                    : isDarkMode ? 'border-slate-800 bg-slate-900/50' : 'border-slate-200 bg-white shadow-sm'
                    }`}
            >
                {preview ? (
                    <>
                        <img src={preview} alt="Preview" className="w-full h-full object-cover" />
                        <button
                            onClick={clearPreview}
                            className="absolute top-4 right-4 p-2 bg-black/50 backdrop-blur-md rounded-full text-white hover:bg-black/70 transition-colors"
                        >
                            <X className="w-5 h-5" />
                        </button>
                    </>
                ) : (
                    <div className="flex flex-col items-center space-y-4">
                        <div className={`p-3 rounded-full ${isDarkMode ? 'bg-slate-800' : 'bg-slate-50'}`}>
                            <Camera className={`w-6 h-6 ${isDarkMode ? 'text-slate-400' : 'text-slate-400'}`} />
                        </div>
                        <div className="text-center">
                            <button
                                onClick={() => fileInputRef.current?.click()}
                                className="text-green-600 font-semibold hover:underline"
                            >
                                Take a photo
                            </button>
                            <p className="text-slate-400 text-xs mt-1">or upload from gallery</p>
                        </div>
                    </div>
                )}

                <input
                    type="file"
                    accept="image/*"
                    capture="environment"
                    className="hidden"
                    ref={fileInputRef}
                    onChange={handleFileChange}
                />
            </div>

            <div className="flex gap-3 pt-2">
                {!preview && (
                    <button
                        onClick={() => fileInputRef.current?.click()}
                        className={`flex-1 py-3 rounded-xl font-bold flex items-center justify-center gap-2 border-2 transition-all text-xs ${isDarkMode
                            ? 'border-slate-800 text-slate-300 hover:bg-slate-800'
                            : 'border-slate-100 text-slate-600 hover:bg-slate-50'
                            }`}
                    >
                        <Upload className="w-4 h-4" />
                        Photos
                    </button>
                )}
                
                <button
                    disabled={!preview}
                    onClick={handleAnalyze}
                    className={`flex-1 py-3 rounded-xl font-bold flex items-center justify-center gap-2 transition-all active:scale-[0.98] text-xs ${preview
                        ? 'bg-[#528956] text-white shadow-lg shadow-green-900/20'
                        : 'bg-slate-200 text-slate-400 cursor-not-allowed dark:bg-slate-800 dark:text-slate-600'
                        }`}
                >
                    <ImageIcon className="w-4 h-4" />
                    Analyze
                </button>
            </div>
        </div>
    );
}

