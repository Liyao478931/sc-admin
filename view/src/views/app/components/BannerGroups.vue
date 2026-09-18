<template>
  <div class="banner-groups">
    <div class="groups-header">
      <span class="header-title">轮播组</span>
      <el-button type="primary" size="small" icon="el-icon-plus" @click="openCreate">新增组</el-button>
    </div>
    <div class="groups-body" v-loading="loading">
      <div v-for="item in list" :key="item.id" class="group-item" :class="{ active: activeId === item.id }" @click="handleSelect(item)">
        <div class="group-info">
          <div class="group-name">{{ item.name }}</div>
          <div class="group-meta">
            <span class="group-code">{{ item.code }}</span>
            <span class="group-divider">|</span>
            <span class="group-pos">{{ item.position || '-' }}</span>
          </div>
        </div>
        <div class="group-right">
          <span class="status-dot" :class="item.status ? 'active' : 'inactive'" />
          <el-dropdown trigger="click" size="mini" @command="cmd => handleCommand(cmd, item)">
            <el-button type="text" size="mini" icon="el-icon-more" class="more-btn" @click.stop />
            <el-dropdown-menu slot="dropdown">
              <el-dropdown-item command="edit" icon="el-icon-edit">编辑</el-dropdown-item>
              <el-dropdown-item command="delete" icon="el-icon-delete" style="color:#F56C6C">删除</el-dropdown-item>
            </el-dropdown-menu>
          </el-dropdown>
        </div>
      </div>
      <div v-if="!loading && list.length === 0" class="empty-tip">暂无轮播组</div>
    </div>
    <div class="groups-footer">共 {{ list.length }} 个组</div>

    <el-dialog :title="form.id ? '编辑轮播组' : '新增轮播组'" :visible.sync="showForm" width="520px" @closed="resetForm">
      <el-form ref="form" :model="form" label-width="120px" size="small" :rules="rules">
        <el-form-item label="组名称" prop="name">
          <el-input v-model="form.name" placeholder="请输入名称" maxlength="30" />
        </el-form-item>
        <el-form-item label="组编码" prop="code">
          <el-input v-model="form.code" placeholder="如 home_banner" maxlength="50" :disabled="!!form.id" />
          <div class="form-tip">编码创建后不可修改</div>
        </el-form-item>
        <el-form-item label="位置标识">
          <el-select v-model="form.position" style="width:100%"><el-option v-for="d in dictPos" :key="d.value" :label="d.label" :value="d.value" /></el-select>
        </el-form-item>
        <el-form-item label="轮播样式">
          <el-select v-model="form.style" style="width:100%"><el-option v-for="d in dictStyle" :key="d.value" :label="d.label" :value="Number(d.value)" /></el-select>
        </el-form-item>
        <el-form-item label="指示器样式">
          <el-select v-model="form.indicator_style" style="width:100%"><el-option v-for="d in dictInd" :key="d.value" :label="d.label" :value="Number(d.value)" /></el-select>
        </el-form-item>
        <el-form-item label="切换动画">
          <el-select v-model="form.animation" style="width:100%"><el-option v-for="d in dictAnim" :key="d.value" :label="d.label" :value="Number(d.value)" /></el-select>
        </el-form-item>
        <el-form-item label="轮播间隔">
          <el-input-number v-model="form.autoplay_interval" :min="1" :max="60" style="width:160px" /> 秒
        </el-form-item>
        <el-form-item label="状态">
          <el-switch v-model="form.status" :active-value="1" :inactive-value="0" />
        </el-form-item>
      </el-form>
      <span slot="footer">
        <el-button @click="showForm=false" size="small">取消</el-button>
        <el-button type="primary" :loading="saving" @click="saveForm" size="small">确定</el-button>
      </span>
    </el-dialog>
  </div>
</template>

<script>
import { getBannerGroups, createBannerGroup, updateBannerGroup, deleteBannerGroup } from '@/api/app'
import { getDictionary } from '@/utils/dict'

export default {
  name: 'BannerGroups',
  data() {
    return {
      list: [], loading: false, activeId: null, showForm: false, saving: false,
      form: { name: '', code: '', position: '', style: 1, indicator_style: 1, animation: 1, autoplay_interval: 3, status: 1 },
      dictStyle: [], dictInd: [], dictAnim: [], dictPos: [],
      rules: {
        name: [{ required: true, message: '请输入名称', trigger: 'blur' }],
        code: [{ required: true, message: '请输入编码', trigger: 'blur' }, { pattern: /^[a-zA-Z][a-zA-Z0-9_]*$/, message: '字母开头，仅字母数字下划线' }],
      }
    }
  },
  created() { this.loadList(); this.loadDicts() },
  methods: {
    async loadDicts() { this.dictStyle=await getDictionary('banner_style')||[]; this.dictInd=await getDictionary('indicator_style')||[]; this.dictAnim=await getDictionary('animation_style')||[]; this.dictPos=await getDictionary('banner_position')||[] },
    async loadList() {
      this.loading = true
      try { const r = await getBannerGroups(); this.list = r.data || []; if (this.list.length > 0 && !this.activeId) { this.activeId = this.list[0].id; this.$emit('select', this.activeId) } } catch (e) { this.list = [] }
      this.loading = false
    },
    handleSelect(item) { this.activeId = item.id; this.$emit('select', item.id) },
    handleCommand(cmd, item) { if (cmd === 'edit') this.openEdit(item); else this.confirmDelete(item) },
    openCreate() { this.form = { name: '', code: '', position: '', style: 1, indicator_style: 1, animation: 1, autoplay_interval: 3, status: 1 }; this.showForm = true },
    openEdit(row) { this.form = { ...row }; this.showForm = true },
    resetForm() { this.$refs.form?.clearValidate() },
    async saveForm() {
      try { await this.$refs.form.validate() } catch (e) { return }
      this.saving = true
      try { if (this.form.id) { const d = { ...this.form }; delete d.id; await updateBannerGroup(this.form.id, d) } else { await createBannerGroup(this.form) } this.$message.success(this.form.id ? '编辑成功' : '新增成功'); this.showForm = false; await this.loadList() } catch (e) {}
      this.saving = false
    },
    confirmDelete(row) {
      this.$confirm(`确定删除「${row.name}」吗？${'<br><span style="color:#F56C6C;font-size:12px">有轮播图时禁止删除</span>'}`, '提示', { type: 'warning', dangerouslyUseHTMLString: true })
        .then(async () => { try { await deleteBannerGroup(row.id); this.$message.success('已删除'); if (this.activeId === row.id) { this.activeId = null; this.$emit('select', null) }; await this.loadList() } catch (e) {} }).catch(() => {})
    }
  }
}
</script>

<style scoped>
.banner-groups { width:100%;background:#fff;border:1px solid #EBEEF5;border-radius:4px;display:flex;flex-direction:column;height:100%;overflow:hidden; }
.groups-header { height:48px;display:flex;align-items:center;justify-content:space-between;padding:0 16px;border-bottom:1px solid #EBEEF5;flex-shrink:0; }
.header-title { font-size:15px;font-weight:600;color:#303133; }
.groups-body { flex:1;overflow-y:auto;padding:4px 0; }
.group-item { display:flex;align-items:center;padding:10px 16px;cursor:pointer;border-left:3px solid transparent;transition:background 0.2s; }
.group-item:hover { background:#f5f7fa; }
.group-item.active { background:#ecf5ff;border-left-color:#409EFF; }
.group-info { flex:1;min-width:0; }
.group-name { font-size:14px;font-weight:500;color:#303133;overflow:hidden;text-overflow:ellipsis;white-space:nowrap; }
.group-meta { font-size:12px;color:#909399;margin-top:2px;display:flex;align-items:center;gap:4px; }
.group-code { font-family:monospace;font-size:11px; }
.group-divider { color:#DCDFE6; }
.group-pos { font-size:11px; }
.group-right { display:flex;align-items:center;gap:8px;flex-shrink:0;margin-left:8px; }
.status-dot { width:8px;height:8px;border-radius:50%; }
.status-dot.active { background:#67C23A; }
.status-dot.inactive { background:#C0C4CC; }
.more-btn { padding:2px 4px;font-size:16px;color:#909399; }
.more-btn:hover { color:#409EFF; }
.groups-footer { height:40px;display:flex;align-items:center;justify-content:center;border-top:1px solid #EBEEF5;font-size:13px;color:#909399;flex-shrink:0; }
.empty-tip { text-align:center;padding:40px;font-size:13px;color:#C0C4CC; }
.form-tip { font-size:12px;color:#C0C4CC;margin-top:2px; }
</style>
