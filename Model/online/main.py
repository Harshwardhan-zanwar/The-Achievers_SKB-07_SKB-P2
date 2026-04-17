import os
import logging
from datetime import datetime, timezone
from typing import Optional

from dotenv import load_dotenv
from fastapi import FastAPI, File, UploadFile, HTTPException, Form
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

# Import Local Logic
from model_loader import get_model
from intelligence_engine import IntelligenceEngine

# Import Supabase client logic
try:
    from db_client import get_db
except ImportError:
    get_db = None

# Load environment variables
load_dotenv()

# Configure Logging
logging.basicConfig(level=logging.INFO, format="%(asctime)s | %(levelname)-8s | %(name)s | %(message)s")
logger = logging.getLogger("PashuRakshak-Backend")

# Initialize FastAPI
app = FastAPI(
    title="Pashu Rakshak AI API",
    description="Cattle Disease Detection and Diagnostic Engine.",
    version="1.0.0"
)

# CORS Configuration
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# API Prefix
API_PREFIX = "/api/v1"

# Initialize global instances lazily or on startup
model = None
engine = None

@app.on_event("startup")
async def startup_event():
    global model, engine
    try:
        model = get_model()
        engine = IntelligenceEngine(protocols_path="disease_protocols.json")
        logger.info("✅ All systems initialized successfully")
    except Exception as e:
        logger.error(f"❌ Initialization Error: {e}")

@app.get("/")
@app.get("/health")
@app.get(f"{API_PREFIX}/health")
async def health():
    """Service health check."""
    return {
        "status": "ok",
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "model_loaded": model is not None,
        "engine_loaded": engine is not None
    }

@app.post(f"{API_PREFIX}/predict")
async def predict(
    file: UploadFile = File(...),
    query: Optional[str] = Form(None),
    location_lat: Optional[float] = Form(None),
    location_lon: Optional[float] = Form(None),
    crop_area: float = Form(1.0),
    market_price: float = Form(1500.0)
):
    """
    Cattle Disease Prediction Endpoint.
    """
    if not model or not engine:
        raise HTTPException(status_code=503, detail="Model or Intelligence Engine not loaded.")

    try:
        logger.info(f"Received prediction request for file: {file.filename}")
        image_bytes = await file.read()
        
        # 1. Model Inference
        disease_key, confidence, top_k, status_msg = model.predict(image_bytes)
        
        # 2. Intelligence Layer
        location = (location_lat, location_lon) if location_lat and location_lon else None
        
        result = engine.analyze(
            disease_key=disease_key,
            confidence=confidence,
            location=location,
            user_query=query,
            crop_area_acres=crop_area,
            market_price_rs_per_quintal=market_price,
            top_k_predictions=top_k
        )
        
        # 3. Add quality validation message
        result["quality_msg"] = status_msg
        
        # Store in DB if available
        if get_db:
            try:
                db = get_db()
                db.insert_scan(result)
            except Exception as db_err:
                logger.warning(f"DB Error: {db_err}")

        return JSONResponse(content=result)

    except Exception as e:
        logger.error(f"Prediction Error: {e}")
        raise HTTPException(status_code=500, detail=str(e))

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
