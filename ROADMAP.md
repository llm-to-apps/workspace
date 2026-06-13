# OS7 Roadmap

## Milestones

- [x] **Brand Foundation**: name, domain direction, logo, favicon, core colors, and first app UI integration.
- [x] **Core Positioning**: define OS7 as `Your own agentic operating system`.
- [ ] **AI-Built Personal And Company Apps**: users describe what they need; OS7 creates apps, databases, dashboards, and workflows.
- [ ] **App Orchestration Agent**: one agent manages all installed apps and decides which MCP tools to call.
- [ ] **MCP App Contract**: every app exposes public/private MCP capabilities that agents can discover.
- [ ] **Per-App Model Policy**: each app can specify which model type should operate it.
- [ ] **Shared Agents And People**: users can add people, and their agents can collaborate through permissions.
- [ ] **Agent Teams**: agents can be grouped into teams and work together on shared tasks.
- [ ] **Permission-Based Team Routing**: a team can route a request to the agent/person with the required access.
- [ ] **Scheduled Agent Tasks**: users can schedule one-time or recurring tasks that send prompts to agents.
- [ ] **App Cost Analytics**: users can see which app spent how much money during a selected period.
- [ ] **Audit, Permissions, And Data Lineage**: every sensitive action is explainable, traceable, and revocable.

## Product

- [ ] Make OS7 a platform where AI creates and manages applications for a person or company.
- [ ] Let the user describe what they need in natural language.
- [ ] Let AI create apps, databases, dashboards, and workflows for that need.
- [ ] Make generated apps the structured operating surface where data can live, be visualized, and be acted on over time.
- [ ] Communicate the shift clearly:

```text
Before: buy SaaS and adapt your process to it.
Now: describe your process and get software built around it.
```

## App Orchestration Agent

- [ ] Build an agent that can manage all installed applications at once.
- [ ] Let the agent discover all apps available to the user or company.
- [ ] Let the agent inspect each app's public capabilities.
- [ ] Let the agent inspect each app's private MCP tools.
- [ ] Let the agent see data schemas and resources exposed through MCP.
- [ ] Let the agent understand permissions and access boundaries.
- [ ] Let the agent inspect current app state where available.
- [ ] Let the agent decide which app to query.
- [ ] Let the agent decide which MCP tool to call.
- [ ] Let the agent decide what data can be moved from one app to another.
- [ ] Let the agent transform data before transfer when needed.
- [ ] Let the agent create workflows across multiple apps.
- [ ] Let the agent ask the user for confirmation before sensitive actions.
- [ ] Let the agent decide when a new app or dashboard should be created.

### Example: Company Overview

- [ ] User asks: `Prepare a monthly business overview.`
- [ ] Agent reads invoices from the finance app.
- [ ] Agent reads customer pipeline from CRM.
- [ ] Agent reads support requests from the support app.
- [ ] Agent combines the data.
- [ ] Agent creates a report dashboard.
- [ ] Agent highlights anomalies and next actions.

### Example: Personal Health

- [ ] User asks: `Help me improve my health routine.`
- [ ] Agent reads sleep data from the sleep tracker.
- [ ] Agent reads workout data from the workout app.
- [ ] Agent reads nutrition logs.
- [ ] Agent updates the weekly plan.
- [ ] Agent creates reminders and progress charts.

## MCP Direction

- [ ] Every app should expose an MCP interface.
- [ ] Define **Public MCP**: safe actions and data meant for external tools or user-level automation.
- [ ] Define **Private MCP**: deeper app operations available only to the OS7 orchestration layer and trusted agents.
- [ ] Avoid hardcoding the orchestration agent to specific apps.
- [ ] Let the orchestration agent discover apps dynamically.
- [ ] Let the orchestration agent inspect MCP capabilities dynamically.
- [ ] Let the orchestration agent plan MCP calls dynamically.
- [ ] Design toward the long-term goal:

```text
One chat window.
Many apps.
One agent that knows how to move through them.
```

## Per-App Model Policy

- [ ] Let each app define what type of model should work with it.
- [ ] Support cheap models for simple apps and simple actions.
- [ ] Support stronger reasoning models for complex workflows, planning, sensitive operations, and cross-app orchestration.
- [ ] Let the app contract describe model requirements, context needs, tool risk, and expected task complexity.
- [ ] Let users or admins override the default model policy for an app.
- [ ] Let OS7 choose a model dynamically based on the task, not only the app.
- [ ] Track model cost per app, per workflow, and per user/company.
- [ ] Prefer cheaper models when the task is routine, low-risk, and well-structured.
- [ ] Escalate to stronger models when the task is ambiguous, risky, multi-step, or requires planning.

Example:

```text
Simple habit tracker:
  - cheap model for adding habits, updating check-ins, and summarizing weekly progress

Finance app:
  - cheap model for simple lookups
  - stronger model for month-end analysis, anomaly detection, or cross-app reports

Company orchestration:
  - stronger model when deciding which apps and MCP tools should be called
```

## Scheduled Agent Tasks

- [ ] Let users create scheduled tasks for agents.
- [ ] Support one-time tasks with a specific date and time.
- [ ] Support recurring tasks with a period, such as daily, weekly, monthly, or custom intervals.
- [ ] Let the user choose which agent should receive the scheduled request.
- [ ] Let the user choose the target app or workspace when the task is app-specific.
- [ ] Let the scheduled task contain a natural-language prompt.
- [ ] Treat the scheduler/Cron as another producer of normal `AgentRun` records, not as a separate execution path.
- [ ] Send the prompt to the selected agent at the scheduled time by creating and queueing an `AgentRun`.
- [ ] Add an explicit run source such as `user`, `schedule`, `webhook`, `system`, or `agent`.
- [ ] Reuse the existing agent worker, Mastra execution path, run events, cost tracking, and history for scheduled runs.
- [ ] Support scheduled runs even when no browser/SSE client is currently connected.
- [ ] Let the agent decide which apps, MCP tools, and workflows are needed to complete the task.
- [ ] Store task run history, status, result, errors, and cost.
- [ ] Let users pause, resume, edit, or delete scheduled tasks.
- [ ] Require confirmation rules for scheduled tasks that can trigger sensitive actions.

Example:

```text
Every Monday at 09:00:
  Ask the finance agent to prepare a weekly cashflow summary.

Every day at 21:00:
  Ask the personal health agent to review today's habits and prepare tomorrow's plan.

On the 1st day of every month:
  Ask the company orchestration agent to generate a management report.
```

## App Cost Analytics

- [ ] Let users select a time period for cost analytics.
- [ ] Show how much money each app spent during that period.
- [ ] Show token usage by app, model, workflow, and user where available.
- [ ] Show which model each app used.
- [ ] Show cost trends over time.
- [ ] Let users drill down from app-level cost into individual agent requests.
- [ ] Highlight expensive apps, workflows, or models.
- [ ] Connect this analytics page to per-app model policy.
- [ ] Help users decide where cheaper models are enough and where stronger models are justified.

## Shared Agents And People

- [ ] Let users add other people to their agent or workspace.
- [ ] Let invited people bring their own agents.
- [ ] Let one person's agent talk to another person's agent.
- [ ] Let agents negotiate what data, tools, and MCP calls are needed to solve a shared task.
- [ ] Let a person's agent call that person's available MCP tools when it has permission.
- [ ] Let another person's agent request actions through the owning person's agent instead of directly accessing private MCP tools.
- [ ] Make each agent responsible for protecting its owner's permissions, private data, and boundaries.
- [ ] Support workflows where agents chain MCP calls across people and apps.
- [ ] Track which agent requested an action and which agent executed it.
- [ ] Require confirmation for sensitive cross-person or cross-company actions.

Example:

```text
User A adds User B to a project.

User B's agent asks User A's agent:
  - what project data is available
  - which MCP tools can be used
  - whether a specific report can be generated

User A's agent:
  - checks permissions
  - calls User A's private MCP tools
  - returns only the allowed result

Together, the agents solve the task without exposing raw private access.
```

Long-term idea:

```text
People collaborate through agents.
Agents collaborate through permissions and MCP.
```

## Agent Teams

- [ ] Let users combine multiple agents into a team.
- [ ] Let teams include personal agents, company agents, app-specific agents, and invited people's agents.
- [ ] Let an agent team work together on one shared goal.
- [ ] Let users address a team instead of choosing a specific person or agent.
- [ ] Let the team route the request to the agent that has the required access, data, or expertise.
- [ ] Let agents in a team divide responsibilities based on available tools, permissions, and domain knowledge.
- [ ] Let one agent coordinate the team as a lead agent or orchestrator.
- [ ] Let specialist agents execute subtasks through their own MCP tools.
- [ ] Let agents exchange intermediate results, context, and decisions.
- [ ] Let teams run recurring workflows, not only one-off tasks.
- [ ] Let the user inspect who did what inside the team.
- [ ] Support temporary teams created for a specific project or task.
- [ ] Support persistent teams for ongoing work, such as finance, health, sales, operations, or family planning.

Example:

```text
User: Launch a new internal sales process.

Agent team:
  - CRM agent prepares pipeline stages
  - finance agent checks invoice flow
  - support agent adds request handoff rules
  - docs agent writes the operating procedure
  - orchestrator agent combines everything into one workflow
```

Example:

```text
User writes to the accounting team:
  Who can give me the profit report?

Accounting team:
  - checks which agents are in the team
  - checks who has access to profit data
  - finds that only Margarita Ivanovna's agent can access profit reports
  - routes the request to Margarita Ivanovna's agent

Margarita Ivanovna's agent:
  - checks permissions
  - calls the finance/private MCP tools
  - prepares the allowed report
  - returns it to the team or asks Margarita Ivanovna for confirmation if needed
```

Long-term idea:

```text
Apps have MCP.
People have agents.
Agents can form teams.
Teams can operate whole workflows.
Teams can route requests to whoever has the right access.
```

## Open Questions

- [ ] How should app permissions be modeled?
- [ ] How much autonomy should the orchestration agent have before asking for confirmation?
- [ ] How should data lineage be tracked when moving data between apps?
- [ ] How should the user inspect what the agent did?
- [ ] Should every generated app have a standard audit log?
- [ ] How should private MCP tools be described so the agent can use them safely?
- [ ] What is the minimum app contract every OS7 app must implement?
- [ ] How should one agent safely expose capabilities to another agent?
- [ ] How should cross-agent permissions expire or be revoked?
- [ ] How should agent-to-agent communication be audited?
- [ ] How should agent teams elect or assign a lead agent?
- [ ] How should conflicts between agents be resolved?
- [ ] How should team-level permissions differ from individual agent permissions?
- [ ] How should a team discover which agent has access to a specific dataset or action?
- [ ] How should the UI show that a request was routed to a specific person's agent because of permissions?
