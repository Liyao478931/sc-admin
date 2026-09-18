<template>
  <div class="fido2-policy-page">
    <!-- 一、全局配置 -->
    <el-card shadow="never" class="sec-card">
      <div slot="header" class="sec-head"><span class="sec-title">FIDO2 安全策略</span><span class="sec-desc">仅对指定账号强制启用，普通账号不受影响</span></div>
      <el-form :model="cfg" label-width="130px" size="small">
        <el-row :gutter="24">
          <el-col :span="12">
            <el-form-item label="全局开关"><el-switch v-model="cfg.enabled" :active-value="1" :inactive-value="0" active-text="启用" inactive-text="停用" /></el-form-item>
            <el-form-item label="RP ID"><el-input v-model="cfg.rp_id" placeholder="留空则取系统域名（当前访问域名）" /></el-form-item>
            <el-form-item label="用户验证策略">
              <el-select v-model="cfg.user_verification" style="width:200px;">
                <el-option label="required（强制）" value="required" />
                <el-option label="preferred（优先）" value="preferred" />
              </el-select>
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="RP Name"><el-input v-model="cfg.rp_name" placeholder="如 数智管控平台" /></el-form-item>
            <el-form-item label="允许记住设备"><el-switch v-model="cfg.allow_remember_device" :active-value="1" :inactive-value="0" /></el-form-item>
            <el-form-item v-if="cfg.allow_remember_device === 1" label="记住天数"><el-input-number v-model="cfg.remember_days" :min="1" :max="30" style="width:200px;" /></el-form-item>
          </el-col>
        </el-row>
        <el-form-item><el-button type="primary" size="small" :loading="saving" @click="saveConfig">保存配置</el-button></el-form-item>
      </el-form>
      <div class="log-tip">说明：命中强制规则（指定用户 > 指定角色 > 指定部门）的账号，登录时账号密码验证通过后，必须通过手机密钥（FIDO2）二次验证才能登录；未绑定密钥的强制账号将被提示先绑定。</div>
    </el-card>

    <!-- 二、指定用户 -->
    <el-card shadow="never" class="sec-card">
      <div slot="header" class="sec-head">
        <span class="sec-title">指定用户</span><span class="sec-desc">优先级最高</span>
        <span style="flex:1"></span>
        <el-button size="small" type="primary" icon="el-icon-plus" @click="openAdd('user')">添加用户</el-button>
      </div>
      <el-table :data="lists.user" size="small" stripe v-loading="loading.user">
        <el-table-column prop="target_name" label="用户" min-width="180" />
        <el-table-column prop="reason" label="强制原因" min-width="150" show-overflow-tooltip />
        <el-table-column prop="created_at" label="添加时间" width="170" />
        <el-table-column label="操作" width="90" align="center">
          <template slot-scope="s"><el-button type="text" size="mini" class="danger" @click="remove('user', s.row)">移除</el-button></template>
        </el-table-column>
      </el-table>
    </el-card>

    <!-- 三、指定角色 -->
    <el-card shadow="never" class="sec-card">
      <div slot="header" class="sec-head">
        <span class="sec-title">指定角色</span><span class="sec-desc">优先级中</span>
        <span style="flex:1"></span>
        <el-button size="small" type="primary" icon="el-icon-plus" @click="openAdd('role')">添加角色</el-button>
      </div>
      <el-table :data="lists.role" size="small" stripe v-loading="loading.role">
        <el-table-column prop="target_name" label="角色" min-width="180" />
        <el-table-column prop="reason" label="强制原因" min-width="150" show-overflow-tooltip />
        <el-table-column prop="created_at" label="添加时间" width="170" />
        <el-table-column label="操作" width="90" align="center">
          <template slot-scope="s"><el-button type="text" size="mini" class="danger" @click="remove('role', s.row)">移除</el-button></template>
        </el-table-column>
      </el-table>
    </el-card>

    <!-- 四、指定部门 -->
    <el-card shadow="never" class="sec-card">
      <div slot="header" class="sec-head">
        <span class="sec-title">指定部门</span><span class="sec-desc">优先级低</span>
        <span style="flex:1"></span>
        <el-button size="small" type="primary" icon="el-icon-plus" @click="openAdd('department')">添加部门</el-button>
      </div>
      <el-table :data="lists.department" size="small" stripe v-loading="loading.department">
        <el-table-column prop="target_name" label="部门" min-width="180" />
        <el-table-column prop="reason" label="强制原因" min-width="150" show-overflow-tooltip />
        <el-table-column prop="created_at" label="添加时间" width="170" />
        <el-table-column label="操作" width="90" align="center">
          <template slot-scope="s"><el-button type="text" size="mini" class="danger" @click="remove('department', s.row)">移除</el-button></template>
        </el-table-column>
      </el-table>
    </el-card>

    <!-- 添加强制对象弹窗 -->
    <el-dialog :title="addTitle" :visible.sync="addVisible" width="460px" top="15vh">
      <el-form label-width="80px" size="small">
        <el-form-item :label="addTypeLabel">
          <!-- 用户：远程搜索 -->
          <el-select v-if="addType === 'user'" v-model="addTargetId" filterable remote :remote-method="searchUsers" :loading="userSearching" placeholder="输入用户名/姓名搜索" style="width:100%;" @focus="searchUsers('')">
            <el-option v-for="u in userOptions" :key="u.id" :label="u.label" :value="u.id" />
          </el-select>
          <!-- 角色/部门：下拉 -->
          <el-select v-else v-model="addTargetId" placeholder="请选择" style="width:100%;">
            <el-option v-for="o in targetOptions" :key="o.id" :label="o.name" :value="o.id" />
          </el-select>
        </el-form-item>
        <el-form-item label="强制原因"><el-input v-model="addReason" placeholder="选填，说明强制原因" maxlength="100" /></el-form-item>
      </el-form>
      <span slot="footer">
        <el-button size="small" @click="addVisible=false">取 消</el-button>
        <el-button size="small" type="primary" :loading="adding" @click="doAdd">确认添加</el-button>
      </span>
    </el-dialog>
  </div>
</template>

<script>
import {
  getFido2PolicyConfig, saveFido2PolicyConfig,
  getFido2Forced, addFido2Forced, deleteFido2Forced,
  fido2UserOptions, fido2RoleOptions, fido2DepartmentOptions
} from '@/api/webauthn'

const TYPE_MAP = { user: 'user', role: 'role', department: 'department' }

export default {
  name: 'Fido2Policy',
  data () {
    return {
      cfg: { enabled: 0, rp_id: '', rp_name: '数智管控平台', user_verification: 'required', allow_remember_device: 1, remember_days: 7 },
      lists: { user: [], role: [], department: [] },
      loading: { user: false, role: false, department: false },
      saving: false, adding: false,
      addVisible: false, addType: 'user', addTargetId: null, addReason: '',
      userOptions: [], userSearching: false, targetOptions: []
    }
  },
  computed: {
    addTitle () { return '添加' + ({ user: '指定用户', role: '指定角色', department: '指定部门' }[this.addType] || '') },
    addTypeLabel () { return { user: '用户', role: '角色', department: '部门' }[this.addType] || '' }
  },
  created () { this.loadConfig(); this.loadLists() },
  methods: {
    async loadConfig () {
      try {
        const r = await getFido2PolicyConfig()
        if (r.code === 0) this.cfg = Object.assign(this.cfg, r.data || {})
      } catch (e) {}
    },
    async loadLists () {
      this.loading.user = this.loading.role = this.loading.department = true
      try {
        const r = await getFido2Forced()
        if (r.code === 0) {
          const list = r.data.list || []
          this.lists.user = list.filter(x => x.target_type === 'user')
          this.lists.role = list.filter(x => x.target_type === 'role')
          this.lists.department = list.filter(x => x.target_type === 'department')
        }
      } catch (e) {} finally {
        this.loading.user = this.loading.role = this.loading.department = false
      }
    },
    async saveConfig () {
      this.saving = true
      try {
        const r = await saveFido2PolicyConfig(this.cfg)
        this.$message.success(r.msg || '配置已保存')
        this.loadConfig()
      } catch (e) {} finally { this.saving = false }
    },
    async openAdd (type) {
      this.addType = type
      this.addTargetId = null
      this.addReason = ''
      this.userOptions = []
      this.targetOptions = []
      this.addVisible = true
      if (type === 'role') {
        try { const r = await fido2RoleOptions(); if (r.code === 0) this.targetOptions = r.data.list || [] } catch (e) {}
      } else if (type === 'department') {
        try { const r = await fido2DepartmentOptions(); if (r.code === 0) this.targetOptions = r.data.list || [] } catch (e) {}
      }
    },
    async searchUsers (kw) {
      this.userSearching = true
      try {
        const r = await fido2UserOptions({ keyword: kw })
        if (r.code === 0) this.userOptions = r.data.list || []
      } catch (e) {} finally { this.userSearching = false }
    },
    async doAdd () {
      if (!this.addTargetId) { this.$message.warning('请选择目标'); return }
      this.adding = true
      try {
        const r = await addFido2Forced({ target_type: this.addType, target_id: this.addTargetId, reason: this.addReason })
        this.$message.success(r.msg || '已添加')
        this.addVisible = false
        this.loadLists()
      } catch (e) {} finally { this.adding = false }
    },
    async remove (type, row) {
      this.$confirm('确认移除该' + ({ user: '用户', role: '角色', department: '部门' }[type]) + '的强制启用？', '移除确认', { type: 'warning' }).then(async () => {
        try {
          const r = await deleteFido2Forced({ target_type: type, target_id: row.target_id })
          this.$message.success(r.msg || '已移除')
          this.loadLists()
        } catch (e) {}
      }).catch(() => {})
    }
  }
}
</script>

<style scoped>
.fido2-policy-page { padding: 16px; background: #f0f2f5; min-height: 100%; }
.sec-card { margin-bottom: 16px; }
.sec-head { display: flex; align-items: center; gap: 12px; }
.sec-title { font-size: 15px; font-weight: 600; color: #303133; }
.sec-desc { font-size: 12px; color: #909399; }
.log-tip { font-size: 12px; color: #909399; }
.danger { color: #F56C6C; }
</style>
