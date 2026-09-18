<template>
  <div class="perm-page">
    <el-row :gutter="16">
      <el-col :span="10">
        <el-card shadow="never">
          <div slot="header">
            <span>权限树</span>
            <div style="float:right;">
              <el-button size="mini" @click="expandAll">展开</el-button>
              <el-button size="mini" @click="collapseAll">折叠</el-button>
              <el-button v-if="hasPerm('permission:store')" size="mini" type="primary" @click="openForm()">新增根权限</el-button>
              <el-button v-if="hasPerm('permission:sync')" size="mini" @click="handleSync">权限同步</el-button>
            </div>
          </div>
          <el-input v-model="search" placeholder="搜索权限" size="small" style="margin-bottom:12px;" />
          <el-tree ref="tree" :data="tree" :props="{label:'display_name',children:'children',isLeaf:'is_leaf'}" :filter-node-method="(v,n)=>n.display_name?.includes(v)||n.code?.includes(v)" node-key="id" highlight-current @node-click="(n)=>selected=n" :expand-on-click-node="false">
            <span slot-scope="{data}" class="perm-node">
              <i :class="data.type_icon||'el-icon-document'" style="margin-right:4px;color:#909399;" />
              <span>{{ data.display_name || data.name }}</span>
              <el-tag v-if="data.type_label" size="mini" :type="data.type===1?'':data.type===2?'warning':'info'" style="margin-left:6px;">{{ data.type_label }}</el-tag>
            </span>
          </el-tree>
        </el-card>
      </el-col>
      <el-col :span="14">
        <el-card v-if="selected" shadow="never">
          <div slot="header">
            <span>{{ selected.display_name || selected.name }} <el-tag size="mini">{{ selected.is_menu ? (selected.type === 1 ? '目录' : '菜单') : ({1:'菜单',2:'按钮',3:'接口'}[selected.type]) }}</el-tag></span>
            <div style="float:right;">
              <el-button v-if="!selected.is_menu && hasPerm('permission:store')" size="mini" @click="openForm(selected)">新增子节点</el-button>
              <el-button v-if="!selected.is_menu && hasPerm('permission:update')" size="mini" type="primary" @click="editMode=true">编辑</el-button>
              <el-button v-if="!selected.is_menu && hasPerm('permission:destroy')" size="mini" style="color:#f56c6c;" @click="handleDelete">删除</el-button>
            </div>
          </div>
          <el-form v-if="!selected.is_menu" :model="selected" label-width="100px" size="small">
            <el-form-item label="权限名称"><el-input v-model="selected.name" :disabled="!editMode" /></el-form-item>
            <el-form-item label="权限编码"><el-input v-model="selected.code" :disabled="!editMode" /></el-form-item>
            <el-form-item label="权限类型"><span>{{ {1:'菜单',2:'按钮',3:'接口'}[selected.type] }}</span></el-form-item>
            <el-form-item label="路由路径"><el-input v-model="selected.path" :disabled="!editMode" /></el-form-item>
            <el-form-item label="图标"><el-input v-model="selected.icon" :disabled="!editMode" /></el-form-item>
            <el-form-item label="排序"><el-input-number v-model="selected.sort" :disabled="!editMode" /></el-form-item>
            <el-form-item v-if="editMode"><el-button type="primary" size="small" @click="handleUpdate">保存</el-button><el-button size="small" @click="editMode=false">取消</el-button></el-form-item>
          </el-form>
          <el-descriptions v-else :column="1" border size="small" style="margin-top:4px;">
            <el-descriptions-item label="菜单名称">{{ selected.display_name }}</el-descriptions-item>
            <el-descriptions-item label="权限标识">{{ selected.code || '-' }}</el-descriptions-item>
            <el-descriptions-item label="路由路径">{{ selected.path || '-' }}</el-descriptions-item>
            <el-descriptions-item label="类型">{{ selected.type === 1 ? '目录' : '菜单' }}</el-descriptions-item>
          </el-descriptions>
        </el-card>
        <el-card v-else shadow="never"><el-empty description="请选择一个权限节点" /></el-card>
      </el-col>
    </el-row>

    <el-dialog :title="formTitle" :visible.sync="formVisible" width="520px">
      <el-form :model="form" label-width="100px" size="small">
        <el-form-item label="权限名称"><el-input v-model="form.name" /></el-form-item>
        <el-form-item label="权限编码"><el-input v-model="form.code" /></el-form-item>
        <el-form-item label="权限类型"><el-select v-model="form.type"><el-option v-for="t in dictPermType" :key="t.value" :label="t.label" :value="t.value" /></el-select></el-form-item>
        <el-form-item label="父级"><el-cascader v-model="form.parent_id" :options="permTree" :props="{label:'name',value:'id',children:'children',expandTrigger:'hover',checkStrictly:true}" clearable style="width:100%;" /></el-form-item>
        <el-form-item label="路由路径"><el-input v-model="form.path" /></el-form-item>
        <el-form-item label="图标"><el-input v-model="form.icon" /></el-form-item>
        <el-form-item label="排序"><el-input-number v-model="form.sort" :min="0" /></el-form-item>
      </el-form>
      <span slot="footer"><el-button @click="formVisible=false">取消</el-button><el-button type="primary" :loading="saving" @click="handleSave">保存</el-button></span>
    </el-dialog>
  </div>
</template>

<script>
import { getPermissionTree, createPermission, updatePermission, deletePermission, syncPermissions, sortPermission } from '@/api/role'
import { getDictByCode } from '@/api/dictionary'

export default {
  name: 'PermissionIndex',
  data() {
    return {
      tree: [], search: '', selected: null, editMode: false, fullTree: [], permTree: [],
      formVisible: false, formTitle: '', saving: false,
      form: { name:'', code:'', type:1, parent_id:null, path:'', icon:'', sort:0 },
      dictPermType: []
    }
  },
  watch: { search(v) { this.$refs.tree?.filter(v) } },
  created() { this.fetchTree(); getDictByCode('permission_type').then(r=>{if(r.code===0)this.dictPermType=r.data||[]}).catch(()=>{}) },
  methods: {
    // 权限判断：按钮权限控制
    hasPerm(code) { const p = this.$store.state.user && this.$store.state.user.permissions ? this.$store.state.user.permissions : []; return p.indexOf(code) > -1 },
    // 懒加载子节点：从已缓存的完整树数据中按 parent_id 查找子节点
    loadChildren(node, resolve) {
      if (!node || !node.data) { resolve([]); return }
      const pid = node.data.id
      const children = (this.fullTree || []).filter(n => n.parent_id === pid)
      // 标记叶子：无子节点则不再加载
      children.forEach(c => { c.is_leaf = !((this.fullTree || []).some(x => x.parent_id === c.id)) })
      resolve(children)
    },
    async fetchTree() {
      try {
        const r = await getPermissionTree(); this.tree = r.data || []
        // 保留完整扁平列表（供父级级联选择等使用）
        this.fullTree = []
        const flatten = (nodes) => { nodes.forEach(n => { this.fullTree.push(n); if (n.children) flatten(n.children) }) }
        flatten(this.tree)
        // 权限节点树（供父级级联选择）：仅权限节点，按 parent_id 组织
        const permNodes = this.fullTree.filter(n => !n.is_menu)
        const byParent = {}
        permNodes.forEach(n => { const pid = n.parent_id || 0; (byParent[pid] = byParent[pid] || []).push(n) })
        const buildPerm = (pid) => (byParent[pid] || []).map(n => ({ ...n, children: buildPerm(n.id) }))
        this.permTree = buildPerm(0)
        // 非懒加载模式：保留完整 children，default-expand-all 默认全部展开
      } catch (e) { /* */ }
    },
    // 展开第一级节点（level<=1），子节点保持收起
    expandFirstLevel() {
      const tree = this.$refs.tree
      if (!tree) return
      const allNodes = (tree.store && tree.store._getAllNodes) ? tree.store._getAllNodes() : []
      allNodes.forEach(node => { if (node) node.expanded = (node.level <= 1) })
    },
    // Element UI el-tree 展开全部：遍历所有节点设置 expanded=true
    setAllExpanded(expanded) {
      const tree = this.$refs.tree
      if (!tree) return
      const allNodes = (tree.store && tree.store._getAllNodes) ? tree.store._getAllNodes() : []
      allNodes.forEach(node => { if (node) node.expanded = expanded })
    },
    expandAll() { this.setAllExpanded(true) },
    collapseAll() { this.setAllExpanded(false) },
    openForm(parent) {
      this.formTitle = parent?.id ? `新增「${parent.name}」的子节点` : '新增根权限'
      this.form = { name:'', code:'', type:1, parent_id:parent?.id || null, path:'', icon:'', sort:0 }
      this.formVisible = true
    },
    async handleSave() { this.saving = true; try { await createPermission(this.form); this.$message.success('创建成功'); this.formVisible = false; this.fetchTree() } catch (e) { /* */ } this.saving = false },
    async handleUpdate() {
      try { await updatePermission(this.selected.id, { name:this.selected.name, code:this.selected.code, path:this.selected.path, icon:this.selected.icon, sort:this.selected.sort }); this.$message.success('更新成功'); this.editMode = false; this.fetchTree() } catch (e) { /* */ }
    },
    async handleDelete() {
      await this.$confirm(`确认删除「${this.selected.name}」？`,'提示',{type:'warning'})
      try { await deletePermission(this.selected.id); this.$message.success('已删除'); this.selected = null; this.fetchTree() } catch (e) { /* */ }
    },
    async handleSync() {
      try { const r = await syncPermissions(); this.$message.success(r.msg); this.fetchTree() } catch (e) { /* */ }
    }
  }
}
</script>
<style scoped>
.perm-page { padding:0; }
.perm-node { flex:1; display:flex; align-items:center; font-size:13px; }
</style>
