<template>
  <div class="dictionary-page">
    <div class="page-header">
      <h2>数据字典</h2>
      <div><el-button v-if="hasPerm('dictionary:export')" size="small" icon="el-icon-download" @click="handleExport">导出</el-button>
      <el-button v-if="hasPerm('dictionary:import')" size="small" icon="el-icon-upload2" @click="showImport=true">导入</el-button></div>
    </div>
    <div class="main-body">
      <!-- 左侧：字典类型列表 -->
      <div class="left-panel">
        <div class="left-header">
          <span style="font-weight:600">字典类型</span>
          <el-button v-if="hasPerm('dictionary:createType')" size="small" type="primary" icon="el-icon-plus" @click="openTypeForm()">新增类型</el-button>
        </div>
        <el-input v-model="typeSearch" size="small" placeholder="搜索类型名称或编码" prefix-icon="el-icon-search" clearable style="margin:8px 12px;width:auto" />
        <div class="type-list">
          <div v-for="t in filteredTypes" :key="t.id" class="type-item" :class="{active:activeType?.id===t.id}" @click="selectType(t)">
            <div class="type-info"><div class="type-name">{{ t.name }}</div><div class="type-code">{{ t.code }}</div></div>
            <div class="type-meta">
              <span class="entry-count">{{ t.entries_count||0 }}项</span>
              <el-button v-if="hasPerm('dictionary:updateType')" size="mini" icon="el-icon-edit" type="text" @click.stop="openTypeForm(t)" />
              <el-button v-if="hasPerm('dictionary:deleteType')" size="mini" icon="el-icon-delete" type="text" @click.stop="confirmDelType(t)" />
            </div>
          </div>
          <div v-if="types.length===0" style="text-align:center;padding:20px;color:#C0C4CC;font-size:13px">暂无字典类型</div>
        </div>
        <div class="left-footer">共 {{ types.length }} 个字典类型</div>
      </div>
      <!-- 右侧：字典条目列表 -->
      <div class="right-panel" v-if="activeType">
        <div class="right-header">
          <div><span class="right-title">{{ activeType.name }}</span><span class="right-code">{{ activeType.code }}</span></div>
          <div style="display:flex;gap:8px">
            <el-input v-model="entrySearch" size="small" placeholder="搜索标签或值" prefix-icon="el-icon-search" clearable style="width:200px" />
            <el-button v-if="hasPerm('dictionary:createEntry')" size="small" type="primary" icon="el-icon-plus" @click="openEntryForm()">新增条目</el-button>
          </div>
        </div>
        <el-table :data="entries" size="small" border stripe style="width:100%" :row-style="{height:'44px'}">
          <el-table-column type="index" label="#" width="60" />
          <el-table-column prop="label" label="字典标签" width="200">
            <template slot-scope="{row}"><el-tag v-if="row.style" :type="row.style" size="small" effect="plain">{{ row.label }}</el-tag><span v-else>{{ row.label }}</span></template>
          </el-table-column>
          <el-table-column prop="value" label="字典值" width="120" />
          <el-table-column prop="sort" label="排序" width="80" />
          <el-table-column prop="style" label="样式" width="100">
            <template slot-scope="{row}"><el-tag v-if="row.style" :type="row.style" size="mini">{{ row.style }}</el-tag><span v-else style="color:#C0C4CC">-</span></template>
          </el-table-column>
          <el-table-column prop="extra" label="扩展数据" width="120">
            <template slot-scope="{row}"><span style="font-size:12px;color:#909399">{{ row.extra?JSON.stringify(row.extra).substring(0,20)+'...':'-' }}</span></template>
          </el-table-column>
          <el-table-column prop="status" label="状态" width="80">
            <template slot-scope="{row}"><el-switch :value="!!row.status" @change="v=>toggleEntryStatus(row,v)" /></template>
          </el-table-column>
          <el-table-column prop="remark" label="备注" width="150">
            <template slot-scope="{row}"><span style="font-size:12px;color:#909399">{{ row.remark||'-' }}</span></template>
          </el-table-column>
          <el-table-column label="操作" width="150" fixed="right">
            <template slot-scope="{row}">
              <el-button v-if="hasPerm('dictionary:updateEntry')" size="mini" type="text" icon="el-icon-edit" @click="openEntryForm(row)">编辑</el-button>
              <el-button v-if="hasPerm('dictionary:deleteEntry')" size="mini" type="text" icon="el-icon-delete" style="color:#F56C6C" @click="confirmDelEntry(row)">删除</el-button>
            </template>
          </el-table-column>
        </el-table>
      </div>
      <div class="right-panel right-empty" v-else><i class="el-icon-notebook-2"></i><p>请从左侧选择一个字典类型</p></div>
    </div>
    <!-- 类型表单弹窗 -->
    <el-dialog :title="typeForm.id?'编辑字典类型':'新增字典类型'" :visible.sync="showTypeForm" width="500px" :close-on-click-modal="false">
      <el-form label-width="100px" size="small">
        <el-form-item label="类型名称"><el-input v-model="typeForm.name" placeholder="如：用户类型" maxlength="50" /></el-form-item>
        <el-form-item label="类型编码"><el-input v-model="typeForm.code" placeholder="如：user_type（英文小写下划线）" maxlength="50" :disabled="!!typeForm.id" /></el-form-item>
        <el-form-item label="类型描述"><el-input v-model="typeForm.description" placeholder="选填" maxlength="255" /></el-form-item>
        <el-form-item label="排序"><el-input-number v-model="typeForm.sort" :min="0" style="width:100%" /></el-form-item>
        <el-form-item label="状态"><el-switch v-model="typeForm.status" :active-value="1" :inactive-value="0" /></el-form-item>
      </el-form>
      <span slot="footer"><el-button @click="showTypeForm=false" size="small">取消</el-button>
        <el-button type="primary" :loading="savingType" @click="saveType" size="small">保存</el-button></span>
    </el-dialog>
    <!-- 条目表单弹窗 -->
    <el-dialog :title="entryForm.id?'编辑字典条目':'新增字典条目'" :visible.sync="showEntryForm" width="550px" :close-on-click-modal="false">
      <el-form label-width="100px" size="small">
        <el-form-item label="字典标签"><el-input v-model="entryForm.label" placeholder="显示名称" maxlength="100" /></el-form-item>
        <el-form-item label="字典值"><el-input v-model="entryForm.value" placeholder="存储值" maxlength="50" /></el-form-item>
        <el-form-item label="排序"><el-input-number v-model="entryForm.sort" :min="0" style="width:100%" /></el-form-item>
        <el-form-item label="样式">
          <el-select v-model="entryForm.style" style="width:100%" clearable>
            <el-option label="默认" value="" /><el-option label="primary" value="primary" /><el-option label="success" value="success" />
            <el-option label="warning" value="warning" /><el-option label="danger" value="danger" /><el-option label="info" value="info" />
          </el-select>
        </el-form-item>
        <el-form-item label="扩展数据"><el-input v-model="entryForm.extra" placeholder='JSON格式，如{"color":"#409EFF"}' maxlength="500" /></el-form-item>
        <el-form-item label="状态"><el-switch v-model="entryForm.status" :active-value="1" :inactive-value="0" /></el-form-item>
        <el-form-item label="备注"><el-input v-model="entryForm.remark" type="textarea" :rows="2" maxlength="255" /></el-form-item>
      </el-form>
      <span slot="footer"><el-button @click="showEntryForm=false" size="small">取消</el-button>
        <el-button type="primary" :loading="savingEntry" @click="saveEntry" size="small">保存</el-button></span>
    </el-dialog>
    <!-- 导入弹窗 -->
    <el-dialog title="导入字典数据" :visible.sync="showImport" width="500px">
      <el-upload drag :action="uploadUrl" :headers="uploadHeaders" :show-file-list="false" accept=".json" :on-success="onImportSuccess" :on-error="()=>$message.error('上传失败')">
        <i class="el-icon-upload"></i><div>将 JSON 文件拖到此处，或<em>点击选择</em></div>
      </el-upload>
      <span slot="footer"><el-button @click="showImport=false" size="small">关闭</el-button></span>
    </el-dialog>
  </div>
</template>

<script>
import { getTypes, createType, updateType, deleteType, getEntries, createEntry, updateEntry, deleteEntry, exportDict } from '@/api/dictionary'

export default {
  name:'DictionaryManager',
  data(){
    return{
      types:[], activeType:null, entries:[], typeSearch:'', entrySearch:'',
      showTypeForm:false, savingType:false, typeForm:{name:'',code:'',description:'',sort:0,status:1},
      showEntryForm:false, savingEntry:false, entryForm:{type_id:0,label:'',value:'',sort:0,style:'',extra:'',status:1,remark:''},
      showImport:false,
    }
  },
  computed:{
    filteredTypes(){
      const q=this.typeSearch.toLowerCase()
      return q?this.types.filter(t=>t.name.toLowerCase().includes(q)||t.code.toLowerCase().includes(q)):this.types
    },
    uploadUrl(){return'/api/dictionary/import'},
    uploadHeaders(){const t=this.$store.state.user?.token;return t?{Authorization:'Bearer '+t}:{}},
  },
  async created(){await this.loadTypes()},
  methods: {
    // 权限判断：按钮权限控制
    hasPerm(code) { const p = this.$store.state.user && this.$store.state.user.permissions ? this.$store.state.user.permissions : []; return p.indexOf(code) > -1 },
    async loadTypes(){try{const r=await getTypes();if(r.code===0)this.types=r.data||[]}catch{}},
    async loadEntries(){
      if(!this.activeType)return
      try{const r=await getEntries(this.activeType.id,this.entrySearch);if(r.code===0)this.entries=r.data||[]}catch{}
    },
    selectType(t){this.activeType=t;this.loadEntries()},
    openTypeForm(t){this.typeForm=t?{...t}:{name:'',code:'',description:'',sort:0,status:1};this.showTypeForm=true},
    async saveType(){
      this.savingType=true
      try{
        const r=this.typeForm.id?await updateType(this.typeForm.id,this.typeForm):await createType(this.typeForm)
        if(r.code===0){this.$message.success('成功');this.showTypeForm=false;this.loadTypes()}else this.$message.error(r.msg||'失败')
      }catch{}finally{this.savingType=false}
    },
    async confirmDelType(t){
      try{await this.$confirm(`确定删除字典类型「${t.name}」？`,'提示',{type:'warning'});const r=await deleteType(t.id);if(r.code===0){this.$message.success('已删除');if(this.activeType?.id===t.id)this.activeType=null;this.loadTypes()}else this.$message.error(r.msg||'失败')}catch{}
    },
    openEntryForm(e){
      this.entryForm=e?{...e,extra:e.extra?JSON.stringify(e.extra):''}:{type_id:this.activeType?.id||0,label:'',value:'',sort:0,style:'',extra:'',status:1,remark:''}
      if(!e)this.entryForm.type_id=this.activeType?.id||0
      this.showEntryForm=true
    },
    async saveEntry(){
      this.savingEntry=true
      try{
        const data={...this.entryForm}
        if(data.extra)try{data.extra=JSON.parse(data.extra)}catch{}
        const r=data.id?await updateEntry(data.id,data):await createEntry(data)
        if(r.code===0){this.$message.success('成功');this.showEntryForm=false;this.loadEntries()}else this.$message.error(r.msg||'失败')
      }catch{}finally{this.savingEntry=false}
    },
    async confirmDelEntry(e){
      try{await this.$confirm(`确定删除字典条目「${e.label}」？`,'提示',{type:'warning'});const r=await deleteEntry(e.id);if(r.code===0){this.$message.success('已删除');this.loadEntries()}else this.$message.error(r.msg||'失败')}catch{}
    },
    async toggleEntryStatus(row,v){
      try{await updateEntry(row.id,{status:v?1:0});row.status=v?1:0}catch{row.status=row.status}
    },
    async handleExport(){
      try{const r=await exportDict();if(r.code===0&&r.data){const b=new Blob([JSON.stringify(r.data,null,2)],{type:'application/json'});const a=document.createElement('a');a.href=URL.createObjectURL(b);a.download='dictionary_export.json';a.click();URL.revokeObjectURL(a.href)}}catch{this.$message.error('导出失败')}
    },
    onImportSuccess(res){
      if(res.code===0){this.$message.success(res.msg||'导入成功');this.showImport=false;this.loadTypes()}else this.$message.error(res.msg||'导入失败')
    },
  },
  watch:{entrySearch(){if(this.activeType)this.loadEntries()}},
}
</script>

<style scoped>
.dictionary-page { padding:20px; height:100%; display:flex; flex-direction:column; background:#f0f2f5; }
.page-header { display:flex; justify-content:space-between; align-items:center; margin-bottom:16px; }
.page-header h2 { margin:0; font-size:20px; font-weight:700; color:#303133; }
.main-body { flex:1; display:flex; gap:16px; min-height:0; }
/* 左侧面板 */
.left-panel { width:280px; flex-shrink:0; background:#f5f7fa; border-radius:8px; display:flex; flex-direction:column; overflow:hidden; border:1px solid #EBEEF5; }
.left-header { display:flex; justify-content:space-between; align-items:center; padding:12px 16px; font-size:14px; color:#303133; }
.type-list { flex:1; overflow-y:auto; padding:4px 0; }
.type-item { display:flex; align-items:center; justify-content:space-between; height:44px; padding:0 16px; cursor:pointer; border-left:3px solid transparent; border-radius:0; margin:1px 0; transition:.15s; }
.type-item:hover { background:#f1f5f9; }
.type-item.active { background:#eef2ff; border-left-color:#4F46E5; }
.type-info { flex:1; min-width:0; }
.type-name { font-size:14px; color:#303133; line-height:1.3; }
.type-code { font-size:12px; color:#909399; }
.type-meta { display:flex; align-items:center; gap:2px; flex-shrink:0; }
.entry-count { font-size:12px; color:#C0C4CC; margin-right:4px; white-space:nowrap; }
.left-footer { padding:12px 16px; font-size:12px; color:#909399; border-top:1px solid #EBEEF5; text-align:center; }
/* 右侧面板 */
.right-panel { flex:1; background:#fff; border-radius:8px; padding:20px 24px; overflow:auto; border:1px solid #EBEEF5; }
.right-empty { display:flex; flex-direction:column; align-items:center; justify-content:center; color:#C0C4CC; }
.right-empty i { font-size:48px; margin-bottom:12px; }
.right-header { display:flex; justify-content:space-between; align-items:center; margin-bottom:12px; flex-wrap:wrap; gap:8px; }
.right-title { font-size:18px; font-weight:700; color:#303133; margin-right:8px; }
.right-code { font-size:13px; color:#909399; }
/* 弹窗内el-form覆盖（暗色模式适配） */
::v-deep .el-dialog__body { padding:20px 24px; }
</style>
