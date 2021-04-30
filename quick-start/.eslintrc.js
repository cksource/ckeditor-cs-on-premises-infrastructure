module.exports = {
   env: {
      es6: true,
      node: true,
   },
   parserOptions: {
      ecmaVersion: 8
   },
   extends: "eslint:recommended",
   rules: {
      indent: [ 'error', 3 ],
      'no-mixed-spaces-and-tabs': [ 'error', 'smart-tabs' ],
      'array-bracket-spacing': [ 'error', 'always' ],
      'object-curly-spacing': [ 'error', 'always' ],
      'computed-property-spacing': [ 'error', 'always' ],
      'template-curly-spacing': [ 'error', 'always' ],
      'linebreak-style': [ 'off' ],
      'space-in-parens': [ 'error', 'always' ],
      'func-style': [ 'off' ],
      'semi': [ 'error', 'always' ]
   },
};