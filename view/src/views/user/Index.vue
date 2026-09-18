<template>
  <div class="user-page">
    <!-- 统计 -->
    <el-row :gutter="16" style="margin-bottom:16px;">
      <el-col :span="6" v-for="s in stats" :key="s.label">
        <el-card shadow="hover"><div class="stat-val">{{ s.value }}</div><div class="stat-lbl">{{ s.label }}</div></el-card>
      </el-col>
    </el-row>

    <el-card shadow="never">
      <div slot="header">
        <span>用户管理</span>
        <div style="float:right;">
          <el-button v-if="hasPerm('user:store')" size="small" type="primary" @click="openForm()">新增用户</el-button>
        </div>
      </div>
      <!-- 筛选 -->
      <el-form :inline="true" size="small">
        <el-form-item><el-input v-model="filters.keyword" placeholder="用户名/姓名/手机号" clearable @input="searchDelay" /></el-form-item>
        <el-form-item><el-select v-model="filters.status" placeholder="状态" clearable @change="fetchList"><el-option v-for="s in dictStatus" :key="s.value" :label="s.label" :value="s.value" /></el-select></el-form-item>
        <el-form-item><el-select v-model="filters.user_type" placeholder="类型" clearable @change="fetchList"><el-option v-for="t in dictUserType" :key="t.value" :label="t.label" :value="t.value" /></el-select></el-form-item>
        <el-form-item><el-button type="primary" @click="fetchList">搜索</el-button></el-form-item>
      </el-form>
      <!-- 表格 -->
      <el-table :data="list" v-loading="loading" stripe border size="small">
        <el-table-column type="index" label="#" width="50" />
        <el-table-column prop="username" label="用户名" width="110" />
        <el-table-column prop="real_name" label="姓名" width="100" />
        <el-table-column prop="phone" label="手机号" width="120" />
        <el-table-column prop="employee_id" label="工号" width="80" />
        <el-table-column label="部门" width="100"><template slot-scope="{row}">{{ row.department?.name || '-' }}</template></el-table-column>
        <el-table-column prop="position" label="岗位" width="100" />
        <el-table-column label="类型" width="100"><template slot-scope="{row}"><el-tag size="mini">{{ getDictLabel(dictUserType, row.user_type) }}</el-tag></template></el-table-column>
        <el-table-column label="角色" width="160">
          <template slot-scope="{row}">
            <template v-if="row.roles && row.roles.length">
              <el-tag v-for="r in row.roles" :key="r.id" size="mini" style="margin:1px 2px;">{{ r.name }}</el-tag>
            </template>
            <span v-else style="color:#ccc;">未分配</span>
          </template>
        </el-table-column>
        <el-table-column prop="last_login_at" label="最后登录" width="160" />
        <el-table-column label="状态" width="70"><template slot-scope="{row}"><el-switch :value="!!row.status" @change="toggleStatus(row)" /></template></el-table-column>
        <el-table-column label="操作" width="300" fixed="right">
          <template slot-scope="{row}">
            <el-button v-if="hasPerm('user:update')" type="text" size="small" @click="openForm(row)">编辑</el-button>
            <el-button v-if="hasPerm('user:assignRoles')" type="text" size="small" @click="openAssignRole(row)">分配角色</el-button>
            <el-button v-if="row.allow_login && hasPerm('user:resetPassword')" type="text" size="small" @click="openResetPwd(row)">重置密码</el-button>
            <el-button v-if="!row.is_super_admin && hasPerm('user:destroy')" type="text" size="small" style="color:#f56c6c;" @click="handleDelete(row)">删除</el-button>
          </template>
        </el-table-column>
      </el-table>
      <el-pagination background :current-page="page" :page-size="limit" :total="total" layout="total,sizes,prev,pager,next" :page-sizes="[10,20,50,100]" @size-change="s=>{limit=s;fetchList()}" @current-change="p=>{page=p;fetchList()}" style="margin-top:16px;" />
    </el-card>

    <!-- 重置密码 -->
    <el-dialog title="重置密码" :visible.sync="pwdVisible" width="450px">
      <el-form :model="pwdForm" label-width="100px" size="small">
        <el-form-item label="新密码"><el-input v-model="pwdForm.password" type="password" show-password /></el-form-item>
        <el-form-item label="确认密码"><el-input v-model="pwdForm.confirm" type="password" show-password /></el-form-item>
      </el-form>
      <span slot="footer"><el-button @click="pwdVisible=false">取消</el-button><el-button type="primary" :loading="saving" @click="handleResetPwd">确认重置</el-button></span>
    </el-dialog>

    <!-- 新增/编辑用户 -->
    <el-dialog :title="formId?'编辑用户':'新增用户'" :visible.sync="formVisible" width="700px">
      <el-form :model="form" label-width="100px" size="small">
        <h4>基础信息</h4>
        <el-row :gutter="16">
          <el-col :span="12"><el-form-item label="真实姓名"><el-input v-model="form.real_name" /></el-form-item></el-col>
          <el-col :span="12"><el-form-item label="手机号"><el-input v-model="form.phone" maxlength="11" /></el-form-item></el-col>
          <el-col :span="12"><el-form-item label="工号"><el-input v-model="form.employee_id" /></el-form-item></el-col>
          <el-col :span="12"><el-form-item label="邮箱"><el-input v-model="form.email" /></el-form-item></el-col>
          <el-col :span="12"><el-form-item label="性别"><el-select v-model="form.gender"><el-option v-for="g in dictGender" :key="g.value" :label="g.label" :value="g.value" /></el-select></el-form-item></el-col>
        </el-row>
        <h4>登录信息</h4>
        <el-row :gutter="16">
          <el-col :span="12"><el-form-item label="用户名"><el-input v-model="form.username" :disabled="!!formId" /></el-form-item></el-col>
          <el-col :span="12"><el-form-item :label="formId?'新密码':'密码'"><el-input v-model="form.password" type="password" show-password :placeholder="formId?'留空不修改':''" /></el-form-item></el-col>
          <el-col :span="12"><el-form-item label="用户类型"><el-select v-model="form.user_type"><el-option v-for="t in dictUserType" :key="t.value" :label="t.label" :value="t.value" /></el-select></el-form-item></el-col>
          <el-col :span="12"><el-form-item label="允许登录"><el-switch v-model="form.allow_login" /></el-form-item></el-col>
        </el-row>
        <h4>组织信息</h4>
        <el-row :gutter="16">
          <el-col :span="12"><el-form-item label="部门"><el-select v-model="form.department_id" clearable style="width:100%;"><el-option v-for="d in deptOptions" :key="d.id" :label="d.label" :value="d.id" /></el-select></el-form-item></el-col>
          <el-col :span="12"><el-form-item label="岗位"><el-select v-model="form.position_id" clearable style="width:100%;"><el-option v-for="p in posOptions" :key="p.id" :label="p.name" :value="p.id" /></el-select></el-form-item></el-col>
          <el-col :span="12"><el-form-item label="直属上级"><el-select v-model="form.leader_id" filterable clearable style="width:100%;"><el-option v-for="u in userOptions" :key="u.id" :label="u.real_name||u.username" :value="u.id" /></el-select></el-form-item></el-col>
          <el-col :span="12"><el-form-item label="入职日期"><el-date-picker v-model="form.hire_date" value-format="yyyy-MM-dd" style="width:100%;" /></el-form-item></el-col>
          <el-col :span="12"><el-form-item label="状态"><el-switch v-model="form.status" /></el-form-item></el-col>
        </el-row>
        <template v-if="form.user_type && form.user_type !== 1">
          <h4>员工档案</h4>
          <el-row :gutter="16">
            <el-col :span="12"><el-form-item label="身份证号"><el-input v-model="form.profile.id_card" /></el-form-item></el-col>
            <el-col :span="12"><el-form-item label="银行卡号"><el-input v-model="form.profile.bank_card" /></el-form-item></el-col>
            <el-col :span="12"><el-form-item label="紧急联系人"><el-input v-model="form.profile.emergency_contact" /></el-form-item></el-col>
            <el-col :span="12"><el-form-item label="联系电话"><el-input v-model="form.profile.emergency_phone" /></el-form-item></el-col>
            <el-col :span="12"><el-form-item label="学历"><el-input v-model="form.profile.education" /></el-form-item></el-col>
            <el-col :span="12"><el-form-item label="毕业院校"><el-input v-model="form.profile.graduate_school" /></el-form-item></el-col>
            <el-col :span="12"><el-form-item label="合同签订日"><el-date-picker v-model="form.profile.contract_start_date" value-format="yyyy-MM-dd" style="width:100%;" /></el-form-item></el-col>
            <el-col :span="12"><el-form-item label="员工状态"><el-select v-model="form.profile.employee_status"><el-option v-for="s in dictEmpStatus" :key="s.value" :label="s.label" :value="s.value" /></el-select></el-form-item></el-col>
          </el-row>
        </template>
      </el-form>
      <span slot="footer"><el-button @click="formVisible=false">取消</el-button><el-button type="primary" :loading="saving" @click="handleSave">保存</el-button></span>
    </el-dialog>

    <!-- 分配角色 -->
    <el-dialog title="分配角色" :visible.sync="roleVisible" width="550px">
      <el-checkbox-group v-model="selectedRoleIds">
        <el-checkbox v-for="r in allRoles" :key="r.id" :label="r.id" style="margin:6px 12px 6px 0;width:120px;">{{ r.name }}</el-checkbox>
      </el-checkbox-group>
      <div v-if="assignUser?.user_type===2" style="color:#999;font-size:12px;margin-top:8px;">该用户为普通员工，角色仅在小程序端生效</div>
      <span slot="footer"><el-button @click="roleVisible=false">取消</el-button><el-button type="primary" :loading="roleSaving" @click="saveAssignRole">保存</el-button></span>
    </el-dialog>
  </div>
</template>

<script>
import { getUserList, getUserDetail, createUser, updateUser, deleteUser, setUserStatus, resetUserPassword, assignUserRoles } from '@/api/user'
import { getDictByCode } from '@/api/dictionary'
import { getDictLabel as getDictLabelUtil } from '@/utils/dict'
import { getDeptTree, getPositions } from '@/api/organization'
import { getRoleList } from '@/api/role'

function flattenDept(nodes) {
  let r=[]
  for(const n of nodes){r.push(n);if(n.children)r=r.concat(flattenDept(n.children))}
  return r
}

export default {
  name: 'UserIndex',
  data() {
    return {
      loading: false, list: [], total: 0, page: 1, limit: 20,
      filters: { keyword: '', status: '', user_type: '' },
      searchTimer: null, stats: [],
      formVisible: false, formId: null, saving: false,
      form: { real_name:'', phone:'', username:'', password:'', employee_id:'', email:'', gender:0, user_type:3, allow_login:1, department_id:null, position:'', leader_id:null, hire_date:'', status:1, profile:{} },
      dictUserType: [], dictStatus: [], dictGender: [], dictEmpStatus: [],
      deptOptions: [], posOptions: [],
      userOptions: [],
      pwdVisible: false, pwdForm: { password:'', confirm:'' }, pwdUserId: null,
      roleVisible: false, roleSaving: false, assignUser: null, selectedRoleIds: [], allRoles: []
    }
  },
  created() {
    this.fetchList(); this.fetchStats(); this.loadDepts(); this.loadUsers(); this.loadPosOptions(); this.loadRoles()
    getDictByCode('user_type').then(r=>{if(r.code===0)this.dictUserType=r.data||[]}).catch(()=>{})
    getDictByCode('dict_status').then(r=>{if(r.code===0)this.dictStatus=r.data||[]}).catch(()=>{})
    getDictByCode('gender').then(r=>{if(r.code===0)this.dictGender=r.data||[]}).catch(()=>{})
    getDictByCode('employee_status').then(r=>{if(r.code===0)this.dictEmpStatus=r.data||[]}).catch(()=>{})
  },
  methods: {
    // 权限判断：按钮权限控制
    hasPerm(code) { const p = this.$store.state.user && this.$store.state.user.permissions ? this.$store.state.user.permissions : []; return p.indexOf(code) > -1 },
    getDictLabel(items, val) { return getDictLabelUtil(items, val) },
    async loadDepts() {
      try{const r=await getDeptTree();if(r.code===0){const flat=flattenDept(r.data||[]);this.deptOptions=flat.map(d=>({id:d.id,label:d.name}))} }catch{}
    },
    async loadPosOptions() {
      try{const r=await getPositions(0);if(r.code===0)this.posOptions=r.data||[]}catch{}
    },
    async fetchList() {
      this.loading = true
      try { const r = await getUserList({ page: this.page, limit: this.limit, ...this.filters }); this.list = r.data.list; this.total = r.data.total } catch (e) { /* */ }
      this.loading = false
    },
    async fetchStats() {
      try { const r = await getUserList({ page: 1, limit: 1 }); const s = r.data.stats || {}; this.stats = [{ label:'总用户数', value:s.total_users||'-' }, { label:'在线用户', value:s.online_users||0 }, { label:'今日新增', value:s.today_new||0 }, { label:'本月新增', value:s.month_new||0 }] } catch (e) { /* */ }
    },
    searchDelay() { clearTimeout(this.searchTimer); this.searchTimer = setTimeout(() => { this.page = 1; this.fetchList() }, 500) },
    async loadUsers() { try { const r = await getUserList({ page: 1, limit: 999 }); this.userOptions = r.data.list } catch (e) { /* */ } },
    async loadRoles() { try { const r = await getRoleList(); this.allRoles = r.data.list || r.data || [] } catch (e) { /* */ } },
    async openForm(row) {
      this.formId = row?.id || null
      // 编辑时加载详情（含员工档案profile数据）
      let src
      if (row?.id) {
        try { const r = await getUserDetail(row.id); if (r.code === 0) row = r.data } catch (e) { /* */ }
        src = { ...row, password: '', profile: row.profile || {} }
      } else {
        src = { real_name:'', phone:'', username:'', password:'', employee_id:'', email:'', gender:0, user_type:3, allow_login:1, department_id:null, position:'', leader_id:null, hire_date:'', status:1, profile:{} }
      }
      ;['allow_login','status','is_super_admin'].forEach(f => {
        if (src[f] !== undefined) src[f] = src[f] === true || src[f] === 1 || src[f] === '1'
      })
      this.form = src
      this.formVisible = true
    },
    async handleSave() {
      this.saving = true
      try { if (this.formId) await updateUser(this.formId, this.form); else await createUser(this.form); this.$message.success('保存成功'); this.formVisible = false; this.fetchList(); this.fetchStats() } catch (e) { /* */ }
      this.saving = false
    },
    async handleDelete(row) {
      await this.$confirm(`确认删除「${row.real_name}」？`, '提示', { type: 'warning' })
      try { await deleteUser(row.id); this.$message.success('已删除'); this.fetchList(); this.fetchStats() } catch (e) { /* */ }
    },
    async toggleStatus(row) { try { await setUserStatus(row.id, row.status ? 0 : 1); this.$message.success('状态已更新'); this.fetchList() } catch (e) { /* */ } },
    openResetPwd(row) { this.pwdUserId = row.id; this.pwdForm = { password:'', confirm:'' }; this.pwdVisible = true },
    async handleResetPwd() {
      if (this.pwdForm.password !== this.pwdForm.confirm) { this.$message.error('两次密码不一致'); return }
      this.saving = true
      try { await resetUserPassword(this.pwdUserId, this.pwdForm.password); this.$message.success('密码已重置'); this.pwdVisible = false } catch (e) { /* */ }
      this.saving = false
    },
    openAssignRole(row) {
      this.assignUser = row
      this.selectedRoleIds = (row.roles || []).map(r => r.id)
      this.roleVisible = true
    },
    async saveAssignRole() {
      this.roleSaving = true
      try { await assignUserRoles(this.assignUser.id, this.selectedRoleIds.join(',')); this.$message.success('角色分配成功'); this.roleVisible = false; this.fetchList() } catch (e) { /* */ }
      this.roleSaving = false
    }
  }
}
</script>

<style scoped>
.user-page { padding: 0; }
.stat-val { font-size: 28px; font-weight: bold; color: #409eff; text-align: center; }
.stat-lbl { font-size: 13px; color: #999; text-align: center; margin-top: 4px; }
h4 { margin: 12px 0; color: #666; border-bottom: 1px solid #f0f0f0; padding-bottom: 6px; }
</style>
