# DDD — Domain-Driven Design for AI Agents

Strategic and tactical patterns for modeling complex business domains in code. Align software structure with real-world domain concepts—reduce translation loss between business intent and implementation.

---

## Core Philosophy

Software complexity comes from **domain complexity**, not tech stack. DDD provides vocab and patterns to manage that complexity through:

1. **Ubiquitous language** — Shared domain vocab used in code, docs, conversations
2. **Bounded contexts** — Explicit boundaries where models apply
3. **Strategic design** — How contexts relate and integrate
4. **Tactical patterns** — Building blocks for domain models (entities, aggregates, services)

---

## Strategic Patterns

### Bounded Context

Self-contained domain model with clear boundaries. Same real-world concept may have different models in different contexts.

**Example:** "Customer" in Sales vs. Support contexts

```
┌─────────────────────┐       ┌─────────────────────┐
│  Sales Context      │       │  Support Context    │
│                     │       │                     │
│  Customer:          │       │  Customer:          │
│  - creditLimit      │       │  - ticketHistory    │
│  - accountManager   │       │  - supportTier      │
│  - lifetimeValue    │       │  - lastContactDate  │
└─────────────────────┘       └─────────────────────┘
```

Different models, different concerns—no forced unified schema.

### Context Map

Visual representation of context relationships and integration points.

**Relationship patterns:**

- **Partnership** — Two contexts evolve together, mutual dependency
- **Customer/Supplier** — Downstream depends on upstream; upstream owns contract
- **Conformist** — Downstream conforms to upstream model (no negotiation)
- **Anti-corruption layer** — Translation layer protecting downstream from upstream changes
- **Shared kernel** — Small shared subset of domain model (high coordination cost)
- **Separate ways** — No integration—duplicate functionality in each context

**Example:**

```
┌──────────┐  Customer/    ┌──────────┐
│ Sales    │──Supplier────▶│ Billing  │
└──────────┘               └──────────┘
     │                          │
     │ ACL                      │ ACL
     ▼                          ▼
┌──────────┐  Partnership  ┌──────────┐
│ Support  │◀────────────▶ │ CRM      │
└──────────┘               └──────────┘
```

### Ubiquitous Language

Domain terminology used consistently in code, tests, docs, and conversation. No "translation layer" between business terms and code identifiers.

**❌ Bad:**

```python
# Code uses generic tech terms
class Record:
    def process(self):
        for item in self.items:
            item.update_status()
```

**✅ Good:**

```python
# Code mirrors business language
class PurchaseOrder:
    def approve(self):
        for line_item in self.line_items:
            line_item.reserve_inventory()
```

---

## Tactical Patterns

### Entity

Object defined by identity, not attributes. Same identity = same entity, even if attributes change.

```python
class User:
    def __init__(self, user_id: UUID, email: str, name: str):
        self.id = user_id  # Identity
        self.email = email
        self.name = name
    
    def __eq__(self, other):
        return isinstance(other, User) and self.id == other.id
    
    def __hash__(self):
        return hash(self.id)
```

### Value Object

Immutable object defined only by attributes. No identity. Two value objects with same attributes are interchangeable.

```python
from dataclasses import dataclass

@dataclass(frozen=True)  # Immutable
class Money:
    amount: Decimal
    currency: str
    
    def add(self, other: 'Money') -> 'Money':
        if self.currency != other.currency:
            raise ValueError("Currency mismatch")
        return Money(self.amount + other.amount, self.currency)

# Two Money objects with same values are equal
assert Money(100, "USD") == Money(100, "USD")
```

### Aggregate

Cluster of entities/value objects treated as single unit for data changes. Aggregate root is entry point—external references only to root, never to internal entities.

**Rules:**

1. Enforce invariants across aggregate
2. All external access through root
3. Aggregate is consistency boundary—transaction scope
4. References between aggregates use IDs, not object references

**Example:**

```python
class Order:  # Aggregate root
    def __init__(self, order_id: UUID):
        self.id = order_id
        self._line_items: list[LineItem] = []
        self._status = OrderStatus.DRAFT
    
    def add_item(self, product_id: UUID, quantity: int, price: Money):
        # Root enforces invariants
        if self._status != OrderStatus.DRAFT:
            raise InvalidOperationError("Cannot modify submitted order")
        
        item = LineItem(product_id, quantity, price)
        self._line_items.append(item)
    
    def submit(self):
        if not self._line_items:
            raise InvalidOperationError("Cannot submit empty order")
        self._status = OrderStatus.SUBMITTED

# LineItem is internal to Order aggregate
# External code cannot directly modify LineItem
```

### Repository

Abstraction for aggregate persistence. Provides collection-like interface—hide database details.

```python
from abc import ABC, abstractmethod

class OrderRepository(ABC):
    @abstractmethod
    def find_by_id(self, order_id: UUID) -> Optional[Order]:
        pass
    
    @abstractmethod
    def save(self, order: Order) -> None:
        pass
    
    @abstractmethod
    def find_by_customer(self, customer_id: UUID) -> list[Order]:
        pass

# Implementation uses SQLAlchemy, but domain code doesn't know/care
class SqlOrderRepository(OrderRepository):
    def __init__(self, session: Session):
        self._session = session
    
    def find_by_id(self, order_id: UUID) -> Optional[Order]:
        # Map DB rows to domain objects
        row = self._session.query(OrderModel).filter_by(id=order_id).first()
        return self._to_domain(row) if row else None
    
    def save(self, order: Order) -> None:
        # Map domain objects to DB rows
        model = self._to_model(order)
        self._session.merge(model)
        self._session.commit()
```

### Domain Service

Operation that doesn't naturally belong to any entity/value object. Stateless—operates on domain objects passed as parameters.

```python
class MoneyTransferService:
    def transfer(self, from_account: Account, to_account: Account, amount: Money):
        # Domain logic spanning multiple aggregates
        if not from_account.can_withdraw(amount):
            raise InsufficientFundsError()
        
        from_account.withdraw(amount)
        to_account.deposit(amount)
        
        # Transaction boundary handled by application layer
```

### Domain Event

Something happened in domain that other parts of system care about. Immutable, past tense.

```python
from dataclasses import dataclass
from datetime import datetime

@dataclass(frozen=True)
class OrderSubmitted:
    order_id: UUID
    customer_id: UUID
    total_amount: Money
    submitted_at: datetime

# Aggregate publishes events
class Order:
    def __init__(self, order_id: UUID):
        self.id = order_id
        self._events: list[DomainEvent] = []
    
    def submit(self):
        # ... state change logic ...
        self._events.append(OrderSubmitted(
            order_id=self.id,
            customer_id=self.customer_id,
            total_amount=self.total,
            submitted_at=datetime.now()
        ))
    
    def collect_events(self) -> list[DomainEvent]:
        events = self._events[:]
        self._events.clear()
        return events
```

---

## Layered Architecture

DDD commonly uses layered or hexagonal architecture to isolate domain from infrastructure.

```
┌─────────────────────────────────────────┐
│  Presentation Layer (API, CLI, Web UI)  │
└─────────────────────────────────────────┘
                  ↓
┌─────────────────────────────────────────┐
│  Application Layer (use cases, flows)   │
└─────────────────────────────────────────┘
                  ↓
┌─────────────────────────────────────────┐
│  Domain Layer (entities, value objects, │
│   aggregates, domain services)          │
└─────────────────────────────────────────┘
                  ↓
┌─────────────────────────────────────────┐
│  Infrastructure Layer (DB, HTTP, queue) │
└─────────────────────────────────────────┘
```

**Dependency rule:** Inner layers never depend on outer layers. Domain layer has zero dependencies on infrastructure.

---

## DDD for Agents

**Modeling workflow:**

1. Extract domain terms from user request
2. Identify entities (things with identity) vs. value objects (interchangeable)
3. Group related entities into aggregates
4. Define aggregate boundaries based on invariants
5. Code domain layer first—pure Python, no framework dependencies
6. Add repositories and application services
7. Wire up infrastructure last

**Agent prompt pattern:**

```
Build <feature> using DDD:

1. Extract ubiquitous language from description
2. Model core domain entities and value objects
3. Define aggregates and their boundaries
4. Implement domain logic in aggregate roots
5. Add repositories for persistence
6. Create application service to orchestrate

Keep domain layer pure—no DB, HTTP, or framework imports.
```

---

## When to Use DDD

**✅ Good fit:**

- Complex business domains with many rules and edge cases
- Long-lived applications evolving over years
- Large teams needing clear boundaries and ownership
- Domains with rich, specialized vocabulary
- High cost of misunderstanding requirements

**❌ Overkill:**

- CRUD apps with minimal business logic
- Data pipelines or ETL jobs
- Throwaway prototypes or MVPs
- Simple services with few entities and rules
- Projects where tech complexity exceeds domain complexity

---

## Common Pitfalls

**Anemic domain model** — Entities are just data bags; all logic in services. Defeats purpose of DDD.

```python
# BAD — anemic
class Order:
    def __init__(self):
        self.items = []
        self.status = "draft"

class OrderService:
    def add_item(self, order, item):
        order.items.append(item)  # No encapsulation
```

```python
# GOOD — rich domain model
class Order:
    def add_item(self, item):
        if self.status != "draft":
            raise InvalidOperationError()
        self._items.append(item)  # Encapsulated, enforces invariants
```

**Over-engineering** — Using all DDD patterns everywhere. Apply patterns only where domain complexity justifies them.

**Ignoring bounded contexts** — Trying to create one unified model for entire system. Accept that different contexts need different models.

---

## Resources

- **Blue Book:** Eric Evans, *Domain-Driven Design* (2003) — Original DDD text
- **Red Book:** Vaughn Vernon, *Implementing Domain-Driven Design* (2013) — Practical implementation guide
- **DDD Distilled:** Vaughn Vernon (2016) — Quick intro, 176 pages
- **Python DDD examples:** https://github.com/cosmicpython/book — "Architecture Patterns with Python"
- **Context mapping:** https://github.com/ddd-crew/context-mapping
