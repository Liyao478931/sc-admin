<!--
  文件：admin/src/views/business/contract/components/ContractFormDialog.vue
  功能：新增/编辑合同弹窗（两步）
    第一步：选择合同类型（销售/采购/维修服务）
    第二步：按类型动态填写（销售/维修→客户；采购→供应商）+ 条款 + 附件
-->
<template>
  <el-dialog
    :title="isEdit ? '编辑合同' : '新增合同'"
    :visible="visible"
    width="800px"
    :close-on-click-modal="false"
    @close="onClose"
  >
    <!-- 第一步：选择合同类型 -->
    <div v-if="step === 1" class="step-category">
      <div class="category-card" :class="{ active: form.contract_type === 'sales' }" @click="form.contract_type = 'sales'">
        <i class="el-icon-shopping-cart-2"></i><div class="cc-name">销售合同</div><div class="cc-desc">与客户签订的设备销售合同</div>
      </div>
      <div class="category-card" :class="{ active: form.contract_type === 'purchase' }" @click="form.contract_type = 'purchase'">
        <i class="el-icon-shopping-bag-1"></i><div class="cc-name">采购合同</div><div class="cc-desc">与供应商签订的配件采购/外协加工合同</div>
      </div>
      <div class="category-card" :class="{ active: form.contract_type === 'repair_service' }" @click="form.contract_type = 'repair_service'">
        <i class="el-icon-wrench"></i><div class="cc-name">维修服务合同</div><div class="cc-desc">与客户签订的长期设备维修服务协议</div>
      </div>
      <div class="step-actions">
        <el-button size="small" @click="$emit('update:visible', false)">取消</el-button>
        <el-button size="small" type="primary" :disabled="!form.contract_type" @click="step = 2">下一步</el-button>
      </div>
    </div>

    <!-- 第二步：选择合同模板（可选） -->
    <div v-else-if="step === 2" class="step-template">
      <div class="step-title">选择合同模板<span class="step-sub">可选，选择后自动生成合同内容</span></div>
      <div v-loading="tplLoading" class="template-list">
        <div v-for="t in filteredTemplateList" :key="t.id" class="template-card" :class="{ active: selectedTemplateId === t.id }" @click="selectedTemplateId = t.id">
          <div class="template-name">{{ t.template_name }}</div>
          <div class="template-type"><el-tag size="mini" :type="t.is_default ? 'success' : 'info'">{{ t.is_default ? '默认' : '可选' }}</el-tag></div>
          <div class="template-desc">适用于：{{ t.contract_type_text }}</div>
        </div>
        <el-empty v-if="!filteredTemplateList.length" description="该合同类型暂无启用模板，可跳过" :image-size="60" />
      </div>
      <div class="step-actions">
        <el-button size="small" @click="step = 1">上一步</el-button>
        <el-button size="small" @click="step = 3">跳过（不选模板）</el-button>
        <el-button size="small" type="primary" :disabled="!selectedTemplateId" @click="nextToInfo">下一步</el-button>
      </div>
    </div>

    <!-- 第三步：填写合同信息 -->
    <el-form v-else-if="step === 3" ref="form" :model="form" label-width="100px" size="small" v-loading="loading">
      <el-divider content-position="left">基本信息</el-divider>
      <el-row :gutter="12">
        <el-col :span="12">
          <el-form-item label="合同名称" prop="contract_name">
            <el-input v-model="form.contract_name" maxlength="200" placeholder="合同名称*" />
          </el-form-item>
        </el-col>
        <el-col :span="12">
          <el-form-item label="合同类型">
            <el-tag size="small" :type="typeTag(form.contract_type)">{{ typeText(form.contract_type) }}</el-tag>
          </el-form-item>
        </el-col>
        <el-col :span="12">
          <el-form-item :label="isPurchase ? '供应商' : '客户'" prop="party_id">
            <el-select v-model="partyId" filterable style="width:100%" :placeholder="'选择' + (isPurchase ? '供应商' : '客户')">
              <el-option v-for="p in partyOptions" :key="p.id" :label="p.customer_name || p.supplier_name" :value="p.id" />
            </el-select>
          </el-form-item>
        </el-col>
        <el-col :span="12">
          <el-form-item label="合同金额">
            <el-input-number v-model="form.contract_amount" :min="0" :precision="2" style="width:100%" />
          </el-form-item>
        </el-col>
        <el-col :span="8">
          <el-form-item label="签订日期" prop="sign_date">
            <el-date-picker v-model="form.sign_date" type="date" value-format="yyyy-MM-dd" style="width:100%" />
          </el-form-item>
        </el-col>
        <el-col :span="8">
          <el-form-item label="生效日期">
            <el-date-picker v-model="form.effective_date" type="date" value-format="yyyy-MM-dd" style="width:100%" />
          </el-form-item>
        </el-col>
        <el-col :span="8">
          <el-form-item label="到期日期">
            <el-date-picker v-model="form.expiry_date" type="date" value-format="yyyy-MM-dd" style="width:100%" />
          </el-form-item>
        </el-col>
        <el-col :span="12">
          <el-form-item label="联系人">
            <el-input v-model="form.contact_person" maxlength="50" />
          </el-form-item>
        </el-col>
        <el-col :span="12">
          <el-form-item label="联系电话">
            <el-input v-model="form.contact_phone" maxlength="20" />
          </el-form-item>
        </el-col>
        <el-col :span="12">
          <el-form-item label="签订地点">
            <el-input v-model="form.sign_location" maxlength="100" placeholder="如：山西省大同市" />
          </el-form-item>
        </el-col>
        <el-col :span="12">
          <el-form-item label="付款方式">
            <el-input v-model="form.payment_terms" maxlength="255" placeholder="如：验收合格后付清全款" />
          </el-form-item>
        </el-col>
        <el-col :span="12">
          <el-form-item label="合同内容">
            <el-input v-model="form.content" type="textarea" :rows="3" maxlength="2000" placeholder="合同条款摘要" />
          </el-form-item>
        </el-col>
      </el-row>

      <!-- 合同明细 -->
      <el-divider content-position="left">合同明细</el-divider>
      <div v-for="(it, idx) in form.items" :key="idx" class="item-row">
        <el-input v-model="it.name" placeholder="名称*" style="width:20%" />
        <el-input v-model="it.model" placeholder="型号" style="width:13%" />
        <el-input v-model="it.unit" placeholder="单位" style="width:9%" />
        <el-input-number v-model="it.qty" :min="0" size="small" style="width:13%" placeholder="数量" @change="calcItemAmount(it)" />
        <el-input-number v-model="it.price" :min="0" :precision="2" size="small" style="width:16%" placeholder="单价" @change="calcItemAmount(it)" />
        <el-input-number v-model="it.amount" :min="0" :precision="2" size="small" style="width:16%" placeholder="金额" />
        <el-button type="text" icon="el-icon-delete" class="danger" @click="form.items.splice(idx, 1)"></el-button>
      </div>
      <el-button size="mini" type="text" icon="el-icon-plus" @click="addItem">添加明细</el-button>
      <span v-if="itemTotal > 0" class="item-total">合计金额：¥{{ itemTotal.toLocaleString() }}</span>

      <!-- 合同条款 -->
      <el-divider content-position="left">合同条款</el-divider>
      <div v-for="(cl, idx) in form.clauses" :key="idx" class="clause-row">
        <el-input v-model="cl.clause_title" placeholder="条款标题*" style="width:200px" />
        <el-input v-model="cl.clause_content" placeholder="条款内容*" type="textarea" :rows="2" style="flex:1" />
        <el-button type="text" icon="el-icon-delete" class="danger" @click="form.clauses.splice(idx, 1)"></el-button>
      </div>
      <el-button size="mini" type="text" icon="el-icon-plus" @click="form.clauses.push({ clause_title: '', clause_content: '' })">添加条款</el-button>

      <!-- 附件 -->
      <el-divider content-position="left">附件</el-divider>
      <el-upload
        :action="uploadUrl" :headers="uploadHeaders" :show-file-list="true"
        :file-list="fileList" :on-success="handleUploadSuccess" :on-remove="handleUploadRemove"
        accept=".pdf,.doc,.docx,.xls,.xlsx"
      >
        <el-button size="small" type="primary" icon="el-icon-upload">上传附件</el-button>
      </el-upload>
        <div style="margin-top:6px">
          <el-button size="mini" type="primary" plain icon="el-icon-folder-opened" @click="driveVisible = true">从企业网盘选择</el-button>
        </div>
        <drive-file-picker :visible="driveVisible" mode="file" :multiple="true" @update:visible="driveVisible = $event" @confirm="onDrivePick" />

      <el-form-item label="备注">
        <el-input v-model="form.remark" type="textarea" :rows="2" maxlength="500" />
      </el-form-item>

      <div class="dialog-footer">
        <el-button size="small" type="text" @click="step = 2">上一步</el-button>
        <el-button size="small" @click="$emit('update:visible', false)">取消</el-button>
        <el-button size="small" type="primary" @click="goPreview">下一步（预览）</el-button>
      </div>
    </el-form>

    <!-- 第四步：预览合同 -->
    <div v-else-if="step === 4" class="step-preview">
      <div class="step-title">预览合同<span class="step-sub">确认内容无误后保存</span></div>
      <div class="preview-toolbar">
        <el-button size="small" @click="generateContractHtml">重新生成</el-button>
        <el-button size="small" @click="step = 3">编辑内容</el-button>
        <el-button size="small" type="primary" plain @click="previewPrint">打印预览</el-button>
      </div>
      <div v-loading="genLoading" class="preview-content" v-html="contractHtml"></div>
      <div class="step-actions">
        <el-button size="small" @click="step = 3">上一步</el-button>
        <el-button size="small" type="primary" :loading="saving" @click="handleSubmit">确认保存</el-button>
      </div>
    </div>
  </el-dialog>
</template>

<script>
import { addContract, editContract, getContractDetail, previewContractByTemplate } from '../../../../api/businessContract'
import { getCustomerOptions } from '../../../../api/businessCustomer'
import { getSupplierOptions } from '../../../../api/businessSupplier'
import { getAvailableTemplates, getTemplateDetail } from '../../../../api/contractTemplate'
import { getToken } from '../../../../utils/auth'

export default {
  name: 'ContractFormDialog',
  props: {
    visible: { type: Boolean, default: false },
    row: { type: Object, default: null }
  },
  data() {
    return {
      step: 1, loading: false, saving: false, genLoading: false,
      customerOptions: [], supplierOptions: [],
      templateList: [], selectedTemplateId: null, contractHtml: '', tplLoading: false,
      partyId: null,
      fileList: [], driveVisible: false,
      form: {
        contract_type: '', contract_name: '', contract_amount: 0,
        sign_date: '', effective_date: '', expiry_date: '',
        responsible_person_id: null, contact_person: '', contact_phone: '',
        content: '', remark: '', clauses: [], attachments: [], payment_terms: '', sign_location: '', items: []
      }
    }
  },
  computed: {
    isEdit() { return !!(this.row && this.row.id) },
    isPurchase() { return this.form.contract_type === 'purchase' },
    partyOptions() { return this.isPurchase ? this.supplierOptions : this.customerOptions },
    filteredTemplateList() { return this.templateList.filter(t => !this.form.contract_type || t.contract_type === this.form.contract_type) },
    itemTotal() { return (this.form.items || []).reduce((s, it) => s + (Number(it.amount) || 0), 0) },
    uploadUrl() { return '/api/upload' },
    uploadHeaders() { return { Authorization: 'Bearer ' + getToken() } }
  },
  watch: {
    visible(val) { if (val) this.open() }
  },
  methods: {
    typeText(t) { return { sales: '销售合同', purchase: '采购合同', repair_service: '维修服务合同' }[t] || t },
    typeTag(t) { return { sales: 'primary', purchase: 'success', repair_service: 'warning' }[t] || 'info' },
    async open() {
      this.step = 1
      this.loading = true
      this.form = { contract_type: '', contract_name: '', contract_amount: 0, sign_date: this.today(), effective_date: '', expiry_date: '', responsible_person_id: null, contact_person: '', contact_phone: '', content: '', remark: '', clauses: [], attachments: [], payment_terms: '', sign_location: '', items: [] }
      this.partyId = null
      this.fileList = []
      this.selectedTemplateId = null
      this.contractHtml = ''
      // 加载可用模板
      try { const r = await getAvailableTemplates(); this.templateList = (r.data && r.data.list) || [] } catch (e) { this.templateList = [] }
      // 加载下拉
      try { const r = await getCustomerOptions(); this.customerOptions = r.data || [] } catch (e) { this.customerOptions = [] }
      try { const r = await getSupplierOptions(); this.supplierOptions = r.data || [] } catch (e) { this.supplierOptions = [] }

      if (this.isEdit) {
        try {
          const r = await getContractDetail(this.row.id)
          if (r.code === 0) {
            const d = r.data
            this.form = {
              contract_type: d.contract_type, contract_name: d.contract_name, contract_amount: Number(d.contract_amount) || 0,
              sign_date: d.sign_date, effective_date: d.effective_date || '', expiry_date: d.expiry_date || '',
              responsible_person_id: d.responsible_person_id || null, contact_person: d.contact_person || '',
              contact_phone: d.contact_phone || '', content: d.content || '', remark: d.remark || '',
              clauses: (d.clauses || []).map(c => ({ clause_title: c.clause_title, clause_content: c.clause_content })),
              attachments: d.attachments || [], payment_terms: d.payment_terms || '', sign_location: d.sign_location || '',
              items: (d.items || []).map(it => ({ ...it }))
            }
            this.contractHtml = d.contract_html || ''
            this.partyId = d.customer_id || d.supplier_id || null
            this.fileList = (d.attachments || []).map(u => ({ name: u.split('/').pop(), url: u }))
            this.step = 3
          }
        } catch (e) {}
      } else {
        this.form.sign_date = this.today()
        this.form.clauses.push({ clause_title: '', clause_content: '' })
      }
      this.loading = false
    },
    today() { const d = new Date(); return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}` },
    addItem() { this.form.items.push({ name: '', model: '', unit: '', qty: 1, price: 0, amount: 0, remark: '' }) },
    calcItemAmount(it) { it.amount = (Number(it.qty) || 0) * (Number(it.price) || 0) },
    /** 第二步下一步：进编辑区前预填模板条款 */
    async nextToInfo() {
      if (this.selectedTemplateId) await this.loadTemplateClauses()
      this.step = 3
    },
    /** 从模板详情解析条款并预填到「合同条款」（替换变量为可读值） */
    async loadTemplateClauses() {
      try {
        const r = await getTemplateDetail(this.selectedTemplateId)
        if (r.code === 0 && r.data && r.data.content) {
          const clauses = []
          const re = /<p><strong>(第[一二三四五六七八九十百\d]+条[^<]*?)<\/strong>(.*?)<\/p>/g
          let m
          while ((m = re.exec(r.data.content))) {
            let content = m[2].trim()
            content = content.replace(/\{payment_terms\}/g, this.form.payment_terms || '付款方式')
            content = content.replace(/\{items_table\}/g, '（详见合同明细）')
            content = content.replace(/\{total_amount\}/g, String(this.form.contract_amount || ''))
            content = content.replace(/\{[a-zA-Z_][a-zA-Z0-9_]*\}/g, '')
            clauses.push({ clause_title: m[1].trim(), clause_content: content })
          }
          if (clauses.length) this.form.clauses = clauses
        }
      } catch (e) {}
    },
    async goPreview() {
      if (this.selectedTemplateId) {
        await this.generateContractHtml()
      } else {
        this.contractHtml = this.form.content || ''
      }
      this.step = 4
    },
    async generateContractHtml() {
      if (!this.selectedTemplateId) { this.$message.warning('请先选择模板'); return }
      const party = this.partyOptions.find(p => p.id === this.partyId)
      const partyName = party ? (party.customer_name || party.supplier_name) : ''
      this.genLoading = true
      try {
        const r = await previewContractByTemplate({
          template_id: this.selectedTemplateId,
          data: {
            contract_name: this.form.contract_name,
            contract_type: this.form.contract_type,
            sign_date: this.form.sign_date,
            customer_id: this.isPurchase ? 0 : this.partyId,
            supplier_id: this.isPurchase ? this.partyId : 0,
            customer_name: this.isPurchase ? '' : partyName,
            supplier_name: this.isPurchase ? partyName : '',
            total_amount: String(this.form.contract_amount || ''),
            payment_terms: this.form.payment_terms || '',
            sign_location: this.form.sign_location || '',
            items: this.form.items || []
          }
        })
        if (r.code === 0 && r.data && r.data.html) {
          this.contractHtml = r.data.html
          this.form.content = r.data.html
          this.$message.success('已按模板生成合同内容')
        } else {
          this.$message.error((r.data && r.data.msg) || r.msg || '生成失败')
        }
      } catch (e) {
        console.error('模板生成失败', e)
        this.$message.error('模板生成失败，请重试或检查模板配置')
      }
      this.genLoading = false
    },
    previewPrint() {
      const w = window.open('', '_blank')
      if (w) { w.document.write(this.contractHtml || this.form.content || ''); w.document.close(); w.print() }
    },
    onClose() { this.step = 1; this.$emit('update:visible', false) },
    handleUploadSuccess(res) {
      if (res.code === 0 && res.data && res.data.url) {
        this.form.attachments.push(res.data.url)
        this.$message.success('上传成功')
      } else {
        this.$message.error(res.msg || '上传失败')
      }
    },
    onDrivePick(list) {
      list.forEach(f => {
        if (this.form.attachments.length >= 10) return
        this.form.attachments.push(f.url)
        this.fileList.push({ name: f.name, url: f.url })
      })
    },
    handleUploadRemove(file) {
      const url = file.url || (file.response && file.response.data && file.response.data.url)
      this.form.attachments = this.form.attachments.filter(u => u !== url)
    },
    async handleSubmit() {
      if (!this.form.contract_name) { this.$message.warning('请填写合同名称'); return }
      if (!this.partyId) { this.$message.warning(this.isPurchase ? '请选择供应商' : '请选择客户'); return }
      if (!this.form.sign_date) { this.$message.warning('请选择签订日期'); return }
      const invalidClause = this.form.clauses.findIndex(c => !c.clause_title || !c.clause_content)
      if (invalidClause > -1) { this.$message.warning(`第 ${invalidClause + 1} 条条款：标题和内容不能为空`); return }
      this.saving = true
      try {
        const payload = {
          ...this.form,
          contract_amount: (this.form.items && this.form.items.length) ? this.itemTotal : this.form.contract_amount,
          customer_id: this.isPurchase ? 0 : this.partyId,
          supplier_id: this.isPurchase ? this.partyId : 0,
          responsible_person_id: 0, // 负责人=创建人，由后端取当前登录用户
          template_id: this.selectedTemplateId || 0,
          contract_html: this.contractHtml || '',
          items: this.form.items || [],
          clauses: this.form.clauses.filter(c => c.clause_title && c.clause_content)
        }
        if (this.isEdit) {
          const r = await editContract(this.row.id, payload)
          if (r.code === 0) { this.$message.success('合同已更新'); this.$emit('success') }
        } else {
          const r = await addContract(payload)
          if (r.code === 0) { this.$message.success('合同创建成功'); this.$emit('success') }
        }
      } catch (e) {}
      this.saving = false
    }
  }
}
</script>

<style scoped>
.step-category { display: flex; gap: 12px; padding: 20px 0; }
.category-card {
  flex: 1; border: 1px solid #dcdfe6; border-radius: 8px; padding: 24px 14px; text-align: center; cursor: pointer; transition: all .2s;
}
.category-card i { font-size: 34px; color: #909399; }
.category-card.active { border-color: #409eff; background: #ecf5ff; }
.category-card.active i { color: #409eff; }
.cc-name { font-size: 15px; font-weight: 600; margin: 8px 0 4px; color: #303133; }
.cc-desc { font-size: 11px; color: #909399; line-height: 1.5; }
.step-actions { margin-top: 20px; text-align: right; }
.clause-row { display: flex; gap: 8px; align-items: flex-start; margin-bottom: 8px; }
.item-row { display: flex; gap: 6px; align-items: center; margin-bottom: 6px; }
.item-total { margin-left: 10px; font-size: 12px; color: #e6a23c; }
.tpl-tip { font-size: 12px; color: #909399; line-height: 1.5; margin-top: 2px; }
.step-template { padding: 12px 0; }
.step-title { font-size: 15px; font-weight: 600; color: #303133; margin-bottom: 12px; }
.step-sub { font-size: 12px; color: #909399; font-weight: normal; margin-left: 8px; }
.template-list { display: flex; flex-wrap: wrap; gap: 12px; min-height: 120px; }
.template-card { width: 200px; border: 1px solid #dcdfe6; border-radius: 8px; padding: 14px; cursor: pointer; transition: all .2s; }
.template-card.active { border-color: #409eff; background: #ecf5ff; }
.template-name { font-size: 14px; font-weight: 600; color: #303133; }
.template-type { margin: 6px 0; }
.template-desc { font-size: 12px; color: #909399; }
.preview-toolbar { margin-bottom: 10px; }
.preview-content { max-height: 55vh; overflow-y: auto; padding: 16px; background: #fff; border: 1px solid #e8ecf1; font-family: 'SimSun', '宋体', serif; font-size: 14px; line-height: 1.8; }
.preview-content table { width: 100%; border-collapse: collapse; margin: 15px 0; }
.preview-content th, .preview-content td { border: 1px solid #333; padding: 6px 10px; text-align: center; }
.preview-content .contract-title { text-align: center; font-size: 22px; font-weight: bold; padding: 20px 0; }
.preview-content .sign-area { margin-top: 30px; }
.preview-content .sign-area table { border: none; }
.preview-content .sign-area td { border: none; vertical-align: top; padding: 10px 20px; width: 50%; }
.dialog-footer { text-align: right; }
.danger { color: #f56c6c; }
</style>
