module.exports = {
  parserOptions: {
    ecmaVersion: 8,
    sourceType: 'module',
    ecmaFeatures: {
      jsx: true,
      experimentalObjectRestSpread: true,
    }
  },
  rules: {
    'comma-dangle': ['error', 'always'],
    'semi': ['error', 'never'],
  },
}
