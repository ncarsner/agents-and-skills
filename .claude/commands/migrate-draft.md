---
description: Draft a database migration with rollback plan
allowed-tools: Read, Glob, Grep
argument-hint: <description-of-schema-change>
---

Generate a database migration for: $ARGUMENTS

## Step 1: Identify the migration system
!`ls migrations/ db/migrate/ prisma/migrations/ drizzle/ alembic/versions/ 2>/dev/null | head -20`

Read 2-3 existing migration files to identify:
- ORM/tool (Prisma, Drizzle, Knex, TypeORM, Alembic, Rails, raw SQL)
- Naming convention (timestamp prefix, sequential numbering)
- Structure (up/down methods, SQL vs ORM DSL)

## Step 2: Generate the migration
Create the migration file following the exact conventions from Step 1.

Requirements:
- Include both UP and DOWN (rollback) logic
- The DOWN must perfectly reverse the UP
- For column additions: set a sensible DEFAULT if the column is NOT NULL
- For column removals in DOWN: document data loss warnings as comments
- For index changes: check that the index name follows the project's naming convention
- For table renames: handle foreign key references

## Step 3: Safety checklist
After the migration code, add a comment block with:
- [ ] Estimated row count for affected tables (check with: SELECT count(*) FROM table)
- [ ] Will this lock the table? (ALTER TABLE on large tables can lock for minutes)
- [ ] Is this backwards-compatible with the current application code?
- [ ] Can this be deployed independently of the application change?
- [ ] What happens if the migration fails halfway through?

Do NOT run the migration. Output the file content only.
