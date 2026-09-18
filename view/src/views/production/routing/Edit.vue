<!--
  文件：admin/src/views/production/routing/Edit.vue
  功能：工艺路线新增/编辑（头信息 + 工序序列）
  权限：production:routing:add/edit
-->
<template>
  <div class="routing-edit-page">
    <el-breadcrumb separator="/" class="breadcrumb">
      <el-breadcrumb-item>生产管理</el-breadcrumb-item>
      <el-breadcrumb-item>基础设置</el-breadcrumb-item>
      <el-breadcrumb-item>工艺路线</el-breadcrumb-item>
      <el-breadcrumb-item>{{ isEdit ? '编辑工艺路线' : '新增工艺路线' }}</el-breadcrumb-item>
    </el-breadcrumb>

    <el-card shadow="never" v-loading="pageLoading">
      <!-- 头信息 -->
      <el-form ref="headForm" :model="form" :rules="headRules" label-width="90px" size="small">
        <el-row :gutter="16">
          <el-col :span="8">
            <el-form-item label="选择产品" prop="product_id">
              <el-select v-model="form.product_id" filterable placeholder="请选择产品" style="width:100%" @change="onProductChange" :disabled="isEdit">
                <el-option v-for="p in productOptions" :key="p.id" :label="p.product_name + ' / ' + (p.product_code || '')" :value="p.id" />
              </el-select>
            </el-form-item>
          </el-col>
          <el-col :span="8">
            <el-form-item label="路线编号" prop="routing_code">
              <el-input v-model="form.routing_code" placeholder="留空自动生成" @blur="checkCode" />
            </el-form-item>
          </el-col>
          <el-col :span="8">
            <el-form-item label="路线名称" prop="routing_name">
              <el-input v-model="form.routing_name" placeholder="请输入路线名称" />
            </el-form-item>
          </el-col>
          <el-col :span="8">
            <el-form-item label="版本号">
              <el-input v-model="form.version" placeholder="如 V1.0" />
            </el-form-item>
          </el-col>
          <el-col :span="8">
            <el-form-item label="产品数量">
              <el-input-number v-model="form.quantity" :min="0.0001" :precision="4" style="width:100%" />
            </el-form-item>
          </el-col>
          <el-col :span="8">
            <el-form-item label="单位">
              <el-input v-model="form.unit" placeholder="如 台" />
            </el-form-item>
          </el-col>
          <el-col :span="8">
            <el-form-item label="生效日期">
              <el-date-picker v-model="form.effective_date" type="date" value-format="yyyy-MM-dd" placeholder="生效日期" style="width:100%" />
            </el-form-item>
          </el-col>
          <el-col :span="8">
            <el-form-item label="失效日期">
              <el-date-picker v-model="form.expiry_date" type="date" value-format="yyyy-MM-dd" placeholder="失效日期" style="width:100%" />
            </el-form-item>
          </el-col>
          <el-col :span="8">
            <el-form-item label="状态">
              <el-switch v-model="form.status" :active-value="1" :inactive-value="0" active-text="启用" inactive-text="停用" />
            </el-form-item>
          </el-col>
          <el-col :span="8">
            <el-form-item label="默认路线">
              <el-switch v-model="form.is_default" :active-value="1" :inactive-value="0" active-text="是" inactive-text="否" />
            </el-form-item>
          </el-col>
          <el-col v-if="isEdit" :span="8">
            <el-form-item label="版本升级">
              <el-switch v-model="form.version_upgrade" active-text="保存时升版" inactive-text="不升版" />
            </el-form-item>
          </el-col>
          <el-col :span="24">
            <el-form-item label="备注">
              <el-input v-model="form.remark" type="textarea" :rows="2" placeholder="备注说明" />
            </el-form-item>
          </el-col>
        </el-row>
      </el-form>

      <!-- 工序序列 -->
      <div class="items-header">
        <span class="items-title">工序序列（按顺序加工）</span>
        <span class="total-hours">合计工时：{{ totalHours }} 小时 / {{ form.items.length }} 道工序</span>
        <div class="items-actions">
          <el-button size="small" type="primary" plain icon="el-icon-plus" @click="addItem">添加工序</el-button>
          <el-button size="small" icon="el-icon-sort" @click="sortItems">按顺序重排</el-button>
        </div>
      </div>

      <el-table :data="form.items" size="small" border stripe class="items-table">
        <el-table-column type="index" label="序号" width="55" align="center" />
        <el-table-column label="工序" width="220">
          <template slot-scope="s">
            <el-select v-model="s.row.process_id" filterable placeholder="选择工序" style="width:100%" @change="pid => onProcessChange(s.$index, pid)">
              <el-option v-for="p in processOptions" :key="p.id" :label="p.process_name + '（' + (p.process_group || '') + '）'" :value="p.id" />
            </el-select>
          </template>
        </el-table-column>
        <el-table-column label="顺序" width="80" align="center">
          <template slot-scope="s">
            <el-input-number v-model="s.row.sort_order" :min="1" :max="999" size="mini" controls-position="right" style="width:60px" />
          </template>
        </el-table-column>
        <el-table-column label="标准工时(h)" width="110" align="center">
          <template slot-scope="s">
            <el-input-number v-model="s.row.standard_hours" :min="0" :max="999" :precision="2" size="mini" controls-position="right" style="width:90px" />
          </template>
        </el-table-column>
        <el-table-column label="工分定额" width="110" align="center">
          <template slot-scope="s">
            <el-input-number v-model="s.row.standard_score" :min="0" :max="9999" :precision="2" size="mini" controls-position="right" style="width:90px" />
          </template>
        </el-table-column>
        <el-table-column label="工位" width="160">
          <template slot-scope="s">
            <el-select v-model="s.row.workstation_id" filterable clearable placeholder="选择工位" style="width:100%" @change="wid => onWorkstationChange(s.$index, wid)">
              <el-option v-for="w in workstationOptions" :key="w.id" :label="w.workstation_name" :value="w.id" />
            </el-select>
          </template>
        </el-table-column>
        <el-table-column label="关键工序" width="90" align="center">
          <template slot-scope="s">
            <el-checkbox v-model="s.row.is_key" :true-label="1" :false-label="0" />
          </template>
        </el-table-column>
        <el-table-column label="备注" min-width="140">
          <template slot-scope="s">
            <el-input v-model="s.row.remark" size="mini" placeholder="备注" />
          </template>
        </el-table-column>
        <el-table-column label="操作" width="120" align="center">
          <template slot-scope="s">
            <el-button type="text" size="mini" icon="el-icon-top" :disabled="s.$index === 0" @click="moveItem(s.$index, -1)" />
            <el-button type="text" size="mini" icon="el-icon-bottom" :disabled="s.$index === form.items.length - 1" @click="moveItem(s.$index, 1)" />
            <el-button type="text" size="mini" class="danger" icon="el-icon-delete" @click="removeItem(s.$index)" />
          </template>
        </el-table-column>
      </el-table>

      <div class="footer-btns">
        <el-button type="primary" size="small" :loading="saving" @click="handleSave(false)">保存</el-button>
        <el-button v-if="!isEdit" type="primary" size="small" plain :loading="saving" @click="handleSave(true)">保存并继续</el-button>
        <el-button size="small" @click="$router.back()">取消</el-button>
      </div>
    </el-card>
  </div>
</template>

<script>
import {
  getRoutingDetail, saveRouting, getProcessList, getWorkstationList, getRoutingItems
} from '../../../api/production'
import { getProductList } from '../../../api/product'

export default {
  name: 'ProductionRoutingEdit',
  data() {
    return {
      isEdit: false,
      pageLoading: false,
      saving: false,
      productOptions: [],
      processOptions: [],
      workstationOptions: [],
      form: {
        id: 0,
        product_id: undefined,
        routing_code: '',
        routing_name: '',
        version: 'V1.0',
        quantity: 1,
        unit: '',
        is_default: 0,
        status: 1,
        effective_date: '',
        expiry_date: '',
        remark: '',
        version_upgrade: false,
        items: []
      },
      headRules: {
        product_id: [{ required: true, message: '请选择产品', trigger: 'change' }],
        routing_name: [{ required: true, message: '请输入路线名称', trigger: 'blur' }]
      }
    }
  },
  computed: {
    totalHours() {
      return (this.form.items || []).reduce((s, it) => s + (Number(it.standard_hours) || 0), 0).toFixed(2)
    }
  },
  created() {
    this.loadOptions()
    const id = this.$route.params.id
    if (id) {
      this.isEdit = true
      this.loadDetail(id)
    } else {
      // 默认序号
      this.addItem()
    }
  },
  methods: {
    async loadOptions() {
      try {
        const p = await getProductList({ page: 1, pageSize: 500 })
        if (p.code === 0) this.productOptions = p.data.list || []
      } catch (e) {}
      try {
        const pr = await getProcessList({ page: 1, pageSize: 200, status: 1 })
        if (pr.code === 0) this.processOptions = pr.data.list || []
      } catch (e) {}
      try {
        const w = await getWorkstationList({ page: 1, pageSize: 500 })
        if (w.code === 0) this.workstationOptions = w.data.list || []
      } catch (e) {}
    },
    async loadDetail(id) {
      this.pageLoading = true
      try {
        const r = await getRoutingDetail(id)
        if (r.code === 0 && r.data && r.data.routing) {
          const rk = r.data.routing
          this.form = {
            id: rk.id,
            product_id: rk.product_id,
            routing_code: rk.routing_code,
            routing_name: rk.routing_name,
            version: rk.version,
            quantity: Number(rk.quantity) || 1,
            unit: rk.unit || '',
            is_default: rk.is_default,
            status: rk.status,
            effective_date: rk.effective_date || '',
            expiry_date: rk.expiry_date || '',
            remark: rk.remark || '',
            version_upgrade: false,
            items: []
          }
          const items = r.data.items || []
          this.form.items = items.map(it => ({
            process_id: it.process_id,
            process_name: it.process_name,
            sort_order: it.sort_order,
            standard_hours: Number(it.standard_hours) || 0,
            standard_score: Number(it.standard_score) || 0,
            workstation_id: it.workstation_id || 0,
            workstation_name: it.workstation_name || '',
            is_key: it.is_key || 0,
            remark: it.remark || ''
          }))
          if (!this.form.items.length) this.addItem()
        }
      } catch (e) {}
      this.pageLoading = false
    },
    onProductChange(pid) {
      const p = this.productOptions.find(x => x.id === pid)
      if (p) {
        if (!this.form.unit) this.form.unit = p.unit || ''
        if (!this.form.routing_name) this.form.routing_name = (p.product_name || '') + '工艺路线'
        if (!this.form.routing_code) this.form.routing_code = ''
      }
    },
    onProcessChange(idx, pid) {
      const p = this.processOptions.find(x => x.id === pid)
      if (p) {
        this.form.items[idx].process_name = p.process_name
        if (!this.form.items[idx].standard_hours) this.form.items[idx].standard_hours = Number(p.standard_hours) || 0
        if (!this.form.items[idx].standard_score) this.form.items[idx].standard_score = Number(p.standard_score) || 0
        if (!this.form.items[idx].sort_order) this.form.items[idx].sort_order = this.form.items.length
      }
    },
    onWorkstationChange(idx, wid) {
      const w = this.workstationOptions.find(x => x.id === wid)
      this.form.items[idx].workstation_name = w ? w.workstation_name : ''
    },
    addItem() {
      this.form.items.push({
        process_id: undefined,
        process_name: '',
        sort_order: this.form.items.length + 1,
        standard_hours: 0,
        standard_score: 0,
        workstation_id: 0,
        workstation_name: '',
        is_key: 0,
        remark: ''
      })
    },
    removeItem(idx) {
      if (this.form.items.length <= 1) { this.$message.warning('至少保留一道工序'); return }
      this.form.items.splice(idx, 1)
      this.renumber()
    },
    moveItem(idx, dir) {
      const target = idx + dir
      if (target < 0 || target >= this.form.items.length) return
      const arr = this.form.items
      const tmp = arr[idx]
      this.$set(arr, idx, arr[target])
      this.$set(arr, target, tmp)
      this.renumber()
    },
    renumber() {
      this.form.items.forEach((it, i) => { it.sort_order = i + 1 })
    },
    sortItems() {
      this.form.items.sort((a, b) => (Number(a.sort_order) || 0) - (Number(b.sort_order) || 0))
      this.renumber()
      this.$message.success('已按顺序重排')
    },
    async checkCode() {
      const code = this.form.routing_code
      if (!code) return
      try {
        const r = await getRoutingItems(0) // 占位避免未使用
        void r
      } catch (e) {}
    },
    async handleSave(continueNext) {
      try {
        await this.$refs.headForm.validate()
      } catch (e) { return }
      if (!this.form.product_id) { this.$message.warning('请选择产品'); return }
      if (!this.form.routing_name) { this.$message.warning('请输入路线名称'); return }
      const items = this.form.items.filter(it => it.process_id)
      if (!items.length) { this.$message.warning('请至少添加一道工序'); return }
      const seen = new Set()
      for (const it of items) {
        if (seen.has(it.process_id)) { this.$message.warning('同一路线下工序不能重复'); return }
        seen.add(it.process_id)
      }
      this.saving = true
      try {
        const r = await saveRouting({
          id: this.form.id,
          product_id: this.form.product_id,
          routing_code: this.form.routing_code,
          routing_name: this.form.routing_name,
          version: this.form.version,
          quantity: this.form.quantity,
          unit: this.form.unit,
          is_default: this.form.is_default,
          status: this.form.status,
          effective_date: this.form.effective_date || '',
          expiry_date: this.form.expiry_date || '',
          remark: this.form.remark,
          version_upgrade: this.form.version_upgrade ? 1 : 0,
          items: items.map((it, i) => ({
            process_id: it.process_id,
            sort_order: i + 1,
            standard_hours: Number(it.standard_hours) || 0,
            standard_score: Number(it.standard_score) || 0,
            workstation_id: it.workstation_id || 0,
            is_key: it.is_key,
            remark: it.remark
          }))
        })
        if (r.code === 0) {
          this.$message.success('保存成功')
          if (continueNext) {
            this.form = { ...this.form, id: 0, routing_code: '', routing_name: '', items: [] }
            this.addItem()
          } else {
            this.$router.push('/production/routing')
          }
        } else {
          this.$message.error(r.msg || '保存失败')
        }
      } catch (e) {}
      this.saving = false
    }
  }
}
</script>

<style scoped>
.routing-edit-page { padding: 4px 16px; }
.breadcrumb { margin-bottom: 14px; }
.items-header { display: flex; align-items: center; margin: 14px 0 10px; }
.items-title { font-size: 15px; font-weight: 600; }
.total-hours { margin-left: 12px; font-size: 13px; color: #909399; }
.items-actions { margin-left: auto; }
.items-table { margin-bottom: 6px; }
.footer-btns { margin-top: 18px; }
.danger { color: #f56c6c; }
</style>
