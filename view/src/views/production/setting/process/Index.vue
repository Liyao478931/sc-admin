<!--
  文件：admin/src/views/production/setting/process/Index.vue
  功能：工序管理（标准维修工序与工分定额配置）
  权限：production:process:view/add/edit/delete
-->
<template>
  <div class="wh-page">
    <el-breadcrumb separator="/" class="breadcrumb">
      <el-breadcrumb-item>生产管理</el-breadcrumb-item>
      <el-breadcrumb-item>基础设置</el-breadcrumb-item>
      <el-breadcrumb-item>工序管理</el-breadcrumb-item>
    </el-breadcrumb>

    <div class="search-bar">
      <el-form inline size="small" label-width="80px" @submit.native.prevent>
        <el-form-item label="工序名称"><el-input v-model="query.process_name" placeholder="请输入工序名称" clearable style="width:150px" @keyup.enter.native="handleSearch" /></el-form-item>
        <el-form-item label="工序编码"><el-input v-model="query.process_code" placeholder="请输入工序编码" clearable style="width:150px" @keyup.enter.native="handleSearch" /></el-form-item>
        <el-form-item label="工序组">
          <el-select v-model="query.process_group" clearable filterable allow-create placeholder="全部" style="width:130px">
            <el-option v-for="g in groupOptions" :key="g" :label="g" :value="g" />
          </el-select>
        </el-form-item>
        <el-form-item label="状态">
          <el-select v-model="query.status" clearable placeholder="全部" style="width:100px">
            <el-option label="启用" :value="1" />
            <el-option label="停用" :value="0" />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-button type="primary" icon="el-icon-search" @click="handleSearch">搜索</el-button>
          <el-button icon="el-icon-refresh-left" @click="handleReset">重置</el-button>
        </el-form-item>
      </el-form>
    </div>

    <div class="toolbar">
      <div class="toolbar-left">
        <el-button v-permission="'production:process:add'" type="primary" size="small" icon="el-icon-plus" @click="openDialog()">新增工序</el-button>
        <el-button size="small" icon="el-icon-refresh" :loading="loading" @click="loadData">刷新</el-button>
      </div>
      <span class="total-text">共 {{ total }} 条</span>
    </div>

    <el-table :data="list" v-loading="loading" size="small" border stripe>
      <el-table-column type="index" label="#" width="55" align="center" />
      <el-table-column prop="process_code" label="工序编码" width="120" />
      <el-table-column prop="process_name" label="工序名称" min-width="120" />
      <el-table-column prop="process_group" label="工序组" width="110" show-overflow-tooltip />
      <el-table-column prop="product_type" label="适用产品类型" width="110" show-overflow-tooltip />
      <el-table-column prop="sort_order" label="工序顺序" width="80" align="center" />
      <el-table-column label="工分定额" width="90" align="right"><template slot-scope="s">{{ Number(s.row.standard_score) }} 分</template></el-table-column>
      <el-table-column label="关联工位数" width="100" align="center">
        <template slot-scope="s"><span class="link-blue" @click="openWsRel(s.row)">{{ s.row.workstation_count || 0 }} 个工位</span></template>
      </el-table-column>
      <el-table-column label="标准工时" width="100" align="right"><template slot-scope="s">{{ Number(s.row.standard_hours) }} 小时</template></el-table-column>
      <el-table-column label="必须" width="70" align="center"><template slot-scope="s">{{ s.row.is_required === 1 ? '是' : '否' }}</template></el-table-column>
      <el-table-column label="状态" width="80" align="center">
        <template slot-scope="s"><el-tag :type="s.row.status_tag" size="mini">{{ s.row.status_label }}</el-tag></template>
      </el-table-column>
      <el-table-column label="操作" width="160" align="center" fixed="right">
        <template slot-scope="s">
          <el-button v-permission="'production:process:edit'" type="text" size="mini" @click="openDialog(s.row)">编辑</el-button>
          <el-button v-permission="'production:process:delete'" type="text" size="mini" class="danger-text" @click="handleDelete(s.row)">删除</el-button>
          <el-button v-permission="'production:process:edit'" type="text" size="mini" @click="handleToggle(s.row)">{{ s.row.status === 1 ? '停用' : '启用' }}</el-button>
          <el-button v-permission="'production:process:edit'" type="text" size="mini" @click="openWsRel(s.row)">关联工位</el-button>
        </template>
      </el-table-column>
    </el-table>

    <el-pagination class="pager" background layout="total, sizes, prev, pager, next, jumper"
      :total="total" :current-page="page" :page-size="pageSize" :page-sizes="[10, 20, 50, 100]"
      @current-change="handlePageChange" @size-change="handleSizeChange" />

    <!-- 新增/编辑对话框 -->
    <el-dialog :title="dialog.id ? '编辑工序' : '新增工序'" :visible.sync="dialogVisible" width="650px" append-to-body>
      <el-form ref="form" :model="dialog" :rules="rules" label-width="120px" size="small">
        <el-row :gutter="16">
          <el-col :span="12">
            <el-form-item label="工序编码" prop="process_code"><el-input v-model="dialog.process_code" placeholder="请输入工序编码，如 PRC-001" /></el-form-item>
            <el-form-item label="工序名称" prop="process_name"><el-input v-model="dialog.process_name" placeholder="请输入工序名称" /></el-form-item>
            <el-form-item label="工序组" prop="process_group">
              <el-select v-model="dialog.process_group" filterable allow-create placeholder="选择或输入工序组" style="width:100%">
                <el-option v-for="g in groupOptions" :key="g" :label="g" :value="g" />
              </el-select>
            </el-form-item>
            <el-form-item label="适用产品类型">
              <el-select v-model="dialog.product_type" filterable allow-create placeholder="选择或输入产品类型" style="width:100%">
                <el-option v-for="t in ['油缸', '立柱', '减速器', '液压支架', '通用']" :key="t" :label="t" :value="t" />
              </el-select>
            </el-form-item>
            <el-form-item label="工序顺序"><el-input-number v-model="dialog.sort_order" :min="0" style="width:100%" /></el-form-item>
            <el-form-item label="是否必须工序"><el-switch v-model="dialog.is_required" :active-value="1" :inactive-value="0" /></el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="工分定额" prop="standard_score"><el-input-number v-model="dialog.standard_score" :min="0" :precision="2" style="width:100%" placeholder="请输入标准工分数" /></el-form-item>
            <el-form-item label="标准工时（小时）"><el-input-number v-model="dialog.standard_hours" :min="0" :precision="2" style="width:100%" placeholder="请输入标准工时" /></el-form-item>
            <el-form-item label="工序描述"><el-input v-model="dialog.description" type="textarea" :rows="3" placeholder="请输入工序描述" /></el-form-item>
            <el-form-item label="状态"><el-switch v-model="dialog.status" :active-value="1" :inactive-value="0" /></el-form-item>
            <el-form-item label="备注"><el-input v-model="dialog.remark" type="textarea" :rows="2" /></el-form-item>
          </el-col>
        </el-row>
      </el-form>
      <div slot="footer">
        <el-button size="small" @click="dialogVisible = false">取消</el-button>
        <el-button size="small" type="primary" :loading="saving" @click="handleSave">保存</el-button>
      </div>
    </el-dialog>

    <!-- 管理工位对话框（工序可用工位） -->
    <el-dialog :title="`关联工位 - ${currentProc.process_name || ''}`" :visible.sync="wsRelVisible" width="700px" append-to-body>
      <el-table :data="wsRelList" size="small" border>
        <el-table-column type="index" label="#" width="50" align="center" />
        <el-table-column prop="workstation_code" label="工位编码" width="110" />
        <el-table-column prop="workstation_name" label="工位名称" min-width="110" />
        <el-table-column prop="workstation_type_label" label="工位类型" width="100" />
        <el-table-column label="当前状态" width="90" align="center">
          <template slot-scope="s"><el-tag :type="s.row.current_status_tag" size="mini">{{ s.row.current_status_label }}</el-tag></template>
        </el-table-column>
        <el-table-column label="是否默认" width="80" align="center">
          <template slot-scope="s"><el-tag v-if="s.row.is_default === 1" type="warning" size="mini">默认</el-tag></template>
        </el-table-column>
        <el-table-column label="操作" width="170" align="center">
          <template slot-scope="s">
            <el-button v-if="s.row.is_default !== 1" type="text" size="mini" @click="handleSetWsDefault(s.row)">设默认</el-button>
            <el-button type="text" size="mini" class="danger-text" @click="handleDetachWsRel(s.row)">移除</el-button>
          </template>
        </el-table-column>
      </el-table>
      <div class="manage-add">
        <el-select v-model="newWsIds" multiple filterable placeholder="选择工位（可多选）" style="width:70%">
          <el-option v-for="w in workstationOptions" :key="w.id" :label="`${w.workstation_code} - ${w.workstation_name} - ${w.workstation_type_label}`" :value="w.id" />
        </el-select>
        <el-button size="small" type="primary" @click="handleAttachWs">添加</el-button>
      </div>
      <div class="manage-count">共 {{ wsRelList.length }} 个工位</div>
    </el-dialog>
  </div>
</template>

<script>
import { getProcessList, getProcessGroups, saveProcess, deleteProcess, toggleProcess, getWorkstationList, getProcessWorkstations, attachWsToProcess, detachProcessWs, setProcessWsDefault } from '@/api/production'

export default {
  name: 'ProductionProcess',
  data () {
    return {
      query: { process_name: '', process_code: '', process_group: '', status: '' },
      groupOptions: [], list: [], total: 0, page: 1, pageSize: 10, loading: false, saving: false,
      dialogVisible: false,
      dialog: this.emptyDialog(),
      wsRelVisible: false, wsRelList: [], workstationOptions: [], newWsIds: [], currentProc: {},
      rules: {
        process_code: [{ required: true, message: '请输入工序编码' }],
        process_name: [{ required: true, message: '请输入工序名称' }],
        process_group: [{ required: true, message: '请输入工序组' }],
        standard_score: [{ required: true, message: '请输入工分定额' }]
      }
    }
  },
  created () { this.loadGroups(); this.loadWorkstationOptions(); this.loadData() },
  methods: {
    emptyDialog () {
      return { id: 0, process_code: '', process_name: '', process_group: '', product_type: '', sort_order: 0, is_required: 1, standard_score: 0, standard_hours: 0, description: '', status: 1, remark: '' }
    },
    async loadGroups () {
      try { const r = await getProcessGroups(); if (r.code === 0) this.groupOptions = r.data.list || [] } catch (e) { this.groupOptions = [] }
    },
    async loadWorkstationOptions () { try { const r = await getWorkstationList({ page: 1, pageSize: 200, status: 1 }); if (r.code === 0) this.workstationOptions = r.data.list || [] } catch (e) { this.workstationOptions = [] } },
    buildParams () {
      const p = { page: this.page, pageSize: this.pageSize }
      if (this.query.process_name) p.process_name = this.query.process_name
      if (this.query.process_code) p.process_code = this.query.process_code
      if (this.query.process_group) p.process_group = this.query.process_group
      if (this.query.status !== '' && this.query.status !== null) p.status = this.query.status
      return p
    },
    async loadData () {
      this.loading = true
      try {
        const r = await getProcessList(this.buildParams())
        if (r.code === 0 && r.data) { this.list = r.data.list || []; this.total = r.data.total || 0 }
      } catch (e) {} finally { this.loading = false }
    },
    handleSearch () { this.page = 1; this.loadData() },
    handleReset () { this.query = { process_name: '', process_code: '', process_group: '', status: '' }; this.handleSearch() },
    handlePageChange (p) { this.page = p; this.loadData() },
    handleSizeChange (s) { this.pageSize = s; this.page = 1; this.loadData() },
    openDialog (row) {
      this.dialog = row ? { ...row } : this.emptyDialog()
      this.dialogVisible = true
    },
    handleSave () {
      this.$refs.form.validate(async (valid) => {
        if (!valid) return
        this.saving = true
        try {
          const r = await saveProcess(this.dialog)
          if (r.code === 0) { this.$message.success('保存成功'); this.dialogVisible = false; this.loadData(); this.loadGroups() } else this.$message.error(r.msg || '保存失败')
        } catch (e) {} finally { this.saving = false }
      })
    },
    handleDelete (row) {
      this.$confirm('确认删除该工序吗？删除后不可恢复', '删除工序', { type: 'warning' }).then(async () => {
        try { const r = await deleteProcess(row.id); if (r.code === 0) { this.$message.success('删除成功'); this.loadData(); this.loadGroups() } else this.$message.error(r.msg || '删除失败') } catch (e) {}
      }).catch(() => {})
    },
    async handleToggle (row) {
      try { const r = await toggleProcess(row.id); if (r.code === 0) { this.$message.success(r.msg); this.loadData() } else this.$message.error(r.msg || '操作失败') } catch (e) {}
    },
    // 关联工位（工序可用工位）
    async openWsRel (row) {
      this.currentProc = row
      this.newWsIds = []
      this.wsRelVisible = true
      await this.refreshWsRel(row.id)
    },
    async refreshWsRel (id) {
      try { const r = await getProcessWorkstations(id); if (r.code === 0) this.wsRelList = r.data.list || [] } catch (e) { this.wsRelList = [] }
    },
    async handleAttachWs () {
      if (!this.newWsIds.length) { this.$message.warning('请选择工位'); return }
      try {
        const r = await attachWsToProcess({ process_id: this.currentProc.id, workstation_ids: this.newWsIds })
        if (r.code === 0) { this.$message.success('关联成功'); this.newWsIds = []; await this.refreshWsRel(this.currentProc.id); this.loadData() } else this.$message.error(r.msg || '关联失败')
      } catch (e) {}
    },
    async handleDetachWsRel (row) {
      this.$confirm('确认移除该工位关联吗？移除后该工序将不能在此工位完成', '移除关联', { type: 'warning' }).then(async () => {
        try { const r = await detachProcessWs(row.rel_id); if (r.code === 0) { this.$message.success('已移除'); await this.refreshWsRel(this.currentProc.id); this.loadData() } else this.$message.error(r.msg || '移除失败') } catch (e) {}
      }).catch(() => {})
    },
    async handleSetWsDefault (row) {
      try { const r = await setProcessWsDefault({ id: row.rel_id }); if (r.code === 0) { this.$message.success('已设为默认'); await this.refreshWsRel(this.currentProc.id) } else this.$message.error(r.msg || '操作失败') } catch (e) {}
    }
  }
}
</script>

<style scoped>
.wh-page { padding: 16px; }
.breadcrumb { margin-bottom: 12px; }
.search-bar { background: #fff; padding: 16px 20px 4px; border-bottom: 1px solid #ebeef5; border-radius: 8px 8px 0 0; }
.toolbar { display: flex; justify-content: space-between; align-items: center; padding: 12px 20px; background: #fff; border-bottom: 1px solid #ebeef5; }
.toolbar-left { display: flex; gap: 10px; }
.total-text { color: #909399; font-size: 14px; }
.link-blue { color: #409EFF; cursor: pointer; }
.danger-text { color: #F56C6C; }
.manage-add { display: flex; gap: 10px; margin-top: 12px; }
.manage-count { margin-top: 8px; font-size: 13px; color: #909399; }
.pager { margin-top: 20px; margin-bottom: 20px; text-align: right; }
</style>
