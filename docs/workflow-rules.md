# Workflow rules — SreerajP_TextApp

Read this file before starting or finishing any change to the project. These rules are
part of the project rules in [../CLAUDE.md](../CLAUDE.md) and apply to every change.

## 1. Plan before changing

For any change to the project, **first write a full plan** to the `plans/` folder at the
project root. Name it `yyyymmdd_hhMMss_<short-slug>.md` (date+time prefix, local time). The
plan must include:
- the list of files to be changed,
- what the issue is,
- the plan for the fix,
- a `**Status:**` line right under the title.

**Status values:** `draft`, `approval_pending`, `in_progress`, `completed`, `dropped`,
`partial_completion`. Normal lifecycle: `draft` → `approval_pending` → `in_progress` →
`completed`. Keep the `Status:` line current at all times.

**Approval gate (must get explicit consent before implementing):**
- After writing the plan, **STOP**. Do not edit, create, or delete any project file (other
  than the plan file itself) until the user approves.
- Present the plan and explicitly ask the user to approve it. **Wait** for the reply.
- Proceed **only** on an explicit "yes / approved / go ahead". Silence, a question, or an
  ambiguous reply is **not** approval — ask again.
- If the plan changes after feedback, re-present it and get approval again.
- The only exception is if the user explicitly says to skip the plan/approval for a specific
  change. A general earlier "go ahead" does not carry over to later changes.

## 2. Log after changing

After implementing a plan, **write a change log** to the `change_log/` folder at the project
root. Name it `yyyymmdd_hhMMss_<short-slug>.md` (date+time prefix, local time), describing
what was changed and referencing the plan it implements.

Create the `plans/` and `change_log/` folders if they do not exist.
