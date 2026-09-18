/**
 * CRMEB 风格 DIY 通用组件默认配置库
 * 排除商城类组件（商品/秒杀/拼团/优惠券等），适配当前项目
 * 每个组件含 cname(显示名)、name(组件类型)、defaultConfig(默认配置)
 */

/** 生成唯一时间戳 id */
export function genTs() {
  return Date.now()
}

export const C_COMPONENT_DEFS = [
  {
    cname: '轮播图',
    name: 'banner',
    icon: 'el-icon-picture',
    defaultConfig: {
      cname: '轮播图',
      name: 'banner',
      isHide: false,
      setUp: { tabVal: 0 },
      // 轮播风格（3种）
      styleConfig: { title: '选择风格', tabVal: 0, tabList: [{ name: '样式一' }, { name: '样式二' }, { name: '样式三' }] },
      swiperConfig: {
        title: '图片列表',
        list: [
          { img: 'https://via.placeholder.com/375x180/667eea/fff?text=Banner1', link: '' },
          { img: 'https://via.placeholder.com/375x180/10b981/fff?text=Banner2', link: '' },
        ],
      },
      // 指示器样式（4种）
      docConfig: { title: '指示器样式', tabVal: 0, tabList: [{ name: '样式一' }, { name: '样式二' }, { name: '样式三' }, { name: '样式四' }] },
      // 指示器位置（左/中/右）
      docPosition: { title: '指示器位置', tabVal: 1, tabList: [{ name: '左对齐' }, { name: '居中对齐' }, { name: '右对齐' }] },
      // 色调
      toneConfig: { title: '色调', tabVal: 0, tabList: [{ name: '跟随主题风格' }, { name: '自定义' }] },
      dotColor: { title: '选中样式', default: [{ item: '#E93323' }], color: [{ item: '#E93323' }] },
      dotBgColor: { title: '常规样式', default: [{ item: '#DDDDDD' }], color: [{ item: '#DDDDDD' }] },
      // 图片圆角
      filletImg: { title: '图片圆角', type: 0, list: [{ val: '全部' }, { val: '单个' }], valName: '圆角值', val: 0, min: 0, valList: [{ val: 0 }, { val: 0 }, { val: 0 }, { val: 0 }] },
      // 图片间距
      imgConfig: { title: '图片间距', val: 1, min: 0 },
      // 图片阴影
      imgShadowConfig: { title: '图片阴影', color: '#888', x: 0, y: 0, blur: 0, spread: 0, visible: 0 },
      bgColor: { title: '背景颜色', default: [{ item: '#fff' }], color: [{ item: '#fff' }] },
      topConfig: { title: '上边距', val: 0, min: 0 },
      bottomConfig: { title: '下边距', val: 0, min: 0 },
    },
  },
  {
    cname: '导航菜单',
    name: 'home_menu',
    icon: 'el-icon-menu',
    defaultConfig: {
      cname: '导航菜单',
      name: 'home_menu',
      isHide: false,
      setUp: { tabVal: 0 },
      // 导航样式（图片加文字/方形/圆形/文字）
      menuStyleConfig: { title: '导航样式', tabVal: 0, tabList: [{ name: '图片加文字' }, { name: '方形图标' }, { name: '圆形图标' }, { name: '纯文字' }] },
      // 单行显示（3/4/5个）
      number: { title: '单行显示', tabVal: 1, tabList: [{ name: '3个' }, { name: '4个' }, { name: '5个' }] },
      // 展示样式
      showConfig: { title: '展示样式', tabVal: 0, tabList: [{ name: '固定显示' }, { name: '滑动显示' }] },
      // 显示行数（1/2行）
      rowsNum: { title: '显示行数', tabVal: 0, tabList: [{ name: '1行' }, { name: '2行' }] },
      menuConfig: {
        title: '菜单列表',
        columns: 4,
        list: [
          { img: '', title: '菜单1', link: '' },
          { img: '', title: '菜单2', link: '' },
          { img: '', title: '菜单3', link: '' },
          { img: '', title: '菜单4', link: '' },
        ],
      },
      // 背景圆角
      filletImg: { title: '背景圆角', type: 0, list: [{ val: '全部' }, { val: '单个' }], valName: '圆角值', val: 0, min: 0, valList: [{ val: 0 }, { val: 0 }, { val: 0 }, { val: 0 }] },
      // 图标阴影
      imgShadowConfig: { title: '图标阴影', color: '#888', x: 0, y: 0, blur: 0, spread: 0, visible: 0 },
      // 色调
      toneConfig: { title: '色调', tabVal: 0, tabList: [{ name: '跟随主题风格' }, { name: '自定义' }] },
      pointerColor: { title: '选中样式', default: [{ item: '#E93323' }], color: [{ item: '#E93323' }] },
      pointerBgColor: { title: '常规样式', default: [{ item: '#DDDDDD' }], color: [{ item: '#DDDDDD' }] },
      textColor: { title: '文字颜色', default: [{ item: '#333' }], color: [{ item: '#333' }] },
      bgColor: { title: '背景颜色', default: [{ item: '#fff' }], color: [{ item: '#fff' }] },
      topConfig: { title: '上边距', val: 0, min: 0 },
      bottomConfig: { title: '下边距', val: 0, min: 0 },
    },
  },
  {
    cname: '标题',
    name: 'home_title',
    icon: 'el-icon-edit-outline',
    defaultConfig: {
      cname: '标题',
      name: 'home_title',
      isHide: false,
      setUp: { tabVal: 0 },
      titleConfig: { title: '标题内容', val: '标题', max: 50 },
      titleColor: { title: '标题颜色', default: [{ item: '#282828' }], color: [{ item: '#282828' }] },
      titleSize: { title: '标题大小', val: 18, min: 12, max: 32 },
      titleAlign: { title: '对齐方式', tabVal: 1, tabList: [{ name: '左' }, { name: '中' }, { name: '右' }] },
      // 右侧按钮
      buttonConfig: { title: '是否显示按钮', tabVal: 0, tabList: [{ name: '显示' }, { name: '不显示' }] },
      linkConfig: { title: '链接地址', val: '' },
      buttonColor: { title: '按钮颜色', default: [{ item: '#4F46E5' }], color: [{ item: '#4F46E5' }] },
      buttonText: { title: '按钮文字', val: '更多' },
      bgColor: { title: '背景颜色', default: [{ item: '#fff' }], color: [{ item: '#fff' }] },
      topConfig: { title: '上边距', val: 0, min: 0 },
      bottomConfig: { title: '下边距', val: 0, min: 0 },
    },
  },
  {
    cname: '富文本',
    name: 'richText',
    icon: 'el-icon-document',
    defaultConfig: {
      cname: '富文本',
      name: 'richText',
      isHide: false,
      setUp: { tabVal: 0 },
      contentConfig: { title: '内容', val: '<p>请输入内容</p>' },
      // 左右内边距（富文本专用）
      lrConfig: { title: '左右内边距', val: 0, min: 0 },
      // 上下内边距
      udConfig: { title: '上下内边距', val: 0, min: 0 },
      bgColor: { title: '背景颜色', default: [{ item: '#fff' }], color: [{ item: '#fff' }] },
      topConfig: { title: '上边距', val: 0, min: 0 },
      bottomConfig: { title: '下边距', val: 0, min: 0 },
    },
  },
  {
    cname: '图片魔方',
    name: 'picture_cube',
    icon: 'el-icon-grid',
    defaultConfig: {
      cname: '图片魔方',
      name: 'picture_cube',
      isHide: false,
      setUp: { tabVal: 0 },
      // 展示样式
      styleConfig: { title: '选择风格', tabVal: 0, tabList: [{ name: '样式一' }, { name: '样式二' }] },
      // 标题显示
      titleShow: { title: '标题显示', tabVal: 0, tabList: [{ name: '显示' }, { name: '不显示' }] },
      cubeConfig: {
        title: '图片列表',
        list: [
          { img: 'https://via.placeholder.com/180x180/667eea/fff?text=1', link: '', info: [{ title: '标题', value: '' }] },
          { img: 'https://via.placeholder.com/180x180/10b981/fff?text=2', link: '', info: [{ title: '标题', value: '' }] },
        ],
      },
      // 图片间距
      imgConfig: { title: '图片间距', val: 1, min: 0 },
      // 图片圆角
      filletImg: { title: '图片圆角', type: 0, list: [{ val: '全部' }, { val: '单个' }], valName: '圆角值', val: 0, min: 0, valList: [{ val: 0 }, { val: 0 }, { val: 0 }, { val: 0 }] },
      // 图片阴影
      imgShadowConfig: { title: '图片阴影', color: '#888', x: 0, y: 0, blur: 0, spread: 0, visible: 0 },
      bgColor: { title: '背景颜色', default: [{ item: '#fff' }], color: [{ item: '#fff' }] },
      topConfig: { title: '上边距', val: 0, min: 0 },
      bottomConfig: { title: '下边距', val: 0, min: 0 },
    },
  },
  {
    cname: '搜索框',
    name: 'search_box',
    icon: 'el-icon-search',
    defaultConfig: {
      cname: '搜索框',
      name: 'search_box',
      isHide: false,
      setUp: { tabVal: 0 },
      // 是否固定
      fixedConfig: { title: '是否固定', tabVal: 0, tabList: [{ name: '固定' }, { name: '不固定' }] },
      // 搜索框样式
      styleConfig: { title: '选择风格', tabVal: 0, tabList: [{ name: '样式一' }, { name: '样式二' }, { name: '样式三' }] },
      logoConfig: { title: '左侧图标', url: '', link: '' },
      searchTipConfig: { title: '搜索提示', value: '', place: '请输入搜索内容', max: 10 },
      // 搜索按钮
      titleSearch: { title: '是否显示按钮', tabVal: 1, tabList: [{ name: '显示' }, { name: '不显示' }] },
      btnTextConfig: { title: '按钮文字', val: '搜索' },
      bgColor: { title: '背景颜色', default: [{ item: '#fff' }], color: [{ item: '#fff' }] },
      topConfig: { title: '上边距', val: 0, min: 0 },
      bottomConfig: { title: '下边距', val: 0, min: 0 },
    },
  },
  {
    cname: '公告',
    name: 'news_roll',
    icon: 'el-icon-bell',
    defaultConfig: {
      cname: '公告',
      name: 'news_roll',
      isHide: false,
      setUp: { tabVal: 0 },
      // 公告样式（横向/纵向滚动）
      styleConfig: { title: '选择风格', tabVal: 0, tabList: [{ name: '横向滚动' }, { name: '纵向滚动' }] },
      // 标题显示
      titleStyle: { title: '标题样式', tabVal: 0, tabList: [{ name: '显示' }, { name: '不显示' }] },
      titleConfig: { title: '标题文字', val: '公告' },
      newsConfig: {
        title: '公告列表',
        list: [{ val: '欢迎使用本系统' }, { val: '系统升级通知' }],
      },
      // 滚动速度
      rollConfig: { title: '滚动速度', val: 5, min: 1, max: 20 },
      bgColor: { title: '背景颜色', default: [{ item: '#FFF8E1' }], color: [{ item: '#FFF8E1' }] },
      topConfig: { title: '上边距', val: 0, min: 0 },
      bottomConfig: { title: '下边距', val: 0, min: 0 },
    },
  },
  {
    cname: '辅助线',
    name: 'z_auxiliary_line',
    icon: 'el-icon-minus',
    defaultConfig: {
      cname: '辅助线',
      name: 'z_auxiliary_line',
      isHide: false,
      setUp: { tabVal: 0 },
      // 线条样式（实线/虚线/点线）
      lineStyle: { title: '线条样式', tabVal: 0, tabList: [{ name: '实线' }, { name: '虚线' }, { name: '点线' }] },
      lineColor: { title: '线条颜色', default: [{ item: '#E8ECF1' }], color: [{ item: '#E8ECF1' }] },
      lineHeight: { title: '线条粗细', val: 1, min: 1, max: 10 },
      lineBgColor: { title: '背景颜色', default: [{ item: '#fff' }], color: [{ item: '#fff' }] },
      // 左右间距
      lrEdge: { title: '左右间距', val: 0, min: 0 },
      topConfig: { title: '上边距', val: 0, min: 0 },
      bottomConfig: { title: '下边距', val: 0, min: 0 },
    },
  },
  {
    cname: '辅助块',
    name: 'z_auxiliary_box',
    icon: 'el-icon-crop',
    defaultConfig: {
      cname: '辅助块',
      name: 'z_auxiliary_box',
      isHide: false,
      setUp: { tabVal: 0 },
      heightConfig: { title: '高度', val: 20, min: 0, max: 200 },
      // 左右间距
      lrEdge: { title: '左右间距', val: 0, min: 0 },
      bgColor: { title: '背景颜色', default: [{ item: '#fff' }], color: [{ item: '#fff' }] },
      topConfig: { title: '上边距', val: 0, min: 0 },
      bottomConfig: { title: '下边距', val: 0, min: 0 },
    },
  },
  {
    cname: '视频',
    name: 'video',
    icon: 'el-icon-video-camera',
    defaultConfig: {
      cname: '视频',
      name: 'video',
      isHide: false,
      setUp: { tabVal: 0 },
      videoConfig: { title: '视频地址', url: '', poster: '' },
      bgColor: { title: '背景颜色', default: [{ item: '#000' }], color: [{ item: '#000' }] },
      topConfig: { title: '上边距', val: 0, min: 0 },
      bottomConfig: { title: '下边距', val: 0, min: 0 },
    },
  },
  {
    cname: '热区',
    name: 'hotspot',
    icon: 'el-icon-location-outline',
    defaultConfig: {
      cname: '热区',
      name: 'hotspot',
      isHide: false,
      setUp: { tabVal: 0 },
      hotspotConfig: {
        title: '热区图片',
        img: 'https://via.placeholder.com/375x200/e0e0e0/999?text=Hotspot',
        list: [{ x: 10, y: 10, w: 100, h: 100, link: '' }],
      },
      bgColor: { title: '背景颜色', default: [{ item: '#fff' }], color: [{ item: '#fff' }] },
      topConfig: { title: '上边距', val: 0, min: 0 },
      bottomConfig: { title: '下边距', val: 0, min: 0 },
    },
  },
  {
    cname: '悬浮按钮',
    name: 'customerService',
    icon: 'el-icon-service',
    defaultConfig: {
      cname: '悬浮按钮',
      name: 'customerService',
      isHide: false,
      setUp: { tabVal: 0 },
      // 按钮设置：跳转类型（0=链接 1=客服）
      buttonConfig: { title: '按钮跳转', tabVal: 0, tabList: [{ name: '页面链接' }, { name: '客服入口' }] },
      // 展示位置（0=左 1=右）
      locationConfig: { title: '展示位置', tabVal: 1, tabList: [{ name: '左' }, { name: '右' }] },
      logoConfig: { title: '按钮图标', url: '', link: '' },
      buttonText: { title: '按钮文字', val: '在线客服', min: 0, max: 10 },
      bgColor: { title: '按钮背景', default: [{ item: '#4F46E5' }], color: [{ item: '#4F46E5' }] },
      topConfig: { title: '上边距', val: 0, min: 0 },
      bottomConfig: { title: '下边距', val: 0, min: 0 },
    },
  },
  {
    cname: '关注公众号',
    name: 'wechat_attention',
    icon: 'el-icon-message',
    defaultConfig: {
      cname: '关注公众号',
      name: 'wechat_attention',
      isHide: false,
      setUp: { tabVal: 0 },
      titleConfig: { title: '标题名称', value: '关注公众号', place: '请输入标题', max: 10 },
      imgConfig: { title: '头像图片', url: '', type: 'image', name: '上传图片' },
      codeConfig: { title: '二维码图片', url: '', type: 'code', name: '上传二维码' },
      btnTextColor: { title: '按钮文字', default: [{ item: '#E93323' }], color: [{ item: '#E93323' }] },
      bgColor: { title: '背景颜色', default: [{ item: '#fff' }], color: [{ item: '#fff' }] },
      topConfig: { title: '上边距', val: 0, min: 0 },
      bottomConfig: { title: '下边距', val: 0, min: 0 },
    },
  },
  {
    cname: '选项卡',
    name: 'tabNav',
    icon: 'el-icon-s-operation',
    defaultConfig: {
      cname: '选项卡',
      name: 'tabNav',
      isHide: false,
      setUp: { tabVal: 0 },
      // 滑动置顶（0=启用 1=不启用）
      stickyConfig: { title: '滑动置顶', tabVal: 0, tabList: [{ name: '启用' }, { name: '不启用' }] },
      // 选项卡列表：text(文字) + link(跳转链接)
      tabListConfig: {
        title: '选项卡列表',
        list: [
          { text: { val: '首页' }, link: '/pages/diy/index?type=home' },
          { text: { val: '资讯' }, link: '' },
          { text: { val: '关于' }, link: '' },
        ],
      },
      // 色调：0=跟随主题 1=自定义
      toneConfig: { title: '色调', tabVal: 0, tabList: [{ name: '跟随主题风格' }, { name: '自定义' }] },
      textColor: { title: '选中文字', default: [{ item: '#E93323' }], color: [{ item: '#E93323' }] },
      decorateColor: { title: '装饰元素', default: [{ item: '#E93323' }], color: [{ item: '#E93323' }] },
      bgColor: { title: '底部背景', default: [{ item: '#fff' }], color: [{ item: '#fff' }] },
      topConfig: { title: '上边距', val: 0, min: 0 },
      bottomConfig: { title: '下边距', val: 0, min: 0 },
    },
  },
  // ============ 业务组件（数据驱动，移动端调用业务接口渲染） ============
  {
    cname: '设备列表',
    name: 'device-list',
    icon: 'el-icon-s-platform',
    defaultConfig: {
      cname: '设备列表',
      name: 'device-list',
      isHide: false,
      setUp: { tabVal: 0 },
      titleConfig: { title: '组件标题', val: '设备列表' },
      limitConfig: { title: '显示数量', val: 5, min: 1, max: 50 },
      linkConfig: { title: '点击链接', val: '' },
    },
  },
  {
    cname: '维修工单',
    name: 'repair-list',
    icon: 'el-icon-tools',
    defaultConfig: {
      cname: '维修工单',
      name: 'repair-list',
      isHide: false,
      setUp: { tabVal: 0 },
      titleConfig: { title: '组件标题', val: '维修工单' },
      limitConfig: { title: '显示数量', val: 5, min: 1, max: 50 },
      linkConfig: { title: '点击链接', val: '' },
    },
  },
  {
    cname: '隐患列表',
    name: 'hazard-list',
    icon: 'el-icon-warning-outline',
    defaultConfig: {
      cname: '隐患列表',
      name: 'hazard-list',
      isHide: false,
      setUp: { tabVal: 0 },
      titleConfig: { title: '组件标题', val: '安全隐患' },
      limitConfig: { title: '显示数量', val: 5, min: 1, max: 50 },
      linkConfig: { title: '点击链接', val: '' },
    },
  },
  {
    cname: '库存预警',
    name: 'inventory-alert',
    icon: 'el-icon-box',
    defaultConfig: {
      cname: '库存预警',
      name: 'inventory-alert',
      isHide: false,
      setUp: { tabVal: 0 },
      titleConfig: { title: '组件标题', val: '库存预警' },
      limitConfig: { title: '显示数量', val: 5, min: 1, max: 50 },
      linkConfig: { title: '点击链接', val: '' },
    },
  },
]

/**
 * 通用样式层（对齐 CRMEB 原版）
 * fillet 圆角 / shadowConfig 阴影 / prConfig 左右边距 / mbConfig 页面上间距 / offsetYConfig 组件上浮
 * 保存时 defaultConfig 会被 JSON 深拷贝，不会共享引用
 */
const COMMON_STYLE = {
  // 组件圆角：type 0=统一 1=单角，val=统一圆角值，valList=四个角
  fillet: {
    title: '组件圆角',
    type: 0,
    list: [
      { val: '全部', icon: 'iconcaozuo-zhengti' },
      { val: '单个', icon: 'iconcaozuo-bianjiao' },
    ],
    valName: '圆角值',
    val: 0,
    min: 0,
    valList: [{ val: 0 }, { val: 0 }, { val: 0 }, { val: 0 }],
  },
  // 组件阴影
  shadowConfig: {
    title: '组件阴影',
    color: '#888',
    x: 0,
    y: 0,
    blur: 0,
    spread: 0,
    visible: 0,
  },
  // 左右边距（padding）
  prConfig: {
    title: '左右边距',
    val: 0,
    min: 0,
  },
  // 页面上间距（marginTop）
  mbConfig: {
    title: '页面上间距',
    val: 0,
    min: 0,
  },
  // 组件上浮（marginTop 负值）
  offsetYConfig: {
    title: '组件上浮',
    val: 0,
    min: 0,
  },
}

// 为所有组件补齐通用样式字段（已有同名字段不覆盖）
C_COMPONENT_DEFS.forEach(c => {
  Object.keys(COMMON_STYLE).forEach(k => {
    if (!c.defaultConfig[k]) c.defaultConfig[k] = COMMON_STYLE[k]
  })
})
