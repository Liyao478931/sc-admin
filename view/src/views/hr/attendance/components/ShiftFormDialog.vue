<template>
  <el-dialog :title="formId ? '编辑班次' : '新增班次'" :visible="visible" @update:visible="$emit('update:visible', $event)" width="800px" top="6vh" :close-on-click-modal="false" @open="onOpen" @closed="reset">
    <el-form ref="form" :model="form" label-width="120px" size="small" :rules="rules">
      <el-tabs v-model="activeTab">
        <!-- 标签页一：基本信息 -->
        <el-tab-pane label="基本信息" name="basic">
          <el-form-item label="班次编码" prop="shift_code">
            <el-input v-model="form.shift_code" placeholder="如 MORNING / NIGHT / SHIFT_01" :disabled="!!formId" maxlength="50" />
          </el-form-item>
          <el-form-item label="班次名称" prop="shift_name">
            <el-input v-model="form.shift_name" placeholder="如 常白班、夜班" maxlength="50" />
          </el-form-item>
          <el-form-item label="班次类别" prop="shift_category">
            <el-radio-group v-model="form.shift_category">
              <el-radio v-for="opt in shiftCategoryOptions" :key="opt.value" :label="opt.value">{{ opt.label }}</el-radio>
            </el-radio-group>
          </el-form-item>
          <el-form-item label="适用部门">
            <el-select v-model="form.department_ids" multiple clearable filterable collapse-tags placeholder="不选则适用于全部部门" style="width:100%">
              <el-option v-for="d in deptOptions" :key="d.id" :label="d.name" :value="d.id" />
            </el-select>
            <div class="flex-tip">不选则适用于全部部门</div>
          </el-form-item>
          <el-form-item label="班次描述">
            <el-input v-model="form.description" placeholder="选填" maxlength="255" />
          </el-form-item>
        </el-tab-pane>

        <!-- 标签页二：工作时间 -->
        <el-tab-pane label="工作时间" name="worktime">
          <el-form-item label="打卡次数">
            <el-select v-model="form.clock_count" style="width:240px">
              <el-option label="2次（上班/下班）" :value="2" />
              <el-option label="4次（上班/下班/上班/下班）" :value="4" />
            </el-select>
          </el-form-item>
          <el-row :gutter="16">
            <el-col :span="12"><el-form-item label="上班时间" prop="start_time">
              <el-time-picker v-model="form.start_time" placeholder="上班时间" format="HH:mm" value-format="HH:mm:ss" style="width:100%" />
            </el-form-item></el-col>
            <template v-if="form.clock_count === 4">
              <el-col :span="12"><el-form-item label="上午下班时间">
                <el-time-picker v-model="form.morning_end_time" placeholder="上午下班" format="HH:mm" value-format="HH:mm:ss" style="width:100%" />
              </el-form-item></el-col>
              <el-col :span="12"><el-form-item label="下午上班时间">
                <el-time-picker v-model="form.afternoon_start_time" placeholder="下午上班" format="HH:mm" value-format="HH:mm:ss" style="width:100%" />
              </el-form-item></el-col>
            </template>
            <el-col :span="12"><el-form-item label="下班时间" prop="end_time">
              <el-time-picker v-model="form.end_time" placeholder="下班时间" format="HH:mm" value-format="HH:mm:ss" style="width:100%" />
            </el-form-item></el-col>
          </el-row>

          <!-- 弹性班次额外字段 -->
          <template v-if="form.shift_category === 'flexible'">
            <div class="flex-title">弹性班次设置</div>
            <el-row :gutter="16">
              <el-col :span="12"><el-form-item label="弹性开始时间"><el-time-picker v-model="form.flex_start" placeholder="最早打卡" format="HH:mm" value-format="HH:mm:ss" style="width:100%" /></el-form-item></el-col>
              <el-col :span="12"><el-form-item label="弹性结束时间"><el-time-picker v-model="form.flex_end" placeholder="最晚打卡" format="HH:mm" value-format="HH:mm:ss" style="width:100%" /></el-form-item></el-col>
              <el-col :span="12"><el-form-item label="核心开始时间"><el-time-picker v-model="form.flex_core_start" placeholder="核心工作开始" format="HH:mm" value-format="HH:mm:ss" style="width:100%" /></el-form-item></el-col>
              <el-col :span="12"><el-form-item label="核心结束时间"><el-time-picker v-model="form.flex_core_end" placeholder="核心工作结束" format="HH:mm" value-format="HH:mm:ss" style="width:100%" /></el-form-item></el-col>
              <el-col :span="12"><el-form-item label="每日总工时要求"><el-input-number v-model="form.flex_daily_hours" :min="0" :max="24" :precision="2" style="width:100%" /></el-form-item></el-col>
            </el-row>
            <div class="flex-tip">弹性顺序：弹性开始 &lt; 核心开始 &lt; 核心结束 &lt; 弹性结束</div>
          </template>
        </el-tab-pane>

        <!-- 标签页三：考勤规则 -->
        <el-tab-pane label="考勤规则" name="rules">
          <div class="rule-group">打卡规则</div>
          <el-form-item label="打卡有效时间">
            <el-input-number v-model="form.punch_valid_minutes" :min="0" :max="600" /> <span class="inline-tip">分钟（上班可提前、下班可延后 N 分钟内打卡有效）</span>
          </el-form-item>

          <div class="rule-group">迟到规则</div>
          <el-row :gutter="16">
            <el-col :span="12"><el-form-item label="允许迟到分钟数"><el-input-number v-model="form.late_minutes" :min="0" :max="600" style="width:100%" /></el-form-item></el-col>
            <el-col :span="12"><el-form-item label="扣款方式">
              <el-select v-model="form.late_deduction_type" style="width:100%"><el-option v-for="opt in deductionTypeOptions" :key="opt.value" :label="opt.label" :value="opt.value" /></el-select>
            </el-form-item></el-col>
          </el-row>
          <div class="rule-group">早退规则</div>
          <el-row :gutter="16">
            <el-col :span="12"><el-form-item label="允许早退分钟数"><el-input-number v-model="form.early_minutes" :min="0" :max="600" style="width:100%" /></el-form-item></el-col>
            <el-col :span="12"><el-form-item label="扣款方式">
              <el-select v-model="form.early_deduction_type" style="width:100%"><el-option v-for="opt in deductionTypeOptions" :key="opt.value" :label="opt.label" :value="opt.value" /></el-select>
            </el-form-item></el-col>
          </el-row>
          <el-form-item label="旷工判定">
            <el-input-number v-model="form.absent_minutes" :min="0" :max="600" /> <span class="inline-tip">迟到/早退超过该分钟数计旷工</span>
          </el-form-item>

          <div class="rule-group">加班计算规则</div>
          <el-row :gutter="16" v-for="o in overtimeGroups" :key="o.key">
            <el-col :span="8"><el-form-item :label="o.label + '开始'"><el-time-picker v-model="form[o.start]" format="HH:mm" value-format="HH:mm:ss" style="width:100%" /></el-form-item></el-col>
            <el-col :span="8"><el-form-item :label="o.label + '结束'"><el-time-picker v-model="form[o.end]" format="HH:mm" value-format="HH:mm:ss" style="width:100%" /></el-form-item></el-col>
            <el-col :span="8"><el-form-item :label="o.label + '倍率'">
              <el-select v-model="form[o.rate]" style="width:100%"><el-option v-for="r in o.rates" :key="r" :label="r + '倍'" :value="r" /></el-select>
            </el-form-item></el-col>
          </el-row>

          <el-form-item label="排序"><el-input-number v-model="form.sort" :min="0" /></el-form-item>
          <el-form-item label="状态"><el-switch v-model="form.status" :active-value="1" :inactive-value="0" active-text="启用" inactive-text="停用" /></el-form-item>
        </el-tab-pane>
      </el-tabs>
    </el-form>

    <span slot="footer">
      <el-button size="small" @click="$emit('update:visible', false)">取消</el-button>
      <el-button size="small" type="primary" :loading="saving" @click="submit">提交</el-button>
    </span>
  </el-dialog>
</template>

<script>
import { getShiftDetail, addShift, editShift } from '@/api/attendanceShift'
import { getDeptTree } from '@/api/organization'

function flattenDept (nodes) {
  let r = []
  for (const n of nodes || []) { r.push(n); if (n.children) r = r.concat(flattenDept(n.children)) }
  return r
}

const defaultForm = () => ({
  shift_code: '', shift_name: '', shift_category: 'fixed', description: '',
  department_ids: [],
  start_time: '', end_time: '', morning_end_time: '', afternoon_start_time: '', clock_count: 2, punch_valid_minutes: 30,
  late_minutes: 0, late_deduction_type: 'minute',
  early_minutes: 0, early_deduction_type: 'minute', absent_minutes: 30,
  overtime_weekday_start: '', overtime_weekday_end: '', overtime_weekday_rate: 1.5,
  overtime_weekend_start: '', overtime_weekend_end: '', overtime_weekend_rate: 2,
  overtime_holiday_start: '', overtime_holiday_end: '', overtime_holiday_rate: 3,
  flex_core_start: '', flex_core_end: '', flex_start: '', flex_end: '', flex_daily_hours: null,
  sort: 0, status: 1
})

export default {
  name: 'ShiftFormDialog',
  props: { visible: { type: Boolean, default: false }, formId: { type: Number, default: 0 } },
  data () {
    return {
      activeTab: 'basic',
      saving: false,
      form: defaultForm(),
      deptOptions: [],
      shiftCategoryOptions: [], deductionTypeOptions: [],
      overtimeGroups: [
        { key: 'weekday', label: '工作日加班', start: 'overtime_weekday_start', end: 'overtime_weekday_end', rate: 'overtime_weekday_rate', rates: [1.5, 2] },
        { key: 'weekend', label: '周末加班', start: 'overtime_weekend_start', end: 'overtime_weekend_end', rate: 'overtime_weekend_rate', rates: [2] },
        { key: 'holiday', label: '节假日加班', start: 'overtime_holiday_start', end: 'overtime_holiday_end', rate: 'overtime_holiday_rate', rates: [3] }
      ],
      rules: {
        shift_code: [{ required: true, message: '请输入班次编码', trigger: 'blur' }],
        shift_name: [{ required: true, message: '请输入班次名称', trigger: 'blur' }],
        shift_category: [{ required: true, message: '请选择班次类别', trigger: 'change' }],
        start_time: [{ required: true, message: '请选择上班时间', trigger: 'change' }],
        end_time: [{ required: true, message: '请选择下班时间', trigger: 'change' }]
      }
    }
  },
  methods: {
    async loadDepts () {
      try {
        const r = await getDeptTree()
        if (r.code === 0) this.deptOptions = flattenDept(r.data || []).map(d => ({ id: d.id, name: d.name }))
      } catch (e) {}
    },
    // 班次类别/扣款方式从字典动态加载
    async loadDicts () {
      const { getDictByCode } = await import('../../../../api/dictionary')
      try { const r = await getDictByCode('attendance_shift_category'); this.shiftCategoryOptions = r.data || [] } catch (e) { this.shiftCategoryOptions = [] }
      try { const r = await getDictByCode('attendance_late_deduction_type'); this.deductionTypeOptions = r.data || [] } catch (e) { this.deductionTypeOptions = [] }
    },
    async onOpen () {
      this.loadDepts()
      this.loadDicts()
      if (this.formId) {
        try {
          const r = await getShiftDetail(this.formId)
          if (r.code === 0) {
            const d = r.data || {}
            this.form = {
              shift_code: d.shift_code || '', shift_name: d.shift_name || '', shift_category: d.shift_category || 'fixed', description: d.description || '',
              department_ids: Array.isArray(d.department_ids) ? d.department_ids : [],
              start_time: d.start_time || '', end_time: d.end_time || '', morning_end_time: d.morning_end_time || '', afternoon_start_time: d.afternoon_start_time || '', clock_count: d.clock_count || 2, punch_valid_minutes: d.punch_valid_minutes === undefined ? 30 : d.punch_valid_minutes,
              late_minutes: d.late_minutes || 0, late_deduction_type: d.late_deduction_type || 'minute',
              early_minutes: d.early_minutes || 0, early_deduction_type: d.early_deduction_type || 'minute', absent_minutes: d.absent_minutes || 30,
              overtime_weekday_start: d.overtime_weekday_start || '', overtime_weekday_end: d.overtime_weekday_end || '', overtime_weekday_rate: Number(d.overtime_weekday_rate || 1.5),
              overtime_weekend_start: d.overtime_weekend_start || '', overtime_weekend_end: d.overtime_weekend_end || '', overtime_weekend_rate: Number(d.overtime_weekend_rate || 2),
              overtime_holiday_start: d.overtime_holiday_start || '', overtime_holiday_end: d.overtime_holiday_end || '', overtime_holiday_rate: Number(d.overtime_holiday_rate || 3),
              flex_core_start: d.flex_core_start || '', flex_core_end: d.flex_core_end || '', flex_start: d.flex_start || '', flex_end: d.flex_end || '', flex_daily_hours: d.flex_daily_hours,
              sort: d.sort || 0, status: d.status === 0 ? 0 : 1
            }
          }
        } catch (e) {}
      }
    },
    reset () {
      this.form = defaultForm()
      this.activeTab = 'basic'
      this.$refs.form && this.$refs.form.clearValidate()
    },
    submit () {
      this.$refs.form.validate(async (ok) => {
        if (!ok) return
        this.saving = true
        try {
          const d = { ...this.form }
          // 空字符串时间字段转 null
          ;['morning_end_time', 'afternoon_start_time', 'overtime_weekday_start', 'overtime_weekday_end', 'overtime_weekend_start', 'overtime_weekend_end', 'overtime_holiday_start', 'overtime_holiday_end', 'flex_core_start', 'flex_core_end', 'flex_start', 'flex_end'].forEach(k => { if (d[k] === '') d[k] = null })
          if (d.flex_daily_hours === null || d.flex_daily_hours === '') d.flex_daily_hours = null
          const r = this.formId ? await editShift(this.formId, d) : await addShift(d)
          if (r.code === 0) {
            this.$message.success('保存成功')
            this.$emit('saved')
          }
        } catch (e) {} finally { this.saving = false }
      })
    }
  }
}
</script>

<style scoped>
.flex-title, .rule-group { font-size: 13px; font-weight: 600; color: #303133; border-left: 3px solid #409EFF; padding-left: 8px; margin: 6px 0 10px; }
.flex-tip, .inline-tip { font-size: 12px; color: #909399; }
</style>
