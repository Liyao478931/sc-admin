<!--
  文件：admin/src/views/business/purchase/request/components/RequestItemTable.vue
  功能：采购明细可编辑表格（产品远程搜索/数量/单价/总价/需求日期/删除/从来源导入/添加产品 + 合计）
  props：items（数组，直接修改）、disabled、canImport（是否可选来源导入）
  emits：import-source（请求从来源导入明细）
-->
<template>
  <div class="request-items">
    <div class="toolbar">
      <el-button v-if="!disabled" type="primary" size="small" icon="el-icon-plus" @click="openAdd">添加产品</el-button>
      <el-button v-if="!disabled && canImport" size="small" icon="el-icon-download" @click="$emit('import-source')">从来源订单导入明细</el-button>
      <span class="flex-1"></span>
      <span class="total-tip">合计总价：¥ {{ totalAmount }}</span>
    </div>

    <el-table :data="items" size="small" border>
      <el-table-column type="index" label="序号" width="55" align="center" />
      <el-table-column label="产品" min-width="220">
        <template slot-scope="s">
          <ProductSelector v-model="s.row.product_id" :label-text="s.row.product_code + ' ' + s.row.product_name" @selected="p => onProductPicked(s.row, p)" />
        </template>
      </el-table-column>
      <el-table-column prop="product_code" label="产品编码" width="120" show-overflow-tooltip />
      <el-table-column prop="product_name" label="产品名称" min-width="120" show-overflow-tooltip />
      <el-table-column prop="product_spec" label="规格型号" width="110" show-overflow-tooltip />
      <el-table-column prop="product_unit" label="单位" width="60" align="center" />
      <el-table-column label="申请数量" width="110">
        <template slot-scope="s">
          <el-input-number v-model="s.row.quantity" :disabled="disabled" :min="1" :precision="0" size="mini" style="width:100%" @change="recalc" />
        </template>
      </el-table-column>
      <el-table-column label="采购单价" width="120">
        <template slot-scope="s">
          <el-input-number v-model="s.row.unit_price" :disabled="disabled" :min="0.01" :precision="2" size="mini" style="width:100%" @change="recalc" />
        </template>
      </el-table-column>
      <el-table-column label="总价" width="100" align="right">
        <template slot-scope="s">{{ fmt(s.row.quantity * s.row.unit_price) }}</template>
      </el-table-column>
      <el-table-column label="需求日期" width="130">
        <template slot-scope="s">
          <el-date-picker v-model="s.row.need_date" :disabled="disabled" type="date" value-format="yyyy-MM-dd" size="mini" style="width:100%" />
        </template>
      </el-table-column>
      <el-table-column label="操作" width="70" align="center" fixed="right">
        <template slot-scope="s">
          <el-button v-if="!disabled" type="text" size="mini" class="danger" @click="removeRow(s.$index)">删除</el-button>
        </template>
      </el-table-column>
    </el-table>
    <el-empty v-if="!items.length" description="暂无明细，点击右上角「添加产品」或「从来源订单导入明细」" :image-size="70" />

    <!-- 添加产品弹窗（支持多选） -->
    <el-dialog title="选择产品" :visible="addVisible" width="620px" :close-on-click-modal="false" @close="addVisible = false">
      <el-form label-width="90px" size="small">
        <el-form-item label="搜索产品">
          <el-select v-model="pickedIds" filterable multiple remote :remote-method="searchProducts" :loading="searching" placeholder="点击即可查看全部产品与物料，输入编码/名称可精确搜索" style="width:100%" @visible-change="handleSelectVisible">
            <el-option v-for="p in productOptions" :key="p._key" :value="p._key" :label="p.product_code + ' ' + p.product_name + (p.specification ? ' [' + p.specification + ']' : '') + (p._src === 'material' ? '（物料）' : '')" />
          </el-select>
        </el-form-item>
      </el-form>
      <div slot="footer">
        <el-button size="small" @click="addVisible = false">取消</el-button>
        <el-button size="small" type="primary" @click="confirmAdd">添加</el-button>
      </div>
    </el-dialog>
  </div>
</template>

<script>
import ProductSelector from '../../../product/bom/components/ProductSelector.vue'
import { searchProducts } from '../../../../../api/product'
import { getMaterialList } from '../../../../../api/warehouse'

export default {
  name: 'RequestItemTable',
  components: { ProductSelector },
  props: {
    items: { type: Array, required: true },
    disabled: { type: Boolean, default: false },
    canImport: { type: Boolean, default: false }
  },
  data() {
    return {
      addVisible: false,
      pickedIds: [],
      productOptions: [],
      searching: false
    }
  },
  computed: {
    totalAmount() {
      return this.fmt(this.items.reduce((s, it) => s + (Number(it.quantity) || 0) * (Number(it.unit_price) || 0), 0))
    }
  },
  methods: {
    fmt(v) { return Number(v).toFixed(2) },
    async searchProducts(keyword) {
      this.searching = true
      try {
        // 合并搜索：产品（business_products）+ 物料（warehouse_material）
        const [pr, mr] = await Promise.all([
          searchProducts(keyword || ''),
          getMaterialList({ keyword: keyword || '', page: 1, pageSize: 100, status: 1 })
        ])
        const products = ((pr.code === 0 && pr.data) ? pr.data : []).map(p => ({
          _key: 'p' + p.id, _src: 'product', id: p.id,
          product_code: p.product_code, product_name: p.product_name,
          specification: p.specification || '', unit: p.unit || '', unit_price: p.unit_price || 0
        }))
        const materials = ((mr.code === 0 && mr.data && mr.data.list) ? mr.data.list : []).map(m => ({
          _key: 'm' + m.id, _src: 'material', id: m.id,
          product_code: m.material_code, product_name: m.material_name,
          specification: m.specification || '', unit: m.unit || '', unit_price: Number(m.reference_price) || 0
        }))
        this.productOptions = [...products, ...materials]
      } catch (e) { this.productOptions = [] }
      this.searching = false
    },
    onProductPicked(row, p) {
      if (!p || !p.id) return
      row.product_code = p.product_code
      row.product_name = p.product_name
      row.product_spec = p.specification || ''
      row.product_unit = p.unit || ''
      if (!row.unit_price || row.unit_price <= 0) row.unit_price = Number(p.unit_price) || 0
      this.recalc()
    },
    openAdd() {
      this.addVisible = true
      this.pickedIds = []
      this.productOptions = []
      // 打开即加载全部产品与物料（无需先输入）
      this.searchProducts('')
    },
    handleSelectVisible(visible) {
      // 下拉展开且当前无选项时，自动加载全部产品与物料
      if (visible && !this.productOptions.length && !this.searching) this.searchProducts('')
    },
    confirmAdd() {
      if (!this.pickedIds.length) { this.$message.warning('请选择产品'); return }
      const picked = this.productOptions.filter(p => this.pickedIds.includes(p._key))
      picked.forEach(p => {
        if (this.items.some(x => x.product_code === p.product_code)) { this.$message.warning('[' + p.product_name + ']已存在，请勿重复添加'); return }
        this.items.push({
          product_id: p.id,
          product_code: p.product_code,
          product_name: p.product_name,
          product_spec: p.specification || '',
          product_unit: p.unit || '',
          quantity: 1,
          unit_price: Number(p.unit_price) || 0,
          need_date: '',
          remark: ''
        })
      })
      this.addVisible = false
      this.recalc()
    },
    removeRow(idx) {
      this.items.splice(idx, 1)
      this.recalc()
    },
    recalc() {
      // 触发合计重算（响应式已自动）
    }
  }
}
</script>

<style scoped>
.toolbar { display: flex; align-items: center; margin-bottom: 12px; }
.flex-1 { flex: 1; }
.total-tip { font-size: 14px; color: #303133; font-weight: 600; }
.danger { color: #f56c6c; }
</style>
