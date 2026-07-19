import { defineConfig } from "oxlint";

export default defineConfig({
  categories: {
    correctness: "error",
  },
  env: {
    builtin: true,
    es2022: true,
    node: true,
  },
  jsPlugins: ["@raycast/eslint-plugin"],
  rules: {
    "@raycast/prefer-ellipsis": "warn",
    "@raycast/prefer-title-case": "warn",
    "@raycast/prefer-common-shortcut": "warn",
    "@raycast/no-reserved-shortcut": "warn",
    "@raycast/no-ambiguous-platform-shortcut": "warn",
  },
});
