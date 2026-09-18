<template>
  <div class="role-page">
    <el-row :gutter="16">
      <!-- 左侧角色列表 -->
      <el-col :span="8">
        <el-card shadow="never">
          <div slot="header">
            <span>角色列表</span>
            <div style="float:right;">
              <el-button v-if="batchDeleteEnabled && hasPerm('role:destroy')" size="small" type="danger" :disabled="selectedRoles.length===0" @click="batchDelete">批量删除</el-button>
              <el-button v-if="hasPerm('role:store')" size="small" type="primary" @click="openForm()">新增角色</el-button>
            </div>
          </div>
          <el-input v-model="search" placeholder="搜索角色" size="small" style="margin-bottom:12px;" />
          <div style="margin-bottom:8px;display:flex;align-items:center;gap:8px" v-if="batchDeleteEnabled">
            <el-checkbox :indeterminate="isIndeterminate" v-model="checkAll" @change="onCheckAll">全选</el-checkbox>
            <span style="font-size:12px;color:#999">已选 {{ selectedRoles.length }} 项</span>
          </div>
          <div v-for="r in filteredRoles" :key="r.id" class="role-card" :class="{active:activeRole?.id===r.id}" @click="selectRole(r)">
            <div style="display:flex;align-items:center;gap:8px">
              <el-checkbox v-if="batchDeleteEnabled && !r.is_system" :value="selectedSet.has(r.id)" @change="toggleSelect(r)" @click.stop />
              <div style="flex:1">
                <div class="role-name">{{ r.name }} <el-tag v-if="r.is_system" size="mini" type="info">系统</el-tag></div>
                <div class="role-code">{{ r.code }}</div>
              </div>
            </div>
            <div class="role-actions">
              <el-button v-if="hasPerm('role:update')" type="text" size="mini" @click.stop="openForm(r)">编辑</el-button>
              <el-button v-if="!r.is_system && hasPerm('role:destroy')" type="text" size="mini" style="color:#f56c6c;" @click.stop="handleDelete(r)">删除</el-button>
            </div>
          </div>
          <el-empty v-if="!filteredRoles.length" description="暂无角色" />
        </el-card>
      </el-col>
      <!-- 右侧权限配置 -->
      <el-col :span="16">
        <el-card v-if="activeRole" shadow="never">
          <div slot="header">
            <span>{{ activeRole.name }} ({{ activeRole.code }})</span>
            <div style="float:right;">
              <el-button v-if="hasPerm('role:savePermissions')" size="small" type="primary" :loading="permSaving" @click="savePerms">保存权限</el-button>
            </div>
          </div>
          <el-tabs v-model="permTab">
            <el-tab-pane label="菜单权限" name="menu">
              <div style="margin-bottom:8px;">
                <el-button size="mini" type="primary" @click="checkAll('menu')">全选</el-button>
                <el-button size="mini" @click="clearAll('menu')">清空</el-button>
                <span style="margin-left:12px;color:#999;font-size:12px;">已选 {{ menuCheckedCount }} 项</span>
              </div>
              <el-tree ref="menuTree" :data="menuTree" show-checkbox node-key="id" :props="{label:'display_name',children:'children'}" @check-change="updateCounts">
                <span slot-scope="{data}" class="perm-node">
                  <span>{{ data.display_name || data.name }}</span>
                  <el-tag v-if="data.type_label" size="mini" type="" style="margin-left:4px;">{{ data.type_label }}</el-tag>
                </span>
              </el-tree>
            </el-tab-pane>
            <el-tab-pane label="按钮权限" name="btn">
              <div style="margin-bottom:8px;">
                <el-select v-model="moduleFilter" placeholder="按模块筛选" clearable size="mini" style="width:160px;margin-right:8px;" @change="filterBtnTree">
                  <el-option v-for="m in btnModules" :key="m" :label="m" :value="m" />
                </el-select>
                <el-button size="mini" type="primary" @click="checkAll('btn')">全选</el-button>
                <el-button size="mini" @click="clearAll('btn')">清空</el-button>
                <span style="margin-left:12px;color:#999;font-size:12px;">已选 {{ btnCheckedCount }} 项</span>
              </div>
              <el-tree ref="btnTree" :data="filteredBtnTree" show-checkbox node-key="id" :props="{label:'display_name',children:'children'}" @check-change="updateCounts">
                <span slot-scope="{data}" class="perm-node">
                  <span>{{ data.display_name || data.name }}</span>
                  <el-tag v-if="data.type_label" size="mini" type="warning" style="margin-left:4px;">{{ data.type_label }}</el-tag>
                </span>
              </el-tree>
            </el-tab-pane>
          </el-tabs>
          <div style="margin-top:16px;">
            <h4>数据范围</h4>
            <el-select v-model="activeRole.data_scope" size="small">
              <el-option label="全部数据" :value="1" />
              <el-option label="本部门及下属" :value="2" />
              <el-option label="本部门" :value="3" />
              <el-option label="仅本人" :value="4" />
              <el-option label="自定义部门" :value="5" />
            </el-select>
          </div>
        </el-card>
        <el-card v-else shadow="never"><el-empty description="请选择一个角色" /></el-card>
      </el-col>
    </el-row>

    <el-dialog :title="formId?'编辑角色':'新增角色'" :visible.sync="formVisible" width="520px">
      <el-form :model="form" label-width="100px" size="small">
        <el-form-item label="角色名称"><el-input v-model="form.name" /></el-form-item>
        <el-form-item label="角色编码"><el-input v-model="form.code" :disabled="!!formId" /></el-form-item>
        <el-form-item label="描述"><el-input v-model="form.description" type="textarea" /></el-form-item>
        <el-form-item label="状态"><el-switch v-model="form.status" /></el-form-item>
      </el-form>
      <span slot="footer"><el-button @click="formVisible=false">取消</el-button><el-button type="primary" :loading="saving" @click="handleSave">保存</el-button></span>
    </el-dialog>
  </div>
</template>

<script>
import { getRoleList, createRole, updateRole, deleteRole, getRolePermissions, saveRolePermissions, getPermissionTree } from '@/api/role'
import { getSettingValue } from '@/api/settings'

export default {
  name: 'RoleIndex',
  data() {
    return {
      roles: [], search: '', activeRole: null,
      menuTree: [], btnTree: [], filteredBtnTree: [], btnModules: [],
      permTab: 'menu', permSaving: false, moduleFilter: '',
      menuCheckedCount: 0, btnCheckedCount: 0,
      selectedPermIds: [],
      formVisible: false, formId: null, saving: false,
      form: { name:'', code:'', description:'', status:1 },
      batchDeleteEnabled: false, selectedSet: new Set(), checkAll: false, isIndeterminate: false,
    }
  },
  computed: {
    filteredRoles() {
      return this.roles.filter(r => !this.search || r.name.includes(this.search) || r.code.includes(this.search))
    },
    selectedRoles() { return this.roles.filter(r => this.selectedSet.has(r.id) && !r.is_system) },
  },
  created() { this.fetchRoles(); this.loadTrees(); this.checkBatchDelete() },
  methods: {
    // 权限判断：按钮权限控制
    hasPerm(code) { const p = this.$store.state.user && this.$store.state.user.permissions ? this.$store.state.user.permissions : []; return p.indexOf(code) > -1 },
    async checkBatchDelete() {
      try { const r = await getSettingValue('role_batch_delete_enabled'); this.batchDeleteEnabled = r.data?.value === '1' } catch {}
    },
    async fetchRoles() { try { const r = await getRoleList(); this.roles = r.data.list || r.data || [] } catch (e) { this.$message.error('加载角色列表失败') } },
    async loadTrees() { try {
      const [m, b] = await Promise.all([getPermissionTree(1), getPermissionTree(2)])
      this.menuTree = m.data; this.btnTree = b.data; this.filteredBtnTree = b.data
      // 提取所有模块名
      const mods = new Set()
      const extract = (nodes) => { for (const n of nodes) { if (n.module) mods.add(n.module); if (n.children) extract(n.children) } }
      extract(b.data)
      this.btnModules = [...mods].sort()
    } catch (e) { /* */ }
    },
    async selectRole(r) {
      this.activeRole = r
      try {
        const res = await getRolePermissions(r.id)
        const ids = res.data.permission_ids || []
        this.$nextTick(() => {
          this.$refs.menuTree?.setCheckedKeys(ids.filter(id => this.findInTree(this.menuTree, id)))
          this.$refs.btnTree?.setCheckedKeys(ids.filter(id => this.findInTree(this.btnTree, id)))
        })
      } catch (e) { /* */ }
    },
    findInTree(tree, id) { for (const n of tree) { if (n.id === id) return true; if (n.children && this.findInTree(n.children, id)) return true } return false },
    openForm(row) { this.formId = row?.id || null; this.form = row ? { ...row } : { name:'', code:'', description:'', status:1 }; this.formVisible = true },
    async handleSave() { this.saving = true; try { if (this.formId) await updateRole(this.formId, this.form); else await createRole(this.form); this.$message.success('保存成功'); this.formVisible = false; this.fetchRoles() } catch (e) { this.$message.error(e.message || '保存失败') } this.saving = false },
    async handleDelete(r) { await this.$confirm(`确认删除角色「${r.name}」？`,'提示',{type:'warning'}); try { await deleteRole(r.id); this.$message.success('已删除'); this.fetchRoles(); if (this.activeRole?.id === r.id) this.activeRole = null; this.selectedSet.delete(r.id) } catch (e) { /* */ } },
    toggleSelect(r) { if (this.selectedSet.has(r.id)) this.selectedSet.delete(r.id); else this.selectedSet.add(r.id); this.updateSelectState() },
    onCheckAll(v) { this.selectedSet = v ? new Set(this.roles.filter(x=>!x.is_system).map(x=>x.id)) : new Set(); this.updateSelectState() },
    updateSelectState() { const list = this.roles.filter(x=>!x.is_system); this.checkAll = this.selectedSet.size === list.length; this.isIndeterminate = this.selectedSet.size > 0 && !this.checkAll },
    async batchDelete() {
      const count = this.selectedRoles.length; if (!count) return
      try { await this.$confirm(`确认删除选中的 ${count} 个角色？`,'提示',{type:'warning'}); for (const r of this.selectedRoles) { await deleteRole(r.id) }; this.$message.success(`已删除 ${count} 个角色`); this.selectedSet.clear(); this.fetchRoles() } catch (e) { /* */ }
    },
    async savePerms() {
      this.permSaving = true
      // 收集勾选：权限节点(数字id)直接加入；菜单/目录节点(id=menu_xx)取其 permission 对应权限节点加入（勾选菜单=分配其菜单权限）
      const collect = (treeRef) => {
        if (!treeRef) return []
        const out = []
        ;(treeRef.getCheckedNodes() || []).forEach(n => {
          // 菜单/目录节点(id=menu_xx)直接提交：由后端持久化到菜单-角色授权，刷新后可完整回显
          if (typeof n.id === 'string' && n.id.indexOf('menu_') === 0) { out.push(n.id); return }
          if (typeof n.id === 'number' || /^\d+$/.test(String(n.id))) { out.push(Number(n.id)); return }
          if (n.code) { const pid = this.findPermIdByCode(n.code); if (pid) out.push(pid) }
        })
        return out
      }
      const allIds = [...new Set([...collect(this.$refs.menuTree), ...collect(this.$refs.btnTree)])]
      try { await saveRolePermissions(this.activeRole.id, allIds.join(',')); this.$message.success('权限保存成功') } catch (e) { /* */ }
      this.permSaving = false
    },
    findPermIdByCode(code) { const search = (nodes) => { for (const n of nodes || []) { if (n.is_menu === false && n.code === code) return n.id; if (n.children) { const r = search(n.children); if (r) return r } } return null }; return search(this.menuTree) || search(this.btnTree) },
    filterBtnTree(val) {
      if (!val) { this.filteredBtnTree = this.btnTree; return }
      // 按模块筛选
      const filterNodes = (nodes) => {
        const result = []
        for (const n of nodes) {
          if (n.module === val) { result.push(n); continue }
          if (n.children) {
            const filtered = filterNodes(n.children)
            if (filtered.length) result.push({ ...n, children: filtered })
          }
        }
        return result
      }
      this.filteredBtnTree = filterNodes(this.btnTree)
    },
    updateCounts() {
      // 统计全部已勾选节点（含菜单/目录与权限）
      this.menuCheckedCount = (this.$refs.menuTree?.getCheckedKeys() || []).length
      this.btnCheckedCount = (this.$refs.btnTree?.getCheckedKeys() || []).length
    },
    checkAll(type) {
      const tree = this.$refs[type === 'menu' ? 'menuTree' : 'btnTree']
      if (tree) {
        const all = this.flattenTree(tree.data)
        all.forEach(n => tree.setChecked(n, true))
      }
    },
    clearAll(type) {
      const tree = this.$refs[type === 'menu' ? 'menuTree' : 'btnTree']
      tree?.setCheckedKeys([])
    },
    flattenTree(nodes) {
      let result = []
      for (const n of nodes) {
        result.push(n)
        if (n.children) result = result.concat(this.flattenTree(n.children))
      }
      return result
    }
  }
}
</script>
<style scoped>
.role-page { padding:0; }
.role-card { padding:12px; border:1px solid #eee; border-radius:6px; margin-bottom:8px; cursor:pointer; transition:all .2s; }
.role-card:hover { border-color:#409eff; }
.role-card.active { border-color:#409eff; background:#ecf5ff; }
.role-name { font-size:14px; font-weight:bold; margin-bottom:4px; }
.role-code { font-size:12px; color:#999; }
.role-actions { margin-top:6px; }
.perm-node { flex:1; display:flex; align-items:center; font-size:13px; }
</style>
