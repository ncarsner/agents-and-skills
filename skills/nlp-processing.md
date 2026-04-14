# Skill: NLP Processing

Patterns and recipes for natural language processing (NLP) tasks in Python
using spaCy, Transformers, and related libraries.

---

## Quick Setup

```bash
# Install spaCy and download English model
uv add spacy
python3 -m spacy download en_core_web_sm    # small, fast
python3 -m spacy download en_core_web_trf   # transformer-based, accurate
```

---

## Text Preprocessing Patterns

### Normalization pipeline
```python
"""Text normalization utilities."""

import re
import unicodedata

WHITESPACE_RE = re.compile(r"\s+")
URL_RE = re.compile(r"https?://\S+")
EMAIL_RE = re.compile(r"\S+@\S+\.\S+")


def normalize(text: str, *, remove_urls: bool = False, remove_emails: bool = False) -> str:
    """Normalize text for NLP processing.

    Args:
        text: Raw input text.
        remove_urls: Replace URLs with a placeholder token.
        remove_emails: Replace email addresses with a placeholder token.

    Returns:
        Cleaned, normalized text string.
    """
    # Remove control characters
    text = "".join(c for c in text if unicodedata.category(c)[0] != "C")
    if remove_urls:
        text = URL_RE.sub("[URL]", text)
    if remove_emails:
        text = EMAIL_RE.sub("[EMAIL]", text)
    # Normalize unicode (NFC form)
    text = unicodedata.normalize("NFC", text)
    # Collapse whitespace
    text = WHITESPACE_RE.sub(" ", text).strip()
    return text
```

---

## spaCy Pipeline Patterns

### Efficient batch processing
```python
"""Efficient spaCy batch processing for large document collections."""

from pathlib import Path
import spacy

nlp = spacy.load("en_core_web_sm", disable=["parser"])  # disable unused components


def process_documents(texts: list[str], batch_size: int = 256) -> list[dict]:
    """Process a large list of texts using spaCy's pipe() for efficiency.

    Args:
        texts: List of raw text strings.
        batch_size: Number of texts per batch.

    Returns:
        List of dicts with 'tokens', 'entities', and 'noun_chunks'.
    """
    results = []
    for doc in nlp.pipe(texts, batch_size=batch_size):
        results.append(
            {
                "tokens": [t.lemma_.lower() for t in doc if not t.is_stop and not t.is_punct],
                "entities": [(e.text, e.label_) for e in doc.ents],
                "noun_chunks": [chunk.text for chunk in doc.noun_chunks],
            }
        )
    return results
```

### Custom component
```python
"""Custom spaCy pipeline component for domain-specific rule matching."""

import spacy
from spacy.language import Language
from spacy.tokens import Doc


@Language.component("legal_entity_detector")
def legal_entity_detector(doc: Doc) -> Doc:
    """Detect and tag legal entity types (e.g., LLC, Corp) as ORG."""
    legal_suffixes = {"llc", "inc", "corp", "ltd", "lp", "llp"}
    for i, token in enumerate(doc):
        if token.text.lower().rstrip(".") in legal_suffixes and i > 0:
            # Tag the preceding token as an organization
            doc[i - 1].ent_type_ = "ORG"
    return doc


# Register component
nlp = spacy.load("en_core_web_sm")
nlp.add_pipe("legal_entity_detector", last=True)
```

---

## Named Entity Recognition

```python
"""NER utilities with filtering and deduplication."""

from dataclasses import dataclass
from collections import defaultdict

import spacy

nlp = spacy.load("en_core_web_sm")

LEGAL_ENTITY_TYPES = {"ORG", "PERSON", "LAW", "GPE", "DATE", "MONEY"}


@dataclass(frozen=True)
class NamedEntity:
    """An extracted named entity."""
    text: str
    label: str
    count: int = 1


def extract_and_count_entities(
    text: str, types: set[str] | None = None
) -> list[NamedEntity]:
    """Extract named entities with occurrence counts.

    Args:
        text: Input text to analyze.
        types: spaCy label types to include. If None, include all.

    Returns:
        List of NamedEntity objects sorted by count descending.
    """
    doc = nlp(text)
    counts: dict[tuple[str, str], int] = defaultdict(int)
    for ent in doc.ents:
        if types is None or ent.label_ in types:
            counts[(ent.text, ent.label_)] += 1
    return sorted(
        [NamedEntity(text=t, label=l, count=c) for (t, l), c in counts.items()],
        key=lambda e: e.count,
        reverse=True,
    )
```

---

## Sentiment Analysis

### Using transformers (HuggingFace)
```python
"""Sentiment analysis using a pre-trained transformer model."""

from transformers import pipeline
from functools import lru_cache


@lru_cache(maxsize=1)
def _get_sentiment_pipeline():
    """Load sentiment pipeline once and cache it."""
    return pipeline("sentiment-analysis", model="distilbert-base-uncased-finetuned-sst-2-english")


def analyze_sentiment(text: str) -> dict[str, str | float]:
    """Classify text as POSITIVE or NEGATIVE with a confidence score.

    Args:
        text: Input text (max ~512 tokens for most models).

    Returns:
        Dict with keys 'label' ('POSITIVE'/'NEGATIVE') and 'score' (0–1).
    """
    classifier = _get_sentiment_pipeline()
    result = classifier(text[:512])[0]
    return {"label": result["label"], "score": round(result["score"], 4)}
```

---

## Text Classification

### TF-IDF + Logistic Regression (fast baseline)
```python
"""Text classification using TF-IDF features."""

from pathlib import Path
import pickle

from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.linear_model import LogisticRegression
from sklearn.pipeline import Pipeline
from sklearn.metrics import classification_report


def build_classifier() -> Pipeline:
    """Build a TF-IDF + LogReg text classification pipeline."""
    return Pipeline(
        [
            ("tfidf", TfidfVectorizer(ngram_range=(1, 2), max_features=50_000)),
            ("clf", LogisticRegression(max_iter=1000, C=1.0)),
        ]
    )


def train(
    texts: list[str], labels: list[str], model_path: Path
) -> Pipeline:
    """Train and persist a text classifier.

    Args:
        texts: Training texts.
        labels: Corresponding labels.
        model_path: Where to save the serialized pipeline.

    Returns:
        Fitted sklearn Pipeline.
    """
    model = build_classifier()
    model.fit(texts, labels)
    model_path.parent.mkdir(parents=True, exist_ok=True)
    with model_path.open("wb") as f:
        pickle.dump(model, f)
    return model


def predict(texts: list[str], model_path: Path) -> list[str]:
    """Load model and predict labels for texts."""
    with model_path.open("rb") as f:
        model = pickle.load(f)  # noqa: S301 -- trusted model artifact
    return model.predict(texts).tolist()
```

---

## Keyword Extraction

```python
"""Keyword and keyphrase extraction using TF-IDF."""

from sklearn.feature_extraction.text import TfidfVectorizer
import numpy as np


def extract_keywords(
    documents: list[str], top_n: int = 10
) -> dict[str, list[tuple[str, float]]]:
    """Extract top TF-IDF keywords per document.

    Args:
        documents: List of text documents.
        top_n: Number of keywords to return per document.

    Returns:
        Dict mapping document index (str) to list of (keyword, score) tuples.
    """
    vectorizer = TfidfVectorizer(stop_words="english", ngram_range=(1, 2))
    tfidf_matrix = vectorizer.fit_transform(documents)
    feature_names = vectorizer.get_feature_names_out()

    results: dict[str, list[tuple[str, float]]] = {}
    for idx, row in enumerate(tfidf_matrix):
        scores = zip(feature_names, row.toarray()[0])
        top = sorted(scores, key=lambda x: x[1], reverse=True)[:top_n]
        results[str(idx)] = [(term, round(score, 4)) for term, score in top if score > 0]

    return results
```

---

## Document Chunking for LLMs

```python
"""Split long documents into overlapping chunks for LLM processing."""


def chunk_text(
    text: str, chunk_size: int = 1000, overlap: int = 100
) -> list[str]:
    """Split text into overlapping character-level chunks.

    Args:
        text: Input text.
        chunk_size: Maximum characters per chunk.
        overlap: Number of characters to overlap between chunks.

    Returns:
        List of text chunk strings.
    """
    if chunk_size <= overlap:
        raise ValueError("chunk_size must be greater than overlap")
    chunks = []
    start = 0
    while start < len(text):
        end = start + chunk_size
        chunks.append(text[start:end])
        start += chunk_size - overlap
    return chunks
```

---

## Testing NLP Code

```python
"""NLP unit tests — deterministic, no model required for core logic."""

import pytest
from my_nlp.preprocessing import normalize
from my_nlp.chunking import chunk_text


def test_normalize_removes_control_chars() -> None:
    assert normalize("hello\x00world") == "helloworld"


def test_normalize_replaces_url() -> None:
    result = normalize("Visit https://example.com today", remove_urls=True)
    assert "[URL]" in result
    assert "https://" not in result


@pytest.mark.parametrize(
    "text,chunk_size,overlap,expected_chunks",
    [
        ("abcdefghij", 5, 2, ["abcde", "defgh", "ghij"]),
        ("abc", 10, 2, ["abc"]),  # shorter than chunk_size
    ],
)
def test_chunk_text(
    text: str, chunk_size: int, overlap: int, expected_chunks: list[str]
) -> None:
    assert chunk_text(text, chunk_size=chunk_size, overlap=overlap) == expected_chunks


def test_chunk_text_raises_when_overlap_exceeds_chunk() -> None:
    with pytest.raises(ValueError, match="chunk_size must be greater than overlap"):
        chunk_text("text", chunk_size=5, overlap=5)
```

---

## See Also

- [`agents/nlp-agent.md`](../agents/nlp-agent.md)
- [`skills/python-testing.md`](python-testing.md)
