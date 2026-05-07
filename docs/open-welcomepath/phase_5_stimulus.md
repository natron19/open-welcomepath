# Phase 5 — Stimulus Controllers: Form Submit and Character Counter

**Goal:** Two Stimulus controllers are in place. The generate form gives users clear feedback during the Gemini call (which can take 5–10 seconds). Character counters prevent users from exceeding field limits.

**Prerequisite:** Phase 4 complete. Views are in place and referencing the controller `data-` attributes.

**Spec reference:** `docs/open-welcomepath/welcomepath-demo-spec.md` section 12 (Bootstrap & UI Patterns).

**Required reading before writing any JS:** `docs/turbo-stimulus-patterns.md` — controller registration pattern, target binding rules.

---

## Tasks

### 5.1 — `app/javascript/controllers/form_submit_controller.js`

```javascript
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["button"]

  submit() {
    const btn = this.buttonTarget
    btn.disabled = true
    btn.innerHTML = `Generating… <span class="spinner-border spinner-border-sm" role="status" aria-hidden="true"></span>`
  }
}
```

**How it is wired in the view (already done in Phase 4):**
- `data-controller="form-submit"` on the `<form>` element
- `data-action="submit->form-submit#submit"` on the `<form>` element
- `data-form-submit-target="button"` on the submit `<input>` or `<button>`

### 5.2 — `app/javascript/controllers/character_count_controller.js`

```javascript
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "counter"]
  static values  = { max: Number }

  connect() {
    this.update()
  }

  update() {
    const current = this.inputTarget.value.length
    const max     = this.maxValue
    this.counterTarget.textContent = `${current} / ${max}`
    this.counterTarget.classList.toggle("text-danger", current >= max)
  }
}
```

**How it is wired in the view (already done in Phase 4):**
- `data-controller="character-count"` on the wrapper `<div>` around each textarea
- `data-character-count-max-value="1500"` (or `300`) on that same `<div>`
- `data-character-count-target="input"` on the `<textarea>`
- `data-action="input->character-count#update"` on the `<textarea>`
- `data-character-count-target="counter"` on the `<small>` element below the textarea

### 5.3 — Register controllers

In `app/javascript/controllers/index.js`, verify both new controllers are registered using the importmap eager-loading pattern (same as the boilerplate's existing controllers):

```javascript
import FormSubmitController from "./form_submit_controller"
application.register("form-submit", FormSubmitController)

import CharacterCountController from "./character_count_controller"
application.register("character-count", CharacterCountController)
```

If the file uses `eagerLoadControllersFrom` or a glob import, the controllers will be auto-registered by file name — verify the naming convention matches (`form_submit_controller.js` → `form-submit`, `character_count_controller.js` → `character-count`).

---

## RSpec

No new specs for Stimulus controllers — they are not testable in request specs. The form interaction is covered by the Phase 9 manual checks. Confirm the boilerplate suite still passes:

```
bundle exec rspec
```

---

## Manual Checks

After `bin/dev`:

- [ ] Navigate to `/paths/new` — both character counter `<small>` elements show `0 / 1500` and `0 / 300` on page load
- [ ] Type in the `member_background` textarea — counter updates in real time; the counter text turns red at exactly 1500 characters
- [ ] Type in the `integration_goal` textarea — counter updates, turns red at 300 characters
- [ ] Submit the form with invalid data (empty fields) — button does NOT disable (form does not submit because browser validation or server returns 422)
- [ ] Submit the form with valid data (Phase 6 AI not yet wired — expect 500/NotImplementedError in dev) — button changes to "Generating…" with spinner before the response returns
- [ ] Hard-refresh the page and repeat the counter check (Turbo navigation must not break re-connection)
- [ ] Check browser console for JavaScript errors — there should be none
