<template>
  <el-dialog :title="form.id ? '编辑分类' : '新增分类'" :visible.sync="visible" width="550px" append-to-body @closed="resetForm">
    <el-form :model="form" label-width="90px" size="small">
      <el-form-item label="分类标识" required>
        <el-input v-model="form.category_key" maxlength="30" :disabled="!!form.id" placeholder="请输入分类标识（如 device）" />
        <div class="tip">小写字母开头，由小写字母/数字/下划线组成，创建后不可修改</div>
      </el-form-item>
      <el-form-item label="分类名称" required>
        <el-input v-model="form.category_name" maxlength="50" placeholder="请输入分类名称（如 设备工具）" />
      </el-form-item>
      <el-form-item label="分类图标">
        <el-input v-model="form.icon" maxlength="50" placeholder="请输入图标类名或emoji（如 el-icon-s-management）" />
      </el-form-item>
      <el-form-item label="排序">
        <el-input-number v-model="form.sort" :min="0" :step="10" />
      </el-form-item>
      <el-form-item label="状态">
        <el-switch v-model="form.status" :active-value="1" :inactive-value="0" active-text="启用" inactive-text="停用" />
      </el-form-item>
      <el-form-item label="描述">
        <el-input v-model="form.description" type="textarea" :rows="2" maxlength="255" placeholder="可选" />
      </el-form-item>
    </el-form>
    <div slot="footer">
      <el-button size="small" @click="visible = false">取消</el-button>
      <el-button size="small" type="primary" :loading="saving" @click="submit">确定</el-button>
    </div>
  </el-dialog>
</template>

<script>
import { addToolCategory, editToolCategory } from '../../../../api/aiToolCategory'

export default {
  name: 'CategoryFormDialog',
  data() {
    return {
      visible: false,
      saving: false,
      form: { id: null, category_key: '', category_name: '', icon: '', sort: 0, status: 1, description: '' }
    }
  },
  methods: {
    open(row) {
      if (row) {
        this.form = {
          id: row.id, category_key: row.category_key, category_name: row.category_name,
          icon: row.icon || '', sort: Number(row.sort) || 0, status: Number(row.status),
          description: row.description || ''
        }
      }
      this.visible = true
    },
    resetForm() {
      this.form = { id: null, category_key: '', category_name: '', icon: '', sort: 0, status: 1, description: '' }
    },
    async submit() {
      if (!this.form.category_key) return this.$message.warning('请输入分类标识')
      if (!this.form.category_name) return this.$message.warning('请输入分类名称')
      this.saving = true
      try {
        if (this.form.id) {
          await editToolCategory(this.form.id, {
            category_name: this.form.category_name, icon: this.form.icon,
            sort: this.form.sort, status: this.form.status, description: this.form.description
          })
        } else {
          await addToolCategory({
            category_key: this.form.category_key, category_name: this.form.category_name,
            icon: this.form.icon, sort: this.form.sort, status: this.form.status, description: this.form.description
          })
        }
        this.$message.success(this.form.id ? '分类已更新' : '分类创建成功')
        this.visible = false
        this.$emit('saved')
      } catch (e) {}
      this.saving = false
    }
  }
}
</script>

<style scoped>
.tip { color: #909399; font-size: 12px; margin-top: 4px; }
</style>
