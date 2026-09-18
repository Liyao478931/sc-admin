<!-- 文件：admin/src/views/ai/tools/create.vue -->
<template>
  <div class="page">
    <!-- 顶部 -->
    <div class="page-head">
      <el-breadcrumb separator="/">
        <el-breadcrumb-item>AI智能平台</el-breadcrumb-item>
        <el-breadcrumb-item>工具中心</el-breadcrumb-item>
        <el-breadcrumb-item>新增工具</el-breadcrumb-item>
      </el-breadcrumb>
      <el-button size="small" icon="el-icon-back" @click="goList">返回列表</el-button>
    </div>

    <el-form ref="form" :model="form" :rules="rules" label-width="140px" class="tool-form">
      <!-- 一、基本信息 -->
      <el-card shadow="never" class="sec-card">
        <div slot="header" class="sec-head"><span class="sec-title">基本信息</span></div>
        <el-form-item label="工具名称" prop="tool_name">
          <el-input v-model="form.tool_name" placeholder="请输入工具名称（如 query_device）" style="width:360px"
            @blur="checkName" />
          <div class="field-tip">小写字母开头，由小写字母/数字/下划线组成，长度3-50</div>
        </el-form-item>
        <el-form-item label="工具显示名称" prop="tool_display_name">
          <el-input v-model="form.tool_display_name" placeholder="请输入显示名称（如 查询设备）" style="width:360px" />
        </el-form-item>
        <el-form-item label="工具分类" prop="category">
          <el-select v-model="form.category" placeholder="请选择分类" style="width:200px">
            <el-option v-for="(t, v) in CATEGORY_OPTIONS" :key="v" :label="t" :value="v" />
          </el-select>
        </el-form-item>
        <el-form-item label="工具描述" prop="description">
          <el-input v-model="form.description" type="textarea" :rows="3" placeholder="请描述工具的用途和调用场景，帮助AI理解" style="width:600px" maxlength="500" show-word-limit />
        </el-form-item>
        <el-form-item label="状态">
          <el-switch v-model="form.status" :active-value="1" :inactive-value="0" active-text="启用" inactive-text="停用" />
        </el-form-item>
      </el-card>

      <!-- 二、请求配置 -->
      <el-card shadow="never" class="sec-card">
        <div slot="header" class="sec-head"><span class="sec-title">请求配置</span></div>
        <el-form-item label="请求方法" prop="method">
          <el-select v-model="form.method" style="width:150px">
            <el-option v-for="m in ['GET', 'POST', 'PUT', 'DELETE']" :key="m" :label="m" :value="m" />
          </el-select>
        </el-form-item>
        <el-form-item label="API路径" prop="api_path">
          <el-input v-model="form.api_path" placeholder="请输入API路径（如 /api/device/detail 或 https://...）" style="width:420px" />
        </el-form-item>
        <el-form-item label="请求头配置">
          <headers-editor v-model="form.headers" />
        </el-form-item>
      </el-card>

      <!-- 三、参数定义 -->
      <el-card shadow="never" class="sec-card">
        <div slot="header" class="sec-head"><span class="sec-title">参数定义（JSON Schema）</span></div>
        <parameters-editor ref="paramsEditor" v-model="form.params_schema" />
      </el-card>

      <!-- 四、响应定义 -->
      <el-card shadow="never" class="sec-card">
        <div slot="header" class="sec-head"><span class="sec-title">响应定义（可选）</span></div>
        <el-input v-model="responseJson" type="textarea" :rows="5" placeholder='{"type":"object","properties":{}}' style="width:600px" />
        <div class="json-actions">
          <el-button size="small" @click="formatResponse">格式化</el-button>
          <el-button size="small" type="primary" @click="validateResponse">校验</el-button>
        </div>
      </el-card>

      <!-- 五、其他配置 -->
      <el-card shadow="never" class="sec-card">
        <div slot="header" class="sec-head"><span class="sec-title">其他配置</span></div>
        <el-form-item label="是否需要人工确认">
          <el-switch v-model="form.requires_confirm" :active-value="1" :inactive-value="0" active-text="是" inactive-text="否" />
          <span class="field-tip">开启后AI调用该工具前需用户确认</span>
        </el-form-item>
        <el-form-item label="超时时间">
          <el-input-number v-model="form.timeout" :min="1" :max="120" /> <span class="field-tip">秒</span>
        </el-form-item>
        <el-form-item label="重试次数">
          <el-input-number v-model="form.retry_count" :min="0" :max="3" /> <span class="field-tip">次</span>
        </el-form-item>
      </el-card>
    </el-form>

    <!-- 底部操作 -->
    <div class="page-footer">
      <el-button plain @click="goList">返回列表</el-button>
      <div class="footer-right">
        <el-button type="primary" :loading="saving" @click="handleSave(true)">保存并测试</el-button>
        <el-button type="success" :loading="saving" @click="handleSave(false)">保存</el-button>
      </div>
    </div>

    <!-- 测试弹窗 -->
    <el-dialog title="测试工具" :visible.sync="testVisible" width="600px" top="8vh">
      <div v-if="testTool" class="test-dialog">
        <div class="test-info">工具：{{ testTool.tool_display_name }}｜路径：{{ testTool.api_path }}</div>
        <div class="test-params">
          <el-form label-width="100px" size="small">
            <el-form-item v-for="(p, key) in testSchemaProps" :key="key" :label="p.title || key">
              <el-input v-model="testForm[key]" :placeholder="'参数 ' + key" />
            </el-form-item>
            <el-form-item v-if="!Object.keys(testSchemaProps).length">
              <span class="field-tip">该工具无参数定义，直接测试</span>
            </el-form-item>
            <el-form-item>
              <el-button type="primary" size="small" :loading="testing" @click="runTest">发送请求</el-button>
            </el-form-item>
          </el-form>
        </div>
        <div v-if="testResult" class="test-result">
          <div class="result-row">状态码：<b :class="testResult.success ? 'ok' : 'err'">{{ testResult.status_code }}</b></div>
          <div class="result-row">响应时间：{{ testResult.elapsed_ms }}ms</div>
          <pre class="result-body">{{ formatBody(testResult.response_body) }}</pre>
        </div>
      </div>
    </el-dialog>
  </div>
</template>

<script>
import HeadersEditor from '@/components/HeadersEditor.vue'
import ParametersEditor from '@/components/ParametersEditor.vue'
import { addAiTool, checkAiToolName, testAiTool } from '@/api/aiTool'

const CATEGORY_OPTIONS = { device: '设备工具', safety: '安全工具', hr: '人事工具', warehouse: '仓储工具', common: '通用工具', business: '经营工具', ai: '知识库工具' }

export default {
  name: 'AiToolCreate',
  components: { HeadersEditor, ParametersEditor },
  data () {
    return {
      CATEGORY_OPTIONS,
      form: {
        tool_name: '', tool_display_name: '', category: '', description: '',
        method: 'GET', api_path: '', headers: [],
        requires_confirm: 0, timeout: 30, retry_count: 0, status: 1
      },
      responseJson: '',
      rules: {
        tool_name: [
          { required: true, message: '请输入工具名称', trigger: 'blur' },
          { pattern: /^[a-z][a-z0-9_]{2,49}$/, message: '小写字母开头，字母/数字/下划线，长度3-50', trigger: 'blur' }
        ],
        tool_display_name: [
          { required: true, message: '请输入显示名称', trigger: 'blur' },
          { min: 2, max: 30, message: '长度2-30字符', trigger: 'blur' }
        ],
        category: [{ required: true, message: '请选择分类', trigger: 'change' }],
        description: [
          { required: true, message: '请输入描述', trigger: 'blur' },
          { min: 10, max: 500, message: '长度10-500字符', trigger: 'blur' }
        ],
        method: [{ required: true, message: '请选择请求方法', trigger: 'change' }],
        api_path: [{ required: true, message: '请输入API路径', trigger: 'blur' }]
      },
      saving: false,
      // 测试
      testVisible: false, testTool: null, testForm: {}, testing: false, testResult: null
    }
  },
  computed: {
    testSchemaProps () {
      if (!this.testTool || !this.testTool.params_schema) return {}
      const ps = typeof this.testTool.params_schema === 'string' ? JSON.parse(this.testTool.params_schema) : this.testTool.params_schema
      return (ps && ps.properties) || {}
    }
  },
  methods: {
    goList () { this.$router.push('/ai/tools/list') },
    async checkName () {
      const n = (this.form.tool_name || '').trim()
      if (!n || !/^[a-z][a-z0-9_]{2,49}$/.test(n)) return
      try {
        const r = await checkAiToolName(n)
        if (r.code === 0 && r.data.exists) this.$message.warning('该工具名称已存在')
      } catch (e) {}
    },
    formatResponse () {
      try { this.responseJson = JSON.stringify(JSON.parse(this.responseJson || '{}'), null, 2); this.$message.success('已格式化') }
      catch (e) { this.$message.error('JSON格式错误') }
    },
    validateResponse () {
      try { JSON.parse(this.responseJson || '{}'); this.$message.success('JSON合法') }
      catch (e) { this.$message.error('JSON格式错误') }
    },
    async handleSave (andTest) {
      // 表单校验
      const valid = await this.$refs.form.validate().catch(() => false)
      if (!valid) return
      // 名称唯一性最终校验
      try {
        const chk = await checkAiToolName(this.form.tool_name)
        if (chk.code === 0 && chk.data.exists) { this.$message.error('工具名称已存在'); return }
      } catch (e) {}

      // 组装参数 schema
      const paramsSchema = this.$refs.paramsEditor.getSchema()
      if (this.$refs.paramsEditor.mode === 'json' && paramsSchema === null) {
        this.$message.error('参数定义JSON不合法'); return
      }
      // 响应 schema
      let responseSchema = null
      if (this.responseJson && this.responseJson.trim()) {
        try { responseSchema = JSON.parse(this.responseJson) } catch (e) { this.$message.error('响应定义JSON不合法'); return }
      }

      this.saving = true
      try {
        const data = {
          tool_name: this.form.tool_name.trim(),
          tool_display_name: this.form.tool_display_name.trim(),
          category: this.form.category,
          description: this.form.description.trim(),
          method: this.form.method,
          api_path: this.form.api_path.trim(),
          headers: this.form.headers,
          params_schema: JSON.stringify(paramsSchema),
          response_schema: responseSchema ? JSON.stringify(responseSchema) : '',
          requires_confirm: this.form.requires_confirm,
          timeout: this.form.timeout,
          retry_count: this.form.retry_count,
          status: this.form.status
        }
        const r = await addAiTool(data)
        if (r.code === 0) {
          this.$message.success('工具创建成功')
          if (andTest) {
            // 保存并测试：跳转到独立测试页
            this.$router.push({ path: '/ai/tools/test', query: { tool_id: r.data.id } })
          } else {
            this.goList()
          }
        }
      } catch (e) {} finally { this.saving = false }
    },
    async runTest () {
      if (!this.testTool) return
      this.testing = true
      this.testResult = null
      try {
        const r = await testAiTool(this.testTool.id, this.testForm)
        if (r.code === 0) { this.testResult = r.data; this.$message.success(r.msg || '测试完成') }
      } catch (e) { this.$message.error('测试失败') } finally { this.testing = false }
    },
    formatBody (body) {
      if (!body) return '(无响应体)'
      try { return JSON.stringify(JSON.parse(body), null, 2) } catch (e) { return body }
    }
  }
}
</script>

<style scoped>
.page { padding: 16px; background: #f0f2f5; min-height: 100%; padding-bottom: 80px; }
.page-head { display: flex; justify-content: space-between; align-items: center; margin-bottom: 16px; }
.sec-card { margin-bottom: 16px; }
.sec-head .sec-title { font-size: 15px; font-weight: 600; color: #303133; }
.field-tip { font-size: 12px; color: #909399; margin-left: 8px; }
.json-actions { margin-top: 8px; }
.page-footer { position: fixed; bottom: 0; left: 0; right: 0; background: #fff; padding: 10px 20px; display: flex; justify-content: space-between; align-items: center; box-shadow: 0 -2px 8px rgba(0,0,0,0.06); }
.footer-right { display: flex; gap: 10px; }
.test-info { font-size: 13px; color: #606266; margin-bottom: 12px; }
.test-result { margin-top: 12px; background: #f8f9fb; border-radius: 6px; padding: 10px; }
.result-row { font-size: 13px; margin-bottom: 4px; }
.result-row .ok { color: #67C23A; }
.result-row .err { color: #F56C6C; }
.result-body { background: #282c34; color: #abb2bf; border-radius: 6px; padding: 10px; font-size: 12px; overflow-x: auto; max-height: 250px; }
</style>
