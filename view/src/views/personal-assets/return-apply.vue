<template>
  <div class="ra-page">
    <el-breadcrumb separator="/" class="ra-breadcrumb">
      <el-breadcrumb-item>个人资产</el-breadcrumb-item>
      <el-breadcrumb-item>资产退还</el-breadcrumb-item>
      <el-breadcrumb-item>退还申请</el-breadcrumb-item>
    </el-breadcrumb>

    <div class="ra-card">
      <div class="ra-title">选择资产</div>
      <div class="ra-asset-box">
        <template v-if="asset.id">
          <div class="ra-asset-name">{{ asset.asset_name }}（{{ asset.specification || '-' }}）</div>
          <div class="ra-asset-meta">编码：{{ asset.asset_code || '-' }}　可退还数量：{{ asset.quantity }} {{ asset.unit }}</div>
          <div class="ra-asset-meta">类型：{{ asset.asset_type_label }}</div>
        </template>
        <div v-else class="ra-asset-empty">请选择要退还的资产</div>
        <el-button size="small" type="text" @click="assetPickerOpen = true">{{ asset.id ? '更换资产' : '选择资产' }}</el-button>
      </div>
    </div>

    <div class="ra-card">
      <div class="ra-title">退还数量 <span style="color:#F56C6C">*</span></div>
      <el-input-number v-model="form.return_quantity" :min="1" :max="Number(asset.quantity) || 9999" :precision="0" />
      <span class="ra-tip">可退还数量：{{ asset.quantity || 0 }} {{ asset.unit || '' }}</span>
    </div>

    <div class="ra-card">
      <div class="ra-title">退还原因 <span style="color:#F56C6C">*</span></div>
      <el-input v-model="form.reason" type="textarea" :rows="3" maxlength="200" show-word-limit placeholder="请填写退还原因（必填）" />
    </div>

    <div class="ra-card">
      <div class="ra-title">资产照片（选填）</div>
      <el-upload :show-file-list="false" :http-request="handlePhotoUpload" accept="image/*">
        <el-button size="small" icon="el-icon-camera">点击上传</el-button>
        <span class="ra-tip">支持 JPG/PNG，不超过 5M</span>
      </el-upload>
      <div style="margin-top:6px">
        <el-button size="mini" type="primary" plain icon="el-icon-folder-opened" @click="driveVisible = true">从企业网盘选择</el-button>
      </div>
      <drive-file-picker :visible="driveVisible" mode="image" :multiple="false" @update:visible="driveVisible = $event" @confirm="onDrivePick" />
      <el-image v-if="form.photo" :src="form.photo" fit="cover" class="ra-photo-preview" :preview-src-list="[form.photo]" />
    </div>

    <div class="ra-tip-box">💡 提示：提交后将由资产管理员审批，审批通过后资产将退还至总仓库。</div>

    <div class="ra-actions">
      <el-button size="small" @click="$router.back()">取消</el-button>
      <el-button size="small" type="primary" :loading="submitting" @click="submitApply">提交申请</el-button>
    </div>

    <!-- 资产选择弹窗 -->
    <el-dialog title="选择资产" :visible.sync="assetPickerOpen" width="600px" append-to-body>
      <el-input v-model="assetKeyword" placeholder="搜索资产名称/编码" clearable size="small" style="margin-bottom:10px" />
      <div v-loading="assetLoading" class="ra-picker-list">
        <div v-for="a in assetList" :key="a.id" class="ra-picker-item" @click="pickAsset(a)">
          <div class="ra-picker-name">{{ a.asset_name }}（{{ a.specification || '-' }}）</div>
          <div class="ra-picker-meta">编码：{{ a.asset_code || '-' }}　可用：{{ a.quantity }} {{ a.unit }}</div>
        </div>
        <div v-if="!assetList.length" class="ra-picker-empty">您名下暂无可用资产</div>
      </div>
    </el-dialog>
  </div>
</template>

<script>
import { getReturnableAssets, submitReturn } from '../../api/personalAssets'
import { uploadReportPhoto } from '../../api/production'

export default {
  name: 'ReturnApply',
  data () {
    return {
      asset: {},
      driveVisible: false,
      form: { return_quantity: 1, reason: '', photo: '' },
      assetPickerOpen: false, assetKeyword: '', assetLoading: false, assetList: [],
      submitting: false
    }
  },
  watch: {
    assetPickerOpen (v) { if (v) this.loadAssets() },
    assetKeyword () { this.loadAssets() }
  },
  created () {
    if (this.$route.query.asset_id) {
      this.loadAssets().then(() => {
        const a = this.assetList.find(x => x.id === Number(this.$route.query.asset_id))
        if (a) this.pickAsset(a)
      })
    }
  },
  methods: {
    async loadAssets () {
      this.assetLoading = true
      try {
        const r = await getReturnableAssets({ keyword: this.assetKeyword, limit: 100 })
        if (r.code === 0) this.assetList = r.data.list || []
      } catch (e) {}
      this.assetLoading = false
    },
    pickAsset (a) {
      this.asset = a
      this.form.return_quantity = 1
      this.assetPickerOpen = false
    },
    onDrivePick(list) { if (list.length) { this.form.photo = list[0].url; this.$message.success('已选择：' + list[0].name) } },
    async handlePhotoUpload (options) {
      const file = options.file
      if (file.size > 5 * 1024 * 1024) { this.$message.warning('图片不能超过 5MB'); options.onError(); return }
      const fd = new FormData()
      fd.append('file', file)
      try {
        const r = await uploadReportPhoto(fd)
        if (r.code === 0 && r.data.url) { this.form.photo = r.data.url; options.onSuccess(r.data) } else { this.$message.error(r.msg || '上传失败'); options.onError() }
      } catch (e) { options.onError() }
    },
    async submitApply () {
      if (!this.asset.id) { this.$message.warning('请选择要退还的资产'); return }
      if (!this.form.return_quantity || this.form.return_quantity <= 0) { this.$message.warning('请输入退还数量'); return }
      if (this.form.return_quantity > Number(this.asset.quantity)) { this.$message.warning('退还数量不能超过可用数量'); return }
      if (!this.form.reason) { this.$message.warning('请填写退还原因'); return }
      this.submitting = true
      try {
        const r = await submitReturn({
          asset_id: this.asset.id,
          return_quantity: this.form.return_quantity,
          reason: this.form.reason,
          photo: this.form.photo
        })
        if (r.code === 0) {
          this.$message.success('申请已提交，请等待管理员审批')
          this.$router.push('/personal-assets/return-records')
        }
      } catch (e) {}
      this.submitting = false
    }
  }
}
</script>

<style scoped>
.ra-page { padding: 16px; background: #f0f2f5; min-height: 100vh; max-width: 700px; margin: 0 auto; }
.ra-breadcrumb { margin-bottom: 12px; }
.ra-card { background: #fff; border-radius: 8px; padding: 16px 20px; margin-bottom: 12px; }
.ra-title { font-size: 14px; font-weight: 600; color: #1f2d3d; margin-bottom: 10px; }
.ra-asset-box { display: flex; align-items: center; justify-content: space-between; background: #f8fafc; border-radius: 8px; padding: 12px 16px; }
.ra-asset-name { font-size: 15px; font-weight: 700; color: #1f2d3d; }
.ra-asset-meta { font-size: 13px; color: #909399; margin-top: 4px; }
.ra-asset-empty { font-size: 14px; color: #b0c0cc; }
.ra-tip { margin-left: 12px; font-size: 13px; color: #909399; }
.ra-tip-box { background: #ecf5ff; border: 1px solid #d9ecff; border-radius: 8px; padding: 12px 16px; font-size: 13px; color: #5a6b7f; margin-bottom: 12px; }
.ra-actions { display: flex; justify-content: flex-end; gap: 10px; }
.ra-photo-preview { width: 120px; height: 120px; border-radius: 8px; margin-top: 10px; }
.ra-picker-list { max-height: 400px; overflow-y: auto; }
.ra-picker-item { padding: 10px 12px; border-bottom: 1px solid #f0f2f5; cursor: pointer; }
.ra-picker-item:hover { background: #f5f7fa; }
.ra-picker-name { font-size: 14px; font-weight: 600; color: #1f2d3d; }
.ra-picker-meta { font-size: 12px; color: #909399; margin-top: 2px; }
.ra-picker-empty { text-align: center; color: #909399; padding: 30px 0; font-size: 13px; }
</style>