<template>
  <div class="security-policy-page">
    <!-- ===== 一、安全评分卡片 ===== -->
    <el-card shadow="never" class="score-card">
      <div class="score-body">
        <div class="score-left">
          <div class="score-num" :style="{ color: scoreColor }">{{ scoreInfo.score || 0 }}</div>
          <div class="score-level" :style="{ color: scoreColor }">{{ scoreInfo.level || '--' }}</div>
          <div class="score-desc">安全项已达标 {{ scoreInfo.passed || 0 }} / {{ scoreInfo.checked || 0 }}</div>
          <div class="score-time">最后检查：{{ scoreInfo.check_time || '--' }}</div>
        </div>
        <div class="score-right">
          <el-button type="primary" size="small" icon="el-icon-refresh" :loading="scoreLoading" @click="loadScore">重新评估</el-button>
          <div class="score-checks">
            <el-tag v-for="(c, i) in scoreInfo.checks || []" :key="i" size="mini" :type="c.pass ? 'success' : 'danger'" class="check-tag">
              {{ c.name }}
            </el-tag>
          </div>
        </div>
      </div>
    </el-card>

    <!-- ===== 二、策略配置 Tab ===== -->
    <el-card shadow="never" class="policy-card">
      <el-tabs v-model="activeTab" type="border-card">
        <!-- 密码策略 -->
        <el-tab-pane label="密码策略" name="password">
          <el-form :model="form.password" label-width="200px" size="small">
            <el-form-item label="密码最小长度">
              <el-input-number v-model="form.password.password_min_length" :min="6" :max="32" />
              <span class="unit">位</span>
            </el-form-item>
            <el-form-item label="密码复杂度要求">
              <el-checkbox-group v-model="form.password.password_complexity">
                <el-checkbox label="uppercase">大写字母</el-checkbox>
                <el-checkbox label="lowercase">小写字母</el-checkbox>
                <el-checkbox label="number">数字</el-checkbox>
                <el-checkbox label="special">特殊字符</el-checkbox>
              </el-checkbox-group>
              <div class="tip">至少满足 3 项</div>
            </el-form-item>
            <el-form-item label="密码有效期">
              <el-input-number v-model="form.password.password_expire_days" :min="0" :max="3650" />
              <span class="unit">天（0 为永不过期）</span>
            </el-form-item>
            <el-form-item label="密码历史限制">
              <el-input-number v-model="form.password.password_history_count" :min="0" :max="20" />
              <span class="unit">禁止重复使用最近 N 次密码</span>
            </el-form-item>
            <el-form-item label="密码尝试失败锁定">
              <el-input-number v-model="form.password.password_fail_lock_count" :min="0" :max="20" />
              <span class="unit">连续失败 N 次后锁定</span>
            </el-form-item>
            <el-form-item label="锁定持续时间">
              <el-input-number v-model="form.password.password_lock_duration" :min="1" :max="1440" />
              <span class="unit">分钟</span>
            </el-form-item>
            <el-form-item label="首次登录强制修改密码">
              <el-switch v-model="form.password.password_first_login_change" />
            </el-form-item>
          </el-form>
        </el-tab-pane>

        <!-- 登录安全 -->
        <el-tab-pane label="登录安全" name="login">
          <el-form :model="form.login" label-width="200px" size="small">
            <el-form-item label="登录验证码"><el-switch v-model="form.login.login_captcha_enabled" /></el-form-item>
            <el-form-item label="多因素认证（MFA）"><el-switch v-model="form.login.login_mfa_enabled" /></el-form-item>
            <el-form-item label="MFA 强制范围">
              <el-select v-model="form.login.login_mfa_scope" style="width: 240px;">
                <el-option label="全部用户" value="all" />
                <el-option label="仅管理员" value="admin" />
                <el-option label="仅特定角色" value="role" />
              </el-select>
            </el-form-item>
            <el-form-item label="异地登录提醒"><el-switch v-model="form.login.login_location_alert" /></el-form-item>
            <el-form-item label="登录失败提醒"><el-switch v-model="form.login.login_fail_alert" /></el-form-item>
            <el-form-item label="登录失败记录保留天数">
              <el-input-number v-model="form.login.login_fail_log_retention" :min="1" :max="365" />
              <span class="unit">天</span>
            </el-form-item>
          </el-form>
        </el-tab-pane>

        <!-- 会话安全 -->
        <el-tab-pane label="会话安全" name="session">
          <el-form :model="form.session" label-width="200px" size="small">
            <el-form-item label="会话超时时间">
              <el-input-number v-model="form.session.session_timeout" :min="1" :max="1440" />
              <span class="unit">分钟</span>
            </el-form-item>
            <el-form-item label="最大并发登录数">
              <el-input-number v-model="form.session.session_max_concurrent" :min="0" :max="20" />
              <span class="unit">0 表示不限制</span>
            </el-form-item>
            <el-form-item label="单点登录（SSO）强制">
              <el-switch v-model="form.session.session_sso_enabled" />
              <span class="tip">开启后新登录踢掉旧会话</span>
            </el-form-item>
            <el-form-item label="记住设备天数">
              <el-input-number v-model="form.session.session_remember_days" :min="0" :max="365" />
              <span class="unit">天</span>
            </el-form-item>
            <el-form-item label="会话空闲检测"><el-switch v-model="form.session.session_idle_detect" /></el-form-item>
            <el-form-item label="闲置超时提醒">
              <el-input-number v-model="form.session.session_idle_alert_minutes" :min="0" :max="60" />
              <span class="unit">分钟</span>
            </el-form-item>
          </el-form>
        </el-tab-pane>

        <!-- IP白名单 -->
        <el-tab-pane label="IP白名单" name="ip_whitelist">
          <el-form :model="form.ip_whitelist" label-width="200px" size="small">
            <el-form-item label="IP白名单开关"><el-switch v-model="form.ip_whitelist.ip_whitelist_enabled" /></el-form-item>
            <el-form-item label="白名单模式">
              <el-select v-model="form.ip_whitelist.ip_whitelist_mode" style="width: 240px;">
                <el-option label="仅允许白名单IP访问" value="strict" />
                <el-option label="白名单IP免验证（跳过验证码/MFA）" value="trusted" />
              </el-select>
            </el-form-item>
            <el-form-item label="当前访问IP">
              <el-input :value="currentIp" disabled style="width: 240px;">
                <el-button slot="append" icon="el-icon-refresh" @click="loadCurrentIp" />
              </el-input>
            </el-form-item>
          </el-form>

          <div class="sub-head">
            <span>白名单列表</span>
            <span class="flex-1"></span>
            <el-button size="small" type="primary" icon="el-icon-plus" @click="$refs.ipDialog.open()">新增IP</el-button>
            <el-button size="small" icon="el-icon-delete" :disabled="!selectedIpRows.length" @click="batchDeleteIp">批量删除</el-button>
          </div>
          <el-table :data="ipList" size="small" stripe v-loading="ipLoading" @selection-change="s => selectedIpRows = s">
            <el-table-column type="selection" width="45" />
            <el-table-column prop="ip_address" label="IP地址/CIDR" min-width="160" />
            <el-table-column prop="description" label="描述" min-width="140" show-overflow-tooltip />
            <el-table-column prop="user_name" label="关联用户" width="120">
              <template slot-scope="s">{{ s.row.user_name || '全局' }}</template>
            </el-table-column>
            <el-table-column prop="expire_time" label="过期时间" width="170">
              <template slot-scope="s">
                <span :class="{ 'expired': s.row.expired }">{{ s.row.expire_time || '永不过期' }}</span>
              </template>
            </el-table-column>
            <el-table-column label="状态" width="80">
              <template slot-scope="s">
                <el-tag size="mini" :type="s.row.status === 1 ? 'success' : 'info'">{{ s.row.status === 1 ? '启用' : '停用' }}</el-tag>
              </template>
            </el-table-column>
            <el-table-column label="操作" width="130" align="center">
              <template slot-scope="s">
                <el-button type="text" size="mini" @click="$refs.ipDialog.open(s.row)">编辑</el-button>
                <el-button type="text" size="mini" class="danger" @click="deleteIp(s.row)">删除</el-button>
              </template>
            </el-table-column>
          </el-table>
          <el-pagination class="pager" small background layout="total, prev, pager, next" :total="ipTotal" :page-size="ipPageSize" :current-page="ipPage" @current-change="p => { ipPage = p; loadIpList() }" />
        </el-tab-pane>

        <!-- 数据安全 -->
        <el-tab-pane label="数据安全" name="data">
          <el-form :model="form.data" label-width="200px" size="small">
            <el-form-item label="数据加密开关"><el-switch v-model="form.data.data_encryption_enabled" /></el-form-item>
            <el-form-item label="单次导出最大条数">
              <el-input-number v-model="form.data.data_export_max_rows" :min="100" :max="1000000" :step="100" />
            </el-form-item>
            <el-form-item label="日志保留天数">
              <el-input-number v-model="form.data.data_log_retention_days" :min="1" :max="3650" />
              <span class="unit">天</span>
            </el-form-item>
          </el-form>
        </el-tab-pane>

        <!-- AI安全策略 -->
        <el-tab-pane label="AI安全策略" name="ai">
          <el-form :model="form.ai" label-width="200px" size="small">
            <el-form-item label="AI调用开关（全局）"><el-switch v-model="form.ai.ai_enabled" /></el-form-item>
            <el-form-item label="AI输入内容安全检测"><el-switch v-model="form.ai.ai_input_detection" /></el-form-item>
            <el-form-item label="AI输出内容安全检测"><el-switch v-model="form.ai.ai_output_detection" /></el-form-item>
            <el-form-item label="工具调用安全控制"><el-switch v-model="form.ai.ai_tool_control" /></el-form-item>
            <el-form-item label="每日Token预算">
              <el-input-number v-model="form.ai.ai_token_budget_daily" :min="0" :step="100000" />
            </el-form-item>
            <el-form-item label="每月Token预算">
              <el-input-number v-model="form.ai.ai_token_budget_monthly" :min="0" :step="1000000" />
            </el-form-item>
            <el-form-item label="AI操作审计日志"><el-switch v-model="form.ai.ai_audit_enabled" /></el-form-item>
          </el-form>

          <!-- 敏感词管理 -->
          <div class="sub-head">
            <span>敏感词库</span>
            <span class="flex-1"></span>
            <el-button size="small" type="primary" icon="el-icon-plus" @click="$refs.wordDialog.open()">新增敏感词</el-button>
            <el-upload :show-file-list="false" :http-request="doImportWords" accept=".txt">
              <el-button size="small" icon="el-icon-upload2">导入</el-button>
            </el-upload>
            <el-button size="small" icon="el-icon-download" @click="doExportWords">导出</el-button>
            <el-button size="small" icon="el-icon-delete" :disabled="!selectedWordRows.length" @click="batchDeleteWords">批量删除</el-button>
          </div>
          <el-table :data="wordList" size="small" stripe v-loading="wordLoading" @selection-change="s => selectedWordRows = s">
            <el-table-column type="selection" width="45" />
            <el-table-column prop="word" label="敏感词" min-width="160" />
            <el-table-column label="分类" width="100">
              <template slot-scope="s">{{ categoryText(s.row.category) }}</template>
            </el-table-column>
            <el-table-column label="严重程度" width="100">
              <template slot-scope="s">
                <el-tag size="mini" :type="severityType(s.row.severity)">{{ severityText(s.row.severity) }}</el-tag>
              </template>
            </el-table-column>
            <el-table-column prop="replace_with" label="替换词" width="120">
              <template slot-scope="s">{{ s.row.replace_with || '***' }}</template>
            </el-table-column>
            <el-table-column label="状态" width="80">
              <template slot-scope="s">
                <el-tag size="mini" :type="s.row.status === 1 ? 'success' : 'info'">{{ s.row.status === 1 ? '启用' : '停用' }}</el-tag>
              </template>
            </el-table-column>
            <el-table-column label="操作" width="130" align="center">
              <template slot-scope="s">
                <el-button type="text" size="mini" @click="$refs.wordDialog.open(s.row)">编辑</el-button>
                <el-button type="text" size="mini" class="danger" @click="deleteWord(s.row)">删除</el-button>
              </template>
            </el-table-column>
          </el-table>
          <el-pagination class="pager" small background layout="total, prev, pager, next" :total="wordTotal" :page-size="wordPageSize" :current-page="wordPage" @current-change="p => { wordPage = p; loadWordList() }" />
        </el-tab-pane>

        <!-- 安全通知 -->
        <el-tab-pane label="安全通知" name="notification">
          <el-form :model="form.notification" label-width="200px" size="small">
            <el-form-item label="安全事件通知渠道">
              <el-checkbox-group v-model="form.notification.notify_channels">
                <el-checkbox label="inbox">站内信</el-checkbox>
                <el-checkbox label="email">邮件</el-checkbox>
                <el-checkbox label="sms">短信</el-checkbox>
                <el-checkbox label="dingtalk">钉钉</el-checkbox>
                <el-checkbox label="wecom">企业微信</el-checkbox>
              </el-checkbox-group>
            </el-form-item>
            <el-form-item label="异常登录通知"><el-switch v-model="form.notification.notify_abnormal_login" /></el-form-item>
            <el-form-item label="密码变更通知"><el-switch v-model="form.notification.notify_password_change" /></el-form-item>
            <el-form-item label="权限变更通知"><el-switch v-model="form.notification.notify_permission_change" /></el-form-item>
          </el-form>
        </el-tab-pane>
      </el-tabs>
    </el-card>

    <!-- ===== 底部操作按钮 ===== -->
    <div class="bottom-bar">
      <el-button type="primary" :loading="saving" @click="saveAll">保存所有配置</el-button>
      <el-button plain :loading="saving" @click="resetAll">重置所有配置</el-button>
    </div>

    <!-- 敏感词弹窗 -->
    <SensitiveWordDialog ref="wordDialog" @saved="onWordSaved" />
    <!-- IP白名单弹窗 -->
    <IpWhitelistDialog ref="ipDialog" @saved="onIpSaved" />
  </div>
</template>

<script>
import {
  getPolicyList, batchSavePolicy, resetPolicy, getSecurityScore,
  getSensitiveWords, deleteSensitiveWord, batchDeleteSensitiveWord,
  importSensitiveWords, exportSensitiveWords,
  getIpWhitelist, deleteIpWhitelist, batchDeleteIpWhitelist, getCurrentIp
} from '../../../api/securityPolicy'
import SensitiveWordDialog from './components/SensitiveWordDialog.vue'
import IpWhitelistDialog from './components/IpWhitelistDialog.vue'

export default {
  name: 'SecurityPolicy',
  components: { SensitiveWordDialog, IpWhitelistDialog },
  data() {
    return {
      activeTab: 'password',
      scoreLoading: false,
      scoreInfo: {},
      form: {
        password: {}, login: {}, session: {}, ip_whitelist: {}, data: {}, ai: {}, notification: {}
      },
      wordLoading: false, wordList: [], wordTotal: 0, wordPage: 1, wordPageSize: 20,
      selectedWordRows: [],
      ipLoading: false, ipList: [], ipTotal: 0, ipPage: 1, ipPageSize: 20,
      selectedIpRows: [], currentIp: '',
      saving: false,
      categoryMap: { political: '政治', porn: '色情', violence: '暴力', ad: '广告', other: '其他' },
      severityMap: { low: '低', medium: '中', high: '高', critical: '严重' }
    }
  },
  computed: {
    scoreColor() {
      const s = this.scoreInfo.score || 0
      if (s >= 85) return '#67c23a'
      if (s >= 70) return '#409eff'
      if (s >= 50) return '#e6a23c'
      return '#f56c6c'
    }
  },
  created() {
    this.loadScore()
    this.loadPolicies()
    this.loadWordList()
    this.loadIpList()
    this.loadCurrentIp()
  },
  methods: {
    async loadScore() {
      this.scoreLoading = true
      try { this.scoreInfo = (await getSecurityScore()).data || {} } catch (e) {}
      this.scoreLoading = false
    },
    async loadPolicies() {
      try {
        const res = await getPolicyList()
        const rows = res.data || []
        const form = { password: {}, login: {}, session: {}, ip_whitelist: {}, data: {}, ai: {}, notification: {} }
        rows.forEach(r => {
          if (!form[r.group]) form[r.group] = {}
          form[r.group][r.policy_key] = r.value
        })
        this.form = form
      } catch (e) {}
    },
    async loadWordList() {
      this.wordLoading = true
      try {
        const res = await getSensitiveWords({ page: this.wordPage, limit: this.wordPageSize })
        this.wordList = res.data.list || []
        this.wordTotal = res.data.total || 0
      } catch (e) {}
      this.wordLoading = false
    },
    async loadIpList() {
      this.ipLoading = true
      try {
        const res = await getIpWhitelist({ page: this.ipPage, limit: this.ipPageSize })
        this.ipList = res.data.list || []
        this.ipTotal = res.data.total || 0
      } catch (e) {}
      this.ipLoading = false
    },
    async loadCurrentIp() {
      try { this.currentIp = (await getCurrentIp()).data.ip || '' } catch (e) {}
    },
    async saveAll() {
      this.saving = true
      try {
        const items = []
        Object.keys(this.form).forEach(g => {
          Object.keys(this.form[g]).forEach(k => {
            items.push({ policy_key: k, policy_value: this.form[g][k] })
          })
        })
        const res = await batchSavePolicy({ items })
        this.$message.success(res.msg || '保存成功')
        this.loadScore()
      } catch (e) {}
      this.saving = false
    },
    async resetAll() {
      this.$confirm('确定将全部策略恢复为默认值？', '提示', { type: 'warning' }).then(async () => {
        try {
          const rows = (await getPolicyList()).data || []
          for (const r of rows) {
            await resetPolicy(r.id)
          }
          this.$message.success('已重置所有策略')
          this.loadPolicies()
          this.loadScore()
        } catch (e) {}
      }).catch(() => {})
    },
    categoryText(v) { return this.categoryMap[v] || v || '-' },
    severityText(v) { return this.severityMap[v] || v || '-' },
    severityType(v) { return { low: 'info', medium: 'warning', high: 'danger', critical: 'danger' }[v] || 'info' },
    onWordSaved() { this.loadWordList(); this.loadScore() },
    deleteWord(row) {
      this.$confirm(`确定删除敏感词「${row.word}」？`, '提示', { type: 'warning' }).then(async () => {
        try { await deleteSensitiveWord(row.id); this.$message.success('已删除'); this.loadWordList(); this.loadScore() } catch (e) {}
      }).catch(() => {})
    },
    batchDeleteWords() {
      this.$confirm(`确定删除选中的 ${this.selectedWordRows.length} 个敏感词？`, '提示', { type: 'warning' }).then(async () => {
        try {
          await batchDeleteSensitiveWord(this.selectedWordRows.map(r => r.id))
          this.$message.success('已删除'); this.loadWordList(); this.loadScore()
        } catch (e) {}
      }).catch(() => {})
    },
    async doImportWords({ file }) {
      const fd = new FormData()
      fd.append('file', file)
      try { const res = await importSensitiveWords(fd); this.$message.success(res.msg); this.loadWordList(); this.loadScore() } catch (e) {}
    },
    async doExportWords() {
      try {
        const res = await exportSensitiveWords()
        const blob = new Blob([res.data], { type: 'text/plain;charset=utf-8' })
        const url = URL.createObjectURL(blob)
        const a = document.createElement('a')
        a.href = url; a.download = 'sensitive_words.txt'; a.click()
        URL.revokeObjectURL(url)
      } catch (e) {}
    },
    onIpSaved() { this.loadIpList() },
    deleteIp(row) {
      this.$confirm(`确定删除白名单 ${row.ip_address}？`, '提示', { type: 'warning' }).then(async () => {
        try { await deleteIpWhitelist(row.id); this.$message.success('已删除'); this.loadIpList() } catch (e) {}
      }).catch(() => {})
    },
    batchDeleteIp() {
      this.$confirm(`确定删除选中的 ${this.selectedIpRows.length} 条记录？`, '提示', { type: 'warning' }).then(async () => {
        try {
          await batchDeleteIpWhitelist(this.selectedIpRows.map(r => r.id))
          this.$message.success('已删除'); this.loadIpList()
        } catch (e) {}
      }).catch(() => {})
    }
  }
}
</script>

<style scoped>
.security-policy-page { padding: 4px 16px; }
.score-card { margin-bottom: 14px; }
.score-body { display: flex; align-items: center; }
.score-left { width: 220px; text-align: center; border-right: 1px solid #ebeef5; padding-right: 20px; }
.score-num { font-size: 52px; font-weight: 700; line-height: 1.1; }
.score-level { font-size: 18px; margin-top: 2px; }
.score-desc { color: #909399; font-size: 13px; margin-top: 6px; }
.score-time { color: #c0c4cc; font-size: 12px; margin-top: 2px; }
.score-right { flex: 1; padding-left: 24px; }
.score-checks { margin-top: 10px; }
.check-tag { margin: 2px 4px 2px 0; }
.unit { color: #909399; margin-left: 6px; font-size: 12px; }
.tip { color: #909399; font-size: 12px; margin-top: 4px; }
.sub-head { display: flex; align-items: center; margin: 12px 0 10px; font-weight: 600; }
.flex-1 { flex: 1; }
.pager { margin-top: 10px; text-align: right; }
.expired { color: #f56c6c; }
.bottom-bar { margin-top: 14px; background: #fff; padding: 10px 24px; box-shadow: 0 2px 8px rgba(0,0,0,.06); text-align: right; border: 1px solid #ebeef5; border-radius: 4px; }
</style>
