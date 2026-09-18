<template>
  <div class="database-page">
    <!-- 顶部标题行 -->
    <div class="page-header-row">
      <h2>数据库维护</h2>
      <span class="header-status">
        <el-tag :type="dbConnected?'success':'danger'" size="mini" effect="plain">{{ dbConnected?'数据库连接正常':'数据库连接异常' }}</el-tag>
        <span v-if="lastBackupTime" class="header-backup">最后备份：{{ lastBackupTime }}</span>
        <el-button v-if="hasPerm('database:tableNames')" size="mini" @click="showTableNameDialog=true">表名管理</el-button>
        <el-button v-if="hasPerm('database:backupSettings')" size="mini" @click="showBackupSettingsDialog=true">自动备份</el-button>
      </span>
    </div>

    <!-- 统计卡片 -->
    <div class="stat-cards">
      <div class="stat-card"><i class="el-icon-collection card-icon blue"></i><div><div class="stat-num">{{ stats.table_count }}<span class="stat-unit"> 张</span></div><div class="stat-label">数据表总数</div></div></div>
      <div class="stat-card"><i class="el-icon-document-copy card-icon green"></i><div><div class="stat-num">{{ fmtNum(stats.total_rows) }}<span class="stat-unit"> 行</span></div><div class="stat-label">总数据量</div></div></div>
      <div class="stat-card"><i class="el-icon-data-analysis card-icon orange"></i><div><div class="stat-num">{{ stats.total_size_format }}<span class="stat-unit"></span></div><div class="stat-label">总大小</div></div></div>
      <div class="stat-card"><i class="el-icon-time card-icon purple"></i><div><div class="stat-num">{{ lastBackupTime||'从未备份' }}</div><div class="stat-label">最后备份时间</div></div></div>
    </div>

    <!-- 操作工具栏 -->
    <div class="toolbar">
      <div class="toolbar-left">
        <el-button size="small" icon="el-icon-refresh" @click="loadData">刷新</el-button>
        <el-button v-if="hasPerm('database:backup')" size="small" type="primary" icon="el-icon-data-analysis" @click="showBackupDialog=true">备份数据库</el-button>
        <el-button v-if="hasPerm('database:optimize')" size="small" type="warning" icon="el-icon-check" :disabled="selectedSet.size===0" @click="batchOptimize">优化表</el-button>
        <el-button v-if="hasPerm('database:repair')" size="small" type="danger" icon="el-icon-warning" :disabled="selectedSet.size===0" @click="batchRepair">修复表</el-button>
        <el-button v-if="hasPerm('database:backups')" size="small" icon="el-icon-document" @click="showBackupListDialog=true">备份列表</el-button>
      </div>
      <div class="toolbar-right">
        <el-input v-model="searchQuery" size="small" placeholder="搜索表名或中文名称" prefix-icon="el-icon-search" style="width:220px" clearable />
      </div>
    </div>

    <!-- 数据表表格 -->
    <div class="table-wrapper">
        <el-table ref="table" :data="pageData" border stripe size="small" style="width:100%" @sort-change="onSort" @selection-change="onSelection" @row-click="showDetail">
        <el-table-column type="selection" width="40" />
        <el-table-column type="index" label="#" width="50" />
        <el-table-column prop="name" label="表名" min-width="150" sortable="custom">
          <template slot-scope="{row}">
            <span class="tb-name" :class="{ 'empty-tb': row.rows===0 }">
              <i v-if="row.fragmentation_rate>20" class="el-icon-warning-outline warn-dot" title="该表碎片率较高，建议优化"></i>
              <i v-else-if="isNew(row.create_time)" class="new-badge">新</i>
              {{ row.name }}
            </span>
          </template>
        </el-table-column>
        <el-table-column prop="cname" label="中文名称" width="140">
          <template slot-scope="{row}">{{ row.cname || autoName(row.name) }}</template>
        </el-table-column>
        <el-table-column prop="rows" label="数据量" width="100" sortable="custom" :formatter="r=>fmtNum(r.rows)" />
        <el-table-column prop="data_size" label="数据大小" width="100" sortable="custom" />
        <el-table-column prop="index_size" label="索引大小" width="100" sortable="custom" />
        <el-table-column prop="total_size" label="总大小" width="100" sortable="custom" />
        <el-table-column prop="create_time" label="创建时间" width="160" sortable="custom" />
        <el-table-column prop="update_time" label="更新时间" width="160" sortable="custom" />
        <el-table-column label="操作" width="240" fixed="right">
          <template slot-scope="{row}">
            <el-button size="mini" type="primary" @click.stop="showDetail(row)">详情</el-button>
            <el-button v-if="hasPerm('database:truncate')" size="mini" type="danger" @click.stop="confirmTruncate(row.name)">清空</el-button>
            <el-button v-if="hasPerm('database:drop')" size="mini" type="danger" @click.stop="confirmDrop(row.name)">删除</el-button>
          </template>
        </el-table-column>
      </el-table>
      <div class="table-footer">
        <span style="color:#909399;font-size:13px">共 {{ filtered.length }} 张表</span>
        <el-pagination v-if="filtered.length>pageSize" :total="filtered.length" :page-size="pageSize" :current-page.sync="page" layout="sizes,prev,pager,next" :page-sizes="[10,20,50,100]" @size-change="pageSize=$event;page=1" background small />
      </div>
    </div>

    <!-- 底部状态栏 -->
    <div class="bottom-bar">
      <span>MySQL {{ mysqlVersion }}</span>
      <span>总大小：{{ stats.total_size_format }}</span>
      <span>最后检查：{{ lastCheckTime }}</span>
    </div>

    <!-- 表详情弹窗 -->
    <el-dialog :title="detailTitle" :visible.sync="showDetailDialog" width="800px" top="5vh">
      <div v-if="detailData" class="detail-body">
        <div class="detail-grid">
          <div><label>表名</label><span>{{ detailData.name }}</span></div>
          <div><label>中文名称</label><span>{{ detailData.cname||autoName(detailData.name) }}</span></div>
          <div><label>数据量</label><span>{{ fmtNum(detailData.rows) }} 行</span></div>
          <div><label>数据大小</label><span>{{ detailData.data_size }}</span></div>
          <div><label>索引大小</label><span>{{ detailData.index_size }}</span></div>
          <div><label>总大小</label><span>{{ detailData.total_size }}</span></div>
          <div><label>表引擎</label><span>{{ detailData.engine }}</span></div>
          <div><label>字符集</label><span>{{ detailData.collation }}</span></div>
          <div><label>创建时间</label><span>{{ detailData.create_time }}</span></div>
          <div><label>更新时间</label><span>{{ detailData.update_time }}</span></div>
        </div>
        <h4>字段（{{ (detailData.columns||[]).length }}）</h4>
        <el-table :data="detailData.columns||[]" size="mini" border stripe max-height="300" style="width:100%">
          <el-table-column prop="Field" label="字段名" min-width="120" />
          <el-table-column prop="Type" label="类型" min-width="140" />
          <el-table-column prop="Null" label="允许空" width="70" :formatter="r=>r.Null==='YES'?'是':'否'" />
          <el-table-column prop="Default" label="默认值" width="100" />
          <el-table-column prop="Key" label="键" width="60" />
          <el-table-column prop="Extra" label="额外" min-width="120" />
        </el-table>
        <h4>索引（{{ idxCount }}）</h4>
        <el-table :data="indexList" size="mini" border stripe max-height="250" style="width:100%">
          <el-table-column prop="Key_name" label="索引名" min-width="120" />
          <el-table-column prop="Index_type" label="类型" width="80" />
          <el-table-column prop="Column_name" label="字段" min-width="120" />
          <el-table-column prop="Non_unique" label="唯一性" width="70" :formatter="r=>r.Non_unique===0?'是':'否'" />
        </el-table>
      </div>
    </el-dialog>

    <!-- 备份确认对话框 -->
    <el-dialog title="数据库备份" :visible.sync="showBackupDialog" width="500px" :close-on-click-modal="false">
      <el-form label-width="100px">
        <el-form-item label="数据库总大小">{{ stats.total_size_format }}</el-form-item>
        <el-form-item label="存储位置">
          <el-select v-model="backupForm.location" style="width:100%">
            <el-option label="服务器本地" value="local" />
            <el-option label="腾讯云COS" value="cos" />
          </el-select>
        </el-form-item>
        <el-form-item label="备份备注"><el-input v-model="backupForm.remark" placeholder="选填" maxlength="200" /></el-form-item>
        <el-form-item v-if="backupProgressing"><el-progress :percentage="backupProgress" :stroke-width="12" :text-inside="true" status="success" /></el-form-item>
      </el-form>
      <span slot="footer">
        <el-button @click="showBackupDialog=false" size="small">取消</el-button>
        <el-button type="primary" :loading="backupProgressing" @click="doBackup" size="small">{{ backupProgressing?'备份中...':'开始备份' }}</el-button>
      </span>
    </el-dialog>

    <!-- 备份列表对话框 -->
    <el-dialog title="备份文件管理" :visible.sync="showBackupListDialog" width="800px">
      <el-table :data="backupList" size="small" border stripe style="width:100%">
        <el-table-column prop="filename" label="文件名" min-width="260" />
        <el-table-column prop="file_size_format" label="大小" width="90" />
        <el-table-column prop="created_at" label="备份时间" width="160" />
        <el-table-column label="操作" width="250" fixed="right">
          <template slot-scope="{row}">
            <el-button v-if="hasPerm('database:downloadBackup')" size="mini" type="primary" @click="downloadBackup(row.filename)">下载</el-button>
            <el-button v-if="hasPerm('database:restoreBackup')" size="mini" type="warning" @click="confirmRestore(row.filename)">恢复</el-button>
            <el-button v-if="hasPerm('database:deleteBackup')" size="mini" type="danger" @click="confirmDeleteBackup(row.filename)">删除</el-button>
          </template>
        </el-table-column>
      </el-table>
      <span slot="footer"><el-button @click="showBackupListDialog=false">关闭</el-button></span>
    </el-dialog>

    <!-- 自动备份配置对话框 -->
    <el-dialog title="自动备份配置" :visible.sync="showBackupSettingsDialog" width="550px">
      <el-form label-width="120px" size="small">
        <el-form-item label="启用自动备份"><el-switch v-model="bkSettings.enabled" /></el-form-item>
        <el-form-item label="备份频率">
          <el-select v-model="bkSettings.interval" style="width:100%">
            <el-option label="每天" value="daily" /><el-option label="每周" value="weekly" /><el-option label="每月" value="monthly" />
          </el-select>
        </el-form-item>
        <el-form-item label="备份时间"><el-time-picker v-model="bkTime" format="HH:mm" value-format="HH:mm" style="width:100%" /></el-form-item>
        <el-form-item label="保留数量"><el-input-number v-model="bkSettings.keep_count" :min="1" :max="365" style="width:100%" /></el-form-item>
        <el-form-item label="存储位置">
          <el-select v-model="bkSettings.location" style="width:100%">
            <el-option label="服务器本地" value="local" />
            <el-option label="腾讯云COS" value="cos" />
          </el-select>
        </el-form-item>
        <el-form-item label="备份后通知"><el-switch v-model="bkSettings.notify" /></el-form-item>
        <el-form-item label="备份加密"><el-switch v-model="bkSettings.encrypt" /></el-form-item>
        <el-form-item v-if="bkSettings.encrypt" label="加密密码"><el-input v-model="bkSettings.encrypt_password" type="password" placeholder="设置备份加密密码" /></el-form-item>
      </el-form>
      <span slot="footer">
        <el-button @click="showBackupSettingsDialog=false" size="small">取消</el-button>
        <el-button type="primary" :loading="savingBkSettings" @click="saveBkSettings" size="small">保存配置</el-button>
      </span>
    </el-dialog>

    <!-- 表名管理对话框 -->
    <el-dialog title="表中文名称管理" :visible.sync="showTableNameDialog" width="600px">
      <el-table :data="tableNameList" size="small" border stripe style="width:100%" max-height="400">
        <el-table-column prop="name" label="表名" min-width="200" />
        <el-table-column label="中文名称" min-width="250">
          <template slot-scope="{row,$index}">
            <el-input v-model="tableNameList[$index].cname" size="mini" />
          </template>
        </el-table-column>
      </el-table>
      <span slot="footer">
        <el-button @click="showTableNameDialog=false" size="small">取消</el-button>
        <el-button type="primary" :loading="savingNames" @click="saveTableNames" size="small">保存</el-button>
      </span>
    </el-dialog>
  </div>
</template>

<script>
import { getTableList, getStatistics, getConnectionStatus, getTableDetail, getFragmentation,
  optimizeTable, repairTable, truncateTable, dropTable, backupDatabase,
  getBackupList, deleteBackup, downloadBackup, restoreBackup,
  getBackupSettings, saveBackupSettings, getTableNames, saveTableNames } from '@/api/database'

function autoName(name) {
  if (!name) return '未知表'
  const map = { users:'用户表', settings:'系统配置表', roles:'角色表', permissions:'权限表',
    departments:'部门表', system_log:'系统日志表', theme_schemes:'主题方案表',
    user_roles:'用户角色关联表', role_permissions:'角色权限关联表',
    employee_profiles:'员工档案表', system_log_202607:'系统日志分区表' }
  if (map[name]) return map[name]
  const dict = { user:'用户', role:'角色', log:'日志', permission:'权限', department:'部门',
    theme:'主题', scheme:'方案', setting:'配置', employee:'员工', profile:'档案',
    system:'系统', data:'数据', backup:'备份', order:'工单', production:'生产',
    material:'物料', quality:'质量', inventory:'库存', report:'报工', progress:'进度',
    dashboard:'控制台', auth:'认证', service:'服务', storage:'存储', email:'邮件',
    sms:'短信', wechat:'微信', login:'登录', config:'配置', file:'文件',
    upload:'上传', export:'导出', import:'导入', clean:'清理', monthly:'月度' }
  return name.split('_').map(p=>dict[p]||p).join('') + '表'
}

export default {
  name: 'DatabaseMaintenance',
  data() {
    return {
      tables: [], stats: { table_count:0, total_rows:0, total_size_format:'0 B' },
      dbConnected: false, lastBackupTime: '', lastCheckTime: '', mysqlVersion: '5.7',
      searchQuery: '', selectedSet: new Set(), selectedRows: [],
      sortField: '', sortOrder: '', page: 1, pageSize: 20,
      showDetailDialog: false, detailData: null, detailTitle: '', indexList: [],
      showBackupDialog: false, backupForm: { location:'local', remark:'' },
      backupProgressing: false, backupProgress: 0,
      showBackupListDialog: false, backupList: [],
      showBackupSettingsDialog: false, bkSettings: { enabled:false, interval:'daily', time:'03:00', keep_count:7, location:'local', notify:true, encrypt:false, encrypt_password:'' },
      bkTime: '03:00', savingBkSettings: false,
      showTableNameDialog: false, tableNameList: [], savingNames: false,
    }
  },
  computed: {
    filtered() {
      let list = [...this.tables]
      const q = this.searchQuery.toLowerCase()
      if (q) list = list.filter(t => t.name.toLowerCase().includes(q) || (t.cname||'').includes(q) || autoName(t.name).includes(q))
      if (this.sortField) {
        list.sort((a, b) => {
          let va = a[this.sortField], vb = b[this.sortField]
          if (typeof va === 'string') va = va.toLowerCase()
          if (typeof vb === 'string') vb = vb.toLowerCase()
          if (va == null) va = ''; if (vb == null) vb = ''
          return va < vb ? -1 : va > vb ? 1 : 0
        })
        if (this.sortOrder === 'desc') list.reverse()
      }
      return list
    },
    pageData() {
      const start = (this.page - 1) * this.pageSize
      return this.filtered.slice(start, start + this.pageSize)
    },
    idxCount() {
      if (!this.detailData || !this.detailData.indexes) return 0
      const s = new Set()
      this.detailData.indexes.forEach(i => s.add(i.Key_name))
      return s.size
    },
  },
  async created() {
    await this.loadData()
    this.loadConnectionStatus()
    this.loadBackupSettings()
  },
  methods: {
    // 权限判断：按钮权限控制
    hasPerm(code) { const p = this.$store.state.user && this.$store.state.user.permissions ? this.$store.state.user.permissions : []; return p.indexOf(code) > -1 },
    autoName,
    async loadData() {
      try {
        const [tr, st] = await Promise.all([getTableList(), getStatistics()])
        if (tr.code === 0) this.tables = (tr.data||[]).map(t=>({...t,fragmentation_rate:0}))
        if (st.code === 0) this.stats = st.data || this.stats
        this.loadFragmentation()
      } catch {}
      try { const r = await getBackupList(); if (r.code===0 && r.data?.length>0) this.lastBackupTime = r.data[0].created_at } catch {}
      this.lastCheckTime = new Date().toLocaleString()
    },
    async loadConnectionStatus() {
      try { const r = await getConnectionStatus(); if (r.code===0) this.dbConnected = r.data?.connected||false } catch { this.dbConnected = false }
    },
    async loadFragmentation() {
      for (const t of this.tables) {
        try { const r = await getFragmentation(t.name); if (r.code===0) t.fragmentation_rate = r.data?.fragmentation_rate||0 } catch {}
      }
    },
    async loadBackupSettings() {
      try { const r = await getBackupSettings(); if (r.code===0 && r.data) { this.bkSettings = {...this.bkSettings, ...r.data}; this.bkTime = r.data.time||'03:00' } } catch {}
    },
    async showDetail(row) {
      this.detailTitle = `${row.name} - ${row.cname||autoName(row.name)}`
      this.showDetailDialog = true
      this.detailData = null
      try {
        const r = await getTableDetail(row.name)
        if (r.code===0 && r.data && typeof r.data === 'object' && r.data.name) {
          this.detailData = r.data
          const s = new Set(); const idx = []
          ;(r.data.indexes||[]).forEach(i => { const k = i.Key_name+':'+i.Column_name; if (!s.has(k)) { s.add(k); idx.push(i) } })
          this.indexList = idx
        } else {
          this.showDetailDialog = false
          this.$message.error((r && r.msg) || '加载详情失败')
        }
      } catch (e) {
        this.showDetailDialog = false
        this.$message.error('加载详情失败')
      }
    },
    onSort({prop,order}) { this.sortField = prop||''; this.sortOrder = order||''; this.page = 1 },
    onSelection(rows) { this.selectedRows = rows; this.selectedSet = new Set(rows.map(r=>r.name)) },
    fmtNum(n) { n=parseInt(n)||0; return n>10000?(n/10000).toFixed(1)+'万':String(n) },
    isNew(d) { return d && (Date.now()-new Date(d).getTime()) < 7*86400000 },
    async doOptimize(name) {
      this.$message.info(`正在优化 ${name}...`)
      try { const r = await optimizeTable(name); if (r.code===0) { this.$message.success(`✅ ${name} 优化完成`); this.loadFragmentation() } else this.$message.error(r.message||'失败') }
      catch { this.$message.error('优化失败') }
    },
    async batchOptimize() {
      if (this.selectedSet.size===0) return
      await this.$confirm(`即将优化 ${this.selectedSet.size} 张表，确认继续？`,'提示',{type:'warning'})
      for (const name of this.selectedSet) {
        try { const r = await optimizeTable(name); this.$message({type:r.code===0?'success':'error',message:`${r.code===0?'✅':'❌'} ${name} ${r.code===0?'优化完成':'优化失败'}`}) } catch { this.$message.error(`❌ ${name} 优化失败`) }
      }
      this.loadFragmentation()
    },
    async doRepair(name) {
      this.$message.info(`正在修复 ${name}...`)
      try { const r = await repairTable(name); if (r.code===0) this.$message.success(`✅ ${name} 修复完成`); else this.$message.error(r.message||'失败') }
      catch { this.$message.error('修复失败') }
    },
    async batchRepair() {
      if (this.selectedSet.size===0) return
      await this.$confirm(`即将修复 ${this.selectedSet.size} 张表，确认继续？`,'提示',{type:'warning'})
      for (const name of this.selectedSet) {
        try { const r = await repairTable(name); this.$message({type:r.code===0?'success':'error',message:`${r.code===0?'✅':'❌'} ${name} ${r.code===0?'修复完成':'修复失败'}`}) } catch { this.$message.error(`❌ ${name} 修复失败`) }
      }
    },
    async confirmTruncate(name) {
      try {
        await this.$confirm(`确定清空表「${name}」？此操作将删除所有数据且不可恢复！`,'危险操作',{confirmButtonText:'确认清空',type:'warning'})
        const r = await truncateTable(name)
        if (r.code===0) { this.$message.success('已清空'); this.loadData() } else this.$message.error(r.message||'失败')
      } catch {}
    },
    async confirmDrop(name) {
      try {
        await this.$prompt(`请输入「${name}」确认删除：`,'危险操作',{confirmButtonText:'确认删除',inputPlaceholder:'请输入表名确认',inputPattern:new RegExp(`^${name}$`),inputErrorMessage:'表名不匹配'})
        const r = await dropTable(name)
        if (r.code===0) { this.$message.success('已删除'); this.loadData() } else this.$message.error(r.message||'失败')
      } catch {}
    },
    async doBackup() {
      this.backupProgressing = true; this.backupProgress = 0
      const timer = setInterval(() => { if (this.backupProgress<90) this.backupProgress += 10 }, 500)
      try {
        const r = await backupDatabase(this.backupForm)
        clearInterval(timer)
        if (r.code===0) { this.backupProgress=100; this.$message.success('备份成功'); this.showBackupDialog=false; this.lastBackupTime=r.data?.backup_time||new Date().toLocaleString() }
        else this.$message.error(r.message||'失败')
      } catch { clearInterval(timer); this.$message.error('备份失败') }
      this.backupProgressing = false; this.backupProgress = 0
    },
    async loadBackupList() {
      try { const r = await getBackupList(); if (r.code===0) this.backupList = r.data||[] } catch { this.$message.error('加载失败') }
    },
    async downloadBackup(filename) {
      const token = this.$store.state.user?.token
      const url = downloadBackup(filename)
      // 用 fetch + blob 下载，避免 Token 暴露在 URL 中
      try {
        const res = await fetch(url, {
          headers: { 'Authorization': token ? `Bearer ${token}` : '' }
        })
        if (!res.ok) { this.$message.error('下载失败'); return }
        const blob = await res.blob()
        const link = document.createElement('a')
        link.href = URL.createObjectURL(blob)
        link.download = filename
        link.click()
        URL.revokeObjectURL(link.href)
      } catch {
        this.$message.error('下载失败')
      }
    },
    async confirmRestore(filename) {
      try {
        await this.$prompt('请输入「确认恢复」以执行恢复操作：','恢复数据库',{confirmButtonText:'确认恢复',inputPlaceholder:'请输入「确认恢复」',inputPattern:/^确认恢复$/,inputErrorMessage:'请输入「确认恢复」'})
        const r = await restoreBackup(filename, {confirm:'确认恢复'})
        if (r.code===0) { this.$message.success(r.message||'恢复成功'); this.loadData() } else this.$message.error(r.message||'失败')
      } catch {}
    },
    async confirmDeleteBackup(filename) {
      try {
        await this.$confirm(`确定删除「${filename}」？`,'提示',{type:'warning'})
        const r = await deleteBackup(filename)
        if (r.code===0) { this.$message.success('已删除'); this.loadBackupList() } else this.$message.error('删除失败')
      } catch {}
    },
    async saveBkSettings() {
      this.savingBkSettings = true
      try {
        const data = {...this.bkSettings, time: this.bkTime}
        const r = await saveBackupSettings(data)
        if (r.code===0) { this.$message.success('配置已保存'); this.showBackupSettingsDialog = false } else this.$message.error(r.message||'失败')
      } catch { this.$message.error('保存失败') }
      this.savingBkSettings = false
    },
    async saveTableNames() {
      this.savingNames = true
      try {
        const names = {}
        this.tableNameList.forEach(t => { if (t.cname) names[t.name] = t.cname })
        const r = await saveTableNames({names})
        if (r.code===0) { this.$message.success('已保存'); this.showTableNameDialog = false; this.loadData() } else this.$message.error(r.message||'失败')
      } catch { this.$message.error('保存失败') }
      this.savingNames = false
    },
    openTableNames() {
      const names = {}
      this.tables.forEach(t => { const n = t.cname || autoName(t.name); if (n) names[t.name] = n })
      this.tableNameList = this.tables.map(t => ({name: t.name, cname: t.cname || autoName(t.name)}))
      this.showTableNameDialog = true
    },
  },
  watch: {
    showBackupListDialog(v) { if (v) this.loadBackupList() },
    showTableNameDialog(v) { if (v) this.openTableNames() },
    searchQuery() { this.page = 1 },
  },
}
</script>

<style scoped>
.database-page { padding:20px; height:100%; display:flex; flex-direction:column; background:#f0f2f5; gap:16px; }
.page-header-row { display:flex; justify-content:space-between; align-items:center; padding-bottom:12px; border-bottom:1px solid #EBEEF5; }
.page-header-row h2 { margin:0; font-size:20px; font-weight:700; color:#303133; }
.header-status { display:flex; align-items:center; gap:8px; flex-wrap:wrap; }
.header-backup { font-size:13px; color:#909399; }
.stat-cards { display:flex; gap:16px; }
.stat-card { flex:1; display:flex; align-items:center; gap:16px; background:#fff; border-radius:8px; padding:16px 20px; box-shadow:0 2px 8px rgba(0,0,0,0.06); height:76px; }
.card-icon { font-size:32px; }
.card-icon.blue { color:#409EFF; } .card-icon.green { color:#67C23A; }
.card-icon.orange { color:#E6A23C; } .card-icon.purple { color:#9B59B6; }
.stat-num { font-size:24px; font-weight:700; color:#303133; line-height:1.2; }
.stat-unit { font-size:14px; font-weight:400; color:#909399; }
.stat-label { font-size:14px; color:#909399; margin-top:2px; }
.toolbar { display:flex; justify-content:space-between; align-items:center; background:#fff; border-radius:8px; padding:8px 16px; gap:8px; }
.toolbar-left { display:flex; gap:8px; flex-wrap:wrap; }
.table-wrapper { flex:1; background:#fff; border-radius:8px; overflow:auto; min-height:0; }
.table-footer { display:flex; justify-content:space-between; align-items:center; padding:8px 16px; border-top:1px solid #EBEEF5; }
.tb-name { font-family:Consolas,monospace; white-space:nowrap; }
.tb-name.empty-tb { color:#C0C4CC; }
.warn-dot { color:#E6A23C; font-size:13px; }
.new-badge { display:inline-flex; align-items:center; justify-content:center; font-size:10px; color:#fff; background:#67C23A; border-radius:3px; padding:0 4px; height:16px; font-style:normal; margin-right:2px; }
.detail-body { max-height:70vh; overflow-y:auto; }
.detail-grid { display:grid; grid-template-columns:1fr 1fr; gap:4px 24px; padding:8px 0 16px; }
.detail-grid div { display:flex; font-size:13px; padding:2px 0; }
.detail-grid label { color:#909399; min-width:80px; flex-shrink:0; }
.detail-grid span { color:#303133; word-break:break-all; }
.detail-body h4 { font-size:15px; font-weight:600; margin:12px 0 8px; padding-bottom:4px; border-bottom:1px solid #f0f2f5; }
.bottom-bar { display:flex; justify-content:space-between; align-items:center; height:32px; background:#fafafa; border-top:1px solid #EBEEF5; padding:0 20px; font-size:12px; color:#909399; }
</style>
