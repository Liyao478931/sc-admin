import { mapState } from 'vuex'

const DEFAULTS = {
  brand_color:'#409EFF', system_name:'数智管控平台', logo_text_color:'#ffffff', logo_bg_color:'#2b2f3a',
  logo_area_height:60, logo_text_size:20, logo_text_bold:true, sidebar_width:220, sidebar_collapsed_width:64,
  sidebar_bg_color:'#304156', sidebar_text_color:'#bfcbd9', sidebar_text_hover:'#ffffff',
  sidebar_active_color:'#409EFF', sidebar_active_bg:'rgba(64,158,255,0.1)',
  navbar_bg_color:'#ffffff', navbar_text_color:'#303133',
  navbar_bottom_shadow:true, navbar_shadow_color:'rgba(0,21,41,0.08)',
  content_bg_color:'#f0f2f5', card_bg_color:'#ffffff', card_radius:8, border_color:'#EBEEF5',
  body_text_color:'#303133', helper_text_color:'#909399', link_color:'#409EFF', link_hover_color:'#337ecc',
  system_font:'system', code_font:'system', font_size:'default', line_height:'default', heading_bold:true,
  text_selection_bg:'#409EFF', text_selection_color:'#ffffff',
  tabs_color:'#409EFF', tabs_bg_color:'#ffffff', tabs_active_bg:'#ffffff', tabs_active_text_color:'#409EFF',
  footer_bg_color:'#ffffff', footer_text_color:'#909399',
  logo_display_mode:'text_icon', logo_icon:'el-icon-s-home', logo_image:'',
  system_name_abbr:'SC', logo_bottom_border:false, logo_area_radius:0, logo_text_font_family:'system', logo_text_letter_spacing:2,
  browser_title_format:'name_page', favicon:'',
  menu_icon_show:true, menu_accordion:true, menu_active_indicator:'left_bar', menu_active_indicator_width:3,
  navbar_height:'default', navbar_bg_opacity:1, navbar_bg_blur:false, navbar_blur_strength:10,
  breadcrumb_show:true, breadcrumb_separator:'/', breadcrumb_home_icon:true,
  global_search_show:true, notification_show:true, user_avatar_show:true, user_avatar_round:true,
  tabs_show:true, tabs_position:'below_navbar', tabs_fixed:true, tabs_bar_height:40, tabs_max_count:20,
  content_padding_v:20, content_padding_h:20, page_bg_color:'#f0f2f5',
  footer_show:false, footer_height:60, footer_divider:true, footer_divider_color:'#EBEEF5',
  user_avatar_size:'default', user_dropdown_items:['profile','logout'],
  navbar_btn_style:'icon', navbar_right_elements:['global_search','notifications','user_avatar','fullscreen','refresh'],
  user_dropdown_show_role:true, sidebar_bottom_info:false, sidebar_bottom_text:'v1.0.0', sidebar_bottom_text_size:12,
  sidebar_scrollbar_style:'default', page_title_show:true, page_title_color:'#303133', page_title_size:'default', page_title_bold:true,
  page_title_underline:false, page_title_underline_color:'#409EFF',
  page_actions_show:true, page_actions_position:'title_right', page_actions_bg:'#ffffff', page_actions_shadow:false, page_actions_padding:16,
  content_bg_image:'', content_padding:20, content_loading_anim:'skeleton', content_loading_color:'#409EFF', content_min_height:'auto',
  // 响应式
  mobile_adaptive:true, mobile_breakpoint:768, tablet_breakpoint:1024, mobile_sidebar_behavior:'drawer',
  mobile_content_padding:12, mobile_menu_collapsed:true, mobile_table_adapt:'scroll',
  mobile_pagination_simplify:true, mobile_cards_stack:true,
}

const FONT_SIZE_MAP = { small:'12px', default:'13px', large:'14px' }

export default {
  computed: {
    ...mapState('theme', ['config', 'loaded']),
    theme() { return Object.assign({}, DEFAULTS, this.config || {}) },
    brandColor() { return this.theme.brand_color },
    sidebarBg() { return this.theme.sidebar_bg_color },
    sidebarText() { return this.theme.sidebar_text_color },
    sidebarActive() { return this.theme.sidebar_active_color },
    navbarBg() { return this.theme.navbar_bg_color },
    navbarText() { return this.theme.navbar_text_color },
    contentBg() { return this.theme.content_bg_color },
  },
  methods: {
    applyTheme() {
      const cfg = this.theme; const root = document.documentElement
      const vars = {
        '--brand-color':cfg.brand_color,'--sidebar-bg':cfg.sidebar_bg_color,'--sidebar-text':cfg.sidebar_text_color,
        '--sidebar-text-hover':cfg.sidebar_text_hover,'--sidebar-active-color':cfg.sidebar_active_color,
        '--sidebar-active-bg':cfg.sidebar_active_bg,'--navbar-bg':cfg.navbar_bg_color,'--navbar-text':cfg.navbar_text_color,
        '--navbar-shadow':cfg.navbar_bottom_shadow?cfg.navbar_shadow_color:'transparent',
        '--content-bg':cfg.content_bg_color,'--content-padding':cfg.content_padding_h+'px',
        '--content-bg-image':cfg.content_bg_image?'url('+cfg.content_bg_image+')':'none',
        '--card-bg':cfg.card_bg_color,'--card-radius':cfg.card_radius+'px','--border-color':cfg.border_color,
        '--logo-bg':cfg.logo_bg_color,'--logo-text-color':cfg.logo_text_color,'--logo-height':cfg.logo_area_height+'px',
        '--logo-text-size':cfg.logo_text_size+'px','--logo-font-family':(cfg.logo_text_font_family==='system'?'"Helvetica Neue",Helvetica,"PingFang SC","Microsoft YaHei",sans-serif':cfg.logo_text_font_family),'--page-bg':cfg.page_bg_color,'--text-color':cfg.body_text_color,
        '--text-helper':cfg.helper_text_color,'--link-color':cfg.link_color,
        '--tabs-color':cfg.tabs_color,'--tabs-bg':cfg.tabs_bg_color,'--tabs-active-bg':cfg.tabs_active_bg,'--tabs-active-text':cfg.tabs_active_text_color,
        '--footer-bg':cfg.footer_bg_color,'--footer-text':cfg.footer_text_color,'--footer-text-size':FONT_SIZE_MAP[cfg.footer_text_size]||'13px',
        // 字体排版
        '--system-font':({system:'"Helvetica Neue",Helvetica,"PingFang SC","Microsoft YaHei",sans-serif','Microsoft YaHei':'"Microsoft YaHei",sans-serif','Source Han Sans':'"Source Han Sans",sans-serif','PingFang SC':'"PingFang SC",sans-serif','Helvetica Neue':'"Helvetica Neue",Helvetica,sans-serif',Arial:'Arial,sans-serif',PingFang:'PingFang, sans-serif',SimSun:'SimSun,serif',SimHei:'SimHei,sans-serif'})[cfg.system_font]||cfg.system_font,
        '--code-font':({system:'Consolas,monospace',Consolas:'Consolas,monospace',Monaco:'Monaco,monospace','Courier New':'"Courier New",monospace','Fira Code':'"Fira Code",monospace','JetBrains Mono':'"JetBrains Mono",monospace'})[cfg.code_font]||cfg.code_font,
        '--font-size':({small:'13px',default:'14px',large:'15px'})[cfg.font_size]||'14px',
        '--line-height':({compact:'1.4',default:'1.6',loose:'1.8'})[cfg.line_height]||'1.6',
        '--heading-bold':cfg.heading_bold?'700':'normal',
        '--link-hover-color':cfg.link_hover_color,
        '--text-selection-bg':cfg.text_selection_bg,
        '--text-selection-color':cfg.text_selection_color,
        // 页面标题
        '--page-title-color':cfg.page_title_color,
        '--page-title-size':({small:'18px',default:'20px',large:'24px'})[cfg.page_title_size]||'20px',
        '--page-title-bold':cfg.page_title_bold?'bold':'normal',
        '--page-title-underline-color':cfg.page_title_underline_color,
        // 页面操作区
        '--page-actions-bg':cfg.page_actions_bg,
        '--page-actions-shadow':cfg.page_actions_shadow?'0 1px 4px rgba(0,0,0,0.06)':'none',
        // 内容区
        '--content-min-height':cfg.content_min_height==='viewport'?'calc(100vh - 60px)':'auto',
        // 布局配置
        '--sidebar-anim-duration':(cfg.sidebar_anim_duration||300)+'ms',
        '--content-max-width':cfg.content_max_width==='full'?'100%':cfg.content_max_width==='wide'?'90%':cfg.content_max_width==='standard'?'1200px':'960px',
        '--page-bg-image':cfg.page_bg_image?'url('+cfg.page_bg_image+')':'none',
        '--page-bg-repeat':cfg.page_bg_repeat||'repeat',
        '--page-bg-fixed':cfg.page_bg_fixed?'fixed':'scroll',
        '--page-min-height':cfg.page_min_height?'100vh':'auto',
      }
      Object.entries(vars).forEach(([k,v]) => root.style.setProperty(k, v))
      // 直接设置侧边栏Logo字体
      const logFont = cfg.logo_text_font_family
      const logoFontVal = logFont === 'system' ? '"Helvetica Neue",Helvetica,"PingFang SC","Microsoft YaHei",sans-serif' : (logFont || '')
      if (logoFontVal) root.style.setProperty('--logo-font-family', logoFontVal)
      const sidebarLogo = document.querySelector('.sidebar-logo')
      if (sidebarLogo) sidebarLogo.style.fontFamily = logoFontVal
      root.setAttribute('data-theme', (cfg.theme_mode==='dark')?'dark':'light')
      // Element UI 主色注入
      const color = cfg.brand_color||'#409EFF'
      let s = document.getElementById('__theme-brand-style')
      if (!s) { s = document.createElement('style'); s.id='__theme-brand-style'; document.head.appendChild(s) }
      s.textContent = `.el-button--primary,.el-button--primary:focus,.el-button--primary:hover{background:${color};border-color:${color}}.el-tabs__item.is-active,.el-tabs__item:hover{color:${color}}.el-tabs__active-bar{background:${color}}.el-menu-item.is-active{color:${color}!important}.el-switch.is-checked .el-switch__core{border-color:${color};background:${color}}.el-radio__input.is-checked .el-radio__inner,.el-checkbox__input.is-checked .el-checkbox__inner{border-color:${color};background:${color}}a{color:${color}}.el-breadcrumb__inner.is-link:hover,.el-breadcrumb__item:last-child .el-breadcrumb__inner{color:${color}}`
      // 浏览器标题
      const pt = window.__pageTitle||document.title; const sn = cfg.system_name||'数智管控平台'
      if (cfg.browser_title_format==='name') document.title = sn
      else if (cfg.browser_title_format==='page_name') document.title = pt+' - '+sn
      else document.title = sn+' - '+pt
      if (cfg.favicon) { let l=document.querySelector('link[rel="icon"]'); if(!l){l=document.createElement('link');l.rel='icon';document.head.appendChild(l)};l.href=cfg.favicon }
      // 字体排版样式注入
      let ts = document.getElementById('__theme-typography-style')
      if (!ts) { ts = document.createElement('style'); ts.id='__theme-typography-style'; document.head.appendChild(ts) }
      const sysFont = root.style.getPropertyValue('--system-font') || ''
      const codeFont = root.style.getPropertyValue('--code-font') || ''
      const fSize = root.style.getPropertyValue('--font-size') || '14px'
      const lHeight = root.style.getPropertyValue('--line-height') || '1.6'
      const selBg = root.style.getPropertyValue('--text-selection-bg') || ''
      const selColor = root.style.getPropertyValue('--text-selection-color') || ''
      let typoCss = ''
      if (sysFont) typoCss += `body{font-family:${sysFont}!important;font-size:${fSize};line-height:${lHeight}}`
      if (codeFont) typoCss += `code,kbd,pre,samp{font-family:${codeFont}!important}`
      if (selBg || selColor) {
        typoCss += `::selection{${selBg?'background:'+selBg+';':''}${selColor?'color:'+selColor+';':''}}`
        typoCss += `::-moz-selection{${selBg?'background:'+selBg+';':''}${selColor?'color:'+selColor+';':''}}`
      }
      ts.textContent = typoCss
    },
  },
}
