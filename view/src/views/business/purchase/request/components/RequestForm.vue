<!--
  文件：admin/src/views/business/purchase/request/components/RequestForm.vue
  功能：采购申请信息表单（基本信息 + 来源信息 + 其他）
  props：form（对象，直接修改）、disabled、deptOptions（部门选项）
  emits：source-selected（{id,no,expected_date}）
-->
<template>
  <el-form ref="requestForm" :model="form" :rules="rules" label-width="120px" size="small">
    <el-row :gutter="16">
      <el-col :span="12">
        <el-form-item label="申请标题" prop="title">
          <el-input v-model="form.title" :disabled="disabled" placeholder="请输入申请标题" clearable />
        </el-form-item>
      </el-col>
      <el-col :span="12">
        <el-form-item label="申请类型" prop="request_type">
          <el-select v-model="form.request_type" :disabled="disabled" style="width:100%">
            <el-option label="日常采购" :value="1" />
            <el-option label="项目采购" :value="2" />
            <el-option label="紧急采购" :value="3" />
            <el-option label="备品备件采购" :value="4" />
          </el-select>
        </el-form-item>
      </el-col>
      <el-col :span="12">
        <el-form-item label="申请部门" prop="department_id">
          <el-cascader v-model="deptPath" :options="deptOptions" :props="{ value: 'id', label: 'name', children: 'children' }" :disabled="disabled" clearable filterable placeholder="请选择部门（含子部门）" style="width:100%" @change="handleDeptChange" />
        </el-form-item>
      </el-col>
      <el-col :span="12">
        <el-form-item label="紧急程度" prop="urgency">
          <el-select v-model="form.urgency" :disabled="disabled" style="width:100%">
            <el-option label="普通" :value="1" />
            <el-option label="紧急" :value="2" />
            <el-option label="特急" :value="3" />
          </el-select>
        </el-form-item>
      </el-col>
      <el-col :span="12">
        <el-form-item label="预算科目">
          <el-input v-model="form.budget_subject" :disabled="disabled" placeholder="预算科目（可选）" clearable />
        </el-form-item>
      </el-col>
      <el-col :span="12">
        <el-form-item label="预算金额">
          <el-input-number v-model="form.budget_amount" :disabled="disabled" :min="0" :precision="2" :step="100" style="width:100%" />
        </el-form-item>
      </el-col>
      <el-col :span="12">
        <el-form-item label="来源类型" prop="source_type">
          <el-select v-model="form.source_type" :disabled="disabled" style="width:100%" @change="$emit('source-type-change', form.source_type)">
            <el-option label="手动创建" :value="1" />
            <el-option label="销售订单" :value="2" />
            <el-option label="维修订单" :value="3" />
            <el-option label="生产工单" :value="4" />
            <el-option label="安全库存补货" :value="5" />
            <el-option label="消耗品补充" :value="6" />
            <el-option label="项目采购" :value="7" />
            <el-option label="计划采购" :value="8" />
            <el-option label="紧急采购" :value="9" />
          </el-select>
        </el-form-item>
      </el-col>
      <el-col :span="12">
        <el-form-item label="来源单据" v-if="form.source_type === 2 || form.source_type === 3">
          <SourceSelector :source-type="form.source_type" :source-id="form.source_id" :source-no="form.source_no" @input="onSourceInput" />
        </el-form-item>
      </el-col>
      <el-col :span="12">
        <el-form-item label="期望交付日期" prop="expected_date">
          <el-date-picker v-model="form.expected_date" :disabled="disabled" type="date" value-format="yyyy-MM-dd" placeholder="选择期望交付日期" style="width:100%" />
        </el-form-item>
      </el-col>
      <el-col :span="24">
        <el-form-item label="用途说明" prop="purpose">
          <el-input v-model="form.purpose" :disabled="disabled" type="textarea" :rows="4" placeholder="详细描述采购原因、用途和要求" />
        </el-form-item>
      </el-col>
      <el-col :span="24">
        <el-form-item label="备注">
          <el-input v-model="form.remark" :disabled="disabled" type="textarea" :rows="3" placeholder="补充说明（可选）" />
        </el-form-item>
      </el-col>
    </el-row>
  </el-form>
</template>

<script>
import SourceSelector from './SourceSelector.vue'

export default {
  name: 'RequestForm',
  components: { SourceSelector },
  props: {
    form: { type: Object, required: true },
    disabled: { type: Boolean, default: false },
    deptOptions: { type: Array, default: () => [] }
  },
  data() {
    return {
      deptPath: [],
      rules: {
        title: [{ required: true, message: '请输入申请标题', trigger: 'blur' }],
        request_type: [{ required: true, message: '请选择申请类型', trigger: 'change' }],
        department_id: [{ required: true, message: '请选择申请部门', trigger: 'change' }],
        urgency: [{ required: true, message: '请选择紧急程度', trigger: 'change' }],
        source_type: [{ required: true, message: '请选择来源类型', trigger: 'change' }],
        expected_date: [{ required: true, message: '请选择期望交付日期', trigger: 'change' }],
        purpose: [{ required: true, message: '请填写用途说明', trigger: 'blur' }]
      }
    }
  },
  watch: {
    'form.urgency'(val) {
      // 紧急/特急时自动在标题前添加 [紧急]/[特急] 前缀（可逆）
      const prefixes = { 1: '', 2: '[紧急]', 3: '[特急]' }
      const target = prefixes[val] || ''
      let title = this.form.title || ''
      title = title.replace(/^(\[紧急\]|\[特急\])/, '')
      if (target) title = target + title
      this.form.title = title
    },
    'form.department_id'(val) {
      // 外部赋值（编辑回显/重置）时同步级联路径
      if (val && this.deptOptions.length) {
        const path = this.findPath(this.deptOptions, val)
        if (path && path.length) this.deptPath = path
      }
    },
    deptOptions() {
      // 部门树加载后同步已选部门路径（编辑回显）
      if (this.form.department_id && this.deptOptions.length) {
        const path = this.findPath(this.deptOptions, this.form.department_id)
        if (path && path.length) this.deptPath = path
      }
    }
  },
  methods: {
    findPath(nodes, targetId, path = []) {
      for (const n of nodes) {
        const p = [...path, n.id]
        if (n.id === targetId) return p
        if (n.children && n.children.length) {
          const r = this.findPath(n.children, targetId, p)
          if (r) return r
        }
      }
      return null
    },
    handleDeptChange(val) {
      this.form.department_id = Array.isArray(val) && val.length ? val[val.length - 1] : null
    },
    onSourceInput(data) {
      this.form.source_id = data.id
      this.form.source_no = data.no
      if (data.expected_date && !this.form.expected_date) this.form.expected_date = data.expected_date
      this.$emit('source-selected', data)
    },
    validate() {
      return new Promise(resolve => {
        this.$refs.requestForm.validate(valid => resolve(valid))
      })
    }
  }
}
</script>
