<template>
  <div class="ta-page">
    <el-breadcrumb separator="/" class="ta-breadcrumb">
      <el-breadcrumb-item>个人资产</el-breadcrumb-item>
      <el-breadcrumb-item>资产调拨</el-breadcrumb-item>
      <el-breadcrumb-item>申请调拨</el-breadcrumb-item>
    </el-breadcrumb>

    <div class="ta-card">
      <div class="ta-title">申请资产</div>
      <div class="ta-asset-box">
        <template v-if="asset.id">
          <div class="ta-asset-name">{{ asset.asset_name }}（{{ asset.specification || '-' }}）</div>
          <div class="ta-asset-meta">编码：{{ asset.asset_code || '-' }}　可用数量：{{ asset.quantity }} {{ asset.unit }}</div>
          <div class="ta-asset-meta">保管人：{{ asset.keeper_name }}{{ asset.keeper_no ? '（' + asset.keeper_no + '）' : '' }}</div>
        </template>
        <div v-else class="ta-asset-empty">请从可借用资产页面选择要申请的资产</div>
      </div>
    </div>

    <div class="ta-card">
      <div class="ta-title">调拨数量</div>
      <el-input-number v-model="form.quantity" :min="1" :max="Number(asset.quantity) || 9999" :precision="0" />
      <span class="ta-tip">可申请数量：{{ asset.quantity || 0 }} {{ asset.unit || '' }}</span>
    </div>

    <div class="ta-card">
      <div class="ta-title">用途说明 <span style="color:#F56C6C">*</span></div>
      <el-input v-model="form.purpose" type="textarea" :rows="3" maxlength="200" show-word-limit placeholder="请说明领用用途（必填）" />
    </div>

    <div class="ta-tip-box">💡 申请调拨：向保管人发起领用申请，待对方确认后资产自动转移至您的名下。</div>

    <div class="ta-actions">
      <el-button size="small" @click="$router.back()">取消</el-button>
      <el-button size="small" type="primary" :loading="submitting" @click="submitApply">提交申请</el-button>
    </div>
  </div>
</template>

<script>
import { applyTransfer } from '../../api/personalAssets'

export default {
  name: 'TransferApply',
  data () {
    return {
      asset: {},
      form: { quantity: 1, purpose: '' },
      submitting: false
    }
  },
  created () {
    // 从可借用资产页面带入（query 参数）
    if (this.$route.query.asset_id && this.$route.query.keeper_id) {
      this.asset = {
        id: Number(this.$route.query.asset_id),
        asset_name: this.$route.query.asset_name || '',
        asset_code: this.$route.query.asset_code || '',
        specification: this.$route.query.specification || '',
        unit: this.$route.query.unit || '',
        quantity: Number(this.$route.query.quantity) || 0,
        keeper_id: Number(this.$route.query.keeper_id),
        keeper_name: this.$route.query.keeper_name || '',
        keeper_no: this.$route.query.keeper_no || ''
      }
    }
  },
  methods: {
    async submitApply () {
      if (!this.asset.id) { this.$message.warning('请选择资产'); return }
      if (!this.form.quantity || this.form.quantity <= 0) { this.$message.warning('请输入调拨数量'); return }
      if (this.form.quantity > Number(this.asset.quantity)) { this.$message.warning('调拨数量不能超过可用数量'); return }
      if (!this.form.purpose) { this.$message.warning('请填写用途说明'); return }
      this.submitting = true
      try {
        const r = await applyTransfer({
          asset_id: this.asset.id,
          quantity: this.form.quantity,
          purpose: this.form.purpose
        })
        if (r.code === 0) {
          this.$message.success('申请已发送，请等待保管人确认')
          this.$router.push('/personal-assets/transfer-pending')
        }
      } catch (e) {}
      this.submitting = false
    }
  }
}
</script>

<style scoped>
.ta-page { padding: 16px; background: #f0f2f5; min-height: 100vh; }
.ta-breadcrumb { margin-bottom: 12px; }
.ta-card { background: #fff; border-radius: 8px; padding: 16px 20px; margin-bottom: 12px; }
.ta-title { font-size: 14px; font-weight: 600; color: #1f2d3d; margin-bottom: 10px; }
.ta-asset-box { background: #f8fafc; border-radius: 8px; padding: 12px 16px; }
.ta-asset-name { font-size: 15px; font-weight: 700; color: #1f2d3d; }
.ta-asset-meta { font-size: 13px; color: #909399; margin-top: 4px; }
.ta-asset-empty { font-size: 14px; color: #b0c0cc; }
.ta-tip { margin-left: 12px; font-size: 13px; color: #909399; }
.ta-tip-box { background: #ecf5ff; border: 1px solid #d9ecff; border-radius: 8px; padding: 12px 16px; font-size: 13px; color: #5a6b7f; margin-bottom: 12px; }
.ta-actions { display: flex; justify-content: flex-end; gap: 10px; }
</style>