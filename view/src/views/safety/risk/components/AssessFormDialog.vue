<template>
  <el-dialog title="风险评估（LEC法）" :visible="visible" width="800px" append-to-body :close-on-click-modal="false" @update:visible="handleVisibleChange">
    <div v-loading="loading">
      <!-- 风险信息（只读） -->
      <el-descriptions v-if="detail" :column="3" size="small" border style="margin-bottom:14px;">
        <el-descriptions-item label="风险编号">{{ detail.risk_code }}</el-descriptions-item>
        <el-descriptions-item label="风险名称">{{ detail.risk_name }}</el-descriptions-item>
        <el-descriptions-item label="风险类型">{{ detail.type_text }}</el-descriptions-item>
        <el-descriptions-item label="所属区域">{{ detail.area }}</el-descriptions-item>
        <el-descriptions-item label="所属部门">{{ detail.department_name || '-' }}</el-descriptions-item>
        <el-descriptions-item label="责任人">{{ detail.responsible_person_name || '-' }}</el-descriptions-item>
        <el-descriptions-item label="危险源描述" :span="3">{{ detail.hazard_source }}</el-descriptions-item>
        <el-descriptions-item label="可能导致的后果" :span="3">{{ detail.consequence }}</el-descriptions-item>
      </el-descriptions>

      <!-- LEC 评估 -->
      <el-divider content-position="left">LEC 评分</el-divider>
      <el-form label-width="150px" size="small">
        <el-form-item label="L 可能性评分" required>
          <el-select v-model="lScore" placeholder="请选择" style="width:100%;" @change="calc">
            <el-option v-for="o in lOptions" :key="o.value" :label="`${o.label}（${o.value}）`" :value="o.value" />
          </el-select>
        </el-form-item>
        <el-form-item label="E 暴露频率评分" required>
          <el-select v-model="eScore" placeholder="请选择" style="width:100%;" @change="calc">
            <el-option v-for="o in eOptions" :key="o.value" :label="`${o.label}（${o.value}）`" :value="o.value" />
          </el-select>
        </el-form-item>
        <el-form-item label="C 后果严重性评分" required>
          <el-select v-model="cScore" placeholder="请选择" style="width:100%;" @change="calc">
            <el-option v-for="o in cOptions" :key="o.value" :label="`${o.label}（${o.value}）`" :value="o.value" />
          </el-select>
        </el-form-item>
      </el-form>

      <!-- 评估结果 -->
      <el-divider content-position="left">评估结果</el-divider>
      <el-form label-width="150px" size="small">
        <el-form-item label="风险值 D">
          <span style="font-size:20px;font-weight:700;color:#303133;">{{ dScore !== null ? dScore : '-' }}</span>
          <span style="color:#909399;font-size:12px;margin-left:8px;">D = L × E × C</span>
        </el-form-item>
        <el-form-item label="风险等级">
          <el-tag v-if="level" :type="levelTag">{{ levelText }}</el-tag>
          <span v-else style="color:#909399;">选择 L/E/C 后自动判定</span>
        </el-form-item>
        <el-form-item label="评估人">
          <span>{{ assessorName || '当前用户' }}</span>
        </el-form-item>
        <el-form-item label="评估日期">
          <el-date-picker v-model="assessDate" type="date" value-format="yyyy-MM-dd" style="width:180px;" />
        </el-form-item>
        <el-form-item label="下次复评日期">
          <span style="color:#E6A23C;font-weight:600;">{{ reviewDate || '-' }}</span>
        </el-form-item>
        <el-form-item label="备注">
          <el-input v-model="remark" type="textarea" :rows="2" maxlength="255" placeholder="选填" />
        </el-form-item>
      </el-form>
    </div>
    <div slot="footer">
      <el-button size="small" @click="handleVisibleChange(false)">取消</el-button>
      <el-button size="small" type="primary" :loading="saving" @click="submit">提交评估</el-button>
    </div>
  </el-dialog>
</template>

<script>
import { getAssessDetail, submitRiskAssessment } from '@/api/safetyRisk'
import { getDictByCode } from '@/api/dictionary'

export default {
  name: 'AssessFormDialog',
  props: {
    visible: { type: Boolean, default: false },
    row: { type: Object, default: null },
  },
  data() {
    return {
      loading: false, saving: false, detail: null,
      lOptions: [], eOptions: [], cOptions: [],
      lScore: '', eScore: '', cScore: '', dScore: null, level: '', assessorName: '',
      assessDate: this.today(), reviewDate: '', remark: '',
    }
  },
  computed: {
    levelText() { return { low: '低风险', general: '一般风险', major: '较大风险', critical: '重大风险' }[this.level] || '' },
    levelTag() { return { low: 'success', general: '', major: 'warning', critical: 'danger' }[this.level] || 'info' },
  },
  watch: {
    visible(val) { if (val) this.load() },
  },
  methods: {
    handleVisibleChange(val) { this.$emit('update:visible', val) },
    today() {
      const d = new Date()
      const p = n => String(n).padStart(2, '0')
      return `${d.getFullYear()}-${p(d.getMonth() + 1)}-${p(d.getDate())}`
    },
    async load() {
      if (!this.row || !this.row.id) return
      this.loading = true
      this.detail = null; this.lScore = ''; this.eScore = ''; this.cScore = ''; this.dScore = null; this.level = ''; this.reviewDate = ''; this.remark = ''
      try {
        const [r, l, e, c] = await Promise.all([
          getAssessDetail(this.row.id), getDictByCode('lec_l'), getDictByCode('lec_e'), getDictByCode('lec_c'),
        ])
        if (r.code === 0) this.detail = r.data
        this.lOptions = (l.data || []).map(x => ({ label: x.label, value: x.value }))
        this.eOptions = (e.data || []).map(x => ({ label: x.label, value: x.value }))
        this.cOptions = (c.data || []).map(x => ({ label: x.label, value: x.value }))
        const user = this.$store.state.user && this.$store.state.user.userInfo
        this.assessorName = (user && (user.real_name || user.username)) || ''
      } catch (e) {}
      this.loading = false
    },
    calc() {
      const l = parseFloat(this.lScore), e = parseFloat(this.eScore), c = parseFloat(this.cScore)
      if (isNaN(l) || isNaN(e) || isNaN(c)) { this.dScore = null; this.level = ''; this.reviewDate = ''; return }
      const d = Math.round(l * e * c * 10) / 10
      this.dScore = d
      this.level = d < 70 ? 'low' : d < 160 ? 'general' : d < 320 ? 'major' : 'critical'
      this.reviewDate = this.futureDate({ low: 12, general: 6, major: 3, critical: 1 }[this.level])
    },
    futureDate(months) {
      // 用真实月数计算（与后端 strtotime("+X months") 一致）
      const d = new Date()
      d.setMonth(d.getMonth() + months)
      const p = n => String(n).padStart(2, '0')
      return `${d.getFullYear()}-${p(d.getMonth() + 1)}-${p(d.getDate())}`
    },
    async submit() {
      if (this.lScore === '' || this.eScore === '' || this.cScore === '') { this.$message.warning('请完成 L/E/C 评分'); return }
      this.saving = true
      try {
        const r = await submitRiskAssessment({
          risk_id: this.row.id, l_score: this.lScore, e_score: this.eScore, c_score: this.cScore,
          assess_date: this.assessDate, remark: this.remark,
        })
        if (r.code === 0) {
          this.$message.success(`评估完成：风险值 ${r.data.d_score}，等级 ${r.data.level_text}，下次复评 ${r.data.review_date}`)
          this.handleVisibleChange(false)
          this.$emit('saved')
        }
      } catch (e) {}
      this.saving = false
    },
  },
}
</script>
