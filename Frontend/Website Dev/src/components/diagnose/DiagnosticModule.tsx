"use client";

import React, { useState } from 'react';
import { useRouter } from 'next/navigation';
import { useDiagnosis } from '@/context/DiagnosisContext';
import ScannerComponent from './ScannerComponent';
import DiagnosisResult from './DiagnosisResult';

interface DiagnosticModuleProps {
    isDarkMode: boolean;
}

export default function DiagnosticModule({ isDarkMode }: DiagnosticModuleProps) {
    const router = useRouter();
    const { setDiagnosis } = useDiagnosis();
    const [step, setStep] = useState<'scan' | 'processing' | 'result'>('scan');
    const [result, setResult] = useState<any>(null);
    const [capturedImage, setCapturedImage] = useState<string | null>(null);

    const handleDiagnosisStart = async (image: string) => {
        setCapturedImage(image);
        setStep('processing');

        try {
            // Convert base64 to blob
            const response = await fetch(image);
            const blob = await response.blob();

            const formData = new FormData();
            formData.append('file', blob, 'scan.png');
            formData.append('crop_area', '1.0');

            const apiResponse = await fetch('http://localhost:8000/api/v1/predict', {
                method: 'POST',
                body: formData,
            });

            if (!apiResponse.ok) throw new Error('Failed to connect to AI server');

            const data = await apiResponse.json();

            // Reject low confidence scans
            if (data.confidence < 80.0 && data.disease_type !== 'unknown') {
                setStep('scan');
                alert(`AI Confidence is too low (${data.confidence}%). Please take a clearer, closer photo of the affected area.`);
                return;
            }

            // Transform FastAPI response to our UI structure
            // Matching the new LivestockIntelligence engine output
            const transformedResult = {
                disease: data.disease || "Unknown",
                scientific_name: data.disease_type?.toUpperCase() || "PATHOGEN",
                confidence: data.confidence?.toFixed(2) || "0.00",
                animal: data.animal_type || "Cattle",
                type: data.disease_type?.toUpperCase() || "VIRAL",
                severity: data.severity_level || "LOW",
                is_positive: data.is_positive,
                timestamp: new Date().toLocaleString(),
                location: `${data.location?.lat || '0.0'}, ${data.location?.lon || '0.0'}`,
                yield_loss: `${data.yield_loss_pct || '0'}%`,
                economic_loss: `₹${data.economic_loss_rs || '0'}`,
                remedy: data.first_aid || "No specific remedy provided.",
                action_plan: data.action_plan || [
                    "Isolate the animal to prevent further spreading",
                    "Consult a local veterinarian",
                    "Monitor food and water intake"
                ],
                weather_advice: data.weather_advice || "Keep the animal in a well-ventilated, dry shelter.",
                marketplace: data.marketplace?.recommended_products || [
                    "Antiseptic Wash",
                    "Mineral Mixture"
                ],
                urgency: data.urgency || { level: "LOW", timeline: "Routine Observation", reason: "Standard care recommended." }
            };

            // Save to context and navigate
            setDiagnosis(transformedResult, image);
            router.push('/users/diagnosis');

        } catch (error) {
            console.error("Diagnosis error:", error);
            // Fallback to mock if API is down for demo purposes
            setStep('scan');
            alert("Could not connect to AI backend. Please ensure the FastAPI server is running.");
        }
    };

    const handleReset = () => {
        setStep('scan');
        setResult(null);
        setCapturedImage(null);
    };

    return (
        <div className="flex-1 flex flex-col h-full overflow-y-auto [&::-webkit-scrollbar]:hidden">
            {step === 'scan' && (
                <ScannerComponent
                    isDarkMode={isDarkMode}
                    onCapture={handleDiagnosisStart}
                />
            )}

            {step === 'processing' && (
                <div className="flex-1 flex flex-col items-center justify-center p-8 space-y-6">
                    <div className="relative w-24 h-24">
                        <div className="absolute inset-0 rounded-full border-4 border-green-500/20 border-t-green-500 animate-spin"></div>
                    </div>
                    <div className="text-center">
                        <h2 className="text-xl font-bold mb-2">Analyzing Samples...</h2>
                        <p className="text-slate-500 text-sm">Our AI is identifying pathogens and assessing animal health.</p>
                    </div>
                </div>
            )}

        </div>
    );
}
