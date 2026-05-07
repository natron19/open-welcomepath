# Phase 11 — Security Review and Publish Prep

**Goal:** The app passes a complete pre-publish security audit before the repo is made public on GitHub. Every item from `docs/prompts/pre-publish-security-check.md` is resolved.

**Prerequisite:** All prior phases complete. `bundle exec rspec` passes with 0 failures.

---

## Tasks

### 11.1 — Run the pre-publish security check

Execute the full security prompt from `docs/prompts/pre-publish-security-check.md`.

That prompt checks:
1. Hardcoded secrets in any file
2. `.gitignore` coverage for `.env`, `*.key`, `config/master.key`, `log/`, `tmp/`
3. `.env.example` — all values are placeholders, no real values
4. `config/database.yml` — no hardcoded credentials; production uses `ENV.fetch`
5. `db/seeds.rb` — no credentials beyond documented demo passwords
6. `config/environments/production.rb` — all sensitive values use `ENV.fetch`
7. `Gemfile` — only source is `https://rubygems.org`
8. `README.md` — no internal infrastructure, real emails, or server names
9. `log/` and `tmp/` — no tracked files with sensitive content
10. `git log` — no commit messages suggesting a secret was ever committed

Fix every flagged item before proceeding.

### 11.2 — Final end-to-end smoke test

Run this full sequence manually before tagging the release:

- [ ] `bin/setup` from a clean checkout (no prior DB) completes without errors
- [ ] `rails db:seed` completes and creates the demo user, AI template, and sample path
- [ ] Sign in as `demo@example.com` / `password123` — dashboard shows recent paths, tip card renders
- [ ] Create a new path with a valid `GEMINI_API_KEY` — full flow from form to show page
- [ ] Show page: SVG root map renders, all 4 weekly panels have activities, raw response toggle works
- [ ] Edit path name and integration goal — saves and returns to show with updated values
- [ ] Clone path — copy appears with all activities, name has " (copy)"
- [ ] Print path — no navbar, no footer, print dialog opens
- [ ] Delete path — cascade removes activities, redirects to index
- [ ] Sign out — all `/paths` routes redirect to sign in
- [ ] Sign in as a second user — cannot see or access first user's paths (returns 404)
- [ ] `/admin/ai_templates` — `welcomepath_path_v1` is present and testable in the admin panel
- [ ] `bundle exec rspec` — full suite passes, 0 failures

### 11.3 — Code hygiene

Scan for any of the following before making the repo public:

- [ ] No `binding.pry`, `byebug`, or `debugger` calls in committed code
- [ ] No `console.log` left in JavaScript files
- [ ] No hardcoded app name / tagline / description (every occurrence uses `ENV.fetch`)
- [ ] No hardcoded Gemini model strings outside of seeds and specs (all calls go through `GeminiService`)
- [ ] No `TODO:` or `FIXME:` comments left in code that should be resolved before publishing
- [ ] No `raise NotImplementedError` stubs remaining from Phase 3 (the create action is fully wired)

### 11.4 — Git history review

```bash
git log --oneline
```

- [ ] No commit message suggests a secret was committed (e.g., "add API key", "fix credentials", "hardcode key for testing")
- [ ] No `.env` file appears in `git show` for any commit: `git log --all -- .env`
- [ ] `config/master.key` was never committed: `git log --all -- config/master.key`

If any of the above returns results, the history must be scrubbed (with `git filter-repo` or BFG) **before** making the repo public. Flag these for manual resolution.

### 11.5 — `.gitignore` final audit

Verify these are present in `.gitignore`:

```
.env
*.env.local
config/master.key
*.key
log/
tmp/
.DS_Store
```

And `.env.example` is **not** in `.gitignore`.

---

## RSpec

Run the full suite one final time:

```bash
bundle exec rspec --format documentation
```

- [ ] 0 failures
- [ ] 0 pending examples
- [ ] Output confirms no real Gemini API calls (all GeminiService calls stubbed)

---

## Manual Checks

These are the publish-gate checks. The repo must not be made public until all boxes are checked:

- [ ] Pre-publish security check (`docs/prompts/pre-publish-security-check.md`) completed — all flagged items resolved
- [ ] No hardcoded secrets in any committed file
- [ ] `.gitignore` covers all sensitive files
- [ ] `.env.example` has zero real values
- [ ] Git history clean — no commits that suggest a secret was ever committed
- [ ] Full RSpec suite passes with 0 failures
- [ ] Full end-to-end smoke test passes (11.2 checklist above)
- [ ] Code hygiene scan clean (11.3 checklist above)
- [ ] README is complete and accurate for a first-time visitor
