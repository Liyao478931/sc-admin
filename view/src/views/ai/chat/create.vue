<!-- 文件：admin/src/views/ai/chat/create.vue -->
<template>
  <div class="chat-page" :class="{ 'chat-page-embedded': embedded }">
    <!-- 顶部会话信息栏 -->
    <div class="chat-header">
      <div class="header-left">
        <el-button v-if="!embedded" size="mini" icon="el-icon-back" @click="goHistory">返回</el-button>
        <span class="chat-title">{{ sessionTitle }}</span>
        <!-- 智能体选择器 -->
        <el-select v-if="agentOptions.length" v-model="selectedAgentId" placeholder="选择智能体" filterable size="mini"
          style="width:180px" :disabled="hasMessages" @change="handleAgentChange">
          <el-option v-for="agent in agentOptions" :key="agent.id" :label="agent.agent_name" :value="agent.agent_id">
            <span>{{ agent.agent_name }}</span>
            <span class="agent-opt-desc" :title="agent.description">{{ agent.description || '暂无描述' }}</span>
          </el-option>
        </el-select>
        <el-button v-if="currentAgent" type="text" size="mini" icon="el-icon-info" @click="showAgentDetail">详情</el-button>
      </div>
      <div class="header-right">
        <el-popover v-model="toolMenuVisible" placement="bottom-end" trigger="click" :width="260" popper-class="tool-popover">
          <div class="tool-menu">
            <div v-for="tool in sessionTools" :key="tool.tool_id" class="tool-menu-item">
              <span class="tool-menu-name" :title="tool.tool_name">{{ tool.tool_display_name || tool.tool_name }}</span>
              <el-switch :value="!!tool.enabled" size="mini" @change="val => toggleTool(tool, val)" />
            </div>
            <div v-if="!sessionTools.length" class="tool-menu-empty">暂无可用工具</div>
          </div>
          <span slot="reference" class="tool-trigger">
            <i class="el-icon-s-tools"></i>
            可用工具 {{ enabledToolsCount }}/{{ sessionTools.length }}
            <i class="el-icon-arrow-down el-icon--right" :class="{ 'arrow-reverse': toolMenuVisible }"></i>
          </span>
        </el-popover>
        <el-tag size="mini" :type="isGenerating ? 'warning' : 'success'">{{ isGenerating ? '对话中' : '已结束' }}</el-tag>
        <el-tag size="mini" type="info">调用 {{ toolCallCount }} 次 · 成功 {{ toolSuccessCount }} 次</el-tag>
        <el-tag size="mini" type="info">Token {{ tokenUsed }}</el-tag>
      </div>
    </div>

    <!-- 当前智能体信息 -->
    <div v-if="currentAgent" class="agent-info">
      <span class="agent-name"><i class="el-icon-user"></i> {{ currentAgent.agent_name }}</span>
      <span class="agent-desc">{{ currentAgent.description || '暂无描述' }}</span>
      <span class="agent-tools">工具 {{ (currentAgent.tool_ids || []).length }} 个</span>
      <span class="agent-knowledge">知识库 {{ (currentAgent.knowledge_base_ids || []).length }} 个</span>
    </div>

    <!-- 上下文感知区（v1.63.0）：上下文栏 + 推荐问题 + 快捷操作 -->
    <div v-if="hasContext" class="ctx-area">
      <context-bar :context="pageContext" :data-summary="dataSummary" :filters="filters" :entity="entity" @clear="clearContext" />
      <suggested-questions :questions="suggestedQuestions" @ask="askSuggested" />
      <quick-actions :actions="quickActions" :loading-map="actionsLoading" @run="executeQuickAction" />
    </div>

    <!-- 中部消息列表 -->
    <div class="chat-body" ref="chatBody">
      <div v-if="!messages.length" class="chat-empty">
        <i class="el-icon-chat-dot-round empty-icon"></i>
        <p>开始与 AI 对话，它可以帮你查询设备、隐患、待办等</p>
        <div class="quick-list">
          <el-tag v-for="(q, i) in quickPrompts" :key="i" class="quick-tag" @click="fillPrompt(q)">{{ q }}</el-tag>
        </div>
      </div>

      <div v-for="(msg, idx) in messages" :key="msg.message_id || idx" class="msg-row" :class="msg.role">
        <!-- 用户消息 -->
        <div v-if="msg.role === 'user'" class="bubble user-bubble">{{ msg.content }}</div>

        <!-- AI 消息 -->
        <div v-else-if="msg.role === 'assistant'" class="bubble ai-bubble">
          <div class="ai-bubble-head">
            <i :class="msg.favorited ? 'el-icon-star-on favorite-on' : 'el-icon-star-off favorite-off'"
              class="fav-star" @click="handleFavorite(msg)" :title="msg.favorited ? '已收藏' : '收藏'"></i>
          </div>
          <div v-if="msg.reasoning_content" class="reasoning-block">
            <div class="reasoning-head" @click="msg.reasoningOpen = !msg.reasoningOpen">
              <i class="el-icon-cpu"></i>
              <span>思考过程</span>
              <i class="el-icon-arrow-down" :class="{ rotated: msg.reasoningOpen }"></i>
            </div>
            <div v-if="msg.reasoningOpen" class="reasoning-body">{{ msg.reasoning_content }}</div>
          </div>
          <!-- 工具调用的 assistant 消息（content=null+tool_calls）→ 显示工具请求卡片 -->
          <div v-if="msg.tool_calls && msg.tool_calls.length" class="tool-card">
            <div class="tool-head">
              <i class="el-icon-set-up"></i>
              <span class="tool-name">{{ toolCallsName(msg.tool_calls) }}</span>
            </div>
          </div>
          <ai-markdown v-if="msg.content" :content="msg.content" />
          <!-- 引用来源 + 反馈（v1.63.0） -->
          <sources-display v-if="msg.sources && msg.sources.length" :sources="msg.sources" @open="onSourcesOpen" />
          <feedback-buttons
            v-if="msg.message_id && !msg.streaming"
            :feedback="feedbackMap[msg.message_id] || ''"
            :regenerating="regeneratingMsgId === msg.message_id"
            @like="submitFeedback(msg, 'like')"
            @dislike="submitFeedback(msg, 'dislike')"
            @regenerate="regenerateMessage(msg)"
            @copy="copyMessage(msg.content)"
            @share="shareMessage(msg)" />
        </div>

        <!-- 工具确认请求消息（内联卡片，替代模态弹窗，移动端更友好） -->
        <div v-else-if="msg.role === 'tool_confirm'" class="bubble tool-confirm-card">
          <div class="tc-head"><i class="el-icon-warning"></i> AI 请求执行【{{ toolConfirmDisplayName(msg.tool) }}】</div>
          <div class="tc-desc">{{ msg.arguments && msg.arguments.description ? '说明：' + msg.arguments.description : '该操作属于高风险操作，请确认是否执行？' }}</div>
          <div class="tc-actions">
            <el-button size="mini" type="warning" @click="doConfirmTool(true)">确认执行</el-button>
            <el-button size="mini" @click="doConfirmTool(false)">取消</el-button>
          </div>
        </div>

        <!-- 工具调用消息 -->
        <div v-else-if="msg.role === 'tool'" class="tool-card">
          <div class="tool-head">
            <i class="el-icon-set-up"></i>
            <span class="tool-name">{{ toolName(msg) }}</span>
            <el-tag size="mini" :type="msg.status === 'error' ? 'danger' : 'success'">
              {{ msg.status === 'error' ? '失败' : '成功' }}
            </el-tag>
            <span v-if="msg.tool_calls && msg.tool_calls.elapsed" class="tool-elapsed">{{ msg.tool_calls.elapsed }}</span>
          </div>
          <div v-if="msg.content && msg.tool_calls && msg.tool_calls.result" class="tool-result">
            结果：{{ formatResultSummary(msg.tool_calls.result) }}
          </div>
          <div v-if="msg.status === 'error'" class="tool-retry">
            <el-button size="mini" type="primary" icon="el-icon-refresh" @click="retryToolMsg(msg)">重试</el-button>
          </div>
        </div>

        <!-- AI 思考中加载动画 -->
        <div v-if="isGenerating && idx === messages.length - 1 && msg.role === 'user'" class="bubble ai-bubble typing">
          <span class="dot"></span><span class="dot"></span><span class="dot"></span>
        </div>
      </div>
    </div>

    <!-- 底部输入区域 -->
    <div class="chat-footer">
      <div class="quick-row" v-if="!messages.length">
        <el-tag v-for="(q, i) in quickPrompts" :key="i" class="quick-tag-sm" @click="fillPrompt(q)">{{ q }}</el-tag>
      </div>
      <div class="input-row">
        <el-input
          ref="chatInput"
          type="textarea"
          :autosize="{ minRows: 1, maxRows: 6 }"
          :placeholder="isGenerating ? 'AI 正在回复...' : '输入你的问题，Enter 发送，Shift+Enter 换行'"
          v-model="inputText"
          :maxlength="10000"
          :disabled="isGenerating"
          @keydown.enter.native.prevent="handleEnter"
        />
        <div class="input-actions">
          <span class="char-count">{{ inputText.length }}/10000</span>
          <!-- 语音输入（v1.68.0，浏览器 Web Speech API） -->
          <el-tooltip :content="listening ? '正在聆听...' : '语音输入'" placement="top">
            <i v-if="speechSupported" class="el-icon-microphone voice-btn" :class="{ listening: listening }" @click="toggleVoice"></i>
          </el-tooltip>
          <el-button v-if="isGenerating" type="danger" size="small" icon="el-icon-video-pause" @click="stopGenerating">停止</el-button>
          <el-button v-else type="primary" size="small" icon="el-icon-s-promotion" :disabled="!inputText.trim()" @click="handleSend">发送</el-button>
          <el-button size="small" icon="el-icon-delete" @click="clearChat">清空</el-button>
        </div>
      </div>
    </div>

    <!-- 收藏确认弹窗 -->
    <el-dialog title="收藏问答" :visible.sync="favoriteDialogVisible" width="520px" top="15vh">
      <div v-if="favoriteTarget" class="fav-preview">
        <div class="fav-preview-q"><b>问题：</b>{{ favoriteTarget.prevQuestion || '(未获取到问题)' }}</div>
        <div class="fav-preview-a"><b>回答：</b>{{ truncateText(favoriteTarget.content, 120) }}</div>
      </div>
      <el-form label-width="70px" size="small" style="margin-top:12px;">
        <el-form-item label="分类">
          <el-select v-model="favoriteCategoryId" style="width:100%" placeholder="选择分类">
            <el-option v-for="c in favoriteCategories" :key="c.id" :label="c.category_name" :value="c.id" />
          </el-select>
        </el-form-item>
        <el-form-item label="备注">
          <el-input v-model="favoriteNote" maxlength="255" placeholder="选填备注" />
        </el-form-item>
      </el-form>
      <span slot="footer">
        <el-button size="small" @click="favoriteDialogVisible = false">取消</el-button>
        <el-button size="small" type="warning" icon="el-icon-star-on" @click="confirmFavorite">确认收藏</el-button>
      </span>
    </el-dialog>
    <!-- 工具调用确认弹窗 -->
    <el-dialog title="操作确认" :visible.sync="confirmVisible" width="520px" top="20vh">
      <div v-if="pendingConfirm" class="confirm-body">
        <div class="confirm-tool"><i class="el-icon-warning"></i> AI 请求执行【{{ confirmToolName }}】</div>
        <div class="confirm-desc">
          {{ pendingConfirm.arguments && pendingConfirm.arguments.description ? '说明：' + pendingConfirm.arguments.description : '该操作属于高风险写操作，请确认是否执行？' }}
        </div>
      </div>
      <span slot="footer">
        <el-button size="small" @click="doConfirmTool(false)">取消</el-button>
        <el-button size="small" type="warning" @click="doConfirmTool(true)">确认执行</el-button>
      </span>
    </el-dialog>
    <!-- 智能体详情弹窗 -->
    <el-dialog title="智能体详情" :visible.sync="agentDetailVisible" width="620px" top="10vh">
      <div v-if="agentDetail">
        <el-descriptions :column="2" size="small" border>
          <el-descriptions-item label="名称">{{ agentDetail.agent_name }}</el-descriptions-item>
          <el-descriptions-item label="关联模型">{{ agentDetail.model_name || ('模型#' + agentDetail.model_id) }}</el-descriptions-item>
          <el-descriptions-item label="描述" :span="2">{{ agentDetail.description || '-' }}</el-descriptions-item>
        </el-descriptions>
        <div class="ad-block">
          <div class="ad-label">人设（系统提示词）</div>
          <pre class="ad-pre">{{ agentDetail.system_prompt }}</pre>
        </div>
        <div class="ad-block">
          <div class="ad-label">绑定知识库（{{ (agentDetail.knowledge_bases || []).length }}）</div>
          <div v-if="agentDetail.knowledge_bases && agentDetail.knowledge_bases.length" class="ad-tags">
            <el-tag v-for="kb in agentDetail.knowledge_bases" :key="kb.id" size="mini" class="ad-tag">{{ kb.kb_name }}</el-tag>
          </div>
          <span v-else class="ad-none">未绑定知识库</span>
        </div>
        <div class="ad-block">
          <div class="ad-label">绑定工具（{{ (agentDetail.tools || []).length }}）</div>
          <div v-if="agentDetail.tools && agentDetail.tools.length" class="ad-tags">
            <el-tag v-for="t in agentDetail.tools" :key="t.id" size="mini" type="success" class="ad-tag">{{ t.tool_display_name || t.tool_name }}</el-tag>
          </div>
          <span v-else class="ad-none">未绑定工具</span>
        </div>
      </div>
    </el-dialog>
  </div>
</template>

<script>
import AiMarkdown from '@/components/AiMarkdown.vue'
import ContextBar from '@/components/ai/ContextBar.vue'
import SuggestedQuestions from '@/components/ai/SuggestedQuestions.vue'
import QuickActions from '@/components/ai/QuickActions.vue'
import SourcesDisplay from '@/components/ai/SourcesDisplay.vue'
import FeedbackButtons from '@/components/ai/FeedbackButtons.vue'
import { mapState } from 'vuex'
import { createAiSession, getAiMessages, deleteAiSession, confirmAiTool, getAiSessionTools, toggleAiSessionTool, retryAiTool, executeQuickAction, submitMessageFeedback, streamRegenerate } from '@/api/aiChat'
import { addAiFavorite, getAiFavoriteCategories, getAiFavoriteList } from '@/api/aiFavorite'
import { getAiAgentOptions, getAiAgentDetailForChat, getAiAgentDetail } from '@/api/aiAgent'
import { getToken } from '@/utils/auth'

export default {
  name: 'AiChatCreate',
  components: { AiMarkdown, ContextBar, SuggestedQuestions, QuickActions, SourcesDisplay, FeedbackButtons },
  props: {
    /** 嵌入模式（悬浮窗口内嵌渲染）：布局自适应 + 隐藏返回按钮 + 忽略 URL 会话参数 */
    embedded: { type: Boolean, default: false }
  },
  data () {
    return {
      sessionId: '',
      sessionTitle: '新对话',
      sessionAgentId: '',
      agentOptions: [],
      selectedAgentId: '',
      currentAgent: null,
      agentDetail: null,
      agentDetailVisible: false,
      messages: [],
      inputText: '',
      isGenerating: false,
      toolCallCount: 0,
      toolSuccessCount: 0,
      tokenUsed: 0,
      sessionTools: [],
      toolMenuVisible: false,
      confirmVisible: false,
      pendingConfirm: null,
      abortController: null,
      // 打字机状态
      typeTimer: null,
      typeBuffer: '',
      typeMsg: null,
      typeSpeed: 15, // 每字符间隔 ms
      // 收藏状态
      favoriteCategories: [],
      favoriteDialogVisible: false,
      favoriteTarget: null,
      favoriteCategoryId: null,
      favoriteNote: '',
      favoritedMessageIds: [],
      quickPrompts: [
        '查询设备 EQP-2026-001 的信息',
        '帮我查一下本月新增的隐患',
        '创建一个维修工单',
        '查询我的待办事项',
        '帮我看看最近一周的考勤情况'
      ],
      // 上下文感知（v1.63.0）
      actionsLoading: {},
      feedbackMap: {},
      regeneratingMsgId: '',
      // 语音输入（v1.68.0）
      speechSupported: typeof window !== 'undefined' && !!(window.SpeechRecognition || window.webkitSpeechRecognition),
      listening: false,
      recognition: null
    }
  },
  computed: {
    ...mapState('ai', ['pageContext', 'dataSummary', 'filters', 'entity']),
    /** 当前会话是否已有消息 */
    hasMessages () {
      return this.messages.length > 0
    },
    /** 上下文感知：页面是否在映射配置中 */
    hasContext () {
      return !!(this.pageContext && this.pageContext.pageTitle)
    },
    /** 推荐问题（来自页面上下文配置） */
    suggestedQuestions () {
      return (this.pageContext && this.pageContext.suggestedQuestions) || []
    },
    /** 快捷操作（来自页面上下文配置） */
    quickActions () {
      return (this.pageContext && this.pageContext.quickActions) || []
    },
    /** 组装发送给后端的 context（页面 + 数据概要 + 实体） */
    contextPayload () {
      if (!this.pageContext) return null
      return {
        page: { route: this.pageContext.route, title: this.pageContext.pageTitle },
        data_summary: this.dataSummary || {},
        entity: this.entity || null
      }
    },
    /** 当前会话启用工具数 */
    enabledToolsCount () {
      return (this.sessionTools || []).filter(t => !!t.enabled).length
    },
    /** 待确认工具显示名 */
    confirmToolName () {
      const pending = this.pendingConfirm || {}
      const name = pending.tool || ''
      const map = { create_repair_order: '创建维修工单', create_hazard: '创建隐患登记', send_notification: '发送通知' }
      return map[name] || name
    }
  },
  async created () {
    // 上下文感知：路由守卫 afterEach 已维护，此处直开/刷新时补充一次
    this.$store.dispatch('ai/updatePageContext', { route: this.$route.path })
    this.loadFavoriteCategories()
    await this.loadAgentOptions()
    // 嵌入模式（悬浮窗口）忽略 URL 的 session_id/ask 参数，避免与宿主页面路由误关联
    const qs = this.embedded ? '' : (this.$route.query.session_id || '')
    if (qs) {
      // 继续历史会话（按会话记录的 agent_id 恢复智能体）
      this.sessionId = qs
      await this.loadSession(qs)
    } else {
      await this.initSession(this.selectedAgentId)
    }
    // 收藏"继续提问"：若携带 ask 参数则填入输入框（新会话）
    const ask = this.embedded ? '' : (this.$route.query.ask || '')
    if (ask && !qs) {
      this.inputText = String(ask)
    }
  },
  beforeDestroy () {
    this.stopGenerating()
  },
  methods: {
    /** 加载启用智能体下拉，确定初始选中（URL > localStorage > 第一个；无启用智能体则隐藏选择器用默认助手） */
    async loadAgentOptions () {
      try {
        const r = await getAiAgentOptions()
        if (r.code === 0) this.agentOptions = Array.isArray(r.data) ? r.data : (r.data.list || [])
      } catch (e) { this.agentOptions = [] }
      const urlAgent = (this.$route.query && this.$route.query.agent_id) || ''
      let chosen = urlAgent || localStorage.getItem('sc_last_agent_id') || ''
      // 嵌入模式（悬浮窗口）：默认通用助手（绑定全部工具），避免复用对话中心智能体记忆导致工具不足
      if (this.embedded) {
        const general = this.agentOptions.find(a => a.agent_id === 'sys_agent_general')
        chosen = general ? general.agent_id : (this.agentOptions.length ? this.agentOptions[0].agent_id : '')
      } else if (chosen && !this.agentOptions.some(a => a.agent_id === chosen)) {
        chosen = ''
      }
      if (!chosen && this.agentOptions.length) chosen = this.agentOptions[0].agent_id
      this.selectedAgentId = chosen
      if (chosen) {
        // 嵌入模式不写入智能体记忆，避免污染对话中心默认选择
        if (!this.embedded) localStorage.setItem('sc_last_agent_id', chosen)
        this.loadAgentConfig()
      }
    },
    /** 加载当前智能体对话配置（人设/知识库/工具） */
    async loadAgentConfig () {
      if (!this.selectedAgentId) { this.currentAgent = null; return }
      try {
        const r = await getAiAgentDetailForChat(this.selectedAgentId)
        if (r.code === 0) this.currentAgent = r.data
        else this.currentAgent = null
      } catch (e) { this.currentAgent = null }
    },
    /** 智能体切换：有消息时确认（创建新会话），无消息直接切换 */
    async handleAgentChange (val) {
      if (this.hasMessages) {
        const c = await this.$confirm('切换智能体将创建新会话，是否继续？', '切换确认', { type: 'warning' }).catch(() => false)
        if (!c) { this.selectedAgentId = this.sessionAgentId || ''; return }
      }
      localStorage.setItem('sc_last_agent_id', val || '')
      this.messages = []
      this.toolCallCount = 0
      this.toolSuccessCount = 0
      this.tokenUsed = 0
      await this.initSession(val)
    },
    /** 查看智能体详情（完整配置） */
    showAgentDetail () {
      const row = this.agentOptions.find(a => a.agent_id === this.selectedAgentId)
      if (!row) return
      this.loadAgentDetail(row.id)
    },
    async loadAgentDetail (id) {
      try {
        const r = await getAiAgentDetail(id)
        if (r.code === 0) { this.agentDetail = r.data; this.agentDetailVisible = true }
      } catch (e) {}
    },
    async initSession (agentId) {
      try {
        const r = await createAiSession(agentId || undefined)
        if (r.code === 0) {
          this.sessionId = r.data.session_id
          this.sessionTitle = r.data.title
          this.sessionAgentId = r.data.agent_id || ''
          if (this.sessionAgentId) this.selectedAgentId = this.sessionAgentId
          this.loadSessionTools()
          this.loadAgentConfig()
        }
      } catch (e) {}
    },
    async loadSession (sessionId) {
      try {
        const r = await getAiMessages(sessionId)
        if (r.code === 0) {
          this.sessionTitle = (r.data.session && r.data.session.title) || '历史对话'
          // 恢复会话关联的智能体
          this.sessionAgentId = (r.data.session && r.data.session.agent_id) || ''
          if (this.sessionAgentId && this.agentOptions.some(a => a.agent_id === this.sessionAgentId)) {
            this.selectedAgentId = this.sessionAgentId
          }
          const raw = r.data.list || []
          let lastQuestion = ''
          this.messages = raw.map(m => {
            let tc = m.tool_calls
            if (typeof tc === 'string') { try { tc = JSON.parse(tc) } catch (e) { tc = null } }
            const item = { role: m.role, content: m.content || '', message_id: m.message_id, tool_calls: tc, status: m.status, reasoning_content: m.reasoning_content || '' }
            if (m.role === 'user') lastQuestion = m.content || ''
            if (m.role === 'assistant') item.prevQuestion = lastQuestion
            return item
          })
          this.toolCallCount = (r.data.session && r.data.session.tool_call_count) || 0
          this.tokenUsed = (r.data.session && r.data.session.total_tokens) || 0
          this.scrollToBottom()
          this.loadFavoriteStatus()
          this.loadSessionTools()
          this.loadAgentConfig()
        }
      } catch (e) {}
    },
    fillPrompt (q) {
      this.inputText = q
      if (this.$refs.chatInput) this.$refs.chatInput.focus()
    },
    handleEnter (e) {
      if (e.shiftKey) return // Shift+Enter 换行
      this.handleSend()
    },
    async handleSend () {
      const msg = this.inputText.trim()
      if (!msg || this.isGenerating) return
      if (!this.sessionId) { this.$message.warning('会话初始化中，请稍候'); return }
      this.inputText = ''
      // 网络异常自动重试（最多 3 次）
      for (let attempt = 1; attempt <= 3; attempt++) {
        const ok = await this.doSend(msg, attempt)
        if (ok) return
        if (attempt < 3) {
          this.$message.info(`网络异常，正在重试（${attempt}/3）...`)
          await new Promise(resolve => setTimeout(resolve, 800))
        } else {
          this.$message.error('网络异常，请稍后重试')
        }
      }
    },
    async doSend (msg, attempt) {
      this.messages.push({ role: 'user', content: msg, message_id: 'u_' + Date.now() + '_' + attempt })
      if (this.sessionTitle === '新对话') {
        this.sessionTitle = msg.length > 20 ? msg.slice(0, 20) + '...' : msg
      }
      this.scrollToBottom()

      this.isGenerating = true
      this.abortController = new AbortController()
      let watchdog = null

      try {
        // 流式请求（fetch + SSE）
        const token = getToken() || ''
        const payload = { session_id: this.sessionId, message: msg }
        if (this.hasContext && this.contextPayload) payload.context = this.contextPayload
        const resp = await fetch('/api/ai/chat/send', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json', 'Authorization': 'Bearer ' + token },
          body: JSON.stringify(payload),
          signal: this.abortController.signal
        })
        if (!resp.ok) return false

        const reader = resp.body.getReader()
        // 看门狗：SSE 流若长时间未结束（如后端响应异常/连接未终止），强制终止避免界面卡死
        watchdog = setTimeout(() => {
          if (this.abortController) {
            this.abortController.abort()
            this.$message.warning('响应超时，已停止等待')
          }
        }, 45000)
        const decoder = new TextDecoder()
        let buffer = ''
        let aiFullText = '' // 完整文本（打字机缓冲）
        let aiMsgId = 'a_' + Date.now() + '_' + attempt
        let hasAi = false
        let toolLogs = [] // 本次工具日志
        let pendingConfirm = null // 待确认工具

        // 预置 AI 消息占位（记录问题供收藏）
        const aiMsg = { role: 'assistant', content: '', message_id: aiMsgId, streaming: true, prevQuestion: msg, favorited: this.favoritedMessageIds.includes(aiMsgId) }
        this.messages.push(aiMsg)
        this.scrollToBottom()

        while (true) {
          const { done, value } = await reader.read()
          if (done) break
          buffer += decoder.decode(value, { stream: true })
          const lines = buffer.split('\n')
          buffer = lines.pop()

          for (const line of lines) {
            const t = line.trim()
            if (!t.startsWith('data: ')) continue
            let data
            try { data = JSON.parse(t.slice(6)) } catch (e) { continue }
            if (data.type === 'text') {
              hasAi = true
              aiFullText = data.content || ''
              if (data.reasoning_content) aiMsg.reasoning_content = data.reasoning_content
              this.startTyping(aiMsg, aiFullText)
            } else if (data.type === 'tool_logs') {
              toolLogs = data.logs || []
              this.showToolLogs(toolLogs)
              this.toolSuccessCount += (toolLogs || []).filter(l => l.status === 'success').length
            } else if (data.type === 'tool_calls') {
              this.toolCallCount = data.count || 0
            } else if (data.type === 'tool_confirm') {
              // 高风险工具待确认：保留有文本内容的占位消息（AI 确认请求文字），否则移除
              pendingConfirm = { tool: data.tool, arguments: data.arguments }
              this.pendingConfirm = pendingConfirm
              if (!aiMsg.content) {
                this.messages = this.messages.filter(m => m.message_id !== aiMsgId)
              }
              this.messages.push({ role: 'tool_confirm', tool: data.tool, arguments: data.arguments, message_id: 'cf_' + Date.now() + '_' + attempt })
            } else if (data.type === 'error') {
              this.$message.error(data.message || '请求失败')
              aiMsg.content = '⚠️ ' + (data.message || '请求失败')
              if (data.tool_logs) this.showToolLogs(data.tool_logs)
            } else if (data.type === 'done') {
              // 回填真实 assistant 消息 ID（供反馈/重新生成使用，v1.63.0）
              if (data.message_id && aiMsg.message_id.startsWith('a_')) aiMsg.message_id = data.message_id
              break
            }
          }
        }

        // 打字机持续播放至完成（不强制截断，保留逐字打印效果）

        // 若有待确认工具：已插入确认卡片，直接结束本次
        if (pendingConfirm) {
          return true
        }

        // 引用来源：本次成功调用的工具（v1.63.0）
        if (aiMsg.content) {
          const srcs = (toolLogs || []).filter(l => l.status === 'success').map(l => ({
            type: 'data', title: l.name || '数据来源', source: 'AI 工具'
          }))
          if (srcs.length) aiMsg.sources = srcs
        }

        // 收起 AI 消息（若无内容则移除占位）
        if (!hasAi && aiMsg.content === '') {
          this.messages = this.messages.filter(m => m.message_id !== aiMsgId)
        } else {
          aiMsg.streaming = false
        }
        this.tokenUsed += Math.ceil((aiFullText.length || 0) / 2)
        return true
      } catch (e) {
        if (e.name === 'AbortError') {
          this.$message.info('已停止生成')
          return true
        }
        this.stopTyping()
        // 移除未完成的 AI 占位
        this.messages = this.messages.filter(m => !m.streaming)
        return false
      } finally {
        if (watchdog) clearTimeout(watchdog)
        this.isGenerating = false
        this.abortController = null
        this.scrollToBottom()
      }
    },
    /** 打开工具调用确认弹窗（展示工具名/参数详情） */
    confirmToolDialog (pending) {
      this.pendingConfirm = pending
      this.confirmVisible = true
    },
    /** 确认/取消工具调用 */
    async doConfirmTool (confirmed) {
      const pending = this.pendingConfirm
      this.confirmVisible = false
      this.pendingConfirm = null
      if (!pending || !this.sessionId) return
      try {
        const r = await confirmAiTool(this.sessionId, confirmed ? 'confirm' : 'reject')
        if (r.code === 0) this.$message.success(confirmed ? '操作已执行' : '已取消该操作')
      } catch (e) {}
      await this.reloadMessages()
    },
    /** 重新拉取会话消息与统计 */
    async reloadMessages () {
      if (!this.sessionId) return
      try {
        const r = await getAiMessages(this.sessionId)
        if (r.code === 0) {
          this.messages = (r.data.list || []).map(m => {
            let tc = m.tool_calls
            if (typeof tc === 'string') { try { tc = JSON.parse(tc) } catch (e) { tc = null } }
            return { role: m.role, content: m.content || '', message_id: m.message_id, tool_calls: tc, status: m.status, reasoning_content: m.reasoning_content || '' }
          })
          this.toolCallCount = (r.data.session && r.data.session.tool_call_count) || 0
          this.tokenUsed = (r.data.session && r.data.session.total_tokens) || 0
          this.loadSessionTools()
          this.scrollToBottom()
        }
      } catch (e) {}
    },
    /** 加载会话可用工具与统计 */
    async loadSessionTools () {
      if (!this.sessionId) return
      try {
        const r = await getAiSessionTools(this.sessionId)
        if (r.code === 0) {
          this.sessionTools = r.data.list || []
          const st = r.data.stats || {}
          this.toolCallCount = st.tool_call_count || 0
          this.toolSuccessCount = st.tool_success_count || 0
        }
      } catch (e) {}
    },
    /** 切换会话工具启用状态（实时生效，仅当前会话） */
    async toggleTool (tool, val) {
      const enabled = !!val
      const prev = tool.enabled
      tool.enabled = enabled ? 1 : 0
      try {
        const r = await toggleAiSessionTool(this.sessionId, tool.tool_id, enabled)
        if (r.code !== 0) {
          tool.enabled = prev
          this.$message.error(r.msg || '切换失败')
        } else {
          this.$message.success(enabled ? '已启用' : '已停用')
        }
      } catch (e) {
        tool.enabled = prev
      }
    },
    /** 重试失败的工具调用 */
    async retryToolMsg (msg) {
      if (!this.sessionId || !msg.message_id) return
      try {
        const r = await retryAiTool(this.sessionId, msg.message_id)
        if (r.code === 0) {
          this.$message.success('重试完成')
          await this.reloadMessages()
        } else {
          this.$message.error(r.msg || '重试失败')
        }
      } catch (e) {}
    },
    // ============ 打字机 ============
    /** 开始逐字渲染（自适应速度：长文本加快，避免等待过久） */
    startTyping (msg, fullText) {
      // 先补全上一条未打完的消息，避免切换后残留半截
      if (this.typeMsg && this.typeBuffer && this.typeMsg !== msg) {
        this.typeMsg.content = this.typeBuffer
        this.scrollToBottom()
      }
      this.stopTyping()
      this.typeMsg = msg
      this.typeBuffer = fullText
      msg.content = ''
      const steps = Math.max(1, Math.ceil(fullText.length / 2))
      // 目标总时长约 2.5s，单步间隔 4~30ms
      const interval = Math.max(4, Math.min(30, Math.round(2500 / steps)))
      const step = () => {
        if (!this.typeMsg) return
        const cur = this.typeMsg.content.length
        if (cur < this.typeBuffer.length) {
          // 每次追加 2 个字符，形成打字机节奏
          this.typeMsg.content = this.typeBuffer.slice(0, cur + 2)
          this.scrollToBottom()
        } else {
          this.stopTyping()
          return
        }
        this.typeTimer = setTimeout(step, interval)
      }
      this.typeTimer = setTimeout(step, interval)
    },
    /** 立即完成打字 */
    finishTyping () {
      if (this.typeMsg && this.typeBuffer) {
        this.typeMsg.content = this.typeBuffer
        this.scrollToBottom()
      }
      this.stopTyping()
    },
    /** 停止打字机 */
    stopTyping () {
      if (this.typeTimer) {
        clearTimeout(this.typeTimer)
        this.typeTimer = null
      }
      this.typeMsg = null
      this.typeBuffer = ''
    },
    /** 展示工具调用卡片 */
    showToolLogs (logs) {
      if (!logs || !logs.length) return
      // 以 tool 消息形式插入，status 用于卡片样式
      logs.forEach((log, i) => {
        this.messages.push({
          role: 'tool',
          content: typeof log.result === 'string' ? log.result : JSON.stringify(log.result || {}),
          tool_calls: { name: log.name, arguments: log.arguments, result: log.result, elapsed: log.elapsed },
          status: log.status,
          message_id: 't_' + Date.now() + '_' + i
        })
      })
      this.scrollToBottom()
    },
    stopGenerating () {
      if (this.abortController) {
        this.abortController.abort()
        this.abortController = null
      }
      this.stopTyping()
      this.isGenerating = false
    },
    async clearChat () {
      const c = await this.$confirm('确认清空当前对话？', '提示', { type: 'warning' }).catch(() => false)
      if (!c) return
      this.messages = []
      this.toolCallCount = 0
      this.tokenUsed = 0
      // 删除旧会话并新建（保留当前智能体）
      if (this.sessionId) {
        try { await deleteAiSession(this.sessionId) } catch (e) {}
      }
      await this.initSession(this.selectedAgentId)
      this.sessionTitle = '新对话'
    },
    // ============ 上下文感知（v1.63.0） ============
    /** 点击推荐问题：填入输入框并发送 */
    askSuggested (q) {
      this.inputText = q.text || ''
      this.handleSend()
    },
    /** 执行快捷操作（分析/报告/导出） */
    async executeQuickAction (a) {
      if (this.isGenerating) { this.$message.warning('AI 正在回复中，请稍候'); return }
      this.$set(this.actionsLoading, a.id, true)
      try {
        const r = await executeQuickAction({
          action: a.id,
          route: this.pageContext ? this.pageContext.route : this.$route.path,
          filters: this.filters || {}
        })
        if (r.code === 0) {
          const summary = r.data.summary || r.data.result || '操作完成'
          this.messages.push({ role: 'assistant', content: summary, message_id: 'qa_' + Date.now(), isActionResult: true })
          this.scrollToBottom()
          this.$message.success(r.data.result || '操作完成')
        } else {
          this.$message.error(r.msg || '操作失败')
        }
      } catch (e) {
        this.$message.error('操作执行失败：' + (e.message || ''))
      } finally {
        this.$set(this.actionsLoading, a.id, false)
      }
    },
    /** 提交消息反馈（like/dislike） */
    async submitFeedback (msg, type) {
      if (!msg.message_id || msg.message_id.startsWith('a_') || msg.message_id.startsWith('u_') || msg.message_id.startsWith('qa_')) return
      try {
        let reason = ''
        if (type === 'dislike') {
          const r = await this.$prompt('请告诉我们为什么（可选）', '反馈', {
            inputType: 'textarea', inputPlaceholder: '选填反馈原因', showCancelButton: true
          }).catch(() => null)
          if (!r || r.value === null) return
          reason = (r.value || '').trim()
        }
        const res = await submitMessageFeedback({ message_id: msg.message_id, feedback: type, reason })
        if (res.code === 0) {
          this.$set(this.feedbackMap, msg.message_id, type)
          this.$message.success(type === 'like' ? '感谢反馈' : '已记录反馈')
        } else {
          this.$message.error(res.msg || '反馈提交失败')
        }
      } catch (e) {
        this.$message.error('反馈提交失败')
      }
    },
    /** 重新生成回复（SSE 流式） */
    async regenerateMessage (msg) {
      if (!msg.message_id || msg.message_id.startsWith('a_') || msg.message_id.startsWith('u_') || msg.message_id.startsWith('qa_')) return
      if (this.isGenerating || this.regeneratingMsgId) { this.$message.warning('正在生成中，请稍候'); return }
      this.regeneratingMsgId = msg.message_id
      const newId = 'rg_' + Date.now()
      this.messages.push({ role: 'assistant', content: '', message_id: newId, streaming: true, prevQuestion: msg.content })
      this.scrollToBottom()
      try {
        await streamRegenerate(msg.message_id, (data) => {
          if (data.type === 'text') {
            const t = this.messages.find(m => m.message_id === newId)
            if (t) {
              t.content = data.content || ''
              if (data.reasoning_content) t.reasoning_content = data.reasoning_content
            }
          } else if (data.type === 'error') {
            this.$message.error(data.message || '重新生成失败')
          } else if (data.type === 'done') {
            if (data.message_id) {
              const t = this.messages.find(m => m.message_id === newId)
              if (t) t.message_id = data.message_id
            }
          }
        })
        const t = this.messages.find(m => m.message_id === newId)
        if (t) t.streaming = false
        this.scrollToBottom()
      } catch (e) {
        this.messages = this.messages.filter(m => !m.streaming)
        this.$message.error('重新生成失败')
      } finally {
        this.regeneratingMsgId = ''
      }
    },
    /** 复制消息内容 */
    copyMessage (content) {
      if (!content) return
      const el = document.createElement('textarea')
      el.value = content
      document.body.appendChild(el)
      el.select()
      try { document.execCommand('copy'); this.$message.success('已复制') } catch (e) { this.$message.error('复制失败') }
      document.body.removeChild(el)
    },
    /** 分享：复制会话链接（携带当前问题摘要） */
    shareMessage (msg) {
      const url = window.location.origin + window.location.pathname + '#/ai/chat/create?session_id=' + this.sessionId
      this.copyMessage(url)
      this.$message.success('会话链接已复制')
    },
    /** 引用来源点击 */
    onSourcesOpen (s) {
      if (s && s.url) window.open(s.url, '_blank')
    },
    /** 清除页面上下文 */
    clearContext () {
      this.$store.dispatch('ai/clearPageContext')
      this.$message.info('已清除页面上下文')
    },
    // ============ 语音输入（v1.68.0） ============
    toggleVoice () {
      if (!this.speechSupported) return
      if (this.listening) { this.stopVoice(); return }
      const SR = window.SpeechRecognition || window.webkitSpeechRecognition
      this.recognition = new SR()
      this.recognition.lang = 'zh-CN'
      this.recognition.interimResults = false
      this.recognition.maxAlternatives = 1
      this.listening = true
      this.recognition.onresult = (e) => {
        const text = e.results && e.results[0] && e.results[0][0] ? e.results[0][0].transcript : ''
        if (text) { this.inputText = text; this.handleSend() }
      }
      this.recognition.onerror = () => { this.listening = false }
      this.recognition.onend = () => { this.listening = false }
      try { this.recognition.start() } catch (e) { this.listening = false }
    },
    stopVoice () {
      if (this.recognition) { try { this.recognition.stop() } catch (e) {} }
      this.listening = false
    },
    async goHistory () {
      this.$router.push('/ai/chat/history')
    },
    scrollToBottom () {
      this.$nextTick(() => {
        const el = this.$refs.chatBody
        if (el) el.scrollTop = el.scrollHeight
      })
    },
    toolName (msg) {
      const tc = msg.tool_calls
      if (tc && tc.name) return tc.name
      return '工具调用'
    },
    truncateText (s, n) {
      if (!s) return ''
      return s.length > n ? s.slice(0, n) + '...' : s
    },
    // ============ 收藏 ============
    async loadFavoriteCategories () {
      try {
        const r = await getAiFavoriteCategories()
        if (r.code === 0) this.favoriteCategories = r.data.list || []
      } catch (e) {}
    },
    async loadFavoriteStatus () {
      // 加载当前会话已收藏的 message_id
      if (!this.sessionId) return
      try {
        const r = await getAiFavoriteList({ page: 1, limit: 100, session_id: this.sessionId })
        if (r.code === 0) {
          this.favoritedMessageIds = (r.data.list || []).map(f => f.message_id).filter(Boolean)
          this.messages.forEach(m => { if (m.role === 'assistant') m.favorited = this.favoritedMessageIds.includes(m.message_id) })
        }
      } catch (e) {}
    },
    async handleFavorite (msg) {
      if (!this.sessionId || !msg.message_id) { this.$message.warning('该消息暂不可收藏'); return }
      // 工具调用消息（无文本内容）不可收藏
      if (!msg.content || !msg.content.trim()) { this.$message.warning('该回答无文本内容，不可收藏'); return }
      if (msg.favorited) {
        // 已收藏：提示并提供取消收藏（按会话精确匹配 message_id）
        const c = await this.$confirm('该问答已收藏，是否取消收藏？', '提示', { type: 'warning' }).catch(() => false)
        if (c) {
          try {
            const r = await getAiFavoriteList({ page: 1, limit: 100, session_id: this.sessionId })
            const fav = (r.data && r.data.list || []).find(f => f.message_id === msg.message_id)
            if (fav) {
              const { deleteAiFavorite } = await import('@/api/aiFavorite')
              await deleteAiFavorite(fav.id)
              msg.favorited = false
              this.favoritedMessageIds = this.favoritedMessageIds.filter(id => id !== msg.message_id)
              this.$message.success('已取消收藏')
            } else {
              this.$message.warning('未找到该收藏记录')
            }
          } catch (e) {}
        }
        return
      }
      // 未收藏：弹收藏确认框
      this.favoriteTarget = msg
      this.favoriteCategoryId = this.favoriteCategories.length ? this.favoriteCategories[0].id : null
      this.favoriteNote = ''
      this.favoriteDialogVisible = true
    },
    async confirmFavorite () {
      if (!this.favoriteTarget) return
      try {
        const r = await addAiFavorite({
          session_id: this.sessionId,
          message_id: this.favoriteTarget.message_id,
          category_id: this.favoriteCategoryId || undefined,
          note: this.favoriteNote
        })
        if (r.code === 0) {
          this.$message.success('收藏成功')
          this.favoriteTarget.favorited = true
          this.favoritedMessageIds.push(this.favoriteTarget.message_id)
          this.favoriteDialogVisible = false
        }
      } catch (e) {}
    },
    toolCallsName (toolCalls) {
      if (Array.isArray(toolCalls) && toolCalls.length && toolCalls[0].function) {
        return toolCalls[0].function.name || '工具调用'
      }
      return '工具调用'
    },
    formatResult (result) {
      if (typeof result === 'string') return result
      try { return JSON.stringify(result, null, 2) } catch (e) { return String(result) }
    },
    /** 工具结果中文摘要（隐藏原始 JSON，提取接口返回消息） */
    formatResultSummary (result) {
      if (!result) return ''
      if (typeof result === 'string') return result
      const body = result.body || {}
      if (body && body.msg) return body.msg
      if (result.error) return '失败：' + result.error
      if (result.success === false) return '执行失败'
      return '执行成功'
    },
    formatTool (tc) {
      return JSON.stringify(tc, null, 2)
    },
    formatJson (obj) {
      if (obj === null || obj === undefined || obj === '') return '(空)'
      try { return JSON.stringify(typeof obj === 'string' ? JSON.parse(obj) : obj, null, 2) } catch (e) { return String(obj) }
    },
    /** 工具确认卡片显示名 */
    toolConfirmDisplayName (name) {
      const map = { create_repair_order: '创建维修工单', create_hazard: '创建隐患登记', send_notification: '发送通知' }
      return map[name] || name
    }
  }
}
</script>

<style scoped>
.chat-page { display: flex; flex-direction: column; height: calc(100vh - 84px); background: #fff; }
.chat-page-embedded { flex: 1; height: auto; min-height: 0; }
.ctx-area { padding: 10px 16px 0; background: #fff; border-bottom: 1px solid #e8e8e8; }
.voice-btn { font-size: 18px; color: #909399; cursor: pointer; margin-right: 6px; transition: color .2s; }
.voice-btn:hover { color: #409eff; }
.voice-btn.listening { color: #f56c6c; animation: voice-pulse 1s infinite; }
@keyframes voice-pulse { 0%, 100% { opacity: 1; } 50% { opacity: .3; } }
.tool-confirm-card { border: 1px solid #f5dab1; background: #fdf6ec; width: 100%; }
.tc-head { font-size: 14px; font-weight: 600; color: #E6A23C; margin-bottom: 6px; }
.tc-params pre { background: #fff; border-radius: 4px; padding: 8px; font-size: 12px; overflow-x: auto; max-height: 160px; margin: 0 0 8px; }
.tc-desc { font-size: 13px; color: #606266; margin-bottom: 8px; }
.tc-actions { display: flex; gap: 8px; }
.agent-opt-desc { float: right; color: #909399; font-size: 12px; max-width: 220px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; margin-left: 16px; }
.agent-info { display: flex; align-items: center; gap: 14px; padding: 6px 16px; background: #f0f7ff; border-bottom: 1px solid #e4ecf7; flex-wrap: wrap; }
.agent-name { font-size: 13px; font-weight: 600; color: #409EFF; }
.agent-desc { font-size: 12px; color: #909399; max-width: 420px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.agent-tools, .agent-knowledge { font-size: 12px; color: #606266; }
.ad-block { margin-top: 12px; }
.ad-label { font-size: 13px; font-weight: 600; color: #909399; margin-bottom: 6px; }
.ad-pre { background: #f8f9fb; border-radius: 6px; padding: 10px; font-size: 12px; overflow-x: auto; white-space: pre-wrap; word-break: break-word; max-height: 180px; }
.ad-tags { display: flex; flex-wrap: wrap; gap: 6px; }
.ad-tag { margin: 0; }
.ad-none { font-size: 12px; color: #c0c4cc; }
.chat-header { display: flex; justify-content: space-between; align-items: center; padding: 10px 16px; border-bottom: 1px solid #ebeef5; background: #fff; }
.header-left { display: flex; align-items: center; gap: 10px; }
.chat-title { font-size: 15px; font-weight: 600; color: #303133; max-width: 300px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.header-right { display: flex; gap: 8px; align-items: center; }
.tool-trigger { cursor: pointer; display: inline-flex; align-items: center; gap: 4px; font-size: 13px; color: #606266; }
.tool-trigger:hover { color: #409EFF; }
.arrow-reverse { transform: rotate(180deg); transition: transform 0.2s; }
.tool-menu { padding: 6px 0; min-width: 200px; }
.tool-menu-item { display: flex; justify-content: space-between; align-items: center; padding: 6px 16px; gap: 16px; }
.tool-menu-name { font-size: 13px; color: #303133; max-width: 160px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.tool-menu-empty { padding: 10px 16px; font-size: 12px; color: #909399; text-align: center; }
.tool-retry { margin-top: 8px; }
.confirm-body { padding: 4px; }
.confirm-tool { font-size: 14px; font-weight: 600; color: #E6A23C; margin-bottom: 10px; }
.confirm-params { margin-bottom: 10px; }
.confirm-label { font-size: 12px; color: #909399; margin-bottom: 4px; }
.confirm-params pre { background: #f8f9fb; border-radius: 6px; padding: 10px; font-size: 12px; overflow-x: auto; max-height: 220px; white-space: pre-wrap; word-break: break-all; }
.confirm-desc { font-size: 13px; color: #606266; }
.chat-body { flex: 1; overflow-y: auto; padding: 20px 24px; background: #f5f7fa; }
.chat-empty { text-align: center; color: #909399; padding-top: 80px; }
.empty-icon { font-size: 60px; color: #dcdfe6; }
.quick-list { margin-top: 20px; display: flex; flex-wrap: wrap; justify-content: center; gap: 10px; max-width: 560px; margin-left: auto; margin-right: auto; }
.quick-tag { cursor: pointer; }
.msg-row { display: flex; margin-bottom: 14px; }
.msg-row.user { justify-content: flex-end; }
.msg-row.assistant { justify-content: flex-start; }
.bubble { max-width: 72%; padding: 10px 14px; border-radius: 8px; font-size: 14px; line-height: 1.7; white-space: pre-wrap; word-break: break-word; }
.user-bubble { background: #409EFF; color: #fff; }
.ai-bubble { background: #fff; border: 1px solid #ebeef5; box-shadow: 0 1px 3px rgba(0,0,0,0.05); position: relative; padding-top: 24px; }
.ai-bubble-head { position: absolute; top: 6px; right: 8px; }
.fav-star { font-size: 16px; cursor: pointer; }
.favorite-on { color: #E6A23C; }
.favorite-off { color: #c0c4cc; }
.fav-preview { background: #f8f9fb; border-radius: 6px; padding: 10px 12px; }
.fav-preview-q { font-size: 13px; color: #303133; margin-bottom: 6px; }
.fav-preview-a { font-size: 13px; color: #606266; }
.reasoning-block { border-left: 3px solid #c0c4cc; background: #f8f9fb; border-radius: 4px; margin-bottom: 8px; padding: 6px 10px; }
.reasoning-head { display: flex; align-items: center; gap: 6px; cursor: pointer; font-size: 12px; color: #909399; user-select: none; }
.reasoning-head .el-icon-arrow-down { transition: transform 0.2s; }
.reasoning-head .el-icon-arrow-down.rotated { transform: rotate(180deg); }
.reasoning-body { margin-top: 6px; font-size: 12px; color: #606266; line-height: 1.6; white-space: pre-wrap; word-break: break-word; }
.tool-card { width: 100%; background: #fdf6ec; border: 1px solid #f5dab1; border-radius: 6px; padding: 8px 12px; }
.tool-head { display: flex; align-items: center; gap: 8px; }
.tool-name { font-weight: 600; font-size: 13px; color: #E6A23C; }
.tool-elapsed { font-size: 12px; color: #909399; margin-left: 4px; }
.tool-args { margin-top: 6px; }
.tool-args pre { background: #fff; border-radius: 4px; padding: 8px; font-size: 12px; overflow-x: auto; max-height: 200px; }
.tool-result { margin-top: 6px; font-size: 12px; color: #303133; background: #fff; border-radius: 4px; padding: 8px; white-space: pre-wrap; word-break: break-word; max-height: 200px; overflow-y: auto; }
.typing .dot { display: inline-block; width: 6px; height: 6px; border-radius: 50%; background: #909399; margin: 0 3px; animation: bounce 1.2s infinite; }
.typing .dot:nth-child(2) { animation-delay: 0.2s; }
.typing .dot:nth-child(3) { animation-delay: 0.4s; }
@keyframes bounce { 0%, 60%, 100% { transform: translateY(0); } 30% { transform: translateY(-5px); } }
.chat-footer { border-top: 1px solid #ebeef5; padding: 10px 16px 14px; background: #fff; }
.quick-row { display: flex; flex-wrap: wrap; gap: 8px; margin-bottom: 10px; }
.quick-tag-sm { cursor: pointer; }
.input-row { display: flex; align-items: flex-end; gap: 10px; }
.input-row .el-textarea { flex: 1; }
.input-actions { display: flex; align-items: center; gap: 8px; padding-bottom: 4px; }
.char-count { font-size: 12px; color: #909399; }

/* ===== 手机浏览器适配（≤768px） ===== */
@media (max-width: 768px) {
  .chat-page { height: calc(100vh - 84px); }
  .chat-header { flex-wrap: wrap; padding: 8px 10px; gap: 6px; }
  .header-left { flex-wrap: wrap; gap: 6px; }
  .header-left .el-select { width: 130px !important; }
  .chat-title { max-width: 130px; font-size: 14px; }
  .header-right { gap: 4px; }
  .header-right .el-tag { display: none; }
  .tool-trigger { font-size: 12px; }
  .agent-info { padding: 4px 10px; gap: 6px; }
  .agent-desc { max-width: 100%; }
  .chat-body { padding: 12px 10px; }
  .bubble { max-width: 88%; padding: 8px 10px; }
  .ai-bubble { padding-top: 22px; }
  .chat-empty { padding-top: 40px; }
  .chat-empty p { font-size: 13px; }
  .empty-icon { font-size: 44px; }
  .quick-list { max-width: 100%; }
  .chat-footer { padding: 8px 10px 10px; }
  .quick-tag-sm { font-size: 12px; }
  .input-row { gap: 6px; }
  .input-actions { gap: 4px; }
  .input-actions .el-button { padding: 8px 12px; }
  .tool-card { padding: 6px 8px; }
  .tool-result { max-height: 160px; }
  .chat-page /deep/ .el-dialog { width: 92% !important; }
}
</style>
