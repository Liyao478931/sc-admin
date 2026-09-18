<!--
  文件：admin/src/views/business/product/bom/components/BomEditableTable.vue
  功能：BOM 子项可编辑表格（新增/编辑页）
    - 行内编辑（产品远程搜索/用量/损耗率/来源/关键件/备注）
    - 新增子项（弹窗，默认顶级或选中行下级）
    - 从BOM复制（覆盖/追加，追加检测重复子件）
    - 导入Excel（后端解析填充）
    - 删除/上移/下移/升级/降级（升级降级含循环引用校验）
  props：items（数组，直接修改）、disabled（已审批只读）
  方法：getSubmitItems() 返回提交数据（parent 转索引）
-->
<template>
  <div class="bom-editable">
    <div class="toolbar">
      <el-button v-if="!disabled" type="primary" size="small" icon="el-icon-plus" @click="openAdd">新增子项</el-button>
      <el-button v-if="!disabled" size="small" icon="el-icon-copy-document" @click="openCopyFrom">从BOM复制</el-button>
      <el-button v-if="!disabled" size="small" icon="el-icon-upload2" @click="openImport">导入Excel</el-button>
      <span class="flex-1"></span>
      <span class="total-tip">共 {{ items.length }} 项</span>
    </div>

    <el-table :data="items" size="small" border highlight-current-row @current-change="r => (currentRow = r)">
      <el-table-column type="index" label="序号" width="55" align="center" />
      <el-table-column label="层级" width="80" align="center">
        <template slot-scope="s">
          <span :style="{ paddingLeft: (levelOf(s.row) * 14) + 'px' }">{{ levelOf(s.row) }}</span>
        </template>
      </el-table-column>
      <el-table-column label="子件产品" min-width="220">
        <template slot-scope="s">
          <ProductSelector v-model="s.row.component_product_id" :disabled="disabled" :label-text="s.row.component_code + ' ' + s.row.component_name" @selected="p => onProductPicked(s.row, p)" />
        </template>
      </el-table-column>
      <el-table-column prop="component_code" label="子件编码" width="130" show-overflow-tooltip />
      <el-table-column prop="component_name" label="子件名称" min-width="140" show-overflow-tooltip />
      <el-table-column prop="component_spec" label="规格" width="120" show-overflow-tooltip />
      <el-table-column prop="component_unit" label="单位" width="70" align="center" />
      <el-table-column label="用量" width="120">
        <template slot-scope="s">
          <el-input-number v-model="s.row.quantity" :disabled="disabled" :min="0.0001" :max="999999" :precision="4" size="mini" style="width:100%" />
        </template>
      </el-table-column>
      <el-table-column label="损耗率%" width="110">
        <template slot-scope="s">
          <el-input-number v-model="s.row.wastage_rate" :disabled="disabled" :min="0" :max="100" :precision="2" size="mini" style="width:100%" />
        </template>
      </el-table-column>
      <el-table-column label="来源类型" width="110">
        <template slot-scope="s">
          <el-select v-model="s.row.source_type" :disabled="disabled" size="mini" style="width:100%">
            <el-option label="自制件" :value="1" />
            <el-option label="外购件" :value="2" />
            <el-option label="外协件" :value="3" />
          </el-select>
        </template>
      </el-table-column>
      <el-table-column label="关键件" width="70" align="center">
        <template slot-scope="s">
          <el-switch v-model="s.row.is_key" :active-value="1" :inactive-value="0" :disabled="disabled" size="mini" />
        </template>
      </el-table-column>
      <el-table-column label="备注" width="140">
        <template slot-scope="s">
          <el-input v-model="s.row.remark" :disabled="disabled" size="mini" placeholder="备注" />
        </template>
      </el-table-column>
      <el-table-column label="操作" width="230" align="center" fixed="right">
        <template slot-scope="s">
          <template v-if="!disabled">
            <el-button type="text" size="mini" class="danger" @click="removeRow(s.$index)">删除</el-button>
            <el-button type="text" size="mini" :disabled="s.$index === 0 || !sameParentPrev(s.$index)" @click="moveUp(s.$index)">上移</el-button>
            <el-button type="text" size="mini" :disabled="s.$index === items.length - 1 || !sameParentNext(s.$index)" @click="moveDown(s.$index)">下移</el-button>
            <el-button type="text" size="mini" :disabled="levelOf(s.row) === 0" @click="promote(s.$index)">升级</el-button>
            <el-button type="text" size="mini" :disabled="!currentRow" @click="demote(s.$index)">降级</el-button>
          </template>
          <span v-else>-</span>
        </template>
      </el-table-column>
    </el-table>

    <!-- 新增子项弹窗 -->
    <el-dialog title="新增子项" :visible="addVisible" width="560px" :close-on-click-modal="false" @close="addVisible = false">
      <el-form label-width="90px" size="small">
        <el-form-item label="子件产品" required>
          <ProductSelector v-model="addForm.component_product_id" @selected="p => (addSelected = p)" />
        </el-form-item>
        <el-row :gutter="12">
          <el-col :span="12">
            <el-form-item label="用量" required>
              <el-input-number v-model="addForm.quantity" :min="0.0001" :precision="4" style="width:100%" />
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="损耗率%">
              <el-input-number v-model="addForm.wastage_rate" :min="0" :max="100" :precision="2" style="width:100%" />
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="来源类型">
              <el-select v-model="addForm.source_type" style="width:100%">
                <el-option label="自制件" :value="1" />
                <el-option label="外购件" :value="2" />
                <el-option label="外协件" :value="3" />
              </el-select>
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="关键件">
              <el-switch v-model="addForm.is_key" :active-value="1" :inactive-value="0" />
            </el-form-item>
          </el-col>
        </el-row>
        <el-form-item label="备注">
          <el-input v-model="addForm.remark" type="textarea" :rows="2" placeholder="备注（可选）" />
        </el-form-item>
      </el-form>
      <div slot="footer">
        <el-button size="small" @click="addVisible = false">取消</el-button>
        <el-button size="small" type="primary" @click="confirmAdd">添加</el-button>
      </div>
    </el-dialog>

    <!-- 从BOM复制弹窗 -->
    <el-dialog title="从BOM复制" :visible="copyVisible" width="560px" :close-on-click-modal="false" @close="copyVisible = false">
      <el-select v-model="copyBomId" filterable placeholder="选择已审批的BOM" style="width:100%">
        <el-option v-for="b in approvedBoms" :key="b.id" :label="b.bom_code + ' ' + b.bom_name + ' (' + b.product_name + ')'" :value="b.id" />
      </el-select>
      <div class="strategy-box">
        <el-radio-group v-model="copyStrategy">
          <el-radio label="overwrite">覆盖当前子项列表</el-radio>
          <el-radio label="append">追加到当前子项列表尾部</el-radio>
        </el-radio-group>
      </div>
      <div slot="footer">
        <el-button size="small" @click="copyVisible = false">取消</el-button>
        <el-button size="small" type="primary" :loading="copying" @click="confirmCopy">导入</el-button>
      </div>
    </el-dialog>

    <!-- 导入Excel弹窗 -->
    <el-dialog title="导入Excel" :visible="importVisible" width="460px" :close-on-click-modal="false" @close="importVisible = false">
      <el-upload
        :auto-upload="false"
        :limit="1"
        accept=".xlsx,.xls"
        :on-change="onFileChange"
        :file-list="fileList"
      >
        <el-button size="small" icon="el-icon-upload2">选择文件</el-button>
      </el-upload>
      <div class="form-tip">Excel列格式：A子件编码 / B子件名称 / C用量 / D损耗率 / E备注（首行为表头）</div>
      <div slot="footer">
        <el-button size="small" @click="importVisible = false">取消</el-button>
        <el-button size="small" type="primary" :loading="importing" :disabled="!selectedFile" @click="confirmImport">解析导入</el-button>
      </div>
    </el-dialog>
  </div>
</template>

<script>
import ProductSelector from './ProductSelector.vue'
import { getApprovedBomList, getBomItems, importBomItems } from '../../../../../api/product'

let seq = 0

export default {
  name: 'BomEditableTable',
  components: { ProductSelector },
  props: {
    items: { type: Array, required: true },
    disabled: { type: Boolean, default: false }
  },
  data() {
    return {
      currentRow: null,
      addSelected: null,
      addVisible: false,
      addForm: { component_product_id: null, quantity: 1, wastage_rate: 0, source_type: 1, is_key: 0, remark: '' },
      copyVisible: false,
      copyBomId: null,
      copyStrategy: 'overwrite',
      approvedBoms: [],
      copying: false,
      importVisible: false,
      fileList: [],
      selectedFile: null,
      importing: false
    }
  },
  methods: {
    // ===== 行结构 =====
    nextKey() { return ++seq },
    /** 父行_key → 父行对象 */
    parentOf(row) {
      if (!row.parent_item_id) return null
      return this.items.find(x => x._key === row.parent_item_id) || null
    },
    /** 行的层级深度（从0起），环时限制深度 */
    levelOf(row) {
      let level = 0
      let cur = row
      let guard = 0
      while (cur && cur.parent_item_id && guard < 50) {
        const p = this.items.find(x => x._key === cur.parent_item_id)
        if (!p) break
        cur = p
        level++
        guard++
      }
      return level
    },
    sameParentPrev(idx) {
      if (idx === 0) return false
      return this.items[idx - 1].parent_item_id === this.items[idx].parent_item_id
    },
    sameParentNext(idx) {
      if (idx === this.items.length - 1) return false
      return this.items[idx + 1].parent_item_id === this.items[idx].parent_item_id
    },
    // ===== 产品选中带出（选中对象由 ProductSelector 提供） =====
    onProductPicked(row, p) {
      if (!p || !p.id) { row.component_code = ''; row.component_name = ''; row.component_spec = ''; row.component_unit = ''; return }
      row.component_code = p.product_code
      row.component_name = p.product_name
      row.component_spec = p.specification || ''
      row.component_unit = p.unit || ''
    },
    // ===== 新增子项 =====
    openAdd() {
      this.addForm = { component_product_id: null, quantity: 1, wastage_rate: 0, source_type: 1, is_key: 0, remark: '' }
      this.addSelected = null
      this.addVisible = true
    },
    confirmAdd() {
      if (!this.addForm.component_product_id) { this.$message.warning('请选择子件产品'); return }
      if (!(this.addForm.quantity > 0)) { this.$message.warning('用量必须大于0'); return }
      // 父级：选中行 → 其下级；否则顶级
      const parentKey = this.currentRow ? this.currentRow._key : 0
      // 层级深度限制（≤10级）
      if (this.currentRow && this.levelOf(this.currentRow) + 1 > 10) {
        this.$message.warning('BOM层级超过最大限制（10级），请简化BOM结构')
        return
      }
      // 重复子件校验
      if (this.items.some(x => x.component_product_id === this.addForm.component_product_id)) {
        this.$message.warning('该子件产品已存在，不能重复添加')
        return
      }
      const row = {
        _key: this.nextKey(),
        parent_item_id: parentKey,
        component_product_id: this.addForm.component_product_id,
        component_code: '', component_name: '', component_spec: '', component_unit: '',
        quantity: this.addForm.quantity,
        wastage_rate: this.addForm.wastage_rate,
        source_type: this.addForm.source_type,
        is_key: this.addForm.is_key,
        remark: this.addForm.remark,
        sort: this.items.length + 1
      }
      this.onProductPicked(row, this.addSelected)
      this.items.push(row)
      this.addVisible = false
    },
    // ===== 删除/移动 =====
    removeRow(idx) {
      this.$confirm('确认删除该子项吗？其子级子项将保留为顶级。', '删除确认', { type: 'warning' }).then(() => {
        const removed = this.items[idx]
        this.items.splice(idx, 1)
        // 其子级提升为顶级
        this.items.forEach(x => { if (x.parent_item_id === removed._key) x.parent_item_id = 0 })
      }).catch(() => {})
    },
    moveUp(idx) {
      const tmp = this.items[idx - 1]
      this.items[idx - 1] = this.items[idx]
      this.items[idx] = tmp
    },
    moveDown(idx) {
      const tmp = this.items[idx + 1]
      this.items[idx + 1] = this.items[idx]
      this.items[idx] = tmp
    },
    // ===== 升级/降级（循环引用校验 + 层级深度限制） =====
    promote(idx) {
      const row = this.items[idx]
      const parent = this.parentOf(row)
      if (!parent) { this.$message.warning('已是顶级，不可升级'); return }
      row.parent_item_id = parent.parent_item_id || 0
    },
    demote(idx) {
      const row = this.items[idx]
      if (!this.currentRow) { this.$message.warning('请先选中目标父级行'); return }
      if (this.currentRow._key === row._key) { this.$message.warning('不能降级为自身的子项'); return }
      // 不能成为自身子孙的父级（循环引用）
      if (this.isDescendant(row._key, this.currentRow._key)) { this.$message.warning('操作将形成循环引用，已阻止'); return }
      if (this.levelOf(this.currentRow) + 1 > 10) { this.$message.warning('BOM层级超过最大限制（10级）'); return }
      row.parent_item_id = this.currentRow._key
    },
    /** 判断 targetKey 是否为 nodeKey 的后代 */
    isDescendant(nodeKey, targetKey) {
      let cur = targetKey
      let guard = 0
      while (cur && guard < 100) {
        if (cur === nodeKey) return true
        const row = this.items.find(x => x._key === cur)
        if (!row) break
        cur = row.parent_item_id || 0
        guard++
      }
      return false
    },
    // ===== 从BOM复制 =====
    async openCopyFrom() {
      this.copyVisible = true
      this.copyBomId = null
      this.copyStrategy = 'overwrite'
      try {
        const r = await getApprovedBomList()
        this.approvedBoms = (r.code === 0 && r.data) ? r.data : []
        if (!this.approvedBoms.length) this.$message.warning('暂无已审批的BOM可复制')
      } catch (e) { this.approvedBoms = [] }
    },
    async confirmCopy() {
      if (!this.copyBomId) { this.$message.warning('请选择要复制的BOM'); return }
      this.copying = true
      try {
        const r = await getBomItems(this.copyBomId)
        const src = (r.code === 0 && r.data && r.data.list) ? r.data.list : []
        if (!src.length) { this.$message.warning('源BOM无子项'); return }
        if (this.copyStrategy === 'overwrite') {
          this.replaceWith(src)
        } else {
          // 追加 + 重复检测
          const exists = src.filter(s => this.items.some(x => x.component_product_id === s.component_product_id)).map(s => s.component_name)
          if (exists.length) { this.$message.warning('以下子件产品已存在：' + exists.join('、') + '，请先删除重复项再导入'); return }
          this.appendWith(src)
        }
        this.copyVisible = false
        this.$message.success('导入成功')
      } catch (e) {}
      this.copying = false
    },
    replaceWith(src) {
      this.items.splice(0, this.items.length)
      this.appendWith(src)
    },
    appendWith(src) {
      src.forEach(s => {
        this.items.push({
          _key: this.nextKey(),
          parent_item_id: 0,
          component_product_id: s.component_product_id,
          component_code: s.component_code,
          component_name: s.component_name,
          component_spec: s.component_spec || '',
          component_unit: s.component_unit || '',
          quantity: s.quantity,
          wastage_rate: s.wastage_rate,
          source_type: s.source_type,
          is_key: s.is_key,
          remark: s.remark,
          sort: this.items.length + 1
        })
      })
    },
    // ===== 导入Excel =====
    onFileChange(file) {
      this.selectedFile = file.raw || file
    },
    async confirmImport() {
      if (!this.selectedFile) return
      this.importing = true
      try {
        const fd = new FormData()
        fd.append('file', this.selectedFile)
        const r = await importBomItems(fd)
        if (r.code === 0 && r.data && r.data.list) {
          this.appendWith(r.data.list)
          if (r.data.fail && r.data.fail.length) this.$message.warning('部分行解析失败：' + r.data.fail.length + ' 条，详见导入结果')
          this.$message.success(r.msg || '导入完成')
          this.importVisible = false
          this.fileList = []
          this.selectedFile = null
        }
      } catch (e) {}
      this.importing = false
    },
    /** 供父组件提交：parent_item_id 由 _key 转数组索引 */
    getSubmitItems() {
      const keyToIdx = {}
      this.items.forEach((x, i) => { keyToIdx[x._key] = i })
      return this.items.map((x, i) => ({
        parent_item_id: x.parent_item_id ? (keyToIdx[x.parent_item_id] !== undefined ? keyToIdx[x.parent_item_id] : 0) : 0,
        component_product_id: x.component_product_id,
        quantity: x.quantity,
        wastage_rate: x.wastage_rate,
        sort: i + 1,
        source_type: x.source_type,
        is_key: x.is_key,
        remark: x.remark || ''
      }))
    }
  }
}
</script>

<style scoped>
.toolbar { display: flex; align-items: center; margin-bottom: 12px; }
.flex-1 { flex: 1; }
.total-tip { font-size: 13px; color: #909399; }
.strategy-box { margin-top: 12px; }
.form-tip { font-size: 12px; color: #909399; margin-top: 8px; line-height: 1.6; }
.danger { color: #f56c6c; }
</style>
