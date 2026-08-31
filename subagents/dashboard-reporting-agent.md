# Dashboard and Reporting Agent Instructions

This file extends `AGENTS.md` with instructions specific to **dashboarding and
reporting** projects in Python. Read root `AGENTS.md` first.

---

## Purpose

Dashboard and reporting agents build tools that:

- Transform raw data into clear, decision-ready visualizations
- Generate static reports (PDF, HTML, CSV, Excel)
- Power interactive web dashboards
- Automate scheduled report delivery

---

## Recommended Libraries

| Need | Library | Install |
|------|---------|---------|
| Static plots | `matplotlib` | `uv add matplotlib` |
| Interactive plots | `plotly` | `uv add plotly` |
| Interactive dashboard | `dash` | `uv add dash` |
| Data wrangling | `pandas` | `uv add pandas` |
| Excel output | `openpyxl` or `xlsxwriter` | `uv add openpyxl` |
| HTML report templates | `jinja2` | `uv add jinja2` |
| PDF reports | `reportlab` or `weasyprint` | `uv add reportlab` |
| Statistical summaries | `scipy` | `uv add scipy` |
| Color palettes | `matplotlib` | included |

---

## Project Structure

```
my-dashboard/
├── pyproject.toml
├── uv.lock
├── .python-version
├── README.md
├── AGENTS.md
├── data/
│   ├── raw/
│   └── processed/
├── reports/                   # generated output (gitignored if large)
├── templates/                 # Jinja2 HTML/text templates
├── src/
│   └── my_dashboard/
│       ├── __init__.py
│       ├── app.py             # Dash app entry point (if interactive)
│       ├── layout.py          # Dash layout components
│       ├── callbacks.py       # Dash callbacks
│       ├── charts.py          # Matplotlib / Plotly figure factories
│       ├── data_loader.py     # Data ingestion and preparation
│       ├── aggregations.py    # Metric computations
│       └── report_generator.py
└── tests/
    ├── conftest.py
    ├── unit/
    │   ├── test_aggregations.py
    │   └── test_data_loader.py
    └── integration/
        └── test_report_generator.py
```

---

## Data Preparation Pattern

```python
"""Data loading and preparation utilities."""

from pathlib import Path

import pandas as pd


def load_sales_data(path: Path) -> pd.DataFrame:
    """Load and validate sales CSV data.

    Args:
        path: Path to the CSV file.

    Returns:
        DataFrame with columns: date, region, product, quantity, revenue.

    Raises:
        FileNotFoundError: If the file does not exist.
        ValueError: If required columns are missing.
    """
    required_columns = {"date", "region", "product", "quantity", "revenue"}

    if not path.exists():
        raise FileNotFoundError(f"Data file not found: {path}")

    df = pd.read_csv(path, parse_dates=["date"])
    missing = required_columns - set(df.columns)
    if missing:
        raise ValueError(f"Missing required columns: {missing}")

    # Type coercion and validation
    df["quantity"] = pd.to_numeric(df["quantity"], errors="raise")
    df["revenue"] = pd.to_numeric(df["revenue"], errors="raise")
    df = df.dropna(subset=["date", "region", "product"])
    return df


def summarize_by_region(df: pd.DataFrame) -> pd.DataFrame:
    """Aggregate revenue and quantity by region.

    Args:
        df: Input sales DataFrame.

    Returns:
        DataFrame indexed by region with total_revenue and total_quantity.
    """
    return (
        df.groupby("region")
        .agg(total_revenue=("revenue", "sum"), total_quantity=("quantity", "sum"))
        .reset_index()
        .sort_values("total_revenue", ascending=False)
    )
```

---

## Matplotlib Chart Patterns

```python
"""Reusable Matplotlib figure factories."""

from pathlib import Path

import matplotlib.pyplot as plt
import pandas as pd


def bar_chart_by_region(
    summary: pd.DataFrame, output_path: Path | None = None
) -> plt.Figure:
    """Create a bar chart of total revenue by region.

    Args:
        summary: DataFrame with columns: region, total_revenue.
        output_path: If provided, save the figure to this path.

    Returns:
        Matplotlib Figure object.
    """
    fig, ax = plt.subplots(figsize=(10, 6))
    ax.bar(summary["region"], summary["total_revenue"], color="#2196F3")
    ax.set_xlabel("Region")
    ax.set_ylabel("Total Revenue ($)")
    ax.set_title("Revenue by Region")
    ax.tick_params(axis="x", rotation=45)
    fig.tight_layout()

    if output_path is not None:
        output_path.parent.mkdir(parents=True, exist_ok=True)
        fig.savefig(output_path, dpi=150, bbox_inches="tight")

    return fig


def trend_line_chart(
    df: pd.DataFrame,
    date_col: str,
    value_col: str,
    title: str,
    output_path: Path | None = None,
) -> plt.Figure:
    """Create a time-series trend line chart.

    Args:
        df: DataFrame containing date and value columns.
        date_col: Name of the date column.
        value_col: Name of the value column.
        title: Chart title.
        output_path: If provided, save the figure to this path.

    Returns:
        Matplotlib Figure object.
    """
    daily = df.groupby(date_col)[value_col].sum().reset_index()
    fig, ax = plt.subplots(figsize=(12, 5))
    ax.plot(daily[date_col], daily[value_col], linewidth=2, color="#4CAF50")
    ax.fill_between(daily[date_col], daily[value_col], alpha=0.1, color="#4CAF50")
    ax.set_title(title)
    ax.set_xlabel("Date")
    ax.set_ylabel(value_col.replace("_", " ").title())
    fig.tight_layout()

    if output_path is not None:
        output_path.parent.mkdir(parents=True, exist_ok=True)
        fig.savefig(output_path, dpi=150, bbox_inches="tight")

    return fig
```

---

## Plotly Interactive Chart Pattern

```python
"""Plotly figure factories for interactive dashboards."""

import plotly.express as px
import plotly.graph_objects as go
import pandas as pd


def revenue_by_region_bar(summary: pd.DataFrame) -> go.Figure:
    """Create an interactive bar chart of revenue by region."""
    return px.bar(
        summary,
        x="region",
        y="total_revenue",
        title="Revenue by Region",
        labels={"total_revenue": "Total Revenue ($)", "region": "Region"},
        color="total_revenue",
        color_continuous_scale="Blues",
    )


def revenue_trend_line(df: pd.DataFrame) -> go.Figure:
    """Create an interactive revenue trend line chart."""
    daily = df.groupby("date")["revenue"].sum().reset_index()
    return px.line(
        daily,
        x="date",
        y="revenue",
        title="Daily Revenue Trend",
        labels={"revenue": "Revenue ($)", "date": "Date"},
    )
```

---

## Dash App Pattern

```python
"""Interactive Dash dashboard application."""

import dash
from dash import Input, Output, dcc, html

from my_dashboard.data_loader import load_sales_data, summarize_by_region
from my_dashboard.charts import revenue_by_region_bar, revenue_trend_line

DATA_PATH = "data/processed/sales.csv"


def create_app() -> dash.Dash:
    """Create and configure the Dash application."""
    app = dash.Dash(__name__, title="Sales Dashboard")

    df = load_sales_data(DATA_PATH)
    regions = df["region"].unique().tolist()

    app.layout = html.Div(
        [
            html.H1("Sales Dashboard", style={"textAlign": "center"}),
            dcc.Dropdown(
                id="region-filter",
                options=[{"label": r, "value": r} for r in regions],
                multi=True,
                placeholder="Filter by region...",
            ),
            dcc.Graph(id="revenue-bar"),
            dcc.Graph(id="revenue-trend"),
        ]
    )

    @app.callback(
        Output("revenue-bar", "figure"),
        Output("revenue-trend", "figure"),
        Input("region-filter", "value"),
    )
    def update_charts(selected_regions: list[str] | None):
        filtered = df
        if selected_regions:
            filtered = df[df["region"].isin(selected_regions)]
        summary = summarize_by_region(filtered)
        return revenue_by_region_bar(summary), revenue_trend_line(filtered)

    return app


if __name__ == "__main__":
    app = create_app()
    app.run(debug=True)
```

---

## HTML Report Template (Jinja2)

`templates/report.html.jinja2`:
```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>{{ title }}</title>
  <style>
    body { font-family: Arial, sans-serif; margin: 2rem; }
    table { border-collapse: collapse; width: 100%; }
    th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
    th { background-color: #2196F3; color: white; }
    tr:nth-child(even) { background-color: #f2f2f2; }
  </style>
</head>
<body>
  <h1>{{ title }}</h1>
  <p>Generated: {{ generated_at }}</p>
  <table>
    <thead>
      <tr>{% for col in columns %}<th>{{ col }}</th>{% endfor %}</tr>
    </thead>
    <tbody>
      {% for row in rows %}
      <tr>{% for val in row %}<td>{{ val }}</td>{% endfor %}</tr>
      {% endfor %}
    </tbody>
  </table>
</body>
</html>
```

---

## Report Generator Pattern

```python
"""Generate HTML and CSV reports from DataFrames."""

from datetime import datetime
from pathlib import Path

import pandas as pd
from jinja2 import Environment, FileSystemLoader


class ReportGenerator:
    """Generates HTML and CSV reports from tabular data."""

    def __init__(self, template_dir: Path) -> None:
        self._env = Environment(loader=FileSystemLoader(str(template_dir)))

    def to_html(
        self,
        df: pd.DataFrame,
        title: str,
        output_path: Path,
        template: str = "report.html.jinja2",
    ) -> None:
        """Render a DataFrame to an HTML report file.

        Args:
            df: Data to render.
            title: Report title.
            output_path: Where to write the HTML file.
            template: Template filename relative to template_dir.
        """
        tmpl = self._env.get_template(template)
        html = tmpl.render(
            title=title,
            generated_at=datetime.utcnow().strftime("%Y-%m-%d %H:%M UTC"),
            columns=df.columns.tolist(),
            rows=df.values.tolist(),
        )
        output_path.parent.mkdir(parents=True, exist_ok=True)
        output_path.write_text(html, encoding="utf-8")

    def to_csv(self, df: pd.DataFrame, output_path: Path) -> None:
        """Write a DataFrame to a CSV file.

        Args:
            df: Data to write.
            output_path: Where to write the CSV file.
        """
        output_path.parent.mkdir(parents=True, exist_ok=True)
        df.to_csv(output_path, index=False, encoding="utf-8")
```

---

## Testing Charts and Reports

```python
"""Unit tests for aggregation functions."""

from pathlib import Path
import pandas as pd
import pytest

from my_dashboard.aggregations import summarize_by_region


@pytest.fixture
def sample_sales_df() -> pd.DataFrame:
    """Minimal sales DataFrame for testing."""
    return pd.DataFrame(
        {
            "date": pd.to_datetime(["2024-01-01", "2024-01-02", "2024-01-03"]),
            "region": ["North", "South", "North"],
            "product": ["Widget", "Gadget", "Widget"],
            "quantity": [10, 5, 8],
            "revenue": [1000.0, 250.0, 800.0],
        }
    )


def test_summarize_by_region_sums_revenue(sample_sales_df: pd.DataFrame) -> None:
    """North region should have combined revenue of 1800."""
    result = summarize_by_region(sample_sales_df)
    north_row = result[result["region"] == "North"].iloc[0]
    assert north_row["total_revenue"] == 1800.0


def test_summarize_by_region_sorted_desc(sample_sales_df: pd.DataFrame) -> None:
    """Results should be sorted by revenue descending."""
    result = summarize_by_region(sample_sales_df)
    revenues = result["total_revenue"].tolist()
    assert revenues == sorted(revenues, reverse=True)
```

---

## See Also

- [`skills/dashboarding-reporting.md`](../skills/dashboarding-reporting.md)
- [`skills/python-testing.md`](../skills/python-testing.md)
