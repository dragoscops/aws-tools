// eslint.config.js
import templEslintConfig from '@templ-project/eslint';

export default [
  {
    // Use broader patterns (no leading ./) so editor + CLI both respect them.
    // Add common build output folders as well.
    ignores: ['**/node_modules/**', '**/dist/**', '**/build/**'],
  },
  ...templEslintConfig,
];
