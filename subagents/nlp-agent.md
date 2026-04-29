# NLP Agent Instructions

This file extends `AGENTS.md` with instructions specific to **natural language
processing (NLP)** projects in Python. Read root `AGENTS.md` first.

---

## Purpose

NLP agents build systems that read, analyze, classify, extract, and generate
human language. Focus areas include:

- Text preprocessing and normalization
- Named entity recognition (NER)
- Text classification and sentiment analysis
- Keyword and keyphrase extraction
- Document similarity and search
- Summarization
- PDF/document ingestion

---

## Recommended Libraries

| Task | Library | Install |
|------|---------|---------|
| NLP pipeline (production) | `spacy` | `uv add spacy` |
| NLP pipeline (research) | `transformers` | `uv add transformers` |
| Tokenization (fast) | `tokenizers` | `uv add tokenizers` |
| ML modeling | `scikit-learn` | `uv add scikit-learn` |
| Deep learning | `torch` | `uv add torch` |
| PDF extraction | `pypdf` | `uv add pypdf` |
| Document parsing | `python-docx` | `uv add python-docx` |
| Data wrangling | `pandas` | `uv add pandas` |
| Text similarity | `sentence-transformers` | `uv add sentence-transformers` |
| Embeddings / vector DB | `chromadb` | `uv add chromadb` |
| Regex patterns | `re` | stdlib |

Default spaCy model for English: `en_core_web_sm` (fast) or `en_core_web_trf`
(transformer-based, accurate).

---

## Project Structure

```
my-nlp-project/
├── pyproject.toml
├── uv.lock
├── .python-version
├── README.md
├── AGENTS.md
├── data/
│   ├── raw/                   # original documents (not committed if large)
│   └── processed/             # cleaned/tokenized data
├── models/                    # serialized model artifacts
├── src/
│   └── my_nlp/
│       ├── __init__.py
│       ├── pipeline.py        # end-to-end NLP pipeline
│       ├── preprocessing.py   # text cleaning and normalization
│       ├── extraction.py      # entity / keyphrase extraction
│       ├── classification.py  # text classification
│       └── similarity.py      # document similarity / search
└── tests/
    ├── conftest.py
    ├── unit/
    │   ├── test_preprocessing.py
    │   └── test_extraction.py
    └── integration/
        └── test_pipeline.py
```

---

## Text Preprocessing Pattern

```python
"""Text cleaning and normalization utilities."""

import re
import unicodedata

import spacy

nlp = spacy.load("en_core_web_sm")


def normalize_whitespace(text: str) -> str:
    """Collapse multiple whitespace characters into a single space."""
    return re.sub(r"\s+", " ", text).strip()


def remove_control_characters(text: str) -> str:
    """Remove non-printable control characters from text."""
    return "".join(
        ch for ch in text if unicodedata.category(ch)[0] != "C"
    )


def clean_text(text: str) -> str:
    """Apply full normalization pipeline to raw text."""
    text = remove_control_characters(text)
    text = normalize_whitespace(text)
    return text


def tokenize(text: str, remove_stopwords: bool = True) -> list[str]:
    """Tokenize text and optionally remove stop words and punctuation.

    Args:
        text: Input text string.
        remove_stopwords: If True, filter out stop words.

    Returns:
        List of lowercase token strings.
    """
    doc = nlp(clean_text(text))
    tokens = [
        token.lemma_.lower()
        for token in doc
        if not token.is_punct and not token.is_space
        and (not remove_stopwords or not token.is_stop)
    ]
    return tokens
```

---

## Named Entity Recognition Pattern

```python
"""Named entity extraction using spaCy."""

from dataclasses import dataclass

import spacy

nlp = spacy.load("en_core_web_sm")


@dataclass
class Entity:
    """A named entity extracted from text."""

    text: str
    label: str
    start_char: int
    end_char: int


def extract_entities(text: str) -> list[Entity]:
    """Extract named entities from text.

    Args:
        text: Input text to analyze.

    Returns:
        List of Entity objects found in the text.
    """
    doc = nlp(text)
    return [
        Entity(
            text=ent.text,
            label=ent.label_,
            start_char=ent.start_char,
            end_char=ent.end_char,
        )
        for ent in doc.ents
    ]


def extract_entities_by_type(
    text: str, entity_types: list[str]
) -> dict[str, list[str]]:
    """Extract entities grouped by type label.

    Args:
        text: Input text.
        entity_types: spaCy labels to include (e.g. ["ORG", "PERSON", "DATE"]).

    Returns:
        Dict mapping label to list of entity strings.
    """
    entities = extract_entities(text)
    result: dict[str, list[str]] = {label: [] for label in entity_types}
    for ent in entities:
        if ent.label in result:
            result[ent.label].append(ent.text)
    return result
```

---

## Document Similarity Pattern

```python
"""Semantic document similarity using sentence-transformers."""

import numpy as np
from sentence_transformers import SentenceTransformer

_model = SentenceTransformer("all-MiniLM-L6-v2")


def embed_texts(texts: list[str]) -> np.ndarray:
    """Encode a list of texts into dense vectors.

    Args:
        texts: List of text strings to embed.

    Returns:
        2-D numpy array of shape (len(texts), embedding_dim).
    """
    return _model.encode(texts, convert_to_numpy=True, show_progress_bar=False)


def cosine_similarity(a: np.ndarray, b: np.ndarray) -> float:
    """Compute cosine similarity between two vectors.

    Args:
        a: First embedding vector.
        b: Second embedding vector.

    Returns:
        Similarity score in [0, 1].
    """
    norm_a = np.linalg.norm(a)
    norm_b = np.linalg.norm(b)
    if norm_a == 0 or norm_b == 0:
        return 0.0
    return float(np.dot(a, b) / (norm_a * norm_b))


def rank_by_similarity(query: str, documents: list[str]) -> list[tuple[float, str]]:
    """Rank documents by semantic similarity to a query.

    Args:
        query: Query string.
        documents: List of document strings to rank.

    Returns:
        List of (score, document) tuples sorted by descending score.
    """
    all_texts = [query] + documents
    embeddings = embed_texts(all_texts)
    query_vec = embeddings[0]
    scored = [
        (cosine_similarity(query_vec, embeddings[i + 1]), doc)
        for i, doc in enumerate(documents)
    ]
    return sorted(scored, key=lambda x: x[0], reverse=True)
```

---

## PDF Ingestion Pattern

```python
"""PDF text extraction utilities."""

from pathlib import Path

from pypdf import PdfReader


def extract_text_from_pdf(path: Path) -> str:
    """Extract all text from a PDF file.

    Args:
        path: Path to the PDF file.

    Returns:
        Concatenated text content of all pages.

    Raises:
        FileNotFoundError: If the PDF file does not exist.
        ValueError: If the file is not a readable PDF.
    """
    if not path.exists():
        raise FileNotFoundError(f"PDF not found: {path}")

    reader = PdfReader(path)
    pages: list[str] = []
    for page in reader.pages:
        text = page.extract_text() or ""
        pages.append(text)
    return "\n\n".join(pages)


def extract_text_by_page(path: Path) -> list[str]:
    """Extract text from each page of a PDF separately.

    Args:
        path: Path to the PDF file.

    Returns:
        List of text strings, one per page.
    """
    if not path.exists():
        raise FileNotFoundError(f"PDF not found: {path}")

    reader = PdfReader(path)
    return [page.extract_text() or "" for page in reader.pages]
```

---

## Testing NLP Modules

```python
"""Unit tests for preprocessing module."""

import pytest

from my_nlp.preprocessing import clean_text, normalize_whitespace, tokenize


def test_normalize_whitespace_collapses_spaces() -> None:
    """Multiple spaces should collapse to one."""
    assert normalize_whitespace("hello   world") == "hello world"


def test_normalize_whitespace_strips_edges() -> None:
    """Leading and trailing whitespace should be removed."""
    assert normalize_whitespace("  hello  ") == "hello"


def test_clean_text_removes_control_characters() -> None:
    """Control characters should be stripped."""
    assert clean_text("hello\x00world") == "helloworld"


@pytest.mark.parametrize(
    "text,expected_contains",
    [
        ("The quick brown fox", ["quick", "brown", "fox"]),
        ("Running quickly", ["run", "quick"]),  # lemmatized
    ],
)
def test_tokenize_lemmatizes(text: str, expected_contains: list[str]) -> None:
    """Tokenize should return lemmatized, lowercase tokens."""
    tokens = tokenize(text)
    for expected in expected_contains:
        assert expected in tokens
```

---

## See Also

- [`skills/nlp-processing.md`](../skills/nlp-processing.md) — detailed NLP patterns
- [`skills/python-testing.md`](../skills/python-testing.md) — testing cookbook
