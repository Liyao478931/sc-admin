<!--
  文件：admin/src/views/business/product/Add.vue
  功能：新增产品（编码由后端生成；支持产品技术参数维护；支持列表"复制产品" query.copyFrom 自动填充）
-->
<template>
  <div class="product-form-page">
    <el-breadcrumb separator="/" class="breadcrumb">
      <el-breadcrumb-item>经营管理</el-breadcrumb-item>
      <el-breadcrumb-item>产品管理</el-breadcrumb-item>
      <el-breadcrumb-item>新增产品</el-breadcrumb-item>
    </el-breadcrumb>

    <el-card shadow="never">
      <el-form ref="form" :model="form" :rules="rules" label-width="100px" size="small" style="max-width:640px">
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
import { addProduct, getProductCategoryTree } from '../../../api/product'

export default {
  name: 'BusinessProductAdd',
  data() {
    return {
      submitting: false,
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
    // 先加载分类树再应用复制数据，保证分类级联路径能正确填充（避免竞态）
    await this.loadCategoryTree()
    this.applyCopyFrom()
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
    /** 从列表"复制产品"进入：query.copyFrom 为 JSON 字符串，填充业务字段与参数（编码由后端生成） */
    applyCopyFrom() {
      const raw = this.$route.query && this.$route.query.copyFrom
      if (!raw) return
      try {
        const data = JSON.parse(raw)
        this.form.product_name = data.product_name || ''
        this.form.specification = data.specification || ''
        this.form.unit = data.unit || ''
        this.form.sort = data.sort || 0
        this.form.status = data.status === 0 ? 0 : 1
        this.form.remark = data.remark || ''
        if (data.category_id) {
          this.categoryPath = this.findPath(this.categoryOptions, Number(data.category_id))
          this.form.category_id = Number(data.category_id)
        }
        this.params = Array.isArray(data.params) ? data.params.map(p => ({
          param_name: p.param_name || '',
          param_value: p.param_value || '',
          param_unit: p.param_unit || ''
        })) : []
      } catch (e) {
        // copyFrom 解析失败则忽略
      }
    },
    /** 在分类树中查找指定 ID 的完整路径（value 数组） */
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
          const r = await addProduct(payload)
          if (r.code === 0) {
            this.$message.success('产品创建成功')
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
