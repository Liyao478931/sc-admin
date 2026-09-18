<!-- 文件：admin/src/views/ai/voice/templates.vue（v1.68.0 指令模板管理） -->
<template>
  <div class="vt-page">
    <div class="crumb"><span>AI智能平台</span><i class="el-icon-arrow-right"></i><span>自然语言交互</span><i class="el-icon-arrow-right"></i><span class="cur">指令模板管理</span></div>

    <div class="toolbar">
      <el-button size="small" type="primary" icon="el-icon-plus" @click="openForm()">新建模板</el-button>
      <el-button size="small" icon="el-icon-refresh" @click="load">刷新</el-button>
    </div>

    <div class="panel">
      <el-table :data="list" v-loading="loading" size="small" border stripe>
        <el-table-column prop="trigger_pattern" label="触发语句" min-width="200" />
        <el-table-column prop="intent_text" label="意图类型" width="90" align="center" />
        <el-table-column prop="target_action" label="目标动作" width="150" />
        <el-table-column prop="use_count" label="使用次数" width="90" align="center" />
        <el-table-column label="状态" width="80" align="center">
          <template slot-scope="s"><el-tag :type="s.row.status === 1 ? 'success' : 'info'" size="mini">{{ s.row.status_text }}</el-tag></template>
        </el-table-column>
        <el-table-column label="操作" width="160" align="center">
          <template slot-scope="s">
            <el-button type="text" size="mini" @click="openForm(s.row)">编辑</el-button>
            <el-button type="text" size="mini" @click="testTpl(s.row)">测试</el-button>
            <el-button type="text" size="mini" class="del" @click="remove(s.row)">删除</el-button>
          </template>
        </el-table-column>
      </el-table>
    </div>

    <!-- 新建/编辑弹窗 -->
    <el-dialog :title="form.id ? '编辑模板' : '新建模板'" :visible.sync="formVisible" width="560px">
      <el-form label-width="90px" size="small">
        <el-form-item label="触发语句">
          <el-input v-model="form.trigger_pattern" placeholder="如：查一下设备{device_id}的维修记录" />
          <div class="tip">使用 {参数名} 作为占位符</div>
        </el-form-item>
        <el-form-item label="意图类型">
          <el-select v-model="form.intent_type" style="width:150px">
            <el-option label="查询" value="query" />
            <el-option label="导航" value="navigate" />
            <el-option label="操作" value="operate" />
            <el-option label="分析" value="analyze" />
            <el-option label="知识问答" value="knowledge" />
          </el-select>
        </el-form-item>
        <el-form-item label="目标动作">
          <el-input v-model="form.target_action" placeholder="工具名或留空（导航/分析）" />
        </el-form-item>
        <el-form-item label="响应模板">
          <el-input v-model="form.response_template" type="textarea" :rows="2" placeholder="如：已查询设备{device_id}的维修记录，共{n}条" />
        </el-form-item>
        <el-form-item label="状态">
          <el-switch v-model="form.status" :active-value="1" :inactive-value="0" active-text="启用" inactive-text="禁用" />
        </el-form-item>
        <el-form-item label="测试">
          <el-input v-model="testInput" placeholder="输入测试语句" style="width:200px" />
          <el-button size="small" type="primary" @click="doTest">测试</el-button>
          <span v-if="testResult" :class="testResult.matched ? 'ok' : 'no'">{{ testResult.matched ? '匹配成功' : '未匹配' }}</span>
        </el-form-item>
      </el-form>
      <span slot="footer">
        <el-button size="small" @click="formVisible = false">取消</el-button>
        <el-button size="small" type="primary" @click="save">保存</el-button>
      </span>
    </el-dialog>
  </div>
</template>

<script>
import { getVoiceTemplates, addVoiceTemplate, updateVoiceTemplate, deleteVoiceTemplate, testVoiceTemplate } from '@/api/aiVoice'

export default {
  name: 'AiVoiceTemplates',
  data () {
    return { list: [], loading: false, formVisible: false, form: { id: 0, trigger_pattern: '', intent_type: 'query', target_action: '', response_template: '', status: 1 }, testInput: '', testResult: null }
  },
  mounted () { this.load() },
  methods: {
    async load () {
      this.loading = true
      try { const r = await getVoiceTemplates(); if (r.code === 0) this.list = r.data.list || [] } catch (e) {} finally { this.loading = false }
    },
    openForm (row) {
      this.form = row ? { ...row } : { id: 0, trigger_pattern: '', intent_type: 'query', target_action: '', response_template: '', status: 1 }
      this.testInput = ''; this.testResult = null
      this.formVisible = true
    },
    async save () {
      if (!this.form.trigger_pattern) { this.$message.warning('触发语句不能为空'); return }
      try {
        const r = this.form.id ? await updateVoiceTemplate(this.form.id, this.form) : await addVoiceTemplate(this.form)
        if (r.code === 0) { this.$message.success('已保存'); this.formVisible = false; this.load() } else this.$message.error(r.msg || '保存失败')
      } catch (e) { this.$message.error('保存失败') }
    },
    remove (row) {
      this.$confirm(`确认删除模板「${row.trigger_pattern}」？`, '提示', { type: 'warning' }).then(async () => {
        try { const r = await deleteVoiceTemplate(row.id); if (r.code === 0) { this.$message.success('已删除'); this.load() } } catch (e) {}
      }).catch(() => {})
    },
    async testTpl (row) {
      this.openForm(row)
      this.testInput = row.trigger_pattern.replace(/\{[a-z_]+\}/g, '示例')
      this.doTest()
    },
    async doTest () {
      if (!this.testInput) return
      try { const r = await testVoiceTemplate(this.testInput); if (r.code === 0) this.testResult = r.data } catch (e) {}
    }
  }
}
</script>

<style scoped>
.crumb { padding: 10px 16px; background: #fff; border-bottom: 1px solid #e8e8e8; font-size: 13px; color: #909399; }
.crumb i { margin: 0 6px; }
.crumb .cur { color: #303133; }
.toolbar { display: flex; align-items: center; gap: 8px; padding: 12px 16px; }
.panel { background: #fff; border: 1px solid #ebeef5; border-radius: 8px; margin: 0 16px 16px; padding: 12px 16px; }
.tip { font-size: 12px; color: #909399; }
.del { color: #f56c6c; }
.ok { color: #67c23a; margin-left: 8px; }
.no { color: #f56c6c; margin-left: 8px; }
</style>
