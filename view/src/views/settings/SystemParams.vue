<template>
  <div class="params-page">
    <div class="page-header">
      <div><h2>系统参数</h2><p class="page-subtitle">管理系统全局配置参数 · 共 {{ totalCount }} 个参数</p></div>
      <div style="display:flex;gap:8px">
        <el-input v-model="search" size="small" placeholder="搜索参数名称或说明" prefix-icon="el-icon-search" clearable style="width:240px" />
        <el-button v-if="hasPerm('settings:reset')" size="small" @click="confirmReset">恢复默认</el-button>
      </div>
    </div>

    <div class="params-body" v-loading="loading">
      <!-- 骨架屏 -->
      <template v-if="loading">
        <div class="param-card" v-for="i in 4" :key="i">
          <div class="card-header"><span class="skeleton" style="width:120px;height:20px"></span><span class="skeleton" style="width:60px;height:16px"></span></div>
          <div v-for="j in 4" :key="j" class="param-row"><span class="skeleton" style="width:140px;height:16px"></span><span class="skeleton" style="width:200px;height:14px"></span><span class="skeleton" style="width:180px;height:32px"></span></div>
        </div>
      </template>
      <template v-else>
        <div v-for="(group, gIdx) in filteredGroups" :key="group.group" class="param-card">
          <div class="card-header">
            <span class="card-title">{{ group.name }}</span>
            <span class="card-count">共 {{ group.params.length }} 项</span>
          </div>
          <div class="param-list">
            <div v-for="(param, pIdx) in group.params" :key="param.key" class="param-row" v-show="!search || matchSearch(param)">
              <div class="param-name">{{ param.name }}</div>
              <div class="param-desc" :title="param.description">{{ param.description }}</div>
              <div class="param-value">
                <span v-if="param.type==='switch'"><el-switch :value="strToBool(param.value)" @change="v=>saveParam(param, v?'1':'0')" :disabled="isDisabled(param)" /></span>
                <span v-else-if="param.type==='number'"><el-input-number :value="Number(param.value)" :min="0" size="small" style="width:140px" @change="v=>saveParam(param,String(v))" :disabled="isDisabled(param)" /></span>
                <span v-else-if="param.type==='select' && param.options">
                  <el-select :value="param.value" size="small" style="width:180px" @change="v=>saveParam(param,v)" :disabled="isDisabled(param)">
                    <el-option v-for="o in param.options" :key="o.value" :label="o.label" :value="o.value" />
                  </el-select>
                </span>
                <span v-else-if="param.type==='textarea'"><el-input :value="param.value" type="textarea" :rows="2" size="small" style="width:260px" @blur="e=>saveParam(param,e.target.value)" :disabled="isDisabled(param)" /></span>
                <span v-else-if="param.is_sensitive">
                  <el-input :value="'••••••••'" show-password disabled size="small" style="width:160px" />
                  <el-button v-if="hasPerm('settings:updateParam')" size="mini" @click="editSensitive(param)" style="margin-left:4px">修改</el-button>
                </span>
                <span v-else-if="param.type==='readonly'"><el-input :value="param.value" disabled size="small" style="width:180px" /></span>
                <span v-else><el-input :value="param.value" size="small" style="width:220px" @blur="e=>saveParam(param,e.target.value)" :disabled="isDisabled(param)" /></span>
              </div>
              <el-button v-if="hasPerm('settings:updateParam')" size="mini" type="primary" @click="saveParam(param,param.value)" :loading="savingKey===param.key" v-show="param.type!=='readonly' && !param.is_sensitive">保存</el-button>
              <el-tag v-if="param.is_sensitive" size="mini" type="warning" style="margin-left:4px">敏感</el-tag>
            </div>
          </div>
        </div>
        <div v-if="filteredGroups.length===0" class="empty-state">
          <i class="el-icon-search" style="font-size:48px;color:#C0C4CC"></i>
          <p style="color:#909399;margin-top:12px">未找到匹配的参数，请调整搜索关键词</p>
        </div>
      </template>
    </div>

    <div class="page-footer" v-if="lastUpdate">最后更新：{{ lastUpdate }}</div>

    <!-- 敏感参数编辑弹窗 -->
    <el-dialog title="编辑敏感参数" :visible.sync="showSensitive" width="450px">
      <el-form label-width="100px" size="small">
        <el-form-item :label="sensitiveParam?.name"><el-input v-model="sensitiveValue" type="password" show-password placeholder="输入新值" /></el-form-item>
      </el-form>
      <span slot="footer"><el-button @click="showSensitive=false" size="small">取消</el-button>
        <el-button type="primary" :loading="saving" @click="doSaveSensitive" size="small">保存</el-button></span>
    </el-dialog>
  </div>
</template>

<script>
import { getParams, updateParam, resetParams } from '@/api/settings'

export default {
  name:'SystemParams',
  data(){
    return{
      loading:false, groups:{}, search:'', lastUpdate:'', saving:false, savingKey:'',
      showSensitive:false, sensitiveParam:null, sensitiveValue:'',
    }
  },
  computed:{
    totalCount(){
      let c=0; Object.values(this.groups).forEach(g=>c+=g.params.length); return c
    },
    filteredGroups(){
      const q=this.search.toLowerCase()
      if(!q) return Object.values(this.groups)
      return Object.values(this.groups).map(g=>({...g,params:g.params.filter(p=>this.matchSearch(p,q))})).filter(g=>g.params.length>0)
    },
  },
  async created(){await this.loadData()},
  methods: {
    // 权限判断：按钮权限控制
    hasPerm(code) { const p = this.$store.state.user && this.$store.state.user.permissions ? this.$store.state.user.permissions : []; return p.indexOf(code) > -1 },
    async loadData(){
      this.loading=true
      try{const r=await getParams();if(r.code===0)this.groups=r.data||{};this.lastUpdate=new Date().toLocaleString()}catch{}
      this.loading=false
    },
    matchSearch(p,q){const s=(q||this.search).toLowerCase();return p.name.toLowerCase().includes(s)||p.description.toLowerCase().includes(s)},
    strToBool(v){return v==='1'||v==='true'},
    isDisabled(p){
      if(p.key==='user_password_min_length'||p.key==='user_login_attempts'||p.key==='user_lockout_duration')return false
      // 参数依赖：notification_* 依赖 notification_enabled
      if(p.key.startsWith('notification_')&&p.key!=='notification_enabled'){
        return this.groups['notification']?.params?.find(pp=>pp.key==='notification_enabled')?.value!=='1'
      }
      // performance_cache_driver 依赖 performance_cache_enabled
      if(p.key==='performance_cache_driver'||p.key==='performance_slow_query_threshold'){
        return this.groups['performance']?.params?.find(pp=>pp.key==='performance_cache_enabled')?.value!=='1'
      }
      return false
    },
    async saveParam(p,val){
      this.savingKey=p.key
      try{
        const r=await updateParam(p.key,{value:String(val)})
        if(r.code===0){this.$message.success('参数已更新');p.value=String(val)}else this.$message.error(r.msg||'失败')
      }catch{}finally{this.savingKey=''}
    },
    editSensitive(p){this.sensitiveParam=p;this.sensitiveValue='';this.showSensitive=true},
    async doSaveSensitive(){
      if(!this.sensitiveValue)return this.$message.warning('请输入新值')
      this.saving=true
      try{
        const r=await updateParam(this.sensitiveParam.key,{value:this.sensitiveValue})
        if(r.code===0){this.$message.success('参数已更新');this.sensitiveParam.value='••••••••';this.showSensitive=false}else this.$message.error(r.msg||'失败')
      }catch{}finally{this.saving=false}
    },
    async confirmReset(){
      try{await this.$confirm('确定恢复所有参数为默认值？此操作不可撤销。','提示',{type:'warning'});const r=await resetParams();if(r.code===0){this.$message.success('已恢复默认');this.loadData()}else this.$message.error(r.msg||'失败')}catch{}
    },
  },
}
</script>

<style scoped>
.params-page { padding:20px; height:100%; display:flex; flex-direction:column; background:#f0f2f5; gap:16px; }
.page-header { display:flex; justify-content:space-between; align-items:flex-start; }
.page-header h2 { margin:0; font-size:20px; font-weight:700; color:#303133; }
.page-subtitle { margin:4px 0 0; font-size:13px; color:#909399; }
.params-body { flex:1; overflow-y:auto; display:flex; flex-direction:column; gap:16px; }
.param-card { background:#fff; border-radius:8px; padding:20px 24px; box-shadow:0 2px 8px rgba(0,0,0,0.06); }
.card-header { display:flex; justify-content:space-between; align-items:center; padding-bottom:12px; border-bottom:1px solid #EBEEF5; }
.card-title { font-size:16px; font-weight:600; color:#303133; }
.card-count { font-size:13px; color:#909399; }
.param-row { display:flex; align-items:center; height:52px; border-bottom:1px solid #f5f7fa; gap:12px; }
.param-row:last-child { border-bottom:none; }
.param-name { width:140px; font-size:14px; font-weight:600; color:#303133; flex-shrink:0; }
.param-desc { width:200px; font-size:13px; color:#909399; flex-shrink:0; overflow:hidden; text-overflow:ellipsis; white-space:nowrap; }
.param-value { flex:1; display:flex; align-items:center; gap:4px; }
.page-footer { font-size:12px; color:#909399; text-align:center; padding:8px 0; }
.skeleton { display:inline-block; background:linear-gradient(90deg,#f0f0f0 25%,#e0e0e0 50%,#f0f0f0 75%); background-size:200% 100%; animation:skeleton-loading 1.5s infinite; border-radius:4px; }
@keyframes skeleton-loading{0%{background-position:200% 0}100%{background-position:-200% 0}}
.empty-state { text-align:center; padding:60px 0; }
</style>
