## Code Quality Standards

- If a problem can be solved in a simpler way, propose it
- If asked to do too much work at once, stop and state that clearly
- Try to not compromise type safety if possible: in Typescript: No `any`, no non-null assertion operator (`!`), no type assertions (`as Type`). In Python: no `# type: ignore`, no `cast`.
- Make illegal states unrepresentable: Model domain with ADTs/discriminated unions; parse inputs at boundaries into typed structures; if state can't exist, code can't mishandle it
- Abstractions: Consciously constrained, pragmatically parameterised, doggedly documented

## Testing

- Write tests that verify semantically correct behavior
- **Failing tests are acceptable** when they expose genuine bugs and test correct behavior

## Plans

- Make the plan extremely concise. Sacrifice grammar for the sake of concision.
- At the end of each plan, give me a list of unresolved questions to answer, if any.

## Git

- Use `gh` CLI if needed to check CI failures, read current PR context etc
- **Never** add yourself/AI to attribution or as a contributor PRs, commits, messages, or PR descriptions
- Commit: Keep the commit message a one sentence, few words. Use standard prefixes, e.g. `feat: implement XYZ`, `fix: duplicate messages on retry`.
- PRs: Look at prior PRs and PR template for formatting. For implementation details, avoid listing every line changed mechanically, focus on mentioning key changes made, difficult design decisions or notable parts.
