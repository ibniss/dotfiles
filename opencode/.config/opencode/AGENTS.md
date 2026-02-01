
## Code Quality Standards

- Make minimal, surgical changes
- Strive for concise, simple solutions
- If a problem can be solved in a simpler way, propose it
- If asked to do too much work at once, stop and state that clearly
- Never compromise type safety if possible: in Typescript: No `any`, no non-null assertion operator (`!`), no type assertions (`as Type`). In Python: no `# type: ignore`, no `cast`.
- Make illegal states unrepresentable: Model domain with ADTs/discriminated unions; parse inputs at boundaries into typed structures; if state can't exist, code can't mishandle it
- Abstractions: Consciously constrained, pragmatically parameterised, doggedly documented

### **ENTROPY REMINDER**
This codebase will outlive you. Every shortcut you take becomes someone else's burden. Every hack compounds into technical debt that slows the whole team down.

You are not just writing code. You are shaping the future of this project. The patterns you establish will be copied. The corners you cut will be cut again.

**Fight entropy. Leave the codebase better than you found it.**

## Testing

- Write tests that verify semantically correct behavior
- **Failing tests are acceptable** when they expose genuine bugs and test correct behavior

## Plans

- Make the plan extremely concise. Sacrifice grammar for the sake of concision.
- At the end of each plan, give me a list of unresolved questions to answer, if any.
