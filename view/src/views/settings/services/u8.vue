<template>
  <div class="u8-page">
    <!-- 一、U8服务配置 -->
    <el-card shadow="never" class="sec-card">
      <div slot="header" class="sec-head"><span class="sec-title">U8服务配置</span></div>
      <el-form :model="form" label-width="130px" size="small">
        <el-row :gutter="24">
          <el-col :span="12">
            <el-form-item label="服务名称"><el-input v-model="form.service_name" disabled /></el-form-item>
            <el-form-item label="U8接口地址"><el-input v-model="form.base_url" placeholder="必填" /></el-form-item>
            <el-form-item label="调用方ID (from_account)"><el-input v-model="form.from_account" placeholder="必填" /></el-form-item>
            <el-form-item label="提供方ID (to_account)"><el-input v-model="form.to_account" placeholder="必填" /></el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="AppKey"><el-input v-model="form.app_key" placeholder="必填" /></el-form-item>
            <el-form-item label="AppSecret"><el-input v-model="form.app_secret" type="password" show-password placeholder="必填（加密存储）" /></el-form-item>
            <el-form-item label="数据源序号"><el-input-number v-model="form.ds_sequence" :min="1" style="width:100%" /></el-form-item>
            <el-form-item label="服务状态"><el-switch v-model="form.status" :active-value="1" :inactive-value="0" active-text="启用" inactive-text="停用" /></el-form-item>
          </el-col>
        </el-row>
        <el-form-item><el-button type="primary" size="small" :loading="saving" @click="saveConfig">保存配置</el-button></el-form-item>
      </el-form>
    </el-card>

    <!-- 二、EAI接口配置 -->
    <el-card shadow="never" class="sec-card">
      <div slot="header" class="sec-head"><span class="sec-title">EAI接口配置</span></div>
      <el-form label-width="130px" size="small">
        <el-form-item label="EAI接口地址"><el-input v-model="form.eai_url" placeholder="http://U8服务器IP:端口/EAI" /></el-form-item>
        <el-form-item label="EAI系统编码"><el-input v-model="form.eai_system_code" placeholder="请输入EAI外部系统编码" /></el-form-item>
        <el-form-item label="EAI默认登录账号"><el-input v-model="form.eai_default_user" placeholder="请输入U8登录账号" /></el-form-item>
        <el-form-item><el-button type="primary" size="small" :loading="saving" @click="saveConfig">保存EAI配置</el-button></el-form-item>
      </el-form>
    </el-card>

    <!-- 三、连接测试 -->
    <el-card shadow="never" class="sec-card">
      <div slot="header" class="sec-head"><span class="sec-title">连接测试</span><span class="sec-desc">测试U8 OpenAPI连接是否正常</span></div>
      <el-button size="small" type="primary" :loading="testing" @click="testConnection">测试连接</el-button>
      <div v-if="testResult" class="test-result" :class="testResult.success ? 'ok' : 'err'">
        {{ testResult.message }}（{{ testResult.response_time }}）｜Token获取：{{ testResult.token_ok ? '正常' : '失败' }}
      </div>
    </el-card>

    <!-- 四、数据同步配置 -->
    <el-card shadow="never" class="sec-card">
      <div slot="header" class="sec-head"><span class="sec-title">数据同步配置</span><span class="sec-desc">仅同步单据状态，不重新提交单据</span></div>
      <el-form label-width="130px" size="small">
        <el-row :gutter="24">
          <el-col :span="12">
            <el-form-item label="同步开关"><el-switch v-model="form.sync_enabled" :active-value="1" :inactive-value="0" /></el-form-item>
            <el-form-item label="同步频率"><el-select v-model="form.sync_frequency" style="width:200px"><el-option label="每小时" value="hourly" /><el-option label="每天" value="daily" /><el-option label="每周" value="weekly" /></el-select></el-form-item>
            <el-form-item v-if="form.sync_frequency === 'daily'" label="同步时间"><el-time-picker v-model="form.sync_time" format="HH:mm" value-format="HH:mm" style="width:200px" /></el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="同步数据类型">
              <el-select v-model="syncDataTypes" multiple collapse-tags placeholder="选择同步类型" style="width:100%">
                <el-option v-for="(t, k) in DATA_TYPE_OPTIONS" :key="k" :label="t" :value="k" />
              </el-select>
            </el-form-item>
            <el-form-item>
              <el-button type="primary" size="small" :loading="syncing" @click="doSync">立即同步</el-button>
              <span class="sync-status">同步状态：<el-tag size="mini" :type="syncStatusTag">{{ syncStatusText }}</el-tag></span>
            </el-form-item>
          </el-col>
        </el-row>
      </el-form>
    </el-card>

    <!-- 五、服务状态 -->
    <el-card shadow="never" class="sec-card">
      <div slot="header" class="sec-head"><span class="sec-title">服务状态</span></div>
      <el-row :gutter="16">
        <el-col :span="6"><div class="state-item">服务健康状态：<el-tag size="mini" :type="form.status ? 'success' : 'info'">{{ form.status ? '正常' : '停用' }}</el-tag></div></el-col>
        <el-col :span="6"><div class="state-item">U8连接状态：<el-tag size="mini" :type="syncStatus.connected ? 'success' : 'info'">{{ syncStatus.connected ? '已连接' : '未连接' }}</el-tag></div></el-col>
        <el-col :span="6"><div class="state-item">最后同步时间：{{ syncStatus.last_sync_time || '-' }}</div></el-col>
        <el-col :span="6"><div class="state-item">同步状态：{{ syncStatusText }}</div></el-col>
      </el-row>
      <div class="state-item" v-if="syncStatus.data_counts">同步数据量：
        <span v-for="c in syncStatus.data_counts" :key="c.data_type" style="margin-right:10px;">{{ c.label }} <b>{{ c.count }}</b> 条</span>
      </div>
      <div v-if="syncStatus.sync_error" class="sync-error">同步错误：{{ syncStatus.sync_error }}</div>
    </el-card>

    <!-- 六、同步日志 -->
    <el-card shadow="never" class="sec-card">
      <div slot="header" class="sec-head"><span class="sec-title">同步日志</span><span class="sec-desc">最近同步记录（明细随仓储模块单据同步接入）</span></div>
      <el-table :data="logRows" size="small" stripe>
        <el-table-column prop="sync_time" label="同步时间" width="180" />
        <el-table-column prop="data_type_text" label="数据类型" width="120" />
        <el-table-column prop="status_text" label="状态" width="90" align="center" />
        <el-table-column prop="record_count" label="记录数" width="90" align="center" />
        <el-table-column prop="error_msg" label="错误信息" min-width="200" show-overflow-tooltip />
      </el-table>
      <div class="log-tip">（自动同步/单据状态同步日志将在仓储模块数据表接入后逐条记录；当前展示最近一次同步状态。）</div>
    </el-card>

    <!-- 七、回调接口配置（U8 主动调用 数智管控平台） -->
    <el-card shadow="never" class="sec-card">
      <div slot="header" class="sec-head"><span class="sec-title">回调接口配置</span><span class="sec-desc">U8 处理完成后主动回调 数智管控平台 更新单据状态</span></div>
      <el-form label-width="130px" size="small">
        <el-form-item label="回调地址"><el-input :value="callbackUrl" readonly><template slot="append"><el-button size="mini" @click="copyCallbackUrl">复制</el-button></template></el-input></el-form-item>
        <el-form-item label="回调开关"><el-switch v-model="form.callback_enabled" :active-value="1" :inactive-value="0" active-text="启用" inactive-text="停用" /></el-form-item>
        <el-form-item label="签名密钥"><el-input v-model="form.callback_secret" type="password" show-password placeholder="首次启用必填；留空表示保持原密钥不变" /></el-form-item>
        <el-form-item><el-button type="primary" size="small" :loading="cbSaving" @click="saveCallbackConfig">保存回调配置</el-button></el-form-item>
      </el-form>
      <div class="log-tip">U8 侧需将回调地址配置为上方 URL，并使用同一签名密钥对通知参数签名（HMAC-SHA256）；接口支持重试与幂等，重复通知不会重复生效。</div>
    </el-card>

    <!-- 八、回调日志 -->
    <el-card shadow="never" class="sec-card">
      <div slot="header" class="sec-head"><span class="sec-title">回调日志</span><span class="sec-desc">U8 主动回调接收记录</span></div>
      <el-table :data="cbLogs" size="small" stripe v-loading="cbLoading">
        <el-table-column prop="create_time" label="接收时间" width="170" />
        <el-table-column prop="tradeid" label="交易流水号" min-width="150" show-overflow-tooltip />
        <el-table-column prop="biz_type_text" label="单据类型" width="110" />
        <el-table-column prop="biz_no" label="单据号" width="130" show-overflow-tooltip />
        <el-table-column prop="errcode" label="U8结果码" width="90" align="center" />
        <el-table-column prop="errmsg" label="U8描述" min-width="130" show-overflow-tooltip />
        <el-table-column prop="process_status_text" label="处理状态" width="110" align="center">
          <template slot-scope="s">
            <el-tag size="mini" :type="cbStatusTag(s.row.process_status)">{{ s.row.process_status_text }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="handle_msg" label="处理结果" min-width="150" show-overflow-tooltip />
      </el-table>
      <div class="pager">
        <el-pagination background layout="total, prev, pager, next" :total="cbTotal" :page-size="cbLimit" :current-page="cbPage" @current-change="loadCallbackLogs" />
      </div>
    </el-card>

    <!-- 九、单据状态台账 -->
    <el-card shadow="never" class="sec-card">
      <div slot="header" class="sec-head"><span class="sec-title">单据状态台账</span><span class="sec-desc">U8 主动回调更新的本地单据状态（业务闭环）</span></div>
      <el-table :data="docRows" size="small" stripe v-loading="docLoading">
        <el-table-column prop="biz_type_text" label="单据类型" width="120" />
        <el-table-column prop="biz_no" label="单据号" min-width="140" show-overflow-tooltip />
        <el-table-column prop="doc_status_text" label="单据状态" width="110" align="center">
          <template slot-scope="s">
            <el-tag size="mini" :type="docStatusTag(s.row.doc_status)">{{ s.row.doc_status_text }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="u8_errcode" label="U8结果码" width="90" align="center" />
        <el-table-column prop="u8_errmsg" label="U8描述" min-width="130" show-overflow-tooltip />
        <el-table-column prop="u8_tradeid" label="回调流水号" min-width="150" show-overflow-tooltip />
        <el-table-column prop="u8_callback_time" label="最近回调" width="170" />
        <el-table-column prop="remark" label="备注" min-width="130" show-overflow-tooltip />
      </el-table>
      <div class="pager">
        <el-pagination background layout="total, prev, pager, next" :total="docTotal" :page-size="docLimit" :current-page="docPage" @current-change="loadDocuments" />
      </div>
    </el-card>
  </div>
</template>

<script>
import { getU8Config, saveU8Config, testU8, getU8SyncStatus, syncU8, saveU8CallbackConfig, getU8CallbackLogs, getU8Documents } from '@/api/serviceU8'

const DATA_TYPE_OPTIONS = { warehouse: '仓库档案', inventory: '存货档案', purchase_in: '采购入库单', product_in: '产成品入库单', sale_out: '销售出库单', other_io: '其他出入库单' }

export default {
  name: 'ServiceU8',
  data () {
    return {
      DATA_TYPE_OPTIONS,
      form: { service_name: 'U8服务', base_url: 'https://api.yonyouup.com', from_account: '', to_account: '', app_key: '', app_secret: '', ds_sequence: 1, eai_url: '', eai_system_code: '', eai_default_user: '', status: 1, sync_enabled: 0, sync_frequency: 'daily', sync_time: '', callback_enabled: 0, callback_secret: '' },
      syncDataTypes: [], saving: false, testing: false, testResult: null, syncing: false,
      syncStatus: { connected: false, sync_status: 'idle', last_sync_time: '', data_counts: [], sync_error: '' },
      cbLogs: [], cbTotal: 0, cbPage: 1, cbLimit: 15, cbLoading: false, cbSaving: false,
      docRows: [], docTotal: 0, docPage: 1, docLimit: 15, docLoading: false
    }
  },
  computed: {
    syncStatusText () { return { idle: '空闲', syncing: '同步中', success: '成功', failed: '失败' }[this.syncStatus.sync_status] || '空闲' },
    syncStatusTag () { return { syncing: 'warning', success: 'success', failed: 'danger' }[this.syncStatus.sync_status] || 'info' },
    logRows () {
      const rows = []
      if (this.syncStatus.last_sync_time) {
        rows.push({
          sync_time: this.syncStatus.last_sync_time,
          data_type_text: (this.syncStatus.sync_types || []).map(t => DATA_TYPE_OPTIONS[t] || t).join('、') || '全部',
          status_text: this.syncStatusText,
          record_count: 0,
          error_msg: this.syncStatus.sync_error || ''
        })
      }
      return rows
    },
    callbackUrl () { return (window.location.origin || '') + '/api/u8/callback' }
  },
  created () { this.loadConfig(); this.loadSyncStatus(); this.loadCallbackLogs(); this.loadDocuments() },
  methods: {
    async loadConfig () {
      try {
        const r = await getU8Config()
        if (r.code === 0) {
          const d = r.data || {}
          this.form = {
            service_name: d.service_name || 'U8服务', base_url: d.base_url || 'https://api.yonyouup.com',
            from_account: d.from_account || '', to_account: d.to_account || '', app_key: d.app_key || '', app_secret: d.app_secret || '',
            ds_sequence: d.ds_sequence || 1, eai_url: d.eai_url || '', eai_system_code: d.eai_system_code || '', eai_default_user: d.eai_default_user || '',
            status: d.status === 0 ? 0 : 1, sync_enabled: d.sync_enabled === 0 ? 0 : 1, sync_frequency: d.sync_frequency || 'daily', sync_time: d.sync_time || '',
            callback_enabled: d.callback_enabled === 0 ? 0 : 1, callback_secret: ''
          }
          this.syncDataTypes = (d.sync_data_types || '').split(',').filter(Boolean)
        }
      } catch (e) {}
    },
    async saveConfig () {
      if (!this.form.base_url || !this.form.from_account || !this.form.to_account || !this.form.app_key || !this.form.app_secret) { this.$message.warning('接口地址、调用方/提供方ID、AppKey、AppSecret 必填'); return }
      this.saving = true
      try {
        const r = await saveU8Config({ ...this.form, sync_data_types: this.syncDataTypes })
        if (r.code === 0) { this.$message.success('配置已保存'); this.loadConfig() }
      } catch (e) {} finally { this.saving = false }
    },
    async testConnection () {
      this.testing = true; this.testResult = null
      try {
        const r = await testU8()
        if (r.code === 0 && r.data) this.testResult = r.data
      } catch (e) {} finally { this.testing = false }
    },
    async loadSyncStatus () {
      try { const r = await getU8SyncStatus(); if (r.code === 0) this.syncStatus = r.data || {} } catch (e) {}
    },
    async doSync () {
      if (!this.syncDataTypes.length) { this.$message.warning('请先选择同步数据类型'); return }
      this.$confirm('确认立即执行一次数据同步（仅同步单据状态）？', '同步确认', { type: 'warning' }).then(async () => {
        this.syncing = true
        try {
          const r = await syncU8(this.syncDataTypes)
          if (r.code === 0) { this.$message.success(r.msg || '同步完成'); this.loadSyncStatus() }
        } catch (e) {} finally { this.syncing = false }
      }).catch(() => {})
    },
    async saveCallbackConfig () {
      if (this.form.callback_enabled === 1 && !this.form.callback_secret) { this.$message.warning('启用回调前请先填写签名密钥'); return }
      this.cbSaving = true
      try {
        const r = await saveU8CallbackConfig({ callback_enabled: this.form.callback_enabled, callback_secret: this.form.callback_secret || '******' })
        if (r.code === 0) { this.$message.success('回调配置已保存'); this.loadConfig() }
      } catch (e) {} finally { this.cbSaving = false }
    },
    async loadCallbackLogs (page) {
      this.cbPage = page || this.cbPage
      this.cbLoading = true
      try {
        const r = await getU8CallbackLogs({ page: this.cbPage, limit: this.cbLimit })
        if (r.code === 0 && r.data) { this.cbLogs = r.data.list || []; this.cbTotal = r.data.total || 0 }
      } catch (e) {} finally { this.cbLoading = false }
    },
    cbStatusTag (s) {
      return { processed: 'success', type_not_supported: 'info', duplicated: 'warning', sign_failed: 'danger', expired: 'danger', failed: 'danger', processing: 'warning' }[s] || 'info'
    },
    copyCallbackUrl () {
      const url = this.callbackUrl
      if (navigator.clipboard && navigator.clipboard.writeText) {
        navigator.clipboard.writeText(url).then(() => this.$message.success('回调地址已复制')).catch(() => this.fallbackCopy(url))
      } else {
        this.fallbackCopy(url)
      }
    },
    fallbackCopy (text) {
      const ta = document.createElement('textarea')
      ta.value = text
      document.body.appendChild(ta)
      ta.select()
      try { document.execCommand('copy'); this.$message.success('回调地址已复制') } catch (e) { this.$message.warning('复制失败，请手动复制') }
      document.body.removeChild(ta)
    },
    async loadDocuments (page) {
      this.docPage = page || this.docPage
      this.docLoading = true
      try {
        const r = await getU8Documents({ page: this.docPage, limit: this.docLimit })
        if (r.code === 0 && r.data) { this.docRows = r.data.list || []; this.docTotal = r.data.total || 0 }
      } catch (e) {} finally { this.docLoading = false }
    },
    docStatusTag (s) {
      return { approved: 'success', rejected: 'danger', submitted: 'info', unknown: 'warning' }[s] || 'info'
    }
  }
}
</script>

<style scoped>
.u8-page { padding: 16px; background: #f0f2f5; min-height: 100%; }
.sec-card { margin-bottom: 16px; }
.sec-head { display: flex; align-items: baseline; gap: 12px; }
.sec-title { font-size: 15px; font-weight: 600; color: #303133; }
.sec-desc { font-size: 12px; color: #909399; }
.test-result { margin-top: 12px; font-size: 13px; }
.test-result.ok { color: #67C23A; }
.test-result.err { color: #F56C6C; }
.sync-status { margin-left: 12px; font-size: 13px; color: #606266; }
.state-item { font-size: 13px; color: #606266; padding: 6px 0; }
.sync-error { font-size: 13px; color: #F56C6C; margin-top: 6px; }
.log-tip { font-size: 12px; color: #909399; margin-top: 8px; }
</style>
