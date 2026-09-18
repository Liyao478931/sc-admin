<template>
  <div class="theme-config-page">
    <TopBar :active-scheme="activeScheme" :schemes="schemes" :saving="saving" :last-save-time="lastSaveTime" @save="saveConfig" @reset="resetConfig" @export="handleExport" @switch-scheme="handleSchemeSwitch" />
    <div class="main-body">
      <LeftSidebar :groups="navGroups" :active-group="activeGroup" :search-query="searchQuery" :total-groups="navGroups.length" :total-items="totalItems" @select-group="scrollToGroup" @search="handleSearch" @save="saveConfig" @reset="resetConfig" />
      <div class="right-panel" ref="scrollContainer">
        <div v-for="g in configGroups" :key="g.key" v-show="g.key===activeGroup" :ref="'group-'+g.key">
          <ConfigGroup :group="g" :fields="g.fields||[]" :form-data="formData" :pre-colors="preColors" :icon-options="iconOptions" :expanded="isGroupExpanded(g.key)" :search-query="searchQuery" :upload-url="uploadUrl" :upload-headers="uploadHeaders" @toggle="toggleGroup(g.key)" @update="(k,v)=>handleFieldUpdate(k,v)" />
        </div>
      </div>
    </div>
    <BottomBar :config-count="totalItems" :last-save-time="lastSaveTime" :has-unsaved="hasUnsaved" />
    <SchemeManager :visible="schemeDialogVisible" :dialog-type="schemeDialogType" :schemes="schemes" @close="schemeDialogVisible=false" @switch-scheme="handleSchemeSwitch" @create="handleCreateScheme" @duplicate="handleDuplicateScheme" @delete="handleDeleteScheme" @import="handleImportData" />
  </div>
</template>
<script>
import { getThemeConfig,saveThemeConfig,resetThemeConfig,getThemeSchemes,createThemeScheme,deleteThemeScheme,activateThemeScheme,duplicateThemeScheme,exportThemeConfig,importThemeConfig } from '@/api/theme'
import TopBar from './components/TopBar.vue'
import LeftSidebar from './components/LeftSidebar.vue'
import ConfigGroup from './components/ConfigGroup.vue'
import BottomBar from './components/BottomBar.vue'
import SchemeManager from './components/SchemeManager.vue'
const PRE_COLORS = ['#409EFF','#67C23A','#E6A23C','#F56C6C','#909399','#303133','#304156','#1f2d3d','#ffffff','#f0f2f5','rgba(64,158,255,0.1)','rgba(0,0,0,0.2)','rgba(255,255,255,0.05)','#337ecc','#2b2f3a','#bfcbd9','#EBEEF5','#c1c1c1']
const ICON_LIST = ['el-icon-s-home','el-icon-setting','el-icon-menu','el-icon-brush','el-icon-edit-outline','el-icon-user','el-icon-s-custom','el-icon-lock','el-icon-document-copy','el-icon-connection','el-icon-bell','el-icon-search','el-icon-refresh','el-icon-full-screen','el-icon-s-fold','el-icon-s-unfold','el-icon-s-promotion','el-icon-star-off','el-icon-collection','el-icon-data-analysis','el-icon-s-data','el-icon-s-operation','el-icon-s-marketing','el-icon-s-platform']
const GROUP_ICONS = { scheme:'el-icon-document-copy',brand:'el-icon-s-home',layout:'el-icon-s-grid',menu_layout:'el-icon-menu',navbar:'el-icon-s-operation',tabs:'el-icon-document',footer:'el-icon-s-platform',content_area:'el-icon-s-data',typography:'el-icon-edit',responsive:'el-icon-mobile-phone' }

export default {
  name: 'ThemeConfig',
  components: { TopBar, LeftSidebar, ConfigGroup, BottomBar, SchemeManager },
  data() {
    return {
      saving:false, formData:{}, schemes:[], activeScheme:null, activeGroup:'brand', searchQuery:'', hasUnsaved:false,
      lastSaveTime:'', schemeDialogVisible:false, schemeDialogType:'', importDialog:false, importData:null, importName:'',
      groupStates:{}, totalItems:0, preColors:PRE_COLORS, iconOptions:ICON_LIST, uploadUrl:'/api/theme/upload',
    }
  },
  computed: {
    uploadHeaders() { const t = this.$store.state.user?.token; return t ? {Authorization:'Bearer '+t} : {} },
    navGroups() { return (this.configGroups||[]).map(g => ({...g, icon:GROUP_ICONS[g.key]||'el-icon-menu', count:(g.fields||[]).length||0})) },
    configGroups() { return this.buildConfigGroups() },
  },
  created() { this.loadGroupStates(); this.loadData(); window.addEventListener('beforeunload',this.beforeUnload) },
  beforeDestroy() { window.removeEventListener('beforeunload',this.beforeUnload) },
  methods: {
    beforeUnload(e){ if(this.hasUnsaved){e.preventDefault();e.returnValue=''} },
    async loadData() {
      try { const [c,s] = await Promise.all([getThemeConfig(),getThemeSchemes()]); if(c.code===0&&c.data)this.formData={...c.data}; if(s.code===0&&s.data){this.schemes=s.data;this.activeScheme=s.data.find(x=>x.is_active)||null}; this.totalItems=Object.keys(this.formData).length } catch(e){ this.$message.error('加载配置失败') }
    },
    async saveConfig() {
      this.saving=true; try { const r=await saveThemeConfig(this.formData); if(r.code===0){this.$message.success('配置保存成功');this.lastSaveTime=new Date().toLocaleString();this.hasUnsaved=false;await this.$store.dispatch('theme/loadConfig');const ff=this.formData.logo_text_font_family;document.documentElement.style.setProperty('--logo-font-family',(ff==='system'?'"Helvetica Neue",Helvetica,"PingFang SC","Microsoft YaHei",sans-serif':ff||''));if(this.$parent&&this.$parent.applyTheme)this.$parent.applyTheme()}else{this.$message.error(r.message||'保存失败')} } catch(e){this.$message.error('保存失败')} finally{this.saving=false}
    },
    async resetConfig() { try { await this.$confirm('确认恢复所有配置到默认值？此操作不可撤销。','提示',{type:'warning'}); const r=await resetThemeConfig(); if(r.code===0){this.$message.success('已恢复默认');await this.loadData()} } catch(e){} },
    handleFieldUpdate(key,val){ this.$set(this.formData,key,val); this.hasUnsaved=true },
    isGroupExpanded(k){ return this.groupStates[k]!==false },
    toggleGroup(k){ this.$set(this.groupStates,k,!this.isGroupExpanded(k)); this.saveGroupStates() },
    loadGroupStates(){ try{const s=localStorage.getItem('theme_config_group_state');if(s)this.groupStates=JSON.parse(s)}catch{} },
    saveGroupStates(){ localStorage.setItem('theme_config_group_state',JSON.stringify(this.groupStates)) },
    scrollToGroup(k){ this.activeGroup=k; this.$nextTick(()=>{const e=this.$refs['group-'+k];if(e&&e[0]){const c=this.$refs.scrollContainer;if(c)c.scrollTo({top:e[0].offsetTop-100,behavior:'smooth'})}}) },
    handleSearch(q){ this.searchQuery=q; if(!q)return; for(const g of this.configGroups){if(g.key==='scheme')continue;const f=g.fields||[];if(f.some(x=>x.label.includes(q)||x.key.includes(q)||x.desc?.includes(q))&&!this.isGroupExpanded(g.key))this.toggleGroup(g.key)} },
    openSchemeDialog(t){this.schemeDialogType=t;this.schemeDialogVisible=true},
    openSwitchDialog(){this.openSchemeDialog('switch')},
    async handleSchemeSwitch(s){ this.schemeDialogVisible=false; if(!s||!s.id)return; try{const r=await activateThemeScheme(s.id);if(r.code===0){this.$message.success('方案切换成功');await this.loadData()}else{this.$message.error(r.message||'切换失败')}}catch(e){this.$message.error('切换方案失败')} },
    async handleCreateScheme(d){ try{const r=await createThemeScheme(d);if(r.code===0){this.$message.success('方案创建成功');this.schemeDialogVisible=false;const s=await getThemeSchemes();if(s.code===0&&s.data)this.schemes=s.data}}catch(e){this.$message.error('创建失败')} },
    async handleDuplicateScheme(d){ try{const r=await duplicateThemeScheme(d.id,{name:d.name});if(r.code===0){this.$message.success('方案已复制');this.schemeDialogVisible=false;const s=await getThemeSchemes();if(s.code===0&&s.data)this.schemes=s.data}}catch(e){this.$message.error('复制失败')} },
    async handleDeleteScheme(s){ try{const r=await deleteThemeScheme(s.id);if(r.code===0){this.$message.success('方案已删除');const s2=await getThemeSchemes();if(s2.code===0&&s2.data){this.schemes=s2.data;this.activeScheme=s2.data.find(x=>x.is_active)||null}}}catch(e){this.$message.error('删除失败')} },
    async handleExport(){ try{const r=await exportThemeConfig({scheme_id:this.activeScheme?.id});if(r.code===0&&r.data){const b=new Blob([JSON.stringify(r.data,null,2)],{type:'application/json'});const a=document.createElement('a');a.href=URL.createObjectURL(b);a.download=(this.activeScheme?.name||'theme')+'_config.json';a.click();URL.revokeObjectURL(a.href)}}catch(e){this.$message.error('导出失败')} },
    async handleImportData(d){ try{const r=await importThemeConfig({config:JSON.stringify(d.data),name:d.name||'导入方案'});if(r.code===0){this.$message.success('导入成功');this.schemeDialogVisible=false;await this.loadData()}}catch(e){this.$message.error('导入失败')} },
    buildConfigGroups() {
      return [
        {key:'scheme',title:'方案管理'},
        {key:'brand',title:'第二组 · 品牌配置（19项）',fields:[
          {key:'logo_display_mode',label:'Logo 显示方式',type:'select',options:[{label:'文字+图标',value:'text_icon'},{label:'仅文字',value:'text_only'},{label:'仅图标',value:'icon_only'},{label:'仅图片',value:'image_only'}]},
          {key:'system_name',label:'系统名称',type:'text',placeholder:'数智管控平台'},
          {key:'system_name_abbr',label:'系统名称缩写',type:'text',placeholder:'SC'},
          {key:'logo_icon',label:'Logo 图标',type:'icon'},
          {key:'logo_image',label:'Logo 图片',type:'image',desc:'建议 32x32px'},
          {key:'logo_text_color',label:'Logo 文字颜色',type:'color'},
          {key:'logo_bg_color',label:'Logo 区域背景色',type:'color'},
          {key:'logo_area_height',label:'Logo 区域高度',type:'number',min:50,max:80,step:2,unit:'px'},
          {key:'logo_text_size',label:'Logo 文字大小',type:'number',min:14,max:28,step:1,unit:'px'},
          {key:'logo_text_bold',label:'Logo 文字加粗',type:'switch'},
          {key:'logo_text_font_family',label:'Logo 字体系列',type:'select',options:[{label:'系统默认',value:'system'},{label:'黑体',value:'SimHei'},{label:'宋体',value:'SimSun'},{label:'微软雅黑',value:'Microsoft YaHei'},{label:'思源黑体',value:'Source Han Sans'},{label:'PingFang SC',value:'PingFang SC'},{label:'Times New Roman',value:'Times New Roman'},{label:'Arial',value:'Arial'}]},
          {key:'logo_text_letter_spacing',label:'Logo 文字间距',type:'number',min:0,max:10,step:1,unit:'px'},
          {key:'logo_bottom_border',label:'Logo 底部边框',type:'switch'},
          {key:'logo_area_radius',label:'Logo 区域圆角',type:'number',min:0,max:12,step:1,unit:'px'},
          {key:'brand_color',label:'品牌色',type:'color'},
          {key:'favicon',label:'浏览器标签页图标',type:'image',desc:'建议 16x16 或 32x32'},
          {key:'browser_title_format',label:'标签页标题格式',type:'select',options:[{label:'系统名称',value:'name'},{label:'系统名称 - 页面标题',value:'name_page'},{label:'页面标题 - 系统名称',value:'page_name'}]},
        ]},
        {key:'layout',title:'第三组 · 布局配置（15项）',fields:[
          {key:'layout_mode',label:'布局模式',type:'select',options:[{label:'经典布局',value:'classic'},{label:'侧边栏布局',value:'sidebar'},{label:'顶栏布局',value:'topbar'},{label:'混合布局',value:'mixed'},{label:'双栏布局',value:'double'}]},
          {key:'sidebar_position',label:'侧边栏位置',type:'select',options:[{label:'左侧',value:'left'},{label:'右侧',value:'right'}]},
          {key:'sidebar_width',label:'侧边栏宽度',type:'slider',min:0,max:320,step:5},
          {key:'sidebar_collapsed_width',label:'折叠后宽度',type:'number',min:0,max:80,step:2,unit:'px'},
          {key:'sidebar_collapsible',label:'允许手动折叠',type:'switch'},{key:'sidebar_default_collapsed',label:'默认折叠',type:'switch'},
          {key:'sidebar_anim_duration',label:'折叠动画时长',type:'number',min:100,max:500,step:50,unit:'ms'},
          {key:'content_max_width',label:'内容区最大宽度',type:'select',options:[{label:'全屏（100%）',value:'full'},{label:'宽屏（90%）',value:'wide'},{label:'标准（1200px）',value:'standard'},{label:'窄屏（960px）',value:'narrow'}]},
          {key:'content_padding_h',label:'内容区水平内边距',type:'number',min:8,max:40,step:2,unit:'px'},
          {key:'content_padding_v',label:'内容区垂直内边距',type:'number',min:8,max:40,step:2,unit:'px'},
          {key:'page_min_height',label:'页面最小高度',type:'switch'},{key:'page_bg_color',label:'页面背景色',type:'color'},{key:'page_bg_image',label:'页面背景图片',type:'image'},
          {key:'page_bg_repeat',label:'背景图片平铺方式',type:'select',options:[{label:'平铺',value:'repeat'},{label:'拉伸',value:'stretch'},{label:'居中',value:'center'},{label:'重复-x',value:'repeat-x'},{label:'重复-y',value:'repeat-y'}]},
          {key:'page_bg_fixed',label:'背景图固定',type:'switch'},
        ]},
        {key:'menu_layout',title:'第四组 · 菜单布局配置',fields:[
          {key:'menu_layout_mode',label:'菜单布局模式',type:'select',options:[{label:'经典树形菜单',value:'classic_tree'},{label:'左侧一级+右侧子菜单',value:'left_right'}]},
          {key:'menu_icon_show',label:'菜单项图标显示',type:'switch'},{key:'menu_icon_size',label:'菜单项图标大小',type:'select',options:[{label:'小（16px）',value:'small'},{label:'默认（18px）',value:'default'},{label:'大（20px）',value:'large'}]},
          {key:'menu_text_size',label:'菜单项文字大小',type:'select',options:[{label:'小（13px）',value:'small'},{label:'默认（14px）',value:'default'},{label:'大（15px）',value:'large'}]},
          {key:'menu_item_height',label:'菜单高度',type:'select',options:[{label:'紧凑（40px）',value:'compact'},{label:'默认（50px）',value:'default'},{label:'宽松（56px）',value:'loose'},{label:'超宽松（64px）',value:'xloose'}]},
          {key:'menu_indent',label:'菜单缩进',type:'number',min:0,max:40,step:2,unit:'px'},{key:'menu_expand_mode',label:'菜单展开方式',type:'select',options:[{label:'点击展开',value:'click'},{label:'悬停展开',value:'hover'}]},
          {key:'menu_accordion',label:'菜单手风琴模式',type:'switch'},{key:'menu_icon_top_only',label:'图标仅显示在顶层',type:'switch'},
          {key:'menu_text_overflow',label:'文字溢出处理',type:'select',options:[{label:'省略号',value:'ellipsis'},{label:'换行',value:'wrap'}]},
          {key:'sidebar_bg_color',label:'侧边栏背景色',type:'color'},{key:'sidebar_text_color',label:'侧边栏文字色',type:'color'},{key:'sidebar_text_hover',label:'侧边栏文字悬停色',type:'color'},{key:'menu_hover_bg_color',label:'菜单悬停背景色',type:'color',desc:'菜单项鼠标悬停时的背景色'},
          {key:'sidebar_active_color',label:'侧边栏激活项颜色',type:'color'},{key:'sidebar_active_bg',label:'侧边栏激活项背景色',type:'color'},
          {key:'sidebar_submenu_bg',label:'侧边栏子菜单背景色',type:'color'},{key:'navbar_bg_color',label:'顶栏背景色',type:'color'},{key:'navbar_text_color',label:'顶栏文字色',type:'color'},
          {key:'sidebar_bottom_info',label:'侧边栏底部固定信息',type:'switch'},{key:'sidebar_bottom_text',label:'底部文字',type:'text',placeholder:'v1.0.0'},
          {key:'sidebar_bottom_text_color',label:'底部文字颜色',type:'color'},{key:'sidebar_bottom_text_size',label:'底部文字大小',type:'number',min:10,max:14,step:1,unit:'px'},
          {key:'sidebar_scrollbar_style',label:'侧边栏滚动条样式',type:'select',options:[{label:'系统默认',value:'default'},{label:'细条',value:'thin'},{label:'隐藏',value:'hidden'}]},
          {key:'left_menu_width',label:'左侧一级菜单宽度',type:'slider',min:160,max:260,step:5,desc:'left_right模式生效'},
          {key:'submenu_popup_bg',label:'子菜单弹窗背景色',type:'color',desc:'left_right模式生效'},{key:'submenu_popup_radius',label:'子菜单弹窗圆角',type:'number',min:0,max:20,step:2,unit:'px',desc:'left_right模式生效'},
          {key:'submenu_popup_shadow',label:'子菜单弹窗阴影',type:'select',options:[{label:'无阴影',value:'none'},{label:'浅阴影',value:'light'},{label:'中等阴影',value:'medium'},{label:'深阴影',value:'heavy'}],desc:'left_right模式生效'},
          {key:'submenu_popup_min_width',label:'子菜单弹窗最小宽度',type:'number',min:140,max:320,step:10,unit:'px',desc:'left_right模式生效'},
          {key:'submenu_item_bg_hover',label:'子菜单悬停背景色',type:'color',desc:'left_right模式生效'},{key:'submenu_item_bg_active',label:'子菜单激活背景色',type:'color',desc:'left_right模式生效'},
        ]},
        {key:'navbar',title:'第五组 · 顶栏配置（29项）',fields:[
          {key:'navbar_height',label:'顶栏高度',type:'select',options:[{label:'矮（50px）',value:'short'},{label:'默认（60px）',value:'default'},{label:'高（70px）',value:'tall'}]},{key:'navbar_fixed',label:'顶栏固定',type:'switch'},
          {key:'navbar_bg_opacity',label:'顶栏背景透明度',type:'slider',min:0,max:1,step:0.05},{key:'navbar_bg_blur',label:'顶栏背景模糊',type:'switch'},{key:'navbar_blur_strength',label:'模糊强度',type:'number',min:2,max:20,step:2,unit:'px'},
          {key:'navbar_left_elements',label:'顶栏左侧元素',type:'tags',options:[{label:'面包屑',value:'breadcrumb'},{label:'Logo（移动端）',value:'logo_mobile'},{label:'页面标题',value:'page_title'}]},
          {key:'navbar_right_elements',label:'顶栏右侧元素',type:'tags',options:[{label:'全局搜索',value:'global_search'},{label:'消息通知',value:'notifications'},{label:'用户头像',value:'user_avatar'},{label:'全屏切换',value:'fullscreen'},{label:'刷新按钮',value:'refresh'},{label:'主题切换',value:'theme_switch'},{label:'语言切换',value:'lang_switch'},{label:'帮助中心',value:'help_center'}]},
          {key:'breadcrumb_show',label:'面包屑导航显示',type:'switch'},{key:'breadcrumb_separator',label:'面包屑分隔符',type:'text',placeholder:'/'},{key:'breadcrumb_home_icon',label:'面包屑首页图标',type:'switch'},{key:'breadcrumb_show_current',label:'显示当前页面标题',type:'switch'},{key:'breadcrumb_max_level',label:'最大显示层级',type:'number',min:2,max:6,step:1},
          {key:'global_search_show',label:'全局搜索显示',type:'switch'},{key:'global_search_placeholder',label:'搜索占位文字',type:'text',placeholder:'搜索菜单、功能、页面...'},{key:'global_search_shortcut',label:'全局搜索快捷键',type:'text',placeholder:'Ctrl+K'},{key:'global_search_recent',label:'搜索最近使用记录',type:'switch'},{key:'global_search_hot',label:'搜索热门搜索',type:'switch'},
          {key:'notification_show',label:'消息通知显示',type:'switch'},{key:'notification_auto_close',label:'通知自动关闭',type:'switch'},{key:'notification_max_count',label:'通知最大显示数量',type:'number',min:5,max:20,step:1},{key:'notification_poll_interval',label:'通知轮询间隔',type:'number',min:10,max:120,step:5,unit:'秒'},
          {key:'user_avatar_show',label:'用户头像显示',type:'switch'},{key:'user_avatar_size',label:'用户头像大小',type:'select',options:[{label:'小（28px）',value:'small'},{label:'默认（32px）',value:'default'},{label:'大（36px）',value:'large'}]},{key:'user_avatar_round',label:'用户头像圆角',type:'switch'},
          {key:'user_dropdown_items',label:'用户下拉菜单',type:'tags',options:[{label:'个人中心',value:'profile'},{label:'修改密码',value:'change_password'},{label:'登录日志',value:'login_logs'},{label:'退出登录',value:'logout'}]},{key:'user_dropdown_show_role',label:'显示用户角色',type:'switch'},{key:'navbar_btn_style',label:'右侧按钮风格',type:'select',options:[{label:'图标',value:'icon'},{label:'文字图标混合',value:'text_icon'}]},
          {key:'navbar_btn_size',label:'按钮大小',type:'select',options:[{label:'小',value:'small'},{label:'默认',value:'default'},{label:'大',value:'large'}]},{key:'navbar_element_gap',label:'右侧元素间距',type:'number',min:4,max:20,step:2,unit:'px'},
        ]},
        {key:'tabs',title:'第七组 · 标签页配置（18项）',fields:[
          {key:'tabs_show',label:'标签页栏显示',type:'switch'},{key:'tabs_position',label:'标签页栏位置',type:'select',options:[{label:'顶栏下方',value:'below_navbar'},{label:'内容区顶部',value:'above_content'}]},{key:'tabs_fixed',label:'标签页栏固定',type:'switch'},
          {key:'tabs_bar_height',label:'标签页栏高度',type:'number',min:32,max:48,step:2,unit:'px'},{key:'tabs_max_count',label:'标签页最大数量',type:'number',min:10,max:50,step:5},
          {key:'tabs_close_behavior',label:'关闭方式',type:'select',options:[{label:'仅当前页',value:'current'},{label:'当前页+其他',value:'others'},{label:'全部',value:'all'}]},
          {key:'tabs_cache',label:'标签页缓存',type:'switch'},{key:'tabs_cache_max',label:'缓存最大数量',type:'number',min:5,max:20,step:1},{key:'tabs_show_icon',label:'显示图标',type:'switch'},{key:'tabs_show_refresh',label:'显示刷新按钮',type:'switch'},{key:'tabs_show_close',label:'显示关闭按钮',type:'switch'},
          {key:'tabs_color',label:'标签页颜色',type:'color'},{key:'tabs_bg_color',label:'标签页背景色',type:'color'},{key:'tabs_active_bg',label:'激活项背景色',type:'color'},{key:'tabs_active_text_color',label:'激活项文字颜色',type:'color'},
          {key:'tabs_item_height',label:'单个标签高度',type:'number',min:28,max:40,step:2,unit:'px'},{key:'tabs_item_padding',label:'标签内边距',type:'number',min:8,max:20,step:2,unit:'px'},{key:'tabs_item_radius',label:'标签圆角',type:'number',min:0,max:8,step:1,unit:'px'},
        ]},
        {key:'footer',title:'第八组 · 页脚配置（15项）',fields:[
          {key:'footer_show',label:'页脚显示',type:'switch'},{key:'footer_fixed',label:'页脚固定',type:'switch'},{key:'footer_height',label:'页脚高度',type:'number',min:40,max:80,step:2,unit:'px'},
          {key:'footer_bg_color',label:'页脚背景色',type:'color'},{key:'footer_text_color',label:'页脚文字颜色',type:'color'},{key:'footer_text_size',label:'页脚文字大小',type:'select',options:[{label:'小（12px）',value:'small'},{label:'默认（13px）',value:'default'},{label:'大（14px）',value:'large'}]},
          {key:'footer_copyright',label:'版权信息',type:'text',placeholder:'Copyright © 2026 数智管控平台'},{key:'footer_left_content',label:'页脚左侧内容',type:'text',placeholder:''},{key:'footer_right_content',label:'页脚右侧内容',type:'text',placeholder:''},
          {key:'footer_links',label:'页脚链接',type:'kvlist'},{key:'footer_link_color',label:'链接颜色',type:'color'},{key:'footer_link_hover_color',label:'链接悬停色',type:'color'},{key:'footer_padding',label:'页脚内边距',type:'number',min:8,max:24,step:2,unit:'px'},
          {key:'footer_divider',label:'页脚分割线',type:'switch'},{key:'footer_divider_color',label:'分割线颜色',type:'color'},
        ]},
        {key:'content_area',title:'第九组 · 内容区配置（17项）',fields:[
          {key:'content_bg_color',label:'内容区背景色',type:'color'},{key:'content_bg_image',label:'内容区背景图',type:'image'},{key:'content_padding',label:'内容区内边距',type:'number',min:8,max:40,step:2,unit:'px'},
          {key:'content_loading_anim',label:'加载动画',type:'select',options:[{label:'无',value:'none'},{label:'旋转',value:'spin'},{label:'波纹',value:'ripple'},{label:'渐变',value:'fade'},{label:'骨架屏',value:'skeleton'},{label:'进度条',value:'progress'}]},{key:'content_loading_color',label:'加载动画颜色',type:'color'},
          {key:'content_min_height',label:'内容区最小高度',type:'select',options:[{label:'自适应',value:'auto'},{label:'固定视口高度',value:'viewport'}]},{key:'page_title_show',label:'页面标题显示',type:'switch'},{key:'page_title_color',label:'页面标题颜色',type:'color'},
          {key:'page_title_size',label:'页面标题大小',type:'select',options:[{label:'小（18px）',value:'small'},{label:'默认（20px）',value:'default'},{label:'大（24px）',value:'large'}]},{key:'page_title_bold',label:'页面标题加粗',type:'switch'},{key:'page_title_underline',label:'标题下划线',type:'switch'},{key:'page_title_underline_color',label:'下划线颜色',type:'color'},
          {key:'page_actions_show',label:'页面操作区显示',type:'switch'},{key:'page_actions_position',label:'操作区位置',type:'select',options:[{label:'标题右侧',value:'title_right'},{label:'标题下方',value:'title_below'},{label:'独立一行',value:'independent'}]},
          {key:'page_actions_bg',label:'操作区背景色',type:'color'},{key:'page_actions_shadow',label:'操作区阴影',type:'switch'},{key:'page_actions_padding',label:'操作区内边距',type:'number',min:8,max:24,step:2,unit:'px'},
        ]},
        {key:'typography',title:'第十组 · 字体排版配置（11项）',fields:[
          {key:'system_font',label:'系统字体',type:'select',options:[{label:'系统默认',value:'system'},{label:'微软雅黑',value:'Microsoft YaHei'},{label:'思源黑体',value:'Source Han Sans'},{label:'PingFang SC',value:'PingFang SC'},{label:'Helvetica Neue',value:'Helvetica Neue'},{label:'Arial',value:'Arial'},{label:'苹方',value:'PingFang'},{label:'宋体',value:'SimSun'},{label:'黑体',value:'SimHei'}]},
          {key:'code_font',label:'代码字体',type:'select',options:[{label:'系统默认',value:'system'},{label:'Consolas',value:'Consolas'},{label:'Monaco',value:'Monaco'},{label:'Courier New',value:'Courier New'},{label:'Fira Code',value:'Fira Code'},{label:'JetBrains Mono',value:'JetBrains Mono'}]},
          {key:'font_size',label:'字体大小',type:'select',options:[{label:'小',value:'small'},{label:'默认',value:'default'},{label:'大',value:'large'}]},{key:'line_height',label:'行高',type:'select',options:[{label:'紧凑（1.4）',value:'compact'},{label:'默认（1.6）',value:'default'},{label:'宽松（1.8）',value:'loose'}]},
          {key:'heading_bold',label:'标题字体加粗',type:'switch'},{key:'body_text_color',label:'正文颜色',type:'color'},{key:'helper_text_color',label:'辅助文字颜色',type:'color'},{key:'link_color',label:'链接颜色',type:'color'},{key:'link_hover_color',label:'链接悬停颜色',type:'color'},{key:'text_selection_bg',label:'文字选中背景色',type:'color'},{key:'text_selection_color',label:'文字选中颜色',type:'color'},
        ]},
        {key:'responsive',title:'第十一组 · 响应式配置（11项）',fields:[
          {key:'mobile_adaptive',label:'移动端适配',type:'switch'},{key:'mobile_breakpoint',label:'移动端断点',type:'number',min:640,max:1024,step:10,unit:'px'},{key:'tablet_breakpoint',label:'平板断点',type:'number',min:768,max:1280,step:10,unit:'px'},
          {key:'mobile_sidebar_behavior',label:'移动端侧边栏行为',type:'select',options:[{label:'抽屉式',value:'drawer'},{label:'底部导航',value:'bottom_nav'},{label:'隐藏',value:'hidden'}]},{key:'mobile_navbar_simplify',label:'移动端顶栏简化',type:'switch'},
          {key:'mobile_content_padding',label:'移动端内容区内边距',type:'number',min:8,max:20,step:2,unit:'px'},{key:'mobile_menu_collapsed',label:'移动端菜单折叠',type:'switch'},
          {key:'mobile_table_adapt',label:'移动端表格适配',type:'select',options:[{label:'水平滚动',value:'scroll'},{label:'卡片式',value:'card'},{label:'简化显示',value:'simplified'}]},{key:'mobile_pagination_simplify',label:'移动端分页简化',type:'switch'},{key:'mobile_cards_stack',label:'移动端卡片堆叠',type:'switch'},{key:'responsive_debug_tool',label:'响应式调试工具',type:'switch'},
        ]},
      ]
    },
  },
}
</script>
<style scoped>
.theme-config-page{display:flex;flex-direction:column;height:100%;min-height:0}
.main-body{flex:1;display:flex;overflow:hidden;min-height:0}
.right-panel{flex:1;overflow-y:auto;min-height:0;height:100%;padding:28px 36px;background:#f8fafc}
.right-panel::-webkit-scrollbar{width:4px}
.right-panel::-webkit-scrollbar-thumb{background:#cbd5e1;border-radius:10px}
</style>
