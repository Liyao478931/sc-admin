<template>
  <el-dialog :title="form.id ? '编辑告警规则' : '新增告警规则'" :visible.sync="visible" width="560px" append-to-body @closed="resetForm">
    <el-form :model="form" label-width="110px" size="small">
      <el-form-item label="规则名称" required>
        <el-input v-model="form.rule_name" maxlength="50" placeholder="如：错误率过高告警" />
      </el-form-item>
      <el-form-item label="监控指标" required>
        <el-select v-model="form.metric" style="width: 100%;" placeholder="选择监控指标">
          <el-option v-for="(v, k) in metricMap" :key="k" :label="v" :value="k" />
        </el-select>
      </el-form-item>
      <el-form-item label="告警条件" required>
        <div class="cond-row">
          <el-select v-model="form.operator" style="width: 140px;">
            <el-option v-for="(v, k) in operatorMap" :key="k" :label="v" :value="k" />
          </el-select>
          <el-input-number v-model="form.threshold" :precision="2" :step="1" :min="0" style="flex:1; margin-left:10px;" />
        </div>
      </el-form-item>
      <el-form-item label="持续时间" required>
        <el-input-number v-model="form.duration" :min="1" :max="1440" />
        <span class="unit">分钟（指标持续异常N分钟后触发）</span>
      </el-form-item>
      <el-form-item label="告警级别" required>
        <el-select v-model="form.level" style="width: 100%;">
          <el-option v-for="(v, k) in levelMap" :key="k" :label="v" :value="k" />
        </el-select>
      </el-form-item>
      <el-form-item label="通知渠道" required>
        <el-checkbox-group v-model="form.channels">
          <el-checkbox label="inbox">站内信</el-checkbox>
          <el-checkbox label="email">邮件</el-checkbox>
          <el-checkbox label="dingtalk">钉钉</el-checkbox>
          <el-checkbox label="workwx">企微</el-checkbox>
        </el-checkbox-group>
      </el-form-item>
      <el-form-item label="通知接收人">
        <el-select
          v-model="form.receivers"
          multiple
          filterable
          remote
          reserve-keyword
          placeholder="搜索并选择接收人（留空则通知全部用户）"
          :remote-method="searchUsers"
          :loading="userLoading"
          style="width: 100%;"
        >
          <el-option v-for="u in userOptions" :key="u.id" :label="u.real_name || u.username" :value="u.id" />
        </el-select>
      </el-form-item>
      <el-form-item label="状态">
        <el-switch v-model="form.status" :active-value="1" :inactive-value="0" active-text="启用" inactive-text="停用" />
      </el-form-item>
      <el-form-item label="描述">
        <el-input v-model="form.description" type="textarea" :rows="2" maxlength="255" placeholder="可选" />
      </el-form-item>
    </el-form>
    <div slot="footer">
      <el-button size="small" @click="visible = false">取消</el-button>
      <el-button size="small" type="primary" :loading="saving" @click="submit">确定</el-button>
    </div>
  </el-dialog>
</template>

<script>
import { addAlertRule, editAlertRule } from '../../../../api/aiMonitor'
import { getUserList } from '../../../../api/user'

export default {
  name: 'AlertRuleDialog',
  data() {
    return {
      visible: false,
      saving: false,
      userLoading: false,
      userOptions: [],
      metricMap: {
        error_rate: '错误率',
        response_time: '响应时间',
        call_count: '调用次数',
        token_consumption: 'Token消耗',
        service_availability: '服务可用性',
        cpu_usage: 'CPU使用率',
        memory_usage: '内存使用率'
      },
      operatorMap: { '>': '大于', '>=': '大于等于', '<': '小于', '<=': '小于等于', '==': '等于' },
      levelMap: { info: '提示', warning: '一般', critical: '重要', emergency: '紧急' },
      form: {
        id: null, rule_name: '', metric: 'error_rate', operator: '>', threshold: 5,
        duration: 2, level: 'warning', channels: ['inbox'], receivers: [], status: 1, description: ''
      }
    }
  },
  methods: {
    async searchUsers(kw) {
      this.userLoading = true
      try {
        const res = await getUserList({ page: 1, limit: 50, keyword: kw || '' })
        this.userOptions = (res.data && res.data.list) || []
      } catch (e) {}
      this.userLoading = false
    },
    open(row) {
      if (row) {
        this.form = {
          id: row.id, rule_name: row.rule_name, metric: row.metric, operator: row.operator,
          threshold: Number(row.threshold), duration: Number(row.duration), level: row.level,
          channels: Array.isArray(row.channels) ? row.channels : [],
          receivers: Array.isArray(row.receivers) ? row.receivers.map(Number) : [],
          status: Number(row.status), description: row.description || ''
        }
        // 预加载已选接收人名称
        if (this.form.receivers.length) this.searchUsers('')
      }
      this.visible = true
    },
    resetForm() {
      this.form = {
        id: null, rule_name: '', metric: 'error_rate', operator: '>', threshold: 5,
        duration: 2, level: 'warning', channels: ['inbox'], receivers: [], status: 1, description: ''
      }
    },
    async submit() {
      if (!this.form.rule_name) return this.$message.warning('请输入规则名称')
      if (!this.form.channels || !this.form.channels.length) return this.$message.warning('请至少选择一个通知渠道')
      this.saving = true
      try {
        const payload = {
          rule_name: this.form.rule_name, metric: this.form.metric, operator: this.form.operator,
          threshold: this.form.threshold, duration: this.form.duration, level: this.form.level,
          channels: this.form.channels, receivers: this.form.receivers, status: this.form.status,
          description: this.form.description
        }
        if (this.form.id) await editAlertRule(this.form.id, payload)
        else await addAlertRule(payload)
        this.$message.success('保存成功')
        this.visible = false
        this.$emit('saved')
      } catch (e) {}
      this.saving = false
    }
  }
}
</script>

<style scoped>
.cond-row { display: flex; align-items: center; }
.unit { color: #909399; margin-left: 8px; font-size: 12px; }
</style>
