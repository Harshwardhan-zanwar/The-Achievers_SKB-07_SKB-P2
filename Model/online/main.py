import os
import logging
from datetime import datetime, timezone
from typing import Optional

from dotenv import load_dotenv
from fastapi import FastAPI, File, UploadFile, HTTPException, Form
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse, FileResponse
from fastapi.staticfiles import StaticFiles

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

# Resolve absolute path to the current directory for reliable file loading
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
PROTOCOLS_PATH = os.path.join(BASE_DIR, "disease_protocols.json")
AUDIO_DIR = os.path.join(BASE_DIR, "static", "audio")

os.makedirs(AUDIO_DIR, exist_ok=True)

app.mount("/audio", StaticFiles(directory=AUDIO_DIR), name="audio")

# Initialize global instances lazily or on startup
model = None
engine = None

@app.on_event("startup")
async def startup_event():
    global model, engine
    try:
        model = get_model()
        engine = IntelligenceEngine(protocols_path=PROTOCOLS_PATH)
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
    file: Optional[UploadFile] = File(None),
    query: Optional[str] = Form(None),
    location_lat: Optional[float] = Form(None),
    location_lon: Optional[float] = Form(None),
    crop_area: float = Form(1.0),
    market_price: float = Form(1500.0),
    language: str = Form("English")
):
    """
    Cattle Disease Prediction Endpoint.
    """
    if not model or not engine:
        raise HTTPException(status_code=503, detail="Model or Intelligence Engine not loaded.")

    try:
        logger.info(f"Received predict request: file={'Yes' if file else 'No'}, query={'Yes' if query else 'No'}")
        
        # 1. Model Inference (Only if image provided)
        disease_key = "Healthy_Cattle"
        confidence = 0.95
        top_k = []
        status_msg = "Voice Consult"
        
        if file and file.filename and len(await file.read()) > 0:
            await file.seek(0) # Reset stream after reading for length check
            image_bytes = await file.read()
            disease_key, confidence, top_k, status_msg = model.predict(image_bytes)
        elif query and len(query.strip()) > 0:
            status_msg = "Voice Analysis"
        else:
             raise HTTPException(status_code=400, detail="Either image or voice query must be provided.")
        
        # 2. Intelligence Layer
        location = (location_lat, location_lon) if location_lat and location_lon else None
        
        result = engine.analyze(
            disease_key=disease_key,
            confidence=confidence,
            location=location,
            user_query=query,
            crop_area_acres=crop_area,
            market_price_rs_per_quintal=market_price,
            top_k_predictions=top_k,
            language=language
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

    except HTTPException as he:
        # Re-raise HTTPExceptions (like the 400 we just raised)
        raise he
    except Exception as e:
        logger.error(f"Prediction Error: {e}")
        raise HTTPException(status_code=500, detail=str(e))

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
