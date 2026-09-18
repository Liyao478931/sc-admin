<!--
  文件：admin/src/views/business/product/bom/Edit.vue
  功能：编辑BOM（头信息回显 + 子项编辑 + 版本升级确认）
  权限：business:product:bom:edit；已审批BOM只读
-->
<template>
  <div class="bom-form-page">
    <el-breadcrumb separator="/" class="breadcrumb">
      <el-breadcrumb-item>经营管理</el-breadcrumb-item>
      <el-breadcrumb-item>产品管理</el-breadcrumb-item>
      <el-breadcrumb-item>BOM管理</el-breadcrumb-item>
      <el-breadcrumb-item>编辑BOM</el-breadcrumb-item>
    </el-breadcrumb>

    <el-alert v-if="approved" type="warning" :closable="false" show-icon title="该BOM已审批，不可编辑（仅可查看与复制）" style="margin-bottom:12px" />

    <div class="page-header">
      <span class="page-title">编辑BOM - {{ form.bom_code || '' }}</span>
      <div class="header-actions">
        <el-button type="primary" size="small" :loading="submitting" :disabled="approved" @click="handleSave(false)">保存</el-button>
        <el-button size="small" :loading="submitting" :disabled="approved" @click="handleSave(true)">保存并继续</el-button>
        <el-button size="small" @click="$router.push('/business/product/bom')">取消</el-button>
      </div>
    </div>

    <el-card shadow="never" class="header-card" v-loading="loading">
      <div class="section-title">BOM头信息</div>
      <BomHeaderForm ref="headerForm" :form="form" :disabled="approved" :id="id" :product-label="productLabel" />
    </el-card>

    <el-card shadow="never" class="items-card" v-loading="loading">
      <div class="section-title">BOM子项列表</div>
      <BomEditableTable ref="editableTable" :items="items" :disabled="approved" />
    </el-card>
  </div>
</template>

<script>
import BomHeaderForm from './components/BomHeaderForm.vue'
import BomEditableTable from './components/BomEditableTable.vue'
import { getBomDetail, saveBom } from '../../../../api/product'

let seq = 0

export default {
  name: 'BusinessProductBomEdit',
  components: { BomHeaderForm, BomEditableTable },
  data() {
    return {
      id: Number(this.$route.params.id) || 0,
      loading: false,
      submitting: false,
      approved: false,
      form: {
        id: null,
        product_id: null,
        bom_code: '',
        bom_name: '',
        version: 'V1.0',
        quantity: 1,
        unit: '',
        is_default: 0,
        status: 1,
        effective_date: '',
        expiry_date: '',
        remark: ''
      },
      items: [],
      snapshot: [], // 结构快照（用于版本升级判定）
      productLabel: ''
    }
  },
  created() {
    this.fetchDetail()
  },
  methods: {
    async fetchDetail() {
      this.loading = true
      try {
        const r = await getBomDetail(this.id)
        if (r.code === 0 && r.data) {
          const bom = r.data.bom || {}
          this.approved = bom.approval_status === 2
          this.form = {
            id: bom.id,
            product_id: bom.product_id,
            bom_code: bom.bom_code,
            bom_name: bom.bom_name,
            version: bom.version,
            quantity: Number(bom.quantity) || 1,
            unit: bom.unit || '',
            is_default: bom.is_default,
            status: bom.status,
            effective_date: bom.effective_date || '',
            expiry_date: bom.expiry_date || '',
            remark: bom.remark || ''
          }
          this.productLabel = (bom.product_code ? bom.product_code + ' ' : '') + (bom.product_name || '')
          this.items = []
          this.snapshot = []
          this.flattenTree(r.data.items || [], 0, this.items)
        } else {
          this.$message.error(r.msg || 'BOM不存在')
          this.$router.push('/business/product/bom')
        }
      } catch (e) {}
      this.loading = false
    },
    /** 树形 → 平铺（含 _key/父引用映射与数值转换） */
    flattenTree(nodes, parentKey, out) {
      ;(nodes || []).forEach(n => {
        const key = ++seq
        out.push({
          _key: key,
          parent_item_id: parentKey || 0,
          component_product_id: n.component_product_id,
          component_code: n.component_code,
          component_name: n.component_name,
          component_spec: n.component_spec || '',
          component_unit: n.component_unit || '',
          quantity: Number(n.quantity) || 1,
          wastage_rate: Number(n.wastage_rate) || 0,
          source_type: n.source_type,
          is_key: n.is_key,
          remark: n.remark || '',
          sort: n.sort || 0
        })
        this.snapshot.push({ k: key, pid: n.component_product_id, qty: Number(n.quantity) || 1, wr: Number(n.wastage_rate) || 0, parent: parentKey || 0 })
        if (n.children && n.children.length) this.flattenTree(n.children, key, out)
      })
    },
    /** 结构性变化判定：新增/删除/改产品ID/改用量/改损耗率/改层级 */
    hasStructuralChange() {
      const cur = this.items.map(x => ({ k: x._key, pid: x.component_product_id, qty: x.quantity, wr: x.wastage_rate, parent: x.parent_item_id || 0 }))
      if (cur.length !== this.snapshot.length) return true
      const map = {}
      this.snapshot.forEach(s => { map[s.k] = s })
      for (const c of cur) {
        const s = map[c.k]
        if (!s) return true
        if (Number(s.pid) !== Number(c.pid) || Number(s.qty) !== Number(c.qty) || Number(s.wr) !== Number(c.wr) || Number(s.parent) !== Number(c.parent)) return true
      }
      return false
    },
    async handleSave(continueEdit) {
      const headerOk = await this.$refs.headerForm.validate()
      if (!headerOk) return
      const submitItems = this.$refs.editableTable.getSubmitItems()
      // 结构性变化 → 版本升级确认
      let versionUpgrade = false
      if (this.hasStructuralChange()) {
        try {
          await this.$confirm('检测到BOM结构发生变化，是否升级版本号？选择升级将自动升级版本号（如V1.0→V1.1），选择不升级则保持当前版本号', '版本升级', {
            confirmButtonText: '升级版本',
            cancelButtonText: '不升级',
            type: 'warning'
          })
          versionUpgrade = true
        } catch (e) { versionUpgrade = false }
      }
      this.submitting = true
      try {
        const payload = { id: this.id, ...this.form, items: submitItems, version_upgrade: versionUpgrade ? 1 : 0 }
        const r = await saveBom(payload)
        if (r.code === 0) {
          this.$message.success('保存成功')
          if (r.data && r.data.version && r.data.version !== this.form.version) this.form.version = r.data.version
          this.rebuildSnapshot()
          if (!continueEdit) this.$router.push('/business/product/bom')
        }
      } catch (e) {}
      this.submitting = false
    },
    /** 保存成功后重建结构快照（避免"保存并继续"再次触发版本升级提示） */
    rebuildSnapshot() {
      this.snapshot = []
      this.items.forEach(x => {
        this.snapshot.push({ k: x._key, pid: x.component_product_id, qty: Number(x.quantity) || 1, wr: Number(x.wastage_rate) || 0, parent: x.parent_item_id || 0 })
      })
    }
  }
}
</script>

<style scoped>
.bom-form-page { padding: 4px 16px; }
.breadcrumb { margin-bottom: 14px; }
.page-header { display: flex; align-items: center; justify-content: space-between; margin-bottom: 14px; }
.page-title { font-size: 18px; font-weight: 700; color: #303133; }
.header-actions .el-button + .el-button { margin-left: 10px; }
.header-card { margin-bottom: 14px; }
.section-title { display: flex; align-items: center; font-size: 15px; font-weight: 600; margin-bottom: 12px; }
.section-title::before { content: ''; width: 4px; height: 14px; border-radius: 2px; background: #409eff; margin-right: 8px; }
</style>
