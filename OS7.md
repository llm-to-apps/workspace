# OS7 Platform Spec

## Goal

OS7 is a platform where a user can deploy an application template into their own isolated live instance, open it at a subdomain like `xyz.os7.dev`, and then edit the application's source code in real time through an LLM chat.

The core idea:

```text
User prompt
  -> Platform orchestrator
  -> LLM agent loop
  -> tools inside user's container
  -> source files changed
  -> app hot reloads / restarts
  -> user sees result immediately
```

Each user application is isolated. The platform itself is not modified by user prompts.

## Product Flow

1. User registers.
2. User sees available application templates.
3. Templates are Git repositories, for example:
   - `template-money`
   - `template-crm`
   - `template-booking`
   - `template-inventory`
4. User clicks `Deploy`.
5. Platform creates a project.
6. Platform creates a private repository from the chosen template.
7. Platform creates a MySQL database and project-specific credentials.
8. Platform starts a user instance container/service.
9. Container clones the project repository.
10. Container writes runtime environment configuration.
11. Container installs dependencies, runs migrations, optionally seeds data.
12. Container starts the application.
13. Reverse proxy maps a subdomain to the running app:

```text
xyz.os7.dev -> project-123 service -> app port
```

14. User opens the app.
15. User writes in chat what to change.
16. Platform orchestrator runs an LLM loop.
17. LLM calls tools exposed by the user instance.
18. Source code changes.
19. App updates in real time through HMR or process restart.
20. Successful changes are committed and pushed.

## Main Architecture

```text
OS7 Platform
  - auth
  - billing
  - templates catalog
  - projects
  - orchestration API
  - LLM loop
  - RAG/context engine
  - audit log
  - git provider integration
  - database provisioning

Docker Swarm Cluster
  - manager nodes
  - worker nodes
  - Traefik reverse proxy
  - os7-manager service
  - user app services

User App Service
  - app source code
  - git workspace
  - app runtime
  - agent tool server
  - logs
  - health endpoint
```

## Docker Swarm Model

Use Docker Swarm as the runtime scheduler.

The platform deploys a privileged internal service:

```text
os7-manager
```

This service runs on a Swarm manager node and has access to Docker Engine API through:

```text
/var/run/docker.sock
```

The manager service creates and manages other Swarm services:

```text
project-123
project-456
project-789
```

Each project is usually one Swarm service with one replica:

```text
service: project-123
replicas: 1
image: os7/user-instance:latest
```

For live editing, keep `replicas = 1`, because the workspace is mutable and the agent edits local source files.

Later, published immutable versions can be scaled horizontally:

```text
live editable instance: mutable workspace, replicas = 1
published app: immutable image, replicas = N
```

## Platform Manager Service

The `os7-manager` service is the control plane inside the Swarm cluster.

Responsibilities:

- Create user services.
- Stop user services.
- Restart user services.
- Remove user services.
- Set environment variables.
- Set resource limits.
- Attach networks.
- Add Traefik routing labels.
- Inspect service state.
- Read service/container health.
- Coordinate deploy/bootstrap lifecycle.

Example Swarm placement:

```yaml
services:
  os7-manager:
    image: os7/manager:latest
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
    environment:
      PLATFORM_DOMAIN: os7.dev
      MYSQL_ADMIN_URL: mysql://...
      GIT_PROVIDER_TOKEN: ...
    networks:
      - public
      - internal
    deploy:
      placement:
        constraints:
          - node.role == manager
```

Security note:

```text
os7-manager + /var/run/docker.sock = root-level control over the cluster
```

Therefore:

- Do not expose manager API publicly without strong auth.
- Do not mount Docker socket into user containers.
- Do not expose Docker API to LLM tools.
- Only the platform manager can create/update/delete services.

## User Instance Service

Each user app runs as a Swarm service.

Example service inputs:

```text
PROJECT_ID=project-123
REPO_URL=git@github.com:org/project-123.git
DATABASE_URL=mysql://project_123_user:password@mysql-host:3306/project_123
APP_DOMAIN=xyz.os7.dev
APP_PORT=3001
AGENT_PORT=7001
START_COMMAND=npm run dev
MIGRATE_COMMAND=npm run db:deploy
SEED_COMMAND=npm run db:seed
```

The container image should be generic:

```text
os7/user-instance:latest
```

It should not contain a specific user's source code. Source code is cloned during bootstrap.

Inside the container:

```text
/workspace/app
  .git/
  package.json
  app/
  components/
  lib/
  prisma/

/agent
  bootstrap.js
  tool-server.js
```

Processes:

```text
app process
  - Next.js dev server or app server

agent tool server
  - exposes filesystem/shell/git/log tools

process supervisor
  - keeps both processes alive
```

Recommended inside-container process supervision:

- `supervisord`
- `s6-overlay`
- `pm2`
- custom Node supervisor with `tini`

## Bootstrap Flow

The container startup command should be a bootstrap script:

```bash
node /agent/bootstrap.js
```

Bootstrap does:

```text
1. Validate required env vars.
2. Clone REPO_URL into /workspace/app.
3. Write runtime env file for the app.
4. Install dependencies.
5. Generate ORM client if needed.
6. Run database migrations.
7. Optionally seed default data.
8. Start app process.
9. Start agent tool server.
10. Expose health endpoint.
```

Example startup contract:

```text
START_COMMAND=npm run dev
MIGRATE_COMMAND=npm run db:deploy
SEED_COMMAND=npm run db:seed
HEALTH_URL=http://localhost:7001/health
```

## Reverse Proxy

Use Traefik with Docker Swarm provider.

Traefik watches Swarm services and reads labels.

For each user service, manager sets labels like:

```text
traefik.enable=true
traefik.http.routers.project-123.rule=Host(`xyz.os7.dev`)
traefik.http.routers.project-123.entrypoints=websecure
traefik.http.routers.project-123.tls.certresolver=letsencrypt
traefik.http.services.project-123.loadbalancer.server.port=3001
```

The agent tool server should not be publicly exposed. It should be reachable only from the platform/internal network.

```text
public:
  xyz.os7.dev -> app port

internal:
  orchestrator/manager -> agent tool server port
```

## Docker Restart and Health

Swarm should restart user services automatically.

For normal Docker containers, use:

```text
RestartPolicy: unless-stopped
```

For Swarm services, use:

```text
RestartPolicy:
  Condition: any
```

Recommended health layers:

```text
1. Docker/Swarm restart policy
2. Supervisor inside container
3. Platform health monitor
```

Health endpoints:

```text
GET /health          -> app health
GET /agent/health    -> agent tool server health
```

If service becomes unhealthy:

```text
1. manager restarts service
2. if restart loop continues, project status becomes degraded
3. user sees recovery/error state
4. orchestrator can ask LLM to inspect logs and repair
```

## Git Model

Each deployed project has a private repository.

Do not use container filesystem as source of truth.

Source of truth:

```text
Git repo + project metadata + database
```

The container workspace is disposable and can be recreated.

Recommended deploy flow:

```text
template repo
  -> create private repo from template
  -> clone repo into user container
```

After each successful user change:

```bash
git add .
git commit -m "User requested: add monthly expenses chart"
git push
```

Benefits:

- rollback
- history
- diff
- audit
- export code
- recreate instance

## MySQL Provisioning

For each project, create isolated database credentials.

Example:

```text
database: project_123
user: project_123_user
password: generated secret
```

Runtime env:

```text
DATABASE_URL=mysql://project_123_user:password@mysql-host:3306/project_123
```

The user app should use production-like MySQL locally inside the platform. For project templates using Prisma:

```bash
npm run db:deploy
npm run db:seed
```

The platform manager needs admin-level DB permissions to create databases/users, but user app services get only their own project credentials.

## Agent Architecture

Use the platform orchestrator as the LLM brain.

The user container exposes tools only.

```text
Orchestrator
  - owns chat session
  - calls LLM
  - performs RAG/context retrieval
  - decides tool calls
  - stores audit log
  - controls billing/limits

Container Agent Tool Server
  - read_file
  - list_files
  - search_text
  - apply_patch
  - run_command
  - read_logs
  - git_diff
  - git_commit
  - rollback
  - restart_app
  - health
```

This is preferable to putting the whole LLM loop inside the container because:

- LLM API keys stay in the platform.
- Model routing is centralized.
- Billing and rate limits are centralized.
- RAG is centralized.
- Audit logs are centralized.
- User containers do not need direct access to LLM providers.
- It is easier to enforce policy.

Aider can be used for MVP as a subprocess, but the production direction should be:

```text
custom tool server inside container
LLM orchestration outside container
```

## Agent Tool Server API

The internal tool server can be HTTP, WebSocket, gRPC, or MCP.

MCP is a good fit because the service is literally exposing tools.

Minimum tool set:

```text
GET  /health
GET  /files/tree
POST /tools/read-file
POST /tools/search-text
POST /tools/apply-patch
POST /tools/run-command
GET  /tools/logs
GET  /tools/git-diff
POST /tools/git-commit
POST /tools/rollback
POST /tools/restart-app
```

Tool safety:

- Restrict file access to `/workspace/app`.
- Block `.env`, private keys, tokens, and platform secrets.
- Mask secrets in logs.
- Allow only safe commands or use command allowlist.
- Apply CPU/memory/time limits.
- Record every tool call.

Example command allowlist:

```text
npm install
npm run dev
npm run build
npm run typecheck
npm test
npx prisma generate
npm run db:deploy
npm run db:seed
git status
git diff
git add
git commit
git push
```

## Live Editing Loop

When user sends:

```text
Add a monthly expenses chart
```

Flow:

```text
1. User message saved.
2. Orchestrator retrieves project context.
3. Orchestrator calls LLM.
4. LLM requests tools.
5. Orchestrator calls container tool server.
6. Tool server reads files/searches code.
7. LLM creates patch.
8. Tool server applies patch.
9. Next.js HMR updates the app.
10. Orchestrator streams progress to UI.
11. Tool server runs typecheck/build.
12. If errors occur, LLM reads logs and repairs.
13. On success, tool server commits and pushes.
14. Project version is recorded.
```

The user sees changes on:

```text
https://xyz.os7.dev
```

## RAG and Context

RAG should live in the platform, not inside each user container.

The container provides ground-truth tools:

```text
read_file
search_text
list_files
git_diff
logs
```

The orchestrator provides retrieval:

```text
repo index
symbol index
docs index
chat history
previous prompts
previous diffs
runtime logs
```

Recommended indexed data:

```text
file path
file chunks
symbols/classes/functions
imports/exports
README/docs
package.json/scripts
Prisma schema/migrations
previous commits/diffs
user prompt history
```

Recommended storage:

```text
Postgres + pgvector
```

or:

```text
Qdrant / Weaviate / Milvus
```

MVP can start without vector RAG:

```text
list_files
rg/search_text
read_file
git_diff
terminal logs
browser errors
```

Then add incremental indexing:

```text
1. Patch applied.
2. Changed files are known.
3. Re-index changed files only.
4. Store index version by git commit SHA.
```

RAG does not replace tools. RAG helps choose what to inspect; tools provide current truth.

## Platform Database Entities

Suggested metadata schema:

```text
User
Template
Project
ProjectRepo
ProjectDatabase
ProjectInstance
ProjectSecret
ProjectVersion
AgentSession
AgentMessage
AgentToolCall
DeploymentEvent
```

Important fields:

```text
Project:
  id
  userId
  templateId
  name
  subdomain
  repoUrl
  status
  createdAt

ProjectInstance:
  id
  projectId
  swarmServiceName
  image
  internalHost
  appPort
  agentPort
  status
  lastHealthcheckAt

ProjectDatabase:
  projectId
  databaseName
  databaseUser
  secretRef

ProjectVersion:
  projectId
  gitCommitSha
  prompt
  status
  createdAt

AgentToolCall:
  sessionId
  toolName
  input
  output
  status
  durationMs
  createdAt
```

## Template Contract

Every app template should include:

```text
package.json
Docker/runtime compatibility
.env.example
health endpoint
README_DEPLOY.md
database migration command
start command
typecheck/build command
```

Example template metadata:

```json
{
  "id": "money",
  "name": "Personal Finance",
  "repo": "git@github.com:os7/template-money.git",
  "defaultBranch": "main",
  "runtime": "node",
  "appPort": 3001,
  "startCommand": "npm run dev",
  "buildCommand": "npm run build",
  "typecheckCommand": "npm run typecheck",
  "migrateCommand": "npm run db:deploy",
  "seedCommand": "npm run db:seed"
}
```

## Deployment API Shape

The platform should expose something like:

```text
POST /api/projects/deploy
```

Input:

```json
{
  "templateId": "money",
  "subdomain": "xyz"
}
```

Internal orchestration:

```text
1. validate user/subdomain/template
2. create project row
3. create private repo from template
4. create MySQL database and user
5. create secrets
6. create Swarm service
7. wait for healthcheck
8. mark live
```

Returned response:

```json
{
  "projectId": "project-123",
  "url": "https://xyz.os7.dev",
  "status": "deploying"
}
```

## Swarm Service Creation

Using Docker Engine API through Node.js, likely with `dockerode`.

The manager creates a Swarm service, not a raw container.

Conceptual service spec:

```ts
await docker.createService({
  Name: `project-${projectId}`,
  TaskTemplate: {
    ContainerSpec: {
      Image: 'os7/user-instance:latest',
      Env: [
        `PROJECT_ID=${projectId}`,
        `REPO_URL=${repoUrl}`,
        `DATABASE_URL=${databaseUrl}`,
        `APP_DOMAIN=${domain}`,
        'APP_PORT=3001',
        'AGENT_PORT=7001',
        'START_COMMAND=npm run dev',
        'MIGRATE_COMMAND=npm run db:deploy',
        'SEED_COMMAND=npm run db:seed'
      ],
      Command: ['node', '/agent/bootstrap.js'],
      Labels: {
        'traefik.enable': 'true',
        [`traefik.http.routers.${projectId}.rule`]: `Host(\`${domain}\`)`,
        [`traefik.http.services.${projectId}.loadbalancer.server.port`]: '3001'
      }
    },
    RestartPolicy: {
      Condition: 'any'
    },
    Resources: {
      Limits: {
        MemoryBytes: 1024 * 1024 * 1024
      }
    }
  },
  Mode: {
    Replicated: {
      Replicas: 1
    }
  },
  Networks: [
    { Target: publicNetworkId },
    { Target: internalNetworkId }
  ]
});
```

## Secrets

Keep secrets out of LLM context.

Runtime needs:

```text
DATABASE_URL
GIT_TOKEN or deploy key
LLAGENTS_INTERNAL_TOKEN
```

LLM should not read:

```text
.env
SSH keys
Git tokens
DB passwords
platform tokens
```

Preferred model:

```text
runtime has secrets
tool server exposes capabilities
LLM gets masked outputs only
```

For Git:

- Use project-specific deploy keys when possible.
- Avoid broad organization tokens inside user containers.
- If a token is required, scope it to one repo.

## Existing Open Source References

Useful projects to study:

- Vercel Open Agents: cloud coding agent architecture with sandbox tools.
- Agent Infra AIO Sandbox: container with browser/shell/filesystem/MCP tools.
- Agent-Sandbox: Kubernetes-native AI agent sandbox runtime.
- Handler.dev: control plane for coding agents in isolated sandboxes.
- OpenHands: autonomous coding agent platform.
- Aider: CLI coding agent, useful for MVP/subprocess experiments.
- Continue.dev: codebase indexing and context ideas.
- ogrep: semantic code search for agents with local index and MCP.

Possible infrastructure alternatives:

- Docker Engine API + Traefik: most direct control.
- CapRover: PaaS on Docker Swarm.
- Coolify: self-hosted PaaS with Git deploy/env/domains.
- Dokku: simpler Heroku-like deployment.

Recommended path for OS7:

```text
MVP:
  Docker Swarm
  Traefik
  custom os7-manager
  custom user-instance image
  custom agent tool server
  MySQL
  Git provider

Later:
  richer RAG
  immutable published builds
  horizontal scaling for published apps
  Kubernetes if Swarm becomes limiting
```

## MVP Milestones

### Milestone 1: Single-server prototype

- Docker Engine API without Swarm.
- Traefik routing by Docker labels.
- One user instance container per project.
- Manual template repo.
- MySQL database creation.
- Agent tool server with read/apply_patch/run/logs.
- Basic chat-to-code loop.

### Milestone 2: Swarm mode

- Initialize Docker Swarm.
- Deploy Traefik as Swarm service.
- Deploy `os7-manager` as Swarm service.
- Create user apps as Swarm services.
- Add service health monitoring.
- Add restart/recreate lifecycle.

### Milestone 3: Git/versioning

- Create private repo from template.
- Clone on bootstrap.
- Commit after successful agent task.
- Push changes.
- Show diffs in UI.
- Implement rollback to previous commit.

### Milestone 4: RAG/context

- Add repo indexing.
- Add symbol/chunk search.
- Add prompt/diff memory.
- Re-index changed files after commits.

### Milestone 5: Production hardening

- Resource limits.
- Network isolation.
- Secret masking.
- Command allowlist.
- Audit logs.
- Billing limits.
- Abuse controls.
- Backups.
- Project export.
