<template>
  <div class="maintenance-level-page">
    <el-card shadow="never">
      <div slot="header" class="card-header">
        <span>保养等级管理</span>
        <div style="float:right;">
          <el-button v-if="hasPerm('device:maintenance:level:add')" size="small" type="primary" icon="el-icon-plus" @click="openForm()">新增等级</el-button>
          <el-button size="small" icon="el-icon-refresh" @click="loadList">刷新</el-button>
        </div>
      </div>

      <el-table :data="list" v-loading="loading" stripe border size="small">
        <el-table-column type="index" label="#" width="50" />
        <el-table-column prop="level_code" label="等级编码" width="120" />
        <el-table-column prop="level_name" label="等级名称" min-width="140" />
        <el-table-column prop="executor_role" label="执行人角色" width="110" />
        <el-table-column prop="acceptor_role" label="验收人角色" width="110" />
        <el-table-column label="默认周期" width="150">
          <template slot-scope="{row}">{{ cycleTypeLabel(row.default_cycle_type) }} {{ row.default_cycle_value > 0 ? row.default_cycle_value : '' }}</template>
        </el-table-column>
        <el-table-column prop="sort" label="排序" width="70" />
        <el-table-column label="状态" width="80">
          <template slot-scope="{row}"><el-tag :type="row.status === 1 ? 'success' : 'info'" size="mini">{{ row.status === 1 ? '启用' : '停用' }}</el-tag></template>
        </el-table-column>
        <el-table-column label="操作" width="160" fixed="right">
          <template slot-scope="{row}">
            <el-button v-if="hasPerm('device:maintenance:level:edit')" size="mini" type="text" icon="el-icon-edit" @click="openForm(row)">编辑</el-button>
            <el-button v-if="hasPerm('device:maintenance:level:delete')" size="mini" type="text" icon="el-icon-delete" style="color:#F56C6C" @click="handleDelete(row)">删除</el-button>
          </template>
        </el-table-column>
      </el-table>
    </el-card>

    <!-- 新增/编辑弹窗 -->
    <el-dialog :title="form.id ? '编辑保养等级' : '新增保养等级'" :visible.sync="formVisible" width="560px" :close-on-click-modal="false">
      <el-form :model="form" :rules="rules" ref="form" label-width="110px" size="small">
        <el-form-item label="等级编码" prop="level_code">
          <el-input v-model="form.level_code" :disabled="!!form.id" placeholder="如 DAILY、LEVEL1" maxlength="30" />
        </el-form-item>
        <el-form-item label="等级名称" prop="level_name">
          <el-input v-model="form.level_name" placeholder="如 日常保养、一级保养" maxlength="50" />
        </el-form-item>
        <el-form-item label="执行人角色">
          <el-input v-model="form.executor_role" placeholder="如 操作工、维护员、工程师、专业维保" maxlength="50" />
        </el-form-item>
        <el-form-item label="验收人角色">
          <el-input v-model="form.acceptor_role" placeholder="如 班长、工程师、主管、经理" maxlength="50" />
        </el-form-item>
        <el-form-item label="默认周期类型">
          <el-select v-model="form.default_cycle_type" clearable style="width:100%">
            <el-option v-for="o in cycleTypeOptions" :key="o.value" :label="o.label" :value="o.value" />
          </el-select>
        </el-form-item>
        <el-form-item label="默认周期值">
          <el-input-number v-model="form.default_cycle_value" :min="0" style="width:100%" />
        </el-form-item>
        <el-form-item label="排序">
          <el-input-number v-model="form.sort" :min="0" style="width:100%" />
        </el-form-item>
        <el-form-item label="描述">
          <el-input v-model="form.description" type="textarea" :rows="2" maxlength="255" />
        </el-form-item>
        <el-form-item label="状态">
          <el-switch v-model="form.status" :active-value="1" :inactive-value="0" active-text="启用" inactive-text="停用" />
        </el-form-item>
      </el-form>
      <span slot="footer">
        <el-button @click="formVisible = false">取消</el-button>
        <el-button type="primary" :loading="saving" @click="handleSave">保存</el-button>
      </span>
    </el-dialog>
  </div>
</template>

<script>
import { getLevelList, addLevel, editLevel, deleteLevel } from '@/api/maintenance'

export default {
  name: 'MaintenanceLevel',
  data() {
    return {
      list: [], loading: false, saving: false,
      formVisible: false,
      form: { id: 0, level_code: '', level_name: '', executor_role: '', acceptor_role: '', default_cycle_type: '', default_cycle_value: 0, description: '', sort: 0, status: 1 },
      rules: {
        level_code: [{ required: true, message: '请输入等级编码', trigger: 'blur' }],
        level_name: [{ required: true, message: '请输入等级名称', trigger: 'blur' }]
      },
      cycleTypeOptions: []
    }
  },
  created() { this.loadList(); this.loadDicts() },
  methods: {
    hasPerm(code) { const p = this.$store.state.user && this.$store.state.user.permissions ? this.$store.state.user.permissions : []; return p.indexOf(code) > -1 },
    // 周期类型从字典动态加载
    async loadDicts() {
      const { getDictByCode } = await import('../../../../api/dictionary')
      try { const r = await getDictByCode('maintenance_cycle_type'); this.cycleTypeOptions = r.data || [] } catch (e) { this.cycleTypeOptions = [] }
    },
    cycleTypeLabel(t) { const o = this.cycleTypeOptions.find(x => x.value === t); return o ? o.label : (t || '-') },
    async loadList() {
      this.loading = true
      try { const r = await getLevelList(); if (r.code === 0) this.list = r.data.list || [] } catch (e) {}
      this.loading = false
    },
    openForm(row) {
      this.form = row ? { ...row } : { id: 0, level_code: '', level_name: '', executor_role: '', acceptor_role: '', default_cycle_type: '', default_cycle_value: 0, description: '', sort: 0, status: 1 }
      this.formVisible = true
      this.$nextTick(() => this.$refs.form && this.$refs.form.clearValidate())
    },
    async handleSave() {
      const valid = await this.$refs.form.validate().catch(() => false)
      if (!valid) return
      this.saving = true
      try {
        const d = { ...this.form }
        if (d.id) { const r = await editLevel(d.id, d); if (r.code === 0) { this.$message.success('更新成功'); this.formVisible = false; this.loadList() } }
        else { const r = await addLevel(d); if (r.code === 0) { this.$message.success('创建成功'); this.formVisible = false; this.loadList() } }
      } catch (e) {}
      this.saving = false
    },
    async handleDelete(row) {
      try {
        await this.$confirm(`确认删除保养等级「${row.level_name}」？`, '提示', { type: 'warning' })
        const r = await deleteLevel(row.id)
        if (r.code === 0) { this.$message.success('已删除'); this.loadList() }
      } catch (e) {}
    }
  }
}
</script>

<style scoped>
.maintenance-level-page { padding: 0; }
</style>
