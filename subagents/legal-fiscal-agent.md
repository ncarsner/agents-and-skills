# Legal and Fiscal Analysis Agent Instructions

This file extends `AGENTS.md` with instructions specific to **legal and fiscal
data analysis** projects in Python. Read root `AGENTS.md` first.

---

## Purpose

Legal and fiscal analysis agents produce tools that:

- Parse, classify, and summarize legal documents (contracts, statutes, filings)
- Extract and validate structured financial data (invoices, reports, ledgers)
- Apply tax rules, depreciation schedules, and compliance checks
- Generate auditable outputs with full data lineage

**Auditability is the top priority.** Every transformation and decision MUST be
traceable back to the source data and the rule that produced it.

---

## Recommended Libraries

| Need | Library | Install |
|------|---------|---------|
| Data wrangling | `pandas` | `uv add pandas` |
| Decimal arithmetic | `decimal` | stdlib |
| Date calculations | `dateutil` | `uv add python-dateutil` |
| PDF extraction | `pypdf` | `uv add pypdf` |
| Excel I/O | `openpyxl` | `uv add openpyxl` |
| Data validation | `pydantic` | `uv add pydantic` |
| Reporting | `reportlab` or `jinja2` | `uv add reportlab` |
| NLP (legal text) | `spacy` | `uv add spacy` |
| Statistical analysis | `scipy` | `uv add scipy` |

**Always use `decimal.Decimal` — never `float` — for monetary values.**

---

## Core Data Model Patterns

```python
"""Core data models for fiscal analysis."""

from dataclasses import dataclass, field
from datetime import date
from decimal import Decimal


@dataclass
class LineItem:
    """A single line item in a financial document."""

    description: str
    quantity: Decimal
    unit_price: Decimal
    tax_rate: Decimal = Decimal("0.00")

    @property
    def subtotal(self) -> Decimal:
        """Gross amount before tax."""
        return (self.quantity * self.unit_price).quantize(Decimal("0.01"))

    @property
    def tax_amount(self) -> Decimal:
        """Tax owed on this line item."""
        return (self.subtotal * self.tax_rate).quantize(Decimal("0.01"))

    @property
    def total(self) -> Decimal:
        """Total including tax."""
        return self.subtotal + self.tax_amount


@dataclass
class Invoice:
    """A parsed invoice document."""

    invoice_number: str
    issue_date: date
    due_date: date
    vendor: str
    client: str
    line_items: list[LineItem] = field(default_factory=list)

    @property
    def subtotal(self) -> Decimal:
        """Sum of all line item subtotals."""
        return sum((item.subtotal for item in self.line_items), Decimal("0.00"))

    @property
    def total_tax(self) -> Decimal:
        """Sum of all line item tax amounts."""
        return sum((item.tax_amount for item in self.line_items), Decimal("0.00"))

    @property
    def total_due(self) -> Decimal:
        """Total amount due."""
        return self.subtotal + self.total_tax

    def is_overdue(self, as_of: date | None = None) -> bool:
        """Return True if the invoice is past its due date."""
        reference = as_of or date.today()
        return reference > self.due_date
```

---

## Tax Rule Engine Pattern

```python
"""Configurable tax rule engine."""

from dataclasses import dataclass
from decimal import Decimal
from typing import Protocol


class TaxRule(Protocol):
    """Interface for a tax rule."""

    def applies_to(self, description: str, amount: Decimal) -> bool:
        """Return True if this rule applies to the given line item."""
        ...

    def compute(self, amount: Decimal) -> Decimal:
        """Return the tax amount for a given taxable amount."""
        ...


@dataclass
class PercentageTaxRule:
    """A simple percentage-based tax rule."""

    name: str
    rate: Decimal
    keywords: list[str] = None

    def __post_init__(self) -> None:
        if self.keywords is None:
            self.keywords = []
        if not (Decimal("0") <= self.rate <= Decimal("1")):
            raise ValueError(f"rate must be between 0 and 1, got {self.rate}")

    def applies_to(self, description: str, amount: Decimal) -> bool:
        """Rule applies if any keyword is found in the description."""
        if not self.keywords:
            return True
        return any(kw.lower() in description.lower() for kw in self.keywords)

    def compute(self, amount: Decimal) -> Decimal:
        """Apply percentage rate to amount."""
        return (amount * self.rate).quantize(Decimal("0.01"))


class TaxEngine:
    """Applies a list of tax rules to compute total tax."""

    def __init__(self, rules: list[TaxRule]) -> None:
        self.rules = rules

    def compute_tax(self, description: str, amount: Decimal) -> Decimal:
        """Apply all matching rules and return total tax.

        Args:
            description: Line item description.
            amount: Pre-tax amount.

        Returns:
            Total tax amount from all applicable rules.
        """
        total = Decimal("0.00")
        for rule in self.rules:
            if rule.applies_to(description, amount):
                total += rule.compute(amount)
        return total
```

---

## Data Validation Pattern

```python
"""Pydantic models for validated financial data intake."""

from datetime import date
from decimal import Decimal

from pydantic import BaseModel, Field, field_validator, model_validator


class InvoiceLineItemInput(BaseModel):
    """Validated input for a single invoice line item."""

    description: str = Field(..., min_length=1)
    quantity: Decimal = Field(..., gt=Decimal("0"))
    unit_price: Decimal = Field(..., ge=Decimal("0"))
    tax_rate: Decimal = Field(default=Decimal("0.00"), ge=Decimal("0"), le=Decimal("1"))

    @field_validator("quantity", "unit_price", "tax_rate", mode="before")
    @classmethod
    def coerce_to_decimal(cls, v: object) -> Decimal:
        """Convert numeric strings and floats to Decimal."""
        try:
            return Decimal(str(v))
        except Exception as exc:
            raise ValueError(f"Cannot convert {v!r} to Decimal") from exc


class InvoiceInput(BaseModel):
    """Validated input for a complete invoice."""

    invoice_number: str = Field(..., pattern=r"^INV-\d{4,}$")
    issue_date: date
    due_date: date
    vendor: str = Field(..., min_length=1)
    client: str = Field(..., min_length=1)
    line_items: list[InvoiceLineItemInput] = Field(..., min_length=1)

    @model_validator(mode="after")
    def due_date_after_issue_date(self) -> "InvoiceInput":
        """Ensure due date is not before issue date."""
        if self.due_date < self.issue_date:
            raise ValueError("due_date must be on or after issue_date")
        return self
```

---

## Audit Trail Pattern

```python
"""Audit logging for fiscal transformations."""

import logging
from dataclasses import dataclass, field
from datetime import datetime
from decimal import Decimal

logger = logging.getLogger(__name__)


@dataclass
class AuditEntry:
    """A single auditable transformation record."""

    timestamp: datetime
    source: str
    field: str
    original_value: str
    transformed_value: str
    rule_applied: str
    notes: str = ""


class AuditLog:
    """Ordered collection of audit entries."""

    def __init__(self) -> None:
        self._entries: list[AuditEntry] = []

    def record(
        self,
        source: str,
        field: str,
        original: object,
        transformed: object,
        rule: str,
        notes: str = "",
    ) -> None:
        """Record a data transformation."""
        entry = AuditEntry(
            timestamp=datetime.utcnow(),
            source=source,
            field=field,
            original_value=str(original),
            transformed_value=str(transformed),
            rule_applied=rule,
            notes=notes,
        )
        self._entries.append(entry)
        logger.debug(
            "AUDIT | %s.%s | %s → %s | rule=%s",
            source,
            field,
            original,
            transformed,
            rule,
        )

    @property
    def entries(self) -> list[AuditEntry]:
        """Return a copy of all audit entries."""
        return list(self._entries)
```

---

## Reporting Pattern

```python
"""Generate fiscal summary reports as CSV or rendered text."""

import csv
import io
from pathlib import Path

from my_fiscal.models import Invoice


def write_invoice_csv(invoices: list[Invoice], output_path: Path) -> None:
    """Write a summary of invoices to a CSV file.

    Args:
        invoices: List of Invoice objects to summarize.
        output_path: Destination path for the CSV file.
    """
    output_path.parent.mkdir(parents=True, exist_ok=True)
    with output_path.open("w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(
            f,
            fieldnames=[
                "invoice_number",
                "issue_date",
                "due_date",
                "vendor",
                "subtotal",
                "total_tax",
                "total_due",
                "overdue",
            ],
        )
        writer.writeheader()
        for inv in invoices:
            writer.writerow(
                {
                    "invoice_number": inv.invoice_number,
                    "issue_date": inv.issue_date.isoformat(),
                    "due_date": inv.due_date.isoformat(),
                    "vendor": inv.vendor,
                    "subtotal": str(inv.subtotal),
                    "total_tax": str(inv.total_tax),
                    "total_due": str(inv.total_due),
                    "overdue": inv.is_overdue(),
                }
            )
```

---

## Testing Financial Logic

```python
"""Tests for fiscal data models."""

from datetime import date
from decimal import Decimal

import pytest

from my_fiscal.models import Invoice, LineItem


@pytest.fixture
def sample_invoice() -> Invoice:
    """Build a simple two-item invoice for testing."""
    return Invoice(
        invoice_number="INV-0001",
        issue_date=date(2024, 1, 1),
        due_date=date(2024, 1, 31),
        vendor="Acme Corp",
        client="Client LLC",
        line_items=[
            LineItem(
                description="Consulting",
                quantity=Decimal("10"),
                unit_price=Decimal("150.00"),
                tax_rate=Decimal("0.10"),
            ),
            LineItem(
                description="Software license",
                quantity=Decimal("1"),
                unit_price=Decimal("500.00"),
                tax_rate=Decimal("0.00"),
            ),
        ],
    )


def test_line_item_subtotal() -> None:
    """10 units × $150 should equal $1500.00."""
    item = LineItem("Consulting", Decimal("10"), Decimal("150.00"))
    assert item.subtotal == Decimal("1500.00")


def test_line_item_tax_amount() -> None:
    """Tax at 10% on $1500 should equal $150.00."""
    item = LineItem("Consulting", Decimal("10"), Decimal("150.00"), Decimal("0.10"))
    assert item.tax_amount == Decimal("150.00")


def test_invoice_total_due(sample_invoice: Invoice) -> None:
    """Invoice total should equal sum of all line item totals."""
    assert sample_invoice.total_due == Decimal("2150.00")


def test_invoice_is_overdue(sample_invoice: Invoice) -> None:
    """Invoice should be overdue when checked after due date."""
    assert sample_invoice.is_overdue(as_of=date(2024, 2, 1))


def test_invoice_not_overdue_before_due_date(sample_invoice: Invoice) -> None:
    """Invoice should not be overdue when checked before due date."""
    assert not sample_invoice.is_overdue(as_of=date(2024, 1, 15))
```

---

## Compliance Checklist

- [ ] All monetary arithmetic uses `decimal.Decimal` (never `float`)
- [ ] Every computed value is logged in the audit trail
- [ ] Source document references (file name, page number) are preserved
- [ ] Output files include generation timestamp and version
- [ ] Rules are externalized to config files (not hard-coded)
- [ ] Validation errors report field name, received value, and constraint violated
- [ ] Reports include a "data sources" section listing all inputs

---

## See Also

- [`skills/legal-fiscal-analysis.md`](../skills/legal-fiscal-analysis.md)
- [`skills/python-testing.md`](../skills/python-testing.md)
