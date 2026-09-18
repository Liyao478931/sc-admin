<template>
  <div class="org-page">
    <div class="page-header">
      <div><h2>组织架构</h2><p class="subtitle">管理部门和岗位结构 · 共 {{ deptCount }} 个部门</p></div>
      <div style="display:flex;gap:8px">
        <el-button size="small" @click="expandAll=!expandAll">{{ expandAll?'折叠全部':'展开全部' }}</el-button>
        <el-button v-if="hasPerm('organization:createDepartment')" size="small" type="primary" @click="openDeptForm()">新增部门</el-button>
      </div>
    </div>
    <div class="main-body">
      <!-- 左侧部门树 -->
      <div class="left-panel">
        <el-input v-model="search" size="small" placeholder="搜索部门名称" prefix-icon="el-icon-search" clearable style="margin-bottom:8px" />
        <div class="tree-wrapper">
          <el-tree ref="tree" :data="deptTree" :props="deptProps" :filter-node-method="filterNode" :default-expand-all="expandAll" node-key="id" highlight-current @node-click="selectDept" draggable :allow-drag="()=>true" @node-drag-end="handleDragEnd">
            <span slot-scope="{data}" class="tree-node">
              <i class="el-icon-share" style="margin-right:4px;color:#909399"></i>
              <span>{{ data.name }}</span>
              <span class="tree-code">{{ data.code }}</span>
              <span class="tree-count">{{ data.user_count||0 }}人</span>
              <span class="tree-actions">
                <el-button v-if="hasPerm('organization:createDepartment')" size="mini" type="text" @click.stop="openDeptForm(null, data.id)">+子</el-button>
                <el-button v-if="hasPerm('organization:updateDepartment')" size="mini" type="text" @click.stop="openDeptForm(data)">编辑</el-button>
                <el-button v-if="hasPerm('organization:deleteDepartment')" size="mini" type="text" style="color:#F56C6C" @click.stop="confirmDelDept(data)">删除</el-button>
              </span>
            </span>
          </el-tree>
        </div>
        <div class="tree-footer">共 {{ deptCount }} 个部门</div>
      </div>
      <!-- 右侧详情 -->
      <div class="right-panel" v-if="activeDept">
        <div class="detail-section">
          <div class="detail-header">
            <h3>{{ activeDept.name }}</h3>
            <span class="detail-code">{{ activeDept.code }}</span>
            <div style="margin-left:auto;display:flex;gap:8px">
              <el-button v-if="hasPerm('organization:updateDepartment')" size="small" @click="editActiveDept">编辑部门</el-button>
              <el-button v-if="hasPerm('organization:createPosition')" size="small" type="primary" @click="openPosForm()">新增岗位</el-button>
            </div>
          </div>
          <div class="detail-grid">
            <div><label>部门编码</label><span>{{ activeDept.code }}</span></div>
            <div><label>负责人</label><span>{{ activeDept.leader?.real_name||activeDept.leader?.username||'-' }}</span></div>
            <div><label>人员数量</label><span>{{ activeDept.user_count||0 }} 人</span></div>
            <div><label>子部门</label><span>{{ activeDept.child_count||0 }} 个</span></div>
            <div><label>创建时间</label><span>{{ activeDept.created_at }}</span></div>
            <div><label>更新时间</label><span>{{ activeDept.updated_at }}</span></div>
          </div>
        </div>
        <!-- 部门成员 -->
        <div class="detail-section">
          <h4>部门成员 ({{ filteredMembers.length }})</h4>
          <el-input v-model="memberSearch" size="mini" placeholder="搜索姓名/手机号" prefix-icon="el-icon-search" clearable style="width:260px;margin-bottom:8px" />
          <el-table v-if="filteredMembers.length" :data="filteredMembers" size="small" border stripe style="width:100%">
            <el-table-column type="index" label="#" width="50" />
            <el-table-column prop="real_name" label="姓名" min-width="100" />
            <el-table-column prop="phone" label="手机号" width="130" />
            <el-table-column prop="status" label="状态" width="70">
              <template slot-scope="{row}"><el-tag :type="row.status?'success':'info'" size="mini">{{ row.status?'启用':'禁用' }}</el-tag></template>
            </el-table-column>
          </el-table>
          <span v-else style="color:#C0C4CC;font-size:13px">暂无成员</span>
        </div>
        <!-- 岗位列表 -->
        <div class="detail-section">
          <h4>岗位列表 ({{ positions.length }})</h4>
          <el-table :data="positions" size="small" border stripe style="width:100%">
            <el-table-column type="index" label="#" width="50" />
            <el-table-column prop="name" label="岗位名称" min-width="140" />
            <el-table-column prop="code" label="编码" width="120" />
            <el-table-column label="关联用户" width="90">
              <template slot-scope="{row}"><span style="color:#909399">{{ row.user_count||0 }}人</span></template>
            </el-table-column>
            <el-table-column prop="status" label="状态" width="80">
              <template slot-scope="{row}"><el-tag :type="row.status?'success':'info'" size="mini">{{ row.status?'启用':'禁用' }}</el-tag></template>
            </el-table-column>
            <el-table-column prop="description" label="描述" min-width="120" />
            <el-table-column label="操作" width="120">
              <template slot-scope="{row}">
                <el-button v-if="hasPerm('organization:updatePosition')" size="mini" type="text" @click="openPosForm(row)">编辑</el-button>
                <el-button v-if="hasPerm('organization:deletePosition')" size="mini" type="text" style="color:#F56C6C" @click="confirmDelPos(row)">删除</el-button>
              </template>
            </el-table-column>
          </el-table>
        </div>
      </div>
      <div class="right-panel right-empty" v-else>
        <i class="el-icon-share"></i><p>请从左侧选择部门</p>
      </div>
    </div>
    <!-- 部门表单弹窗 -->
    <el-dialog :title="deptDialogTitle" :visible.sync="showDeptForm" width="520px">
      <el-form label-width="100px" size="small">
        <el-form-item label="部门名称"><el-input v-model="deptForm.name" /></el-form-item>
        <el-form-item label="部门编码"><el-input v-model="deptForm.code" :disabled="!!deptForm.id" /></el-form-item>
        <el-form-item label="上级部门">
          <el-cascader v-model="deptForm.parent_id" :options="deptOptions" :props="{label:'name',value:'id',children:'children',checkStrictly:true,emitPath:false}" :disabled="!!deptForm.id" clearable style="width:100%" />
        </el-form-item>
        <el-form-item label="负责人">
          <el-select v-model="deptForm.leader_id" filterable clearable style="width:100%">
            <el-option v-for="u in userOptions" :key="u.id" :label="u.real_name||u.username" :value="u.id" />
          </el-select>
        </el-form-item>
        <el-form-item label="排序"><el-input-number v-model="deptForm.sort" :min="0" style="width:100%" /></el-form-item>
        <el-form-item label="状态"><el-switch v-model="deptForm.status" :active-value="1" :inactive-value="0" /></el-form-item>
        <el-form-item label="描述"><el-input v-model="deptForm.description" type="textarea" :rows="2" /></el-form-item>
      </el-form>
      <span slot="footer"><el-button @click="showDeptForm=false">取消</el-button><el-button type="primary" :loading="saving" @click="saveDept">保存</el-button></span>
    </el-dialog>
    <!-- 岗位表单弹窗 -->
    <el-dialog :title="posForm.id?'编辑岗位':'新增岗位'" :visible.sync="showPosForm" width="450px">
      <el-form label-width="100px" size="small">
        <el-form-item label="岗位名称"><el-input v-model="posForm.name" /></el-form-item>
        <el-form-item label="岗位编码"><el-input v-model="posForm.code" :disabled="!!posForm.id" /></el-form-item>
        <el-form-item label="所属部门"><el-input :value="activeDept?.name" disabled /></el-form-item>
        <el-form-item label="排序"><el-input-number v-model="posForm.sort" :min="0" style="width:100%" /></el-form-item>
        <el-form-item label="状态"><el-switch v-model="posForm.status" :active-value="1" :inactive-value="0" /></el-form-item>
        <el-form-item label="描述"><el-input v-model="posForm.description" type="textarea" :rows="2" /></el-form-item>
      </el-form>
      <span slot="footer"><el-button @click="showPosForm=false">取消</el-button><el-button type="primary" :loading="saving" @click="savePos">保存</el-button></span>
    </el-dialog>
  </div>
</template>

<script>
import { getDeptTree, getDept, createDept, updateDept, deleteDept, sortDept, getDeptMembers, getPositions, createPosition, updatePosition, deletePosition } from '@/api/organization'
import { getSettingValue } from '@/api/settings'
import { getUserOptions } from '@/api/user'
import { getDictByCode } from '@/api/dictionary'

function flattenTree(nodes) {
  let r = []
  for (const n of nodes) { r.push(n); if (n.children) r = r.concat(flattenTree(n.children)) }
  return r
}

export default {
  name:'Organization',
  data(){
    return{
      deptTree:[], search:'', expandAll:true, activeDept:null, members:[], positions:[],
      showDeptForm:false, deptForm:{id:null,name:'',code:'',parent_id:0,leader_id:null,sort:0,status:1,description:''},
      showPosForm:false, posForm:{name:'',code:'',department_id:0,sort:0,status:1,description:''},
      saving:false, userOptions:[], codeAutoGen:false, orgStatus:[], memberSearch:'',
    }
  },
  computed:{
    deptProps(){return{children:'children',label:'name'}},
    deptCount(){return flattenTree(this.deptTree).length},
    deptOptions(){return[{name:'顶级部门',id:0,children:this.deptTree}]},
    filteredMembers(){
      if(!this.memberSearch)return this.members
      const kw=this.memberSearch.toLowerCase()
      return this.members.filter(m=>(m.real_name||'').toLowerCase().includes(kw)||(m.phone||'').includes(kw))
    },
    deptDialogTitle(){
      const hasId = this.deptForm.id !== null && this.deptForm.id !== undefined
      if(hasId) return '编辑部门 — '+this.deptForm.name
      if(this.deptForm.parent_id) return '新增子部门'
      return '新增部门'
    },
  },
  watch:{search(v){this.$refs.tree?.filter(v)}},
  async created(){
    await Promise.all([
      this.fetchTree(),
      getUserOptions().then(r=>{if(r.code===0)this.userOptions=(r.data||[]).map(o=>({id:o.value,real_name:o.label,username:o.label}))}).catch(()=>{}),
      getDictByCode('org_status').then(r=>{if(r.code===0)this.orgStatus=r.data||[]}).catch(()=>{}),
      getSettingValue('org_code_auto_generate').then(r=>{this.codeAutoGen=r.data?.value==='1'}).catch(()=>{}),
    ])
  },
  methods: {
    // 权限判断：按钮权限控制
    hasPerm(code) { const p = this.$store.state.user && this.$store.state.user.permissions ? this.$store.state.user.permissions : []; return p.indexOf(code) > -1 },
    async fetchTree(){try{const r=await getDeptTree();if(r.code===0)this.deptTree=r.data||[]}catch{}},
    filterNode(v,data){if(!v)return true;return data.name.toLowerCase().includes(v.toLowerCase())},
    async selectDept(data){
      this.activeDept=data
      try{
        const[r,m,p]=await Promise.all([getDept(data.id),getDeptMembers(data.id),getPositions(data.id)])
        if(r.code===0)this.activeDept=r.data
        if(m.code===0)this.members=m.data||[]
        if(p.code===0)this.positions=p.data||[]
      }catch{}
    },
    openDeptForm(row, parentId){
      // 先关闭再打开，确保 dialog 重新渲染（Vue 2 el-dialog 内容复用问题）
      this.showDeptForm=false
      this.$nextTick(()=>{
        if(row){
          // 编辑模式 - 显式逐字段赋值确保 Vue 2 响应式
          this.deptForm.id = row.id
          this.deptForm.name = row.name
          this.deptForm.code = row.code
          this.deptForm.parent_id = row.parent_id || 0
          this.deptForm.leader_id = row.leader_id || null
          this.deptForm.sort = row.sort || 0
          this.deptForm.status = row.status ?? 1
          this.deptForm.description = row.description || ''
        } else {
          // 新增模式
          const pid = parentId || this.activeDept?.id || 0
          this.deptForm.id = null
          this.deptForm.name = ''
          this.deptForm.code = ''
          this.deptForm.parent_id = pid
          this.deptForm.leader_id = null
          this.deptForm.sort = 0
          this.deptForm.status = 1
          this.deptForm.description = ''
          if(this.codeAutoGen) this.deptForm.code = 'DEPT-'+String(Date.now()).slice(-6)
        }
        this.showDeptForm=true
      })
    },
    async handleDragEnd(e){
      if(!e.draggedNode||!e.dropNode)return
      const newSort=e.dropNode.data.sort+(e.dropPosition===0?0:1)
      try{await sortDept(e.draggedNode.data.id,newSort);this.$message.success('排序已更新');this.fetchTree()}catch{}
    },
    async saveDept(){
      this.saving=true
      try{
        const data={...this.deptForm};if(!data.parent_id)data.parent_id=0
        const r=data.id?await updateDept(data.id,data):await createDept(data)
        if(r.code===0){this.$message.success('成功');this.showDeptForm=false;this.fetchTree()}else this.$message.error(r.msg||'失败')
      }catch{}finally{this.saving=false}
    },
    async confirmDelDept(data){
      try{await this.$confirm(`确定删除部门「${data.name}」？`,'提示',{type:'warning'});const r=await deleteDept(data.id);if(r.code===0){this.$message.success('已删除');if(this.activeDept?.id===data.id)this.activeDept=null;this.fetchTree()}else this.$message.error(r.msg||'失败')}catch{}
    },
    editActiveDept(){
      // 从部门树中取最新数据，避免 activeDept 数据不完整
      const all = flattenTree(this.deptTree)
      const found = all.find(d => d.id === this.activeDept?.id)
      if(found){ this.openDeptForm(found) }
      else if(this.activeDept){ this.openDeptForm(this.activeDept) }
    },
    openPosForm(row){
      this.posForm=row?{...row}:{name:'',code:'',department_id:this.activeDept?.id||0,sort:0,description:''}
      this.showPosForm=true
    },
    async savePos(){
      this.saving=true
      try{
        const data={...this.posForm}
        const r=data.id?await updatePosition(data.id,data):await createPosition(data)
        if(r.code===0){this.$message.success('成功');this.showPosForm=false;this.loadPositions()}else this.$message.error(r.msg||'失败')
      }catch{}finally{this.saving=false}
    },
    async confirmDelPos(data){
      try{await this.$confirm(`确定删除岗位「${data.name}」？`,'提示',{type:'warning'});const r=await deletePosition(data.id);if(r.code===0){this.$message.success('已删除');this.loadPositions()}else this.$message.error(r.msg||'失败')}catch{}
    },
    async loadPositions(){if(this.activeDept){const r=await getPositions(this.activeDept.id);if(r.code===0)this.positions=r.data||[]}},
  },
}
</script>

<style scoped>
.org-page { padding:20px; height:100%; display:flex; flex-direction:column; background:#f0f2f5; }
.page-header { display:flex; justify-content:space-between; align-items:flex-start; margin-bottom:16px; }
.page-header h2 { margin:0; font-size:20px; font-weight:700; color:#303133; }
.subtitle { margin:4px 0 0; font-size:13px; color:#909399; }
.main-body { flex:1; display:flex; gap:16px; min-height:0; }
.left-panel { width:320px; flex-shrink:0; background:#f5f7fa; border-radius:8px; display:flex; flex-direction:column; padding:12px; border:1px solid #EBEEF5; }
.tree-wrapper { flex:1; overflow:auto; }
.tree-node { flex:1; display:flex; align-items:center; font-size:13px; }
.tree-code { font-size:12px; color:#909399; margin-left:6px; }
.tree-count { margin-left:auto; font-size:12px; color:#C0C4CC; margin-right:8px; }
.tree-actions { opacity:0; transition:opacity .2s; white-space:nowrap; }
.tree-node:hover .tree-actions { opacity:1; }
.tree-footer { padding:8px 0 0; font-size:12px; color:#909399; border-top:1px solid #EBEEF5; margin-top:8px; text-align:center; }
.right-panel { flex:1; background:#fff; border-radius:8px; padding:20px 24px; overflow:auto; border:1px solid #EBEEF5; }
.right-empty { display:flex; flex-direction:column; align-items:center; justify-content:center; color:#C0C4CC; }
.detail-section { margin-bottom:20px; }
.detail-header { display:flex; align-items:center; gap:12px; margin-bottom:12px; flex-wrap:wrap; }
.detail-header h3 { margin:0; font-size:18px; font-weight:600; }
.detail-code { font-size:13px; color:#909399; }
.detail-grid { display:grid; grid-template-columns:1fr 1fr; gap:6px 24px; }
.detail-grid div { display:flex; padding:4px 0; font-size:13px; }
.detail-grid label { color:#909399; min-width:80px; flex-shrink:0; }
.detail-section h4 { font-size:15px; font-weight:600; margin:0 0 8px; padding-bottom:6px; border-bottom:1px solid #f0f2f5; }
</style>
