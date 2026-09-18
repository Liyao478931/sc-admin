import Vue from 'vue'
import ElementUI from 'element-ui'
import 'element-ui/lib/theme-chalk/index.css'
import locale from 'element-ui/lib/locale/lang/zh-CN'
import './utils/patchElementUI' // element-ui 运行时补丁：须在 Vue.use(ElementUI) 之前
import App from './App.vue'
import router from './router'
import store from './store'
import permission from './directive/permission'
import DriveFilePicker from './components/DriveFilePicker.vue'

Vue.use(ElementUI, { locale })
Vue.use(permission)
Vue.component('drive-file-picker', DriveFilePicker)
Vue.config.productionTip = false

new Vue({ router, store, render: h => h(App) }).$mount('#app')
