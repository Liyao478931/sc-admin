<template>
  <div class="ai-eval-page">
    <el-tabs v-model="activeTab" type="border-card">
      <!-- ==================== Tab1 在线调试 ==================== -->
      <el-tab-pane label="在线调试" name="debug">
        <div class="debug-layout">
          <!-- 左侧：对话区域 -->
          <div class="chat-area">
            <div class="agent-head">
              <el-select
                v-model="evalConfig.agent_id"
                filterable
                size="small"
                style="width: 180px;"
                placeholder="选择智能体"
                @change="onAgentChange"
              >
                <el-option v-for="a in agentList" :key="a.agent_id" :label="a.agent_name" :value="a.agent_id" />
              </el-select>
              <span v-if="agent" class="agent-desc">{{ agent.description || '暂无描述' }}</span>
              <span v-if="agent" class="agent-meta">知识库 {{ kbCount }} 个 · 工具 {{ toolCount }} 个</span>
            </div>
            <div class="chat-msgs" ref="chatMsgs">
              <div v-for="(m, i) in chatMessages" :key="i" :class="['msg-row', m.role]">
                <div class="msg-bubble" :class="m.role">
                  <div v-if="m.role === 'user'" class="msg-text">{{ m.content }}</div>
                  <div v-else class="msg-text markdown-body" v-html="m.content"></div>
                  <!-- 工具调用卡片 -->
                  <div v-if="m.tools && m.tools.length" class="tool-cards">
                    <el-card v-for="(t, ti) in m.tools" :key="ti" shadow="never" class="tool-card">
                      <div class="tool-name">{{ t.name || t.tool_name || '工具调用' }}</div>
                      <div class="tool-args">{{ JSON.stringify(t.arguments || t.args || {}) }}</div>
                      <div class="tool-result">{{ t.result || t.output || '' }}</div>
                    </el-card>
                  </div>
                </div>
              </div>
              <div v-if="chatLoading" class="msg-row assistant"><div class="msg-bubble assistant loading-bubble">正在思考…</div></div>
              <el-empty v-if="!chatMessages.length && !chatLoading" description="输入问题开始测试" :image-size="60" />
            </div>
            <div class="chat-input">
              <el-input
                v-model="chatInput"
                type="textarea"
                :rows="2"
                placeholder="输入测试问题，Enter 发送，Shift+Enter 换行"
                @keydown.enter.native.prevent="handleChatSend"
              />
              <div class="chat-actions">
                <el-button type="primary" size="small" :loading="chatLoading" @click="handleChatSend">发送</el-button>
                <el-button size="small" @click="confirmClearChat">清空对话</el-button>
                <el-button size="small" type="warning" icon="el-icon-document" :disabled="!lastDebug" @click="saveAsCase">保存为测试用例</el-button>
              </div>
            </div>
          </div>

          <!-- 右侧：调试信息面板 -->
          <div class="debug-panel">
            <div class="debug-title">调试信息</div>
            <el-empty v-if="!lastDebug" description="发送消息后显示调试信息" :image-size="60" />
            <div v-else>
              <el-descriptions :column="1" size="small" border class="debug-desc">
                <el-descriptions-item label="Token消耗">{{ lastDebug.tokens || 0 }}</el-descriptions-item>
                <el-descriptions-item label="响应时间">{{ lastDebug.response_time || 0 }} ms</el-descriptions-item>
              </el-descriptions>
              <div class="debug-sec-title">工具调用（{{ (lastDebug.tools || []).length }}）</div>
              <el-tag v-for="(t, i) in lastDebug.tools || []" :key="i" size="mini" class="dbg-tag">{{ t.name || t.tool_name || '工具' }}</el-tag>
              <el-empty v-if="!(lastDebug.tools || []).length" description="本次未调用工具" :image-size="40" />
              <div class="debug-sec-title">知识库检索（{{ (lastDebug.knowledge || []).length }}）</div>
              <el-tag v-for="(k, i) in lastDebug.knowledge || []" :key="i" size="mini" class="dbg-tag">{{ k.title || k.document || '知识片段' }}</el-tag>
              <el-empty v-if="!(lastDebug.knowledge || []).length" description="本次未检索知识库" :image-size="40" />
            </div>
          </div>
        </div>
      </el-tab-pane>

      <!-- ==================== Tab2 测试用例 ==================== -->
      <el-tab-pane label="测试用例" name="cases">
        <div class="filter-bar">
          <el-input v-model="caseFilter.keyword" placeholder="用例名称/输入搜索" size="small" clearable style="width: 200px;" @keyup.enter.native="p => { casePage = 1; loadCases() }" @clear="p => { casePage = 1; loadCases() }" />
          <el-input v-model="caseFilter.tag" placeholder="标签筛选" size="small" clearable style="width: 140px; margin-left: 10px;" @keyup.enter.native="p => { casePage = 1; loadCases() }" @clear="p => { casePage = 1; loadCases() }" />
          <span class="flex-1"></span>
          <el-button size="small" type="primary" icon="el-icon-plus" @click="$refs.caseDialog.open()">新增用例</el-button>
          <el-button size="small" icon="el-icon-upload2" @click="importCaseDialog = true">导入</el-button>
          <el-button size="small" icon="el-icon-download" @click="doExportCases">导出</el-button>
          <el-button size="small" icon="el-icon-refresh" @click="loadCases">刷新</el-button>
        </div>

        <el-table :data="caseList" size="small" stripe v-loading="caseLoading">
          <el-table-column prop="case_name" label="用例名称" min-width="140" show-overflow-tooltip />
          <el-table-column prop="input" label="输入内容" min-width="180" show-overflow-tooltip />
          <el-table-column prop="expected_output" label="期望输出" min-width="160" show-overflow-tooltip>
            <template slot-scope="s">{{ s.row.expected_output || '--' }}</template>
          </el-table-column>
          <el-table-column label="期望工具" width="130">
            <template slot-scope="s">
              <el-tag v-for="t in s.row.expected_tools || []" :key="t" size="mini" class="ch-tag">{{ t }}</el-tag>
              <span v-if="!(s.row.expected_tools || []).length">--</span>
            </template>
          </el-table-column>
          <el-table-column label="标签" width="140">
            <template slot-scope="s">
              <el-tag v-for="t in s.row.tags || []" :key="t" size="mini" type="info" class="ch-tag">{{ t }}</el-tag>
              <span v-if="!(s.row.tags || []).length">--</span>
            </template>
          </el-table-column>
          <el-table-column label="状态" width="80">
            <template slot-scope="s">
              <el-tag size="mini" :type="s.row.status === 1 ? 'success' : 'info'">{{ s.row.status === 1 ? '启用' : '停用' }}</el-tag>
            </template>
          </el-table-column>
          <el-table-column label="操作" width="160" align="center">
            <template slot-scope="s">
              <el-button type="text" size="mini" @click="$refs.caseDialog.open(s.row)">编辑</el-button>
              <el-button type="text" size="mini" @click="quickRunCase(s.row)">执行</el-button>
              <el-button type="text" size="mini" class="danger" @click="deleteCase(s.row)">删除</el-button>
            </template>
          </el-table-column>
        </el-table>
        <el-pagination class="pager" small background layout="total, prev, pager, next" :total="caseTotal" :page-size="casePageSize" :current-page="casePage" @current-change="p => { casePage = p; loadCases() }" />

        <!-- 导入弹窗 -->
        <el-dialog title="导入测试用例" :visible.sync="importCaseDialog" width="520px" append-to-body>
          <el-input v-model="importCaseContent" type="textarea" :rows="10" placeholder='粘贴 JSON 数组，格式：[{"case_name":"...","input":"...","expected_output":"...","expected_tools":[1,2],"tags":["tag"]}]' />
          <div slot="footer">
            <el-button size="small" @click="importCaseDialog = false">取消</el-button>
            <el-button size="small" type="primary" :loading="importing" @click="doImportCases">导入</el-button>
          </div>
        </el-dialog>
      </el-tab-pane>

      <!-- ==================== Tab3 批量评测 ==================== -->
      <el-tab-pane label="批量评测" name="batch">
        <el-card shadow="never" class="batch-config">
          <div class="sec-title">评测配置</div>
          <el-form :model="evalConfig" label-width="130px" size="small">
            <el-form-item label="智能体">
              <el-select v-model="evalConfig.agent_id" filterable style="width: 300px;" placeholder="选择智能体">
                <el-option v-for="a in agentList" :key="a.agent_id" :label="a.agent_name" :value="a.agent_id" />
              </el-select>
            </el-form-item>
            <el-form-item label="测试用例">
              <div class="case-select">
                <el-checkbox :value="allCasesSelected" @change="toggleAllCases">全选</el-checkbox>
                <el-checkbox-group v-model="evalConfig.case_ids">
                  <el-checkbox v-for="c in caseListAll" :key="c.case_id" :label="c.case_id">{{ c.case_name }}</el-checkbox>
                </el-checkbox-group>
              </div>
            </el-form-item>
            <el-form-item label="匹配度阈值">
              <el-input-number v-model="evalConfig.threshold" :min="1" :max="100" /> <span class="unit">分（默认60）</span>
            </el-form-item>
            <el-form-item label="工具调用验证"><el-switch v-model="evalConfig.tool_check" /></el-form-item>
            <el-form-item label="评测任务名">
              <el-input v-model="evalConfig.task_name" placeholder="留空自动生成" style="width: 300px;" />
            </el-form-item>
            <el-form-item>
              <el-button type="primary" size="small" :loading="evalRunning" @click="startEval">开始评测</el-button>
            </el-form-item>
          </el-form>
        </el-card>

        <!-- 进度 -->
        <el-card v-if="evalRunning || evalProgress.status" shadow="never" class="batch-progress">
          <div class="sec-title">评测进度</div>
          <el-progress :percentage="evalProgress.percent || 0" :status="evalProgress.percent >= 100 ? 'success' : ''" />
          <div class="progress-text">{{ evalProgress.current || '' }}</div>
        </el-card>

        <!-- 结果 -->
        <el-card v-if="evalResult" shadow="never" class="batch-result">
          <div class="sec-title">评测结果</div>
          <el-row :gutter="12" class="stat-row">
            <el-col :span="4"><div class="stat-item"><div class="stat-num">{{ evalResult.summary.total || 0 }}</div><div class="stat-label">总用例</div></div></el-col>
            <el-col :span="4"><div class="stat-item"><div class="stat-num success">{{ evalResult.summary.passed || 0 }}</div><div class="stat-label">通过</div></div></el-col>
            <el-col :span="4"><div class="stat-item"><div class="stat-num danger">{{ evalResult.summary.failed || 0 }}</div><div class="stat-label">失败</div></div></el-col>
            <el-col :span="4"><div class="stat-item"><div class="stat-num">{{ evalResult.summary.pass_rate || 0 }}%</div><div class="stat-label">通过率</div></div></el-col>
            <el-col :span="4"><div class="stat-item"><div class="stat-num">{{ evalResult.summary.avg_score || 0 }}</div><div class="stat-label">平均评分</div></div></el-col>
            <el-col :span="4"><div class="stat-item"><div class="stat-num">{{ evalResult.summary.tool_accuracy || 0 }}%</div><div class="stat-label">工具准确率</div></div></el-col>
          </el-row>
          <el-table :data="evalResult.results || []" size="small" stripe>
            <el-table-column prop="case_name" label="用例" min-width="120" show-overflow-tooltip />
            <el-table-column prop="input" label="输入" min-width="140" show-overflow-tooltip />
            <el-table-column prop="actual_output" label="实际输出" min-width="160" show-overflow-tooltip />
            <el-table-column prop="expected_output" label="期望输出" min-width="140" show-overflow-tooltip />
            <el-table-column prop="score" label="评分" width="70" />
            <el-table-column label="状态" width="80">
              <template slot-scope="s">
                <el-tag size="mini" :type="s.row.passed ? 'success' : 'danger'">{{ s.row.passed ? '通过' : '失败' }}</el-tag>
              </template>
            </el-table-column>
            <el-table-column label="操作" width="90">
              <template slot-scope="s">
                <el-button type="text" size="mini" @click="$refs.resultDialog.open(s.row)">详情</el-button>
              </template>
            </el-table-column>
          </el-table>
        </el-card>
      </el-tab-pane>

      <!-- ==================== Tab4 评测报告 ==================== -->
      <el-tab-pane label="评测报告" name="reports">
        <div class="filter-bar">
          <el-select v-model="reportFilter.agent_id" placeholder="智能体筛选" clearable size="small" style="width: 180px;" @change="p => { reportPage = 1; loadTasks() }">
            <el-option v-for="a in agentList" :key="a.agent_id" :label="a.agent_name" :value="a.agent_id" />
          </el-select>
          <el-select v-model="reportFilter.status" placeholder="状态筛选" clearable size="small" style="width: 130px; margin-left: 10px;" @change="p => { reportPage = 1; loadTasks() }">
            <el-option label="待执行" value="pending" />
            <el-option label="执行中" value="running" />
            <el-option label="已完成" value="completed" />
            <el-option label="失败" value="failed" />
          </el-select>
          <el-input v-model="reportFilter.keyword" placeholder="任务/智能体搜索" size="small" clearable style="width: 180px; margin-left: 10px;" @keyup.enter.native="p => { reportPage = 1; loadTasks() }" @clear="p => { reportPage = 1; loadTasks() }" />
          <span class="flex-1"></span>
          <el-button size="small" icon="el-icon-refresh" @click="loadTasks">刷新</el-button>
        </div>

        <el-table :data="taskList" size="small" stripe v-loading="taskLoading">
          <el-table-column prop="task_name" label="任务名称" min-width="150" show-overflow-tooltip />
          <el-table-column prop="agent_name" label="智能体" min-width="120" />
          <el-table-column prop="total_count" label="用例数" width="70" />
          <el-table-column prop="pass_rate" label="通过率" width="80">
            <template slot-scope="s">{{ s.row.pass_rate }}%</template>
          </el-table-column>
          <el-table-column prop="avg_score" label="平均评分" width="80" />
          <el-table-column prop="create_time" label="执行时间" width="165" />
          <el-table-column label="状态" width="90">
            <template slot-scope="s">
              <el-tag size="mini" :type="statusType(s.row.status)">{{ s.row.status_text }}</el-tag>
            </template>
          </el-table-column>
          <el-table-column label="操作" width="180" align="center">
            <template slot-scope="s">
              <el-button v-if="s.row.status === 'completed'" type="text" size="mini" @click="$refs.reportDialog.open(s.row.id)">查看报告</el-button>
              <el-button v-if="s.row.status === 'completed'" type="text" size="mini" @click="openCompare(s.row)">对比</el-button>
              <el-button type="text" size="mini" class="danger" @click="deleteTask(s.row)">删除</el-button>
            </template>
          </el-table-column>
        </el-table>
        <el-pagination class="pager" small background layout="total, prev, pager, next" :total="taskTotal" :page-size="taskPageSize" :current-page="taskPage" @current-change="p => { taskPage = p; loadTasks() }" />
      </el-tab-pane>
    </el-tabs>

    <!-- 用例弹窗 -->
    <CaseDialog ref="caseDialog" @saved="loadCases" />
    <!-- 用例结果详情 -->
    <ResultDetailDialog ref="resultDialog" />
    <!-- 报告详情 -->
    <ReportDetailDialog ref="reportDialog" />
    <!-- 报告对比 -->
    <ReportCompareDialog ref="compareDialog" :agent-list="agentList" />
  </div>
</template>

<script>
import {
  evalChat, getEvalCases, deleteEvalCase, importEvalCases, exportEvalCases,
  createEvalTask, runEvalTask, getEvalTasks, deleteEvalTask, getEvalTaskProgress
} from '../../../api/aiEval'
import { getAiAgentOptions } from '../../../api/aiAgent'
import { getAiToolOptions } from '../../../api/aiTool'
import CaseDialog from './components/EvalCaseDialog.vue'
import ResultDetailDialog from './components/EvalResultDetailDialog.vue'
import ReportDetailDialog from './components/EvalReportDetailDialog.vue'
import ReportCompareDialog from './components/EvalReportCompareDialog.vue'

export default {
  name: 'AiAgentEvaluate',
  components: { CaseDialog, ResultDetailDialog, ReportDetailDialog, ReportCompareDialog },
  data() {
    return {
      activeTab: 'debug',
      // 智能体
      agent: null, agentList: [], kbCount: 0, toolCount: 0,
      // 在线调试
      chatInput: '', chatLoading: false, chatMessages: [], lastDebug: null, chatSessionId: '',
      // 用例
      caseLoading: false, caseList: [], caseTotal: 0, casePage: 1, casePageSize: 20,
      caseFilter: { keyword: '', tag: '' },
      caseListAll: [], importCaseDialog: false, importCaseContent: '', importing: false,
      // 批量评测
      evalConfig: { agent_id: '', case_ids: [], threshold: 60, tool_check: true, task_name: '' },
      evalRunning: false, evalProgress: {}, evalResult: null, evalTimer: null,
      // 报告
      taskLoading: false, taskList: [], taskTotal: 0, taskPage: 1, taskPageSize: 20,
      reportFilter: { agent_id: '', status: '', keyword: '' },
      agentOptions: []
    }
  },
  computed: {
    allCasesSelected() {
      return this.caseListAll.length > 0 && this.evalConfig.case_ids.length === this.caseListAll.length
    }
  },
  created() {
    // 从 URL 参数读取 agent_id
    const agentId = this.$route.query.agent_id || ''
    if (agentId) this.evalConfig.agent_id = agentId
    this.loadAgents()
    this.loadCases()
    this.loadAllCases()
    this.loadTasks()
    if (agentId) this.loadAgentInfo(agentId)
  },
  beforeDestroy() {
    if (this.evalTimer) clearInterval(this.evalTimer)
  },
  methods: {
    // ===== 智能体 =====
    async loadAgents() {
      try {
        const res = await getAiAgentOptions()
        this.agentList = res.data || []
        // URL 参数或已选智能体 → 同步 agent 信息
        if (this.evalConfig.agent_id) this.onAgentChange(this.evalConfig.agent_id)
      } catch (e) {}
    },
    onAgentChange(agentId) {
      this.agent = this.agentList.find(a => a.agent_id === agentId) || null
      if (this.agent) {
        this.kbCount = this.agent.knowledge_count != null ? this.agent.knowledge_count : ((this.agent.knowledge_base_ids || []).length)
        this.toolCount = this.agent.tool_count != null ? this.agent.tool_count : ((this.agent.tool_ids || []).length)
      } else {
        this.kbCount = 0
        this.toolCount = 0
      }
      // 切换智能体后清空对话，避免上下文串
      this.chatMessages = []
      this.chatSessionId = ''
      this.lastDebug = null
    },
    async loadAgentInfo(agentId) {
      try {
        const res = await getAiAgentOptions()
        const list = res.data || []
        this.agentList = list
        this.onAgentChange(agentId)
      } catch (e) {}
    },
    // ===== 在线调试 =====
    async handleChatSend() {
      const msg = this.chatInput.trim()
      if (!msg) return this.$message.warning('请输入内容')
      if (!this.evalConfig.agent_id && !this.agent) return this.$message.warning('请先在批量评测或URL参数中选择智能体')
      const agentId = this.evalConfig.agent_id || (this.agent && this.agent.agent_id)
      if (!agentId) return this.$message.warning('请选择智能体')

      this.chatMessages.push({ role: 'user', content: msg })
      this.chatInput = ''
      this.chatLoading = true
      try {
        const res = await evalChat({ agent_id: agentId, message: msg, session_id: this.chatSessionId })
        const d = res.data || {}
        this.chatSessionId = d.session_id || this.chatSessionId
        // 简单转义 + 换行转 <br>
        const content = (d.reply || '').replace(/</g, '&lt;').replace(/\n/g, '<br/>')
        this.chatMessages.push({ role: 'assistant', content, tools: d.tools || [] })
        this.lastDebug = d
        this.$nextTick(() => { if (this.$refs.chatMsgs) this.$refs.chatMsgs.scrollTop = this.$refs.chatMsgs.scrollHeight })
      } catch (e) {}
      this.chatLoading = false
    },
    confirmClearChat() {
      this.$confirm('确定清空当前对话？', '提示', { type: 'warning' }).then(() => {
        this.chatMessages = []
        this.chatSessionId = ''
        this.lastDebug = null
      }).catch(() => {})
    },
    saveAsCase() {
      // 将最近一次用户输入保存为用例
      const lastUser = [...this.chatMessages].reverse().find(m => m.role === 'user')
      if (!lastUser) return this.$message.warning('没有可保存的对话')
      this.$refs.caseDialog.open(null, lastUser.content)
      this.$message.success('已填充到新增用例弹窗')
    },
    // ===== 用例 =====
    async loadCases() {
      this.caseLoading = true
      try {
        const params = { page: this.casePage, limit: this.casePageSize }
        if (this.caseFilter.keyword) params.keyword = this.caseFilter.keyword
        if (this.caseFilter.tag) params.tag = this.caseFilter.tag
        const res = await getEvalCases(params)
        this.caseList = res.data.list || []
        this.caseTotal = res.data.total || 0
      } catch (e) {}
      this.caseLoading = false
    },
    async loadAllCases() {
      try {
        const res = await getEvalCases({ page: 1, limit: 100 })
        this.caseListAll = res.data.list || []
      } catch (e) {}
    },
    deleteCase(row) {
      this.$confirm(`确定删除用例「${row.case_name}」？`, '提示', { type: 'warning' }).then(async () => {
        try { await deleteEvalCase(row.id); this.$message.success('已删除'); this.loadCases(); this.loadAllCases() } catch (e) {}
      }).catch(() => {})
    },
    quickRunCase(row) {
      // 快速执行：跳转到在线调试并填充输入
      this.chatMessages = []
      this.chatSessionId = ''
      this.chatInput = row.input
      this.activeTab = 'debug'
      this.$message.success('已填充用例输入，请点击发送')
    },
    async doImportCases() {
      this.importing = true
      try {
        const res = await importEvalCases({ content: this.importCaseContent })
        this.$message.success(res.msg || '导入成功')
        this.importCaseDialog = false
        this.importCaseContent = ''
        this.loadCases(); this.loadAllCases()
      } catch (e) {}
      this.importing = false
    },
    async doExportCases() {
      try {
        const res = await exportEvalCases()
        const blob = new Blob([res.data], { type: 'application/json;charset=utf-8' })
        const url = URL.createObjectURL(blob)
        const a = document.createElement('a')
        a.href = url; a.download = 'eval_cases.json'; a.click()
        URL.revokeObjectURL(url)
      } catch (e) {}
    },
    // ===== 批量评测 =====
    toggleAllCases(val) {
      this.evalConfig.case_ids = val ? this.caseListAll.map(c => c.case_id) : []
    },
    async startEval() {
      if (!this.evalConfig.agent_id) return this.$message.warning('请选择智能体')
      if (!this.evalConfig.case_ids.length) return this.$message.warning('请至少选择一个测试用例')
      this.evalRunning = true
      this.evalResult = null
      this.evalProgress = { percent: 5, current: '正在创建评测任务…' }
      try {
        const createRes = await createEvalTask({
          agent_id: this.evalConfig.agent_id,
          task_name: this.evalConfig.task_name,
          case_ids: this.evalConfig.case_ids
        })
        const taskId = createRes.data.id
        // 启动评测（同步执行，轮询进度）
        this.evalProgress = { percent: 10, current: '正在执行评测…' }
        this.evalTimer = setInterval(() => this.pollProgress(taskId), 2000)
        const runRes = await runEvalTask(taskId, {
          threshold: this.evalConfig.threshold,
          tool_check: this.evalConfig.tool_check ? 1 : 0
        })
        this.evalResult = runRes.data
        this.evalProgress = { percent: 100, current: '评测完成' }
        if (this.evalTimer) clearInterval(this.evalTimer)
        this.loadTasks()
      } catch (e) {
        if (this.evalTimer) clearInterval(this.evalTimer)
        this.evalProgress = {}
      }
      this.evalRunning = false
    },
    async pollProgress(taskId) {
      try {
        const res = await getEvalTaskProgress(taskId)
        this.evalProgress = res.data || {}
      } catch (e) {}
    },
    // ===== 报告 =====
    async loadTasks() {
      this.taskLoading = true
      try {
        const params = { page: this.taskPage, limit: this.taskPageSize }
        if (this.reportFilter.agent_id) params.agent_id = this.reportFilter.agent_id
        if (this.reportFilter.status) params.status = this.reportFilter.status
        if (this.reportFilter.keyword) params.keyword = this.reportFilter.keyword
        const res = await getEvalTasks(params)
        this.taskList = res.data.list || []
        this.taskTotal = res.data.total || 0
      } catch (e) {}
      this.taskLoading = false
    },
    deleteTask(row) {
      this.$confirm(`确定删除评测任务「${row.task_name}」？`, '提示', { type: 'warning' }).then(async () => {
        try { await deleteEvalTask(row.id); this.$message.success('已删除'); this.loadTasks() } catch (e) {}
      }).catch(() => {})
    },
    openCompare(row) {
      this.$refs.compareDialog.open(row)
    },
    // ===== 辅助 =====
    statusType(st) { return { pending: 'info', running: 'warning', completed: 'success', failed: 'danger' }[st] || 'info' }
  }
}
</script>

<style scoped>
.ai-eval-page { padding: 4px 16px; }
.debug-layout { display: flex; gap: 14px; height: calc(100vh - 220px); min-height: 480px; }
.chat-area { flex: 6; display: flex; flex-direction: column; border: 1px solid #ebeef5; border-radius: 6px; overflow: hidden; }
.agent-head { padding: 10px 14px; border-bottom: 1px solid #ebeef5; display: flex; align-items: center; gap: 10px; }
.agent-desc { color: #606266; font-size: 13px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.agent-meta { color: #909399; font-size: 12px; margin-left: auto; }
.chat-msgs { flex: 1; overflow-y: auto; padding: 14px; background: #fafafa; }
.msg-row { display: flex; margin-bottom: 12px; }
.msg-row.user { justify-content: flex-end; }
.msg-bubble { max-width: 78%; padding: 10px 14px; border-radius: 8px; font-size: 13px; line-height: 1.6; }
.msg-bubble.user { background: #409eff; color: #fff; }
.msg-bubble.assistant { background: #fff; color: #303133; border: 1px solid #ebeef5; }
.loading-bubble { color: #909399; }
.tool-cards { margin-top: 8px; }
.tool-card { margin-bottom: 6px; }
.tool-name { font-weight: 600; color: #409eff; font-size: 12px; }
.tool-args, .tool-result { color: #606266; font-size: 12px; word-break: break-all; }
.chat-input { border-top: 1px solid #ebeef5; padding: 10px; }
.chat-actions { margin-top: 8px; text-align: right; }
.debug-panel { flex: 4; border: 1px solid #ebeef5; border-radius: 6px; padding: 12px; overflow-y: auto; }
.debug-title { font-weight: 600; margin-bottom: 10px; }
.debug-sec-title { font-weight: 600; margin: 12px 0 6px; font-size: 13px; }
.dbg-tag { margin: 2px 4px 2px 0; }
.filter-bar { display: flex; align-items: center; margin-bottom: 12px; }
.flex-1 { flex: 1; }
.pager { margin-top: 10px; text-align: right; }
.ch-tag { margin-right: 4px; }
.sec-title { font-weight: 600; margin-bottom: 10px; }
.batch-config, .batch-progress, .batch-result { margin-bottom: 14px; }
.case-select { display: flex; flex-direction: column; gap: 6px; }
.unit { color: #909399; font-size: 12px; margin-left: 6px; }
.stat-row { margin-bottom: 10px; }
.stat-item { text-align: center; border: 1px solid #ebeef5; border-radius: 6px; padding: 10px 0; }
.stat-num { font-size: 22px; font-weight: 700; }
.stat-num.success { color: #67c23a; }
.stat-num.danger { color: #f56c6c; }
.stat-label { color: #909399; font-size: 12px; }
.progress-text { color: #606266; font-size: 13px; margin-top: 8px; }
</style>
