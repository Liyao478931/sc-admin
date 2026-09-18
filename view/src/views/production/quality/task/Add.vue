<!--
  文件：admin/src/views/production/quality/task/Add.vue
  功能：新增/编辑检验（关联工单 + 质检标准带入检验项目 + 实测值录入自动判定）
  权限：quality:task:add / edit
-->
<template>
  <div class="wh-page">
    <el-breadcrumb separator="/" class="breadcrumb">
      <el-breadcrumb-item>生产管理</el-breadcrumb-item>
      <el-breadcrumb-item>质量管理</el-breadcrumb-item>
      <el-breadcrumb-item>检验任务</el-breadcrumb-item>
      <el-breadcrumb-item>{{ isEdit ? '编辑检验' : '新增检验' }}</el-breadcrumb-item>
    </el-breadcrumb>

    <div class="page-header">
      <span class="page-title">{{ isEdit ? '编辑检验' : '新增检验' }}</span>
      <div class="header-actions">
        <el-button size="small" @click="$router.push('/production/quality/task')">取消</el-button>
        <el-button size="small" type="primary" :loading="saving" @click="handleSave">保存</el-button>
      </div>
    </div>

    <el-card shadow="never" class="form-card">
      <el-form ref="form" :model="form" :rules="rules" label-width="120px" size="small">
        <el-row :gutter="20">
          <el-col :span="12">
            <el-form-item label="关联工单" prop="work_order_id">
              <el-select v-model="form.work_order_id" filterable placeholder="请选择待质检工单" style="width:100%" @change="onOrderChange" :disabled="isEdit">
                <el-option v-for="o in orderOptions" :key="o.id" :label="`${o.order_no} - ${o.product_name}（${o.product_spec || ''}）`" :value="o.id" />
              </el-select>
            </el-form-item>
            <el-form-item label="质检标准" prop="standard_id">
              <el-select v-model="form.standard_id" filterable placeholder="请选择质检标准" style="width:100%" @change="onStandardChange">
                <el-option v-for="s in standardOptions" :key="s.id" :label="`${s.standard_name}（${s.standard_code}）`" :value="s.id" />
              </el-select>
            </el-form-item>
            <el-form-item label="质检员" prop="inspector_id">
              <el-select v-model="form.inspector_id" filterable placeholder="请选择质检员" style="width:100%">
                <el-option v-for="u in userOptions" :key="u.id" :label="u.real_name || u.username" :value="u.id" />
              </el-select>
            </el-form-item>
            <el-form-item label="检验日期" prop="inspection_date">
              <el-date-picker v-model="form.inspection_date" type="date" value-format="yyyy-MM-dd" style="width:100%" />
            </el-form-item>
          </el-col>
        </el-row>

        <div class="sub-title">检验项目（实测值录入，自动判定）</div>
        <el-table :data="form.items" size="small" border empty-text="请先选择质检标准，自动带入检验项目">
          <el-table-column type="index" label="#" width="45" align="center" />
          <el-table-column prop="item_name" label="项目名称" min-width="120" />
          <el-table-column label="类型" width="70" align="center"><template slot-scope="s">{{ itemTypeOptions[s.row.item_type] }}</template></el-table-column>
          <el-table-column prop="standard_value" label="标准值" width="130" show-overflow-tooltip />
          <el-table-column label="上下限" width="120" align="center"><template slot-scope="s">{{ s.row.lower_limit ?? '-' }} ~ {{ s.row.upper_limit ?? '-' }} {{ s.row.unit || '' }}</template></el-table-column>
          <el-table-column label="实测值" width="150">
            <template slot-scope="s">
              <el-input v-if="s.row.item_type === 1" v-model="s.row.measured_value" size="mini" placeholder="输入实测值" @input="judgeItem(s.row)" />
              <el-input-number v-else-if="s.row.item_type === 2" v-model="s.row.measured_value" :controls="false" size="mini" style="width:100%" @change="judgeItem(s.row)" />
              <el-switch v-else v-model="s.row.measured_value" active-text="合格" inactive-text="不合格" size="mini" @change="judgeItem(s.row)" />
            </template>
          </el-table-column>
          <el-table-column label="判定" width="80" align="center">
            <template slot-scope="s">
              <el-tag v-if="s.row.measured_value !== '' && s.row.measured_value !== null" :type="s.row.is_qualified === 1 ? 'success' : 'danger'" size="mini">{{ s.row.is_qualified === 1 ? '合格' : '不合格' }}</el-tag>
              <span v-else class="pending-text">未录入</span>
            </template>
          </el-table-column>
        </el-table>

        <div class="result-bar">
          总结果：
          <el-tag :type="form.result === 1 ? 'success' : (form.result === 2 ? 'danger' : 'warning')" size="medium">{{ resultOptions[form.result] }}</el-tag>
          <span class="result-tip">全部项目合格则总结果合格；任一不合格则为不合格；实测值未录全为待判定</span>
        </div>

        <el-form-item label="检验结论" prop="conclusion" style="margin-top:12px">
          <el-input v-model="form.conclusion" type="textarea" :rows="3" placeholder="请输入检验结论" />
        </el-form-item>
        <el-form-item label="备注">
          <el-input v-model="form.remark" type="textarea" :rows="2" placeholder="备注（可选）" />
        </el-form-item>
      </el-form>
    </el-card>
  </div>
</template>

<script>
import { getQualityOrders, getQualityTaskDetail, saveQualityTask, getQualityStandardList, getOrderUsers } from '@/api/production'

export default {
  name: 'QualityTaskAdd',
  data () {
    return {
      isEdit: false,
      resultOptions: { 1: '合格', 2: '不合格', 3: '待判定' },
      itemTypeOptions: { 1: '文本', 2: '数值', 3: '布尔' },
      orderOptions: [], standardOptions: [], userOptions: [],
      form: {
        work_order_id: null, standard_id: null, inspector_id: null, inspector_name: '',
        inspection_date: this.today(), conclusion: '', remark: '', items: [], result: 3
      },
      rules: {
        work_order_id: [{ required: true, message: '请选择关联工单' }],
        standard_id: [{ required: true, message: '请选择质检标准' }],
        inspector_id: [{ required: true, message: '请选择质检员' }],
        inspection_date: [{ required: true, message: '请选择检验日期' }],
        conclusion: [{ required: true, message: '请填写检验结论' }]
      },
      saving: false
    }
  },
  created () {
    this.loadOrders()
    this.loadStandards()
    this.loadUsers()
    this.prefillInspector()
    const id = this.$route.query.id
    if (id) { this.isEdit = true; this.loadDetail(id) }
  },
  methods: {
    today () { const d = new Date(); return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}` },
    prefillInspector () {
      const info = this.$store.state.user && this.$store.state.user.userInfo
      if (info && info.id) { this.form.inspector_id = info.id; this.form.inspector_name = info.real_name || info.username || '' }
    },
    async loadOrders () { try { const r = await getQualityOrders(); if (r.code === 0) this.orderOptions = r.data.list || [] } catch (e) { this.orderOptions = [] } },
    async loadStandards () { try { const r = await getQualityStandardList({ page: 1, pageSize: 500, status: 1 }); if (r.code === 0) this.standardOptions = r.data.list || [] } catch (e) { this.standardOptions = [] } },
    async loadUsers () { try { const r = await getOrderUsers(); if (r.code === 0) this.userOptions = r.data.list || [] } catch (e) { this.userOptions = [] } },
    onOrderChange (id) {
      const o = this.orderOptions.find(x => x.id === id)
      if (!o) return
      // 自动匹配：标准适用产品类型包含工单产品名（弱匹配，可手动改）
      const matched = this.standardOptions.find(s => o.product_name && s.product_type && o.product_name.indexOf(s.product_type) >= 0)
      if (matched) { this.form.standard_id = matched.id; this.onStandardChange() }
    },
    onStandardChange () {
      const s = this.standardOptions.find(x => x.id === this.form.standard_id)
      this.form.items = (s && s.items ? s.items : []).map(it => ({
        item_name: it.item_name, item_type: Number(it.item_type) || 1, standard_value: it.standard_value || '',
        upper_limit: it.upper_limit ?? null, lower_limit: it.lower_limit ?? null, unit: it.unit || '',
        measured_value: '', is_qualified: 0
      }))
      this.computeResult()
    },
    judgeItem (row) {
      if (row.item_type === 2 && row.measured_value !== '' && row.measured_value !== null) {
        const v = Number(row.measured_value)
        row.is_qualified = ((row.upper_limit === null || row.upper_limit === undefined || v <= Number(row.upper_limit)) &&
          (row.lower_limit === null || row.lower_limit === undefined || v >= Number(row.lower_limit))) ? 1 : 0
      } else if (row.item_type === 3) {
        row.is_qualified = row.measured_value === true ? 1 : 0
      } else {
        row.is_qualified = (row.measured_value !== '' && row.measured_value !== null && row.measured_value !== undefined) ? 1 : 0
      }
      this.computeResult()
    },
    computeResult () {
      const items = this.form.items
      if (!items.length) { this.form.result = 3; return }
      const filled = items.filter(i => i.measured_value !== '' && i.measured_value !== null && i.measured_value !== undefined)
      const unqualified = items.filter(i => i.is_qualified === 0)
      if (unqualified.length) this.form.result = 2
      else if (filled.length === items.length) this.form.result = 1
      else this.form.result = 3
    },
    async loadDetail (id) {
      try {
        const r = await getQualityTaskDetail(id)
        if (r.code === 0 && r.data) {
          const d = r.data.inspection
          this.form = {
            work_order_id: d.work_order_id, standard_id: d.standard_id, inspector_id: d.inspector_id,
            inspector_name: d.inspector_name, inspection_date: d.inspection_date || this.today(),
            conclusion: d.conclusion || '', remark: d.remark || '',
            items: (r.data.items || []).map(i => ({
              item_name: i.item_name, item_type: Number(i.item_type), standard_value: i.standard_value || '',
              upper_limit: i.upper_limit, lower_limit: i.lower_limit, unit: i.unit || '',
              measured_value: i.measured_value ?? '', is_qualified: Number(i.is_qualified)
            })),
            result: Number(d.result)
          }
        }
      } catch (e) {}
    },
    async handleSave () {
      if (!this.form.work_order_id) { this.$message.warning('请选择关联工单'); return }
      if (!this.form.standard_id) { this.$message.warning('请选择质检标准'); return }
      if (!this.form.inspector_id) { this.$message.warning('请选择质检员'); return }
      if (!this.form.conclusion) { this.$message.warning('请填写检验结论'); return }
      const filled = this.form.items.filter(i => i.measured_value !== '' && i.measured_value !== null && i.measured_value !== undefined)
      if (!filled.length) { this.$message.warning('请至少填写一个检验项目的实测值'); return }
      this.saving = true
      try {
        const data = {
          work_order_id: this.form.work_order_id, standard_id: this.form.standard_id,
          inspector_id: this.form.inspector_id, inspector_name: this.form.inspector_name,
          inspection_date: this.form.inspection_date, conclusion: this.form.conclusion, remark: this.form.remark,
          items: this.form.items
        }
        if (this.isEdit) data.id = this.$route.query.id
        const r = await saveQualityTask(data)
        if (r.code === 0) { this.$message.success('保存成功'); this.$router.replace('/production/quality/task') } else this.$message.error(r.msg || '保存失败')
      } catch (e) {} finally { this.saving = false }
    }
  }
}
</script>

<style scoped>
.wh-page { padding: 16px; }
.breadcrumb { margin-bottom: 12px; }
.page-header { display: flex; justify-content: space-between; align-items: center; background: #fff; padding: 14px 20px; border-radius: 8px 8px 0 0; border-bottom: 1px solid #ebeef5; }
.page-title { font-size: 18px; font-weight: 700; }
.header-actions { display: flex; gap: 10px; }
.form-card { margin-top: 12px; border-radius: 8px; }
.sub-title { font-size: 14px; font-weight: 600; margin: 8px 0 12px; }
.result-bar { margin: 12px 0; font-size: 14px; color: #303133; }
.result-tip { font-size: 12px; color: #909399; margin-left: 10px; }
.pending-text { color: #909399; font-size: 12px; }
</style>
