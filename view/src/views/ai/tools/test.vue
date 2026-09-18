<!-- 文件：admin/src/views/ai/tools/test.vue -->
<template>
  <div class="page">
    <!-- 顶部工具信息栏 -->
    <el-card shadow="never" class="head-card">
      <div class="head-row">
        <div class="head-left">
          <i class="el-icon-s-tools head-icon"></i>
          <div>
            <div class="head-title">
              {{ tool ? tool.tool_display_name : '工具测试' }}
              <el-tag v-if="tool" size="mini" class="cat-tag">{{ tool.category_text || tool.category }}</el-tag>
            </div>
            <div v-if="tool" class="head-sub">{{ tool.tool_name }}｜{{ tool.description }}</div>
          </div>
        </div>
        <div class="head-right">
          <el-tag v-if="tool" size="mini" :type="methodTag(tool.method)">{{ tool.method }}</el-tag>
          <span v-if="tool" class="head-path">{{ tool.api_path }}</span>
          <el-button size="small" icon="el-icon-back" @click="goList">返回工具列表</el-button>
        </div>
      </div>
    </el-card>

    <!-- 中部：左右两栏 -->
    <el-row :gutter="16" class="main-row">
      <!-- 左栏：测试表单 -->
      <el-col :span="12">
        <el-card shadow="never" class="col-card">
          <div slot="header" class="col-head"><span class="col-title">测试表单</span></div>
          <div v-if="tool">
            <!-- 请求头（只读可折叠） -->
            <el-collapse class="header-collapse">
              <el-collapse-item title="请求头配置（只读）">
                <pre class="header-pre">{{ formatJson(tool.headers) }}</pre>
              </el-collapse-item>
            </el-collapse>
            <!-- 动态表单 -->
            <dynamic-form ref="dynForm" :schema="tool.params_schema || {}" v-model="formData" />
            <div class="form-actions">
              <el-button v-if="!testing" type="primary" icon="el-icon-s-promotion" @click="sendTest">发送请求</el-button>
              <el-button v-if="testing" type="danger" icon="el-icon-video-pause" @click="cancelTest">取消请求</el-button>
              <el-button :disabled="testing" @click="resetForm">重置表单</el-button>
            </div>
          </div>
          <el-empty v-else description="工具不存在或已停用" />
        </el-card>
      </el-col>

      <!-- 右栏：测试结果 -->
      <el-col :span="12">
        <el-card shadow="never" class="col-card">
          <div slot="header" class="col-head">
            <span class="col-title">测试结果</span>
            <div v-if="testResult" class="result-overview">
              <el-tag size="mini" :type="statusTagType(testResult.status_code)">HTTP {{ testResult.status_code }}</el-tag>
              <span class="result-time">{{ testResult.elapsed_ms }}ms</span>
            </div>
          </div>
          <div v-if="testError" class="test-error">{{ testError }}</div>
          <div v-else-if="testResult">
            <json-viewer title="响应体" :content="testResult.response_body" />
            <div style="margin-top:10px;">
              <json-viewer title="响应头" :content="testResult.response_headers || {}" />
            </div>
            <div class="result-footer">
              <span class="result-size">响应大小：{{ formatSize(testResult.response_body) }}</span>
              <el-dropdown trigger="click" @command="exportReport">
                <el-button size="mini" icon="el-icon-download">导出报告</el-button>
                <el-dropdown-menu slot="dropdown">
                  <el-dropdown-item command="txt">导出文本</el-dropdown-item>
                  <el-dropdown-item command="json">导出JSON</el-dropdown-item>
                </el-dropdown-menu>
              </el-dropdown>
            </div>
          </div>
          <el-empty v-else description="尚未测试" />
        </el-card>
      </el-col>
    </el-row>

    <!-- 底部：测试历史 -->
    <el-card shadow="never" class="hist-card">
      <div slot="header" class="col-head">
        <span class="col-title">测试历史</span>
        <el-button size="mini" type="danger" icon="el-icon-delete" @click="clearHistory">清空历史</el-button>
      </div>
      <el-table :data="historyList" size="small" stripe v-loading="histLoading">
        <el-table-column prop="create_time" label="测试时间" width="170" />
        <el-table-column label="状态码" width="90" align="center">
          <template slot-scope="s">
            <el-tag size="mini" :type="s.row.response_status ? statusTagType(s.row.response_status) : 'info'">
              {{ s.row.response_status || '-' }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="response_time" label="响应时间" width="90" align="center">
          <template slot-scope="s">{{ s.row.response_time }}ms</template>
        </el-table-column>
        <el-table-column label="状态" width="80" align="center">
          <template slot-scope="s">
            <el-tag size="mini" :type="s.row.status === 'success' ? 'success' : (s.row.status === 'timeout' ? 'warning' : 'danger')">
              {{ s.row.status === 'success' ? '成功' : (s.row.status === 'timeout' ? '超时' : '错误') }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column label="响应预览" min-width="200" show-overflow-tooltip>
          <template slot-scope="s">{{ s.row.response_body_preview || s.row.error_message }}</template>
        </el-table-column>
        <el-table-column label="操作" width="140" align="center">
          <template slot-scope="s">
            <el-button size="mini" @click="viewHistoryDetail(s.row)">详情</el-button>
            <el-button size="mini" type="primary" @click="retest(s.row)">重新测试</el-button>
          </template>
        </el-table-column>
      </el-table>
      <div class="pager">
        <el-pagination background layout="total, prev, pager, next" :total="histTotal"
          :page-size="histLimit" :current-page="histPage" @current-change="p => { histPage = p; loadHistory() }" />
      </div>
    </el-card>

    <!-- 历史详情弹窗 -->
    <el-dialog title="测试详情" :visible.sync="detailVisible" width="720px" top="6vh">
      <div v-if="detailLog">
        <div class="detail-row">工具：{{ detailLog.tool_name }}</div>
        <div class="detail-row">时间：{{ detailLog.create_time }}</div>
        <div class="detail-row">状态码：{{ detailLog.response_status }}｜耗时：{{ detailLog.response_time }}ms</div>
        <div class="detail-block">
          <div class="detail-label">请求参数</div>
          <json-viewer title="" :content="detailLog.request_params || {}" />
        </div>
        <div class="detail-block">
          <div class="detail-label">响应体</div>
          <json-viewer title="" :content="detailLog.response_body || ''" />
        </div>
        <div v-if="detailLog.error_message" class="detail-block">
          <div class="detail-label">错误信息</div>
          <div class="detail-error">{{ detailLog.error_message }}</div>
        </div>
      </div>
    </el-dialog>
  </div>
</template>

<script>
import DynamicForm from '@/components/DynamicForm.vue'
import JsonViewer from '@/components/JsonViewer.vue'
import {
  getAiToolDetail, getToolTestHistory, getToolTestDetail, clearToolTestHistory
} from '@/api/aiTool'

export default {
  name: 'AiToolTest',
  components: { DynamicForm, JsonViewer },
  data () {
    return {
      toolId: 0,
      tool: null,
      formData: {},
      testing: false,
      abortController: null,
      testResult: null,
      testError: '',
      // 历史
      historyList: [], histTotal: 0, histPage: 1, histLimit: 15, histLoading: false,
      detailVisible: false, detailLog: null
    }
  },
  created () {
    const id = parseInt(this.$route.query.tool_id || '0', 10)
    if (!id) { this.$message.warning('缺少工具ID'); this.goList(); return }
    this.toolId = id
    this.loadTool()
    this.loadHistory()
  },
  methods: {
    methodTag (m) {
      return { GET: 'primary', POST: 'success', PUT: 'warning', DELETE: 'danger' }[m] || 'info'
    },
    statusTagType (code) {
      if (code >= 200 && code < 300) return 'success'
      if (code >= 300 && code < 400) return 'primary'
      if (code >= 400 && code < 500) return 'warning'
      return 'danger'
    },
    formatJson (obj) {
      if (obj === null || obj === undefined || obj === '') return '(空)'
      try { return JSON.stringify(typeof obj === 'string' ? JSON.parse(obj) : obj, null, 2) } catch (e) { return String(obj) }
    },
    goList () { this.$router.push('/ai/tools/list') },
    async loadTool () {
      try {
        const r = await getAiToolDetail(this.toolId)
        if (r.code === 0) {
          this.tool = r.data
          // 初始化表单默认值
          this.formData = this.initForm(this.tool.params_schema)
        } else {
          this.$message.error(r.msg || '工具不存在')
          this.goList()
        }
      } catch (e) { this.goList() }
    },
    initForm (schema) {
      const form = {}
      const props = (schema && schema.properties) || {}
      Object.keys(props).forEach(key => {
        const p = props[key] || {}
        if (p.default !== undefined) form[key] = p.default
        else if (p.type === 'boolean') form[key] = false
        else if (p.type === 'array') form[key] = []
        else if (p.type === 'object') form[key] = {}
        else if (p.type === 'number' || p.type === 'integer') form[key] = 0
        else form[key] = ''
      })
      return form
    },
    resetForm () {
      this.formData = this.initForm(this.tool ? this.tool.params_schema : null)
      this.testResult = null
      this.testError = ''
    },
    async sendTest () {
      if (!this.tool) return
      // 必填参数前端校验（含嵌套表单）
      const valid = this.$refs.dynForm ? await this.$refs.dynForm.validate() : true
      if (!valid) return
      this.testing = true
      this.testError = ''
      this.abortController = new AbortController()
      const token = (await import('@/utils/auth')).getToken() || ''
      try {
        const resp = await fetch('/api/ai/tools/test', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json', 'Authorization': 'Bearer ' + token },
          body: JSON.stringify({ tool_id: this.toolId, params: this.formData }),
          signal: this.abortController.signal
        })
        const json = await resp.json()
        if (json.code === 0) {
          this.testResult = json.data
          this.testError = ''
        } else {
          this.testError = json.msg || '测试失败'
          this.testResult = null
        }
        this.loadHistory()
      } catch (e) {
        if (e.name === 'AbortError') {
          this.testError = '请求已取消'
        } else {
          this.testError = '请求失败：' + (e.message || '未知错误')
        }
        this.testResult = null
      } finally {
        this.testing = false
        this.abortController = null
      }
    },
    cancelTest () {
      if (this.abortController) this.abortController.abort()
    },
    formatSize (body) {
      if (!body) return '0 B'
      const bytes = new Blob([String(body)]).size
      if (bytes < 1024) return bytes + ' B'
      if (bytes < 1048576) return (bytes / 1024).toFixed(1) + ' KB'
      return (bytes / 1048576).toFixed(1) + ' MB'
    },
    exportReport (format) {
      if (!this.testResult) return
      const tool = this.tool || {}
      const report = {
        tool_name: tool.tool_name,
        tool_display_name: tool.tool_display_name,
        method: tool.method,
        api_path: tool.api_path,
        request_params: this.formData,
        status_code: this.testResult.status_code,
        elapsed_ms: this.testResult.elapsed_ms,
        response_headers: this.testResult.response_headers || {},
        response_body: this.testResult.response_body
      }
      let content, ext, mime
      if (format === 'json') {
        content = JSON.stringify(report, null, 2)
        ext = 'json'
        mime = 'application/json'
      } else {
        content = [
          '=== 工具测试报告 ===',
          '工具：' + (report.tool_display_name || report.tool_name),
          '方法：' + report.method + ' 路径：' + report.api_path,
          '状态码：' + report.status_code + ' 耗时：' + report.elapsed_ms + 'ms',
          '--- 请求参数 ---',
          JSON.stringify(report.request_params, null, 2),
          '--- 响应体 ---',
          String(report.response_body || '')
        ].join('\n')
        ext = 'txt'
        mime = 'text/plain'
      }
      const blob = new Blob([content], { type: mime + ';charset=utf-8' })
      const url = URL.createObjectURL(blob)
      const a = document.createElement('a')
      a.href = url
      a.download = (report.tool_name || 'tool') + '_test_' + new Date().toISOString().slice(0, 19).replace(/[T:]/g, '-') + '.' + ext
      document.body.appendChild(a)
      a.click()
      document.body.removeChild(a)
      URL.revokeObjectURL(url)
    },
    async loadHistory () {
      if (!this.toolId) return
      this.histLoading = true
      try {
        const r = await getToolTestHistory(this.toolId, this.histPage, this.histLimit)
        if (r.code === 0) {
          this.historyList = r.data.list || []
          this.histTotal = r.data.total || 0
        }
      } catch (e) {} finally { this.histLoading = false }
    },
    async clearHistory () {
      const c = await this.$confirm('确认清空该工具的所有测试历史吗？', '提示', { type: 'warning' }).catch(() => false)
      if (!c) return
      try {
        const r = await clearToolTestHistory(this.toolId)
        if (r.code === 0) { this.$message.success('已清空'); this.loadHistory() }
      } catch (e) {}
    },
    async viewHistoryDetail (row) {
      try {
        const r = await getToolTestDetail(row.id)
        if (r.code === 0) { this.detailLog = r.data; this.detailVisible = true }
      } catch (e) {}
    },
    retest (row) {
      // 回填历史参数并重新测试
      if (row.request_params) this.formData = row.request_params
      this.sendTest()
    }
  }
}
</script>

<style scoped>
.page { padding: 16px; background: #f0f2f5; min-height: 100%; }
.head-card { margin-bottom: 16px; }
.head-row { display: flex; justify-content: space-between; align-items: center; }
.head-left { display: flex; align-items: center; gap: 12px; }
.head-icon { font-size: 32px; color: #409EFF; }
.head-title { font-size: 16px; font-weight: 600; color: #303133; }
.cat-tag { margin-left: 8px; }
.head-sub { font-size: 12px; color: #909399; margin-top: 2px; max-width: 400px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.head-right { display: flex; align-items: center; gap: 10px; }
.head-path { font-size: 13px; color: #606266; }
.main-row { margin-bottom: 16px; }
.col-card { margin-bottom: 0; }
.col-head { display: flex; justify-content: space-between; align-items: center; }
.col-title { font-size: 15px; font-weight: 600; color: #303133; }
.header-collapse { margin-bottom: 12px; }
.header-pre { background: #f8f9fb; border-radius: 6px; padding: 8px; font-size: 12px; overflow-x: auto; max-height: 150px; }
.form-actions { margin-top: 12px; }
.result-overview { display: flex; align-items: center; gap: 10px; }
.result-time { font-size: 13px; color: #606266; }
.test-error { color: #F56C6C; padding: 12px; background: #fef0f0; border-radius: 6px; }
.result-footer { display: flex; justify-content: space-between; align-items: center; margin-top: 12px; }
.result-size { font-size: 13px; color: #909399; }
.hist-card { margin-bottom: 16px; }
.pager { margin-top: 12px; text-align: right; }
.detail-row { font-size: 13px; color: #606266; margin-bottom: 6px; }
.detail-block { margin-top: 10px; }
.detail-label { font-size: 13px; font-weight: 600; color: #909399; margin-bottom: 4px; }
.detail-error { color: #F56C6C; font-size: 13px; }
</style>
