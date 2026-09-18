const path = require('path')

module.exports = {
  transpileDependencies: ['pinia', 'vue-demi', '@vue/devtools-api'],
  configureWebpack: {
    resolve: {
      alias: {
        'vue-demi$': path.resolve(__dirname, 'node_modules/vue-demi/lib/index.cjs')
      }
    }
  }
}