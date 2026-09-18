<!--
  文件：admin/src/views/hr/assessment/template/components/IndicatorEditDialog.vue
  功能：指标编辑弹窗（基本信息 + 数据源配置 + 扣分规则可视化配置）
-->
<template>
  <el-dialog :title="dialogTitle" :visible.sync="visibleSync" width="720px" top="4vh" :close-on-click-modal="false" @closed="onClosed">
    <el-form :model="form" label-width="110px" size="small">
      <el-divider content-position="left">基本信息</el-divider>
      <el-row :gutter="16">
        <el-col :span="12">
          <el-form-item label="指标名称" required>
            <el-input v-model="form.name" placeholder="如：迟到早退" maxlength="100" />
          </el-form-item>
        </el-col>
        <el-col :span="12">
          <el-form-item label="所属大类">
            <el-select v-model="form.category" style="width:100%" clearable placeholder="选择大类">
              <el-option v-for="c in LIB_CATEGORIES" :key="c" :label="c" :value="c" />
            </el-select>
          </el-form-item>
        </el-col>
      </el-row>
      <el-row :gutter="16">
        <el-col :span="12">
          <el-form-item label="所属分组">
            <el-select v-model="form.parent_id" style="width:100%">
              <el-option label="顶级（无分组）" :value="0" />
              <el-option v-for="g in parentOptions" :key="g.id" :label="g.label" :value="g.id" />
            </el-select>
          </el-form-item>
        </el-col>
        <el-col :span="12">
          <el-form-item label="分值" required>
            <el-input-number v-model="form.score" :min="0" :precision="2" :step="1" style="width:100%" />
          </el-form-item>
        </el-col>
      </el-row>
      <el-form-item label="评分类型">
        <el-radio-group v-model="form.scoring_type">
          <el-radio :label="1">扣分制</el-radio>
          <el-radio :label="2">加分制</el-radio>
          <el-radio :label="3">等级制</el-radio>
        </el-radio-group>
      </el-form-item>

      <el-divider content-position="left">数据源配置</el-divider>
      <el-form-item label="数据来源">
        <el-radio-group v-model="form.data_source_mode">
          <el-radio label="manual">手动录入</el-radio>
          <el-radio label="auto">自动取数</el-radio>
        </el-radio-group>
      </el-form-item>
      <template v-if="form.data_source_mode === 'auto'">
        <el-row :gutter="16">
          <el-col :span="12">
            <el-form-item label="数据源">
              <el-select v-model="form.data_source" style="width:100%" placeholder="选择数据源">
                <el-option v-for="(t, v) in DATA_SOURCES" :key="v" :label="t" :value="v" />
              </el-select>
            </el-form-item>
          </el-col>
        </el-row>
        <el-form-item label="取数条件">
          <el-input v-model="form.data_source_config" type="textarea" :rows="3" placeholder='{"table":"attendance_record","date_field":"work_date","employee_id_field":"employee_id","count_field":"id"}' />
          <div class="form-tip">JSON 格式，用于系统自动取数扣分</div>
        </el-form-item>
      </template>

      <el-divider content-position="left">扣分规则配置</el-divider>
      <el-form-item label="扣分方式">
        <el-radio-group v-model="form.deduct_mode" :disabled="form.scoring_type !== 1">
          <el-radio-button label="by_count">按次数扣分</el-radio-button>
          <el-radio-button label="by_ratio">按比例扣分</el-radio-button>
          <el-radio-button label="fixed">固定扣分</el-radio-button>
          <el-radio-button label="grade">等级折算</el-radio-button>
        </el-radio-group>
        <div v-if="form.scoring_type !== 1" class="form-tip">仅「扣分制」支持自动扣分规则，加分制/等级制请使用对应配置</div>
      </el-form-item>

      <!-- 按次数扣分：条件构建器 -->
      <template v-if="form.deduct_mode === 'by_count'">
        <div class="cond-list">
          <div v-for="(c, idx) in form.conditions" :key="idx" class="cond-row">
            <el-input v-model="c.field" size="mini" placeholder="字段名" class="cond-field" />
            <el-select v-model="c.operator" size="mini" class="cond-op">
              <el-option v-for="(t, v) in OPERATORS" :key="v" :label="t" :value="v" />
            </el-select>
            <el-input v-model="c.value" size="mini" placeholder="值" class="cond-value" />
            <span class="cond-label">每单位扣</span>
            <el-input-number v-model="c.deduct_per_unit" size="mini" :min="0" :precision="2" :controls="false" class="cond-num" />
            <span class="cond-label">上限</span>
            <el-input-number v-model="c.max_deduct" size="mini" :min="0" :precision="2" :controls="false" class="cond-num" />
            <el-button size="mini" icon="el-icon-delete" class="danger" circle @click="removeCondition(idx)" />
          </div>
          <el-button size="mini" icon="el-icon-plus" @click="addCondition">添加条件</el-button>
          <div class="form-tip">满足任一条件即触发扣分（或关系）</div>
        </div>
      </template>

      <!-- 按比例扣分 -->
      <template v-if="form.deduct_mode === 'by_ratio'">
        <el-form-item label="达标线">
          <el-input-number v-model="form.ratio_value" :min="0" :max="100" :precision="2" /> %
          <div class="form-tip">实际得分低于达标线时，按比例扣分（比例 0-100）</div>
        </el-form-item>
      </template>

      <!-- 固定扣分 -->
      <template v-if="form.deduct_mode === 'fixed'">
        <el-form-item label="每次扣分">
          <el-input-number v-model="form.fixed_deduct" :min="0" :precision="2" /> 分
        </el-form-item>
      </template>

      <!-- 等级折算 -->
      <template v-if="form.deduct_mode === 'grade'">
        <el-row :gutter="16">
          <el-col :span="6" v-for="g in GRADE_KEYS" :key="g.key">
            <el-form-item :label="g.label">
              <el-input-number v-model="form.grade[g.key]" :min="0" :precision="2" :controls="false" style="width:100%" />
            </el-form-item>
          </el-col>
        </el-row>
      </template>

      <el-form-item label="触发阈值">
        <el-input-number v-model="form.threshold" :min="0" :precision="0" /> 次
        <div class="form-tip">达到该次数才开始扣分，低于此值不扣分（容错）</div>
      </el-form-item>
      <el-form-item label="扣分原因模板">
        <el-input v-model="form.remark_template" placeholder="如：迟到&#123;&#123;count&#125;&#125;次，扣&#123;&#123;deduct&#125;&#125;分" />
        <div class="form-tip">支持变量：count（次数）、deduct（扣分）、score（分数），如「迟到&#123;&#123;count&#125;&#125;次，扣&#123;&#123;deduct&#125;&#125;分」由系统自动替换</div>
      </el-form-item>
    </el-form>
    <div slot="footer">
      <el-button size="small" @click="visibleSync = false">取消</el-button>
      <el-button size="small" type="primary" :loading="saving" @click="doSave">保存</el-button>
    </div>
  </el-dialog>
</template>

<script>
const LIB_CATEGORIES = ['履职情况', '公共量化指标', '安全', '纪律行为规范']
const DATA_SOURCES = {
  attendance: '考勤打卡', production: '生产工单', quality: '质检', maintenance: '设备保养',
  training: '培训管理', exam: '考试', safety: '安全检查', manual: '手动录入'
}
const OPERATORS = { eq: '等于', gt: '大于', lt: '小于', contains: '包含', ne: '不等于' }
const GRADE_KEYS = [
  { key: 'a', label: 'A 级' }, { key: 'b', label: 'B 级' },
  { key: 'c', label: 'C 级' }, { key: 'd', label: 'D 级' }
]

function emptyForm () {
  return {
    id: 0, name: '', category: '', parent_id: 0, score: 0, scoring_type: 1,
    data_source_mode: 'manual', data_source: '', data_source_config: '',
    deduct_mode: 'by_count', conditions: [], ratio_value: 90, fixed_deduct: 0,
    grade: { a: 0, b: 0, c: 0, d: 0 }, threshold: 0, remark_template: ''
  }
}

export default {
  name: 'AssessmentIndicatorEditDialog',
  props: {
    visible: { type: Boolean, default: false },
    form: { type: Object, default: () => emptyForm() },
    parentOptions: { type: Array, default: () => [] }
  },
  data () {
    return {
      LIB_CATEGORIES, DATA_SOURCES, OPERATORS, GRADE_KEYS,
      saving: false
    }
  },
  computed: {
    visibleSync: {
      get () { return this.visible },
      set (v) { if (!v) this.$emit('close') }
    },
    dialogTitle () {
      return this.form && this.form.id ? '编辑指标' : '新增指标'
    }
  },
  methods: {
    addCondition () {
      this.form.conditions.push({ field: '', operator: 'eq', value: '', deduct_per_unit: 1, max_deduct: 0 })
    },
    removeCondition (idx) {
      this.form.conditions.splice(idx, 1)
    },
    onClosed () {
      // 复位
      Object.assign(this.form, emptyForm())
    },
    doSave () {
      const f = this.form
      if (!(f.name || '').trim()) { this.$message.warning('请填写指标名称'); return }
      if (f.score === null || f.score === undefined || f.score < 0) { this.$message.warning('请填写有效分值'); return }
      if (f.data_source_mode === 'auto' && !f.data_source) { this.$message.warning('请选择数据源'); return }
      if (f.data_source_config && !this.isValidJson(f.data_source_config)) { this.$message.warning('取数条件必须是合法 JSON'); return }
      // 扣分规则校验
      if (f.scoring_type === 1) {
        if (f.deduct_mode === 'by_count') {
          for (const c of f.conditions) {
            if (c.deduct_per_unit > 0 && f.score > 0 && c.deduct_per_unit > f.score) {
              this.$message.warning(`条件「${c.field}」每单位扣分不能超过指标分值（${f.score}）`); return
            }
            if (c.max_deduct > 0 && f.score > 0 && c.max_deduct > f.score) {
              this.$message.warning(`条件「${c.field}」扣分上限不能超过指标分值（${f.score}）`); return
            }
          }
        } else if (f.deduct_mode === 'by_ratio') {
          if (f.ratio_value < 0 || f.ratio_value > 100) { this.$message.warning('达标线比例应在 0-100 之间'); return }
        }
      }
      this.saving = true
      const payload = {
        id: f.id,
        name: f.name.trim(),
        category: f.category || '',
        parent_id: f.parent_id || 0,
        score: f.score,
        scoring_type: f.scoring_type,
        data_source: f.data_source_mode === 'auto' ? f.data_source : '',
        data_source_config: f.data_source_mode === 'auto' ? f.data_source_config : '',
        auto_deduct_rule: this.buildRule(f),
        is_custom: 1
      }
      this.$emit('save', payload)
      this.saving = false
    },
    buildRule (f) {
      if (f.scoring_type !== 1) return ''
      const rule = { mode: f.deduct_mode, logical_operator: 'or', fallback_score: 0, threshold: f.threshold || 0, remark_template: (f.remark_template || '').trim() }
      if (f.deduct_mode === 'by_count') {
        rule.conditions = f.conditions.filter(c => (c.field || '').trim() !== '').map(c => ({
          field: c.field.trim(), operator: c.operator, value: c.value,
          deduct_per_unit: Number(c.deduct_per_unit || 0), max_deduct: Number(c.max_deduct || 0)
        }))
      } else if (f.deduct_mode === 'by_ratio') {
        rule.conditions = [{ field: 'score', operator: 'lt', value: f.ratio_value, deduct_ratio: 1, max_deduct: f.score }]
      } else if (f.deduct_mode === 'fixed') {
        rule.conditions = [{ field: 'record', operator: 'eq', value: 'trigger', deduct_per_unit: Number(f.fixed_deduct || 0), max_deduct: f.score }]
      } else if (f.deduct_mode === 'grade') {
        rule.grade = { a: Number(f.grade.a || 0), b: Number(f.grade.b || 0), c: Number(f.grade.c || 0), d: Number(f.grade.d || 0) }
      }
      return JSON.stringify(rule)
    },
    isValidJson (s) {
      try { JSON.parse(s); return true } catch (e) { return false }
    }
  }
}
</script>

<style scoped>
.form-tip { font-size: 12px; color: #909399; line-height: 1.6; margin-top: 4px; }
.danger { color: #F56C6C; }
.cond-list { padding: 0 0 0 110px; margin-bottom: 14px; }
.cond-row { display: flex; align-items: center; gap: 6px; margin-bottom: 8px; flex-wrap: wrap; }
.cond-field { width: 110px; }
.cond-op { width: 86px; }
.cond-value { width: 90px; }
.cond-label { font-size: 12px; color: #5a6f86; white-space: nowrap; }
.cond-num { width: 90px; }
</style>
