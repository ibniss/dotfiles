## Global Operating Style

- Prefer the simplest solution that satisfies the request; call out tradeoffs briefly.
- If a request is too broad, propose smaller slices and ask which slice to do first.

## Code Quality Standards

- If a problem can be solved in a simpler way, propose it.
- If asked to do too much work at once, stop and state that clearly.
- Try not to compromise type safety.
  - TypeScript: no `any`, no non-null assertion operator (`!`), no unchecked type assertions.
  - Python: no `# type: ignore`, no `cast`.
- Make illegal states unrepresentable where practical (discriminated unions/ADTs, parse at boundaries).
- Keep abstractions intentionally narrow and documented.

## Testing

- Write tests that verify semantically correct behavior.
- Failing tests are acceptable when they expose genuine bugs and represent correct expected behavior.

## Git

- Use `gh` CLI if needed to check CI failures, read current PR context etc
- **Never** add yourself/AI to attribution or as a contributor PRs, commits, messages, or PR descriptions
- Commit: Keep the commit message a one sentence, few words. Use standard prefixes, e.g. `feat: implement XYZ`, `fix: duplicate messages on retry`.
- PRs: Look at prior PRs and PR template for formatting. For implementation details, avoid listing every line changed mechanically, focus on mentioning key changes made, difficult design decisions or notable parts.
