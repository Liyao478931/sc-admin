const { defineConfig } = require('@vue/cli-service')
module.exports = defineConfig({
  publicPath: '/admin/',
  outputDir: 'dist',
  productionSourceMap: false,
  lintOnSave: false,
  transpileDependencies: true,
  css: {
    loaderOptions: {
      scss: { additionalData: '' }
    }
  }
})
