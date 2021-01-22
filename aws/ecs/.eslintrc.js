module.exports = {
	extends: '@cksource-cs/eslint-config-cs-module/typescript',
	parserOptions: {
		project: "tsconfig.json",
		tsconfigRootDir: __dirname,
		sourceType: "module",
	  },
};
