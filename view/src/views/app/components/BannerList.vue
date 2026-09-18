<template>
  <div class="banner-list">
    <div class="list-header">
      <div class="header-left">
        <h3 class="current-group">轮播图列表</h3>
      </div>
      <div class="header-right">
        <el-button v-if="hasPerm('app:banner:create')" type="primary" size="small" icon="el-icon-plus" :disabled="!groupId" @click="openCreate">新增</el-button>
        <el-button v-if="hasPerm('app:banner:batch')" size="small" type="success" icon="el-icon-upload2" :disabled="!groupId" @click="showBatch=true">批量上传</el-button>
        <el-input v-model="keyword" size="small" placeholder="搜索标题..." prefix-icon="el-icon-search" clearable style="width:200px;margin-left:12px" @input="onSearch" />
      </div>
    </div>
    <div class="stats-row" v-if="stats">
      <div class="stat-card"><div class="stat-val">{{ stats.total_views||0 }}</div><div class="stat-lb">总展示</div></div>
      <div class="stat-card"><div class="stat-val">{{ stats.total_clicks||0 }}</div><div class="stat-lb">总点击</div></div>
      <div class="stat-card"><div class="stat-val">{{ stats.banner_count||0 }}</div><div class="stat-lb">轮播图数</div></div>
    </div>
    <div class="table-wrap" v-loading="loading">
      <el-table ref="dragTable" :data="list" size="small" border stripe style="width:100%" row-key="id">
        <el-table-column type="index" label="#" width="50" align="center" />
        <el-table-column label="图片" width="100" align="center">
          <template slot-scope="{row}"><img v-if="row.image" :src="row.image" style="width:80px;height:40px;object-fit:cover;border-radius:4px" /><span v-else style="color:#ccc">无图</span></template>
        </el-table-column>
        <el-table-column prop="title" label="标题" min-width="120" show-overflow-tooltip />
        <el-table-column label="链接" min-width="140" show-overflow-tooltip>
          <template slot-scope="{row}"><span style="font-size:12px;color:#909399">{{ row.link_url||'-' }}</span></template>
        </el-table-column>
        <el-table-column label="平台" width="70" align="center">
          <template slot-scope="{row}"><el-tag :type="['info','primary','success'][row.platform]||'info'" size="mini" effect="plain">{{ ['全部','小程序','H5'][row.platform]||'未知' }}</el-tag></template>
        </el-table-column>
        <el-table-column label="排序" width="60" align="center">
          <template slot-scope="{row}"><el-tag size="mini">{{ row.sort }}</el-tag></template>
        </el-table-column>
        <el-table-column label="状态" width="70" align="center">
          <template slot-scope="{row}"><el-switch :value="!!row.status" @change="v=>toggleStatus(row,v?1:0)" /></template>
        </el-table-column>
        <el-table-column label="定时发布" width="150" align="center"><template slot-scope="{row}"><span style="font-size:12px">{{ row.publish_time||'立即' }}</span></template></el-table-column>
        <el-table-column label="定时下架" width="150" align="center"><template slot-scope="{row}"><span style="font-size:12px">{{ row.unpublish_time||'永不' }}</span></template></el-table-column>
        <el-table-column label="操作" width="120" align="center" fixed="right">
          <template slot-scope="{row}">
            <el-button v-if="hasPerm('app:banner:edit')" size="mini" type="text" icon="el-icon-edit" @click="openEdit(row)">编辑</el-button>
            <el-button v-if="hasPerm('app:banner:delete')" size="mini" type="text" icon="el-icon-delete" style="color:#F56C6C" @click="confirmDel(row)">删除</el-button>
          </template>
        </el-table-column>
      </el-table>
    </div>
    <div class="pagination-wrap" v-if="total>0">
      <el-pagination :current-page="page" :page-sizes="[20,50,100]" :page-size="limit" :total="total" layout="total,sizes,prev,pager,next,jumper" @size-change="s=>{limit=s;load()}" @current-change="p=>{page=p;load()}" />
    </div>

    <el-dialog :title="form.id?'编辑轮播图':'新增轮播图'" :visible.sync="showForm" width="560px" @closed="resetForm">
      <el-form ref="formRef" :model="form" label-width="100px" size="small">
        <el-form-item label="标题" prop="title"><el-input v-model="form.title" maxlength="100" /></el-form-item>
        <el-form-item label="图片">
          <el-upload action="" :show-file-list="false" :http-request="uploadImage" accept="image/*">
            <img v-if="form.image" :src="form.image" style="width:120px;height:60px;object-fit:cover;border-radius:4px;cursor:pointer" />
            <el-button v-else size="small">选择图片</el-button>
          </el-upload>
          <div style="margin-top:6px">
            <el-button size="mini" type="primary" plain icon="el-icon-folder-opened" @click="driveVisible = true">从企业网盘选择</el-button>
          </div>
          <drive-file-picker :visible="driveVisible" mode="image" :multiple="false" @update:visible="driveVisible = $event" @confirm="onDrivePick" />
        </el-form-item>
        <el-form-item label="链接类型">
          <el-select v-model="form.link_type" style="width:100%"><el-option v-for="d in dictLinkType" :key="d.value" :label="d.label" :value="Number(d.value)" /></el-select>
        </el-form-item>
        <el-form-item label="跳转链接"><el-input v-model="form.link_url" /></el-form-item>
        <el-form-item label="平台">
          <el-select v-model="form.platform" style="width:100%"><el-option v-for="d in dictPlatform" :key="d.value" :label="d.label" :value="Number(d.value)" /></el-select>
        </el-form-item>
        <el-form-item label="排序"><el-input-number v-model="form.sort" :min="0" style="width:100%" /></el-form-item>
        <el-form-item label="状态"><el-switch v-model="form.status" :active-value="1" :inactive-value="0" /></el-form-item>
        <el-form-item label="定时发布"><el-date-picker v-model="form.publish_time" type="datetime" placeholder="留空立即发布" style="width:100%" value-format="yyyy-MM-dd HH:mm:ss" /></el-form-item>
        <el-form-item label="定时下架"><el-date-picker v-model="form.unpublish_time" type="datetime" placeholder="留空永不失效" style="width:100%" value-format="yyyy-MM-dd HH:mm:ss" /></el-form-item>
      </el-form>
      <span slot="footer"><el-button @click="showForm=false">取消</el-button><el-button type="primary" :loading="saving" @click="saveForm">确定</el-button></span>
    </el-dialog>

    <el-dialog title="批量上传" :visible.sync="showBatch" width="700px" @closed="resetBatch">
      <el-upload ref="batchUp" action="" multiple :auto-upload="false" :file-list="batchFiles" :on-change="onBatchChange" :on-remove="onBatchRemove" accept="image/*" list-type="picture-card">
        <i class="el-icon-plus" />
      </el-upload>
      <div v-if="batchFiles.length>0" style="margin-top:16px;border-top:1px solid #EBEEF5;padding-top:16px">
        <el-form label-width="90px" size="small">
          <el-form-item label="链接类型"><el-select v-model="batchOpts.link_type" style="width:100%"><el-option label="内链" value="1" /><el-option label="外链" value="2" /><el-option label="商品" value="3" /><el-option label="活动" value="4" /><el-option label="文章" value="5" /></el-select></el-form-item>
          <el-form-item label="跳转链接"><el-input v-model="batchOpts.link_url" /></el-form-item>
          <el-form-item label="平台"><el-select v-model="batchOpts.platform" style="width:100%"><el-option label="全部" value="0" /><el-option label="小程序" value="1" /><el-option label="H5" value="2" /></el-select></el-form-item>
          <el-form-item label="状态"><el-switch v-model="batchOpts.status" :active-value="1" :inactive-value="0" /></el-form-item>
        </el-form>
        <div style="margin-top:12px;padding-top:12px;border-top:1px solid #EBEEF5">
          <div style="font-size:13px;font-weight:500;color:#606266;margin-bottom:8px">图片标题（可单独修改）</div>
          <div v-for="(f,idx) in batchFiles" :key="f.uid" style="display:flex;align-items:center;gap:8px;margin-bottom:6px">
            <span style="font-size:12px;color:#909399;width:24px;text-align:right;flex-shrink:0">{{ idx+1 }}.</span>
            <el-input v-model="f._title" size="small" placeholder="点击输入标题" maxlength="100" style="flex:1" />
          </div>
        </div>
        <div v-if="batchProgress.show" style="margin-top:12px">
          <el-progress :percentage="batchProgress.pct" :status="batchProgress.done?'success':undefined" />
        </div>
      </div>
      <span slot="footer"><el-button @click="showBatch=false">取消</el-button><el-button type="primary" :loading="batchLoading" :disabled="batchFiles.length===0" @click="submitBatch">上传 {{ batchFiles.length }} 张</el-button></span>
    </el-dialog>
  </div>
</template>

<script>
import Sortable from 'sortablejs'
import { getBannerList, createBanner, updateBanner, deleteBanner, sortBanners, getBannerStats } from '@/api/app'
import { getDictionary } from '@/utils/dict'
import { getSettingValue } from '@/api/settings'
import request from '@/api/request'

export default {
  name: 'BannerList',
  props: { groupId: { type: [Number,String], default: null } },
  data() {
    return {
      list: [], total: 0, page: 1, limit: 20, loading: false, keyword: '', searchTimer: null, stats: null,
      showForm: false, saving: false,
      driveVisible: false,
      form: { title:'', image:'', link_type:1, link_url:'', platform:0, sort:0, status:1, publish_time:null, unpublish_time:null },
      showBatch: false, batchLoading: false, batchFiles: [],
      batchOpts: { link_type:1, link_url:'', platform:0, status:1 },
      batchProgress: { show:false, pct:0, done:false },
      dictLinkType: [], dictPlatform: [], maxBannerCount: 0,
    }
  },
  created() { this.loadDicts() },
  watch: { groupId: { immediate: true, handler(v) { if(v){ this.page=1;this.keyword='';this.load();this.loadStats() }else{ this.list=[];this.total=0 } } } },
  methods: {
    // 权限判断：按钮权限控制
    hasPerm(code) { const p = this.$store.state.user && this.$store.state.user.permissions ? this.$store.state.user.permissions : []; return p.indexOf(code) > -1 },
     async load() {
      if(!this.groupId) return; this.loading=true
      try{ const r=await getBannerList({group_id:this.groupId,page:this.page,limit:this.limit,keyword:this.keyword||undefined}); this.list=r.data.list||[]; this.total=r.data.total||0; this.$nextTick(()=>this.initDrag()) }catch(e){ this.list=[];this.total=0 }
      this.loading=false
    },
    async loadStats() {
      if(!this.groupId) return; try{ const r=await getBannerStats({group_id:this.groupId}); this.stats=r.data||null }catch(e){ this.stats=null }
    },
    onSearch() { clearTimeout(this.searchTimer); this.searchTimer=setTimeout(()=>{this.page=1;this.load()},300) },
    initDrag() {
      const el=this.$refs.dragTable?.$el?.querySelector('.el-table__body-wrapper tbody'); if(!el) return
      Sortable.create(el, {
        animation:200, handle:'.el-table__row',
        onEnd:async({oldIndex,newIndex})=>{
          if(oldIndex===newIndex) return
          const ids=this.list.map(i=>i.id); const item=ids.splice(oldIndex,1)[0]; ids.splice(newIndex,0,item)
          try{ await sortBanners(ids); this.$message.success('排序已更新'); await this.load() }catch(e){ await this.load() }
        }
      })
    },
    toggleStatus(row,v) { const o=row.status; row.status=v; updateBanner(row.id,{status:v}).catch(()=>{row.status=o}) },
    async loadDicts() { this.dictLinkType=await getDictionary('link_type')||[]; this.dictPlatform=await getDictionary('platform_type')||[];
      try{ const r=await getSettingValue('banner_max_count_per_group'); this.maxBannerCount=parseInt(r.data?.value)||0 }catch(e){} },
    openCreate() { this.form={title:'',image:'',link_type:1,link_url:'',platform:0,sort:0,status:1,publish_time:null,unpublish_time:null}; this.showForm=true },
    openEdit(row) { this.form={...row}; this.showForm=true },
    resetForm() {},
    onDrivePick(list) { if (list.length) { this.form.image = list[0].url; this.$message.success('已选择：' + list[0].name) } },
    async uploadImage({file,onSuccess}) {
      const fd=new FormData(); fd.append('file',file)
      try{ const r=await request({url:'/upload',method:'post',data:fd,headers:{'Content-Type':'multipart/form-data'}}); if(r.code===0&&r.data?.url){ this.form.image=r.data.url; onSuccess(); this.$message.success('上传成功') }else{ this.$message.error(r.msg||'上传失败') } }catch(e){ this.$message.error('上传失败') }
    },
    async saveForm() {
      this.saving=true
      try{ if(this.form.id){ await updateBanner(this.form.id,this.form) }else{ await createBanner({...this.form,group_id:this.groupId}) } this.$message.success('保存成功'); this.showForm=false; this.load(); this.loadStats() }catch(e){}
      this.saving=false
    },
    confirmDel(row) { this.$confirm('确定删除吗？','提示',{type:'warning'}).then(async()=>{ try{ await deleteBanner(row.id); this.$message.success('已删除'); this.load(); this.loadStats() }catch(e){} }).catch(()=>{}) },
    onBatchChange(f,fl){ this.batchFiles=fl.map(x=>({uid:x.uid,raw:x.raw,_title:x.name?.replace(/\.[^.]+$/,'')||''})) },
    onBatchRemove(f,fl){ this.batchFiles=fl.map(x=>({uid:x.uid,raw:x.raw,_title:x.name?.replace(/\.[^.]+$/,'')||''})) },
    resetBatch(){ this.$refs.batchUp?.clearFiles(); this.batchFiles=[]; this.batchOpts={link_type:1,link_url:'',platform:0,status:1}; this.batchProgress={show:false,pct:0,done:false} },
    async submitBatch() {
      if(!this.batchFiles.length) return; this.batchLoading=true; this.batchProgress={show:true,pct:0,done:false}
      const total=this.batchFiles.length; let doneCount=0
      for(const f of this.batchFiles){
        if(!f.raw) continue
        const fd=new FormData(); fd.append('group_id',this.groupId); Object.entries(this.batchOpts).forEach(([k,v])=>fd.append(k,v))
        fd.append('files',f.raw); fd.append('titles',f._title||'')
        try{ await request({url:'/admin/banners/batch',method:'post',data:fd,headers:{'Content-Type':'multipart/form-data'}}); doneCount++ }catch(e){}
        this.batchProgress.pct=Math.round(doneCount/total*100)
      }
      this.batchProgress.done=true; this.batchLoading=false
      this.$message.success(`上传完成 ${doneCount}/${total}`)
      if(doneCount===total){ this.showBatch=false; this.load(); this.loadStats() }
    }
  }
}
</script>

<style scoped>
.banner-list { width:100%;background:#fff;border:1px solid #EBEEF5;border-radius:4px;display:flex;flex-direction:column;overflow:hidden; }
.list-header { height:48px;display:flex;align-items:center;justify-content:space-between;padding:0 20px;border-bottom:1px solid #EBEEF5;flex-shrink:0; }
.current-group { font-size:15px;font-weight:600;color:#303133;margin:0; }
.header-right { display:flex;align-items:center; }
.stats-row { display:flex;gap:16px;padding:12px 20px 0;flex-shrink:0; }
.stat-card { background:#f5f7fa;border-radius:8px;padding:14px 24px;display:flex;flex-direction:column;align-items:center;min-width:100px; }
.stat-val { font-size:24px;font-weight:bold;color:#409EFF;line-height:1.2; }
.stat-lb { font-size:13px;color:#909399;margin-top:4px; }
.table-wrap { margin:12px 20px 0;flex:1;overflow-x:auto; }
.pagination-wrap { display:flex;justify-content:flex-end;padding:12px 20px;margin:0 20px 20px;border-top:1px solid #EBEEF5;flex-shrink:0; }
</style>
