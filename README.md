# OS7

OS7 is a platform for creating, installing, managing, and evolving applications through AI.

The core idea is simple: a user or company gets a personal application environment where apps can be installed from templates, connected together, controlled from one chat window, and extended by AI over time.

In other words, OS7 is an operating layer above business and personal software.

## Vision

Most software today is fragmented.

A company may have a CRM, finance tracker, booking system, inventory tool, internal dashboards, spreadsheets, and custom automations. A person may have task managers, notes, budgeting tools, documents, calendars, and personal databases.

Each app has its own interface, data model, login, workflow, and limitations. Moving data between them usually requires manual work, fragile integrations, or custom scripts.

OS7 turns this into a unified AI-controlled workspace:

```text
User intent
  -> single chat interface
  -> AI orchestrator
  -> app-specific tools and MCP calls
  -> data moves, apps change, workflows run
  -> user sees the result
```

The user does not need to know which API, database, or service should be called. The orchestrator understands the request, chooses the right app or tool, performs the work, and reports back.

## Product Concept

OS7 starts with application templates.

A user can choose a template such as:

- personal finance
- CRM
- booking
- inventory
- internal admin panel
- content calendar
- support desk
- project tracker

The platform deploys that template into the user's own isolated live instance. The app is immediately usable and can be opened in the browser.

Then the user can talk to the platform:

```text
"Add a field for customer priority."
"Import this CSV into the CRM."
"Show overdue invoices from the finance app."
"Move paid customers into the onboarding tracker."
"Create a dashboard for revenue by month."
"Change this page so managers can approve requests."
```

The AI can manage the app at multiple levels:

- use the app through tools and APIs
- read and write data
- call MCP servers connected to the app
- inspect logs and runtime state
- edit source code
- run migrations
- restart or redeploy services
- commit successful changes

This makes each installed application both usable software and an AI-editable workspace.

## Agent OS / Personal OS

The larger product direction is an AI operating system for applications.

Possible names:

- **Agent OS**: emphasizes that the system is operated by agents and can coordinate many tools, apps, and workflows.
- **Personal OS**: emphasizes the user's own environment, memory, preferences, apps, and data.
- **Company OS**: emphasizes the business version: an AI-native internal operating layer for a team or organization.
- **OS7**: emphasizes coordination. Many apps and agents act like instruments, while the orchestrator turns user intent into action.

The best positioning may be:

```text
OS7 is an Agent OS for personal and company applications.
```

For individual users, it behaves like a Personal OS.

For teams and companies, it behaves like a Company OS.

## What Makes It Different

Traditional SaaS gives the user fixed applications.

No-code tools let users assemble workflows, but they still require the user to understand logic, data, integrations, and edge cases.

AI coding tools can modify code, but they usually operate on one repository at a time and are not the main interface for using the deployed software.

OS7 combines these layers:

- **Template marketplace**: install useful apps quickly.
- **Live app hosting**: each user gets a real deployed app instance.
- **AI app management**: the user can operate the app through conversation.
- **AI app development**: the user can ask for product changes, and the platform edits the source code.
- **MCP orchestration**: the agent can call tools across apps and external services.
- **Unified chat**: one interface can control many applications.
- **Data movement**: data can be transformed and moved between apps without manual export/import.
- **Persistent context**: the platform can remember user, project, app, and company context.

The result is not just "AI inside an app." It is AI above a user's whole application environment.

## Example Flow

1. A user signs up.
2. The user installs a CRM template.
3. OS7 creates an isolated project and deploys the CRM.
4. The user imports customers from a spreadsheet.
5. The user asks the chat to add a "contract renewal date" field.
6. The agent edits the CRM source code, updates the database schema, runs checks, and redeploys.
7. Later, the user installs a finance app.
8. The user asks: "Show CRM customers with unpaid invoices."
9. The orchestrator queries both apps, joins the data, and returns the answer.
10. The user asks: "Create a renewal workflow for customers with unpaid invoices."
11. The orchestrator creates the workflow across CRM, finance, and notifications.

## Architecture Direction

At a high level, the platform contains:

```text
OS7 Platform
  - authentication
  - billing
  - app template catalog
  - project management
  - deployment manager
  - AI orchestrator
  - MCP/tool router
  - memory and context engine
  - audit log
  - git integration
  - database provisioning

User App Instance
  - app source code
  - runtime environment
  - isolated database credentials
  - app-specific tool server
  - logs and health checks
  - git workspace

Unified Chat
  - understands user intent
  - selects the right app/tool
  - performs MCP calls
  - edits code when needed
  - explains the result
```

The current repository already follows this direction:

- `web` handles registration, templates, projects, and the user-facing product surface.
- `manager` controls deployment of user app services.
- `agent` runs the AI orchestration layer.
- `agent-tools` contains tooling exposed to agents.
- `templates` contains starter applications.
- `deploy` and `docker` contain infrastructure pieces.

## Core Capabilities

### Install Apps From Templates

Users should be able to select an application template and deploy it into a live, isolated environment.

Templates are not static demos. They are the starting point for a user's own software.

### Manage Apps Through AI

The chat should become the main control surface.

The user can ask for operational work:

- create records
- update data
- generate reports
- import or export files
- search across apps
- trigger workflows
- inspect errors

### Modify Apps Through AI

The same chat can change the product itself:

- add fields
- change pages
- create dashboards
- add roles and permissions
- integrate external APIs
- update database schema
- improve workflows

The platform should make these changes safely: inspect, edit, test, run migrations, redeploy, and commit.

### Orchestrate Data Across Apps

The long-term value appears when many apps are installed.

The orchestrator should be able to move and transform data between apps:

```text
CRM customer
  -> invoice in finance app
  -> onboarding task
  -> notification
  -> dashboard update
```

This is where MCP becomes important. Each app can expose tools, and the orchestrator can decide which tools to call.

### Build a Persistent User or Company Context

The platform should understand:

- what apps exist
- what data each app owns
- what tools are available
- what the user prefers
- what the company workflow looks like
- what previous changes were made

This context makes the AI more useful over time.

## Strategic Goal

The goal is to make software feel less like a collection of separate products and more like one living system.

Users install apps when they need structure.

They use chat when they need action.

They ask AI to change the software when the structure no longer fits.

That is the promise of OS7:

```text
Install apps.
Control them through AI.
Connect them through agents.
Evolve them through conversation.
```

