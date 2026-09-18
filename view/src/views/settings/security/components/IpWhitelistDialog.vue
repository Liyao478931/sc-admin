<template>
  <el-dialog :title="form.id ? '编辑IP白名单' : '新增IP白名单'" :visible.sync="visible" width="480px" append-to-body @closed="resetForm">
    <el-form :model="form" label-width="90px" size="small">
      <el-form-item label="IP地址/CIDR" required>
        <el-input v-model="form.ip_address" placeholder="如 192.168.1.100 或 192.168.1.0/24" />
      </el-form-item>
      <el-form-item label="描述">
        <el-input v-model="form.description" placeholder="可选" />
      </el-form-item>
      <el-form-item label="过期时间">
        <el-date-picker v-model="form.expire_time" type="datetime" value-format="yyyy-MM-dd HH:mm:ss" placeholder="留空为永不过期" style="width: 100%;" />
      </el-form-item>
    </el-form>
    <div slot="footer">
      <el-button size="small" @click="visible = false">取消</el-button>
      <el-button size="small" type="primary" :loading="saving" @click="submit">确定</el-button>
    </div>
  </el-dialog>
</template>

<script>
import { addIpWhitelist, editIpWhitelist } from '../../../../api/securityPolicy'

export default {
  name: 'IpWhitelistDialog',
  data() {
    return {
      visible: false,
      saving: false,
      form: { id: null, ip_address: '', description: '', expire_time: '' }
    }
  },
  methods: {
    open(row) {
      if (row) {
        this.form = { id: row.id, ip_address: row.ip_address, description: row.description || '', expire_time: row.expire_time || '' }
      }
      this.visible = true
    },
    resetForm() {
      this.form = { id: null, ip_address: '', description: '', expire_time: '' }
    },
    async submit() {
      if (!this.form.ip_address) return this.$message.warning('请输入IP地址')
      this.saving = true
      try {
        const payload = { ip_address: this.form.ip_address, description: this.form.description, expire_time: this.form.expire_time }
        if (this.form.id) await editIpWhitelist(this.form.id, payload)
        else await addIpWhitelist(payload)
        this.$message.success('保存成功')
        this.visible = false
        this.$emit('saved')
      } catch (e) {}
      this.saving = false
    }
  }
}
</script>
