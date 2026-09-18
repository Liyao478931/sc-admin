<!--
  文件：admin/src/views/warehouse/check/plan/Add.vue
  功能：新增/编辑盘点计划（编辑由 Edit.vue 以 :id 复用本组件）
  权限：warehouse:check:plan:add / edit
-->
<template>
  <div class="wh-page">
    <el-breadcrumb separator="/" class="breadcrumb">
      <el-breadcrumb-item>仓储管理</el-breadcrumb-item>
      <el-breadcrumb-item>库存盘点</el-breadcrumb-item>
      <el-breadcrumb-item>盘点计划</el-breadcrumb-item>
      <el-breadcrumb-item>{{ isEdit ? '编辑计划' : '新增计划' }}</el-breadcrumb-item>
    </el-breadcrumb>

    <div class="page-header">
      <span class="page-title">{{ isEdit ? '编辑盘点计划 - ' + (form.plan_no || '') : '新增盘点计划' }}</span>
      <div class="header-right">
        <el-button type="primary" :loading="saving" @click="handleSave">保 存</el-button>
        <el-button @click="$router.push('/warehouse/check/plan')">取 消</el-button>
      </div>
    </div>

    <el-card class="form-card" shadow="never">
      <el-form ref="form" :model="form" :rules="rules" label-width="140px" size="small">
        <el-row :gutter="20">
          <el-col :span="12">
            <el-form-item label="计划名称" prop="plan_name">
              <el-input v-model="form.plan_name" placeholder="请输入盘点计划名称" />
            </el-form-item>
            <el-form-item label="盘点类型" prop="plan_type">
              <el-select v-model="form.plan_type" style="width:100%">
                <el-option v-for="(t, v) in typeOptions" :key="v" :label="t" :value="Number(v)" />
              </el-select>
            </el-form-item>
            <el-form-item label="盘点仓库" prop="warehouse_id">
              <el-select v-model="form.warehouse_id" style="width:100%" @change="onWarehouseChange">
                <el-option v-for="w in warehouses" :key="w.id" :label="w.warehouse_name" :value="w.id" />
              </el-select>
            </el-form-item>
            <el-form-item label="盘点方式" prop="inventory_method">
              <el-select v-model="form.inventory_method" style="width:100%">
                <el-option label="明盘（显示账面库存）" :value="1" />
                <el-option label="暗盘（不显示账面库存）" :value="2" />
              </el-select>
            </el-form-item>
            <el-form-item label="计划开始日期" prop="plan_start_date">
              <el-date-picker v-model="form.plan_start_date" type="date" value-format="yyyy-MM-dd" style="width:100%" :picker-options="{ disabledDate: d => d.getTime() < Date.now() - 86400000 }" />
            </el-form-item>
            <el-form-item label="计划结束日期" prop="plan_end_date">
              <el-date-picker v-model="form.plan_end_date" type="date" value-format="yyyy-MM-dd" style="width:100%" :picker-options="{ disabledDate: d => d.getTime() < new Date(this.form.plan_start_date || Date.now()).getTime() }" />
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="范围类型" prop="scope_type">
              <el-select v-model="form.scope_type" style="width:100%" @change="onScopeChange">
                <el-option v-for="(t, v) in scopeOptions" :key="v" :label="t" :value="Number(v)" />
              </el-select>
            </el-form-item>
            <el-form-item v-if="form.scope_type === 2" label="盘点货位" prop="scope_value">
              <el-select v-model="form.scope_value" multiple filterable placeholder="请选择货位" style="width:100%">
                <el-option v-for="l in locations" :key="l.id" :label="l.location_name" :value="l.id" />
              </el-select>
            </el-form-item>
            <el-form-item v-else-if="form.scope_type === 3" label="物料分类" prop="scope_value">
              <el-select v-model="form.scope_value" multiple filterable placeholder="请选择物料分类" style="width:100%">
                <el-option v-for="c in categories" :key="c.id" :label="c.category_name" :value="c.id" />
              </el-select>
            </el-form-item>
            <el-form-item v-else-if="form.scope_type === 4" label="盘点物料" prop="scope_value">
              <el-select v-model="form.scope_value" multiple filterable placeholder="请选择物料（支持搜索）" style="width:100%">
                <el-option v-for="m in materials" :key="m.id" :label="(m.material_name || m.material_code)" :value="m.id" />
              </el-select>
            </el-form-item>
            <el-form-item label="预计耗时（小时）">
              <el-input-number v-model="form.expected_duration" :min="0.5" :step="0.5" :precision="1" />
            </el-form-item>
            <el-form-item label="负责人" prop="responsible_person_id">
              <el-select v-model="form.responsible_person_id" filterable placeholder="请选择负责人" style="width:100%">
                <el-option v-for="u in users" :key="u.id" :label="u.real_name || u.username" :value="u.id" />
              </el-select>
            </el-form-item>
            <el-form-item label="参与人员">
              <el-select v-model="form.participants" multiple filterable placeholder="请选择参与人员" style="width:100%">
                <el-option v-for="u in users" :key="u.id" :label="u.real_name || u.username" :value="u.id" />
              </el-select>
            </el-form-item>
            <el-form-item label="备注">
              <el-input v-model="form.remark" type="textarea" :rows="3" placeholder="请输入备注信息" />
            </el-form-item>
          </el-col>
        </el-row>
      </el-form>
    </el-card>
  </div>
</template>

<script>
import { getWarehouseList, getLocationList, getMaterialList, getMaterialCategoryTree, savePlan, getPlanDetail } from '@/api/warehouse'
import { getUserList } from '@/api/user'

export default {
  name: 'InventoryPlanAdd',
  props: {
    editId: { type: [String, Number], default: 0 }
  },
  data () {
    return {
      typeOptions: { 1: '全盘', 2: '抽盘', 3: '循环盘点' },
      scopeOptions: { 1: '全仓', 2: '按货位', 3: '按物料分类', 4: '按物料' },
      warehouses: [], locations: [], categories: [], materials: [], users: [],
      saving: false,
      form: {
        id: 0, plan_no: '', plan_name: '', plan_type: 1, warehouse_id: null,
        scope_type: 1, scope_value: [], inventory_method: 1,
        plan_start_date: '', plan_end_date: '', expected_duration: 1,
        responsible_person_id: null, participants: [], remark: ''
      },
      rules: {
        plan_name: [{ required: true, message: '请填写计划名称', trigger: 'blur' }],
        plan_type: [{ required: true, message: '请选择盘点类型', trigger: 'change' }],
        warehouse_id: [{ required: true, message: '请选择盘点仓库', trigger: 'change' }],
        inventory_method: [{ required: true, message: '请选择盘点方式', trigger: 'change' }],
        scope_type: [{ required: true, message: '请选择范围类型', trigger: 'change' }],
        plan_start_date: [{ required: true, message: '请选择计划开始日期', trigger: 'change' }],
        plan_end_date: [{ required: true, message: '请选择计划结束日期', trigger: 'change' }],
        responsible_person_id: [{ required: true, message: '请选择负责人', trigger: 'change' }],
        scope_value: [{ required: true, message: '请选择盘点范围', trigger: 'change' }]
      }
    }
  },
  computed: {
    isEdit () { return Number(this.editId) > 0 }
  },
  created () {
    this.loadBase()
    if (this.isEdit) this.loadEdit()
  },
  methods: {
    async loadBase () {
      try {
        const [wr, lr, cr, mr, ur] = await Promise.all([
          getWarehouseList({ status: 1, page: 1, pageSize: 100 }),
          getLocationList({ page: 1, pageSize: 100 }),
          getMaterialCategoryTree(),
          getMaterialList({ page: 1, pageSize: 100 }),
          getUserList({ page: 1, pageSize: 100 })
        ])
        if (wr.code === 0) this.warehouses = (wr.data && wr.data.list) || []
        if (lr.code === 0) this.locations = Array.isArray(lr.data) ? lr.data : ((lr.data && lr.data.list) || [])
        if (cr.code === 0) this.categories = this.flattenTree((cr.data && (cr.data.list || cr.data)) || [])
        if (mr.code === 0) this.materials = (mr.data && mr.data.list) || []
        if (ur.code === 0) this.users = Array.isArray(ur.data) ? ur.data : ((ur.data && ur.data.list) || [])
      } catch (e) {}
    },
    flattenTree (tree) {
      const out = []
      const walk = list => (list || []).forEach(n => { out.push({ id: n.id, category_name: n.name || n.category_name }); if (n.children) walk(n.children) })
      walk(tree)
      return out
    },
    async loadEdit () {
      try {
        const r = await getPlanDetail(Number(this.editId))
        if (r.code === 0 && r.data && r.data.plan) {
          const p = r.data.plan
          this.form = {
            id: p.id, plan_no: p.plan_no, plan_name: p.plan_name, plan_type: p.plan_type,
            warehouse_id: p.warehouse_id, scope_type: p.scope_type, scope_value: p.scope_value || [],
            inventory_method: p.inventory_method, plan_start_date: p.plan_start_date,
            plan_end_date: p.plan_end_date, expected_duration: p.expected_duration,
            responsible_person_id: p.responsible_person_id, participants: p.participants || [],
            remark: p.remark || ''
          }
        }
      } catch (e) {}
    },
    onWarehouseChange () { this.locations = [] },
    onScopeChange () { this.form.scope_value = [] },
    handleSave () {
      this.$refs.form.validate(valid => {
        if (!valid) return
        if (this.form.scope_type > 1 && !this.form.scope_value.length) { this.$message.error('请选择盘点范围'); return }
        if (this.form.plan_end_date < this.form.plan_start_date) { this.$message.error('计划结束日期不能早于开始日期'); return }
        this.saving = true
        savePlan({
          ...this.form,
          scope_value: JSON.stringify(this.form.scope_value),
          participants: JSON.stringify(this.form.participants)
        }).then(r => {
          if (r.code === 0) { this.$message.success('保存成功'); this.$router.push('/warehouse/check/plan') } else this.$message.error(r.msg || '保存失败')
        }).catch(() => {}).finally(() => { this.saving = false })
      })
    }
  }
}
</script>

<style scoped>
.wh-page { padding: 16px; }
.breadcrumb { margin-bottom: 12px; }
.page-header { display: flex; justify-content: space-between; align-items: center; background: #fff; padding: 16px 20px; border-radius: 8px; margin-bottom: 14px; }
.page-title { font-size: 18px; font-weight: 600; color: #303133; }
.header-right { display: flex; gap: 10px; }
.form-card { border-radius: 8px; }
</style>
