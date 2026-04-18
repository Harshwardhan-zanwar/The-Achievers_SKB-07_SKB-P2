"use client";

import React, { createContext, useContext, useState } from 'react';

interface DiagnosisContextType {
    lastResult: any | null;
    scannedImage: string | null;
    setDiagnosis: (result: any, image: string | null) => void;
    clearDiagnosis: () => void;
}

const DiagnosisContext = createContext<DiagnosisContextType | undefined>(undefined);

export function DiagnosisProvider({ children }: { children: React.ReactNode }) {
    const [lastResult, setLastResult] = useState<any | null>(null);
    const [scannedImage, setScannedImage] = useState<string | null>(null);

    const setDiagnosis = (result: any, image: string | null) => {
        setLastResult(result);
        setScannedImage(image);
    };

    const clearDiagnosis = () => {
        setLastResult(null);
        setScannedImage(null);
    };

    return (
        <DiagnosisContext.Provider value={{ lastResult, scannedImage, setDiagnosis, clearDiagnosis }}>
            {children}
        </DiagnosisContext.Provider>
    );
}

export function useDiagnosis() {
    const context = useContext(DiagnosisContext);
    if (context === undefined) {
        throw new Error('useDiagnosis must be used within a DiagnosisProvider');
    }
    return context;
}
