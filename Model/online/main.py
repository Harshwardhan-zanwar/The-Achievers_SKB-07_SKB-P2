import os
import logging
from datetime import datetime, timezone
from typing import Optional

from dotenv import load_dotenv
from fastapi import FastAPI, File, UploadFile, HTTPException, Form
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

# Import Supabase client logic
try:
    from db_client import get_db
except ImportError:
    get_db = None

# Load environment variables
load_dotenv()

# Configure Logging
logging.basicConfig(level=logging.INFO, format="%(asctime)s | %(levelname)-8s | %(name)s | %(message)s")
logger = logging.getLogger("AgriSense-Backend")

# Initialize FastAPI
app = FastAPI(
    title="AgriSense API Skeleton",
    description="Backend skeleton for AgriSense Website. Includes Mock ML and Supabase integration.",
    version="1.0.0"
)

# CORS Configuration - Critical for Next.js Frontend
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # In production, specify your frontend URL
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# API Prefix
API_PREFIX = "/api/v1"

@app.get("/")
@app.get("/health")
@app.get(f"{API_PREFIX}/health")
async def health():
    """Service health check."""
    return {
        "status": "ok",
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "database_connected": get_db().is_connected if get_db else False
    }

@app.get(f"{API_PREFIX}/endpoints")
async def endpoints():
    """List available endpoints."""
    return {
        "endpoints": [
            {"path": f"{API_PREFIX}/health", "method": "GET", "desc": "Health check"},
            {"path": f"{API_PREFIX}/predict", "method": "POST", "desc": "Crop disease prediction (Mock Mode)"},
        ]
    }

@app.post(f"{API_PREFIX}/predict")
async def predict(
    file: UploadFile = File(...),
    location_lat: Optional[float] = Form(None),
    location_lon: Optional[float] = Form(None),
    crop_area: float = Form(1.0)
):
    """
    Mock Prediction Endpoint.
    This takes an image and returns a generic 'Mock Result' so the frontend can be developed.
    """
    logger.info(f"Received prediction request for file: {file.filename}")

    # --- MOCK ML LOGIC ---
    # This is where your teammate will plug in the actual ML model later.
    mock_result = {
        "disease": "Tomato Late Blight",
        "disease_key": "tomato_late_blight",
        "confidence_raw": 0.985,
        "is_positive": True,
        "severity_level": "MODERATE",
        "disease_type": "Fungal",
        "yield_loss_pct": 15.5,
        "economic_loss_rs": 4500.0,
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "location": {
            "lat": location_lat,
            "lon": location_lon
        },
        "recommendations": [
            "Apply Copper-based fungicides.",
            "Remove and destroy infected leaves.",
            "Improve air circulation between plants."
        ]
    }

    # --- SUPABASE INTEGRATION ---
    # Save the result to the database if configured
    if get_db:
        db = get_db()
        db.insert_scan(mock_result)

    return JSONResponse(content=mock_result)

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
