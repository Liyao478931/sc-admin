<template>
  <div class="tc-page">
    <el-breadcrumb separator="/" class="tc-breadcrumb">
      <el-breadcrumb-item>个人资产</el-breadcrumb-item>
      <el-breadcrumb-item>资产调拨</el-breadcrumb-item>
      <el-breadcrumb-item>发起调拨</el-breadcrumb-item>
    </el-breadcrumb>

    <div class="tc-card">
      <div class="tc-title">选择资产</div>
      <div class="tc-asset-box">
        <template v-if="asset.id">
          <div class="tc-asset-name">{{ asset.asset_name }}（{{ asset.specification || '-' }}）</div>
          <div class="tc-asset-meta">编码：{{ asset.asset_code || '-' }}　可调拨数量：{{ asset.quantity }} {{ asset.unit }}</div>
          <div class="tc-asset-meta">保管人：{{ asset.user_name || '我' }}</div>
        </template>
        <div v-else class="tc-asset-empty">请选择要调拨的资产</div>
        <el-button size="small" type="text" @click="assetPickerOpen = true">{{ asset.id ? '更换资产' : '选择资产' }}</el-button>
      </div>
    </div>

    <div class="tc-card">
      <div class="tc-title">调拨对象</div>
      <div class="tc-asset-box">
        <template v-if="targetUser.id">
          <div class="tc-asset-name">{{ targetUser.name }}</div>
          <div class="tc-asset-meta">工号：{{ targetUser.employee_id || '-' }}　部门：{{ targetUser.department_name || '-' }}</div>
        </template>
        <div v-else class="tc-asset-empty">请选择调拨对象</div>
        <el-button size="small" type="text" @click="userPickerOpen = true">{{ targetUser.id ? '更换' : '选择调拨对象' }}</el-button>
      </div>
    </div>

    <div class="tc-card">
      <div class="tc-title">调拨数量</div>
      <el-input-number v-model="form.quantity" :min="1" :max="Number(asset.quantity) || 9999" :precision="0" />
      <span class="tc-tip">可调拨数量：{{ asset.quantity || 0 }} {{ asset.unit || '' }}</span>
    </div>

    <div class="tc-card">
      <div class="tc-title">调拨说明</div>
      <el-input v-model="form.remark" type="textarea" :rows="3" maxlength="200" show-word-limit placeholder="请填写调拨原因（选填）" />
    </div>

    <div class="tc-actions">
      <el-button size="small" @click="$router.back()">取消</el-button>
      <el-button size="small" type="primary" :loading="submitting" @click="submitTransfer">提交调拨</el-button>
    </div>

    <!-- 资产选择弹窗 -->
    <el-dialog title="选择资产" :visible.sync="assetPickerOpen" width="520px" append-to-body>
      <el-input v-model="assetKeyword" placeholder="搜索资产名称" clearable size="small" style="margin-bottom:10px" />
      <div v-loading="assetLoading" class="tc-picker-list">
        <div v-for="a in myAssets" :key="a.id" class="tc-picker-item" @click="pickAsset(a)">
          <div class="tc-picker-name">{{ a.asset_name }}（{{ a.specification || '-' }}）</div>
          <div class="tc-picker-meta">编码：{{ a.asset_code || '-' }}　数量：{{ a.quantity }} {{ a.unit }}</div>
        </div>
        <div v-if="!myAssets.length" class="tc-picker-empty">暂无可用资产</div>
      </div>
    </el-dialog>

    <!-- 员工选择弹窗 -->
    <el-dialog title="选择调拨对象" :visible.sync="userPickerOpen" width="500px" append-to-body>
      <el-input v-model="userKeyword" placeholder="搜索员工姓名/工号" clearable size="small" style="margin-bottom:10px" />
      <div v-loading="userLoading" class="tc-picker-list">
        <div v-for="u in userOptions" :key="u.user_id" class="tc-picker-item" @click="pickUser(u)">
          <div class="tc-picker-name">{{ u.name }}</div>
          <div class="tc-picker-meta">工号：{{ u.employee_id || '-' }}　部门：{{ u.department_name || '-' }}</div>
        </div>
        <div v-if="!userOptions.length" class="tc-picker-empty">暂无可用员工</div>
      </div>
    </el-dialog>
  </div>
</template>

<script>
import { getMyAssetList, getAssetEmployeeOptions, createTransfer } from '../../api/personalAssets'

export default {
  name: 'TransferCreate',
  data () {
    return {
      asset: {}, myAssets: [], assetLoading: false, assetPickerOpen: false, assetKeyword: '',
      targetUser: {}, userOptions: [], userLoading: false, userPickerOpen: false, userKeyword: '',
      form: { quantity: 1, remark: '' },
      submitting: false
    }
  },
  watch: {
    assetPickerOpen (v) { if (v) this.loadMyAssets() },
    userPickerOpen (v) { if (v) this.loadUsers() },
    assetKeyword () { this.loadMyAssets() },
    userKeyword () { this.loadUsers() }
  },
  created () {
    // URL 参数带入资产
    if (this.$route.query.asset_id) {
      this.loadMyAssets().then(() => {
        const a = this.myAssets.find(x => x.id === Number(this.$route.query.asset_id))
        if (a) this.pickAsset(a)
      })
    }
  },
  methods: {
    async loadMyAssets () {
      this.assetLoading = true
      try {
        const r = await getMyAssetList({ keyword: this.assetKeyword, page: 1, limit: 100 })
        if (r.code === 0) this.myAssets = r.data.list || []
      } catch (e) {}
      this.assetLoading = false
    },
    async loadUsers () {
      this.userLoading = true
      try {
        const r = await getAssetEmployeeOptions(this.userKeyword)
        if (r.code === 0) this.userOptions = r.data || []
      } catch (e) {}
      this.userLoading = false
    },
    pickAsset (a) {
      this.asset = a
      this.form.quantity = 1
      this.assetPickerOpen = false
    },
    pickUser (u) {
      this.targetUser = u
      this.userPickerOpen = false
    },
    async submitTransfer () {
      if (!this.asset.id) { this.$message.warning('请选择资产'); return }
      if (!this.targetUser.user_id) { this.$message.warning('请选择调拨对象'); return }
      if (!this.form.quantity || this.form.quantity <= 0) { this.$message.warning('请输入调拨数量'); return }
      if (this.form.quantity > Number(this.asset.quantity)) { this.$message.warning('调拨数量不能超过可调拨数量'); return }
      this.submitting = true
      try {
        const r = await createTransfer({
          asset_id: this.asset.id,
          target_user_id: this.targetUser.user_id,
          quantity: this.form.quantity,
          remark: this.form.remark
        })
        if (r.code === 0) {
          this.$message.success('调拨已发起，等待对方确认')
          this.$router.push('/personal-assets/transfer-pending')
        }
      } catch (e) {}
      this.submitting = false
    }
  }
}
</script>

<style scoped>
.tc-page { padding: 16px; background: #f0f2f5; min-height: 100vh; }
.tc-breadcrumb { margin-bottom: 12px; }
.tc-card { background: #fff; border-radius: 8px; padding: 16px 20px; margin-bottom: 12px; }
.tc-title { font-size: 14px; font-weight: 600; color: #1f2d3d; margin-bottom: 10px; }
.tc-asset-box { display: flex; align-items: center; justify-content: space-between; background: #f8fafc; border-radius: 8px; padding: 12px 16px; }
.tc-asset-name { font-size: 15px; font-weight: 700; color: #1f2d3d; }
.tc-asset-meta { font-size: 13px; color: #909399; margin-top: 4px; }
.tc-asset-empty { font-size: 14px; color: #b0c0cc; }
.tc-tip { margin-left: 12px; font-size: 13px; color: #909399; }
.tc-actions { display: flex; justify-content: flex-end; gap: 10px; }
.tc-picker-list { max-height: 400px; overflow-y: auto; }
.tc-picker-item { padding: 10px 12px; border-bottom: 1px solid #f0f2f5; cursor: pointer; }
.tc-picker-item:hover { background: #f5f7fa; }
.tc-picker-name { font-size: 14px; font-weight: 600; color: #1f2d3d; }
.tc-picker-meta { font-size: 12px; color: #909399; margin-top: 2px; }
.tc-picker-empty { text-align: center; color: #909399; padding: 30px 0; font-size: 13px; }
</style>