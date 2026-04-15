# Skill: Legal and Fiscal Analysis

Patterns and recipes for analyzing legal documents and financial data in
Python, with a focus on correctness, auditability, and compliance.

---

## Foundational Rules

1. **Always use `decimal.Decimal` for money.** Never use `float`.
2. **Preserve source references.** Every data point should trace back to its
   source document, page, and field.
3. **Log all transformations.** Use structured logging for audit trails.
4. **Validate inputs early.** Reject malformed data at the boundary.
5. **Externalize rules.** Tax rates, thresholds, and schedules belong in
   config files, not code.

---

## Decimal Arithmetic

```python
"""Correct monetary arithmetic using decimal.Decimal."""

from decimal import Decimal, ROUND_HALF_UP

CENT = Decimal("0.01")


def round_currency(amount: Decimal) -> Decimal:
    """Round to nearest cent using banker's rounding (ROUND_HALF_UP for finance)."""
    return amount.quantize(CENT, rounding=ROUND_HALF_UP)


def percentage_of(base: Decimal, rate: Decimal) -> Decimal:
    """Compute rate% of base, rounded to cents.

    Args:
        base: The base amount in USD.
        rate: The rate as a decimal fraction (e.g., Decimal("0.22") for 22%).

    Returns:
        Amount rounded to nearest cent.
    """
    return round_currency(base * rate)


# Examples:
# percentage_of(Decimal("50000"), Decimal("0.22")) == Decimal("11000.00")
# percentage_of(Decimal("0.10"), Decimal("0.10")) == Decimal("0.01")
```

---

## Tax Rate Schedule

```python
"""Federal income tax bracket calculator (example)."""

from dataclasses import dataclass
from decimal import Decimal


@dataclass(frozen=True)
class TaxBracket:
    """A single tax bracket."""
    lower: Decimal
    upper: Decimal | None   # None = no upper limit
    rate: Decimal


# 2024 MFJ brackets (example — always verify against current IRS tables)
FEDERAL_BRACKETS_MFJ_2024: list[TaxBracket] = [
    TaxBracket(Decimal("0"), Decimal("23200"), Decimal("0.10")),
    TaxBracket(Decimal("23200"), Decimal("94300"), Decimal("0.12")),
    TaxBracket(Decimal("94300"), Decimal("201050"), Decimal("0.22")),
    TaxBracket(Decimal("201050"), Decimal("383900"), Decimal("0.24")),
    TaxBracket(Decimal("383900"), Decimal("487450"), Decimal("0.32")),
    TaxBracket(Decimal("487450"), Decimal("731200"), Decimal("0.35")),
    TaxBracket(Decimal("731200"), None, Decimal("0.37")),
]


def compute_bracket_tax(
    taxable_income: Decimal, brackets: list[TaxBracket]
) -> Decimal:
    """Compute total income tax using a progressive bracket schedule.

    Args:
        taxable_income: Taxable income after deductions.
        brackets: Ordered list of TaxBracket objects.

    Returns:
        Total tax owed, rounded to cents.

    Raises:
        ValueError: If taxable_income is negative.
    """
    if taxable_income < Decimal("0"):
        raise ValueError("taxable_income must be non-negative")

    total_tax = Decimal("0")
    for bracket in brackets:
        if taxable_income <= bracket.lower:
            break
        upper = bracket.upper if bracket.upper is not None else taxable_income
        taxable_in_bracket = min(taxable_income, upper) - bracket.lower
        total_tax += taxable_in_bracket * bracket.rate

    return round_currency(total_tax)
```

---

## Document Parsing — Invoice

```python
"""Invoice data extraction from structured text."""

import re
from dataclasses import dataclass, field
from datetime import date
from decimal import Decimal
from pathlib import Path

import pdfplumber


INVOICE_NUMBER_RE = re.compile(r"Invoice\s*#?\s*:?\s*([A-Z]{0,4}-?\d{4,})", re.I)
DATE_RE = re.compile(r"(\d{1,2})[/\-](\d{1,2})[/\-](\d{2,4})")
AMOUNT_RE = re.compile(r"\$\s*([\d,]+\.\d{2})")


def extract_invoice_number(text: str) -> str | None:
    """Extract invoice number from raw text."""
    match = INVOICE_NUMBER_RE.search(text)
    return match.group(1) if match else None


def extract_dollar_amounts(text: str) -> list[Decimal]:
    """Extract all dollar amounts from raw text.

    Returns:
        List of Decimal values found in the text.
    """
    return [Decimal(m.replace(",", "")) for m in AMOUNT_RE.findall(text)]


def extract_text_from_pdf(path: Path) -> str:
    """Extract all text from a PDF invoice.

    Args:
        path: Path to the PDF file.

    Returns:
        Concatenated text from all pages.
    """
    with pdfplumber.open(path) as pdf:
        return "\n".join(page.extract_text() or "" for page in pdf.pages)
```

---

## Date and Period Utilities

```python
"""Date arithmetic for fiscal periods."""

from datetime import date, timedelta
from dateutil.relativedelta import relativedelta


def fiscal_year_start(year: int, fiscal_month_start: int = 1) -> date:
    """Return the start date of a fiscal year.

    Args:
        year: Calendar year.
        fiscal_month_start: Month the fiscal year begins (1 = January).

    Returns:
        Start date of the fiscal year.
    """
    return date(year, fiscal_month_start, 1)


def fiscal_year_end(year: int, fiscal_month_start: int = 1) -> date:
    """Return the end date of a fiscal year."""
    start = fiscal_year_start(year, fiscal_month_start)
    return start + relativedelta(years=1) - timedelta(days=1)


def days_overdue(due_date: date, as_of: date | None = None) -> int:
    """Return number of days past due, or 0 if not overdue.

    Args:
        due_date: Invoice due date.
        as_of: Reference date (defaults to today).

    Returns:
        Integer days overdue (0 if not overdue).
    """
    reference = as_of or date.today()
    delta = (reference - due_date).days
    return max(0, delta)


def quarter_for_date(d: date) -> tuple[int, int]:
    """Return (year, quarter) for a given date.

    Returns:
        Tuple of (calendar year, quarter number 1–4).
    """
    return d.year, (d.month - 1) // 3 + 1
```

---

## Depreciation Schedules

```python
"""Common depreciation methods for fiscal analysis."""

from decimal import Decimal


def straight_line_depreciation(
    cost: Decimal, salvage_value: Decimal, useful_life_years: int
) -> list[Decimal]:
    """Calculate annual depreciation using straight-line method.

    Args:
        cost: Original cost of the asset.
        salvage_value: Estimated value at end of useful life.
        useful_life_years: Number of years over which to depreciate.

    Returns:
        List of annual depreciation amounts.

    Raises:
        ValueError: If useful_life_years is less than 1.
    """
    if useful_life_years < 1:
        raise ValueError("useful_life_years must be at least 1")
    annual = (cost - salvage_value) / Decimal(str(useful_life_years))
    return [round_currency(annual)] * useful_life_years


def double_declining_balance(
    cost: Decimal, useful_life_years: int
) -> list[Decimal]:
    """Calculate annual depreciation using double-declining balance.

    Args:
        cost: Original cost of the asset.
        useful_life_years: Number of years over which to depreciate.

    Returns:
        List of annual depreciation amounts. Final year takes remaining value.
    """
    rate = Decimal("2") / Decimal(str(useful_life_years))
    book_value = cost
    annual_amounts = []
    for year in range(useful_life_years - 1):
        depreciation = round_currency(book_value * rate)
        annual_amounts.append(depreciation)
        book_value -= depreciation
    # Final year: depreciate remaining book value
    annual_amounts.append(round_currency(book_value))
    return annual_amounts
```

---

## Legal Document Clause Extraction

```python
"""Extract and classify clauses from legal documents."""

import re
import spacy

nlp = spacy.load("en_core_web_sm")

SECTION_RE = re.compile(
    r"^(?:Section|§)\s*(\d+(?:\.\d+)*)\s*[.:]?\s*(.+?)$",
    re.MULTILINE | re.IGNORECASE,
)


def extract_sections(text: str) -> list[dict[str, str]]:
    """Extract numbered sections from a legal document.

    Args:
        text: Raw document text.

    Returns:
        List of dicts with 'number' and 'heading' keys.
    """
    return [
        {"number": m.group(1), "heading": m.group(2).strip()}
        for m in SECTION_RE.finditer(text)
    ]


OBLIGATION_VERBS = {"shall", "must", "will", "agrees to", "is required to"}


def find_obligation_sentences(text: str) -> list[str]:
    """Find sentences that express legal obligations.

    Args:
        text: Document text.

    Returns:
        List of sentence strings containing obligation language.
    """
    doc = nlp(text)
    return [
        sent.text.strip()
        for sent in doc.sents
        if any(verb in sent.text.lower() for verb in OBLIGATION_VERBS)
    ]
```

---

## Validation with Pydantic

```python
"""Strict financial data validation."""

from datetime import date
from decimal import Decimal

from pydantic import BaseModel, Field, field_validator


class TaxReturnInput(BaseModel):
    """Validated input for a tax return computation."""

    filing_year: int = Field(..., ge=2000, le=2100)
    gross_income: Decimal = Field(..., ge=Decimal("0"))
    deductions: Decimal = Field(default=Decimal("0"), ge=Decimal("0"))
    withholding: Decimal = Field(default=Decimal("0"), ge=Decimal("0"))
    filing_status: str = Field(..., pattern=r"^(single|mfj|mfs|hoh|qw)$")

    @field_validator("gross_income", "deductions", "withholding", mode="before")
    @classmethod
    def coerce_decimal(cls, v: object) -> Decimal:
        try:
            return Decimal(str(v))
        except Exception as exc:
            raise ValueError(f"Cannot convert {v!r} to Decimal") from exc

    @property
    def taxable_income(self) -> Decimal:
        return max(Decimal("0"), self.gross_income - self.deductions)
```

---

## Testing

```python
"""Tests for tax computation logic."""

from decimal import Decimal
from datetime import date
import pytest

from my_fiscal.tax import compute_bracket_tax, FEDERAL_BRACKETS_MFJ_2024
from my_fiscal.dates import days_overdue, quarter_for_date


def test_tax_zero_income() -> None:
    assert compute_bracket_tax(Decimal("0"), FEDERAL_BRACKETS_MFJ_2024) == Decimal("0.00")


def test_tax_first_bracket_only() -> None:
    """Income of $10,000 at 10% = $1,000."""
    result = compute_bracket_tax(Decimal("10000"), FEDERAL_BRACKETS_MFJ_2024)
    assert result == Decimal("1000.00")


def test_tax_raises_negative_income() -> None:
    with pytest.raises(ValueError, match="non-negative"):
        compute_bracket_tax(Decimal("-1"), FEDERAL_BRACKETS_MFJ_2024)


@pytest.mark.parametrize(
    "due,as_of,expected",
    [
        (date(2024, 1, 1), date(2024, 1, 10), 9),
        (date(2024, 1, 10), date(2024, 1, 1), 0),  # not overdue
        (date(2024, 1, 1), date(2024, 1, 1), 0),   # due today
    ],
)
def test_days_overdue(due: date, as_of: date, expected: int) -> None:
    assert days_overdue(due, as_of) == expected


def test_quarter_for_date() -> None:
    assert quarter_for_date(date(2024, 3, 31)) == (2024, 1)
    assert quarter_for_date(date(2024, 7, 1)) == (2024, 3)
```

---

## See Also

- [`agents/legal-fiscal-agent.md`](../agents/legal-fiscal-agent.md)
- [`skills/python-testing.md`](python-testing.md)
