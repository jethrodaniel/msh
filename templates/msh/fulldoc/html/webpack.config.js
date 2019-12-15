// see https://webpack.js.org/configuration/

const path = require('path');

module.exports = {
  // mode: "production",
  mode: "development",
  devtool: "source-map",
  output: {
    filename: 'bundle.js'
  },
  module: {
    rules: [
      {
        test: /\.(s*)css$/,
        use: ['style-loader','css-loader', 'sass-loader']
      },
      {
        test: /\.svg$/,
        use: ['@svgr/webpack'],
      }
    ]
  },
  plugins: [
  ]
};
