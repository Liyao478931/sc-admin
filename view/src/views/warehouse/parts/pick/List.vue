<!--
  文件：admin/src/views/warehouse/parts/pick/List.vue
  功能：配件领用列表（审核流/确认发料/撤销/版本历史/导出）
  权限：warehouse:pick:view/add/edit/delete/audit/confirm/export/version:view/version:restore
-->
<template>
  <div class="wh-page">
    <el-breadcrumb separator="/" class="breadcrumb">
      <el-breadcrumb-item>仓储管理</el-breadcrumb-item>
      <el-breadcrumb-item>配件出入库</el-breadcrumb-item>
      <el-breadcrumb-item>配件领用</el-breadcrumb-item>
    </el-breadcrumb>

    <div class="search-bar">
      <el-form inline size="small" label-width="90px" @submit.native.prevent>
        <el-form-item label="领料单编号"><el-input v-model="q.pick_no" placeholder="请输入领料单编号" clearable style="width:160px" @keyup.enter.native="handleSearch" /></el-form-item>
        <el-form-item label="关联工单"><el-input v-model="q.work_order_no" placeholder="请输入关联工单编号" clearable style="width:150px" @keyup.enter.native="handleSearch" /></el-form-item>
        <el-form-item label="领料部门">
          <el-select v-model="q.department_id" clearable filterable placeholder="全部" style="width:150px">
            <el-option v-for="d in deptOptions" :key="d.id" :label="d.label" :value="d.id" />
          </el-select>
        </el-form-item>
        <el-form-item label="领料类型">
          <el-select v-model="q.pick_type" clearable placeholder="全部" style="width:110px">
            <el-option v-for="(t, v) in PICK_TYPES" :key="v" :label="t" :value="Number(v)" />
          </el-select>
        </el-form-item>
        <el-form-item label="状态">
          <el-select v-model="q.status" clearable placeholder="全部" style="width:100px">
            <el-option v-for="(t, v) in STATUS_TYPES" :key="v" :label="t" :value="Number(v)" />
          </el-select>
        </el-form-item>
        <el-form-item label="领料日期">
          <el-date-picker v-model="dateRange" type="daterange" range-separator="至" start-placeholder="开始" end-placeholder="结束" value-format="yyyy-MM-dd" style="width:220px" />
        </el-form-item>
        <el-form-item>
          <el-button type="primary" icon="el-icon-search" @click="handleSearch">搜索</el-button>
          <el-button icon="el-icon-refresh-left" @click="handleReset">重置</el-button>
        </el-form-item>
      </el-form>
    </div>

    <div class="toolbar">
      <div class="toolbar-left">
        <el-button v-permission="'warehouse:pick:add'" type="primary" size="small" icon="el-icon-plus" @click="$router.push('/warehouse/parts/pick/add')">新增领料单</el-button>
        <el-button v-permission="'warehouse:pick:export'" size="small" icon="el-icon-download" :loading="exporting" @click="handleExport">导出</el-button>
        <el-button size="small" icon="el-icon-refresh" :loading="loading" @click="getList">刷新</el-button>
      </div>
      <span class="total-text">共 {{ total }} 条</span>
    </div>

    <el-table :data="list" v-loading="loading" size="small" border stripe empty-text="暂无领料单数据">
      <el-table-column type="index" label="#" width="55" align="center" />
      <el-table-column label="领料单编号" width="170">
        <template slot-scope="s">
          <span class="link" @click="goDetail(s.row)">{{ s.row.pick_no }}</span>
          <el-tooltip :content="'当前版本：' + s.row.version_no + '，共 ' + s.row.version_history_count + ' 个历史版本'" placement="top">
            <span class="version-tag">{{ s.row.version_no }}</span>
          </el-tooltip>
        </template>
      </el-table-column>
      <el-table-column label="领料类型" width="100" align="center">
        <template slot-scope="s"><el-tag :type="s.row.pick_type_tag" size="mini">{{ s.row.pick_type_label }}</el-tag></template>
      </el-table-column>
      <el-table-column label="关联工单" width="140">
        <template slot-scope="s"><span class="link" @click="goWorkOrder(s.row)">{{ s.row.work_order_no || '-' }}</span></template>
      </el-table-column>
      <el-table-column prop="department_name" label="领料部门" width="120" show-overflow-tooltip />
      <el-table-column prop="picker_name" label="领料人" width="90" />
      <el-table-column prop="pick_date" label="领料日期" width="110" />
      <el-table-column prop="item_count" label="种类数" width="70" align="center" />
      <el-table-column prop="total_quantity" label="总数量" width="80" align="right" />
      <el-table-column label="状态" width="90" align="center">
        <template slot-scope="s"><el-tag :type="s.row.status_tag" size="mini">{{ s.row.status_label }}</el-tag></template>
      </el-table-column>
      <el-table-column label="操作" width="230" align="center" fixed="right">
        <template slot-scope="s">
          <el-button type="text" size="mini" @click="goDetail(s.row)">详情</el-button>
          <el-button v-if="s.row.status === 0 || s.row.status === 4" v-permission="'warehouse:pick:edit'" type="text" size="mini" @click="$router.push('/warehouse/parts/pick/edit/' + s.row.id)">编辑</el-button>
          <el-button v-if="s.row.status === 0 || s.row.status === 4" v-permission="'warehouse:pick:delete'" type="text" size="mini" class="danger" @click="handleDelete(s.row)">删除</el-button>
          <el-dropdown trigger="click" @command="cmd => handleMore(cmd, s.row)">
            <el-button type="text" size="mini">更多<i class="el-icon-arrow-down el-icon--right"></i></el-button>
            <el-dropdown-menu slot="dropdown">
              <el-dropdown-item v-if="s.row.status === 0" command="submit">提交审核</el-dropdown-item>
              <el-dropdown-item v-if="s.row.status === 1" v-permission="'warehouse:pick:audit'" command="approve">审核通过</el-dropdown-item>
              <el-dropdown-item v-if="s.row.status === 1" v-permission="'warehouse:pick:audit'" command="reject">审核驳回</el-dropdown-item>
              <el-dropdown-item v-if="s.row.status === 2" v-permission="'warehouse:pick:confirm'" command="confirm">确认发料</el-dropdown-item>
              <el-dropdown-item v-if="s.row.status === 0 || s.row.status === 1" command="cancel">撤销申请</el-dropdown-item>
              <el-dropdown-item command="version">版本历史</el-dropdown-item>
            </el-dropdown-menu>
          </el-dropdown>
        </template>
      </el-table-column>
    </el-table>

    <el-pagination class="pager" background layout="total, sizes, prev, pager, next, jumper"
      :total="total" :current-page="page" :page-size="pageSize" :page-sizes="[10, 20, 50, 100]"
      @current-change="p => { page = p; getList() }" @size-change="s => { pageSize = s; page = 1; getList() }" />

    <!-- 审核弹窗 -->
    <el-dialog title="审核通过" :visible="auditVisible" @update:visible="v => auditVisible = v" width="460px" top="8vh">
      <el-input v-model="auditRemark" type="textarea" :rows="3" placeholder="审核备注（可选）" />
      <span slot="footer">
        <el-button size="small" @click="auditVisible = false">取消</el-button>
        <el-button size="small" type="primary" :loading="acting" @click="doApprove">确认通过</el-button>
      </span>
    </el-dialog>
    <el-dialog title="审核驳回" :visible="rejectVisible" @update:visible="v => rejectVisible = v" width="460px" top="8vh">
      <el-input v-model="rejectReason" type="textarea" :rows="3" placeholder="请填写驳回原因（必填）" />
      <span slot="footer">
        <el-button size="small" @click="rejectVisible = false">取消</el-button>
        <el-button size="small" type="danger" :loading="acting" @click="doReject">确认驳回</el-button>
      </span>
    </el-dialog>

    <!-- 版本历史弹窗 -->
    <el-dialog :title="'版本历史 - ' + (currentRow ? currentRow.pick_no : '')" :visible="verVisible" @update:visible="v => verVisible = v" width="760px" top="6vh">
      <el-table :data="versions" size="small" border :row-class-name="rowCls">
        <el-table-column prop="version_no" label="版本号" width="110" align="center" />
        <el-table-column prop="change_summary" label="变更摘要" min-width="180" />
        <el-table-column prop="operator_name" label="操作人" width="100" />
        <el-table-column prop="create_time" label="修改时间" width="160" />
        <el-table-column label="操作" width="160" align="center">
          <template slot-scope="s">
            <el-button type="text" size="mini" @click="viewVersion(s.row)">查看详情</el-button>
            <el-button v-permission="'warehouse:pick:version:restore'" v-if="!s.row.is_current" type="text" size="mini" class="danger" @click="doRestore(s.row)">恢复</el-button>
          </template>
        </el-table-column>
      </el-table>
    </el-dialog>
  </div>
</template>

<script>
import { getPickList, deletePick, submitPick, approvePick, rejectPick, confirmPick, cancelPick, getPickVersions, getPickVersionDetail, restorePickVersion, exportPick } from '../../../../api/warehouse'
import { getDepartmentTree } from '../../../../api/user'

const PICK_TYPES = { 1: '生产领料', 2: '维修领料', 3: '研发领料', 4: '其他领料' }
const STATUS_TYPES = { 0: '草稿', 1: '待审核', 2: '已审核', 3: '已领料', 4: '已驳回', 5: '已撤销' }

export default {
  name: 'WarehousePickList',
  data () {
    return {
      PICK_TYPES, STATUS_TYPES,
      list: [], total: 0, page: 1, pageSize: 10, loading: false, exporting: false,
      q: { pick_no: '', work_order_no: '', department_id: '', pick_type: '', status: '' },
      dateRange: null, deptOptions: [],
      auditVisible: false, rejectVisible: false, auditRemark: '', rejectReason: '', acting: false, currentRow: null,
      verVisible: false, versions: []
    }
  },
  created () { this.getList(); this.loadDepts() },
  methods: {
    async loadDepts () {
      try {
        const r = await getDepartmentTree()
        const flat = []
        const walk = nodes => nodes.forEach(n => { flat.push({ id: n.id, label: n.name }); if (n.children) walk(n.children) })
        if (r.code === 0 && r.data) walk(Array.isArray(r.data) ? r.data : [])
        this.deptOptions = flat
      } catch (e) { this.deptOptions = [] }
    },
    buildParams () {
      const p = { page: this.page, pageSize: this.pageSize }
      Object.keys(this.q).forEach(k => { if (this.q[k] !== '' && this.q[k] !== null) p[k] = this.q[k] })
      if (this.dateRange && this.dateRange.length === 2) { p.start_date = this.dateRange[0]; p.end_date = this.dateRange[1] }
      return p
    },
    async getList () {
      this.loading = true
      try {
        const r = await getPickList(this.buildParams())
        if (r.code === 0 && r.data) { this.list = r.data.list || []; this.total = r.data.total || 0 }
      } catch (e) {} finally { this.loading = false }
    },
    handleSearch () { this.page = 1; this.getList() },
    handleReset () { this.q = { pick_no: '', work_order_no: '', department_id: '', pick_type: '', status: '' }; this.dateRange = null; this.handleSearch() },
    goDetail (row) { this.$router.push('/warehouse/parts/pick/detail/' + row.id) },
    goWorkOrder (row) { if (row.production_order_id) this.$router.push('/business/order/detail/' + row.production_order_id) },
    handleDelete (row) {
      this.$confirm('确认删除该领料单吗？删除后不可恢复', '提示', { type: 'warning' }).then(async () => {
        try {
          const r = await deletePick(row.id)
          if (r.code === 0) { this.$message.success('删除成功'); this.getList() } else this.$message.error(r.msg || '删除失败')
        } catch (e) {}
      }).catch(() => {})
    },
    handleMore (cmd, row) {
      this.currentRow = row
      if (cmd === 'submit') {
        this.$confirm('提交后不可再编辑，确认提交审核吗？', '提示').then(() => this.doAction(submitPick(row.id), '已提交审核')).catch(() => {})
      } else if (cmd === 'approve') {
        this.auditRemark = ''; this.auditVisible = true
      } else if (cmd === 'reject') {
        this.rejectReason = ''; this.rejectVisible = true
      } else if (cmd === 'confirm') {
        this.$confirm('确认发料将扣减库存并生成流水，确认继续吗？', '确认发料', { type: 'warning' }).then(() => this.doConfirm()).catch(() => {})
      } else if (cmd === 'cancel') {
        this.$confirm('确认撤销该领料申请吗？', '提示').then(() => this.doAction(cancelPick(row.id), '已撤销')).catch(() => {})
      } else if (cmd === 'version') {
        this.openVersions()
      }
    },
    async doAction (promise, msg) {
      this.acting = true
      try {
        const r = await promise
        if (r.code === 0) { this.$message.success(msg); this.getList() } else this.$message.error(r.msg || '操作失败')
      } catch (e) {} finally { this.acting = false }
    },
    doApprove () {
      this.$confirm('确认审核通过该领料单吗？', '提示').then(() => this.doAction(approvePick(this.currentRow.id, this.auditRemark), '审核通过')).catch(() => {})
        .finally(() => { this.auditVisible = false })
    },
    doReject () {
      if (!this.rejectReason.trim()) { this.$message.warning('请填写驳回原因'); return }
      this.$confirm('确认驳回该领料单吗？', '提示', { type: 'warning' }).then(() => this.doAction(rejectPick(this.currentRow.id, this.rejectReason), '已驳回')).catch(() => {})
        .finally(() => { this.rejectVisible = false })
    },
    async doConfirm () {
      this.$message({ message: '正在处理发料，请稍候...', type: 'info', duration: 0 })
      try {
        const r = await confirmPick(this.currentRow.id)
        this.$message.closeAll()
        if (r.code === 0) { this.$message.success(r.msg || '发料成功'); this.getList() } else this.$message.error(r.msg || '发料失败')
      } catch (e) { this.$message.closeAll() }
    },
    async openVersions () {
      try {
        const r = await getPickVersions(this.currentRow.id)
        if (r.code === 0 && r.data) { this.versions = r.data.list || []; this.verVisible = true } else this.$message.error(r.msg || '加载失败')
      } catch (e) {}
    },
    rowCls ({ row }) { return row.is_current ? 'current-version' : '' },
    async viewVersion (v) {
      try {
        const r = await getPickVersionDetail(this.currentRow.id, v.version_no)
        if (r.code === 0 && r.data && r.data.snapshot) {
          const s = r.data.snapshot
          this.$alert(`版本 ${v.version_no}\n领料类型：${PICK_TYPES[s.pick.pick_type] || ''} 领料人：${s.pick.picker_name}\n明细 ${(s.items || []).length} 项：\n` + (s.items || []).map(it => `${it.material_name} × ${it.apply_quantity}`).join('\n'), '版本详情（只读）')
        }
      } catch (e) {}
    },
    doRestore (v) {
      this.$confirm(`确认恢复到 ${v.version_no} 吗？当前数据将被覆盖`, '提示', { type: 'warning' }).then(async () => {
        try {
          const r = await restorePickVersion(this.currentRow.id, v.version_no)
          if (r.code === 0) { this.$message.success(r.msg || '已恢复'); this.openVersions(); this.getList() } else this.$message.error(r.msg || '恢复失败')
        } catch (e) {}
      }).catch(() => {})
    },
    async handleExport () {
      this.exporting = true
      try {
        const resp = await exportPick(this.buildParams())
        const url = window.URL.createObjectURL(new Blob([resp.data]))
        const a = document.createElement('a')
        a.href = url; a.download = '配件领用_' + new Date().toISOString().slice(0, 10) + '.xlsx'
        a.click(); window.URL.revokeObjectURL(url)
      } catch (e) { this.$message.error('导出失败') } finally { this.exporting = false }
    }
  }
}
</script>

<style scoped>
.wh-page { padding: 16px; }
.breadcrumb { margin-bottom: 12px; }
.search-bar { background: #fff; padding: 16px 20px 0; border-bottom: 1px solid #ebeef5; border-radius: 8px 8px 0 0; }
.toolbar { display: flex; justify-content: space-between; align-items: center; padding: 12px 20px; background: #fff; border-bottom: 1px solid #ebeef5; }
.toolbar-left { display: flex; gap: 10px; }
.total-text { color: #909399; font-size: 14px; }
.pager { margin-top: 20px; margin-bottom: 20px; text-align: right; }
.danger { color: #F56C6C; }
.link { color: #409EFF; cursor: pointer; }
.version-tag { background: #f0f9eb; color: #67C23A; border-radius: 4px; padding: 1px 6px; font-size: 12px; margin-left: 6px; }
/deep/ .current-version { background: #f0f9eb; }
</style>
