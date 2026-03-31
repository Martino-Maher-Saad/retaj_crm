FROM python:3.10-slim

# إعدادات الأمان والتوافق الإجبارية لموقع Hugging Face (مستخدم بصلاحية 1000)
RUN useradd -m -u 1000 user
USER user
ENV PATH="/home/user/.local/bin:$PATH"

WORKDIR /home/user/app

# إجبار الدوكر يحفظ الموديل في فولدر المستخدم الجديد مش الأدمن
ENV HF_HOME="/home/user/app/.cache"

COPY --chown=user requirements.txt .
# تحميل النسخة الخفيفة جداً من PyTorch لتوفير المساحة والوقت
RUN pip install --no-cache-dir torch==2.1.2+cpu --index-url https://download.pytorch.org/whl/cpu
RUN pip install --no-cache-dir -r requirements.txt

# تحميل الموديل أوتوماتيك
RUN python -c "from sentence_transformers import SentenceTransformer; SentenceTransformer('intfloat/multilingual-e5-small')"

COPY --chown=user . .

EXPOSE 7860

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "7860"]