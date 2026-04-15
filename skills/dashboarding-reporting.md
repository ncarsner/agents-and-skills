# Skill: Dashboarding and Reporting

Patterns and recipes for creating data visualizations, interactive dashboards,
and automated reports in Python.

---

## Library Selection

| Need | Library | When to Use |
|------|---------|------------|
| Static charts (PNG/PDF) | `matplotlib` | Print reports, email attachments |
| Interactive charts | `plotly` | Web dashboards, notebooks |
| Full interactive dashboard | `dash` | Web app without separate frontend |
| Data wrangling | `pandas` | Always |
| Excel output | `openpyxl` | Excel-native reports |
| HTML reports | `jinja2` | Templated HTML emails, static pages |
| PDF reports | `reportlab` | Formal PDF documents |

---

## Data Preparation Patterns

### Load and validate
```python
"""Data loading with schema validation."""

from pathlib import Path
import pandas as pd


REQUIRED_COLUMNS: set[str] = {"date", "category", "amount"}


def load_and_validate(path: Path) -> pd.DataFrame:
    """Load a CSV and validate required columns and types.

    Args:
        path: Path to the CSV file.

    Returns:
        Validated DataFrame with correct dtypes.

    Raises:
        FileNotFoundError: If path does not exist.
        ValueError: If required columns are missing.
    """
    if not path.exists():
        raise FileNotFoundError(f"Data file not found: {path}")

    df = pd.read_csv(path)
    missing = REQUIRED_COLUMNS - set(df.columns)
    if missing:
        raise ValueError(f"Missing required columns: {sorted(missing)}")

    df["date"] = pd.to_datetime(df["date"], errors="raise")
    df["amount"] = pd.to_numeric(df["amount"], errors="raise")
    return df
```

### Aggregation functions
```python
"""Common aggregation patterns."""


def monthly_totals(df: pd.DataFrame, value_col: str = "amount") -> pd.DataFrame:
    """Aggregate a time-series DataFrame to monthly totals.

    Args:
        df: DataFrame with a 'date' column (datetime dtype).
        value_col: Column to sum.

    Returns:
        DataFrame with columns: year_month, total.
    """
    return (
        df.assign(year_month=df["date"].dt.to_period("M"))
        .groupby("year_month")[value_col]
        .sum()
        .reset_index()
        .rename(columns={value_col: "total"})
        .sort_values("year_month")
    )


def top_n_categories(df: pd.DataFrame, n: int = 5, value_col: str = "amount") -> pd.DataFrame:
    """Return the top N categories by total value.

    Args:
        df: DataFrame with 'category' and value columns.
        n: Number of top categories to return.
        value_col: Column to aggregate.

    Returns:
        DataFrame with columns: category, total (sorted descending).
    """
    return (
        df.groupby("category")[value_col]
        .sum()
        .reset_index()
        .rename(columns={value_col: "total"})
        .nlargest(n, "total")
    )
```

---

## Matplotlib Chart Patterns

### Figure factory with save support
```python
"""Matplotlib figure factories."""

from pathlib import Path
import matplotlib.pyplot as plt
import matplotlib.ticker as mticker
import pandas as pd


PALETTE = ["#2196F3", "#4CAF50", "#FF9800", "#F44336", "#9C27B0"]


def bar_chart(
    labels: list[str],
    values: list[float],
    title: str,
    xlabel: str,
    ylabel: str,
    output_path: Path | None = None,
) -> plt.Figure:
    """Create a vertical bar chart.

    Args:
        labels: X-axis category labels.
        values: Corresponding bar heights.
        title: Chart title.
        xlabel: X-axis label.
        ylabel: Y-axis label.
        output_path: If given, save the figure here.

    Returns:
        Matplotlib Figure.
    """
    fig, ax = plt.subplots(figsize=(10, 6))
    colors = [PALETTE[i % len(PALETTE)] for i in range(len(labels))]
    bars = ax.bar(labels, values, color=colors)
    ax.bar_label(bars, fmt="${:,.0f}", padding=3)
    ax.set_title(title, fontsize=14, fontweight="bold")
    ax.set_xlabel(xlabel)
    ax.set_ylabel(ylabel)
    ax.yaxis.set_major_formatter(mticker.FuncFormatter(lambda x, _: f"${x:,.0f}"))
    ax.tick_params(axis="x", rotation=30)
    fig.tight_layout()
    if output_path:
        output_path.parent.mkdir(parents=True, exist_ok=True)
        fig.savefig(output_path, dpi=150, bbox_inches="tight")
    return fig


def time_series_chart(
    df: pd.DataFrame,
    date_col: str,
    value_col: str,
    title: str,
    output_path: Path | None = None,
) -> plt.Figure:
    """Create a time series line chart with shaded area."""
    fig, ax = plt.subplots(figsize=(12, 5))
    ax.plot(df[date_col], df[value_col], linewidth=2, color=PALETTE[0])
    ax.fill_between(df[date_col], df[value_col], alpha=0.15, color=PALETTE[0])
    ax.set_title(title, fontsize=14, fontweight="bold")
    ax.set_xlabel("Date")
    ax.set_ylabel(value_col.replace("_", " ").title())
    fig.autofmt_xdate()
    fig.tight_layout()
    if output_path:
        output_path.parent.mkdir(parents=True, exist_ok=True)
        fig.savefig(output_path, dpi=150, bbox_inches="tight")
    return fig
```

---

## Plotly Interactive Charts

```python
"""Plotly figure factories for Dash dashboards."""

import plotly.express as px
import plotly.graph_objects as go
import pandas as pd


def bar_chart_plotly(df: pd.DataFrame, x: str, y: str, title: str) -> go.Figure:
    """Create an interactive Plotly bar chart."""
    fig = px.bar(
        df, x=x, y=y, title=title,
        color=y, color_continuous_scale="Blues",
        labels={y: y.replace("_", " ").title(), x: x.title()},
    )
    fig.update_traces(texttemplate="%{y:$,.0f}", textposition="outside")
    fig.update_layout(showlegend=False, uniformtext_minsize=8)
    return fig


def pie_chart_plotly(df: pd.DataFrame, names: str, values: str, title: str) -> go.Figure:
    """Create an interactive donut chart."""
    return px.pie(
        df, names=names, values=values, title=title, hole=0.4,
        color_discrete_sequence=px.colors.qualitative.Set2,
    )


def kpi_indicator(label: str, value: float, reference: float) -> go.Figure:
    """Create a KPI indicator with delta from reference."""
    fig = go.Figure(
        go.Indicator(
            mode="number+delta",
            value=value,
            delta={"reference": reference, "relative": True, "valueformat": ".1%"},
            title={"text": label},
            number={"prefix": "$", "valueformat": ",.0f"},
        )
    )
    fig.update_layout(height=200)
    return fig
```

---

## Dash Dashboard Pattern

```python
"""Minimal Dash dashboard skeleton."""

import dash
from dash import Input, Output, dcc, html
import plotly.graph_objects as go

from my_dashboard.data import load_data, top_n_categories, monthly_totals
from my_dashboard.charts import bar_chart_plotly, time_series_chart


def build_layout(categories: list[str]) -> html.Div:
    """Build the static dashboard layout."""
    return html.Div(
        className="dashboard",
        children=[
            html.H1("Financial Dashboard"),
            html.Div(
                className="controls",
                children=[
                    dcc.Dropdown(
                        id="category-filter",
                        options=[{"label": c, "value": c} for c in categories],
                        multi=True,
                        placeholder="Filter by category...",
                    ),
                    dcc.DatePickerRange(
                        id="date-range",
                        display_format="YYYY-MM-DD",
                    ),
                ],
            ),
            dcc.Graph(id="bar-chart"),
            dcc.Graph(id="trend-chart"),
        ],
    )


def register_callbacks(app: dash.Dash, df) -> None:
    """Register all Dash callbacks."""

    @app.callback(
        Output("bar-chart", "figure"),
        Output("trend-chart", "figure"),
        Input("category-filter", "value"),
        Input("date-range", "start_date"),
        Input("date-range", "end_date"),
    )
    def update_charts(categories, start_date, end_date):
        filtered = df.copy()
        if categories:
            filtered = filtered[filtered["category"].isin(categories)]
        if start_date:
            filtered = filtered[filtered["date"] >= start_date]
        if end_date:
            filtered = filtered[filtered["date"] <= end_date]

        top = top_n_categories(filtered)
        monthly = monthly_totals(filtered)

        return (
            bar_chart_plotly(top, "category", "total", "Top Categories"),
            bar_chart_plotly(monthly, "year_month", "total", "Monthly Trend"),
        )


def create_app(data_path: str = "data/processed/data.csv") -> dash.Dash:
    """Create and configure the Dash application."""
    app = dash.Dash(__name__, title="Financial Dashboard")
    df = load_data(data_path)
    categories = sorted(df["category"].unique().tolist())
    app.layout = build_layout(categories)
    register_callbacks(app, df)
    return app
```

---

## Excel Report Pattern

```python
"""Generate formatted Excel reports using openpyxl."""

from pathlib import Path
from datetime import datetime

import openpyxl
from openpyxl.styles import Font, PatternFill, Alignment, numbers
from openpyxl.utils import get_column_letter
import pandas as pd


HEADER_FILL = PatternFill("solid", fgColor="2196F3")
HEADER_FONT = Font(bold=True, color="FFFFFF")


def write_excel_report(
    df: pd.DataFrame, output_path: Path, sheet_name: str = "Report"
) -> None:
    """Write a DataFrame to a formatted Excel file.

    Args:
        df: Data to write.
        output_path: Destination .xlsx path.
        sheet_name: Name for the worksheet.
    """
    wb = openpyxl.Workbook()
    ws = wb.active
    ws.title = sheet_name

    # Write header
    for col_idx, col_name in enumerate(df.columns, start=1):
        cell = ws.cell(row=1, column=col_idx, value=col_name)
        cell.font = HEADER_FONT
        cell.fill = HEADER_FILL
        cell.alignment = Alignment(horizontal="center")

    # Write data
    for row_idx, row in enumerate(df.itertuples(index=False), start=2):
        for col_idx, value in enumerate(row, start=1):
            ws.cell(row=row_idx, column=col_idx, value=value)

    # Auto-size columns
    for col_idx, col in enumerate(df.columns, start=1):
        max_len = max(len(str(col)), df[col].astype(str).str.len().max())
        ws.column_dimensions[get_column_letter(col_idx)].width = min(max_len + 4, 40)

    # Freeze header row
    ws.freeze_panes = "A2"

    output_path.parent.mkdir(parents=True, exist_ok=True)
    wb.save(output_path)
```

---

## Scheduled Report Delivery

```python
"""Email a generated report using smtplib."""

import smtplib
from email.message import EmailMessage
from pathlib import Path


def email_report(
    subject: str,
    body: str,
    attachment: Path,
    recipients: list[str],
    sender: str,
    smtp_host: str,
    smtp_port: int = 587,
    smtp_user: str | None = None,
    smtp_password: str | None = None,
) -> None:
    """Send an email with a file attachment.

    Args:
        subject: Email subject line.
        body: Plain text body.
        attachment: Path to the file to attach.
        recipients: List of recipient email addresses.
        sender: Sender email address.
        smtp_host: SMTP server hostname.
        smtp_port: SMTP server port (587 for STARTTLS).
        smtp_user: SMTP username (if authentication required).
        smtp_password: SMTP password (if authentication required).
    """
    msg = EmailMessage()
    msg["Subject"] = subject
    msg["From"] = sender
    msg["To"] = ", ".join(recipients)
    msg.set_content(body)

    with attachment.open("rb") as f:
        msg.add_attachment(
            f.read(),
            maintype="application",
            subtype="octet-stream",
            filename=attachment.name,
        )

    with smtplib.SMTP(smtp_host, smtp_port) as smtp:
        smtp.ehlo()
        smtp.starttls()
        if smtp_user and smtp_password:
            smtp.login(smtp_user, smtp_password)
        smtp.send_message(msg)
```

---

## Testing Dashboard Code

```python
"""Tests for aggregation and report generation."""

import pandas as pd
import pytest
from pathlib import Path

from my_dashboard.data import load_and_validate, top_n_categories


@pytest.fixture
def sample_df() -> pd.DataFrame:
    return pd.DataFrame(
        {
            "date": pd.to_datetime(["2024-01-01", "2024-01-02", "2024-02-01"]),
            "category": ["A", "B", "A"],
            "amount": [100.0, 50.0, 200.0],
        }
    )


def test_top_n_categories_returns_correct_order(sample_df: pd.DataFrame) -> None:
    result = top_n_categories(sample_df, n=2)
    assert result.iloc[0]["category"] == "A"
    assert result.iloc[0]["total"] == 300.0


def test_load_and_validate_missing_columns(tmp_path: Path) -> None:
    p = tmp_path / "bad.csv"
    p.write_text("a,b\n1,2\n")
    with pytest.raises(ValueError, match="Missing required columns"):
        load_and_validate(p)
```

---

## See Also

- [`agents/dashboard-reporting-agent.md`](../agents/dashboard-reporting-agent.md)
- [`skills/python-testing.md`](python-testing.md)
- [`templates/pyproject.toml`](../templates/pyproject.toml)
