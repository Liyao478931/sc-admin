<!--
  文件：admin/src/views/business/product/drawing/Upload.vue
  功能：上传图纸（新增）/ 编辑图纸（复用，路由 /edit/:id）
  权限：新增 business:product:drawing:add；编辑 business:product:drawing:edit
-->
<template>
  <div class="drawing-upload-page">
    <el-breadcrumb separator="/" class="breadcrumb">
      <el-breadcrumb-item>经营管理</el-breadcrumb-item>
      <el-breadcrumb-item>产品管理</el-breadcrumb-item>
      <el-breadcrumb-item>图纸管理</el-breadcrumb-item>
      <el-breadcrumb-item>{{ isEdit ? '编辑图纸' : '上传图纸' }}</el-breadcrumb-item>
    </el-breadcrumb>

    <div class="page-header">
      <span class="page-title">{{ isEdit ? '编辑图纸 - ' + form.drawing_code : '上传图纸' }}</span>
      <div class="header-actions">
        <el-button type="primary" size="small" :loading="submitting" @click="handleSave">保存</el-button>
        <el-button size="small" @click="handleCancel">取消</el-button>
      </div>
    </div>

    <el-card shadow="never">
      <el-row :gutter="24">
        <!-- 左侧表单 -->
        <el-col :span="14">
          <el-form ref="form" :model="form" :rules="rules" label-width="120px" size="small">
            <el-form-item label="关联产品" prop="product_id">
              <ProductSelector v-model="form.product_id" :label-text="productLabel" @input="onProductChange" />
            </el-form-item>
            <el-form-item label="图纸编号" prop="drawing_code">
              <el-input v-model="form.drawing_code" placeholder="留空自动生成 DWG+日期+序号" clearable @blur="checkCode" @input="codeChecked = false" />
              <div v-if="codeError" class="code-error">{{ codeError }}</div>
            </el-form-item>
            <el-form-item label="图纸名称" prop="drawing_name">
              <el-input v-model="form.drawing_name" placeholder="请输入图纸名称" clearable />
            </el-form-item>
            <el-form-item label="图纸类型" prop="drawing_type">
              <el-select v-model="form.drawing_type" style="width:100%">
                <el-option label="CAD图纸" :value="1" />
                <el-option label="PDF图纸" :value="2" />
                <el-option label="图片" :value="3" />
                <el-option label="三维模型" :value="4" />
                <el-option label="其他" :value="5" />
              </el-select>
            </el-form-item>
            <el-form-item label="图纸分类" prop="category_id">
              <el-cascader
                v-model="categoryPath"
                :options="categoryOptions"
                :props="{ value: 'value', label: 'label', children: 'children' }"
                clearable
                filterable
                style="width:100%"
                placeholder="选择图纸分类（可空）"
                @change="onCategoryChange"
              />
            </el-form-item>
            <el-form-item label="版本号" prop="version">
              <el-input v-model="form.version" placeholder="如 V1.0" clearable />
            </el-form-item>
            <el-form-item label="状态">
              <el-switch v-model="form.status" :active-value="1" :inactive-value="0" />
            </el-form-item>
            <el-form-item label="备注" prop="remark">
              <el-input v-model="form.remark" type="textarea" :rows="3" placeholder="备注说明（可选）" />
            </el-form-item>
          </el-form>
        </el-col>
        <!-- 右侧文件上传 -->
        <el-col :span="10">
          <div class="upload-title">图纸文件</div>
          <FileUploader :file-type="form.drawing_type" :existing-file="existingFile" @file="v => (selectedFile = v)" />
        </el-col>
      </el-row>
    </el-card>
  </div>
</template>

<script>
import ProductSelector from '../bom/components/ProductSelector.vue'
import FileUploader from './components/FileUploader.vue'
import { getDrawingDetail, saveDrawing, checkDrawingCode, getDrawingCategoryTree } from '../../../../api/product'

export default {
  name: 'BusinessProductDrawingUpload',
  components: { ProductSelector, FileUploader },
  data() {
    return {
      id: Number(this.$route.params.id) || 0,
      submitting: false,
      isEdit: false,
      categoryOptions: [],
      categoryPath: [],
      productLabel: '',
      selectedFile: null,
      existingFile: {},
      codeError: '',
      codeChecked: false,
      form: {
        product_id: null,
        drawing_code: '',
        drawing_name: '',
        drawing_type: 1,
        category_id: null,
        version: 'V1.0',
        status: 1,
        remark: ''
      },
      rules: {
        product_id: [{ required: true, message: '请选择关联产品', trigger: 'change' }],
        drawing_name: [{ required: true, message: '请输入图纸名称', trigger: 'blur' }],
        drawing_type: [{ required: true, message: '请选择图纸类型', trigger: 'change' }]
      }
    }
  },
  async created() {
    this.isEdit = this.id > 0
    await this.loadCategoryTree()
    if (this.isEdit) await this.loadDetail()
    else this.form.drawing_code = this.genCode()
  },
  methods: {
    genCode() {
      const d = new Date()
      const pad = x => String(x).padStart(2, '0')
      return 'DWG' + d.getFullYear() + pad(d.getMonth() + 1) + pad(d.getDate()) + '0001'
    },
    async loadCategoryTree() {
      try {
        const r = await getDrawingCategoryTree()
        this.categoryOptions = (r && r.code === 0 && r.data) ? r.data : []
      } catch (e) { this.categoryOptions = [] }
    },
    async loadDetail() {
      try {
        const r = await getDrawingDetail(this.id)
        if (r.code === 0 && r.data && r.data.drawing) {
          const d = r.data.drawing
          this.form = {
            product_id: d.product_id,
            drawing_code: d.drawing_code,
            drawing_name: d.drawing_name,
            drawing_type: d.drawing_type,
            category_id: d.category_id || null,
            version: d.version,
            status: d.status,
            remark: d.remark || ''
          }
          this.productLabel = (d.product_code ? d.product_code + ' ' : '') + (d.product_name || '')
          this.existingFile = { file_name: d.file_name, file_path: d.file_path, file_size: d.file_size, file_ext: d.file_ext }
          if (d.category_id) this.categoryPath = this.findPath(this.categoryOptions, Number(d.category_id))
        } else {
          this.$message.error(r.msg || '图纸不存在')
          this.$router.push('/business/product/drawing/list')
        }
      } catch (e) {}
    },
    findPath(options, id, trail) {
      const path = trail || []
      for (let i = 0; i < options.length; i++) {
        const node = options[i]
        const next = path.concat([node.value])
        if (node.value === id) return next
        if (node.children && node.children.length) {
          const found = this.findPath(node.children, id, next)
          if (found) return found
        }
      }
      return []
    },
    onCategoryChange() {
      this.form.category_id = this.categoryPath.length ? this.categoryPath[this.categoryPath.length - 1] : null
    },
    onProductChange() { this.codeChecked = false },
    async checkCode() {
      const code = (this.form.drawing_code || '').trim()
      if (!code) { this.codeError = ''; return }
      try {
        const r = await checkDrawingCode(code, this.id)
        const exists = r.code === 0 && r.data && r.data.exists
        this.codeChecked = true
        this.codeError = exists ? '该图纸编号已存在，请重新输入' : ''
      } catch (e) { this.codeError = '' }
    },
    handleSave() {
      this.$refs.form.validate(async valid => {
        if (!valid) return
        if (this.codeError) { this.$message.warning('图纸编号已存在，请修改后再保存'); return }
        if (!this.isEdit && !this.selectedFile) { this.$message.warning('请上传图纸文件'); return }
        this.submitting = true
        try {
          const fd = new FormData()
          if (this.isEdit) fd.append('id', this.id)
          fd.append('product_id', this.form.product_id)
          fd.append('drawing_code', this.form.drawing_code)
          fd.append('drawing_name', this.form.drawing_name)
          fd.append('drawing_type', this.form.drawing_type)
          if (this.form.category_id) fd.append('category_id', this.form.category_id)
          fd.append('version', this.form.version || 'V1.0')
          fd.append('status', this.form.status)
          if (this.form.remark) fd.append('remark', this.form.remark)
          if (this.selectedFile) fd.append('file', this.selectedFile)
          const r = await saveDrawing(fd)
          if (r.code === 0) { this.$message.success('保存成功'); this.$router.push('/business/product/drawing/list') }
        } catch (e) {}
        this.submitting = false
      })
    },
    handleCancel() {
      if (this.form.product_id || this.form.drawing_name || this.selectedFile) {
        this.$confirm('当前有未保存内容，确认离开吗？', '提示', { type: 'warning' }).then(() => this.$router.push('/business/product/drawing/list')).catch(() => {})
      } else {
        this.$router.push('/business/product/drawing/list')
      }
    }
  }
}
</script>

<style scoped>
.drawing-upload-page { padding: 4px 16px; }
.breadcrumb { margin-bottom: 14px; }
.page-header { display: flex; align-items: center; justify-content: space-between; margin-bottom: 14px; }
.page-title { font-size: 18px; font-weight: 700; color: #303133; }
.header-actions .el-button + .el-button { margin-left: 10px; }
.upload-title { font-size: 14px; font-weight: 600; color: #303133; margin-bottom: 12px; }
.code-error { color: #f56c6c; font-size: 12px; line-height: 1.4; margin-top: 4px; }
</style>
