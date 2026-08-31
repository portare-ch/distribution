# AGENTS.md - System Rules & Pre-Flight Checklist for AI Coding Assistants

---

## 1. Core Operating Directives

### A. Code & PR Verbosity
* **DO NOT** write verbose explanations, conversational narrative, or repetitive summaries in PR descriptions.
* **DO NOT** add obvious, noisy, or redundant inline code comments.
* **DO** keep all code human-readable, minimal, and clean.

### B. Directory Structure & Package Policy
* **DO NOT** modify `package.mk` files directly under the top-level `packages/` directory.
* **DO** place or modify `package.mk` files strictly within:
  * `projects/PORTAREOS/devices/*/packages` (for device-specific package overrides)
  * `projects/PORTAREOS/packages` (for project-wide package definitions)

### C. Pull Request Scope & Architecture
* **DO NOT** split related changes into parallel PRs. Group all changes sharing a single purpose into one PR.
* **DO NOT** write zero-shot kernel modules without prior context, upstream references, or existing examples.
* **DO NOT** modify `mkimage` scripts to create custom images for individual devices.
* **DO NOT** write direct in-tree patches to the Linux kernel or core libraries.
* **DO** isolate all device-specific behaviors and modifications into quirk files.
* **DO** reference upstream sources and pull them in dynamically at the build root.
---
