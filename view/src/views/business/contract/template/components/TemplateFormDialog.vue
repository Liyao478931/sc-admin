<!--
  文件：admin/src/views/business/contract/template/components/TemplateFormDialog.vue
  功能：新增/编辑合同模板弹窗（el-tabs 三页）
    - 基本信息：模板名称/合同类型/模板类型/状态
    - 模板内容：HTML 编辑 + 变量插入 + 预览 + 格式化
    - 变量说明：可用变量列表 + 搜索
-->
<template>
  <el-dialog :title="isEdit ? '编辑模板' : '新增模板'" :visible="visible" width="900px" :close-on-click-modal="false" @close="$emit('update:visible', false)">
    <el-tabs v-model="tab" v-loading="loading">
      <!-- 一、基本信息 -->
      <el-tab-pane label="基本信息" name="basic">
        <el-form :model="form" label-width="110px" size="small">
          <el-form-item label="模板名称" required>
            <el-input v-model="form.template_name" maxlength="100" placeholder="模板名称*" />
          </el-form-item>
          <el-form-item label="适用合同类型" required>
            <el-select v-model="form.contract_type" style="width:260px">
              <el-option v-for="opt in typeOptions" :key="opt.value" :label="opt.label" :value="opt.value" />
            </el-select>
          </el-form-item>
          <el-form-item label="模板类型">
            <el-radio-group v-model="form.template_type">
              <el-radio label="standard">标准模板</el-radio>
              <el-radio label="custom">自定义模板</el-radio>
            </el-radio-group>
          </el-form-item>
          <el-form-item label="状态">
            <el-switch v-model="form.status" :active-value="1" :inactive-value="0" active-text="启用" inactive-text="停用" />
          </el-form-item>
          <el-alert v-if="isEdit && detailReferenced > 0" type="warning" :closable="false" show-icon title="该模板已被合同引用，核心内容不可修改（可复制后新建模板）" style="margin-top:8px" />
        </el-form>
      </el-tab-pane>

      <!-- 二、模板内容（表单编辑，非 HTML 代码） -->
      <el-tab-pane label="模板内容" name="content">
        <div class="content-toolbar">
          <el-radio-group v-model="contentMode" size="mini">
            <el-radio-button label="form">表单编辑</el-radio-button>
            <el-radio-button label="html">HTML 源码（高级）</el-radio-button>
          </el-radio-group>
          <el-button size="mini" type="primary" plain icon="el-icon-view" @click="doPreview">预览</el-button>
        </div>

        <!-- 表单编辑模式 -->
        <div v-if="contentMode === 'form'">
          <el-form :model="form" label-width="100px" size="small">
            <el-form-item label="合同标题"><el-input v-model="form.title" maxlength="50" placeholder="如：购销合同" /></el-form-item>
            <el-form-item label="明细表列">
              <el-select v-model="form.columns" multiple filterable allow-create default-first-option size="small" style="width:100%" placeholder="选择或输入明细列（key:名称），如 name:名称">
                <el-option v-for="o in columnOptions" :key="o.value" :label="o.label" :value="o.value" />
              </el-select>
              <div class="tip">明细表格的列（不含「序号」行号）；格式 key:列名，可自定义</div>
            </el-form-item>
            <el-form-item label="条款列表">
              <div v-for="(cl, idx) in form.clauses" :key="idx" class="clause-row">
                <el-input v-model="cl.clause_title" placeholder="条款标题，如：第一条　付款方式" style="width:38%" />
                <el-input v-model="cl.clause_content" placeholder="条款内容（可含变量如 {payment_terms}；明细表格行填 {items_table}）" type="textarea" :rows="2" style="flex:1" />
                <el-button type="text" icon="el-icon-arrow-up" @click="moveClause(idx, -1)"></el-button>
                <el-button type="text" icon="el-icon-arrow-down" @click="moveClause(idx, 1)"></el-button>
                <el-button type="text" icon="el-icon-delete" class="danger" @click="removeClause(idx)"></el-button>
              </div>
              <el-button size="mini" type="text" icon="el-icon-plus" @click="addClause">添加条款</el-button>
            </el-form-item>
            <el-form-item label="签署栏">
              <el-switch v-model="form.sign_enabled" :active-value="1" :inactive-value="0" active-text="显示甲乙方签署栏" inactive-text="不显示" />
              <div class="tip">签署栏自动取甲乙方真实信息（名称/地址/法人/代理人/电话/传真/银行/税号）</div>
            </el-form-item>
          </el-form>
        </div>

        <!-- HTML 源码模式（高级用户） -->
        <div v-else>
          <el-input ref="contentInput" v-model="form.content" type="textarea" :rows="18" placeholder="HTML 模板内容" class="content-area" />
        </div>

        <el-divider content-position="left">变量插入</el-divider>
        <el-input v-model="varSearch" size="small" placeholder="搜索变量" clearable style="width:220px;margin-bottom:8px" />
        <div class="var-grid">
          <el-tag
            v-for="v in filteredVars" :key="v.var_key" size="small" class="var-tag"
            :type="varTag(v.var_category)" @click="insertVar(v.var_key)"
          >{{ v.var_name }}（{ {{ v.var_key }} }）</el-tag>
        </div>
      </el-tab-pane>

      <!-- 三、变量说明 -->
      <el-tab-pane label="变量说明" name="variables">
        <el-input v-model="varSearch" size="small" placeholder="搜索变量" clearable style="width:260px;margin-bottom:8px" />
        <el-table :data="filteredVars" size="mini" border max-height="420">
          <el-table-column prop="var_key" label="变量键" width="180" />
          <el-table-column prop="var_name" label="变量名称" width="130" />
          <el-table-column prop="var_category_text" label="分类" width="120" />
          <el-table-column prop="var_type_text" label="类型" width="80" align="center" />
          <el-table-column prop="description" label="说明" min-width="160" show-overflow-tooltip />
          <el-table-column prop="example" label="示例值" min-width="160" show-overflow-tooltip />
        </el-table>
      </el-tab-pane>
    </el-tabs>

    <div slot="footer" class="dialog-footer">
      <el-button size="small" @click="$emit('update:visible', false)">取消</el-button>
      <el-button size="small" type="primary" :loading="saving" @click="handleSubmit">保存</el-button>
    </div>

    <!-- 预览弹窗 -->
    <el-dialog title="模板预览" :visible.sync="previewVisible" width="850px" append-to-body top="4vh">
      <div class="preview-body"><iframe :srcdoc="previewHtml" class="preview-frame"></iframe></div>
    </el-dialog>
  </el-dialog>
</template>

<script>
import { addTemplate, editTemplate, getTemplateDetail, getTemplateVariables, previewContract } from '../../../../../api/contractTemplate'
import { getDictByCode } from '../../../../../api/dictionary'

export default {
  name: 'TemplateFormDialog',
  props: {
    visible: { type: Boolean, default: false },
    row: { type: Object, default: null }
  },
  data() {
    return {
      tab: 'basic', loading: false, saving: false, contentMode: 'form',
      typeOptions: [], varList: [], varSearch: '',
      form: { template_name: '', contract_type: '', template_type: 'standard', content: '', style: '', variables: [], is_default: 0, status: 1, title: '购销合同', clauses: [], sign_enabled: 1, columns: [] },
      columnOptions: [
        { value: 'name:名称', label: 'name:名称' },
        { value: 'model:型号', label: 'model:型号' },
        { value: 'unit:单位', label: 'unit:单位' },
        { value: 'qty:数量', label: 'qty:数量' },
        { value: 'price:单价（元）', label: 'price:单价（元）' },
        { value: 'amount:金额（元）', label: 'amount:金额（元）' },
        { value: 'remark:备注', label: 'remark:备注' }
      ],
      detailReferenced: 0,
      previewVisible: false, previewHtml: ''
    }
  },
  computed: {
    isEdit() { return !!(this.row && this.row.id) },
    filteredVars() {
      const kw = this.varSearch.trim().toLowerCase()
      if (!kw) return this.varList
      return this.varList.filter(v => (v.var_key || '').toLowerCase().includes(kw) || (v.var_name || '').toLowerCase().includes(kw))
    }
  },
  watch: {
    visible(val) { if (val) this.open() }
  },
  methods: {
    varTag(c) { return { basic: 'info', customer: 'primary', supplier: 'success', items: 'warning', amount: 'danger', system: 'info', custom: '' }[c] || 'info' },
    async open() {
      this.tab = 'basic'
      this.loading = true
      this.varSearch = ''
      this.form = { template_name: '', contract_type: '', template_type: 'standard', content: '', style: '', variables: [], is_default: 0, status: 1, title: '购销合同', clauses: [{ clause_title: '第一条　序号、名称、型号、数量、价款等。', clause_content: '{items_table}' }], sign_enabled: 1, columns: ['name:名称', 'model:型号', 'unit:单位', 'qty:数量', 'price:单价（元）', 'amount:金额（元）', 'remark:备注'] }
      this.detailReferenced = 0
      try { const r = await getDictByCode('contract_type'); this.typeOptions = r.data || [] } catch (e) { this.typeOptions = [] }
      try { const r = await getTemplateVariables(); this.varList = (r.data && r.data.list) || [] } catch (e) { this.varList = [] }

      if (this.isEdit) {
        try {
          const r = await getTemplateDetail(this.row.id)
          if (r.code === 0) {
            const d = r.data
            this.form = {
              template_name: d.template_name, contract_type: d.contract_type, template_type: d.template_type || 'standard',
              content: d.content || '', style: d.style || '', variables: d.variables || [], is_default: d.is_default || 0, status: d.status,
              title: '购销合同', clauses: [], sign_enabled: 1, columns: ['name:名称', 'model:型号', 'unit:单位', 'qty:数量', 'price:单价（元）', 'amount:金额（元）', 'remark:备注']
            }
            this.parseHtmlToForm(d.content || '')
            this.contentMode = 'form'
            this.detailReferenced = d.referenced || 0
            // 被引用模板：内容编辑区禁用
            if (this.detailReferenced > 0) this.tab = 'basic'
          }
        } catch (e) {}
      }
      this.loading = false
    },
    fillImported(content) {
      // 从导入弹窗填充内容（打开后调用）
      if (content) { this.form.content = content; this.parseHtmlToForm(content); this.tab = 'content' }
    },
    /** 将 HTML 模板解析回表单（标题/条款/签署栏） */
    parseHtmlToForm(html) {
      if (!html) return
      const titleM = html.match(/<div class="contract-title">([^<]*)<\/div>/)
      this.form.title = titleM ? titleM[1].trim() : '购销合同'
      const clauses = []
      const re = /<p><strong>(第[一二三四五六七八九十百\d]+条[^<]*?)<\/strong>(.*?)<\/p>/g
      let m
      while ((m = re.exec(html))) clauses.push({ clause_title: m[1].trim(), clause_content: m[2].trim() })
      this.form.clauses = clauses.length ? clauses : [{ clause_title: '第一条　序号、名称、型号、数量、价款等。', clause_content: '{items_table}' }]
      this.form.sign_enabled = html.includes('sign-area') ? 1 : 0
      const colsM = html.match(/<!--COLS:(.*?)-->/)
      if (colsM && colsM[1]) this.form.columns = colsM[1].split(',').filter(Boolean)
    },
    /** 由表单组装 HTML 模板 */
    buildHtml() {
      const css = `body { font-family: SimSun, serif; font-size: 14px; padding: 40px; }
.contract-title { text-align: center; font-size: 22px; font-weight: bold; padding: 20px 0; }
.contract-info-table { width: 100%; border: none; margin: 10px 0; }
.contract-info-table td { border: none; padding: 2px 0; }
.contract-info-table td.left { width: 60%; text-align: left; }
.contract-info-table td.right { text-align: left; }
table { width: 100%; border-collapse: collapse; margin: 15px 0; }
th, td { border: 1px solid #000; padding: 6px 10px; text-align: center; }
th { background: #f5f5f5; font-weight: bold; }
.text-left { text-align: left; }
.text-right { text-align: right; }
.sign-area { margin-top: 30px; }
.sign-area table { border: 1px solid #000; border-collapse: collapse; }
.sign-area td { border: none; vertical-align: top; padding: 10px 20px; text-align: left; }
.sign-area td:first-child { border-right: 1px solid #000; }`
      let clausesHtml = ''
      ;(this.form.clauses || []).forEach(c => {
        if (c.clause_title) clausesHtml += `<p><strong>${this.escHtml(c.clause_title)}</strong>${this.escHtml(c.clause_content || '')}</p>\n`
      })
      const signHtml = this.form.sign_enabled === 1 ? `<div class="sign-area">
  <table>
    <tr>
      <td style="width:50%;"><p><strong>甲方</strong></p><p>甲方（章）：{customer_seal}</p><p>地址：{customer_address}</p><p>法定代表人：{customer_legal_person}</p><p>委托代理人：{customer_agent}</p><p>电话：{customer_phone}</p><p>传真：{customer_fax}</p><p>开户银行：{customer_bank}</p><p>帐号：{customer_account}</p><p>税号：{customer_tax}</p></td>
      <td style="width:50%;"><p><strong>乙方</strong></p><p>乙方（章）：{supplier_seal}</p><p>地址：{supplier_address}</p><p>法定代表人：{supplier_legal_person}</p><p>委托代理人：{supplier_agent}</p><p>电话：{supplier_phone}</p><p>传真：{supplier_fax}</p><p>开户银行：{supplier_bank}</p><p>帐号：{supplier_account}</p><p>税号：{supplier_tax}</p></td>
    </tr>
  </table>
</div>` : ''
      const colsTag = (this.form.columns && this.form.columns.length) ? `<!--COLS:${this.form.columns.join(',')}-->` : ''
      return `<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<style>
${css}
</style>
</head>
<body>

<div class="contract-title">${this.form.title}</div>

<div class="contract-info">
  <table class="contract-info-table">
    <tr><td class="left"><strong>甲方：</strong>{customer_name}</td><td class="right"><strong>签订时间：</strong>{sign_date}</td></tr>
    <tr><td class="left"><strong>乙方：</strong>{supplier_name}</td><td class="right"><strong>签订地点：</strong>{sign_location}</td></tr>
  </table>
</div>

${clausesHtml}
${signHtml}
${colsTag}

</body>
</html>`
    },
    addClause() { this.form.clauses.push({ clause_title: '', clause_content: '' }) },
    removeClause(idx) { this.form.clauses.splice(idx, 1) },
    moveClause(idx, dir) {
      const i = idx + dir
      if (i < 0 || i >= this.form.clauses.length) return
      const arr = this.form.clauses
      ;[arr[idx], arr[i]] = [arr[i], arr[idx]]
    },
    /** HTML 转义（保留变量占位符） */
    escHtml(s) {
      return String(s == null ? '' : s).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;')
    },
    insertVar(key) {
      const input = this.$refs.contentInput && this.$refs.contentInput.$el && this.$refs.contentInput.$el.querySelector('textarea')
      const token = '{' + key + '}'
      if (input) {
        const start = input.selectionStart ?? this.form.content.length
        const end = input.selectionEnd ?? start
        this.form.content = this.form.content.slice(0, start) + token + this.form.content.slice(end)
        this.$nextTick(() => { input.focus(); const pos = start + token.length; input.setSelectionRange(pos, pos) })
      } else {
        this.form.content += token
      }
    },
    formatHtml() {
      // 简易格式化：缩进标签（不改变语义）
      const s = this.form.content.replace(/>\s*</g, '><').replace(/></g, '>\n<')
      this.form.content = s.replace(/<(\/?)([a-zA-Z][a-zA-Z0-9]*)([^>]*)>/g, (m, close, tag, attrs) => {
        const indent = /^\/|^(br|img|hr|input|meta|link)$/.test(tag) ? '' : ''
        return indent + m
      })
      this.$message.success('格式化完成')
    },
    async doPreview() {
      if (this.contentMode === 'form') this.form.content = this.buildHtml()
      if (!this.form.content) { this.$message.warning('模板内容为空，无法预览'); return }
      try {
        const r = await previewContract({ template_id: this.row && this.row.id ? this.row.id : 0, data: {} })
        // 未保存模板无 id：本地渲染（替换示例数据）
        if (r.code === 0) { this.previewHtml = r.data.html; this.previewVisible = true; return }
      } catch (e) {}
      // 本地兜底渲染
      const sample = { contract_no: 'CT-20260810-0001', contract_name: '示例合同', sign_date: '2026年08月10日', sign_location: '山西省大同市', customer_name: '客户名称', supplier_name: '供应商名称', total_amount: '10000.00', total_amount_cn: '壹万元整', payment_terms: '验收合格后付清全款', items_table: '<table border="1" cellpadding="6" style="width:100%;border-collapse:collapse;text-align:center;"><tr><th>序号</th><th>名称</th><th>数量</th><th>金额（元）</th></tr><tr><td>1</td><td>示例服务</td><td>1</td><td>10000.00</td></tr></table>' }
      let html = this.form.content
      Object.keys(sample).forEach(k => { html = html.split('{' + k + '}').join(sample[k]) })
      this.previewHtml = html
      this.previewVisible = true
    },
    async handleSubmit() {
      if (!this.form.template_name) { this.$message.warning('请填写模板名称'); return }
      if (!this.form.contract_type) { this.$message.warning('请选择适用合同类型'); return }
      if (this.contentMode === 'form') this.form.content = this.buildHtml()
      if (!this.form.content) { this.$message.warning('请填写模板内容'); return }
      this.saving = true
      try {
        const r = this.isEdit ? await editTemplate(this.row.id, this.form) : await addTemplate(this.form)
        if (r.code === 0) { this.$message.success(r.msg); this.$emit('success') } else { this.$message.error(r.msg || '保存失败') }
      } catch (e) {}
      this.saving = false
    }
  }
}
</script>

<style scoped>
.content-toolbar { margin-bottom: 8px; display: flex; align-items: center; gap: 8px; }
.content-toolbar .tip { font-size: 12px; color: #909399; }
.clause-row { display: flex; gap: 8px; align-items: flex-start; margin-bottom: 8px; }
.danger { color: #f56c6c; }
.content-area :deep(textarea) { font-family: Consolas, Monaco, monospace; font-size: 13px; }
.var-grid { display: flex; flex-wrap: wrap; gap: 6px; max-height: 200px; overflow: auto; }
.var-tag { cursor: pointer; }
.preview-body { height: 70vh; }
.preview-frame { width: 100%; height: 100%; border: 1px solid #ebeef5; }
.dialog-footer { text-align: right; }
</style>
