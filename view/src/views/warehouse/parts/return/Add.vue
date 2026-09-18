<!--
  文件：admin/src/views/warehouse/parts/return/Add.vue
  功能：新增退库单 / 编辑退库单（按路由参数区分，编辑仅草稿/已驳回）
  权限：warehouse:return:add / edit
-->
<template>
  <div class="wh-page">
    <el-breadcrumb separator="/" class="breadcrumb">
      <el-breadcrumb-item>仓储管理</el-breadcrumb-item>
      <el-breadcrumb-item>配件出入库</el-breadcrumb-item>
      <el-breadcrumb-item>配件退库</el-breadcrumb-item>
      <el-breadcrumb-item>{{ isEdit ? '编辑退库单' : '新增退库单' }}</el-breadcrumb-item>
    </el-breadcrumb>

    <div class="page-header">
      <span class="page-title">{{ isEdit ? `编辑退库单 - ${form.return_no || ''}` : '新增退库单' }}</span>
      <div>
        <el-button size="small" @click="handleBack">取消</el-button>
        <el-button size="small" type="primary" :loading="saving" @click="handleSave">保存</el-button>
      </div>
    </div>

    <el-card shadow="never" class="form-card">
      <el-form ref="form" :model="form" :rules="rules" label-width="120px" size="small">
        <el-row :gutter="24">
          <el-col :span="12">
            <el-form-item label="退库类型" prop="return_type">
              <el-select v-model="form.return_type" placeholder="请选择退库类型" style="width:100%">
                <el-option v-for="(t, v) in RETURN_TYPES" :key="v" :label="t" :value="Number(v)" />
              </el-select>
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="关联领料单" prop="pick_id">
              <el-select v-model="form.pick_id" filterable placeholder="请选择可退库的领料单" style="width:100%" @change="handlePickChange">
                <el-option v-for="p in pickOptions" :key="p.id" :label="`${p.pick_no}（${p.department_name || ''}）`" :value="p.id" />
              </el-select>
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="退库部门">
              <el-input v-model="form.department_name" disabled placeholder="选择领料单后自动带出" />
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="退库人" prop="returner_id">
              <el-select v-model="form.returner_id" filterable placeholder="请选择退库人" style="width:100%">
                <el-option v-for="u in userOptions" :key="u.id" :label="u.real_name || u.username" :value="u.id" />
              </el-select>
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="退库日期" prop="return_date">
              <el-date-picker v-model="form.return_date" type="date" value-format="yyyy-MM-dd" placeholder="请选择退库日期" style="width:100%" />
            </el-form-item>
          </el-col>
          <el-col :span="24">
            <el-form-item label="退库原因" prop="return_reason">
              <el-input v-model="form.return_reason" type="textarea" :rows="3" placeholder="请选择或输入退库原因（生产计划变更/领料过多/物料质量问题/工单取消/其他）" />
            </el-form-item>
          </el-col>
        </el-row>
      </el-form>
    </el-card>

    <!-- 退库明细 -->
    <el-card shadow="never" class="logs-card">
      <div slot="header" class="logs-header">
        <span>退库明细（共 {{ items.length }} 种物料，退库总数量 {{ totalQuantity }}）</span>
        <div>
          <el-button v-if="form.pick_id" size="mini" icon="el-icon-download" @click="importFromPick">从领料单导入明细</el-button>
        </div>
      </div>
      <el-table :data="items" size="small" border empty-text="请选择领料单后导入或添加明细">
        <el-table-column type="index" label="#" width="50" align="center" />
        <el-table-column prop="material_code" label="物料编码" width="110" />
        <el-table-column prop="material_name" label="物料名称" min-width="140" show-overflow-tooltip />
        <el-table-column prop="spec" label="规格型号" width="120" show-overflow-tooltip />
        <el-table-column prop="unit" label="单位" width="60" align="center" />
        <el-table-column prop="pick_quantity" label="领料数量" width="90" align="center" />
        <el-table-column prop="returned_quantity" label="已退库数量" width="100" align="center" />
        <el-table-column prop="returnable_quantity" label="可退库数量" width="100" align="center">
          <template slot-scope="s"><span class="strong">{{ s.row.returnable_quantity }}</span></template>
        </el-table-column>
        <el-table-column label="退库数量" width="130">
          <template slot-scope="s">
            <el-input-number v-model="s.row.return_quantity" :min="0" :max="s.row.returnable_quantity" :precision="2" size="mini" style="width:100%" @change="v => validateQty(s.row, v)" />
          </template>
        </el-table-column>
        <el-table-column label="物料状态" width="110">
          <template slot-scope="s">
            <el-select v-model="s.row.material_status" size="mini" style="width:100%">
              <el-option v-for="(t, v) in MATERIAL_STATUS" :key="v" :label="t" :value="Number(v)" />
            </el-select>
          </template>
        </el-table-column>
        <el-table-column label="备注" min-width="120">
          <template slot-scope="s"><el-input v-model="s.row.remark" size="mini" placeholder="备注" /></template>
        </el-table-column>
        <el-table-column label="操作" width="70" align="center">
          <template slot-scope="s"><el-button type="text" size="mini" class="danger" @click="removeItem(s.$index)">删除</el-button></template>
        </el-table-column>
      </el-table>
    </el-card>

    <!-- 备注 -->
    <el-card shadow="never" class="logs-card">
      <el-form label-width="120px" size="small">
        <el-form-item label="备注">
          <el-input v-model="form.remark" type="textarea" :rows="3" placeholder="请输入补充说明" />
        </el-form-item>
      </el-form>
    </el-card>
  </div>
</template>

<script>
import { getReturnDetail, getReturnablePickList, saveReturn } from '../../../../api/warehouse'
import { getUserList } from '../../../../api/user'

const RETURN_TYPES = { 1: '生产退库', 2: '维修退库', 3: '质量退库', 4: '其他退库' }
const MATERIAL_STATUS = { 1: '完好', 2: '待检', 3: '报废' }

export default {
  name: 'WarehouseReturnAdd',
  data () {
    return {
      RETURN_TYPES, MATERIAL_STATUS,
      isEdit: false, saving: false, pickOptions: [], userOptions: [], pickMap: {},
      form: {
        id: 0, return_no: '', pick_id: 0, return_type: 1, department_id: 0, department_name: '',
        returner_id: 0, return_date: this.today(), return_reason: '', remark: ''
      },
      items: [],
      rules: {
        return_type: [{ required: true, message: '请选择退库类型', trigger: 'change' }],
        pick_id: [{ required: true, message: '请选择关联领料单', trigger: 'change' }],
        returner_id: [{ required: true, message: '请选择退库人', trigger: 'change' }],
        return_date: [{ required: true, message: '请选择退库日期', trigger: 'change' }],
        return_reason: [{ required: true, message: '请填写退库原因', trigger: 'blur' }]
      }
    }
  },
  computed: {
    totalQuantity () {
      return this.items.reduce((s, it) => s + (Number(it.return_quantity) || 0), 0)
    }
  },
  created () {
    this.isEdit = !!this.$route.params.id
    this.loadPicks()
    this.loadUsers()
    if (this.isEdit) this.loadDetail(Number(this.$route.params.id))
  },
  methods: {
    today () {
      const d = new Date()
      return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`
    },
    async loadPicks () {
      try {
        const r = await getReturnablePickList()
        this.pickOptions = (r.code === 0 && r.data && r.data.list) ? r.data.list : []
        this.pickMap = {}
        this.pickOptions.forEach(p => { this.pickMap[p.id] = p })
      } catch (e) { this.pickOptions = [] }
    },
    async loadUsers () {
      try {
        const r = await getUserList({ page: 1, limit: 200 })
        this.userOptions = (r.data && r.data.list) || []
        if (!this.isEdit && this.userOptions.length) {
          const cur = this.userOptions.find(u => u.is_current === 1 || u.id === (this.$store.state.user.userInfo && this.$store.state.user.userInfo.id))
          this.form.returner_id = cur ? cur.id : this.userOptions[0].id
        }
      } catch (e) { this.userOptions = [] }
    },
    async loadDetail (id) {
      try {
        const r = await getReturnDetail(id)
        if (r.code === 0 && r.data) {
          const d = r.data
          this.form = {
            id: d.id, return_no: d.return_no, pick_id: d.pick_id, return_type: d.return_type,
            department_id: d.department_id, department_name: d.department_name,
            returner_id: d.returner_id, return_date: d.return_date, return_reason: d.return_reason || '', remark: d.remark || ''
          }
          this.items = (d.items || []).map(it => ({
            pick_item_id: it.pick_item_id, material_id: it.material_id, material_code: it.material_code,
            material_name: it.material_name, spec: it.spec, unit: it.unit,
            pick_quantity: Number(it.pick_quantity) || 0, returned_quantity: Number(it.returned_quantity) || 0,
            returnable_quantity: Number(it.returnable_quantity) || 0,
            return_quantity: Number(it.return_quantity) || 0, material_status: it.material_status || 1, remark: it.remark || ''
          }))
        } else this.$message.error(r.msg || '加载失败')
      } catch (e) {}
    },
    handlePickChange (pid) {
      const pick = this.pickMap[pid]
      if (!pick) return
      this.form.department_id = pick.department_id || 0
      this.form.department_name = pick.department_name || ''
      this.importItems(pick)
    },
    importFromPick () {
      const pick = this.pickMap[this.form.pick_id]
      if (!pick) return
      if (this.items.length) {
        this.$confirm('导入将覆盖当前明细列表，是否继续？', '提示', { type: 'warning' }).then(() => this.importItems(pick)).catch(() => {})
      } else this.importItems(pick)
    },
    importItems (pick) {
      this.items = (pick.items || []).filter(it => it.returnable_quantity > 0).map(it => ({
        pick_item_id: it.pick_item_id, material_id: it.material_id, material_code: it.material_code,
        material_name: it.material_name, spec: it.spec, unit: it.unit,
        pick_quantity: Number(it.pick_quantity) || 0, returned_quantity: Number(it.returned_quantity) || 0,
        returnable_quantity: Number(it.returnable_quantity) || 0,
        return_quantity: Number(it.returnable_quantity) || 0, material_status: 1, remark: ''
      }))
    },
    validateQty (row, v) {
      if (v > row.returnable_quantity) {
        row.return_quantity = row.returnable_quantity
        this.$message.warning(`退库数量不能大于可退库数量 ${row.returnable_quantity}`)
      }
    },
    removeItem (idx) { this.items.splice(idx, 1) },
    handleBack () {
      if (this.form.return_reason || this.items.length) {
        this.$confirm('当前有未保存的内容，确认离开吗？', '提示', { type: 'warning' }).then(() => {
          this.$router.push({ path: '/warehouse/parts/return/list' })
        }).catch(() => {})
        return
      }
      this.$router.push({ path: '/warehouse/parts/return/list' })
    },
    handleSave () {
      this.$refs.form.validate(async valid => {
        if (!valid) { this.$message.warning('请完善必填项'); return }
        if (!this.items.length) { this.$message.warning('请至少添加一条退库明细'); return }
        const invalid = this.items.find(it => !it.return_quantity || it.return_quantity <= 0)
        if (invalid) { this.$message.warning(`物料 [${invalid.material_name}] 退库数量必须大于 0`); return }
        this.saving = true
        try {
          const r = await saveReturn({ ...this.form, items: this.items })
          if (r.code === 0) {
            this.$message.success(r.msg || '保存成功')
            this.$router.push({ path: '/warehouse/parts/return/list' })
          } else this.$message.error(r.msg || '保存失败')
        } catch (e) {} finally { this.saving = false }
      })
    }
  }
}
</script>

<style scoped>
.wh-page { padding: 16px; }
.breadcrumb { margin-bottom: 12px; }
.page-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 16px; }
.page-title { font-size: 18px; font-weight: bold; }
.form-card { margin-bottom: 16px; }
.logs-card { margin-bottom: 16px; }
.logs-header { display: flex; justify-content: space-between; align-items: center; }
.strong { font-weight: bold; color: #E6A23C; }
.danger { color: #F56C6C; }
</style>
