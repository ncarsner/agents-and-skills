# BDD — Behavior-Driven Development for AI Agents

Guide for writing executable specs, bridging user stories and test automation. Focus on collaboration through ubiquitous language—business, dev, test speak same vocab.

---

## Core Pattern

User story → Given/When/Then → Automated tests → Living docs

Each scenario tests **one behavior** in plain language readable by non-technical stakeholders.

---

## Gherkin Syntax

```gherkin
Feature: User authentication
  As a returning user
  I want to log in securely
  So that I can access my dashboard

  Scenario: Successful login with valid credentials
    Given I am on the login page
    And I have a registered account
    When I enter valid username and password
    And I click the "Login" button
    Then I should see my dashboard
    And I should see a welcome message

  Scenario: Failed login with invalid password
    Given I am on the login page
    When I enter a valid username
    And I enter an invalid password
    And I click the "Login" button
    Then I should see "Invalid credentials"
    And I should remain on the login page
```

---

## BDD Workflow

1. **Discovery** — Stakeholder + dev + QA collaborative writing session  
   Map user stories to concrete examples with business value
   
2. **Formulation** — Convert examples to Given/When/Then scenarios  
   Focus on behavior not implementation—no technical jargon
   
3. **Automation** — Bind scenarios to test code  
   Use frameworks like pytest-bdd, behave (Python), Cucumber (Ruby/JS)
   
4. **Validation** — Run scenarios as executable specs  
   Pass = behavior exists; fail = missing or broken behavior
   
5. **Living documentation** — Scenarios stay synchronized with code  
   When behavior changes, update scenario first, then code

---

## Pytest-BDD Example

**Feature file: `features/auth.feature`**

```gherkin
Feature: Password reset
  Scenario: Request password reset email
    Given a user exists with email "user@example.com"
    When I request a password reset for "user@example.com"
    Then I should receive a reset email
    And the email should contain a reset link
```

**Step definitions: `tests/test_auth.py`**

```python
from pytest_bdd import scenarios, given, when, then, parsers
import pytest

scenarios('features/auth.feature')

@given(parsers.parse('a user exists with email "{email}"'))
def existing_user(email, user_repository):
    user_repository.create(email=email)

@when(parsers.parse('I request a password reset for "{email}"'))
def request_reset(email, auth_service):
    auth_service.request_password_reset(email)

@then('I should receive a reset email')
def verify_email_sent(email_service):
    assert email_service.sent_count() == 1

@then('the email should contain a reset link')
def verify_reset_link(email_service):
    email = email_service.last_sent()
    assert 'reset-password' in email.body
```

---

## BDD Anti-Patterns

**❌ Testing implementation details**

```gherkin
# BAD — exposes internal structure
Given the database contains user ID 42
When I call UserRepository.findById(42)
Then it should return a User object
```

```gherkin
# GOOD — tests behavior
Given a user exists
When I search for that user
Then I should see their profile
```

**❌ Scenarios too long or complex**

```gherkin
# BAD — tests multiple behaviors, hard to debug
Scenario: Complete user journey
  Given I register a new account
  And I verify my email
  And I log in
  And I update my profile
  And I change my password
  And I log out
  And I log back in
  ...
```

Break into focused scenarios—one behavior each.

**❌ Missing context in Given/When/Then**

```gherkin
# BAD — unclear preconditions
When I click submit
Then I see success message
```

```gherkin
# GOOD — explicit context
Given I am on the contact form
And I have filled all required fields
When I click "Submit"
Then I should see "Message sent successfully"
```

---

## BDD for Agents

When building features, write scenarios **before code**:

1. Translate user request into Gherkin scenarios
2. Show scenarios to user for confirmation (async if possible)
3. Implement step definitions as test stubs
4. Write minimal code to pass each step
5. Refactor while keeping scenarios green

**Agent prompt pattern:**

```
I need to add feature: <description>

Write BDD scenarios in Given/When/Then format covering:
- Happy path
- Primary error cases
- Edge cases

Then implement step definitions and minimal code to pass.
```

---

## Tools by Language

| Language   | Framework          | Docs                                  |
|------------|--------------------|---------------------------------------|
| Python     | pytest-bdd         | https://pytest-bdd.readthedocs.io     |
| Python     | behave             | https://behave.readthedocs.io         |
| JavaScript | Cucumber.js        | https://cucumber.io/docs/cucumber-js  |
| Ruby       | Cucumber           | https://cucumber.io/docs/ruby         |
| Java       | Cucumber JVM       | https://cucumber.io/docs/jvm          |
| .NET       | SpecFlow           | https://specflow.org                  |

---

## When to Use BDD

**✅ Good fit:**

- User-facing features with clear business rules
- Complex domain logic requiring stakeholder collaboration
- Projects with non-technical stakeholders in spec review
- Regulatory compliance—scenarios serve as acceptance criteria

**❌ Overkill:**

- Internal refactoring with no behavior change
- Pure technical components with no user-visible behavior
- Throwaway prototypes or spikes
- Microservices with narrow, stable contracts

---

## Key Principles

1. **Ubiquitous language** — Use domain terms in scenarios, not tech jargon
2. **Executable specs** — Scenarios are tests, not just documentation
3. **Outside-in** — Start with user behavior, work inward to implementation
4. **Collaboration first** — BDD is a communication tool before automation tool
5. **Living docs** — Scenarios evolve with product, never drift from reality

---

## Resources

- **BDD Fundamentals:** https://cucumber.io/docs/bdd/
- **Dan North (BDD creator):** https://dannorth.net/introducing-bdd/
- **Gherkin reference:** https://cucumber.io/docs/gherkin/reference/
- **pytest-bdd examples:** https://github.com/pytest-dev/pytest-bdd/tree/master/examples
