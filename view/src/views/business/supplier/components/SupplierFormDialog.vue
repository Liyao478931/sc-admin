<!--
  文件：admin/src/views/business/supplier/components/SupplierFormDialog.vue
  功能：新增/编辑供应商弹窗（700px）
    - 基本信息：名称必填、简称、编码（自动生成只读）、类型必选、供应品类、所属区域、评级默认C
    - 联系人信息：姓名、电话、邮箱、地址
    - 资质信息：税号、开户银行、银行账号、资质证照（动态列表）、合作开始日期
    - 分类与状态：供应商分类、状态开关
    - 备注
-->
<template>
  <el-dialog
    :title="isEdit ? '编辑供应商' : '新增供应商'"
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
          <el-form-item label="供应商名称" prop="supplier_name">
            <el-input v-model="form.supplier_name" placeholder="供应商全称" maxlength="200" />
          </el-form-item>
        </el-col>
        <el-col :span="12">
          <el-form-item label="供应商简称">
            <el-input v-model="form.supplier_short_name" maxlength="50" />
          </el-form-item>
        </el-col>
        <el-col :span="12">
          <el-form-item label="供应商编码">
            <el-input :value="isEdit ? form.supplier_code : '自动生成'" disabled />
          </el-form-item>
        </el-col>
        <el-col :span="12">
          <el-form-item label="供应商类型" prop="supplier_type">
            <el-select v-model="form.supplier_type" style="width:100%" placeholder="请选择">
              <el-option v-for="opt in typeOptions" :key="opt.value" :label="opt.label" :value="opt.value" />
            </el-select>
          </el-form-item>
        </el-col>
        <el-col :span="12">
          <el-form-item label="供应品类">
            <el-select v-model="form.supply_category" style="width:100%" placeholder="请选择" clearable>
              <el-option v-for="opt in supplyOptions" :key="opt.value" :label="opt.label" :value="opt.value" />
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
          <el-form-item label="供应商评级">
            <el-radio-group v-model="form.supplier_level">
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

      <!-- 资质信息 -->
      <el-divider content-position="left">资质信息</el-divider>
      <el-row :gutter="12">
        <el-col :span="12"><el-form-item label="税号"><el-input v-model="form.tax_number" maxlength="50" /></el-form-item></el-col>
        <el-col :span="12"><el-form-item label="开户银行"><el-input v-model="form.bank_name" maxlength="100" /></el-form-item></el-col>
        <el-col :span="12"><el-form-item label="银行账号"><el-input v-model="form.bank_account" maxlength="50" /></el-form-item></el-col>
        <el-col :span="12">
          <el-form-item label="合作开始日期">
            <el-date-picker v-model="form.cooperation_start" type="date" value-format="yyyy-MM-dd" style="width:100%" placeholder="选择日期" />
          </el-form-item>
        </el-col>
      </el-row>

      <!-- 资质证照（动态列表：名称/编号/有效期） -->
      <el-form-item label="资质证照">
        <div v-for="(q, idx) in form.qualifications" :key="idx" class="qual-row">
          <el-input v-model="q.name" placeholder="证照名称（如营业执照）" style="width:180px" maxlength="50" />
          <el-input v-model="q.number" placeholder="证照编号" style="width:160px" maxlength="50" />
          <el-date-picker v-model="q.expire" type="date" value-format="yyyy-MM-dd" placeholder="有效期至" style="width:150px" />
          <el-button type="text" icon="el-icon-delete" class="danger" @click="removeQual(idx)"></el-button>
        </div>
        <el-button size="mini" icon="el-icon-plus" @click="addQual">添加证照</el-button>
      </el-form-item>

      <!-- 分类与状态 -->
      <el-divider content-position="left">分类与状态</el-divider>
      <el-row :gutter="12">
        <el-col :span="12">
          <el-form-item label="供应商分类">
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
import { addSupplier, editSupplier, getSupplierCategoryOptions } from '../../../../api/businessSupplier'
import { getDictByCode } from '../../../../api/dictionary'

export default {
  name: 'SupplierFormDialog',
  props: {
    visible: { type: Boolean, default: false },
    row: { type: Object, default: null }
  },
  data() {
    return {
      loading: false,
      saving: false,
      categories: [],
      typeOptions: [], supplyOptions: [], levelOptions: [],
      regionTree: [], regionPath: [], valueToPath: {},
      form: {
        supplier_name: '', supplier_short_name: '', supplier_code: '',
        supplier_type: '', supply_category: '', region: '', supplier_level: 'C',
        contact_person: '', contact_phone: '', contact_email: '', address: '',
        tax_number: '', bank_name: '', bank_account: '', qualifications: [], cooperation_start: '',
        category_id: null, status: 1, remark: ''
      },
      rules: {
        supplier_name: [{ required: true, message: '请输入供应商名称', trigger: 'blur' }],
        supplier_type: [{ required: true, message: '请选择供应商类型', trigger: 'change' }]
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
        supplier_name: '', supplier_short_name: '', supplier_code: '',
        supplier_type: '', supply_category: '', region: '', supplier_level: 'C',
        contact_person: '', contact_phone: '', contact_email: '', address: '',
        tax_number: '', bank_name: '', bank_account: '', qualifications: [], cooperation_start: '',
        category_id: null, status: 1, remark: ''
      }
      if (this.isEdit) {
        const r = this.row
        this.form = {
          supplier_name: r.supplier_name || '', supplier_short_name: r.supplier_short_name || '', supplier_code: r.supplier_code || '',
          supplier_type: r.supplier_type || '', supply_category: r.supply_category || '', region: r.region || '', supplier_level: r.supplier_level || 'C',
          contact_person: r.contact_person || '', contact_phone: r.contact_phone || '', contact_email: r.contact_email || '', address: r.address || '',
          tax_number: r.tax_number || '', bank_name: r.bank_name || '', bank_account: r.bank_account || '',
          qualifications: Array.isArray(r.qualifications) ? r.qualifications.map(q => ({ name: q.name || '', number: q.number || '', expire: q.expire || '' })) : [],
          cooperation_start: r.cooperation_start || '',
          category_id: r.category_id || null, status: r.status === 0 ? 0 : 1, remark: r.remark || ''
        }
      }
      try {
        const c = await getSupplierCategoryOptions()
        this.categories = c.data || []
      } catch (e) { this.categories = [] }
      // 供应商类型 / 供应品类 / 供应商评级从字典动态加载（字典新增即自动显示）
      try { const t = await getDictByCode('supplier_type'); this.typeOptions = t.data || [] } catch (e) { this.typeOptions = [] }
      try { const s = await getDictByCode('supplier_supply_category'); this.supplyOptions = s.data || [] } catch (e) { this.supplyOptions = [] }
      try { const l = await getDictByCode('supplier_level'); this.levelOptions = l.data || [] } catch (e) { this.levelOptions = [] }
      // 独立加载区域树（保证级联数据必定就绪）
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
        const byParent = {}
        items.forEach(it => {
          const extra = Array.isArray(it.extra) && it.extra.length ? it.extra[0] : ''
          const key = extra || 'root'
          if (!byParent[key]) byParent[key] = []
          byParent[key].push({ value: it.value, label: it.label })
        })
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
    addQual() { this.form.qualifications.push({ name: '', number: '', expire: '' }) },
    removeQual(idx) { this.form.qualifications.splice(idx, 1) },
    async handleSubmit() {
      const valid = await this.$refs.form.validate().catch(() => false)
      if (!valid) return
      // 所属区域：取级联末级编码（行政区划代码）
      this.form.region = this.regionPath.length ? this.regionPath[this.regionPath.length - 1] : ''
      // 清理空证照行
      this.form.qualifications = this.form.qualifications.filter(q => q.name !== '' || q.number !== '' || q.expire !== '')
      this.saving = true
      try {
        if (this.isEdit) {
          const r = await editSupplier(this.row.id, this.form)
          if (r.code === 0) { this.$message.success('供应商已更新'); this.$emit('success') }
        } else {
          const r = await addSupplier(this.form)
          if (r.code === 0) { this.$message.success('供应商创建成功'); this.$emit('success') }
        }
      } catch (e) {}
      this.saving = false
    }
  }
}
</script>

<style scoped>
.qual-row { display: flex; gap: 8px; margin-bottom: 8px; }
.danger { color: #f56c6c; }
</style>
