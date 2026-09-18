<template>
  <div class="pk-page">
    <el-breadcrumb separator="/" class="pk-breadcrumb">
      <el-breadcrumb-item>个人资产</el-breadcrumb-item>
      <el-breadcrumb-item>资产领用</el-breadcrumb-item>
      <el-breadcrumb-item>配件领用申请</el-breadcrumb-item>
    </el-breadcrumb>

    <!-- 提示横幅 -->
    <div class="pk-banner">
      <i class="el-icon-info pk-banner-icon"></i>
      <span>配件领用申请：从总仓库领取配件到个人名下，需经审批后生效。请如实填写领用数量和用途。</span>
    </div>

    <!-- 表单 -->
    <div class="pk-form-card">
      <el-form ref="form" :model="form" :rules="rules" label-width="100px" size="small">
        <el-row :gutter="24">
          <el-col :span="12">
            <el-form-item label="申请单号">
              <el-input :value="applyNo" disabled />
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="申请人">
              <el-input :value="userName" disabled />
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="部门">
              <el-input :value="deptName" disabled />
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="申请日期">
              <el-input :value="today" disabled />
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="选择配件" prop="material_id">
              <el-select v-model="form.material_id" filterable remote :remote-method="searchMaterials" :loading="matLoading" placeholder="请输入配件名称/编码" style="width:100%">
                <el-option v-for="m in materialOptions" :key="m.id" :label="m.material_name + '（' + (m.specification || '-') + '）— 库存：' + m.stock_quantity + ' ' + m.unit" :value="m.id" />
              </el-select>
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="规格型号">
              <el-input :value="form.specification" disabled placeholder="选择配件后自动带出" />
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="单位">
              <el-input :value="form.unit" disabled placeholder="选择配件后自动带出" />
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="当前库存">
              <el-input :value="String(currentStock)" disabled />
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="申请数量" prop="apply_quantity">
              <el-input-number v-model="form.apply_quantity" :min="0.5" :step="0.5" :max="currentStock || 9999" :precision="1" style="width:100%" />
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="关联工单">
              <el-input v-model="form.work_order_no" placeholder="可选，关联工单号" />
            </el-form-item>
          </el-col>
          <el-col :span="24">
            <el-form-item label="用途说明" prop="purpose">
              <el-input v-model="form.purpose" type="textarea" :rows="3" maxlength="500" show-word-limit placeholder="请详细说明领用用途（最少10个字符）" />
            </el-form-item>
          </el-col>
          <el-col :span="24">
            <el-form-item label="备注">
              <el-input v-model="form.remark" type="textarea" :rows="2" maxlength="200" show-word-limit placeholder="可选备注" />
            </el-form-item>
          </el-col>
        </el-row>
      </el-form>
    </div>

    <!-- 底部操作 -->
    <div class="pk-actions">
      <el-button size="small" @click="$router.back()">返回</el-button>
      <el-button size="small" :loading="saving" @click="saveDraft">保存草稿</el-button>
      <el-button size="small" type="primary" :loading="submitting" @click="submitApply">提交申请</el-button>
    </div>
  </div>
</template>

<script>
import { searchPickMaterials, createPickApply } from '../../../api/pickApply'

export default {
  name: 'PickApplyCreate',
  data () {
    const validateQty = (rule, value, cb) => {
      if (!value || value <= 0) cb(new Error('请输入申请数量'))
      else if (this.currentStock > 0 && value > this.currentStock) cb(new Error('申请数量不能超过当前库存（当前库存：' + this.currentStock + ' 件）'))
      else cb()
    }
    return {
      applyNo: '自动生成',
      userName: '',
      deptName: '',
      today: '',
      materialOptions: [], matLoading: false,
      form: { material_id: '', specification: '', unit: '', apply_quantity: 1, work_order_no: '', purpose: '', remark: '' },
      currentStock: 0,
      saving: false, submitting: false,
      rules: {
        material_id: [{ required: true, message: '请选择配件', trigger: 'change' }],
        apply_quantity: [{ validator: validateQty, trigger: 'change' }],
        purpose: [{ required: true, message: '请填写用途说明', trigger: 'blur' }, { min: 10, message: '用途说明最少10个字符', trigger: 'blur' }]
      }
    }
  },
  created () {
    const d = new Date()
    this.today = d.getFullYear() + '-' + ('0' + (d.getMonth() + 1)).slice(-2) + '-' + ('0' + d.getDate()).slice(-2)
    const userInfo = JSON.parse(localStorage.getItem('userInfo') || '{}')
    this.userName = userInfo.real_name || userInfo.name || '当前用户'
    this.deptName = userInfo.department || ''
    // 复制重申请数据（从详情返回）
    if (this.$route.query.material_id) {
      this.form.material_id = Number(this.$route.query.material_id)
      this.form.specification = this.$route.query.specification || ''
      this.form.unit = this.$route.query.unit || ''
      this.form.apply_quantity = Number(this.$route.query.quantity) || 1
      this.form.purpose = this.$route.query.purpose || ''
    }
  },
  methods: {
    async searchMaterials (kw) {
      this.matLoading = true
      try {
        const r = await searchPickMaterials({ keyword: kw || '' })
        if (r.code === 0) this.materialOptions = r.data || []
      } catch (e) {}
      this.matLoading = false
    },
    watchMaterial () {
      const m = this.materialOptions.find(x => x.id === this.form.material_id)
      if (m) {
        this.form.specification = m.specification || ''
        this.form.unit = m.unit || ''
        this.currentStock = Number(m.stock_quantity) || 0
      }
    },
    async saveDraft () {
      if (!this.form.material_id) { this.$message.warning('请选择配件'); return }
      this.saving = true
      try {
        const r = await createPickApply({ ...this.form, action: 'draft' })
        if (r.code === 0) { this.$message.success('草稿已保存'); this.$router.push('/personal-assets/pick-apply/my-list') }
      } catch (e) {}
      this.saving = false
    },
    submitApply () {
      this.$refs.form.validate(async valid => {
        if (!valid) return
        this.$confirm('确认提交配件领用申请？提交后将进入审批流程。', '确认', { type: 'warning' }).then(async () => {
          this.submitting = true
          try {
            const r = await createPickApply({ ...this.form, action: 'submit' })
            if (r.code === 0) { this.$message.success('提交成功，等待审批'); this.$router.push('/personal-assets/pick-apply/my-list') }
          } catch (e) {}
          this.submitting = false
        }).catch(() => {})
      })
    }
  },
  watch: {
    'form.material_id' () { this.watchMaterial() }
  }
}
</script>

<style scoped>
.pk-page { padding: 16px; background: #f0f2f5; min-height: 100vh; }
.pk-breadcrumb { margin-bottom: 12px; }
.pk-banner { display: flex; align-items: center; background: #ecf5ff; border: 1px solid #d9ecff; border-radius: 4px; padding: 12px 16px; margin-bottom: 16px; font-size: 14px; color: #5a6b7f; }
.pk-banner-icon { color: #409EFF; font-size: 16px; margin-right: 8px; }
.pk-form-card { background: #fff; border-radius: 8px; padding: 20px; border: 1px solid #ebeef5; }
.pk-actions { display: flex; justify-content: flex-end; gap: 10px; margin-top: 16px; }
</style>