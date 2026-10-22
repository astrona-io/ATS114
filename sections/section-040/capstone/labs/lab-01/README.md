---
estimated_duration: 45m
---

# Rotate Everything After A Leak

- **Slug:** ats-114-capstone-040
- **Author:** Paris Nakita Kejser
- **Type:** Astrona graded lab

Read `question.md` for the task; `solution.md` is the walkthrough.

## Run it

```sh
astrona run -c .
astrona submit
astrona destroy ats-114-capstone-040
```

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Environment definition, bootstrap and grading |
| `question.md` | The task |
| `solution.md` | Step-by-step walkthrough |
| `prerequisites.md` | Assumed knowledge and what the environment provides |
| `bootstrap/` | Environment preparation and the starting state |
| `manifests/` | Helm values, the tester pod and PostgreSQL |
| `solution/` | Reference solution used by `astrona test` |
| `testing/` | Helpers `astrona test` runs first |
| `validation/` | Grading scripts, one per check |
