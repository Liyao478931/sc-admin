<!--
  文件：admin/src/views/production/setting/workstation/Index.vue
  功能：工位管理（定义工位 + 关联设备 1:N + 关联员工 M:N）
  权限：production:workstation:view/add/edit/delete/device:manage/staff:manage
-->
<template>
  <div class="wh-page">
    <el-breadcrumb separator="/" class="breadcrumb">
      <el-breadcrumb-item>生产管理</el-breadcrumb-item>
      <el-breadcrumb-item>基础设置</el-breadcrumb-item>
      <el-breadcrumb-item>工位管理</el-breadcrumb-item>
    </el-breadcrumb>

    <div class="search-bar">
      <el-form inline size="small" label-width="80px" @submit.native.prevent>
        <el-form-item label="工位名称"><el-input v-model="query.workstation_name" placeholder="请输入工位名称" clearable style="width:150px" @keyup.enter.native="handleSearch" /></el-form-item>
        <el-form-item label="工位编码"><el-input v-model="query.workstation_code" placeholder="请输入工位编码" clearable style="width:150px" @keyup.enter.native="handleSearch" /></el-form-item>
        <el-form-item label="工位类型">
          <el-select v-model="query.workstation_type" clearable placeholder="全部" style="width:130px">
            <el-option v-for="(t, v) in typeOptions" :key="v" :label="t" :value="Number(v)" />
          </el-select>
        </el-form-item>
        <el-form-item label="占用状态">
          <el-select v-model="query.current_status" clearable placeholder="全部" style="width:110px">
            <el-option label="空闲" :value="0" />
            <el-option label="占用中" :value="1" />
            <el-option label="维护中" :value="2" />
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
        <el-button v-permission="'production:workstation:add'" type="primary" size="small" icon="el-icon-plus" @click="openDialog()">新增工位</el-button>
        <el-button size="small" icon="el-icon-refresh" :loading="loading" @click="loadData">刷新</el-button>
      </div>
      <span class="total-text">共 {{ total }} 个</span>
    </div>

    <el-table :data="list" v-loading="loading" size="small" border stripe>
      <el-table-column type="index" label="#" width="55" align="center" />
      <el-table-column prop="workstation_code" label="工位编码" width="110" />
      <el-table-column prop="workstation_name" label="工位名称" min-width="120" />
      <el-table-column label="工位类型" width="100" align="center">
        <template slot-scope="s"><el-tag :type="s.row.workstation_type_tag" size="mini">{{ s.row.workstation_type_label }}</el-tag></template>
      </el-table-column>
      <el-table-column label="关联设备" min-width="140" show-overflow-tooltip><template slot-scope="s">{{ s.row.device_names || '-' }}</template></el-table-column>
      <el-table-column label="关联员工" min-width="140" show-overflow-tooltip><template slot-scope="s">{{ s.row.staff_names || '-' }}</template></el-table-column>
      <el-table-column label="可做工序数" width="100" align="center">
        <template slot-scope="s"><span class="link-blue" @click="openProcessRel(s.row)">{{ s.row.process_count || 0 }} 道工序</span></template>
      </el-table-column>
      <el-table-column prop="workshop" label="所属车间" width="90" show-overflow-tooltip />
      <el-table-column prop="responsible_person_name" label="负责人" width="80" />
      <el-table-column label="占用状态" width="90" align="center">
        <template slot-scope="s"><el-tag :type="s.row.current_status_tag" size="mini">{{ s.row.current_status_label }}</el-tag></template>
      </el-table-column>
      <el-table-column label="状态" width="80" align="center">
        <template slot-scope="s"><el-tag :type="s.row.status_tag" size="mini">{{ s.row.status_label }}</el-tag></template>
      </el-table-column>
      <el-table-column label="操作" width="250" align="center" fixed="right">
        <template slot-scope="s">
          <el-button v-permission="'production:workstation:edit'" type="text" size="mini" @click="openDialog(s.row)">编辑</el-button>
          <el-button v-permission="'production:workstation:delete'" type="text" size="mini" class="danger-text" @click="handleDelete(s.row)">删除</el-button>
          <el-button v-permission="'production:workstation:edit'" type="text" size="mini" @click="handleToggle(s.row)">{{ s.row.status === 1 ? '停用' : '启用' }}</el-button>
          <el-button v-permission="'production:workstation:device:manage'" type="text" size="mini" @click="openDevices(s.row)">管理设备</el-button>
          <el-button v-permission="'production:workstation:staff:manage'" type="text" size="mini" @click="openStaff(s.row)">管理员工</el-button>
          <el-button v-permission="'production:workstation:edit'" type="text" size="mini" @click="openProcessRel(s.row)">关联工序</el-button>
        </template>
      </el-table-column>
    </el-table>

    <el-pagination class="pager" background layout="total, sizes, prev, pager, next, jumper"
      :total="total" :current-page="page" :page-size="pageSize" :page-sizes="[10, 20, 50, 100]"
      @current-change="handlePageChange" @size-change="handleSizeChange" />

    <!-- 新增/编辑工位对话框 -->
    <el-dialog :title="dialog.id ? '编辑工位' : '新增工位'" :visible.sync="dialogVisible" width="700px" append-to-body>
      <el-form ref="wsForm" :model="dialog" :rules="wsRules" label-width="120px" size="small">
        <el-row :gutter="16">
          <el-col :span="12">
            <el-form-item label="工位编码" prop="workstation_code"><el-input v-model="dialog.workstation_code" placeholder="请输入工位编码，如 WS-001" /></el-form-item>
            <el-form-item label="工位名称" prop="workstation_name"><el-input v-model="dialog.workstation_name" placeholder="请输入工位名称" /></el-form-item>
            <el-form-item label="工位类型" prop="workstation_type">
              <el-select v-model="dialog.workstation_type" style="width:100%">
                <el-option v-for="(t, v) in typeOptions" :key="v" :label="t" :value="Number(v)" />
              </el-select>
            </el-form-item>
            <el-form-item label="所属车间"><el-input v-model="dialog.workshop" placeholder="请输入所属车间名称" /></el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="负责人">
              <el-select v-model="dialog.responsible_person_id" filterable clearable placeholder="请选择负责人" style="width:100%">
                <el-option v-for="u in userOptions" :key="u.id" :label="u.real_name || u.username" :value="u.id" />
              </el-select>
            </el-form-item>
            <el-form-item label="状态"><el-switch v-model="dialog.status" :active-value="1" :inactive-value="0" /></el-form-item>
            <el-form-item label="备注"><el-input v-model="dialog.remark" type="textarea" :rows="4" /></el-form-item>
          </el-col>
        </el-row>
      </el-form>
      <div slot="footer">
        <el-button size="small" @click="dialogVisible = false">取消</el-button>
        <el-button size="small" type="primary" :loading="saving" @click="handleSave">保存</el-button>
      </div>
    </el-dialog>

    <!-- 管理设备对话框 -->
    <el-dialog :title="`管理设备 - ${currentWs.workstation_name || ''}`" :visible.sync="deviceVisible" width="700px" append-to-body>
      <el-table :data="deviceList" size="small" border>
        <el-table-column type="index" label="#" width="50" align="center" />
        <el-table-column prop="device_code" label="设备编码" width="140" />
        <el-table-column prop="device_name" label="设备名称" min-width="150" />
        <el-table-column prop="device_spec" label="规格型号" width="140" show-overflow-tooltip />
        <el-table-column label="主设备" width="80" align="center">
          <template slot-scope="s"><el-tag v-if="s.row.is_primary === 1" type="warning" size="mini">主设备</el-tag></template>
        </el-table-column>
        <el-table-column label="操作" width="160" align="center">
          <template slot-scope="s">
            <el-button v-if="s.row.is_primary !== 1" type="text" size="mini" @click="handleSetPrimary(s.row)">设为主设备</el-button>
            <el-button type="text" size="mini" class="danger-text" @click="handleDetachDevice(s.row)">移除</el-button>
          </template>
        </el-table-column>
      </el-table>
      <div class="manage-add">
        <el-select v-model="newDeviceIds" multiple filterable placeholder="选择设备（可多选）" style="width:70%">
          <el-option v-for="d in deviceOptions" :key="d.id" :label="`${d.device_code} - ${d.name} - ${d.specification || d.model || ''}`" :value="d.id" />
        </el-select>
        <el-button size="small" type="primary" @click="handleAttachDevices">添加</el-button>
      </div>
      <div class="manage-count">共 {{ deviceList.length }} 台设备</div>
    </el-dialog>

    <!-- 管理员工对话框 -->
    <el-dialog :title="`管理员工 - ${currentWs.workstation_name || ''}`" :visible.sync="staffVisible" width="700px" append-to-body>
      <el-table :data="staffList" size="small" border>
        <el-table-column type="index" label="#" width="50" align="center" />
        <el-table-column prop="user_name" label="员工姓名" width="100" />
        <el-table-column prop="employee_id" label="工号" width="100" />
        <el-table-column prop="position" label="岗位" width="110" show-overflow-tooltip />
        <el-table-column label="角色类型" width="130">
          <template slot-scope="s">
            <el-select v-model="s.row.role_type" size="mini" @change="(v) => handleSetRole(s.row, v)">
              <el-option v-for="(t, r) in roleOptions" :key="r" :label="t" :value="Number(r)" />
            </el-select>
          </template>
        </el-table-column>
        <el-table-column label="操作" width="80" align="center">
          <template slot-scope="s"><el-button type="text" size="mini" class="danger-text" @click="handleDetachStaff(s.row)">移除</el-button></template>
        </el-table-column>
      </el-table>
      <div class="manage-add">
        <el-select v-model="newStaffIds" multiple filterable placeholder="选择员工（可多选）" style="width:70%">
          <el-option v-for="u in staffOptions" :key="u.id" :label="`${u.real_name || u.username} - ${u.employee_id || ''} - ${u.position || ''}`" :value="u.id" />
        </el-select>
        <el-button size="small" type="primary" @click="handleAttachStaff">添加</el-button>
      </div>
      <div class="manage-count">共 {{ staffList.length }} 名员工</div>
    </el-dialog>

    <!-- 管理工序对话框（工位可做工序） -->
    <el-dialog :title="`关联工序 - ${currentWs.workstation_name || ''}`" :visible.sync="processRelVisible" width="700px" append-to-body>
      <el-table :data="processRelList" size="small" border>
        <el-table-column type="index" label="#" width="50" align="center" />
        <el-table-column prop="process_code" label="工序编码" width="110" />
        <el-table-column prop="process_name" label="工序名称" min-width="110" />
        <el-table-column prop="process_group" label="工序组" width="110" show-overflow-tooltip />
        <el-table-column label="工分定额" width="90" align="right"><template slot-scope="s">{{ Number(s.row.standard_score) }} 分</template></el-table-column>
        <el-table-column label="是否默认" width="80" align="center">
          <template slot-scope="s"><el-tag v-if="s.row.is_default === 1" type="warning" size="mini">默认</el-tag></template>
        </el-table-column>
        <el-table-column label="操作" width="170" align="center">
          <template slot-scope="s">
            <el-button v-if="s.row.is_default !== 1" type="text" size="mini" @click="handleSetProcessDefault(s.row)">设默认</el-button>
            <el-button type="text" size="mini" class="danger-text" @click="handleDetachProcessRel(s.row)">移除</el-button>
          </template>
        </el-table-column>
      </el-table>
      <div class="manage-add">
        <el-select v-model="newProcessIds" multiple filterable placeholder="选择工序（可多选）" style="width:70%">
          <el-option v-for="p in processOptions" :key="p.id" :label="`${p.process_code} - ${p.process_name} - ${p.process_group}`" :value="p.id" />
        </el-select>
        <el-button size="small" type="primary" @click="handleAttachProcesses">添加</el-button>
      </div>
      <div class="manage-count">共 {{ processRelList.length }} 道工序</div>
    </el-dialog>
  </div>
</template>

<script>
import { getWorkstationList, saveWorkstation, deleteWorkstation, toggleWorkstation, getWsDeviceOptions, getWsDevices, attachWsDevices, detachWsDevice, setWsPrimary, getWsStaffOptions, getWsStaff, attachWsStaff, detachWsStaff, setWsRole, getOrderUsers, getProcessList, getWsProcesses, attachProcessToWs, detachProcessWs, setProcessWsDefault } from '@/api/production'

export default {
  name: 'ProductionWorkstation',
  data () {
    return {
      typeOptions: { 1: '拆解工位', 2: '清洗工位', 3: '检测工位', 4: '电镀工位', 5: '加工工位', 6: '组装工位', 7: '测试工位', 8: '喷漆工位', 9: '质检工位', 10: '其他' },
      roleOptions: { 1: '主操作员', 2: '副操作员', 3: '辅助人员' },
      query: { workstation_name: '', workstation_code: '', workstation_type: '', current_status: '' },
      list: [], total: 0, page: 1, pageSize: 10, loading: false, saving: false,
      userOptions: [],
      dialogVisible: false, dialog: this.emptyDialog(),
      wsRules: {
        workstation_code: [{ required: true, message: '请输入工位编码' }],
        workstation_name: [{ required: true, message: '请输入工位名称' }],
        workstation_type: [{ required: true, message: '请选择工位类型' }]
      },
      currentWs: {}, deviceVisible: false, deviceList: [], deviceOptions: [], newDeviceIds: [],
      staffVisible: false, staffList: [], staffOptions: [], newStaffIds: [],
      processRelVisible: false, processRelList: [], processOptions: [], newProcessIds: []
    }
  },
  created () { this.loadUsers(); this.loadDeviceOptions(); this.loadStaffOptions(); this.loadProcessOptions(); this.loadData() },
  methods: {
    emptyDialog () {
      return { id: 0, workstation_code: '', workstation_name: '', workstation_type: 1, workshop: '', responsible_person_id: null, status: 1, remark: '' }
    },
    async loadUsers () { try { const r = await getOrderUsers(); if (r.code === 0) this.userOptions = r.data.list || [] } catch (e) { this.userOptions = [] } },
    async loadDeviceOptions () { try { const r = await getWsDeviceOptions(); if (r.code === 0) this.deviceOptions = r.data.list || [] } catch (e) { this.deviceOptions = [] } },
    async loadStaffOptions () { try { const r = await getWsStaffOptions(); if (r.code === 0) this.staffOptions = r.data.list || [] } catch (e) { this.staffOptions = [] } },
    async loadProcessOptions () { try { const r = await getProcessList({ page: 1, pageSize: 200, status: 1 }); if (r.code === 0) this.processOptions = r.data.list || [] } catch (e) { this.processOptions = [] } },
    buildParams () {
      const p = { page: this.page, pageSize: this.pageSize }
      if (this.query.workstation_name) p.workstation_name = this.query.workstation_name
      if (this.query.workstation_code) p.workstation_code = this.query.workstation_code
      if (this.query.workstation_type !== '' && this.query.workstation_type !== null) p.workstation_type = this.query.workstation_type
      if (this.query.current_status !== '' && this.query.current_status !== null) p.current_status = this.query.current_status
      return p
    },
    async loadData () {
      this.loading = true
      try {
        const r = await getWorkstationList(this.buildParams())
        if (r.code === 0 && r.data) { this.list = r.data.list || []; this.total = r.data.total || 0 }
      } catch (e) {} finally { this.loading = false }
    },
    handleSearch () { this.page = 1; this.loadData() },
    handleReset () { this.query = { workstation_name: '', workstation_code: '', workstation_type: '', current_status: '' }; this.handleSearch() },
    handlePageChange (p) { this.page = p; this.loadData() },
    handleSizeChange (s) { this.pageSize = s; this.page = 1; this.loadData() },
    openDialog (row) {
      this.dialog = row ? { ...row } : this.emptyDialog()
      this.dialogVisible = true
    },
    handleSave () {
      this.$refs.wsForm.validate(async (valid) => {
        if (!valid) return
        this.saving = true
        try {
          const r = await saveWorkstation(this.dialog)
          if (r.code === 0) { this.$message.success('保存成功'); this.dialogVisible = false; this.loadData() } else this.$message.error(r.msg || '保存失败')
        } catch (e) {} finally { this.saving = false }
      })
    },
    handleDelete (row) {
      this.$confirm('确认删除该工位吗？删除后不可恢复', '删除工位', { type: 'warning' }).then(async () => {
        try { const r = await deleteWorkstation(row.id); if (r.code === 0) { this.$message.success('删除成功'); this.loadData() } else this.$message.error(r.msg || '删除失败') } catch (e) {}
      }).catch(() => {})
    },
    async handleToggle (row) {
      try { const r = await toggleWorkstation(row.id); if (r.code === 0) { this.$message.success(r.msg); this.loadData() } else this.$message.error(r.msg || '操作失败') } catch (e) {}
    },
    // 管理设备
    async openDevices (row) {
      this.currentWs = row
      this.newDeviceIds = []
      this.deviceVisible = true
      await this.refreshDevices(row.id)
    },
    async refreshDevices (id) {
      try { const r = await getWsDevices(id); if (r.code === 0) this.deviceList = r.data.list || [] } catch (e) { this.deviceList = [] }
    },
    async handleAttachDevices () {
      if (!this.newDeviceIds.length) { this.$message.warning('请选择设备'); return }
      try {
        const r = await attachWsDevices({ workstation_id: this.currentWs.id, device_ids: this.newDeviceIds })
        if (r.code === 0) { this.$message.success('关联成功'); this.newDeviceIds = []; await this.refreshDevices(this.currentWs.id); this.loadData() } else this.$message.error(r.msg || '关联失败')
      } catch (e) {}
    },
    async handleDetachDevice (row) {
      try { const r = await detachWsDevice(row.id); if (r.code === 0) { this.$message.success('已移除'); await this.refreshDevices(this.currentWs.id); this.loadData() } else this.$message.error(r.msg || '移除失败') } catch (e) {}
    },
    async handleSetPrimary (row) {
      try { const r = await setWsPrimary({ id: row.id }); if (r.code === 0) { this.$message.success('已设为主设备'); await this.refreshDevices(this.currentWs.id) } else this.$message.error(r.msg || '操作失败') } catch (e) {}
    },
    // 管理员工
    async openStaff (row) {
      this.currentWs = row
      this.newStaffIds = []
      this.staffVisible = true
      await this.refreshStaff(row.id)
    },
    async refreshStaff (id) {
      try { const r = await getWsStaff(id); if (r.code === 0) this.staffList = r.data.list || [] } catch (e) { this.staffList = [] }
    },
    async handleAttachStaff () {
      if (!this.newStaffIds.length) { this.$message.warning('请选择员工'); return }
      try {
        const r = await attachWsStaff({ workstation_id: this.currentWs.id, user_ids: this.newStaffIds })
        if (r.code === 0) { this.$message.success('关联成功'); this.newStaffIds = []; await this.refreshStaff(this.currentWs.id); this.loadData() } else this.$message.error(r.msg || '关联失败')
      } catch (e) {}
    },
    async handleDetachStaff (row) {
      try { const r = await detachWsStaff(row.id); if (r.code === 0) { this.$message.success('已移除'); await this.refreshStaff(this.currentWs.id); this.loadData() } else this.$message.error(r.msg || '移除失败') } catch (e) {}
    },
    async handleSetRole (row, roleType) {
      try { const r = await setWsRole({ id: row.id, role_type: roleType }); if (r.code !== 0) this.$message.error(r.msg || '更新失败') } catch (e) {}
    },
    // 关联工序（工位可做工序）
    async openProcessRel (row) {
      this.currentWs = row
      this.newProcessIds = []
      this.processRelVisible = true
      await this.refreshProcessRel(row.id)
    },
    async refreshProcessRel (id) {
      try { const r = await getWsProcesses(id); if (r.code === 0) this.processRelList = r.data.list || [] } catch (e) { this.processRelList = [] }
    },
    async handleAttachProcesses () {
      if (!this.newProcessIds.length) { this.$message.warning('请选择工序'); return }
      try {
        const r = await attachProcessToWs({ workstation_id: this.currentWs.id, process_ids: this.newProcessIds })
        if (r.code === 0) { this.$message.success('关联成功'); this.newProcessIds = []; await this.refreshProcessRel(this.currentWs.id); this.loadData() } else this.$message.error(r.msg || '关联失败')
      } catch (e) {}
    },
    async handleDetachProcessRel (row) {
      this.$confirm('确认移除该工序关联吗？移除后该工位将不能做此工序', '移除关联', { type: 'warning' }).then(async () => {
        try { const r = await detachProcessWs(row.rel_id); if (r.code === 0) { this.$message.success('已移除'); await this.refreshProcessRel(this.currentWs.id); this.loadData() } else this.$message.error(r.msg || '移除失败') } catch (e) {}
      }).catch(() => {})
    },
    async handleSetProcessDefault (row) {
      try { const r = await setProcessWsDefault({ id: row.rel_id }); if (r.code === 0) { this.$message.success('已设为默认工序'); await this.refreshProcessRel(this.currentWs.id) } else this.$message.error(r.msg || '操作失败') } catch (e) {}
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
.danger-text { color: #F56C6C; }
.pager { margin-top: 20px; margin-bottom: 20px; text-align: right; }
.manage-add { display: flex; gap: 10px; margin-top: 12px; }
.manage-count { margin-top: 8px; font-size: 13px; color: #909399; }
</style>
