from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from sentence_transformers import SentenceTransformer
import os

app = FastAPI(title="Retaj CRM Embedding API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

print("جاري تحميل الموديل في الذاكرة (Memory)...")
model_name = os.getenv("MODEL_NAME", "intfloat/multilingual-e5-small")
model = SentenceTransformer(model_name)
print("تم تحميل الموديل بنجاح ✅")

# التعديل الجديد بيستقبل المتغير من فلاتر
class TextRequest(BaseModel):
    text: str
    is_query: bool = False  # الافتراضي إنه بيسجل عقار مش بيبحث

@app.get("/health")
def health_check():
    return {"status": "awake", "model": model_name}

@app.get("/")
def health_check_root():
    return {"status": "API is running successfully!"}

@app.post("/embed")
def generate_embedding(request: TextRequest):
    if not request.text or len(request.text.strip()) == 0:
        raise HTTPException(status_code=400, detail="النص فارغ")
    
    try:
        # السيرفر هو العقل المدبر: لو الفلاتر بعت true يزود query، لو false يزود passage
        prefix = "query: " if request.is_query else "passage: "
        processed_text = prefix + request.text

        # توليد الشفرة المعرفية (Vector)
        embedding = model.encode(processed_text, normalize_embeddings=True)
        return {"embedding": embedding.tolist()}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))