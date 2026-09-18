import Vue from 'vue'
import Vuex from 'vuex'
import user from './modules/user'
import theme from './modules/theme'
import dictionary from './modules/dictionary'
import mobildConfig from './modules/mobildConfig'
import ai from './modules/ai'

Vue.use(Vuex)

export default new Vuex.Store({
  modules: { user, theme, dictionary, mobildConfig, ai }
})
