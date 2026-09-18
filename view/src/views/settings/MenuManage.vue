<template>
  <div class="menu-page">
    <div class="page-header">
      <div><h2>菜单管理</h2><p class="subtitle">管理系统导航菜单结构 · 共 {{ flatCount }} 个菜单</p></div>
      <div style="display:flex;gap:8px">
        <el-button v-if="hasPerm('menu:clearCache')" size="small" icon="el-icon-refresh" @click="clearCache">刷新缓存</el-button>
        <el-button size="small" @click="toggleExpand">{{ expandAll?'折叠全部':'展开全部' }}</el-button>
      </div>
    </div>
    <div class="main-body">
      <!-- 左侧菜单树 -->
  <div class="left-panel">
    <el-input v-model="search" size="small" placeholder="搜索菜单名称或路径" prefix-icon="el-icon-search" clearable style="margin-bottom:8px" />
    <div class="tree-wrapper" :style="treeStyle">
          <el-tree ref="tree" :data="menuTree" :props="treeProps" :filter-node-method="filterNode" :default-expand-all="expandAll" node-key="id" highlight-current @node-click="selectMenu" :expand-on-click-node="true" draggable :allow-drag="allowDrag" @node-drag-end="handleDragEnd">
            <span slot-scope="{data}" class="tree-node">
              <i :class="data.icon || 'el-icon-menu'" style="margin-right:4px;color:#909399"></i>
              <span>{{ data.name }}</span>
              <el-tag v-if="data.children?.length" size="mini" type="info" style="margin-left:4px;cursor:default">{{ data.children.length }}项</el-tag>
              <el-tag v-if="data.status===0" size="mini" type="info" style="margin-left:4px;cursor:pointer" @click.stop="toggleStatus(data)">禁用</el-tag>
              <el-tag v-else size="mini" type="success" style="margin-left:4px;cursor:pointer" @click.stop="toggleStatus(data)">启用</el-tag>
              <span class="tree-actions">
                <el-button v-if="hasPerm('menu:update')" size="mini" type="text" @click.stop="editMenu(data)">编辑</el-button>
                <el-button v-if="!data.is_system && hasPerm('menu:delete')" size="mini" type="text" style="color:#F56C6C" @click.stop="confirmDel(data)">删除</el-button>
              </span>
            </span>
          </el-tree>
        </div>
        <div class="tree-footer">共 {{ flatCount }} 个菜单</div>
      </div>
      <!-- 右侧编辑区 -->
      <div class="right-panel" v-if="formVisible">
        <div class="right-header">
          <span>{{ formId?'编辑菜单':'新增菜单' }}</span>
          <el-button size="small" @click="formVisible=false" icon="el-icon-close">关闭</el-button>
        </div>
        <el-form :model="form" label-width="100px" size="small">
          <el-form-item label="上级菜单">
            <el-cascader v-model="form.parent_id" :options="menuOptions" :props="{label:'name',value:'id',children:'children',checkStrictly:true,emitPath:false}" clearable style="width:100%" />
          </el-form-item>
          <el-form-item label="菜单类型">
            <el-select v-model="form.type" style="width:100%" :disabled="isSystemEdit">
              <el-option v-for="t in dictMenuType" :key="t.value" :label="t.label" :value="t.value" />
            </el-select>
          </el-form-item>
          <el-form-item label="菜单名称"><el-input v-model="form.name" /></el-form-item>
          <el-form-item label="路由路径"><el-input v-model="form.path" placeholder="如 /users" /></el-form-item>
          <el-form-item label="菜单图标">
            <el-select v-model="form.icon" filterable clearable style="width:100%">
              <el-option v-for="icon in icons" :key="icon" :label="icon" :value="icon"><i :class="icon" style="margin-right:6px"/>{{ icon }}</el-option>
            </el-select>
          </el-form-item>
          <el-form-item label="权限标识">
            <el-select v-model="form.permission" filterable clearable style="width:100%">
              <el-option v-for="p in permOptions" :key="p.code" :label="`${p.name} (${p.code})`" :value="p.code" />
            </el-select>
          </el-form-item>
          <el-form-item label="排序"><el-input-number v-model="form.sort" :min="0" style="width:100%" /></el-form-item>
          <el-form-item label="状态"><el-switch v-model="form.status" :active-value="1" :inactive-value="0" /></el-form-item>
          <el-form-item label="系统内置" v-if="form.is_system">
            <el-switch v-model="form.is_system" :active-value="1" :inactive-value="0" disabled />
          </el-form-item>
          <el-form-item>
            <el-button type="primary" :loading="saving" @click="saveMenu">保存</el-button>
            <el-button @click="formVisible=false">取消</el-button>
          </el-form-item>
        </el-form>
      </div>
      <div class="right-panel right-empty" v-else>
        <i class="el-icon-menu"></i>
        <p>请从左侧选择要编辑的菜单，或点击节点上的「编辑」按钮</p>
        <el-button v-if="hasPerm('menu:create')" type="primary" @click="addNew" style="margin-top:12px">新增菜单</el-button>
      </div>
    </div>
  </div>
</template>

<script>
import { getMenuTree, getMenu, createMenu, updateMenu, deleteMenu, sortMenu, toggleMenuStatus, clearMenuCache } from '@/api/menus'
import { getDictByCode } from '@/api/dictionary'
import { getPermissionTree } from '@/api/role'
import { getThemeConfig } from '@/api/theme'

const ICONS = ['el-icon-s-home','el-icon-setting','el-icon-s-operation','el-icon-user','el-icon-s-custom','el-icon-lock',
  'el-icon-document-copy','el-icon-connection','el-icon-brush','el-icon-edit-outline','el-icon-notebook-2',
  'el-icon-menu','el-icon-data-line','el-icon-s-marketing','el-icon-data-analysis','el-icon-document',
  'el-icon-s-tools','el-icon-key','el-icon-s-grid','el-icon-s-promotion','el-icon-collection','el-icon-search',
  'el-icon-refresh','el-icon-full-screen','el-icon-bell','el-icon-s-fold','el-icon-s-unfold','el-icon-coin',
  'el-icon-shield','el-icon-warning','el-icon-info','el-icon-monitor','el-icon-data-board','el-icon-set-up']

function flattenTree(nodes) {
  let r = []
  for (const n of nodes) { r.push(n); if (n.children) r = r.concat(flattenTree(n.children)) }
  return r
}

export default {
  name:'MenuManage',
  data(){
    return{
      menuTree:[], search:'', expandAll:true,
      formVisible:false, formId:null, saving:false,
      form:{parent_id:0,name:'',path:'',icon:'',permission:'',sort:0,status:1,type:2,is_system:0},
      dictMenuType:[], permOptions:[], icons:ICONS, themeConfig:{},
    }
  },
  computed:{
    treeProps(){return{children:'children',label:'name'}},
    flatCount(){return flattenTree(this.menuTree).length},
    menuOptions(){return[{name:'顶级菜单',id:0,children:this.menuTree}]},
    isSystemEdit(){return this.formId && this.menuData?.is_system},
    menuData(){return this.formId ? this.findInTree(this.menuTree, this.formId) : null},
    treeStyle(){
      const t=this.themeConfig
      return{
        backgroundColor:t.menu_hover_bg_color||'transparent',
        color:t.sidebar_text_color||'#303133',
        fontSize:(t.menu_text_size==='small'?'13px':t.menu_text_size==='large'?'15px':'14px'),
      }
    },
  },
  watch:{search(v){this.$refs.tree?.filter(v)}},
  async created(){
    await Promise.all([
      this.fetchTree(),
      getDictByCode('menu_type').then(r=>{if(r.code===0)this.dictMenuType=r.data||[]}).catch(()=>{}),
      getPermissionTree(1).then(r=>{if(r.code===0)this.permOptions=flattenTree(r.data||[])}).catch(()=>{}),
      getThemeConfig().then(r=>{if(r.code===0)this.themeConfig=r.data||{}}).catch(()=>{}),
    ])
  },
  methods: {
    // 权限判断：按钮权限控制
    hasPerm(code) { const p = this.$store.state.user && this.$store.state.user.permissions ? this.$store.state.user.permissions : []; return p.indexOf(code) > -1 },
    async fetchTree(){try{const r=await getMenuTree();if(r.code===0)this.menuTree=r.data||[]}catch{};this.$nextTick(()=>this.expandAllTree(true))},
    expandAllTree(expand){const tree=this.$refs.tree;if(tree&&tree.store){try{tree.store._getAllNodes().forEach(n=>{n.expanded=expand})}catch{}}},
    toggleExpand(){this.expandAll=!this.expandAll;this.$nextTick(()=>this.expandAllTree(this.expandAll))},
    filterNode(v,data){if(!v)return true;return data.name.toLowerCase().includes(v.toLowerCase())||(data.path||'').toLowerCase().includes(v.toLowerCase())},
    findInTree(nodes,id){for(const n of nodes){if(n.id===id)return n;if(n.children){const f=this.findInTree(n.children,id);if(f)return f}}return null},
    async selectMenu(data){
      this.formId=data.id;this.form={...data}
      try{const r=await getMenu(data.id);if(r.code===0)this.form={...r.data,parent_id:r.data.parent_id||0};this.formVisible=true}catch{}
    },
    editMenu(data){this.formId=data.id;this.form={...data,parent_id:data.parent_id||0};this.formVisible=true},
    async saveMenu(){
      this.saving=true
      try{
        const data={...this.form}
        if(!data.parent_id)data.parent_id=0
        const r=data.id?await updateMenu(data.id,data):await createMenu(data)
        if(r.code===0){this.$message.success('成功');this.formVisible=false;this.fetchTree()}else this.$message.error(r.msg||'失败')
      }catch{}finally{this.saving=false}
    },
    async confirmDel(data){
      if(data.is_system)return this.$message.warning('系统内置菜单不可删除')
      try{
        await this.$confirm(`确定删除菜单「${data.name}」？`,'提示',{type:'warning'})
        const r=await deleteMenu(data.id)
        if(r.code===0){this.$message.success('已删除');this.formVisible=false;this.fetchTree()}else this.$message.error(r.msg||'失败')
      }catch{}
    },
    async clearCache(){try{await clearMenuCache();this.$message.success('缓存已清除');this.fetchTree()}catch{}},
    addNew(){this.formId=null;this.form={parent_id:0,name:'',path:'',icon:'',permission:'',sort:0,status:1,type:2,is_system:0};this.formVisible=true},
    async toggleStatus(data){
      try{const r=await toggleMenuStatus(data.id);if(r.code===0){data.status=r.data?.status?1:0;this.$message.success('状态已更新')}else this.$message.error(r.msg||'失败')}catch{}
    },
    allowDrag(){return true},
    async handleDragEnd(e){
      if(!e.draggedNode)return
      const node=e.draggedNode,dropNode=e.dropNode
      if(!node||!dropNode)return
      const newSort=dropNode.data.sort+(e.dropPosition===0?0:1)
      try{await sortMenu(node.data.id,newSort);this.$message.success('排序已更新');this.fetchTree()}catch{}
    },
  },
}
</script>

<style scoped>
.menu-page { padding:20px; height:100%; display:flex; flex-direction:column; background:#f0f2f5; }
.page-header { display:flex; justify-content:space-between; align-items:flex-start; margin-bottom:16px; }
.page-header h2 { margin:0; font-size:20px; font-weight:700; color:#303133; }
.subtitle { margin:4px 0 0; font-size:13px; color:#909399; }
.main-body { flex:1; display:flex; gap:16px; min-height:0; }
.left-panel { width:320px; flex-shrink:0; background:#fff; border-radius:8px; display:flex; flex-direction:column; padding:12px; box-shadow:0 1px 4px rgba(0,0,0,0.04); }
.tree-wrapper { flex:1; overflow:auto; }
.tree-node { flex:1; display:flex; align-items:center; font-size:13px; }
.tree-node .tree-actions { margin-left:auto; opacity:0; transition:opacity .2s; white-space:nowrap; }
.tree-node:hover .tree-actions { opacity:1; }
.tree-footer { padding:8px 0 0; font-size:12px; color:#909399; border-top:1px solid #EBEEF5; margin-top:8px; text-align:center; }
.right-panel { flex:1; background:#fff; border-radius:8px; padding:20px 24px; overflow:auto; box-shadow:0 1px 4px rgba(0,0,0,0.04); }
.right-empty { display:flex; flex-direction:column; align-items:center; justify-content:center; color:#C0C4CC; }
.right-empty i { font-size:48px; margin-bottom:12px; }
.right-header { display:flex; justify-content:space-between; align-items:center; margin-bottom:16px; font-size:16px; font-weight:600; color:#303133; }
</style>
