## Debugging

- When debugging, don't guess and after tracing through the code if the issue isn't clear, bias towards instrumenting/logging around the issue especially if it's a quick to reproduce.

## Planning

- When planning features, prefer vertical slices that can be tested end-to-end and iterated on, rather than broad horizontal ones that require long phases before functionality can be verified.

## Design

- Make illegal states unrepresentable where practical (discriminated unions/ADTs etc). Model data using the most precise data structure you reasonably can. If ruling out a particular possibility is too hard using the encoding you are currently using, consider alternate encodings that can express the property you care about more easily. Don’t be afraid to refactor.
- Parse, don't validate. Push the burden of proof upward as far as possible, but no further. Get your data into the most precise representation you need as quickly as you can. Ideally, this should happen at the boundary of your system, before any of the data is acted upon. If one particular code branch eventually requires a more precise representation of a piece of data, parse the data into the more precise representation as soon as the branch is selected. Use sum types judiciously to allow your datatypes to reflect and adapt to control flow. 
- Write functions on the data representation you wish you had, not the data representation you are given. 
- Don’t be afraid to parse data in multiple passes. Avoiding shotgun parsing just means you shouldn’t act on the input data before it’s fully parsed, not that you can’t use some of the input data to decide how to parse other input data.
- Prefer deep modules with narrow interfaces over many shallow layers of abstractions. Avoid shallow pass-through one-liner wrappers.
- No backward compatibility by default. No shims, no legacy fallbacks, no dual-path support. Only add compat when explicitly requested.

## Worktree Setup

- At the start of work in a Git repository, run `codex-sync-mise-local` once before substantial work if it is available on `PATH`.

## Git

- Use `gh` CLI if needed to check CI failures, read current PR context etc
- **Never** add yourself/AI to attribution or as a contributor PRs, commits, messages, or PR descriptions
- Commit: Keep the commit message a one sentence, few words. Use standard prefixes, e.g. `feat: implement XYZ`, `fix: duplicate messages on retry`.
- PRs: Look at prior PRs and PR template for formatting. For implementation details, avoid listing every line changed mechanically, focus on mentioning key changes made, difficult design decisions or notable parts.
