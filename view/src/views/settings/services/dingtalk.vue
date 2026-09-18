<template>
  <div class="dingtalk-page">
    <!-- 一、服务配置 -->
    <el-card shadow="never" class="sec-card">
      <div slot="header" class="sec-head"><span class="sec-title">钉钉服务配置</span></div>
      <el-form :model="form" label-width="120px" size="small">
        <el-row :gutter="24">
          <el-col :span="12">
            <el-form-item label="企业 CorpId"><el-input v-model="form.corp_id" placeholder="必填" maxlength="100" /></el-form-item>
            <el-form-item label="AppKey"><el-input v-model="form.app_key" placeholder="必填" maxlength="100" /></el-form-item>
            <el-form-item label="AppSecret"><el-input v-model="form.app_secret" type="password" show-password placeholder="必填（掩码 ****** 表示已保存，不修改请保持）" maxlength="200" /></el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="AgentId"><el-input v-model="form.agent_id" placeholder="选填" maxlength="50" /></el-form-item>
            <el-form-item label="服务名称"><el-input v-model="form.service_name" maxlength="50" /></el-form-item>
            <el-form-item label="服务状态"><el-switch v-model="form.status" :active-value="1" :inactive-value="0" active-text="启用" inactive-text="停用" /></el-form-item>
          </el-col>
        </el-row>
        <el-form-item>
          <el-button type="primary" size="small" :loading="saving" @click="saveConfig">保存配置</el-button>
          <el-button size="small" :loading="testing" @click="testConnection">测试连接</el-button>
          <span v-if="testResult" class="test-result" :class="testResult.success ? 'ok' : 'err'">{{ testResult.message }}（{{ testResult.response_time }}）</span>
        </el-form-item>
      </el-form>
    </el-card>

    <!-- 二、数据权限配置 -->
    <el-card shadow="never" class="sec-card">
      <div slot="header" class="sec-head"><span class="sec-title">数据权限配置</span><span class="sec-desc">请在钉钉开放平台申请以下权限后启用对应功能</span></div>
      <el-table :data="permList" size="small" border>
        <el-table-column prop="name" label="权限名称" min-width="180" />
        <el-table-column prop="code" label="权限标识" min-width="220" />
        <el-table-column label="状态" width="90" align="center">
          <template slot-scope="{ row }"><el-tag size="mini" :type="row.enabled ? 'success' : 'info'">{{ row.enabled ? '已授权' : '未授权' }}</el-tag></template>
        </el-table-column>
        <el-table-column label="操作" width="110" align="center">
          <template slot-scope="{ row }"><el-button type="text" size="mini" @click="openApplyGuide(row)">申请指引</el-button></template>
        </el-table-column>
      </el-table>
      <el-alert v-if="applyGuide" :title="applyGuide" type="info" :closable="true" show-icon style="margin-top:10px;" @close="applyGuide = ''" />
    </el-card>

    <!-- 三、数据同步配置 -->
    <el-card shadow="never" class="sec-card">
      <div slot="header" class="sec-head"><span class="sec-title">数据同步配置</span><span class="sec-desc">系统将按设置的频率自动拉取钉钉数据</span></div>
      <el-form label-width="120px" size="small">
        <el-row :gutter="24">
          <el-col :span="12">
            <el-form-item label="同步开关"><el-switch v-model="form.sync_enabled" :active-value="1" :inactive-value="0" /></el-form-item>
            <el-form-item label="同步频率">
              <el-select v-model="form.sync_frequency" style="width:200px"><el-option label="每小时" value="hourly" /><el-option label="每天" value="daily" /><el-option label="每周" value="weekly" /></el-select>
            </el-form-item>
            <el-form-item v-if="form.sync_frequency === 'daily'" label="同步时间">
              <el-time-picker v-model="form.sync_time" format="HH:mm" value-format="HH:mm" style="width:200px" />
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="同步数据类型">
              <el-select v-model="syncDataTypes" multiple collapse-tags placeholder="选择同步类型" style="width:100%">
                <el-option v-for="(t, k) in DATA_TYPE_OPTIONS" :key="k" :label="t" :value="k" />
              </el-select>
            </el-form-item>
            <el-form-item label="同步起始日期">
              <el-date-picker v-model="form.sync_start_date" type="date" value-format="yyyy-MM-dd" style="width:200px" />
            </el-form-item>
          </el-col>
        </el-row>
        <el-form-item>
          <el-button type="primary" size="small" :loading="syncing" @click="doSync">立即同步</el-button>
          <span class="sync-status">同步状态：<el-tag size="mini" :type="syncStatusTag">{{ syncStatusText }}</el-tag></span>
        </el-form-item>
      </el-form>
    </el-card>

    <!-- 四、服务状态 -->
    <el-card shadow="never" class="sec-card">
      <div slot="header" class="sec-head"><span class="sec-title">服务状态</span></div>
      <el-row :gutter="16">
        <el-col :span="6"><div class="state-item">服务健康状态：<el-tag size="mini" :type="form.status ? 'success' : 'info'">{{ form.status ? '正常' : '停用' }}</el-tag></div></el-col>
        <el-col :span="6"><div class="state-item">最后同步时间：{{ syncStatus.last_sync_time || '-' }}</div></el-col>
        <el-col :span="12"><div class="state-item" v-if="syncStatus.data_counts">
          数据量：
          <span v-for="c in syncStatus.data_counts" :key="c.data_type" style="margin-right:10px;">{{ c.label }} <b>{{ c.count }}</b> 条</span>
        </div></el-col>
      </el-row>
    </el-card>

    <!-- 五、用户映射 -->
    <el-card shadow="never" class="sec-card">
      <div slot="header" class="sec-head"><span class="sec-title">钉钉用户映射</span><span class="sec-desc">建立钉钉用户ID与系统用户的映射关系</span></div>
      <div class="toolbar">
        <el-input v-model="mapKeyword" placeholder="按系统用户姓名搜索" clearable style="width:200px" @keyup.enter.native="loadMaps" @clear="loadMaps" />
        <div>
          <el-button size="small" type="primary" icon="el-icon-plus" @click="bindVisible = true">新增绑定</el-button>
          <el-upload :show-file-list="false" :http-request="doImportMap" accept=".xlsx,.xls" style="display:inline-block;margin:0 8px;">
            <el-button size="small" icon="el-icon-upload2">导入映射</el-button>
          </el-upload>
          <el-button size="small" icon="el-icon-refresh" @click="loadMaps">刷新</el-button>
        </div>
      </div>
      <el-table :data="maps" size="small" v-loading="mapLoading" stripe>
        <el-table-column prop="dingtalk_userid" label="钉钉用户ID" min-width="160" />
        <el-table-column prop="system_user_name" label="系统用户姓名" width="120" />
        <el-table-column prop="employee_id" label="员工档案ID" width="100" align="center" />
        <el-table-column prop="bind_time" label="绑定时间" width="160" />
        <el-table-column label="操作" width="100" align="center">
          <template slot-scope="{ row }"><el-button type="text" size="mini" style="color:#F56C6C" @click="unbindMap(row)">解绑</el-button></template>
        </el-table-column>
      </el-table>
      <el-pagination class="pager" background layout="total, prev, pager, next" :total="mapTotal" :current-page="mapPage" :page-size="10"
        @current-change="p => { mapPage = p; loadMaps() }" />
    </el-card>

    <!-- 六、同步日志 -->
    <el-card shadow="never" class="sec-card">
      <div slot="header" class="sec-head"><span class="sec-title">同步日志</span></div>
      <el-form :inline="true" size="small" class="log-filter">
        <el-form-item>
          <el-select v-model="logFilter.data_type" clearable placeholder="全部类型" style="width:120px" @change="loadLogs"><el-option v-for="(t, k) in DATA_TYPE_OPTIONS" :key="k" :label="t" :value="k" /></el-select>
        </el-form-item>
        <el-form-item>
          <el-select v-model="logFilter.status" clearable placeholder="全部状态" style="width:100px" @change="loadLogs"><el-option label="成功" value="1" /><el-option label="失败" value="0" /></el-select>
        </el-form-item>
        <el-form-item>
          <el-date-picker v-model="logFilter.dateRange" type="daterange" value-format="yyyy-MM-dd" range-separator="至" start-placeholder="开始" end-placeholder="结束" style="width:220px" @change="loadLogs" />
        </el-form-item>
        <el-form-item><el-button size="small" icon="el-icon-refresh" @click="loadLogs">刷新</el-button></el-form-item>
      </el-form>
      <el-table :data="logs" size="small" stripe>
        <el-table-column prop="sync_type_text" label="同步类型" width="90" align="center" />
        <el-table-column prop="data_type_text" label="数据类型" width="110" align="center" />
        <el-table-column prop="start_time" label="开始时间" width="160" />
        <el-table-column prop="end_time" label="结束时间" width="160" />
        <el-table-column prop="total_count" label="总记录" width="80" align="center" />
        <el-table-column prop="success_count" label="成功" width="80" align="center" />
        <el-table-column prop="fail_count" label="失败" width="80" align="center" />
        <el-table-column label="状态" width="80" align="center">
          <template slot-scope="{ row }"><el-tag size="mini" :type="row.status === 1 ? 'success' : 'danger'">{{ row.status === 1 ? '成功' : '失败' }}</el-tag></template>
        </el-table-column>
        <el-table-column label="操作" width="90" align="center">
          <template slot-scope="{ row }"><el-button v-if="row.error_msg" type="text" size="mini" @click="openLogDetail(row)">详情</el-button></template>
        </el-table-column>
      </el-table>
      <el-pagination class="pager" background layout="total, prev, pager, next" :total="logTotal" :current-page="logPage" :page-size="10"
        @current-change="p => { logPage = p; loadLogs() }" />
    </el-card>

    <!-- 绑定弹窗 -->
    <el-dialog title="新增绑定" :visible="bindVisible" @update:visible="v => bindVisible = v" width="480px" top="8vh" @open="openBind">
      <el-form :model="bindForm" label-width="100px" size="small">
        <el-form-item label="钉钉用户ID"><el-input v-model="bindForm.dingtalk_userid" maxlength="100" /></el-form-item>
        <el-form-item label="系统用户">
          <el-select v-model="bindForm.system_user_id" filterable placeholder="选择系统用户" style="width:100%">
            <el-option v-for="u in userOptions" :key="u.id" :label="(u.real_name || u.username) + '（' + u.username + '）'" :value="u.id" />
          </el-select>
        </el-form-item>
        <el-form-item label="员工档案">
          <el-select v-model="bindForm.employee_id" filterable clearable placeholder="选填" style="width:100%">
            <el-option v-for="e in empOptions" :key="e.id" :label="e.name" :value="e.id" />
          </el-select>
        </el-form-item>
        <el-form-item label="备注"><el-input v-model="bindForm.remark" maxlength="255" /></el-form-item>
      </el-form>
      <span slot="footer">
        <el-button size="small" @click="bindVisible = false">取消</el-button>
        <el-button size="small" type="primary" :loading="bindSaving" @click="submitBind">确认</el-button>
      </span>
    </el-dialog>

    <!-- 日志详情弹窗 -->
    <el-dialog title="同步日志详情" :visible="logDetailVisible" @update:visible="v => logDetailVisible = v" width="560px" top="8vh">
      <div class="log-detail">{{ currentLog.error_msg }}</div>
    </el-dialog>
  </div>
</template>

<script>
import {
  getDingtalkConfig, saveDingtalkConfig, testDingtalk, getDingtalkSyncStatus, syncDingtalk,
  getDingtalkUserMap, bindDingtalkUserMap, unbindDingtalkUserMap, importDingtalkUserMap, getDingtalkSyncLogs
} from '@/api/serviceDingtalk'
import { getUserList } from '@/api/user'
import { getScheduleEmployees } from '@/api/attendanceSchedule'

const DATA_TYPE_OPTIONS = { attendance: '打卡记录', leave: '请假记录', outing: '外出记录', travel: '出差记录', car_apply: '用车申请记录' }

export default {
  name: 'ServiceDingtalk',
  data () {
    return {
      DATA_TYPE_OPTIONS,
      form: { corp_id: '', app_key: '', app_secret: '', agent_id: '', service_name: '钉钉服务', status: 1, sync_enabled: 0, sync_frequency: 'daily', sync_time: '', sync_start_date: '' },
      syncDataTypes: [], saving: false, testing: false, testResult: null,
      permList: [
        { name: '查询企业考勤数据（考勤打卡记录）', code: 'attendance:list', enabled: false },
        { name: '获取审批实例数据（请假/外出/出差/用车申请）', code: 'processinstance:list', enabled: false },
        { name: '通讯录读取权限（用户映射）', code: 'contact:read', enabled: false },
        { name: '消息推送权限（消息通知）', code: 'message:push', enabled: false }
      ],
      applyGuide: '',
      syncing: false,
      syncStatus: { sync_enabled: 0, sync_status: 'idle', last_sync_time: '', data_counts: [] },
      mapKeyword: '', maps: [], mapTotal: 0, mapPage: 1, mapLoading: false,
      userOptions: [], empOptions: [],
      bindVisible: false, bindSaving: false, bindForm: { dingtalk_userid: '', system_user_id: '', employee_id: null, remark: '' },
      logs: [], logTotal: 0, logPage: 1, logFilter: { data_type: '', status: '', dateRange: null },
      logDetailVisible: false, currentLog: {}
    }
  },
  computed: {
    syncStatusText () { return { idle: '空闲', syncing: '同步中', success: '成功', failed: '失败' }[this.syncStatus.sync_status] || '空闲' },
    syncStatusTag () { return { syncing: 'warning', success: 'success', failed: 'danger' }[this.syncStatus.sync_status] || 'info' }
  },
  created () { this.loadConfig(); this.loadSyncStatus(); this.loadMaps(); this.loadLogs() },
  methods: {
    async loadConfig () {
      try {
        const r = await getDingtalkConfig()
        if (r.code === 0) {
          const d = r.data || {}
          this.form = {
            corp_id: d.corp_id || '', app_key: d.app_key || '', app_secret: d.app_secret || '',
            agent_id: d.agent_id || '', service_name: d.service_name || '钉钉服务', status: d.status === 0 ? 0 : 1,
            sync_enabled: d.sync_enabled === 0 ? 0 : 1, sync_frequency: d.sync_frequency || 'daily', sync_time: d.sync_time || '', sync_start_date: d.sync_start_date || ''
          }
          this.syncDataTypes = (d.sync_data_types || '').split(',').filter(Boolean)
        }
      } catch (e) {}
    },
    async saveConfig () {
      if (!this.form.corp_id || !this.form.app_key || !this.form.app_secret) { this.$message.warning('CorpId、AppKey、AppSecret 必填'); return }
      this.saving = true
      try {
        const r = await saveDingtalkConfig({ ...this.form, sync_data_types: this.syncDataTypes })
        if (r.code === 0) { this.$message.success('配置已保存'); this.loadConfig() }
      } catch (e) {} finally { this.saving = false }
    },
    async testConnection () {
      this.testing = true; this.testResult = null
      try {
        const r = await testDingtalk()
        if (r.code === 0 && r.data) this.testResult = r.data
      } catch (e) {} finally { this.testing = false }
    },
    openApplyGuide (row) {
      this.applyGuide = `请登录钉钉开放平台（open.dingtalk.com）→ 应用开发 → 选择应用 → 权限管理，申请「${row.name}」权限（${row.code}），审核通过后本项即生效。`
    },
    async loadSyncStatus () {
      try {
        const r = await getDingtalkSyncStatus()
        if (r.code === 0) this.syncStatus = r.data || {}
      } catch (e) {}
    },
    async doSync () {
      if (!this.syncDataTypes.length) { this.$message.warning('请先选择同步数据类型'); return }
      this.$confirm('确认立即执行一次数据同步？', '同步确认', { type: 'warning' }).then(async () => {
        this.syncing = true
        try {
          const r = await syncDingtalk(this.syncDataTypes)
          if (r.code === 0) { this.$message.success(r.msg || '同步完成'); this.loadSyncStatus(); this.loadLogs() }
        } catch (e) {} finally { this.syncing = false }
      }).catch(() => {})
    },
    async loadMaps () {
      this.mapLoading = true
      try {
        const r = await getDingtalkUserMap({ page: this.mapPage, limit: 10, keyword: this.mapKeyword })
        if (r.code === 0) { this.maps = r.data.list || []; this.mapTotal = r.data.total || 0 }
      } catch (e) {} finally { this.mapLoading = false }
    },
    async openBind () {
      this.bindForm = { dingtalk_userid: '', system_user_id: '', employee_id: null, remark: '' }
      try {
        const [u, e] = await Promise.all([getUserList({ page: 1, limit: 999 }), getScheduleEmployees({})])
        this.userOptions = (u.data && u.data.list) || []
        this.empOptions = e.data || []
      } catch (e) {}
    },
    async submitBind () {
      if (!this.bindForm.dingtalk_userid || !this.bindForm.system_user_id) { this.$message.warning('钉钉用户ID和系统用户必填'); return }
      this.bindSaving = true
      try {
        const r = await bindDingtalkUserMap(this.bindForm)
        if (r.code === 0) { this.$message.success('绑定成功'); this.bindVisible = false; this.loadMaps() }
      } catch (e) {} finally { this.bindSaving = false }
    },
    unbindMap (row) {
      this.$confirm(`确认解绑「${row.system_user_name}」与钉钉用户 ${row.dingtalk_userid} 的映射？`, '解绑确认', { type: 'warning' }).then(async () => {
        try {
          const r = await unbindDingtalkUserMap(row.id)
          if (r.code === 0) { this.$message.success('已解绑'); this.loadMaps() }
        } catch (e) {}
      }).catch(() => {})
    },
    async doImportMap ({ file }) {
      const fd = new FormData()
      fd.append('file', file)
      try {
        const r = await importDingtalkUserMap(fd)
        if (r.code === 0) { this.$message.success(r.msg || '导入完成'); this.loadMaps() }
      } catch (e) {}
    },
    async loadLogs () {
      try {
        const params = { page: this.logPage, limit: 10 }
        if (this.logFilter.data_type) params.data_type = this.logFilter.data_type
        if (this.logFilter.status !== '' && this.logFilter.status !== null) params.status = this.logFilter.status
        if (this.logFilter.dateRange && this.logFilter.dateRange.length === 2) { params.start_date = this.logFilter.dateRange[0]; params.end_date = this.logFilter.dateRange[1] }
        const r = await getDingtalkSyncLogs(params)
        if (r.code === 0) { this.logs = r.data.list || []; this.logTotal = r.data.total || 0 }
      } catch (e) {}
    },
    openLogDetail (row) { this.currentLog = row; this.logDetailVisible = true }
  }
}
</script>

<style scoped>
.dingtalk-page { padding: 16px; background: #f0f2f5; min-height: 100%; }
.sec-card { margin-bottom: 16px; }
.sec-head { display: flex; align-items: baseline; gap: 12px; }
.sec-title { font-size: 15px; font-weight: 600; color: #303133; }
.sec-desc { font-size: 12px; color: #909399; }
.test-result { margin-left: 12px; font-size: 13px; }
.test-result.ok { color: #67C23A; }
.test-result.err { color: #F56C6C; }
.sync-status { margin-left: 12px; font-size: 13px; color: #606266; }
.state-item { font-size: 13px; color: #606266; padding: 6px 0; }
.toolbar { display: flex; justify-content: space-between; margin-bottom: 12px; }
.pager { margin-top: 12px; text-align: right; }
.log-filter { margin-bottom: 10px; }
.log-detail { font-size: 13px; color: #F56C6C; word-break: break-all; white-space: pre-wrap; max-height: 300px; overflow-y: auto; }
</style>
