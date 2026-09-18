<template>
  <div class="esign-page">
    <!-- 一、服务基本信息 -->
    <el-card shadow="never" class="sec-card">
      <div slot="header" class="sec-head"><span class="sec-title">服务基本信息</span><span class="sec-desc">腾讯电子签 AccessToken 模式（Bearer 认证）</span></div>
      <el-form :model="form" label-width="140px" size="small">
        <el-row :gutter="24">
          <el-col :span="12">
            <el-form-item label="服务名称"><el-input v-model="form.service_name" disabled /></el-form-item>
            <el-form-item label="环境选择">
              <el-select v-model="form.environment" style="width:100%">
                <el-option label="测试环境" value="test" />
                <el-option label="生产环境" value="production" />
              </el-select>
            </el-form-item>
            <el-form-item label="SecretId" required><el-input v-model="form.secret_id" placeholder="腾讯云API密钥ID（必填）" /></el-form-item>
            <el-form-item label="AppId" required><el-input v-model="form.app_id" placeholder="电子签应用ID（必填）" /></el-form-item>
            <el-form-item label="空间ID (SpaceId)" required><el-input v-model="form.space_id" placeholder="标识应用所属空间（必填）" /></el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="服务状态">
              <el-switch v-model="form.status" :active-value="1" :inactive-value="0" active-text="启用" inactive-text="停用" />
            </el-form-item>
            <el-form-item label="SecretKey" required>
              <el-input v-model="form.secret_key" type="password" show-password placeholder="腾讯云API密钥（必填，加密存储）" />
            </el-form-item>
            <el-form-item label="Endpoint"><el-input :value="endpointText" readonly /></el-form-item>
            <el-form-item label="回调地址">
              <el-input :value="callbackUrl" readonly>
                <template slot="append"><el-button size="mini" @click="copyText(callbackUrl)">复制</el-button></template>
              </el-input>
            </el-form-item>
            <el-form-item label="加密Key">
              <el-input v-model="form.encrypt_key" type="password" show-password placeholder="回调消息解密Key（留空自动生成）">
                <template slot="append"><el-button size="mini" @click="copyText(encryptKeyPlain)">复制</el-button></template>
              </el-input>
            </el-form-item>
          </el-col>
        </el-row>
        <el-form-item><el-button type="primary" size="small" :loading="saving" @click="saveConfig">保存配置</el-button></el-form-item>
      </el-form>
    </el-card>

    <!-- 二、签署配置 -->
    <el-card shadow="never" class="sec-card">
      <div slot="header" class="sec-head"><span class="sec-title">签署配置</span><span class="sec-desc">合同发起签署时的默认参数</span></div>
      <el-form :model="form" label-width="140px" size="small">
        <el-row :gutter="24">
          <el-col :span="12">
            <el-form-item label="默认签署方式">
              <el-select v-model="form.default_sign_type" style="width:100%">
                <el-option label="静默签署" value="silent" />
                <el-option label="手动签署" value="manual" />
              </el-select>
            </el-form-item>
            <el-form-item label="签署到期天数"><el-input-number v-model="form.sign_expire_days" :min="1" :max="90" style="width:100%" /></el-form-item>
            <el-form-item label="企业印章ID (SealId)"><el-input v-model="form.seal_id" placeholder="电子签控制台印章管理获取" /></el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="签署通知方式">
              <el-select v-model="form.notify_channels" multiple collapse-tags placeholder="选择通知渠道" style="width:100%">
                <el-option label="短信" value="sms" />
                <el-option label="微信" value="wechat" />
                <el-option label="邮件" value="email" />
              </el-select>
            </el-form-item>
            <el-form-item label="操作人UserId"><el-input v-model="form.operator_user_id" placeholder="接口调用人员UserId" /></el-form-item>
          </el-col>
        </el-row>
        <el-form-item><el-button type="primary" size="small" :loading="saving" @click="saveConfig">保存配置</el-button></el-form-item>
      </el-form>
    </el-card>

    <!-- 三、连接测试 -->
    <el-card shadow="never" class="sec-card">
      <div slot="header" class="sec-head"><span class="sec-title">连接测试</span><span class="sec-desc">通过 SecretId/SecretKey 获取 AccessToken 验证连接</span></div>
      <el-button size="small" type="primary" :loading="testing" @click="testConnection">测试连接</el-button>
      <div v-if="testResult" class="test-result" :class="testResult.success ? 'ok' : 'err'">
        {{ testResult.message }}（{{ testResult.response_time }}）｜Token获取：{{ testResult.token_ok ? '正常' : '失败' }}
      </div>
    </el-card>

    <!-- 四、模板管理 -->
    <el-card shadow="never" class="sec-card">
      <div slot="header" class="sec-head">
        <span class="sec-title">签署模板管理</span>
        <span class="sec-desc">从电子签平台同步模板到本地，供合同发起时选择</span>
        <div style="margin-left:auto;">
          <el-button size="small" type="primary" plain :loading="syncing" @click="syncTemplates">同步模板</el-button>
        </div>
      </div>
      <el-table :data="templates" size="small" stripe v-loading="tplLoading">
        <el-table-column prop="template_id" label="模板ID" min-width="180" show-overflow-tooltip />
        <el-table-column prop="template_name" label="模板名称" min-width="160" show-overflow-tooltip />
        <el-table-column prop="template_type" label="模板类型" width="110" />
        <el-table-column prop="description" label="描述" min-width="160" show-overflow-tooltip />
        <el-table-column prop="sync_time" label="同步时间" width="170" />
        <el-table-column label="操作" width="100" align="center">
          <template slot-scope="s">
            <el-button size="mini" type="text" @click="copyText(s.row.template_id)">复制ID</el-button>
          </template>
        </el-table-column>
      </el-table>
    </el-card>

    <!-- 五、签署日志 -->
    <el-card shadow="never" class="sec-card">
      <div slot="header" class="sec-head"><span class="sec-title">签署日志</span><span class="sec-desc">系统发起的电子签签署记录</span></div>
      <div class="toolbar">
        <el-select v-model="logQuery.sign_status" size="small" clearable placeholder="签署状态" style="width:140px">
          <el-option v-for="(t, k) in SIGN_STATUS_TEXT" :key="k" :label="t" :value="k" />
        </el-select>
        <el-date-picker
          v-model="logQuery.timeRange" type="daterange" size="small" range-separator="至"
          start-placeholder="开始日期" end-placeholder="结束日期" value-format="yyyy-MM-dd" style="margin-left:10px;"
        />
        <el-input v-model="logQuery.keyword" size="small" placeholder="合同编号/流程ID/名称" clearable style="width:220px;margin-left:10px;" @keyup.enter.native="loadLogs(1)" />
        <el-button size="small" type="primary" style="margin-left:10px;" @click="loadLogs(1)">搜索</el-button>
        <el-button size="small" @click="resetLogQuery">重置</el-button>
      </div>
      <el-table :data="logRows" size="small" stripe v-loading="logLoading">
        <el-table-column prop="contract_no" label="合同编号" width="160" show-overflow-tooltip />
        <el-table-column prop="flow_id" label="签署流程ID" min-width="180" show-overflow-tooltip />
        <el-table-column prop="operator_name" label="发起人" width="100" />
        <el-table-column prop="create_time" label="发起时间" width="170" />
        <el-table-column prop="sign_status_text" label="签署状态" width="100" align="center">
          <template slot-scope="s">
            <el-tag size="mini" :type="signStatusTag(s.row.sign_status)">{{ s.row.sign_status_text }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="sign_time" label="完成时间" width="170" />
        <el-table-column label="操作" width="90" align="center">
          <template slot-scope="s">
            <el-button size="mini" type="text" @click="showLogDetail(s.row)">详情</el-button>
          </template>
        </el-table-column>
      </el-table>
      <div class="pager">
        <el-pagination background layout="total, prev, pager, next" :total="logTotal" :page-size="logLimit" :current-page="logPage" @current-change="loadLogs" />
      </div>
    </el-card>

    <!-- 签署日志详情弹窗 -->
    <el-dialog title="签署日志详情" :visible.sync="detailVisible" width="720px">
      <el-descriptions :column="1" border size="small" v-if="logDetail">
        <el-descriptions-item label="合同编号">{{ logDetail.contract_no || '-' }}</el-descriptions-item>
        <el-descriptions-item label="流程名称">{{ logDetail.flow_name || '-' }}</el-descriptions-item>
        <el-descriptions-item label="签署流程ID">{{ logDetail.flow_id || '-' }}</el-descriptions-item>
        <el-descriptions-item label="签署状态"><el-tag size="mini" :type="signStatusTag(logDetail.sign_status)">{{ logDetail.sign_status_text }}</el-tag></el-descriptions-item>
        <el-descriptions-item label="签署链接">{{ logDetail.sign_url || '-' }}</el-descriptions-item>
        <el-descriptions-item label="发起人">{{ logDetail.operator_name || '-' }}</el-descriptions-item>
        <el-descriptions-item label="发起时间">{{ logDetail.create_time || '-' }}</el-descriptions-item>
        <el-descriptions-item label="完成时间">{{ logDetail.sign_time || '-' }}</el-descriptions-item>
        <el-descriptions-item label="错误信息">{{ logDetail.error_message || '-' }}</el-descriptions-item>
        <el-descriptions-item label="回调数据"><pre class="pre-wrap">{{ logDetail.callback_data || '-' }}</pre></el-descriptions-item>
      </el-descriptions>
    </el-dialog>
  </div>
</template>

<script>
import { getEsignConfig, saveEsignConfig, testEsign, getEsignTemplates, syncEsignTemplates, getEsignLogs, getEsignLogDetail } from '@/api/serviceEsign'

const SIGN_STATUS_TEXT = { pending: '待签署', signing: '签署中', signed: '已签署', expired: '已过期', rejected: '已拒签' }

export default {
  name: 'ServiceEsign',
  data () {
    return {
      SIGN_STATUS_TEXT,
      form: {
        service_name: '腾讯电子签服务', status: 1, environment: 'test',
        secret_id: '', secret_key: '', app_id: '', space_id: '', endpoint: '', callback_url: '', encrypt_key: '',
        default_sign_type: 'manual', sign_expire_days: 7, notify_channels: ['sms', 'wechat'], seal_id: '', operator_user_id: ''
      },
      saving: false, testing: false, testResult: null,
      templates: [], tplLoading: false, syncing: false,
      logRows: [], logTotal: 0, logPage: 1, logLimit: 15, logLoading: false,
      logQuery: { sign_status: '', timeRange: null, keyword: '' },
      detailVisible: false, logDetail: null
    }
  },
  computed: {
    endpointText () {
      return this.form.endpoint || (this.form.environment === 'production' ? 'ess.tencentcloudapi.com' : 'ess.test.ess.tencent.cn')
    },
    callbackUrl () { return this.form.callback_url || (window.location.origin || '') + '/api/business/contract/sign/callback' },
    encryptKeyPlain () {
      // 掩码状态下无明文可复制；保存前用户输入/自动生成后可见
      return (this.form.encrypt_key && this.form.encrypt_key !== '******') ? this.form.encrypt_key : ''
    }
  },
  created () { this.loadConfig(); this.loadTemplates(); this.loadLogs() },
  methods: {
    async loadConfig () {
      try {
        const r = await getEsignConfig()
        if (r.code === 0) {
          const d = r.data || {}
          this.form = {
            service_name: d.service_name || '腾讯电子签服务', status: d.status === 0 ? 0 : 1, environment: d.environment || 'test',
            secret_id: d.secret_id || '', secret_key: d.secret_key ? '******' : '', app_id: d.app_id || '', space_id: d.space_id || '',
            endpoint: d.endpoint || '', callback_url: d.callback_url || '', encrypt_key: d.encrypt_key ? '******' : '',
            default_sign_type: d.default_sign_type || 'manual', sign_expire_days: d.sign_expire_days || 7,
            notify_channels: Array.isArray(d.notify_channels) ? d.notify_channels : ((d.notify_channels || '').split(',').filter(Boolean)),
            seal_id: d.seal_id || '', operator_user_id: d.operator_user_id || ''
          }
        }
      } catch (e) {}
    },
    async saveConfig () {
      if (!this.form.secret_id) { this.$message.warning('SecretId 必填'); return }
      if (!this.form.app_id) { this.$message.warning('AppId 必填'); return }
      if (!this.form.space_id) { this.$message.warning('空间ID (SpaceId) 必填'); return }
      if (!this.form.secret_key) { this.$message.warning('SecretKey 必填'); return }
      this.saving = true
      try {
        const r = await saveEsignConfig({ ...this.form, notify_channels: this.form.notify_channels })
        if (r.code === 0) { this.$message.success(r.msg || '配置已保存'); this.loadConfig() }
      } catch (e) {} finally { this.saving = false }
    },
    async testConnection () {
      this.testing = true; this.testResult = null
      try {
        const r = await testEsign()
        if (r.code === 0 && r.data) this.testResult = r.data
      } catch (e) {} finally { this.testing = false }
    },
    async loadTemplates () {
      this.tplLoading = true
      try {
        const r = await getEsignTemplates()
        if (r.code === 0 && r.data) this.templates = r.data.list || []
      } catch (e) {} finally { this.tplLoading = false }
    },
    async syncTemplates () {
      this.$confirm('确认从电子签平台同步模板列表？', '同步模板', { type: 'warning' }).then(async () => {
        this.syncing = true
        try {
          const r = await syncEsignTemplates()
          if (r.code === 0) { this.$message.success(r.msg || '同步完成'); this.loadTemplates() }
        } catch (e) {} finally { this.syncing = false }
      }).catch(() => {})
    },
    async loadLogs (page) {
      this.logPage = page || this.logPage
      this.logLoading = true
      try {
        const params = { page: this.logPage, limit: this.logLimit, sign_status: this.logQuery.sign_status, keyword: this.logQuery.keyword }
        if (this.logQuery.timeRange && this.logQuery.timeRange.length === 2) {
          params.start_time = this.logQuery.timeRange[0]
          params.end_time = this.logQuery.timeRange[1]
        }
        const r = await getEsignLogs(params)
        if (r.code === 0 && r.data) { this.logRows = r.data.list || []; this.logTotal = r.data.total || 0 }
      } catch (e) {} finally { this.logLoading = false }
    },
    resetLogQuery () {
      this.logQuery = { sign_status: '', timeRange: null, keyword: '' }
      this.loadLogs(1)
    },
    signStatusTag (s) {
      return { pending: 'info', signing: 'primary', signed: 'success', expired: 'danger', rejected: 'danger' }[s] || 'info'
    },
    async showLogDetail (row) {
      try {
        const r = await getEsignLogDetail(row.id)
        if (r.code === 0) { this.logDetail = r.data || {}; this.detailVisible = true }
      } catch (e) {}
    },
    copyText (text) {
      if (!text) { this.$message.warning('暂无可复制内容'); return }
      if (navigator.clipboard && navigator.clipboard.writeText) {
        navigator.clipboard.writeText(text).then(() => this.$message.success('已复制')).catch(() => this.fallbackCopy(text))
      } else {
        this.fallbackCopy(text)
      }
    },
    fallbackCopy (text) {
      const ta = document.createElement('textarea')
      ta.value = text
      document.body.appendChild(ta)
      ta.select()
      try { document.execCommand('copy'); this.$message.success('已复制') } catch (e) { this.$message.warning('复制失败，请手动复制') }
      document.body.removeChild(ta)
    }
  }
}
</script>

<style scoped>
.esign-page { padding: 16px; background: #f0f2f5; min-height: 100%; }
.sec-card { margin-bottom: 16px; }
.sec-head { display: flex; align-items: baseline; gap: 12px; }
.sec-title { font-size: 15px; font-weight: 600; color: #303133; }
.sec-desc { font-size: 12px; color: #909399; }
.test-result { margin-top: 12px; font-size: 13px; }
.test-result.ok { color: #67C23A; }
.test-result.err { color: #F56C6C; }
.toolbar { margin-bottom: 12px; display: flex; align-items: center; flex-wrap: wrap; }
.pager { margin-top: 12px; text-align: right; }
.pre-wrap { white-space: pre-wrap; word-break: break-all; margin: 0; font-size: 12px; color: #606266; }
</style>
