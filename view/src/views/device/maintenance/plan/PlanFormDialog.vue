<template>
  <el-dialog :title="planId ? '编辑保养计划' : '新增保养计划'" :visible.sync="visible" width="850px" :close-on-click-modal="false" @open="onOpen">
    <el-form :model="form" :rules="rules" ref="form" label-width="120px" size="small" v-loading="loading">
      <!-- 基本信息区域 -->
      <div class="section-title">基本信息</div>
      <el-row :gutter="16">
        <el-col :span="12">
          <el-form-item label="计划名称" prop="plan_name"><el-input v-model="form.plan_name" maxlength="100" /></el-form-item>
        </el-col>
        <el-col :span="12">
          <el-form-item label="关联设备" prop="device_id">
            <el-select v-model="form.device_id" filterable remote :remote-method="searchDevices" :loading="deviceLoading" placeholder="搜索选择设备" style="width:100%">
              <el-option v-for="d in deviceOptions" :key="d.id" :label="d.name + '（' + d.device_code + '）'" :value="d.id" />
            </el-select>
          </el-form-item>
        </el-col>
      </el-row>
      <el-row :gutter="16">
        <el-col :span="12">
          <el-form-item label="保养等级" prop="level_id">
            <el-select v-model="form.level_id" placeholder="选择等级" style="width:100%" :disabled="readonlyCore" @change="onLevelChange">
              <el-option v-for="l in levelOptions" :key="l.id" :label="l.level_name" :value="l.id" />
            </el-select>
          </el-form-item>
        </el-col>
        <el-col :span="12">
          <el-form-item label="项目模板">
            <el-select v-model="form.template_id" clearable filterable placeholder="按等级自动筛选" style="width:100%" :disabled="readonlyCore" @change="onTemplateChange">
              <el-option v-for="t in templateOptions" :key="t.id" :label="t.template_name" :value="t.id" />
            </el-select>
          </el-form-item>
        </el-col>
      </el-row>

      <!-- 周期设置区域 -->
      <div class="section-title">周期设置</div>
      <el-row :gutter="16">
        <el-col :span="12">
          <el-form-item label="周期类型" prop="cycle_type">
            <el-select v-model="form.cycle_type" style="width:100%" :disabled="readonlyCore">
              <el-option v-for="o in cycleTypeOptions" :key="o.value" :label="o.label" :value="o.value" />
            </el-select>
          </el-form-item>
        </el-col>
        <el-col :span="12">
          <el-form-item label="周期值" prop="cycle_value">
            <el-input-number v-model="form.cycle_value" :min="1" style="width:100%" :disabled="readonlyCore" />
          </el-form-item>
        </el-col>
      </el-row>
      <el-row :gutter="16">
        <el-col :span="12">
          <el-form-item label="首次保养日期">
            <el-date-picker v-model="form.start_date" type="date" value-format="yyyy-MM-dd" style="width:100%" @change="onStartDateChange" />
          </el-form-item>
        </el-col>
        <el-col :span="12">
          <el-form-item label="下次保养日期">
            <el-input :value="form.next_maintenance_date || '-'" disabled />
          </el-form-item>
        </el-col>
      </el-row>

      <!-- 执行人设置区域 -->
      <div class="section-title">执行人设置</div>
      <el-row :gutter="16">
        <el-col :span="12">
          <el-form-item label="执行人">
            <el-select v-model="form.executor_id" filterable clearable style="width:100%">
              <el-option v-for="u in userOptions" :key="u.id" :label="u.real_name || u.username" :value="u.id" />
            </el-select>
          </el-form-item>
        </el-col>
        <el-col :span="12">
          <el-form-item label="验收人">
            <el-select v-model="form.acceptor_id" filterable clearable style="width:100%">
              <el-option v-for="u in userOptions" :key="u.id" :label="u.real_name || u.username" :value="u.id" />
            </el-select>
          </el-form-item>
        </el-col>
      </el-row>
      <el-row :gutter="16">
        <el-col :span="12">
          <el-form-item label="是否需要审批">
            <el-switch v-model="form.need_approve" :active-value="1" :inactive-value="0" active-text="是" inactive-text="否" />
          </el-form-item>
        </el-col>
      </el-row>

      <!-- 有效期区域 -->
      <div class="section-title">有效期</div>
      <el-row :gutter="16">
        <el-col :span="12">
          <el-form-item label="开始日期"><el-date-picker v-model="form.start_date" type="date" value-format="yyyy-MM-dd" style="width:100%" /></el-form-item>
        </el-col>
        <el-col :span="12">
          <el-form-item label="结束日期"><el-date-picker v-model="form.end_date" type="date" value-format="yyyy-MM-dd" style="width:100%" /></el-form-item>
        </el-col>
      </el-row>

      <!-- 备注 -->
      <el-form-item label="备注"><el-input v-model="form.remark" type="textarea" :rows="2" /></el-form-item>

      <!-- 模板预览区域 -->
      <div v-if="previewItems.length" class="section-title">模板预览</div>
      <template-preview v-if="previewItems.length" :items="previewItems" />
    </el-form>
    <span slot="footer">
      <el-button @click="visible = false">取消</el-button>
      <el-button type="primary" :loading="saving" @click="handleSave">保存</el-button>
    </span>
  </el-dialog>
</template>

<script>
import { getLevelOptions, getTemplateOptions, getTemplateDetail, getPlanDetail, addPlan, editPlan } from '@/api/maintenance'
import { getAssetList } from '@/api/deviceAsset'
import { getUserList } from '@/api/user'
import TemplatePreview from './components/TemplatePreview.vue'

export default {
  name: 'PlanFormDialog',
  components: { TemplatePreview },
  props: {
    visible: Boolean,
    planId: { type: Number, default: 0 },
    readonlyCore: { type: Boolean, default: false }
  },
  data() {
    return {
      loading: false, saving: false, deviceLoading: false,
      levelOptions: [], templateOptions: [], deviceOptions: [], userOptions: [], previewItems: [],
      cycleTypeOptions: [],
      form: {
        plan_name: '', device_id: null, level_id: null, template_id: null,
        cycle_type: 'month', cycle_value: 1, start_date: null, end_date: null,
        next_maintenance_date: null, executor_id: null, acceptor_id: null, need_approve: 1, remark: ''
      },
      rules: {
        plan_name: [{ required: true, message: '请输入计划名称', trigger: 'blur' }],
        device_id: [{ required: true, message: '请选择设备', trigger: 'change' }],
        level_id: [{ required: true, message: '请选择保养等级', trigger: 'change' }],
        cycle_type: [{ required: true, message: '请选择周期类型', trigger: 'change' }],
        cycle_value: [{ required: true, message: '请输入周期值', trigger: 'blur' }]
      }
    }
  },
  methods: {
    async onOpen() {
      this.loadLevelOptions()
      this.loadUsers()
      this.loadDicts()
      this.searchDevices('')
      if (this.planId) {
        this.loading = true
        try { const r = await getPlanDetail(this.planId); if (r.code === 0) { this.fillForm(r.data); this.onLevelChange(this.form.level_id, true) } } catch (e) {}
        this.loading = false
      } else {
        this.resetForm()
      }
    },
    // 周期类型从字典动态加载
    async loadDicts() {
      const { getDictByCode } = await import('../../../../api/dictionary')
      try { const r = await getDictByCode('maintenance_cycle_type'); this.cycleTypeOptions = r.data || [] } catch (e) { this.cycleTypeOptions = [] }
    },
    resetForm() {
      this.form = { plan_name: '', device_id: null, level_id: null, template_id: null, cycle_type: 'month', cycle_value: 1, start_date: null, end_date: null, next_maintenance_date: null, executor_id: null, acceptor_id: null, need_approve: 1, remark: '' }
      this.previewItems = []
    },
    fillForm(d) {
      this.form = {
        plan_name: d.plan_name, device_id: d.device_id, level_id: d.level_id, template_id: d.template_id,
        cycle_type: d.cycle_type, cycle_value: d.cycle_value, start_date: d.start_date, end_date: d.end_date,
        next_maintenance_date: d.next_maintenance_date, executor_id: d.executor_id, acceptor_id: d.acceptor_id,
        need_approve: d.need_approve, remark: d.remark
      }
      if (d.device_id) this.deviceOptions = [{ id: d.device_id, name: d.device_name, device_code: d.device_code }]
      this.previewItems = d.template_items || []
    },
    async loadLevelOptions() { try { const r = await getLevelOptions(); if (r.code === 0) this.levelOptions = r.data || [] } catch (e) {} },
    async loadUsers() { try { const r = await getUserList({ limit: 500 }); if (r.code === 0) this.userOptions = r.data.list || [] } catch (e) {} },
    async searchDevices(kw) {
      this.deviceLoading = true
      try { const r = await getAssetList({ keyword: kw, limit: 20 }); if (r.code === 0) this.deviceOptions = r.data.list || [] } catch (e) {}
      this.deviceLoading = false
    },
    async onLevelChange(levelId, silent) {
      if (!silent) {
        this.form.template_id = null
        this.previewItems = []
      }
      try { const r = await getTemplateOptions({ level_id: levelId }); if (r.code === 0) this.templateOptions = r.data || [] } catch (e) {}
      if (!silent && levelId) this.$message.info('已按等级筛选模板')
    },
    async onTemplateChange(tplId) {
      if (!tplId) { this.previewItems = []; return }
      // 调用详情接口获取模板项目列表用于预览
      try { const r = await getTemplateDetail(tplId); if (r.code === 0) this.previewItems = r.data.items || [] } catch (e) { this.previewItems = [] }
    },
    onStartDateChange(v) { if (v) this.form.next_maintenance_date = v },
    async handleSave() {
      const valid = await this.$refs.form.validate().catch(() => false)
      if (!valid) return
      if (this.form.end_date && this.form.start_date && this.form.end_date < this.form.start_date) {
        return this.$message.warning('结束日期必须晚于开始日期')
      }
      this.saving = true
      try {
        const d = { ...this.form }
        if (this.planId) { const r = await editPlan(this.planId, d); if (r.code === 0) { this.$message.success('更新成功'); this.$emit('saved') } }
        else { const r = await addPlan(d); if (r.code === 0) { this.$message.success('创建成功'); this.$emit('saved') } }
      } catch (e) {}
      this.saving = false
    }
  }
}
</script>

<style scoped>
.section-title { font-weight: 600; margin: 12px 0 8px; padding-left: 8px; border-left: 3px solid #409EFF; }
</style>
