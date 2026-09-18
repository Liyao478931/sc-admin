<template>
  <el-dialog title="培训评估" :visible.sync="dialogVisible" width="550px" append-to-body>
    <el-form :model="form" :rules="rules" ref="formRef" label-width="100px" size="small">
      <el-form-item label="评估等级" prop="evaluation_level">
        <el-select v-model="form.evaluation_level" style="width:100%" @change="onLevelChange">
          <el-option v-for="l in levelOptions" :key="l.value" :label="l.label" :value="l.value" />
        </el-select>
      </el-form-item>
      <el-form-item label="评估得分" prop="evaluation_score">
        <el-input-number v-model="form.evaluation_score" :min="0" :max="100" style="width:100%" />
        <div style="color:#909399;font-size:12px;margin-top:4px">优秀≥90，良好≥75，一般≥60，差&lt;60</div>
      </el-form-item>
      <el-form-item label="评估意见">
        <el-input v-model="form.evaluation_opinion" type="textarea" :rows="3" maxlength="500" show-word-limit placeholder="评估意见（选填）" />
      </el-form-item>
    </el-form>
    <div slot="footer">
      <el-button size="small" @click="dialogVisible = false">取消</el-button>
      <el-button size="small" type="primary" :loading="saving" @click="submit">提交评估</el-button>
    </div>
  </el-dialog>
</template>

<script>
import { evaluateRecord } from '@/api/safetyTrainingRecord'

export default {
  name: 'EvaluateDialog',
  props: {
    visible: Boolean,
    recordId: { type: Number, default: 0 },
  },
  data() {
    return {
      dialogVisible: this.visible,
      saving: false,
      levelOptions: [
        { label: '优秀', value: 'excellent' },
        { label: '良好', value: 'good' },
        { label: '一般', value: 'general' },
        { label: '差', value: 'poor' }
      ],
      form: { evaluation_level: 'good', evaluation_score: 80, evaluation_opinion: '' },
      rules: {
        evaluation_level: [{ required: true, message: '请选择评估等级', trigger: 'change' }],
        evaluation_score: [{ required: true, message: '请输入评估得分', trigger: 'change' }]
      }
    }
  },
  watch: {
    visible(val) {
      this.dialogVisible = val
      if (val) this.form = { evaluation_level: 'good', evaluation_score: 80, evaluation_opinion: '' }
    },
    dialogVisible(val) { this.$emit('update:visible', val) },
  },
  methods: {
    onLevelChange() {
      this.form.evaluation_score = { excellent: 95, good: 80, general: 65, poor: 40 }[this.form.evaluation_level] || 80
    },
    submit() {
      this.$refs.formRef.validate(async (valid) => {
        if (!valid) return
        this.$confirm('确认提交培训评估？评估提交后不可修改。', '提交确认', { type: 'warning' }).then(async () => {
          this.saving = true
          try {
            const r = await evaluateRecord(this.recordId, this.form)
            if (r.code === 0) { this.$message.success('评估提交成功'); this.dialogVisible = false; this.$emit('saved') }
          } catch (e) {}
          this.saving = false
        }).catch(() => {})
      })
    }
  }
}
</script>
