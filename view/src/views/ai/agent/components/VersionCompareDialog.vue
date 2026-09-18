<template>
  <el-dialog :title="rollbackMode ? '选择回滚目标版本' : '版本对比'" :visible.sync="visible" width="720px" append-to-body>
    <el-form :model="form" label-width="110px" size="small">
      <el-form-item :label="rollbackMode ? '回滚到版本' : '版本A'">
        <el-select v-model="form.version_id_a" filterable style="width: 100%;" placeholder="选择版本" @change="doCompare">
          <el-option v-for="v in versionOptions" :key="v.id" :label="v.version_number + (v.version_name ? ' ' + v.version_name : '')" :value="v.id" />
        </el-select>
      </el-form-item>
      <el-form-item v-if="!rollbackMode" label="版本B">
        <el-select v-model="form.version_id_b" filterable style="width: 100%;" placeholder="选择版本" @change="doCompare">
          <el-option v-for="v in versionOptions" :key="v.id" :label="v.version_number + (v.version_name ? ' ' + v.version_name : '')" :value="v.id" />
        </el-select>
      </el-form-item>
      <el-form-item v-if="rollbackMode">
        <el-button type="danger" size="small" :loading="rolling" @click="doRollback">确认回滚</el-button>
      </el-form-item>
    </el-form>

    <div v-if="result && result.diffs" class="cmp-result">
      <div class="cmp-head">
        <span>版本 {{ result.version_a.version_number }} vs {{ result.version_b.version_number }}</span>
      </div>
      <el-table :data="result.diffs" size="small" stripe>
        <el-table-column prop="label" label="配置项" width="90" />
        <el-table-column prop="value_a" label="版本A" min-width="160" show-overflow-tooltip />
        <el-table-column prop="value_b" label="版本B" min-width="160" show-overflow-tooltip />
      </el-table>
      <el-empty v-if="!result.diffs.length" description="两个版本配置完全一致" :image-size="50" />
    </div>

    <div slot="footer">
      <el-button size="small" @click="visible = false">关闭</el-button>
    </div>
  </el-dialog>
</template>

<script>
import { getPublishVersions, comparePublishVersions, rollbackPublishVersion } from '../../../../api/aiPublish'

export default {
  name: 'VersionCompareDialog',
  data() {
    return {
      visible: false,
      rollbackMode: false,
      rolling: false,
      versionOptions: [],
      form: { version_id_a: '', version_id_b: '' },
      result: null
    }
  },
  methods: {
    async open(row, rollbackMode) {
      this.rollbackMode = !!rollbackMode
      this.visible = true
      this.result = null
      this.form = { version_id_a: row ? row.id : '', version_id_b: '' }
      // 加载版本选项（需要 agent_id，从 URL 或 row）
      const agentId = row ? row.agent_id : (this.$route && this.$route.query.agent_id) || ''
      if (!agentId) return this.$message.warning('缺少智能体信息')
      try {
        const res = await getPublishVersions({ agent_id: agentId, page: 1, limit: 100 })
        this.versionOptions = res.data.list || []
        // 回滚模式：默认选非草稿版本
        if (this.rollbackMode && !this.form.version_id_a) {
          const target = this.versionOptions.find(v => v.status !== 'draft') || this.versionOptions[0]
          if (target) this.form.version_id_a = target.id
        }
        if (this.form.version_id_a && !this.rollbackMode) this.doCompare()
      } catch (e) {}
    },
    async doCompare() {
      if (!this.form.version_id_a || (!this.rollbackMode && !this.form.version_id_b)) return
      try {
        const params = { version_id_a: this.form.version_id_a }
        if (!this.rollbackMode) params.version_id_b = this.form.version_id_b
        else {
          // 回滚模式对比当前版本
          const a = this.versionOptions.find(v => v.id === this.form.version_id_a)
          const cur = this.versionOptions.find(v => v.is_current === 1)
          if (!cur) { this.result = null; return }
          params.version_id_b = cur.id
        }
        const res = await comparePublishVersions(params)
        this.result = res.data || {}
      } catch (e) {}
    },
    async doRollback() {
      this.rolling = true
      try {
        const res = await rollbackPublishVersion(this.form.version_id_a)
        this.$message.success(res.msg || '回滚成功')
        this.visible = false
        this.$emit('saved')
      } catch (e) {}
      this.rolling = false
    }
  }
}
</script>

<style scoped>
.cmp-result { margin-top: 10px; }
.cmp-head { font-weight: 600; margin-bottom: 8px; }
</style>
