# OS7 Template Rules

These rules apply to all OS7 app templates.

## Next.js App Architecture

All new OS7 Next.js app templates should use the App Router only. Do not add a
`pages/` router alongside `app/`.

Use a consistent project layout:

- `app/` for Next.js route segments, layouts, route handlers, loading/error
  boundaries, and providers.
- `src/features/<feature>/` for business feature modules.
- `src/features/<feature>/schemas.ts` for shared input schemas and parsing.
- `src/features/<feature>/service.ts` for business operations, Prisma writes,
  serialization, realtime notifications, and mutation rules.
- `src/server/` for server-only modules such as auth, env, db, events,
  serializers, resolvers, filters, and snapshot builders.
- `src/shared/` for shared schemas, result/error contracts, UI-neutral types,
  and small utilities.
- `src/mcp/` for typed MCP tool registries and dispatch.
- `app/api/**/route.ts` as thin route adapters that handle auth/request/response
  concerns and delegate business work to feature services.
- `app/api/mcp/route.ts` as a thin MCP/JSON-RPC adapter. It should register
  tools from shared feature schemas and delegate execution to feature services.

Avoid putting substantial Prisma queries, validation, or business rules directly
inside route handlers. Prisma access should happen through feature services or a
future shared DAL, not from UI components.

Feature modules should keep one source of truth for each business operation:

- API routes use the feature service.
- MCP tools use the same feature service.
- Tool input schemas come from the feature schema module.
- Runtime parsing should use the shared schema layer and Zod-based parsers.
- UI and agent-facing APIs should receive stable structured results, not
  free-form UI strings.

Use path aliases instead of long relative imports:

- `@/features/*`
- `@/server/*`
- `@/shared/*`
- `@/mcp/*`

API routes should use a shared result/error contract. Do not hand-roll a new
error envelope in each route; use the app's standard `AppResult` / `AppError`
helpers and HTTP mapping.

Server-only modules that touch secrets, cookies, Prisma, auth, env, events, or
business data must import `server-only` at the top of the file.

## Logging And Audit

Every OS7 app template should include a small server-side logging wrapper, such
as `src/server/logger.ts`. Do not scatter raw `console.log` calls through
feature services, API routes, MCP handlers, workers, or background jobs.

Runtime logs should be structured and machine-readable. Prefer stable event names
and object payloads over free-form strings. Long-running operations should log a
minimal lifecycle:

- `<operation>.started`
- `<operation>.finished`
- `<operation>.failed`

If Sentry access is configured for an app, server-side unexpected errors must be
reported to Sentry in addition to structured runtime logs. Sentry integration
must be optional: local/dev templates should keep working without Sentry env
vars. Keep Sentry payloads safe and narrow; redact tokens, cookies, OAuth codes,
secrets, provider payloads, SQL details, and large personal-data objects before
reporting.

Useful log context should include the fields that exist for the current request:

- `requestId`
- `userId`
- `projectId` or app/resource id
- `operation` or event name
- `status`
- `elapsedMs`
- external service name when calling MCP, OAuth, email, queues, storage, or
  payment providers

Never log secrets or raw credentials. Logs must not include auth tokens, cookies,
OAuth codes, API keys, database passwords, full connection strings, private
headers, or unredacted environment values. For agent and MCP calls, log tool
names, status, duration, and narrow identifiers; avoid dumping full prompts,
large tool arguments, personal data, or raw tool JSON unless the app explicitly
needs a redacted debug mode.

Background jobs, queues, streams, and external calls should log important
milestones such as enqueue, start, retry, external request started/finished,
stream first chunk, completion, and failure. Include durations so slow steps can
be diagnosed from stdout alone.

Mutating business operations should write audit events separately from runtime
logs when the app has user-owned data. Audit events should capture who did what,
to which resource, and when, with safe metadata. Runtime logs are for operators;
audit events are for product/accountability history.

User-facing error messages should stay concise and safe. Do not expose internal
stack traces, provider payloads, SQL details, tokens, or implementation-specific
log context in UI responses.

Each app should include standard route-level boundaries:

- `app/loading.tsx`
- `app/error.tsx`
- `app/not-found.tsx`

Each app should include a formatting and linting baseline:

- `eslint.config.mjs`
- `prettier.config.mjs`
- `.prettierignore`
- `.editorconfig`
- `npm run lint`
- `npm run format`
- `npm run format:check`
- `npm run test`
- `npm run test:e2e` for critical Playwright flows when the app includes a UI
- `npm run typecheck`
- `npm run build`

Apps with database-backed user workflows must also include e2e tests against a
real database, not only mocked service tests. The real-database e2e path should
exercise at least one critical create/read workflow through the browser and API
surface, using the same service layer as production.

For simple Prisma apps, prefer a service-free SQLite-backed e2e script such as
`npm run test:e2e:sqlite` when the schema can support both providers. The app may
also support the production database provider for compatibility checks, but the
default developer and CI path should not require a manually managed database
server unless the app genuinely depends on provider-specific database behavior.

Real-database e2e scripts should:

- create or reset an isolated test database
- apply the current schema before the browser run
- run Playwright with local/test auth enabled
- cover at least one full CRUD or mutation workflow for core business data
- clean generated database files and Playwright artifacts, or ignore them in
  `.gitignore`

Each template should document dependency audit expectations. Audit fixes should
be deliberate dependency work; do not run forced audit fixes during unrelated
feature changes.

## Mobile-First UX

All OS7 app templates must be mobile-first. Mobile adaptation is mandatory, not
an optional follow-up. The first usable screen and every common CRUD workflow
must work on narrow mobile viewports before desktop refinements are considered
complete.

Use responsive layouts, touch-friendly controls, readable typography, stable
spacing, and scrollable content regions where needed. Forms, tables, lists,
dialogs, navigation, filters, and action toolbars must not overflow or require
desktop-only interactions. Prefer app-like mobile patterns over shrinking a
desktop dashboard.

Before reporting frontend work as complete, verify the relevant UI on at least a
mobile viewport and a desktop viewport.

## Loading UX

App templates should prefer skeleton states over full-screen spinners for
initial data loading, route transitions, and record edit screens. Loading UI
should preserve the real app shell and approximate the final layout so users see
where content will appear and the page does not jump when data arrives.

Never infer an error state from empty data alone. Before first data arrives,
`null`, `undefined`, or an empty client snapshot is a loading/empty-before-data
condition and should render a skeleton. Show an error state only from an explicit
failed request, exception, or validated not-found response.

Use route-aware skeletons for dashboards, tables, lists, charts, and forms. For
example, a dashboard should show skeleton summary cards and chart/list panels, a
table route should show skeleton rows, and an edit route should show a form-like
skeleton instead of a plain `Loading...` card.

Spinners should be reserved for narrow, local actions such as a saving button,
small inline pagination fetch, or short overlay tied to a specific user action.
Avoid stacking multiple animated loading indicators during auth, redirects, app
bootstrap, and dashboard data fetches.

## App Shell Structure

Every OS7 app template must use a consistent application shell:

- header with the app logo or mark, primary menu/navigation, and current user area
- main content area for the app's primary workflow
- footer for secondary status, metadata, or low-priority actions

This structure is mandatory for desktop and mobile layouts. On mobile, the menu
may collapse into a compact control, but the header, main area, and footer must
remain clear and usable.

## MCP Data Contract

Each app template should expose an application MCP interface for the data it
owns. The MCP surface should cover the maximum practical CRUD for user-facing
business data:

- create records
- read individual records
- update records
- delete records
- list records with limits
- search/filter records with limits
- retrieve summaries or narrow projections when full records are not needed

MCP tools should let the orchestrator add, remove, edit, search, and retrieve
app data without needing direct database access.

MCP tools must not dump large unbounded datasets into the LLM context. List and
search tools must have clear limits, pagination or cursors where useful, compact
default projections, and explicit filters. Prefer summaries, counts, IDs, and
narrow result sets over returning every row. Large exports should be handled as
files or background jobs, not as raw MCP responses.

MCP actions that change user-visible app state must notify the UI. This includes
create, update, delete, import, sync, background job completion, runtime mode
changes, and any tool that changes data the browser may currently display. The
MCP handler or shared feature service must publish the app's realtime event,
SSE/WebSocket notification, or focused cache invalidation signal after the
mutation commits successfully.

The UI should listen for these notifications and update focused client state or
refetch a narrow JSON snapshot. Do not require browser reloads, whole-route
refreshes, or periodic full-page polling for ordinary MCP-driven changes.

If an MCP tool and a UI/API action perform the same mutation, they must reuse the
same service-layer mutation path so audit logging, realtime notifications, and
validation cannot drift.
