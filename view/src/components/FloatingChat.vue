<template>
  <!-- 免认证页面（登录页等）不显示悬浮 AI 聊天入口 -->
  <div v-if="!isLoginPage" class="floating-chat">
    <!-- ===== 悬浮按钮（可拖拽到任意位置；move/up 由 document 级监听接管） ===== -->
    <div
      v-if="!isOpen || isMinimized"
      class="float-btn"
      :style="btnStyle"
      @mousedown="startBtnDrag"
      @click="toggleChat"
    >
      <i class="el-icon-chat-dot-round"></i>
      <span class="float-tip">AI助手</span>
    </div>

    <!-- ===== 聊天窗口 ===== -->
    <div
      v-if="isOpen"
      class="chat-window"
      :style="windowStyle"
    >
      <!-- 顶部标题栏（可拖拽；move/up 由 document 级监听接管，避免鼠标移出中断） -->
      <div
        class="window-header"
        @mousedown="startDrag"
      >
        <span class="header-title"><i class="el-icon-chat-dot-round"></i> AI助手</span>
        <div class="header-actions">
          <i class="el-icon-minus" title="最小化" @click="minimize" @mousedown.stop></i>
          <i class="el-icon-close" title="关闭" @click="closeChat" @mousedown.stop></i>
        </div>
      </div>

      <!-- 主体：内嵌对话中心组件（功能与 /ai/chat/create 完全一致，v1.64.0） -->
      <div class="window-body">
        <ai-chat-create v-if="isOpen" embedded />
      </div>
    </div>
  </div>
</template>

<script>
// 文件：admin/src/components/FloatingChat.vue
// 悬浮 AI 助手：固定在页面右下角，内嵌对话中心组件（create.vue），功能与对话中心完全一致
import AiChatCreate from '../views/ai/chat/create.vue'

export default {
  name: 'FloatingChat',
  components: { AiChatCreate },
  data() {
    return {
      isOpen: false,          // 是否展开聊天窗口
      isMinimized: false,     // 是否最小化
      isDragging: false,      // 是否正在拖拽窗口
      windowPosition: { x: 0, y: 0 }, // 窗口偏移（默认右下角，拖拽后覆盖）
      dragStart: { x: 0, y: 0 },
      dragOffset: { x: 0, y: 0 },
      // 悬浮按钮拖拽
      btnPosition: null,       // 按钮拖拽后的位置 {left, top}（null=默认右下角）
      isBtnDragging: false,   // 是否正在拖拽按钮
      btnDragStart: { x: 0, y: 0 }, // 拖拽起点
      btnDragOrigin: { left: 0, top: 0 }, // 拖拽起始位置
      btnMoved: false         // 拖拽是否超过阈值（区分点击）
    }
  },
  computed: {
    // 免认证页面（登录页等）不显示悬浮 AI 聊天入口
    isLoginPage() { return !!(this.$route.meta && this.$route.meta.noAuth) },
    windowStyle() {
      const base = { zIndex: 999 }
      if (this.windowPosition.x !== 0 || this.windowPosition.y !== 0) {
        return { ...base, left: this.windowPosition.x + 'px', top: this.windowPosition.y + 'px', right: 'auto', bottom: 'auto' }
      }
      return base
    },
    btnStyle() {
      const base = { zIndex: 999 }
      if (this.btnPosition) {
        return { ...base, left: this.btnPosition.left + 'px', top: this.btnPosition.top + 'px', right: 'auto', bottom: 'auto' }
      }
      return base // 默认右下角（CSS right/bottom）
    }
  },
  created() {
    // 恢复按钮拖拽位置
    try {
      const saved = JSON.parse(localStorage.getItem('floating_chat_btn_pos') || 'null')
      if (saved && typeof saved.left === 'number') this.btnPosition = saved
    } catch (e) {}
  },
  beforeDestroy() {
    // 清理 document 拖拽监听，避免组件销毁后残留
    document.removeEventListener('mousemove', this.onDrag)
    document.removeEventListener('mouseup', this.stopDrag)
    document.removeEventListener('mousemove', this.onBtnDrag)
    document.removeEventListener('mouseup', this.stopBtnDrag)
  },
  methods: {
    // ===== 打开/关闭 =====
    toggleChat() {
      // 拖拽后不触发展开（区分点击与拖拽）
      if (this.btnMoved) {
        this.btnMoved = false
        return
      }
      if (this.isOpen && this.isMinimized) {
        this.isMinimized = false
      } else if (!this.isOpen) {
        this.isOpen = true
        this.isMinimized = false
        // 联动：打开时同步当前页面上下文（v1.63.0 上下文感知）
        if (this.$route && this.$route.path) {
          this.$store.dispatch('ai/updatePageContext', { route: this.$route.path })
        }
      }
    },
    minimize() {
      this.isMinimized = true
    },
    closeChat() {
      this.isOpen = false
      this.isMinimized = false
    },
    // ===== 拖拽（mousemove/mouseup 挂 document，鼠标移出元素不中断） =====
    startDrag(e) {
      this.isDragging = true
      this.dragStart = { x: e.clientX, y: e.clientY }
      const rect = e.currentTarget.parentElement.getBoundingClientRect()
      this.dragOffset = { x: rect.left, y: rect.top }
      document.addEventListener('mousemove', this.onDrag)
      document.addEventListener('mouseup', this.stopDrag)
      e.preventDefault()
    },
    onDrag(e) {
      if (!this.isDragging) return
      this.windowPosition = {
        x: this.dragOffset.x + (e.clientX - this.dragStart.x),
        y: this.dragOffset.y + (e.clientY - this.dragStart.y)
      }
    },
    stopDrag() {
      this.isDragging = false
      document.removeEventListener('mousemove', this.onDrag)
      document.removeEventListener('mouseup', this.stopDrag)
    },
    // ===== 悬浮按钮拖拽（mousemove/mouseup 挂 document，鼠标移出按钮不中断） =====
    startBtnDrag(e) {
      // 仅左键
      if (e.button !== 0) return
      this.isBtnDragging = true
      this.btnMoved = false
      this.btnDragStart = { x: e.clientX, y: e.clientY }
      // 记录起始位置（默认右下角 → 取当前按钮实际位置）
      const rect = e.currentTarget.getBoundingClientRect()
      this.btnDragOrigin = {
        left: this.btnPosition ? this.btnPosition.left : rect.left,
        top: this.btnPosition ? this.btnPosition.top : rect.top
      }
      document.addEventListener('mousemove', this.onBtnDrag)
      document.addEventListener('mouseup', this.stopBtnDrag)
      e.preventDefault()
    },
    onBtnDrag(e) {
      if (!this.isBtnDragging) return
      const dx = e.clientX - this.btnDragStart.x
      const dy = e.clientY - this.btnDragStart.y
      // 超过 5px 视为拖拽（非点击）
      if (!this.btnMoved && Math.abs(dx) + Math.abs(dy) > 5) this.btnMoved = true
      // 新位置（限制在视口内）
      const left = Math.max(0, Math.min(window.innerWidth - 56, this.btnDragOrigin.left + dx))
      const top = Math.max(0, Math.min(window.innerHeight - 56, this.btnDragOrigin.top + dy))
      this.btnPosition = { left, top }
    },
    stopBtnDrag() {
      this.isBtnDragging = false
      document.removeEventListener('mousemove', this.onBtnDrag)
      document.removeEventListener('mouseup', this.stopBtnDrag)
      // 持久化按钮位置（刷新后保持）
      if (this.btnPosition) {
        try { localStorage.setItem('floating_chat_btn_pos', JSON.stringify(this.btnPosition)) } catch (e) {}
      }
    }
  }
}
</script>

<style scoped>
/* 悬浮按钮 */
.float-btn {
  position: fixed;
  right: 20px;
  bottom: 80px;
  width: 56px;
  height: 56px;
  border-radius: 50%;
  background: linear-gradient(135deg, #409eff, #337ecc);
  color: #fff;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 24px;
  cursor: pointer;
  box-shadow: 0 4px 12px rgba(64, 158, 255, 0.4);
  z-index: 999;
  transition: transform 0.2s;
}
.float-btn:hover { transform: scale(1.08); }
.float-tip {
  position: absolute;
  right: 68px;
  top: 50%;
  transform: translateY(-50%);
  background: rgba(0, 0, 0, 0.75);
  color: #fff;
  font-size: 12px;
  padding: 4px 10px;
  border-radius: 4px;
  white-space: nowrap;
  opacity: 0;
  pointer-events: none;
  transition: opacity 0.2s;
}
.float-btn:hover .float-tip { opacity: 1; }

/* 聊天窗口 */
.chat-window {
  position: fixed;
  right: 20px;
  bottom: 80px;
  width: 900px;
  height: 600px;
  max-width: calc(100vw - 40px);
  max-height: calc(100vh - 120px);
  background: #fff;
  border-radius: 12px;
  box-shadow: 0 8px 32px rgba(0, 0, 0, 0.25);
  display: flex;
  flex-direction: column;
  overflow: hidden;
}
.window-header {
  height: 48px;
  background: linear-gradient(135deg, #409eff, #337ecc);
  color: #fff;
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 0 14px;
  cursor: move;
  flex-shrink: 0;
}
.header-title { font-weight: 600; font-size: 14px; }
.header-actions i {
  margin-left: 10px;
  cursor: pointer;
  font-size: 16px;
  opacity: 0.85;
}
.header-actions i:hover { opacity: 1; }

/* 主体：内嵌对话中心组件（flex column 撑满） */
.window-body { display: flex; flex-direction: column; flex: 1; overflow: hidden; min-height: 0; }

/* 拖拽区域禁止文本选择，避免拖拽过程中被选中文本干扰导致中断 */
.float-btn, .window-header { user-select: none; -webkit-user-select: none; }
</style>
