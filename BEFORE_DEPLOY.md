# Before Deploy

Production is not ready yet. This checklist captures the issues found during the pre-deploy pass.

## P0 - Blockers

- [ ] Replace `prisma db push` with production migrations.

  `web/Dockerfile` starts with `npm run prisma:push && npm run seed && npm run start`. For production, use committed Prisma migrations and `prisma migrate deploy`.

  Needed:
  - create migrations for the current `web/prisma/schema.prisma`,
  - update the web image start command,
  - document the migration step for deploy/update.

- [ ] Fix `web` image seeding.

  `web/prisma/seed.ts` reads template manifests from `../../templates/money/manifest*.json`, but the runtime image only copies `web/prisma`. The container will not have `templates/money`.

  Pick one:
  - copy required manifests into the web image, or
  - embed template data in `web/prisma/seed.ts`, or
  - move manifests into a package/path owned by `web`.

- [ ] Verify required production env is complete.

  Current target values:
  - `PLATFORM_BASE_URL=https://os7.dev`
  - `PLATFORM_DOMAIN=os7.dev`
  - `PROJECT_PUBLIC_SCHEME=https`
  - `OAUTH_INTERNAL_BASE_URL=http://web:3000`

  Also verify `AUTH_SECRET`, `FORGEJO_ADMIN_PASSWORD`, `FORGEJO_SECRET_KEY`, `FORGEJO_INTERNAL_TOKEN`, `POSTGRES_PASSWORD`, `MYSQL_ROOT_PASSWORD`, `OPENROUTER_API_KEY`.

- [ ] Verify production Swarm routing.

  `make up` deploys the platform as a Docker Swarm stack, so Traefik should discover `web` through the Swarm provider. Before public traffic, verify:
  - `docker stack services os7` shows `os7_web`,
  - Traefik has a router for `Host(os7.dev)`,
  - `https://os7.dev` reaches the web service,
  - user app services created by manager are attached to the same ingress network.

## P1 - Product/Safety

- [ ] Implement real production login.

  Email verification currently returns `501` in production because email code delivery is not configured. Either add an email provider/code delivery or choose another production auth mechanism.

- [ ] Add billing guardrails before paid/public usage.

  Credits are debited into `billing_accounts.creditBalance`, but there is no purchase/top-up flow and no block when balance is insufficient. Decide MVP policy:
  - allow negative balances intentionally, or
  - require positive balance before agent/s2s calls.

- [ ] Make deploy/update versioning consistent.

  `deploy/update.sh` updates only `MANAGER_IMAGE_TAG`, but production uses separate `MANAGER_IMAGE_TAG`, `WEB_IMAGE_TAG`, and `AGENT_IMAGE_TAG`. Update all deployable images together or pin one release version across services.

- [ ] Add health checks and smoke test script.

  Minimum smoke test:
  - open `https://os7.dev`,
  - sign in,
  - deploy Money,
  - wait until project is ready,
  - open project page by slug,
  - verify iframe OAuth,
  - run main agent -> project subagent,
  - verify project chat realtime event update,
  - verify S2S handshake,
  - delete project and confirm service/database cleanup.

## P2 - Cleanup

- [ ] Reduce production OAuth/debug logs.

  Web and Money still log iframe OAuth flow details. Move verbose logs behind a flag such as `DEBUG_OAUTH=true`.

- [ ] Confirm Traefik/Cloudflare TLS assumptions.

  Docs say Cloudflare terminates TLS and Traefik exposes HTTP only. Verify headers, cookies, and redirects behave correctly with `PLATFORM_BASE_URL=https://os7.dev`.

- [ ] Verify project image strategy.

  `money-dev` uses `os7-money:dev`, which is local-only. Production templates should point to registry images, not local image tags.

- [ ] Decide whether `Money (dev)` should exist in production seed.

  If `money-dev` is for local testing only, exclude it from production seed or mark it unavailable in production.

## Recently Fixed

- [x] Replace `OS7_BASE_URL` with `PLATFORM_BASE_URL`.

  `PLATFORM_BASE_URL` is now the public platform URL. `OAUTH_ISSUER_URL` is no longer required in `web`; Money still receives `OAUTH_ISSUER_URL` as app env rendered from the platform issuer.

- [x] Make `deploy/make up` deploy a Swarm stack.

  Production now uses `docker stack deploy` via `make up`, so `web`, `manager`, `worker`, `agent`, databases, Redis, Forgejo, Traefik, and user apps are all Swarm services.

- [x] Split production deploy into stack components.

  Production stack config now lives in `deploy/stack/*.yml` instead of one giant YAML file.

- [x] Split production env into components.

  Production env examples now live in `deploy/env/*.env.example`; `make ensure-env` creates matching local `deploy/env/*.env` files. Image names and tags are kept together in `deploy/env/release.env`.
