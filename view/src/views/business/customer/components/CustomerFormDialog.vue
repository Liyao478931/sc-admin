<!--
  文件：admin/src/views/business/customer/components/CustomerFormDialog.vue
  功能：新增/编辑客户弹窗（700px）
    - 基本信息：客户名称必填、客户简称、客户编码（新增自动生成只读）、客户类型必选、所属行业、所属区域、客户等级默认C
    - 联系人信息：联系人姓名、联系电话、联系邮箱、地址
    - 财务信息：税号、开户银行、银行账号、信用额度
    - 分类与状态：客户分类、状态开关
    - 备注
-->
<template>
  <el-dialog
    :title="isEdit ? '编辑客户' : '新增客户'"
    :visible="visible"
    width="700px"
    :close-on-click-modal="false"
    @close="$emit('update:visible', false)"
  >
    <el-form ref="form" :model="form" :rules="rules" label-width="110px" size="small" v-loading="loading">
      <!-- 基本信息 -->
      <el-divider content-position="left">基本信息</el-divider>
      <el-row :gutter="12">
        <el-col :span="12">
          <el-form-item label="客户名称" prop="customer_name">
            <el-input v-model="form.customer_name" placeholder="客户全称" maxlength="200" />
          </el-form-item>
        </el-col>
        <el-col :span="12">
          <el-form-item label="客户简称">
            <el-input v-model="form.customer_short_name" maxlength="50" />
          </el-form-item>
        </el-col>
        <el-col :span="12">
          <el-form-item label="客户编码">
            <el-input :value="isEdit ? form.customer_code : '自动生成'" disabled />
          </el-form-item>
        </el-col>
        <el-col :span="12">
          <el-form-item label="客户类型" prop="customer_type">
            <el-select v-model="form.customer_type" style="width:100%" placeholder="请选择">
              <el-option v-for="opt in typeOptions" :key="opt.value" :label="opt.label" :value="opt.value" />
            </el-select>
          </el-form-item>
        </el-col>
        <el-col :span="12">
          <el-form-item label="所属行业">
            <el-select v-model="form.industry" style="width:100%" placeholder="请选择" clearable>
              <el-option v-for="opt in industryOptions" :key="opt.value" :label="opt.label" :value="opt.value" />
            </el-select>
          </el-form-item>
        </el-col>
        <el-col :span="12">
          <el-form-item label="所属区域">
            <el-cascader
              v-model="regionPath"
              :options="regionTree"
              filterable
              clearable
              :props="{ checkStrictly: true, expandTrigger: 'hover' }"
              style="width:100%"
              placeholder="搜索或选择 省/市/县"
            />
          </el-form-item>
        </el-col>
        <el-col :span="12">
          <el-form-item label="客户等级">
            <el-radio-group v-model="form.customer_level">
              <el-radio-button v-for="opt in levelOptions" :key="opt.value" :label="opt.value">{{ opt.label }}</el-radio-button>
            </el-radio-group>
          </el-form-item>
        </el-col>
      </el-row>

      <!-- 联系人信息 -->
      <el-divider content-position="left">联系人信息</el-divider>
      <el-row :gutter="12">
        <el-col :span="12"><el-form-item label="联系人姓名"><el-input v-model="form.contact_person" maxlength="50" /></el-form-item></el-col>
        <el-col :span="12"><el-form-item label="联系电话"><el-input v-model="form.contact_phone" maxlength="20" /></el-form-item></el-col>
        <el-col :span="12"><el-form-item label="联系邮箱"><el-input v-model="form.contact_email" maxlength="100" /></el-form-item></el-col>
        <el-col :span="12"><el-form-item label="地址"><el-input v-model="form.address" maxlength="255" /></el-form-item></el-col>
      </el-row>

      <!-- 财务信息 -->
      <el-divider content-position="left">财务信息</el-divider>
      <el-row :gutter="12">
        <el-col :span="12"><el-form-item label="税号"><el-input v-model="form.tax_number" maxlength="50" /></el-form-item></el-col>
        <el-col :span="12"><el-form-item label="开户银行"><el-input v-model="form.bank_name" maxlength="100" /></el-form-item></el-col>
        <el-col :span="12"><el-form-item label="银行账号"><el-input v-model="form.bank_account" maxlength="50" /></el-form-item></el-col>
        <el-col :span="12">
          <el-form-item label="信用额度">
            <el-input-number v-model="form.credit_limit" :min="0" :precision="2" style="width:100%" />
          </el-form-item>
        </el-col>
      </el-row>

      <!-- 分类与状态 -->
      <el-divider content-position="left">分类与状态</el-divider>
      <el-row :gutter="12">
        <el-col :span="12">
          <el-form-item label="客户分类">
            <el-select v-model="form.category_id" style="width:100%" placeholder="请选择" clearable>
              <el-option v-for="c in categories" :key="c.id" :label="c.category_name" :value="c.id" />
            </el-select>
          </el-form-item>
        </el-col>
        <el-col :span="12">
          <el-form-item label="状态">
            <el-switch v-model="form.status" :active-value="1" :inactive-value="0" active-text="启用" inactive-text="停用" />
          </el-form-item>
        </el-col>
      </el-row>

      <!-- 备注 -->
      <el-form-item label="备注">
        <el-input v-model="form.remark" type="textarea" :rows="3" maxlength="500" />
      </el-form-item>
    </el-form>

    <div slot="footer">
      <el-button size="small" @click="$emit('update:visible', false)">取消</el-button>
      <el-button size="small" type="primary" :loading="saving" @click="handleSubmit">保存</el-button>
    </div>
  </el-dialog>
</template>

<script>
import { addCustomer, editCustomer, getCategoryOptions } from '../../../../api/businessCustomer'
import { getDictByCode } from '../../../../api/dictionary'

export default {
  name: 'CustomerFormDialog',
  props: {
    visible: { type: Boolean, default: false },
    row: { type: Object, default: null } // 编辑时传入，新增为 null
  },
  data() {
    return {
      loading: false,
      saving: false,
      categories: [],
      typeOptions: [], industryOptions: [], levelOptions: [],
      regionTree: [], regionPath: [], valueToPath: {},
      regionMap: { north: '华北', east: '华东', south: '华南', central: '华中', southwest: '西南', northwest: '西北', northeast: '东北', other: '其他' },
      form: {
        customer_name: '', customer_short_name: '', customer_code: '',
        customer_type: '', industry: '', region: '', customer_level: 'C',
        contact_person: '', contact_phone: '', contact_email: '', address: '',
        tax_number: '', bank_name: '', bank_account: '', credit_limit: 0,
        category_id: null, status: 1, remark: ''
      },
      rules: {
        customer_name: [{ required: true, message: '请输入客户名称', trigger: 'blur' }],
        customer_type: [{ required: true, message: '请选择客户类型', trigger: 'change' }]
      }
    }
  },
  computed: {
    isEdit() { return !!(this.row && this.row.id) }
  },
  watch: {
    visible(val) {
      if (val) this.open()
    }
  },
  methods: {
    async open() {
      this.loading = true
      this.regionPath = []
      this.form = {
        customer_name: '', customer_short_name: '', customer_code: '',
        customer_type: '', industry: '', region: '', customer_level: 'C',
        contact_person: '', contact_phone: '', contact_email: '', address: '',
        tax_number: '', bank_name: '', bank_account: '', credit_limit: 0,
        category_id: null, status: 1, remark: ''
      }
      if (this.isEdit) {
        const r = this.row
        this.form = {
          customer_name: r.customer_name || '', customer_short_name: r.customer_short_name || '', customer_code: r.customer_code || '',
          customer_type: r.customer_type || '', industry: r.industry || '', region: r.region || '', customer_level: r.customer_level || 'C',
          contact_person: r.contact_person || '', contact_phone: r.contact_phone || '', contact_email: r.contact_email || '', address: r.address || '',
          tax_number: r.tax_number || '', bank_name: r.bank_name || '', bank_account: r.bank_account || '', credit_limit: Number(r.credit_limit) || 0,
          category_id: r.category_id || null, status: r.status === 0 ? 0 : 1, remark: r.remark || ''
        }
      }
      try {
        const c = await getCategoryOptions()
        this.categories = c.data || []
      } catch (e) { this.categories = [] }
      // 客户类型 / 所属行业 / 客户等级从字典动态加载（字典新增即自动显示）
      try { const t = await getDictByCode('customer_type'); this.typeOptions = t.data || [] } catch (e) { this.typeOptions = [] }
      try { const i = await getDictByCode('customer_industry'); this.industryOptions = i.data || [] } catch (e) { this.industryOptions = [] }
      try { const l = await getDictByCode('customer_level'); this.levelOptions = l.data || [] } catch (e) { this.levelOptions = [] }
      // 独立加载区域树（不与分类加载相互影响，保证级联数据必定就绪）
      await this.loadRegionTree()
      // 编辑回显：根据已存区域编码反查级联路径
      if (this.isEdit && this.form.region) {
        this.regionPath = this.valueToPath[this.form.region] || []
      }
      this.loading = false
    },
    // 加载全国行政区划字典并递归构建省/市/县级联树（支持任意层级）
    async loadRegionTree() {
      try {
        const r = await getDictByCode('china_region')
        const items = r.data || []
        // 按父级编码分组（extra[0] 为父级代码，空为省级）
        const byParent = {}
        items.forEach(it => {
          const extra = Array.isArray(it.extra) && it.extra.length ? it.extra[0] : ''
          const key = extra || 'root'
          if (!byParent[key]) byParent[key] = []
          byParent[key].push({ value: it.value, label: it.label })
        })
        // 递归构建树并记录 value → 路径（用于编辑回显）
        const valueToPath = {}
        const build = (parentKey, prefix) => {
          const nodes = byParent[parentKey] || []
          return nodes.map(n => {
            const path = [...prefix, n.value]
            valueToPath[n.value] = path
            n.children = build(n.value, path)
            return n
          })
        }
        const tree = build('root', [])
        this.regionTree = tree
        this.valueToPath = valueToPath
      } catch (e) {
        this.regionTree = []
      }
    },
    async handleSubmit() {
      const valid = await this.$refs.form.validate().catch(() => false)
      if (!valid) return
      // 所属区域：取级联末级编码（行政区划代码）
      this.form.region = this.regionPath.length ? this.regionPath[this.regionPath.length - 1] : ''
      this.saving = true
      try {
        if (this.isEdit) {
          const r = await editCustomer(this.row.id, this.form)
          if (r.code === 0) { this.$message.success('客户已更新'); this.$emit('success') }
        } else {
          const r = await addCustomer(this.form)
          if (r.code === 0) { this.$message.success('客户创建成功'); this.$emit('success') }
        }
      } catch (e) {}
      this.saving = false
    }
  }
}
</script>
