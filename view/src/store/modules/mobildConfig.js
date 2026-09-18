/**
 * DIY 页面编辑器状态管理（CRMEB 架构适配）
 * defaultArray: 组件实例数据（以 num 为 key 的对象）
 * pageFooter: 底部导航配置
 * pageTitle: 页面设置
 */
export default {
  namespaced: true,
  state: {
    configName: '',
    pageTitle: '',
    pageName: '模板名称',
    pageShow: 1,
    pageColor: 0,
    pagePic: 0,
    pageColorPicker: '#f5f5f5',
    pageTabVal: 0,
    pagePicUrl: '',
    // 已知组件列表默认数据（以 num 为 key）
    defaultArray: {},
    // 页面标题配置
    pageTitleConfig: {
      cname: '页面设置',
      name: 'pageTitle',
      titleConfig: {
        title: '标题',
        val: '',
        max: 50,
      },
      bgColor: {
        title: '背景颜色',
        name: 'bgColor',
        default: [{ item: '#f5f5f5' }],
        color: [{ item: '#f5f5f5' }],
      },
    },
    // 底部导航配置
    pageFooter: {
      cname: '底部导航',
      name: 'pageFoot',
      isHide: false,
      navConfig: {
        title: '导航类型',
        tabVal: 0,
        tabList: [{ name: '底部固定' }, { name: '底部悬浮' }],
      },
      navStyleConfig: {
        title: '导航样式',
        tabVal: 0,
        tabList: [{ name: '图片+文字' }, { name: '文字' }, { name: '图片' }],
      },
      bgColor: {
        title: '背景颜色',
        name: 'bgColor',
        default: [{ item: '#fff' }],
        color: [{ item: '#fff' }],
      },
      txtColor: {
        title: '文字颜色',
        name: 'txtColor',
        default: [{ item: '#282828' }],
        color: [{ item: '#282828' }],
      },
      activeTxtColor: {
        title: '选中文字颜色',
        name: 'txtColor',
        default: [{ item: '#F62C2C' }],
        color: [{ item: '#F62C2C' }],
      },
      menuList: [
        { name: '首页', link: '/pages/index/index' },
        { name: '我的', link: '/pages/user/index' },
      ],
    },
  },
  mutations: {
    /** 添加组件默认配置到 defaultArray */
    ADDARRAY(state, data) {
      if (data && data.val) {
        data.val.id = 'id' + (data.val.timestamp || Date.now())
        state.defaultArray[data.num] = data.val
      }
    },
    /** 删除组件 */
    DELETEARRAY(state, data) {
      delete state.defaultArray[data.num]
    },
    /** 更新组件配置 */
    UPDATEARR(state, data) {
      if (data && data.val && data.val.id) {
        for (const k in state.defaultArray) {
          if (state.defaultArray[k].id === data.val.id) {
            state.defaultArray[k] = data.val
          }
        }
        state.defaultArray = Object.assign({}, state.defaultArray)
      }
    },
    /** 清空所有组件 */
    SETEMPTY(state) {
      state.defaultArray = {}
    },
    /** 更新页面标题 */
    UPTITLE(state, val) { state.pageTitle = val },
    /** 更新页面名称 */
    UPNAME(state, val) { state.pageName = val },
    /** 页面是否显示 */
    UPSHOW(state, val) { state.pageShow = val },
    /** 背景色 */
    UPCOLOR(state, val) { state.pageColor = val },
    /** 背景图 */
    UPPIC(state, val) { state.pagePic = val },
    /** 背景色值 */
    UPPICKER(state, val) { state.pageColorPicker = val },
    /** 背景图样式 */
    UPRADIO(state, val) { state.pageTabVal = val },
    /** 背景图URL */
    UPPICURL(state, val) { state.pagePicUrl = val },
    /** 底部导航显隐 */
    footerHide(state) {
      state.pageFooter.isHide = !state.pageFooter.isHide
    },
    /** 更新底部导航配置 */
    footPageUpdata(state, data) {
      state.pageFooter = data
    },
    /** 更新页面标题配置 */
    titleUpdata(state, data) {
      state.pageTitle = data
    },
  },
  actions: {},
}
