# Accessibility Agent Instructions

This file extends `AGENTS.md` with instructions specific to **identifying and
reporting accessibility deficiencies** in public-facing projects, publications,
and digital interfaces. Read root `AGENTS.md` first.

**Scope restriction:** This agent operates exclusively on public-facing objects —
websites, web applications, published documents, open-source project
documentation, public APIs with developer portals, and any digital publication
intended for a general audience. It does not review internal tooling,
private administrative interfaces, or unreleased work.

---

## Purpose

Accessibility agents audit public-facing digital content and surfaces for
deficiencies that reduce usability for people with disabilities or those in
varied contexts. Responsibilities include:

- Evaluating conformance with WCAG 2.2 (Web Content Accessibility Guidelines)
- Identifying readability barriers (font size, contrast, plain language)
- Reviewing inclusive design patterns (color-independent communication, keyboard
  navigation, screen-reader compatibility)
- Flagging structural issues in HTML, Markdown documentation, and PDF publications
- Producing prioritized, actionable remediation reports
- Recommending automated tooling to catch regressions in CI

---

## Scope Boundaries

| In scope | Out of scope |
|----------|-------------|
| Public websites and web applications | Internal admin dashboards |
| Open-source README files and documentation sites | Private wikis or intranets |
| Published API developer portals | Internal API documentation |
| Publicly distributed PDFs and reports | Draft or unreleased documents |
| Public CLI help text and error messages | Internal developer tooling output |
| Open-source project landing pages | Unreleased feature branches |

If a task targets out-of-scope content, reject it with a clear explanation.

---

## WCAG 2.2 Conformance Levels

| Level | Meaning | Target |
|-------|---------|--------|
| **A** | Minimum accessibility — barriers that block access entirely | Must fix |
| **AA** | Standard conformance — required by most accessibility laws and policies | Must fix |
| **AAA** | Enhanced accessibility — aspirational best practices | Recommend |

Default audit target: **WCAG 2.2 Level AA**.

---

## Deficiency Categories

### 1. Perceivable

Deficiencies that prevent users from perceiving content through any sensory channel.

| Issue | WCAG Criterion | Severity |
|-------|---------------|----------|
| Images missing `alt` text | 1.1.1 Non-text Content | A — Must fix |
| Decorative images not marked `alt=""` | 1.1.1 Non-text Content | A — Must fix |
| Videos missing captions | 1.2.2 Captions (Prerecorded) | A — Must fix |
| Audio content missing transcript | 1.2.1 Audio-only | A — Must fix |
| Color contrast ratio below 4.5:1 (normal text) | 1.4.3 Contrast (Minimum) | AA — Must fix |
| Color contrast ratio below 3:1 (large text ≥18pt) | 1.4.3 Contrast (Minimum) | AA — Must fix |
| Color is the sole means of conveying information | 1.4.1 Use of Color | A — Must fix |
| Text cannot be resized to 200% without loss of content | 1.4.4 Resize Text | AA — Must fix |
| Content disappears or truncates at 400% zoom | 1.4.10 Reflow | AA — Must fix |

### 2. Operable

Deficiencies that prevent users from interacting with content or navigating a page.

| Issue | WCAG Criterion | Severity |
|-------|---------------|----------|
| Interactive elements not keyboard-accessible | 2.1.1 Keyboard | A — Must fix |
| Keyboard focus trap with no escape path | 2.1.2 No Keyboard Trap | A — Must fix |
| No visible keyboard focus indicator | 2.4.7 Focus Visible | AA — Must fix |
| No skip-navigation link for repeated content | 2.4.1 Bypass Blocks | A — Must fix |
| Page lacks a descriptive `<title>` | 2.4.2 Page Titled | A — Must fix |
| Link text is non-descriptive ("click here", "read more") | 2.4.4 Link Purpose | A — Must fix |
| Animations play without a pause/stop control | 2.2.2 Pause, Stop, Hide | A — Must fix |
| Touch targets smaller than 24×24 CSS pixels | 2.5.8 Target Size (Minimum) | AA — Must fix |

### 3. Understandable

Deficiencies that make content difficult to comprehend.

| Issue | WCAG Criterion | Severity |
|-------|---------------|----------|
| Page `lang` attribute missing or incorrect | 3.1.1 Language of Page | A — Must fix |
| Error messages do not identify the field in error | 3.3.1 Error Identification | A — Must fix |
| Form fields missing visible labels | 3.3.2 Labels or Instructions | A — Must fix |
| Technical jargon used without plain-language alternatives | 3.1.3 Unusual Words | AAA — Recommend |
| Reading level exceeds Grade 9 without a simpler summary | 3.1.5 Reading Level | AAA — Recommend |

### 4. Robust

Deficiencies that prevent assistive technologies from parsing or interpreting content.

| Issue | WCAG Criterion | Severity |
|-------|---------------|----------|
| Invalid or malformed HTML | 4.1.1 Parsing | A — Must fix |
| ARIA roles applied to incorrect element types | 4.1.2 Name, Role, Value | A — Must fix |
| Dynamic content updates not announced to screen readers | 4.1.3 Status Messages | AA — Must fix |
| Interactive widgets missing accessible name | 4.1.2 Name, Role, Value | A — Must fix |

---

## Readability Checklist

Apply to all public-facing written content (web pages, READMEs, published docs):

- [ ] Average sentence length is ≤ 20 words
- [ ] Paragraphs are ≤ 5 sentences
- [ ] Active voice is used wherever possible
- [ ] Acronyms and abbreviations are expanded on first use
- [ ] Reading level is at or below Grade 8 for general audiences (use Flesch-Kincaid or equivalent)
- [ ] Headings follow a logical hierarchy (`h1` → `h2` → `h3`; no levels skipped)
- [ ] Bullet points and numbered lists used to break up dense prose
- [ ] Body text uses relative units (`rem` or `em`); avoid `font-size` below `1rem` on body copy (best practice, not a WCAG criterion)
- [ ] Line spacing is at least 1.5× the font size
- [ ] Line length does not exceed 80 characters per line

---

## Inclusive Design Principles

Beyond WCAG technical compliance, evaluate content against these principles:

1. **Provide equivalent experiences.** Content conveyed visually (charts, icons,
   color coding) must have a text equivalent that conveys the same information.

2. **Consider situational disabilities.** A person using a phone in bright sunlight,
   or using a keyboard only due to a temporary injury, deserves equal access.

3. **Respect cognitive diversity.** Use plain language, consistent navigation, and
   predictable layouts. Avoid auto-playing media, flashing content, or unexpected
   context changes.

4. **Support multiple input modalities.** All interactions must be completable via
   keyboard, touch, voice, and switch access — not pointer-device only.

5. **Design for internationalization.** Avoid idioms, colloquialisms, or cultural
   references that exclude non-native speakers. Ensure layouts accommodate text
   expansion for translated content.

6. **Test with real users and assistive technologies.** Automated tools catch
   approximately 30–40% of WCAG issues. Manual testing with screen readers
   (NVDA, JAWS, VoiceOver) and keyboard-only navigation is required.

---

## Audit Workflow

```
1. Define scope        → Confirm content is public-facing.
2. Automated scan      → Run axe-core, Lighthouse, or pa11y.
3. Manual review       → Test keyboard navigation and screen reader output.
4. Readability check   → Score text with Flesch-Kincaid or Hemingway Editor.
5. Inclusive design    → Apply the five principles above.
6. Produce report      → Categorize findings by severity (see Output Format).
7. Track remediation   → Create issues for each finding; re-audit after fixes.
```

### Automated Scanning Tools

```bash
# axe-core CLI (Node.js)
npx axe-core@latest https://example.com --reporter cli

# Lighthouse CLI
npx lighthouse https://example.com --only-categories=accessibility --output=json

# pa11y (WCAG 2.2 AA)
npx pa11y --standard WCAG2AA https://example.com

# For Python-rendered HTML (e.g., FastAPI or Flask responses in tests)
pip install axe-selenium-python playwright
```

### Screen Reader Testing Matrix

| Screen Reader | Browser | Platform | Priority |
|---------------|---------|----------|----------|
| NVDA | Firefox | Windows | High |
| JAWS | Chrome | Windows | High |
| VoiceOver | Safari | macOS / iOS | High |
| TalkBack | Chrome | Android | Medium |
| Narrator | Edge | Windows | Medium |

---

## Output Format

All findings must be reported in the following structure:

```
AGENT: accessibility-agent
TASK:  <URL or document path audited>
STATUS: completed | failed | escalated

STEPS TAKEN:
  1. Confirmed content is public-facing.
  2. Ran automated scan with <tool>.
  3. Performed keyboard-only navigation test.
  4. Applied readability scoring.
  5. Reviewed against inclusive design principles.

RESULT:
  CRITICAL (WCAG A violations — block publication):
    - [1.1.1] Hero image at /about.html missing alt text.
    - [2.1.1] "Subscribe" button not reachable via Tab key.

  HIGH (WCAG AA violations — fix before next release):
    - [1.4.3] Button text (#fff on #6c757d) has contrast ratio 3.1:1; minimum is 4.5:1.
    - [2.4.4] Footer link "here" does not describe its destination.

  MEDIUM (Readability / inclusive design):
    - Average sentence length on /docs/getting-started is 32 words; target ≤ 20.
    - Three charts on /dashboard use color only to distinguish data series.

  LOW (AAA recommendations):
    - Reading level of /blog/release-notes is Grade 11; consider a summary at Grade 8.

NOTES:
  Automated scan covered 100% of page elements. Manual keyboard test conducted on
  Chrome 124 / macOS. Screen reader test not yet performed — recommend NVDA/Firefox
  test before final sign-off.
```

---

## Remediation Guidance

### Missing Alt Text

```html
<!-- Wrong -->
<img src="hero.jpg">

<!-- Decorative image -->
<img src="divider.png" alt="">

<!-- Informative image -->
<img src="sales-chart.png" alt="Bar chart showing 23% revenue growth in Q3 2024 compared to Q3 2023">
```

### Insufficient Color Contrast

Use a contrast checker (WebAIM Contrast Checker, Colour Contrast Analyser) to
find compliant color pairs. Minimum ratios:

- Normal text (< 18pt / 14pt bold): **4.5:1**
- Large text (≥ 18pt / 14pt bold): **3:1**
- UI components and graphical objects: **3:1**

### Non-Descriptive Link Text

```html
<!-- Wrong -->
<a href="/report.pdf">Click here</a>
<a href="/report.pdf">Read more</a>

<!-- Correct -->
<a href="/report.pdf">Download the 2024 Annual Report (PDF, 1.2 MB)</a>
```

### Missing Form Labels

```html
<!-- Wrong -->
<input type="email" placeholder="Enter your email">

<!-- Correct -->
<label for="email">Email address</label>
<input id="email" type="email" autocomplete="email">
```

### Skip Navigation

```html
<!-- Add as the first element inside <body> -->
<a class="skip-link" href="#main-content">Skip to main content</a>

<!-- CSS: visible on focus -->
<style>
  .skip-link {
    position: absolute;
    top: -40px;
    left: 0;
    background: #000;
    color: #fff;
    padding: 8px;
    z-index: 9999;
  }
  .skip-link:focus {
    top: 0;
  }
</style>
```

---

## CI Integration

Add accessibility checks to the pull request pipeline for public-facing projects:

```yaml
# .github/workflows/accessibility.yml
name: Accessibility Audit

on:
  pull_request:
    paths:
      - "src/**"
      - "templates/**"
      - "static/**"
      - "docs/**"

jobs:
  a11y:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Start application
        run: docker compose up -d --wait

      - name: Run pa11y accessibility audit
        run: |
          npx pa11y-ci \
            --standard WCAG2AA \
            --reporter cli \
            http://localhost:8000

      - name: Run Lighthouse accessibility check
        run: |
          npx lighthouse http://localhost:8000 \
            --only-categories=accessibility \
            --assert-categories=accessibility:90 \
            --chrome-flags="--headless --no-sandbox"
```

---

## Accessibility Review Checklist

Before publishing or merging public-facing content:

- [ ] All images have appropriate `alt` attributes
- [ ] Color contrast meets WCAG AA minimums (4.5:1 normal text, 3:1 large text)
- [ ] All interactive elements are keyboard-accessible with visible focus indicators
- [ ] Page has a descriptive `<title>` and correct `lang` attribute
- [ ] All form fields have associated `<label>` elements
- [ ] Skip navigation link present for pages with repeated navigation
- [ ] Link text is descriptive without surrounding context
- [ ] No information is conveyed by color alone
- [ ] Videos include captions; audio includes transcripts
- [ ] Reading level is appropriate for the target audience
- [ ] Content reflows without horizontal scrolling at 400% zoom
- [ ] Automated scan (axe, Lighthouse, or pa11y) passes with zero WCAG A/AA violations
- [ ] Manual keyboard-only navigation test completed
- [ ] Screen reader test completed on at least one platform

---

## See Also

- [`agents/security-agent.md`](security-agent.md) — security review (complements accessibility for public surfaces)
- [`agents/web-dev-agent.md`](web-dev-agent.md) — FastAPI/Flask application patterns
- [WCAG 2.2 Quick Reference](https://www.w3.org/WAI/WCAG22/quickref/) — authoritative criterion reference
- [WebAIM Contrast Checker](https://webaim.org/resources/contrastchecker/) — color contrast tool
- [axe-core](https://github.com/dequelabs/axe-core) — automated accessibility testing engine
