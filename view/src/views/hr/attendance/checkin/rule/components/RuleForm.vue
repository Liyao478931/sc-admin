<template>
  <el-dialog :title="ruleId ? '编辑打卡规则' : '新增打卡规则'" :visible.sync="visible" width="750px" :close-on-click-modal="false" @closed="reset">
    <el-form ref="formRef" :model="form" :rules="rules" label-width="100px" size="small">
      <!-- 基础信息 -->
      <el-row :gutter="12">
        <el-col :span="14">
          <el-form-item label="规则名称" prop="rule_name">
            <el-input v-model="form.rule_name" placeholder="请输入规则名称" maxlength="100" />
          </el-form-item>
        </el-col>
        <el-col :span="10">
          <el-form-item label="规则类型">
            <el-radio-group v-model="form.rule_type">
              <el-radio :label="0">默认规则</el-radio>
              <el-radio :label="1">自定义规则</el-radio>
            </el-radio-group>
          </el-form-item>
        </el-col>
      </el-row>
      <el-form-item label="关联部门">
        <el-select v-model="form.department_ids" multiple filterable collapse-tags clearable placeholder="留空表示全部部门" style="width:100%">
          <el-option v-for="d in deptOptions" :key="d.id" :label="d.name" :value="d.id" />
        </el-select>
        <div class="form-hint">仅选中的部门员工适用此规则，留空 = 全部部门</div>
      </el-form-item>

      <!-- 打卡次数 -->
      <el-form-item label="每日打卡次数">
        <el-radio-group v-model="form.checkin_count">
          <el-radio :label="1">1次</el-radio>
          <el-radio :label="2">2次</el-radio>
          <el-radio :label="4">4次</el-radio>
        </el-radio-group>
      </el-form-item>

      <!-- 打卡时间 -->
      <el-form-item label="打卡时间">
        <!-- 1次 -->
        <template v-if="form.checkin_count === 1">
          <el-time-picker v-model="form.morning_start" format="HH:mm" value-format="HH:mm" placeholder="打卡时间" style="width:140px" />
        </template>
        <!-- 2次 -->
        <template v-else-if="form.checkin_count === 2">
          <span class="time-label">上班</span>
          <el-time-picker v-model="form.morning_start" format="HH:mm" value-format="HH:mm" placeholder="上班时间" style="width:130px" />
          <span class="time-sep">至</span>
          <span class="time-label">下班</span>
          <el-time-picker v-model="form.afternoon_end" format="HH:mm" value-format="HH:mm" placeholder="下班时间" style="width:130px" />
        </template>
        <!-- 4次 -->
        <template v-else>
          <div class="time-grid">
            <div class="time-item"><span class="time-label">上午上班</span><el-time-picker v-model="form.morning_start" format="HH:mm" value-format="HH:mm" style="width:130px" /></div>
            <div class="time-item"><span class="time-label">上午下班</span><el-time-picker v-model="form.morning_end" format="HH:mm" value-format="HH:mm" style="width:130px" /></div>
            <div class="time-item"><span class="time-label">下午上班</span><el-time-picker v-model="form.afternoon_start" format="HH:mm" value-format="HH:mm" style="width:130px" /></div>
            <div class="time-item"><span class="time-label">下午下班</span><el-time-picker v-model="form.afternoon_end" format="HH:mm" value-format="HH:mm" style="width:130px" /></div>
          </div>
        </template>
      </el-form-item>

      <!-- 时间范围 -->
      <el-row :gutter="12">
        <el-col :span="12">
          <el-form-item label="可提前打卡">
            <el-input-number v-model="form.advance_minutes" :min="0" :max="120" :step="5" style="width:100%" />
            <span class="unit">分钟</span>
          </el-form-item>
        </el-col>
        <el-col :span="12">
          <el-form-item label="可延迟打卡">
            <el-input-number v-model="form.delay_minutes" :min="0" :max="120" :step="5" style="width:100%" />
            <span class="unit">分钟</span>
          </el-form-item>
        </el-col>
      </el-row>
      <el-row :gutter="12">
        <el-col :span="12">
          <el-form-item label="迟到宽限">
            <el-input-number v-model="form.grace_late_minutes" :min="0" :max="30" :step="1" style="width:100%" />
            <span class="unit">分钟</span>
          </el-form-item>
        </el-col>
        <el-col :span="12">
          <el-form-item label="早退宽限">
            <el-input-number v-model="form.grace_early_minutes" :min="0" :max="30" :step="1" style="width:100%" />
            <span class="unit">分钟</span>
          </el-form-item>
        </el-col>
      </el-row>

      <!-- 适用工作日 -->
      <el-form-item label="适用工作日">
        <el-checkbox-group v-model="form.weekdays">
          <el-checkbox v-for="w in weekOptions" :key="w.value" :label="w.value">{{ w.label }}</el-checkbox>
        </el-checkbox-group>
      </el-form-item>

      <!-- 状态 -->
      <el-form-item label="状态">
        <el-radio-group v-model="form.status">
          <el-radio :label="1">启用</el-radio>
          <el-radio :label="0">停用</el-radio>
        </el-radio-group>
      </el-form-item>
    </el-form>

    <span slot="footer">
      <el-button size="small" @click="visible = false">取消</el-button>
      <el-button size="small" type="primary" :loading="saving" @click="save">保存</el-button>
    </span>
  </el-dialog>
</template>

<script>
import { createRule, updateRule, getRuleDetail } from '@/api/attendanceRule'
import { getDeptTree } from '@/api/organization'

function flattenDept (nodes) {
  let r = []
  for (const n of nodes || []) { r.push(n); if (n.children) r = r.concat(flattenDept(n.children)) }
  return r
}

export default {
  name: 'RuleForm',
  props: {
    visible: { type: Boolean, default: false },
    ruleId: { type: Number, default: 0 }
  },
  data () {
    return {
      form: {
        id: 0, rule_name: '', rule_type: 0, department_ids: [], checkin_count: 2,
        morning_start: '08:00', morning_end: '12:00', afternoon_start: '13:30', afternoon_end: '18:00',
        advance_minutes: 30, delay_minutes: 30, grace_late_minutes: 5, grace_early_minutes: 5,
        weekdays: [1, 2, 3, 4, 5], status: 1
      },
      weekOptions: [
        { label: '周一', value: 1 }, { label: '周二', value: 2 }, { label: '周三', value: 3 },
        { label: '周四', value: 4 }, { label: '周五', value: 5 }, { label: '周六', value: 6 }, { label: '周日', value: 7 }
      ],
      deptOptions: [],
      rules: {
        rule_name: [{ required: true, message: '请输入规则名称', trigger: 'blur' }]
      },
      saving: false
    }
  },
  watch: {
    visible (v) {
      if (v) {
        if (this.ruleId) this.loadDetail()
      }
    }
  },
  created () {
    // 组件挂载即加载部门（父组件 v-if 挂载时 watch.visible 不触发，必须在 created 加载）
    this.loadDepts()
    // 编辑模式：首次挂载直接加载详情（ruleId prop 已就绪）
    if (this.ruleId) this.loadDetail()
  },
  methods: {
    async loadDepts () {
      try {
        const r = await getDeptTree()
        if (r.code === 0) this.deptOptions = flattenDept(r.data || []).map(d => ({ id: d.id, name: d.name }))
      } catch (e) {}
    },
    async loadDetail () {
      try {
        const r = await getRuleDetail(this.ruleId)
        if (r.code === 0 && r.data) {
          const d = r.data
          const hm = (t) => t ? String(t).slice(0, 5) : ''
          this.form = {
            id: d.id, rule_name: d.rule_name, rule_type: Number(d.rule_type) || 0,
            department_ids: d.department_ids || [], checkin_count: Number(d.checkin_count) || 2,
            morning_start: hm(d.morning_start), morning_end: hm(d.morning_end),
            afternoon_start: hm(d.afternoon_start), afternoon_end: hm(d.afternoon_end),
            advance_minutes: Number(d.advance_minutes) || 30, delay_minutes: Number(d.delay_minutes) || 30,
            grace_late_minutes: Number(d.grace_late_minutes) || 5, grace_early_minutes: Number(d.grace_early_minutes) || 5,
            weekdays: d.weekdays || [1, 2, 3, 4, 5], status: Number(d.status) === 0 ? 0 : 1
          }
        }
      } catch (e) {}
    },
    save () {
      this.$refs.formRef.validate(async (valid) => {
        if (!valid) return
        if (!this.form.weekdays.length) { this.$message.warning('请至少选择一个适用工作日'); return }
        this.saving = true
        try {
          const data = {
            rule_name: this.form.rule_name, rule_type: this.form.rule_type,
            department_ids: this.form.department_ids || [], checkin_count: this.form.checkin_count,
            morning_start: this.form.morning_start, morning_end: this.form.morning_end,
            afternoon_start: this.form.afternoon_start, afternoon_end: this.form.afternoon_end,
            advance_minutes: this.form.advance_minutes, delay_minutes: this.form.delay_minutes,
            grace_late_minutes: this.form.grace_late_minutes, grace_early_minutes: this.form.grace_early_minutes,
            weekdays: this.form.weekdays, status: this.form.status
          }
          const r = this.form.id ? await updateRule(this.form.id, data) : await createRule(data)
          if (r.code === 0) {
            this.$message.success(r.msg || '保存成功')
            this.visible = false
            this.$emit('saved')
          } else {
            this.$message.error(r.msg || '保存失败')
          }
        } catch (e) {
          this.$message.error('请求失败')
        } finally {
          this.saving = false
        }
      })
    },
    reset () {
      this.form = {
        id: 0, rule_name: '', rule_type: 0, department_ids: [], checkin_count: 2,
        morning_start: '08:00', morning_end: '12:00', afternoon_start: '13:30', afternoon_end: '18:00',
        advance_minutes: 30, delay_minutes: 30, grace_late_minutes: 5, grace_early_minutes: 5,
        weekdays: [1, 2, 3, 4, 5], status: 1
      }
    }
  }
}
</script>

<style scoped>
.form-hint { font-size: 12px; color: #c0c4cc; margin-top: 4px; }
.time-label { color: #606266; font-size: 13px; margin-right: 6px; }
.time-sep { margin: 0 10px; color: #909399; }
.time-grid { display: flex; flex-wrap: wrap; gap: 10px; width: 100%; }
.time-item { display: flex; align-items: center; gap: 6px; }
.time-item .time-label { width: 60px; }
.unit { margin-left: 6px; color: #909399; font-size: 12px; }
</style>
