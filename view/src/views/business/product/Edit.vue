<!--
  文件：admin/src/views/business/product/Edit.vue
  功能：编辑产品（编码只读；支持维护产品技术参数）
-->
<template>
  <div class="product-form-page">
    <el-breadcrumb separator="/" class="breadcrumb">
      <el-breadcrumb-item>经营管理</el-breadcrumb-item>
      <el-breadcrumb-item>产品管理</el-breadcrumb-item>
      <el-breadcrumb-item>编辑产品</el-breadcrumb-item>
    </el-breadcrumb>

    <el-card shadow="never">
      <el-form ref="form" :model="form" :rules="rules" label-width="100px" size="small" style="max-width:640px">
        <el-form-item label="产品编码">
          <el-input :value="productCode" disabled />
        </el-form-item>
        <el-form-item label="产品名称" prop="product_name">
          <el-input v-model="form.product_name" placeholder="请输入产品名称" clearable />
        </el-form-item>
        <el-form-item label="产品分类" prop="category_id">
          <el-cascader
            v-model="categoryPath"
            :options="categoryOptions"
            :props="{ value: 'value', label: 'label', children: 'children' }"
            clearable
            filterable
            style="width:100%"
            placeholder="请选择产品分类（可空）"
            @change="onCategoryChange"
          />
        </el-form-item>
        <el-form-item label="规格型号" prop="specification">
          <el-input v-model="form.specification" placeholder="请输入规格型号" clearable />
        </el-form-item>
        <el-form-item label="单位" prop="unit">
          <el-input v-model="form.unit" placeholder="请输入单位" clearable style="width:200px" />
        </el-form-item>
        <el-form-item label="排序" prop="sort">
          <el-input-number v-model="form.sort" :min="0" :max="9999" />
        </el-form-item>
        <el-form-item label="状态" prop="status">
          <el-radio-group v-model="form.status">
            <el-radio :label="1">启用</el-radio>
            <el-radio :label="0">停用</el-radio>
          </el-radio-group>
        </el-form-item>
        <el-form-item label="备注" prop="remark">
          <el-input v-model="form.remark" type="textarea" :rows="3" placeholder="请输入备注（可选）" />
        </el-form-item>
      </el-form>
    </el-card>

    <!-- ===== 产品参数 ===== -->
    <el-card shadow="never" class="param-card">
      <div slot="header" class="param-header">
        <span>产品参数</span>
        <el-button type="text" icon="el-icon-plus" @click="addParam">添加参数</el-button>
      </div>
      <el-table :data="params" size="small" border v-if="params.length">
        <el-table-column label="参数名称" min-width="180">
          <template slot-scope="s">
            <el-input v-model="s.row.param_name" placeholder="如 额定功率" size="mini" />
          </template>
        </el-table-column>
        <el-table-column label="参数值" min-width="200">
          <template slot-scope="s">
            <el-input v-model="s.row.param_value" placeholder="参数值" size="mini" />
          </template>
        </el-table-column>
        <el-table-column label="单位" width="120">
          <template slot-scope="s">
            <el-input v-model="s.row.param_unit" placeholder="如 kW" size="mini" />
          </template>
        </el-table-column>
        <el-table-column label="操作" width="80" align="center">
          <template slot-scope="s">
            <el-button type="text" size="mini" class="danger" @click="removeParam(s.$index)">删除</el-button>
          </template>
        </el-table-column>
      </el-table>
      <el-empty v-else description="暂无参数，点击右上角「添加参数」新增" :image-size="70" />
    </el-card>

    <div class="form-actions">
      <el-button type="primary" :loading="submitting" @click="submit">保存</el-button>
      <el-button @click="$router.back()">取消</el-button>
    </div>
  </div>
</template>

<script>
import { getProductDetail, getProductParams, editProduct, getProductCategoryTree } from '../../../api/product'

export default {
  name: 'BusinessProductEdit',
  data() {
    return {
      id: Number(this.$route.params.id) || 0,
      submitting: false,
      productCode: '',
      categoryOptions: [],
      categoryPath: [],
      form: { product_name: '', category_id: null, specification: '', unit: '', sort: 0, status: 1, remark: '' },
      params: [],
      rules: {
        product_name: [{ required: true, message: '请输入产品名称', trigger: 'blur' }]
      }
    }
  },
  async created() {
    // 先加载分类树再加载详情，保证分类级联能正确回显（避免竞态）
    await this.loadCategoryTree()
    await this.loadDetail()
    this.loadParams()
  },
  methods: {
    async loadCategoryTree() {
      try {
        const r = await getProductCategoryTree()
        this.categoryOptions = (r && r.code === 0 && r.data) ? r.data : []
      } catch (e) {
        this.categoryOptions = []
      }
    },
    async loadDetail() {
      try {
        const r = await getProductDetail(this.id)
        if (r.code === 0 && r.data) {
          const d = r.data
          this.productCode = d.product_code || ''
          this.form.product_name = d.product_name || ''
          this.form.specification = d.specification || ''
          this.form.unit = d.unit || ''
          this.form.sort = d.sort || 0
          this.form.status = d.status === 0 ? 0 : 1
          this.form.remark = d.remark || ''
          if (d.category_id) {
            this.form.category_id = Number(d.category_id)
            this.categoryPath = this.findPath(this.categoryOptions, Number(d.category_id))
          }
        } else {
          this.$message.error(r.msg || '产品不存在')
        }
      } catch (e) {}
    },
    async loadParams() {
      try {
        const r = await getProductParams(this.id)
        if (r.code === 0 && r.data && r.data.params) {
          this.params = r.data.params.map(p => ({
            param_name: p.param_name || '',
            param_value: p.param_value || '',
            param_unit: p.param_unit || ''
          }))
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
    addParam() {
      this.params.push({ param_name: '', param_value: '', param_unit: '' })
    },
    removeParam(idx) {
      this.params.splice(idx, 1)
    },
    submit() {
      this.$refs.form.validate(async valid => {
        if (!valid) return
        this.submitting = true
        try {
          const payload = { ...this.form, params: this.params.map((p, i) => ({ ...p, sort: i + 1 })) }
          const r = await editProduct(this.id, payload)
          if (r.code === 0) {
            this.$message.success('产品已更新')
            this.$router.push('/business/product/list')
          }
        } catch (e) {}
        this.submitting = false
      })
    }
  }
}
</script>

<style scoped>
.product-form-page { padding: 4px 16px; }
.breadcrumb { margin-bottom: 14px; }
.param-card { margin-top: 14px; }
.param-header { display: flex; align-items: center; justify-content: space-between; }
.form-actions { margin: 16px 0; }
.danger { color: #f56c6c; }
</style>
