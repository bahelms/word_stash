from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from typing import Optional, List, Dict
import trafilatura
import datetime as dt

# ---- Summarization (extractive: Sumy) ----
from sumy.parsers.plaintext import PlaintextParser
from sumy.nlp.tokenizers import Tokenizer
from sumy.summarizers.text_rank import TextRankSummarizer

# ---- Tags (YAKE) ----
import yake
import os

USE_ABSTRACTIVE = os.getenv("USE_ABSTRACTIVE", "false").lower() in ("1", "true", "yes")

# lazy import heavy libs only if requested
nlp_pipe = None
if USE_ABSTRACTIVE:
    from transformers import pipeline

    # small/fast-ish summarizer; you can swap to "facebook/bart-large-cnn" if your VM is beefier
    nlp_pipe = pipeline(
        "summarization", model="sshleifer/distilbart-cnn-12-6", device=-1
    )

app = FastAPI(title="Article Parser", version="1.0.0")


class ParseRequest(BaseModel):
    url: Optional[str] = None
    html: Optional[str] = None
    max_summary_sentences: int = 4
    num_tags: int = 8
    language: str = "en"


def summarize_extractive(text: str, max_sents: int = 4) -> str:
    parser = PlaintextParser.from_string(text, Tokenizer("english"))
    summarizer = TextRankSummarizer()
    sentences = summarizer(parser.document, max_sents)
    return " ".join([str(s) for s in sentences])


def summarize_abstractive(text: str, max_tokens: int = 180) -> str:
    # keep chunks modest to avoid max token overflows
    max_input = 3500  # characters heuristic
    chunk = text[:max_input]
    out = nlp_pipe(chunk, max_length=256, min_length=60, do_sample=False)[0][
        "summary_text"
    ]
    return out


def extract_tags(text: str, top_k: int = 8, language: str = "en") -> List[str]:
    kw = yake.KeywordExtractor(lan=language, n=1, top=top_k, dedupLim=0.9)
    return [k for k, score in kw.extract_keywords(text)]


def parse_article(url: Optional[str], html: Optional[str]) -> Dict:
    if not url and not html:
        raise HTTPException(status_code=400, detail="Provide url or html")

    downloaded = html or trafilatura.fetch_url(url)
    if not downloaded:
        raise HTTPException(status_code=422, detail="Could not fetch content")

    # extract with metadata
    result = trafilatura.extract(
        downloaded, include_comments=False, include_formatting=False, output="json"
    )
    if not result:
        raise HTTPException(status_code=422, detail="Could not extract article")

    data = trafilatura.extract(downloaded, output="json", with_metadata=True)
    # `data` is a JSON string; parse to dict
    import json

    meta = json.loads(data)

    # normalize fields
    title = meta.get("title")
    author = meta.get("author") or meta.get("authors") or []  # can be string or list
    if isinstance(author, list):
        author = ", ".join(author)
    date_published = (
        meta.get("date") or meta.get("published") or meta.get("publication_date")
    )
    if date_published:
        try:
            # try to standardize
            date_published = str(
                dt.datetime.fromisoformat(date_published.replace("Z", "+00:00")).date()
            )
        except Exception:
            # leave as-is if unknown format
            pass

    text = meta.get("text") or ""
    if not text.strip():
        raise HTTPException(status_code=422, detail="Article text empty")

    # summarization
    if USE_ABSTRACTIVE:
        summary = summarize_abstractive(text)
    else:
        summary = summarize_extractive(text, max_sents=4)

    tags = extract_tags(text, top_k=8, language="en")

    return {
        "title": title,
        "author": author,
        "date_published": date_published,
        "summary": summary,
        "tags": tags,
        "word_count": len(text.split()),
        "source_url": url,
    }


@app.post("/extract")
def extract(req: ParseRequest):
    return parse_article(req.url, req.html)


@app.get("/healthz")
def health():
    return {"ok": True}
