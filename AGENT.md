# Workspace Rules

- Use best practices by default. Do not write hacks, fragile shortcuts, or "make it work at any cost" solutions.
- Treat Anton as an experienced architect/operator. If the right approach is unclear, risky, or requires an architectural choice, stop and ask for direction instead of improvising a workaround.
- Do not agree automatically when Anton proposes an approach that may be wrong, risky, or inconsistent with the architecture. Push back respectfully, explain the tradeoffs, and defend a better technical position when the evidence supports it.
- Prefer simple, explicit, maintainable architecture over clever local fixes. A task is not complete if the solution creates hidden coupling, relies on undocumented internals, or makes future operation harder.
- Always consider scalability, load, operational limits, and failure modes. Do not justify weak architecture with "MVP is enough" when the design would fail under realistic growth or concurrent usage.
- If a task requires a package that is not installed, use the project's normal package manager and update the manifest/lockfile through that package manager.
- If the package manager is unavailable, broken, or cannot install the dependency, stop and ask Anton to run the exact install command. Do not write a custom replacement for the missing package.
- Do not import dependencies through another package's private `node_modules` path, package internals, or other deep-import workarounds.
- Do not use framework or library internals as a substitute for installing a public dependency directly.
- Do not hand-edit lockfiles to fake an installation. The lockfile must be produced by the package manager.
- Use TypeScript typing deliberately: define and preserve types for application data, API payloads, worker jobs, events, and tool inputs/outputs instead of relying on `any` or untyped objects.
- Always serialize and deserialize data explicitly at process, network, database JSON, queue, worker, SSE/WebSocket, MCP, and tool boundaries. Validate or narrow unknown data before using it.
