/**
 * SC 数智管控平台 - 全局菜单搜索（v1.76.42）
 * ------------------------------------------------------------
 * 功能：点击顶栏搜索按钮（或 Ctrl+K）弹出搜索面板，输入关键词模糊匹配
 *      当前用户【有权限】的菜单，回车/点击直接跳转。
 * 数据源：AppSidebar 组件实例的 menuItems
 *        （即后端 GET /api/menus/user 按当前用户角色权限过滤后的菜单树）
 * 结论：无权限的菜单不会出现在搜索结果中（搜索源与侧边栏完全一致）。
 * ------------------------------------------------------------
 * 构建/部署说明：
 *   1. 本文件需复制为 public/admin/static/js/global-search.js
 *   2. public/admin/index.html 的 </body> 前引入：
 *      <script src="/admin/static/js/global-search.js"></script>
 *   3. Navbar 搜索按钮的 handler（MainLayout.handleGlobalSearch）改为调用
 *      window.__scGlobalSearch()（对应 chunk 6268.*.js 同步替换）。
 */
(function () {
  'use strict'
  if (window.__scGlobalSearchInstalled) return
  window.__scGlobalSearchInstalled = true

  var PANEL_ID = 'sc-global-search'
  var PANEL_INPUT_ID = PANEL_ID + '-input'
  var PANEL_BODY_ID = PANEL_ID + '-body'
  var RESULT_LIMIT = 20
  var cursorIndex = -1
  var activeList = []

  /* ================= 工具 ================= */
  function getRootVm() {
    try { return document.querySelector('#app').__vue__ } catch (e) { return null }
  }

  // 深度查找 AppSidebar 组件实例（菜单数据源）
  function findSidebar(vm) {
    if (!vm) return null
    if (vm.$options && vm.$options.name === 'AppSidebar') return vm
    var kids = vm.$children || []
    for (var i = 0; i < kids.length; i++) {
      var r = findSidebar(kids[i])
      if (r) return r
    }
    return null
  }

  // 菜单树扁平化：仅保留可跳转节点（有 path），记录完整层级
  function flatten(items, parents) {
    var out = []
    parents = parents || []
    ;(items || []).forEach(function (it) {
      var chain = parents.concat([it.name])
      if (it.path && it.path !== '/') {
        out.push({ title: it.name, full: chain.join(' / '), path: it.path, icon: it.icon || '' })
      }
      if (it.children && it.children.length) {
        out = out.concat(flatten(it.children, chain))
      }
    })
    return out
  }

  function getMenuList() {
    var sidebar = findSidebar(getRootVm())
    var items = (sidebar && sidebar.menuItems) || []
    return flatten(items)
  }

  // 读取主题配置（占位文案 / 快捷键自定义）
  function getThemeConfig() {
    try {
      var root = getRootVm()
      if (root && root.$store && root.$store.state && root.$store.state.theme) {
        return root.$store.state.theme.config || {}
      }
    } catch (e) { /* ignore */ }
    return {}
  }

  function defaultPlaceholder() {
    var c = getThemeConfig()
    return c.global_search_placeholder || '搜索菜单、功能、页面...'
  }

  /* ================= 浮层 DOM ================= */
  function ensurePanel() {
    var el = document.getElementById(PANEL_ID)
    if (el) return el
    el = document.createElement('div')
    el.id = PANEL_ID
    el.style.cssText = [
      'position:fixed', 'top:12vh', 'left:50%', 'transform:translateX(-50%)',
      'width:560px', 'max-width:92vw', 'background:#fff', 'border-radius:10px',
      'box-shadow:0 12px 40px rgba(0,0,0,.16)', 'z-index:3000', 'font-size:14px',
      'color:#303133', 'overflow:hidden', 'display:none', 'font-family:inherit',
      'text-align:left'
    ].join(';') + ';'
    el.innerHTML =
      '<div style="display:flex;align-items:center;padding:12px 16px;border-bottom:1px solid #ebeef5;">' +
        '<i class="el-icon-search" style="color:#909399;margin-right:8px;font-size:16px;"></i>' +
        '<input id="' + PANEL_INPUT_ID + '" type="text" autocomplete="off" spellcheck="false" placeholder="' + defaultPlaceholder() + '" style="flex:1;border:none;outline:none;font-size:14px;color:#303133;background:transparent;height:24px;box-sizing:border-box;" />' +
        '<span style="color:#c0c4cc;font-size:12px;border:1px solid #dcdfe6;border-radius:4px;padding:1px 6px;margin-left:8px;flex-shrink:0;">Esc</span>' +
      '</div>' +
      '<div id="' + PANEL_BODY_ID + '" style="max-height:50vh;overflow-y:auto;padding:6px 0;"></div>'
    document.body.appendChild(el)

    var input = el.querySelector('#' + PANEL_INPUT_ID)
    input.addEventListener('input', function () { renderResults(input.value) })
    input.addEventListener('keydown', function (e) {
      if (e.key === 'Escape') { e.stopPropagation(); closePanel(); return }
      if (e.key === 'ArrowDown' || e.key === 'ArrowUp') {
        e.preventDefault()
        moveCursor(e.key === 'ArrowDown' ? 1 : -1)
      }
      if (e.key === 'Enter') { e.preventDefault(); jumpActive() }
    })
    document.addEventListener('mousedown', function (e) {
      var panel = document.getElementById(PANEL_ID)
      if (panel && !panel.contains(e.target) && !isSearchBtn(e.target)) closePanel()
    })
    return el
  }

  function isSearchBtn(target) {
    var n = target
    while (n && n !== document.body) {
      if (n.classList && n.classList.contains('navbar-btn')) {
        if (n.querySelector('.el-icon-search') || n.classList.contains('el-icon-search')) return true
      }
      if (n.classList && n.classList.contains('el-icon-search')) return true
      n = n.parentNode
    }
    return false
  }

  /* ================= 渲染 ================= */
  function buildItemDom(item) {
    var row = document.createElement('div')
    row.style.cssText = 'display:flex;align-items:center;padding:9px 18px;cursor:pointer;border-left:3px solid transparent;'
    row.setAttribute('data-path', item.path)
    row.addEventListener('mouseenter', function () { setActive(row) })
    row.addEventListener('click', function () { goTo(item.path) })

    var icon = document.createElement('i')
    icon.className = item.icon || 'el-icon-menu'
    icon.style.cssText = 'color:#409EFF;margin-right:10px;font-size:16px;flex-shrink:0;'
    row.appendChild(icon)

    var wrap = document.createElement('div')
    wrap.style.cssText = 'flex:1;min-width:0;'
    var title = document.createElement('div')
    title.textContent = item.title
    title.style.cssText = 'font-size:14px;color:#303133;overflow:hidden;text-overflow:ellipsis;white-space:nowrap;'
    var full = document.createElement('div')
    full.textContent = item.full
    full.style.cssText = 'font-size:12px;color:#909399;overflow:hidden;text-overflow:ellipsis;white-space:nowrap;margin-top:2px;'
    wrap.appendChild(title)
    wrap.appendChild(full)
    row.appendChild(wrap)
    return row
  }

  function renderResults(keyword) {
    var body = document.getElementById(PANEL_BODY_ID)
    if (!body) return
    body.innerHTML = ''
    activeList = []
    cursorIndex = -1

    var list = getMenuList()
    var kw = (keyword || '').trim().toLowerCase()

    var matched = list
    if (kw) {
      matched = list.filter(function (m) {
        return m.title.toLowerCase().indexOf(kw) !== -1 || m.full.toLowerCase().indexOf(kw) !== -1 || m.path.toLowerCase().indexOf(kw) !== -1
      })
    }
    if (matched.length === 0) {
      var empty = document.createElement('div')
      empty.textContent = kw ? '未找到与「' + keyword + '」匹配的菜单' : '暂无可搜索的菜单'
      empty.style.cssText = 'text-align:center;color:#909399;padding:28px 0;font-size:13px;'
      body.appendChild(empty)
      return
    }
    matched.slice(0, RESULT_LIMIT).forEach(function (m) {
      var row = buildItemDom(m)
      body.appendChild(row)
      activeList.push(row)
    })
    if (activeList.length > 0) setActive(activeList[0])
  }

  function setActive(row) {
    activeList.forEach(function (r) {
      r.style.backgroundColor = ''
      r.style.borderLeftColor = 'transparent'
    })
    if (!row) return
    row.style.backgroundColor = '#f5f7fa'
    row.style.borderLeftColor = '#409EFF'
    cursorIndex = activeList.indexOf(row)
    var body = document.getElementById(PANEL_BODY_ID)
    if (body && row.scrollIntoView) row.scrollIntoView({ block: 'nearest' })
  }

  function moveCursor(step) {
    if (activeList.length === 0) return
    var next = cursorIndex + step
    if (next < 0) next = activeList.length - 1
    if (next >= activeList.length) next = 0
    setActive(activeList[next])
  }

  function jumpActive() {
    if (cursorIndex >= 0 && activeList[cursorIndex]) {
      var p = activeList[cursorIndex].getAttribute('data-path')
      if (p) goTo(p)
    }
  }

  function goTo(path) {
    closePanel()
    if (/^https?:\/\//.test(path)) { window.open(path, '_blank'); return }
    var root = getRootVm()
    if (root && root.$router) {
      root.$router.push(path).catch(function () {
        window.location.hash = '#/' + path.replace(/^\//, '')
      })
    } else {
      window.location.hash = '#/' + path.replace(/^\//, '')
    }
  }

  /* ================= 开关 ================= */
  function openPanel() {
    var el = ensurePanel()
    el.style.display = 'block'
    var input = el.querySelector('#' + PANEL_INPUT_ID)
    input.value = ''
    input.placeholder = defaultPlaceholder()
    renderResults('')
    input.focus()
  }

  function closePanel() {
    var el = document.getElementById(PANEL_ID)
    if (el) el.style.display = 'none'
  }

  function togglePanel() {
    var el = document.getElementById(PANEL_ID)
    if (el && el.style.display === 'block') closePanel()
    else openPanel()
  }

  /* ================= 快捷键 ================= */
  function parseShortcut(str) {
    // 支持 'Ctrl+K' / 'Ctrl+Shift+F' / 'Alt+K' / 'Meta+K' 等
    if (!str) return null
    var parts = String(str).split('+').map(function (s) { return s.trim().toLowerCase() })
    if (parts.length === 0) return null
    var key = parts.pop()
    if (!key || key.length !== 1) return null
    return { ctrl: parts.indexOf('ctrl') !== -1, shift: parts.indexOf('shift') !== -1, alt: parts.indexOf('alt') !== -1, meta: parts.indexOf('meta') !== -1, key: key }
  }

  function matchShortcut(e, cfg) {
    var shortcut = parseShortcut(cfg.global_search_shortcut)
    if (!shortcut) shortcut = { ctrl: true, shift: false, alt: false, meta: false, key: 'k' }
    var k = (e.key || '').toLowerCase()
    if (k !== shortcut.key) return false
    return !!e.ctrlKey === !!shortcut.ctrl && !!e.shiftKey === !!shortcut.shift && !!e.altKey === !!shortcut.alt && !!e.metaKey === !!shortcut.meta
  }

  document.addEventListener('keydown', function (e) {
    // 输入框中按 Esc 不在此处拦截
    if (e.key === 'Escape') return
    var tag = e.target && e.target.tagName
    if (tag === 'INPUT' || tag === 'TEXTAREA') {
      // 输入框内 Ctrl+K 也允许打开（切到面板）
      if (!(e.ctrlKey || e.metaKey)) return
    }
    if (matchShortcut(e, getThemeConfig())) {
      e.preventDefault()
      e.stopPropagation()
      togglePanel()
    }
  }, true)

  /* ================= 对外接口 ================= */
  window.__scGlobalSearch = function () {
    openPanel()
  }
})()
