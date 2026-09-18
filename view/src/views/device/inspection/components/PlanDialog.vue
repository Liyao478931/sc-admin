<template>
  <el-dialog :title="mode === 'add' ? '新增巡检计划' : '编辑巡检计划'" :visible.sync="dialogVisible" width="800px" @open="handleOpen" @closed="resetForm">
    <el-form ref="form" :model="form" :rules="rules" label-width="110px" size="small">
      <el-divider content-position="left">基本信息</el-divider>
      <el-row :gutter="16">
        <el-col :span="12">
          <el-form-item label="计划名称" prop="plan_name"><el-input v-model="form.plan_name" maxlength="100" placeholder="请输入计划名称" /></el-form-item>
        </el-col>
        <el-col :span="12">
          <el-form-item label="计划类型" prop="plan_type">
            <el-select v-model="form.plan_type" style="width:100%">
              <el-option v-for="t in planTypeOptions" :key="t.value" :label="t.label" :value="t.value" />
            </el-select>
          </el-form-item>
        </el-col>
        <el-col :span="12">
          <el-form-item label="状态">
            <el-select v-model="form.status" style="width:100%">
              <el-option v-for="s in statusOptions" :key="s.value" :label="s.label" :value="s.value" />
            </el-select>
          </el-form-item>
        </el-col>
        <el-col :span="12">
          <el-form-item label="内容模板">
            <el-select v-model="form.template_id" clearable filterable style="width:100%" @change="onTemplateChange">
              <el-option v-for="t in templateOptions" :key="t.id" :label="t.template_name" :value="t.id" />
            </el-select>
          </el-form-item>
        </el-col>
      </el-row>

      <el-divider content-position="left">目标设置</el-divider>
      <el-row :gutter="16">
        <el-col :span="12">
          <el-form-item label="目标类型">
            <el-radio-group v-model="form.target_type">
              <el-radio label="device">按设备</el-radio>
              <el-radio label="device_type">按设备类型</el-radio>
            </el-radio-group>
          </el-form-item>
        </el-col>
        <el-col :span="12">
          <el-form-item v-if="form.target_type === 'device'" label="选择设备">
            <el-select v-model="form.target_ids" multiple filterable style="width:100%">
              <el-option v-for="d in deviceOptions" :key="d.id" :label="`${d.device_code}-${d.name}`" :value="d.id" />
            </el-select>
          </el-form-item>
          <el-form-item v-else label="设备类型">
            <el-select v-model="form.target_ids" multiple filterable style="width:100%">
              <el-option v-for="c in categoryOptions" :key="c.id" :label="c.name" :value="c.id" />
            </el-select>
          </el-form-item>
        </el-col>
      </el-row>

      <el-divider content-position="left">执行人设置</el-divider>
      <el-form-item label="执行人">
        <el-select v-model="form.executor_ids" multiple filterable style="width:100%">
          <el-option v-for="m in managerList" :key="m.id" :label="m.name" :value="m.id" />
        </el-select>
      </el-form-item>

      <el-divider content-position="left">频率设置</el-divider>
      <el-row :gutter="16">
        <el-col :span="12">
          <el-form-item label="频率类型">
            <el-select v-model="form.frequency_type" style="width:100%">
              <el-option v-for="f in freqOptions" :key="f.value" :label="f.label" :value="f.value" />
            </el-select>
          </el-form-item>
        </el-col>
        <el-col :span="12">
          <el-form-item label="频率值">
            <el-input v-model="form.frequency_value" placeholder="如：周一/每月1号" maxlength="50" />
          </el-form-item>
        </el-col>
        <el-col :span="12">
          <el-form-item label="开始日期"><el-date-picker v-model="form.start_date" type="date" value-format="yyyy-MM-dd" style="width:100%" /></el-form-item>
        </el-col>
        <el-col :span="12">
          <el-form-item label="结束日期"><el-date-picker v-model="form.end_date" type="date" value-format="yyyy-MM-dd" style="width:100%" /></el-form-item>
        </el-col>
        <el-col :span="24">
          <el-form-item label="备注"><el-input v-model="form.remark" type="textarea" :rows="2" /></el-form-item>
        </el-col>
      </el-row>
    </el-form>
    <div slot="footer">
      <el-button size="small" @click="dialogVisible = false">取消</el-button>
      <el-button size="small" type="primary" :loading="submitting" @click="submit">确认提交</el-button>
    </div>
  </el-dialog>
</template>

<script>
import { addPlan, editPlan, getPlanDetail, getTemplateOptions } from '@/api/deviceInspection'
import { getAssetList } from '@/api/deviceAsset'
import { getCategoryTree } from '@/api/deviceCategory'
import { getManagers } from '@/api/deviceAsset'
import { getDictionaryBatch } from '@/utils/dict'

export default {
  name: 'InspectionPlanDialog',
  props: {
    visible: Boolean,
    mode: { type: String, default: 'add' },
    planId: { type: Number, default: 0 }
  },
  data() {
    return {
      dialogVisible: this.visible,
      submitting: false,
      planTypeOptions: [],
      freqOptions: [],
      statusOptions: [],
      templateOptions: [],
      deviceOptions: [],
      categoryOptions: [],
      managerList: [],
      form: this.emptyForm(),
      rules: {
        plan_name: [{ required: true, message: '请输入计划名称', trigger: 'blur' }],
        plan_type: [{ required: true, message: '请选择计划类型', trigger: 'change' }]
      }
    }
  },
  watch: {
    visible(val) { this.dialogVisible = val; if (val) this.loadDicts() }
  },
methods: {
  // 周期/状态从字典动态加载
  async loadDicts() {
    const { getDictByCode } = await import('../../../../api/dictionary')
    try { const r = await getDictByCode('inspection_cycle_type'); this.freqOptions = r.data || [] } catch (e) { this.freqOptions = [] }
    try { const r = await getDictByCode('plan_status'); this.statusOptions = r.data || [] } catch (e) { this.statusOptions = [] }
  },
  emptyForm() {
      return {
        plan_name: '', plan_type: 'periodic', status: 'active', template_id: null,
        target_type: 'device', target_ids: [], executor_ids: [], frequency_type: 'weekly',
        frequency_value: '', start_date: null, end_date: null, remark: ''
      }
    },
    async handleOpen() {
      this.form = this.emptyForm()
      try {
        const dict = await getDictionaryBatch(['inspection_plan_type'])
        this.planTypeOptions = dict['inspection_plan_type'] || []
        const [tpl, dev, cat, mgr] = await Promise.all([getTemplateOptions(), getAssetList({ page: 1, limit: 100 }), getCategoryTree({ all: 1 }), getManagers()])
        this.templateOptions = tpl.data || []
        this.deviceOptions = (dev.data && dev.data.list) || []
        this.categoryOptions = this.flattenCat((cat.data && cat.data.list) || [])
        this.managerList = mgr.data || []
      } catch (e) {}
      if (this.mode === 'edit' && this.planId) await this.loadDetail(this.planId)
    },
    flattenCat(nodes, arr = []) {
      (nodes || []).forEach(n => { arr.push({ id: n.id, name: n.name }); if (n.children && n.children.length) this.flattenCat(n.children, arr) })
      return arr
    },
    resetForm() { this.$refs.form && this.$refs.form.clearValidate() },
    async loadDetail(id) {
      try {
        const res = await getPlanDetail(id)
        if (res.code !== 0) return
        const d = res.data
        this.form = {
          plan_name: d.plan_name, plan_type: d.plan_type, status: d.status, template_id: d.template_id,
          target_type: d.target_type, target_ids: String(d.target_ids || '').split(',').map(Number).filter(Boolean),
          executor_ids: String(d.executor_ids || '').split(',').map(Number).filter(Boolean),
          frequency_type: d.frequency_type || 'weekly', frequency_value: d.frequency_value || '',
          start_date: d.start_date || null, end_date: d.end_date || null, remark: d.remark || ''
        }
      } catch (e) {}
    },
    onTemplateChange(id) { /* 预览可扩展 */ },
    submit() {
      this.$refs.form.validate(async (valid) => {
        if (!valid) return
        if (!this.form.target_ids.length) { this.$message.warning('请选择目标设备或设备类型'); return }
        if (!this.form.executor_ids.length) { this.$message.warning('请选择执行人'); return }
        this.submitting = true
        try {
          const payload = { ...this.form }
          if (this.mode === 'add') { await addPlan(payload); this.$message.success('创建成功') }
          else { await editPlan(this.planId, payload); this.$message.success('更新成功') }
          this.$emit('saved')
          this.dialogVisible = false
        } catch (e) { /* 拦截器已提示 */ }
        this.submitting = false
      })
    }
  }
}
</script>
