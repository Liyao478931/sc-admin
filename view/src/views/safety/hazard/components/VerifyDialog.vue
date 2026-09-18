<template>
  <el-dialog title="隐患验证" :visible.sync="dialogVisible" width="700px" @open="openVerifyForm">
    <div v-loading="loading">
      <el-descriptions :column="3" border size="small" title="隐患信息">
        <el-descriptions-item label="隐患编号">{{ d.hazard_code || '-' }}</el-descriptions-item>
        <el-descriptions-item label="隐患名称">{{ d.hazard_name || '-' }}</el-descriptions-item>
        <el-descriptions-item label="隐患等级"><el-tag :type="levelType(d.hazard_level)" size="mini">{{ levelLabel(d.hazard_level) }}</el-tag></el-descriptions-item>
        <el-descriptions-item label="整改人">{{ d.handler_name || '-' }}</el-descriptions-item>
        <el-descriptions-item label="整改完成">{{ d.handle_completed_at || '-' }}</el-descriptions-item>
        <el-descriptions-item label="发现人">{{ d.discovered_by_name || '-' }}</el-descriptions-item>
      </el-descriptions>
      <el-descriptions :column="1" border size="small" title="整改信息" style="margin-top:12px">
        <el-descriptions-item label="整改措施">{{ d.handle_measure || '-' }}</el-descriptions-item>
        <el-descriptions-item label="整改附件">
          <el-image v-for="(a, i) in attachments" :key="i" :src="a" style="width:60px;height:60px;margin-right:6px" fit="cover" :preview-src-list="attachments" />
          <span v-if="!attachments.length">-</span>
        </el-descriptions-item>
      </el-descriptions>
      <el-form label-width="100px" size="small" style="margin-top:16px">
        <el-form-item label="验证意见"><el-input v-model="form.opinion" type="textarea" :rows="4" maxlength="500" placeholder="请填写验证意见（至少10字）" /></el-form-item>
        <el-form-item label="验证照片">
          <el-upload action="/api/upload/image" :headers="uploadHeaders" list-type="picture-card" multiple :limit="9" accept="image/jpeg,image/png,image/gif,image/webp" :before-upload="beforeUpload" :on-success="onUpload" :on-remove="onRemove" :on-preview="onPreview"><i class="el-icon-plus"></i></el-upload>
        </el-form-item>
      </el-form>
      <el-collapse style="margin-top:8px">
        <el-collapse-item title="验证历史（{{ (d.verify_history || []).length }}）">
          <el-timeline v-if="d.verify_history && d.verify_history.length">
            <el-timeline-item v-for="(h, i) in d.verify_history" :key="i" :timestamp="h.time" placement="top">
              <div>{{ h.type === 'reject' ? '驳回' : (h.result === 'passed' ? '验证通过' : '验证') }}：{{ h.opinion }}</div>
              <div style="color:#909399;font-size:12px">{{ h.by }}</div>
            </el-timeline-item>
          </el-timeline>
          <el-empty v-else description="暂无验证历史" :image-size="50" />
        </el-collapse-item>
      </el-collapse>
    </div>
    <div slot="footer">
      <el-button type="success" :loading="submitting" @click="$emit('pass', { id: d.id, opinion: form.opinion, images: images })">通过并关闭</el-button>
      <el-button type="danger" :loading="submitting" @click="$emit('reject', { id: d.id, reason: form.opinion })">驳回</el-button>
      <el-button @click="dialogVisible = false">取消</el-button>
    </div>
  </el-dialog>
</template>

<script>
import { getVerifyDetail } from '@/api/safetyHazard'
import { getDictionaryBatch } from '@/utils/dict'
import { getToken } from '@/utils/auth'

export default {
  name: 'HazardVerifyDialog',
  props: { visible: Boolean, hazardId: { type: Number, default: 0 } },
  data() {
    return {
      dialogVisible: this.visible, loading: false, submitting: false, d: {},
      levelDict: [], form: { opinion: '' }, images: []
    }
  },
  computed: {
    uploadHeaders() { return { Authorization: 'Bearer ' + getToken() } },
    attachments() { const v = this.d.handle_attachments; return Array.isArray(v) ? v : (typeof v === 'string' && v ? JSON.parse(v) : []) }
  },
  watch: { visible(val) { this.dialogVisible = val } },
  methods: {
    levelLabel(v) { const t = this.levelDict.find(x => x.value === v); return t ? t.label : v },
    levelType(v) { const t = this.levelDict.find(x => x.value === v); return (t && t.style) || 'info' },
    async openVerifyForm() {
      this.form = { opinion: '' }; this.images = []; this.d = { hazard_code: '', hazard_name: '', hazard_level: '' }
      try {
        const dict = await getDictionaryBatch(['safety_hazard_level'])
        this.levelDict = dict['safety_hazard_level'] || []
        if (this.hazardId) {
          const r = await getVerifyDetail(this.hazardId)
          if (r.code === 0) this.d = r.data
        }
      } catch (e) {}
    },
    beforeUpload(f) { if (f.size > 5 * 1024 * 1024) { this.$message.error('照片不能超过5MB'); return false } return true },
    onUpload(res, file) { if (res.code === 0 && res.data && res.data.url) this.images.push(res.data.url) },
    onRemove(file) { const url = file.url || (file.response && file.response.data && file.response.data.url); this.images = this.images.filter(x => x !== url) },
    onPreview(file) { if (file.url) window.open(file.url, '_blank') }
  }
}
</script>
