<template>
  <div class="logistics-page">
    <!-- 一、配置列表 -->
    <el-card shadow="never" class="sec-card">
      <div slot="header" class="sec-head">
        <span class="sec-title">物流服务配置</span>
        <span class="sec-desc">对接多家物流API，为采购订单跟踪等模块提供统一查询与订阅推送</span>
      </div>
      <div class="toolbar">
        <div class="toolbar-left">
          <el-select v-model="filter.provider" clearable placeholder="全部服务商" style="width:160px" @change="loadList">
            <el-option v-for="p in PROVIDER_OPTIONS" :key="p.code" :label="p.name" :value="p.code" />
          </el-select>
          <el-select v-model="filter.enabled" clearable placeholder="全部状态" style="width:110px" @change="loadList">
            <el-option label="已启用" value="1" />
            <el-option label="已停用" value="0" />
          </el-select>
        </div>
        <el-button type="primary" size="small" icon="el-icon-plus" @click="openDialog()">添加服务商</el-button>
      </div>

      <el-table :data="list" v-loading="loading" size="small" stripe border>
        <el-table-column prop="provider_name" label="服务商" min-width="150">
          <template slot-scope="{ row }">
            <div>{{ row.provider_name }}</div>
            <div class="sub-text">{{ row.provider_name_text }}（{{ row.provider_code }}）</div>
          </template>
        </el-table-column>
        <el-table-column label="状态" width="90" align="center">
          <template slot-scope="{ row }">
            <el-tag size="mini" :type="row.is_enabled === 1 ? 'success' : 'info'">{{ row.is_enabled === 1 ? '已启用' : '已停用' }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column label="默认" width="90" align="center">
          <template slot-scope="{ row }">
            <el-tag size="mini" :type="row.is_default === 1 ? 'success' : 'info'">{{ row.is_default === 1 ? '是' : '否' }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column label="回调地址" min-width="280">
          <template slot-scope="{ row }">
            <div class="cb-row">
              <span class="cb-text">{{ row.callback_url || '-' }}</span>
              <el-button v-if="row.callback_url" type="text" size="mini" icon="el-icon-document-copy" @click="copyText(row.callback_url)">复制</el-button>
            </div>
          </template>
        </el-table-column>
        <el-table-column prop="update_time" label="更新时间" width="160" />
        <el-table-column label="操作" width="230" align="center" fixed="right">
          <template slot-scope="{ row }">
            <el-button type="text" size="mini" @click="openDialog(row)">编辑</el-button>
            <el-button type="text" size="mini" :loading="testingId === row.id" @click="testConn(row)">测试连接</el-button>
            <el-button v-if="row.is_default !== 1" type="text" size="mini" @click="setDefault(row)">设为默认</el-button>
            <el-button type="text" size="mini" @click="toggle(row)">{{ row.is_enabled === 1 ? '停用' : '启用' }}</el-button>
            <el-button type="text" size="mini" style="color:#F56C6C" @click="remove(row)">删除</el-button>
          </template>
        </el-table-column>
      </el-table>
      <el-pagination class="pager" background layout="total, prev, pager, next" :total="total" :current-page="page" :page-size="limit"
        @current-change="p => { page = p; loadList() }" />
    </el-card>

    <!-- 二、新增/编辑对话框 -->
    <el-dialog :title="form.id ? '编辑服务商' : '新增服务商'" :visible="dialogVisible" @update:visible="v => dialogVisible = v"
      width="620px" top="6vh" :close-on-click-modal="false">
      <el-form :model="form" :rules="rules" ref="form" label-width="130px" size="small">
        <el-form-item label="服务商" prop="provider_code">
          <el-select v-model="form.provider_code" style="width:100%" :disabled="!!form.id" @change="onProviderChange">
            <el-option v-for="p in PROVIDER_OPTIONS" :key="p.code" :label="p.name" :value="p.code" />
          </el-select>
        </el-form-item>
        <el-form-item label="服务商名称" prop="provider_name">
          <el-input v-model="form.provider_name" placeholder="自定义名称，便于识别（如：快递鸟主账号）" maxlength="50" />
        </el-form-item>
        <el-form-item label="App Key" prop="app_key">
          <el-input v-model="form.app_key" type="password" show-password :placeholder="keyPlaceholder" maxlength="200" />
        </el-form-item>
        <el-form-item label="App Secret" prop="app_secret">
          <el-input v-model="form.app_secret" type="password" show-password :placeholder="secretPlaceholder" maxlength="200" />
        </el-form-item>
        <el-form-item v-if="needAppCode" label="App Code" prop="app_code">
          <el-input v-model="form.app_code" type="password" show-password :placeholder="appCodePlaceholder" maxlength="200" />
        </el-form-item>
        <el-form-item label="API地址" prop="api_url">
          <el-input v-model="form.api_url" placeholder="服务商提供的API端点（留空自动填充默认地址）" maxlength="255" />
        </el-form-item>
        <el-row :gutter="16">
          <el-col :span="12">
            <el-form-item label="是否启用">
              <el-switch v-model="form.is_enabled" :active-value="1" :inactive-value="0" active-text="启用" inactive-text="停用" />
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="是否默认">
              <el-switch v-model="form.is_default" :active-value="1" :inactive-value="0" />
              <div class="sub-text">设为默认后业务模块优先调用</div>
            </el-form-item>
          </el-col>
        </el-row>
        <el-form-item label="排序"><el-input-number v-model="form.sort" :min="0" :max="999" style="width:140px" /></el-form-item>
        <el-form-item label="备注"><el-input v-model="form.remark" type="textarea" :rows="2" maxlength="255" placeholder="选填" /></el-form-item>
      </el-form>
      <div v-if="form.id && form.callback_url" class="cb-note">
        <b>推送回调地址：</b>{{ form.callback_url }}<el-button type="text" size="mini" icon="el-icon-document-copy" @click="copyText(form.callback_url)">复制</el-button>
      </div>
      <span slot="footer">
        <el-button size="small" @click="dialogVisible = false">取消</el-button>
        <el-button size="small" type="primary" :loading="saving" @click="submit">保存</el-button>
      </span>
    </el-dialog>

    <!-- 三、调用日志 -->
    <el-card shadow="never" class="sec-card">
      <div slot="header" class="sec-head"><span class="sec-title">调用日志</span><span class="sec-desc">记录查询/订阅/推送回调，便于排查问题与统计用量</span></div>
      <div class="toolbar">
        <div class="toolbar-left">
          <el-select v-model="logFilter.provider" clearable placeholder="全部服务商" style="width:150px" @change="loadLogs">
            <el-option v-for="p in PROVIDER_OPTIONS" :key="p.code" :label="p.name" :value="p.code" />
          </el-select>
          <el-select v-model="logFilter.api_method" clearable placeholder="全部方法" style="width:110px" @change="loadLogs">
            <el-option label="轨迹查询" value="query" />
            <el-option label="订阅推送" value="subscribe" />
            <el-option label="推送回调" value="callback" />
          </el-select>
          <el-select v-model="logFilter.status" clearable placeholder="全部状态" style="width:100px" @change="loadLogs">
            <el-option label="成功" value="1" />
            <el-option label="失败" value="0" />
          </el-select>
          <el-button size="small" icon="el-icon-refresh" @click="loadLogs">刷新</el-button>
        </div>
      </div>
      <el-table :data="logs" v-loading="logLoading" size="small" stripe border>
        <el-table-column prop="provider_name" label="服务商" width="120" />
        <el-table-column prop="api_method_text" label="方法" width="100" align="center" />
        <el-table-column label="状态" width="80" align="center">
          <template slot-scope="{ row }"><el-tag size="mini" :type="row.status === 1 ? 'success' : 'danger'">{{ row.status === 1 ? '成功' : '失败' }}</el-tag></template>
        </el-table-column>
        <el-table-column prop="error_message" label="错误信息" min-width="180" show-overflow-tooltip />
        <el-table-column prop="ip" label="调用方IP" width="130" />
        <el-table-column prop="create_time" label="调用时间" width="160" />
        <el-table-column label="操作" width="80" align="center">
          <template slot-scope="{ row }"><el-button type="text" size="mini" @click="openLogDetail(row)">详情</el-button></template>
        </el-table-column>
      </el-table>
      <el-pagination class="pager" background layout="total, prev, pager, next" :total="logTotal" :current-page="logPage" :page-size="logLimit"
        @current-change="p => { logPage = p; loadLogs() }" />
    </el-card>

    <!-- 日志详情弹窗 -->
    <el-dialog title="调用日志详情" :visible="logDetailVisible" @update:visible="v => logDetailVisible = v" width="680px" top="6vh">
      <div class="log-detail">
        <div class="log-line"><b>服务商：</b>{{ currentLog.provider_name }}（{{ currentLog.provider_code }}）｜{{ currentLog.api_method_text }}｜{{ currentLog.create_time }}</div>
        <div class="log-sec-title">请求参数</div>
        <pre>{{ prettyJson(currentLog.request_params) }}</pre>
        <div class="log-sec-title">返回数据</div>
        <pre>{{ prettyJson(currentLog.response_data) }}</pre>
        <div v-if="currentLog.error_message" class="log-sec-title">错误信息</div>
        <pre v-if="currentLog.error_message" class="err-text">{{ currentLog.error_message }}</pre>
      </div>
    </el-dialog>
  </div>
</template>

<script>
import {
  getLogisticsList, saveLogistics, updateLogistics, deleteLogistics,
  testLogistics, setDefaultLogistics, toggleLogistics, getLogisticsLogs
} from '@/api/serviceLogistics'

const PROVIDER_OPTIONS = [
  { code: 'kdniao', name: '快递鸟', needAppCode: false },
  { code: 'kuaidi100', name: '快递100', needAppCode: true },
  { code: 'aliyun_express', name: '阿里云快递查询', needAppCode: true },
  { code: 'aliyun_cainiao', name: '菜鸟物流', needAppCode: false }
]
const DEFAULT_API_URLS = {
  kdniao: 'https://api.kdniao.com/api/dist',
  kuaidi100: 'https://kd100api.kuaidi100.com/express/poll',
  aliyun_express: 'https://route.showapi.com/2650-3',
  aliyun_cainiao: ''
}

export default {
  name: 'ServiceLogistics',
  data () {
    return {
      PROVIDER_OPTIONS,
      list: [], total: 0, page: 1, limit: 20, loading: false,
      filter: { provider: '', enabled: '' },
      dialogVisible: false, saving: false, form: this.emptyForm(),
      testingId: 0,
      logs: [], logTotal: 0, logPage: 1, logLimit: 10, logLoading: false,
      logFilter: { provider: '', api_method: '', status: '' },
      logDetailVisible: false, currentLog: {}
    }
  },
  computed: {
    needAppCode () {
      const p = PROVIDER_OPTIONS.find(x => x.code === this.form.provider_code)
      return !!(p && p.needAppCode)
    },
    keyPlaceholder () {
      if (this.form.provider_code === 'aliyun_express') return 'AppKey（签名方式用，APPCODE 方式可留空）'
      if (this.form.provider_code === 'kuaidi100') return 'AppKey（经典网关签名用，填 AppCode 可留空）'
      if (this.form.provider_code === 'aliyun_cainiao') return '选填'
      return 'API密钥（必填）'
    },
    secretPlaceholder () {
      if (this.form.provider_code === 'aliyun_express' || this.form.provider_code === 'kuaidi100' || this.form.provider_code === 'aliyun_cainiao') return '选填（未使用可留空）'
      return 'API密钥（必填，编辑时保持 ****** 即不修改）'
    },
    appCodePlaceholder () {
      if (this.form.provider_code === 'aliyun_express') return '阿里云市场 AppCode（选填；已填 AppKey 可留空）'
      if (this.form.provider_code === 'kuaidi100') return '快递100 AppCode（APPCODE 简单认证，填了可留空 AppKey）'
      return 'AppCode（选填）'
    },
    rules () {
      const rules = {
        provider_code: [{ required: true, message: '请选择服务商', trigger: 'change' }],
        provider_name: [{ required: true, message: '服务商名称必填', trigger: 'blur' }],
        api_url: [{ required: true, message: 'API地址必填', trigger: 'blur' }]
      }
      if (this.form.provider_code === 'aliyun_express' || this.form.provider_code === 'kuaidi100') {
        // 阿里云/快递100：AppKey 或 AppCode 至少填一个
        rules.app_key = [{
          validator: (rule, value, cb) => {
            if ((value || '').trim() || (this.form.app_code || '').trim()) cb()
            else cb(new Error('AppKey 或 AppCode 至少填一个'))
          }, trigger: 'blur'
        }]
      } else if (this.form.provider_code !== 'aliyun_cainiao') {
        rules.app_key = [{ required: true, message: 'App Key 必填', trigger: 'blur' }]
        rules.app_secret = [{ required: true, message: 'App Secret 必填', trigger: 'blur' }]
      }
      return rules
    }
  },
  created () { this.loadList(); this.loadLogs() },
  methods: {
    emptyForm () {
      return {
        id: 0, provider_code: 'kdniao', provider_name: '', app_key: '', app_secret: '',
        app_code: '', api_url: DEFAULT_API_URLS.kdniao, is_enabled: 1, is_default: 0,
        sort: 0, remark: '', callback_url: ''
      }
    },
    onProviderChange (code) {
      // 若当前 API 地址为空或仍是某服务商的默认地址（用户未手改），切换时自动替换为新服务商默认地址
      const oldDefaults = Object.values(DEFAULT_API_URLS)
      if (!this.form.api_url || oldDefaults.includes(this.form.api_url)) {
        this.form.api_url = DEFAULT_API_URLS[code] || ''
      }
    },
    async loadList () {
      this.loading = true
      try {
        const params = { page: this.page, limit: this.limit }
        if (this.filter.provider) params.provider = this.filter.provider
        if (this.filter.enabled !== '') params.enabled = this.filter.enabled
        const r = await getLogisticsList(params)
        if (r.code === 0) { this.list = r.data.list || []; this.total = r.data.total || 0 }
      } catch (e) {} finally { this.loading = false }
    },
    openDialog (row) {
      if (row) {
        this.form = {
          id: row.id, provider_code: row.provider_code, provider_name: row.provider_name,
          app_key: row.app_key || '', app_secret: row.app_secret || '', app_code: row.app_code || '',
          api_url: row.api_url || '', is_enabled: row.is_enabled === 0 ? 0 : 1, is_default: row.is_default === 1 ? 1 : 0,
          sort: row.sort || 0, remark: row.remark || '', callback_url: row.callback_url || ''
        }
      } else {
        this.form = this.emptyForm()
      }
      this.dialogVisible = true
      this.$nextTick(() => { if (this.$refs.form) this.$refs.form.clearValidate() })
    },
    async submit () {
      try { await this.$refs.form.validate() } catch (e) { return }
      this.saving = true
      try {
        const payload = { ...this.form }
        const r = this.form.id ? await updateLogistics(this.form.id, payload) : await saveLogistics(payload)
        if (r.code === 0) {
          this.$message.success('保存成功')
          this.dialogVisible = false
          this.loadList()
        } else {
          this.$message.error(r.msg || '保存失败')
        }
      } catch (e) {} finally { this.saving = false }
    },
    async testConn (row) {
      this.testingId = row.id
      try {
        const r = await testLogistics(row.id)
        if (r.code === 0 && r.data) {
          const d = r.data
          this.$alert(d.message, '测试连接', { type: d.success ? 'success' : 'error', confirmButtonText: '知道了' })
        }
      } catch (e) {} finally { this.testingId = 0 }
    },
    setDefault (row) {
      this.$confirm(`确认将「${row.provider_name}」设为默认物流服务商？`, '设为默认', { type: 'warning' }).then(async () => {
        try {
          const r = await setDefaultLogistics(row.id)
          if (r.code === 0) { this.$message.success('已设为默认'); this.loadList() }
        } catch (e) {}
      }).catch(() => {})
    },
    toggle (row) {
      this.$confirm(`确认${row.is_enabled === 1 ? '停用' : '启用'}「${row.provider_name}」？`, '状态变更', { type: 'warning' }).then(async () => {
        try {
          const r = await toggleLogistics(row.id)
          if (r.code === 0) { this.$message.success(r.msg || '操作成功'); this.loadList() }
        } catch (e) {}
      }).catch(() => {})
    },
    remove (row) {
      this.$confirm(`确认删除物流服务商「${row.provider_name}」？删除后该配置不可恢复。`, '删除确认', { type: 'error' }).then(async () => {
        try {
          const r = await deleteLogistics(row.id)
          if (r.code === 0) { this.$message.success('已删除'); this.loadList() }
        } catch (e) {}
      }).catch(() => {})
    },
    copyText (text) {
      const ta = document.createElement('textarea')
      ta.value = text
      ta.style.position = 'fixed'
      ta.style.opacity = '0'
      document.body.appendChild(ta)
      ta.select()
      try { document.execCommand('copy'); this.$message.success('已复制') } catch (e) { this.$message.warning('复制失败，请手动复制') }
      document.body.removeChild(ta)
    },
    async loadLogs () {
      this.logLoading = true
      try {
        const params = { page: this.logPage, limit: this.logLimit }
        if (this.logFilter.provider) params.provider = this.logFilter.provider
        if (this.logFilter.api_method) params.api_method = this.logFilter.api_method
        if (this.logFilter.status !== '') params.status = this.logFilter.status
        const r = await getLogisticsLogs(params)
        if (r.code === 0) { this.logs = r.data.list || []; this.logTotal = r.data.total || 0 }
      } catch (e) {} finally { this.logLoading = false }
    },
    openLogDetail (row) { this.currentLog = row; this.logDetailVisible = true },
    prettyJson (s) {
      if (!s) return ''
      try { return JSON.stringify(JSON.parse(s), null, 2) } catch (e) { return String(s) }
    }
  }
}
</script>

<style scoped>
.logistics-page { padding: 16px; background: #f0f2f5; min-height: 100%; }
.sec-card { margin-bottom: 16px; }
.sec-head { display: flex; align-items: baseline; gap: 12px; }
.sec-title { font-size: 15px; font-weight: 600; color: #303133; }
.sec-desc { font-size: 12px; color: #909399; }
.toolbar { display: flex; justify-content: space-between; align-items: center; margin-bottom: 12px; }
.toolbar-left { display: flex; gap: 8px; }
.sub-text { font-size: 12px; color: #909399; }
.cb-row { display: flex; align-items: center; gap: 6px; }
.cb-text { font-size: 12px; color: #606266; word-break: break-all; flex: 1; }
.cb-note { font-size: 13px; color: #606266; background: #f5f7fa; border: 1px solid #e4e7ed; border-radius: 4px; padding: 8px 10px; margin-top: 4px; }
.pager { margin-top: 12px; text-align: right; }
.log-detail { font-size: 13px; color: #303133; }
.log-line { margin-bottom: 8px; }
.log-sec-title { font-size: 12px; color: #909399; margin: 8px 0 4px; }
.log-detail pre { background: #f5f7fa; border: 1px solid #e4e7ed; border-radius: 4px; padding: 8px; font-size: 12px; white-space: pre-wrap; word-break: break-all; max-height: 240px; overflow-y: auto; margin: 0; }
.log-detail pre.err-text { color: #F56C6C; }
</style>
