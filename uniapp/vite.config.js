import { defineConfig } from 'vite'
import uni from '@dcloudio/vite-plugin-uni'
import path from 'path'

export default defineConfig({
  plugins: [uni()],
  resolve: {
    alias: {
      '@': path.resolve(__dirname, './src'),
      '@components': path.resolve(__dirname, './src/components'),
      '@utils': path.resolve(__dirname, './src/utils'),
      '@api': path.resolve(__dirname, './src/api'),
      '@store': path.resolve(__dirname, './src/store'),
      '@composables': path.resolve(__dirname, './src/composables'),
      '@static': path.resolve(__dirname, './src/static')
    }
  },
  css: {
    preprocessorOptions: {
      scss: {
        additionalData: `@import "${path.resolve(__dirname, './src/uni.scss').replace(/\\/g, '/')}";`
      }
    }
  },
  server: {
    proxy: {
      '/api': {
        target: 'https://qq.yywyrh.cn',
        changeOrigin: true,
        secure: false
      }
    }
  }
})
