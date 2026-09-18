<!--
  文件：admin/src/views/warehouse/parts/purchase-in/Add.vue
  功能：新增/编辑采购入库单（选到货单 -> 明细 -> 入库信息）
  权限：warehouse:purchase:in:add / edit
-->
<template>
  <div class="wh-page">
    <el-breadcrumb separator="/" class="breadcrumb">
      <el-breadcrumb-item>仓储管理</el-breadcrumb-item>
      <el-breadcrumb-item>配件出入库</el-breadcrumb-item>
      <el-breadcrumb-item>采购入库</el-breadcrumb-item>
      <el-breadcrumb-item>{{ isEdit ? '编辑入库单' : '新增入库单' }}</el-breadcrumb-item>
    </el-breadcrumb>

    <div class="page-header">
      <span class="page-title">{{ isEdit ? '编辑采购入库单 - ' + form.in_no : (previewNo ? '新增采购入库单 - ' + previewNo : '新增采购入库单') }}</span>
      <div>
        <el-button size="small" icon="el-icon-setting" @click="$router.push('/settings/code-rule/purchase-in')">编码规则</el-button>
        <el-button type="primary" size="small" :loading="saving" @click="handleSave">保存</el-button>
        <el-button size="small" @click="handleCancel">取消</el-button>
      </div>
    </div>

    <el-alert v-if="isEdit" type="info" :closable="false" show-icon class="arrival-tip"
      :title="'该入库单来源于采购到货单：' + form.arrival_no + '，不可更换来源'" />

    <el-card shadow="never" class="info-card">
      <div slot="header" class="card-head"><span>入库单信息</span></div>
      <el-form :model="form" label-width="120px" size="small" class="in-form">
        <el-row :gutter="16">
          <el-col :span="12">
            <el-form-item label="来源采购到货单" required>
              <el-select v-model="form.arrival_id" :disabled="isEdit" filterable placeholder="请选择采购到货单" style="width:100%" @change="onArrivalChange">
                <el-option v-for="a in arrivalOptions" :key="a.id" :label="a.label" :value="a.id" />
              </el-select>
            </el-form-item>
          </el-col>
          <el-col :span="12"><el-form-item label="供应商"><el-input v-model="form.supplier_name" disabled placeholder="从到货单自动带出" /></el-form-item></el-col>
          <el-col :span="12">
            <el-form-item label="入库仓库" required>
              <el-select v-model="form.warehouse_id" filterable placeholder="请选择仓库" style="width:100%" @change="loadLocations">
                <el-option v-for="w in warehouseOptions" :key="w.id" :label="w.warehouse_name" :value="w.id" />
              </el-select>
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="入库日期" required>
              <el-date-picker v-model="form.in_date" type="date" value-format="yyyy-MM-dd" style="width:100%" placeholder="选择入库日期" />
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="入库人">
              <el-select v-model="form.receiver_id" filterable placeholder="选择入库人" style="width:100%">
                <el-option v-for="u in userOptions" :key="u.id" :label="u.real_name || u.username" :value="u.id" />
              </el-select>
            </el-form-item>
          </el-col>
        </el-row>
      </el-form>
    </el-card>

    <el-card shadow="never" class="info-card">
      <div slot="header" class="card-head"><span>入库物料明细</span></div>
      <el-table :data="items" size="small" border empty-text="请先选择来源采购到货单">
        <el-table-column type="index" label="#" width="45" align="center" />
        <el-table-column prop="material_code" label="物料编码" width="110" />
        <el-table-column prop="material_name" label="物料名称" min-width="130" show-overflow-tooltip />
        <el-table-column prop="spec" label="规格型号" width="110" show-overflow-tooltip />
        <el-table-column prop="unit" label="单位" width="55" align="center" />
        <el-table-column prop="arrival_quantity" label="到货数量" width="80" align="right" />
        <el-table-column prop="qualified_quantity" label="合格数量" width="80" align="right" />
        <el-table-column prop="can_in_quantity" label="可入库数量" width="90" align="right" />
        <el-table-column label="入库数量" width="120" align="right">
          <template slot-scope="s">
            <el-input-number v-model="s.row.in_quantity" :min="0" :max="Number(s.row.can_in_quantity)" :precision="0" size="small" style="width:100%" @change="v => onQtyChange(s.$index, v)" />
          
</template>
        </el-table-column>
        <el-table-column label="入库单价" width="130" align="right">
          <template slot-scope="s">
            <el-input-number v-model="s.row.in_price" :min="0" :precision="4" size="small" style="width:100%" />
          </template>
        </el-table-column>
        <el-table-column label="存放货位" width="150">
          <template slot-scope="s">
            <el-select v-model="s.row.location_id" filterable placeholder="选择货位" size="small" style="width:100%">
              <el-option v-for="l in locationOptions" :key="l.id" :label="l.label" :value="l.id" />
            </el-select>
          </template>
        </el-table-column>
        <el-table-column label="生产批次" width="110"><template slot-scope="s"><el-input v-model="s.row.batch_no" size="small" /></template></el-table-column>
        <el-table-column label="生产日期" width="120"><template slot-scope="s"><el-date-picker v-model="s.row.produce_date" type="date" value-format="yyyy-MM-dd" size="small" style="width:100%" /></template></el-table-column>
        <el-table-column label="有效期至" width="120"><template slot-scope="s"><el-date-picker v-model="s.row.expire_date" type="date" value-format="yyyy-MM-dd" size="small" style="width:100%" /></template></el-table-column>
        <el-table-column label="操作" width="55" align="center" fixed="right">
          <template slot-scope="s"><el-button type="text" size="mini" class="danger" @click="items.splice(s.$index, 1)">删除</el-button></template>
        </el-table-column>
      </el-table>
      <div class="summary" v-if="items.length">
        合计：入库总数量 <b>{{ totalQty }}</b>，入库总金额 <b>¥ {{ totalAmount.toFixed(2) }}</b>
      </div>
    </el-card>

    <el-card shadow="never" class="info-card">
      <el-form label-width="120px" size="small">
        <el-form-item label="备注"><el-input v-model="form.remark" type="textarea" :rows="3" placeholder="请输入备注信息" /></el-form-item>
      </el-form>
    </el-card>

    <!-- 附件（编辑模式，草稿保存后可上传） -->
    <el-card v-if="isEdit" shadow="never" class="info-card">
      <div slot="header" class="card-head"><span>附件</span>
        <el-button size="mini" icon="el-icon-upload2" @click="uploadVisible = true">上传附件</el-button>
      </div>
      <el-table :data="attachments" size="small" border empty-text="暂无附件">
        <el-table-column prop="file_name" label="文件名" min-width="200" show-overflow-tooltip />
        <el-table-column label="文件大小" width="100" align="right"><template slot-scope="s">{{ formatSize(s.row.file_size) }}</template></el-table-column>
        <el-table-column prop="uploader_name" label="上传人" width="100" />
        <el-table-column prop="upload_time" label="上传时间" width="160" />
        <el-table-column label="操作" width="120" align="center">
          <template slot-scope="s">
            <el-button type="text" size="mini" @click="downloadAtt(s.row)">下载</el-button>
            <el-button v-permission="'warehouse:purchase:in:attachment:delete'" type="text" size="mini" class="danger" @click="handleDeleteAtt(s.row)">删除</el-button>
          </template>
        </el-table-column>
      </el-table>
    </el-card>

    <!-- 上传附件弹窗 -->
    <el-dialog title="上传附件" :visible="uploadVisible" @update:visible="v => uploadVisible = v" width="460px" top="8vh">
      <el-upload drag :auto-upload="false" :limit="1" accept=".jpg,.jpeg,.png,.gif,.pdf,.xlsx,.docx" :on-change="onUploadFileChange" :file-list="uploadFileList">
        <i class="el-icon-upload"></i>
        <div class="el-upload__text">将文件拖到此处，或<em>点击上传</em></div>
        <div class="el-upload__tip" slot="tip">支持 jpg/png/gif/pdf/xlsx/docx，大小不超过 10MB</div>
      </el-upload>
      <div style="margin-top:6px">
        <el-button size="mini" type="primary" plain icon="el-icon-folder-opened" @click="driveVisible = true">从企业网盘选择</el-button>
      </div>
      <drive-file-picker :visible="driveVisible" mode="file" :multiple="false" @update:visible="driveVisible = $event" @confirm="onDrivePick" />
      <span slot="footer">
        <el-button size="small" @click="uploadVisible = false">取消</el-button>
        <el-button size="small" type="primary" :loading="uploading" :disabled="!uploadFile" @click="handleUpload">上传</el-button>
      </span>
    </el-dialog>
  </div>
</template>

<script>
import { getReadyArrivalList, savePurchaseIn, getPurchaseInDetail, getWarehouseList, getLocationOptions, getPurchaseInNextCode, getInAttachments, uploadInAttachment, deleteInAttachment, downloadInAttachment } from '../../../../api/warehouse'
import { getUserList } from '../../../../api/user'

export default {
  name: 'WarehousePurchaseInAdd',
  data () {
    return {
      driveVisible: false,
      id: Number(this.$route.params.id) || 0,
      isEdit: false, saving: false, previewNo: '',
      attachments: [], uploadVisible: false, uploadFile: null, uploadFileList: [], uploading: false,
      arrivalOptions: [], warehouseOptions: [], locationOptions: [], userOptions: [],
      form: { in_no: '', arrival_id: null, arrival_no: '', order_id: 0, order_no: '', supplier_id: 0, supplier_name: '', warehouse_id: null, in_date: this.today(), receiver_id: 0, remark: '' },
      items: []
    }
  },
  computed: {
    totalQty () { return this.items.reduce((s, it) => s + Number(it.in_quantity || 0), 0) },
    totalAmount () { return this.items.reduce((s, it) => s + Number(it.in_quantity || 0) * Number(it.in_price || 0), 0) }
  },
  created () {
    this.isEdit = this.id > 0
    this.loadBase()
    if (this.isEdit) this.loadDetail()
    else this.loadNextNo()
  },
  async loadNextNo () {
    try { const r = await getPurchaseInNextCode(); if (r.code === 0 && r.data) this.previewNo = r.data.code } catch (e) {}
  },
  methods: {
    today () { const d = new Date(); return d.getFullYear() + '-' + String(d.getMonth() + 1).padStart(2, '0') + '-' + String(d.getDate()).padStart(2, '0') },
    async loadBase () {
      try {
        const [a, w, u] = await Promise.all([getReadyArrivalList(), getWarehouseList({ page: 1, pageSize: 100, status: 1 }), getUserList({ page: 1, limit: 200 })])
        this.arrivalOptions = (a.code === 0 && a.data) ? a.data : []
        this.warehouseOptions = (w.code === 0 && w.data) ? (w.data.list || []) : []
        this.userOptions = (u.data && u.data.list) || []
        const me = this.$store && this.$store.state && this.$store.state.user
        if (me && me.id) this.form.receiver_id = me.id
        // 从到货单详情"生成入库单"跳转：自动选中到货单并带出明细
        const qArrival = Number(this.$route.query.arrival_id || 0)
        if (qArrival && !this.isEdit && this.form.arrival_id !== qArrival) {
          this.form.arrival_id = qArrival
          this.onArrivalChange(qArrival)
        }
      } catch (e) {}
    },
    async loadDetail () {
      try {
        const r = await getPurchaseInDetail(this.id)
        if (r.code === 0 && r.data) {
          const d = r.data.in || {}
          this.form = { in_no: d.in_no, arrival_id: d.arrival_id, arrival_no: d.arrival_no, order_id: d.order_id, order_no: d.order_no, supplier_id: d.supplier_id, supplier_name: d.supplier_name, warehouse_id: d.warehouse_id, in_date: d.in_date || this.today(), receiver_id: d.receiver_id, remark: d.remark || '' }
          this.items = (r.data.items || []).map(it => ({ ...it, can_in_quantity: Number(it.in_quantity), arrival_quantity: Number(it.arrival_quantity || 0), qualified_quantity: Number(it.qualified_quantity || 0) }))
          if (this.form.warehouse_id) this.loadLocations()
        }
      } catch (e) {}
      this.loadAttachments()
    },
    async loadAttachments () {
      if (!this.isEdit) return
      try {
        const r = await getInAttachments(this.id)
        this.attachments = (r.code === 0 && r.data) ? (r.data.list || []) : []
      } catch (e) { this.attachments = [] }
    },
    onDrivePick(list) {
      const f = list[0]
      if (!f) return
      fetch(f.url).then(res => res.blob()).then(blob => {
        const raw = new File([blob], f.name, { type: blob.type || 'application/octet-stream' })
        if (raw.size > 10 * 1024 * 1024) { this.$message.error('文件大小不能超过 10MB'); return }
        this.onUploadFileChange({ raw, name: f.name, size: raw.size, status: 'ready' }, [{ raw, name: f.name }])
      }).catch(() => this.$message.error('读取网盘文件失败'))
    },
    onUploadFileChange (file, fileList) {
      if (file.size > 10 * 1024 * 1024) { this.$message.error('文件大小不能超过 10MB'); this.uploadFile = null; this.uploadFileList = []; return }
      this.uploadFile = file.raw
      this.uploadFileList = fileList.slice(-1)
    },
    async handleUpload () {
      if (!this.uploadFile) return
      this.uploading = true
      try {
        const fd = new FormData()
        fd.append('file', this.uploadFile)
        const r = await uploadInAttachment(this.id, fd)
        if (r.code === 0) { this.$message.success('上传成功'); this.uploadVisible = false; this.uploadFile = null; this.uploadFileList = []; this.loadAttachments() } else this.$message.error(r.msg || '上传失败')
      } catch (e) {} finally { this.uploading = false }
    },
    async downloadAtt (row) {
      try {
        const resp = await downloadInAttachment(row.id)
        const url = window.URL.createObjectURL(new Blob([resp.data]))
        const a = document.createElement('a')
        a.href = url
        a.download = row.file_name
        a.click()
        window.URL.revokeObjectURL(url)
      } catch (e) { this.$message.error('下载失败') }
    },
    handleDeleteAtt (row) {
      this.$confirm('确认删除该附件吗？', '提示', { type: 'warning' }).then(async () => {
        try {
          const r = await deleteInAttachment(row.id)
          if (r.code === 0) { this.$message.success('删除成功'); this.loadAttachments() } else this.$message.error(r.msg || '删除失败')
        } catch (e) {}
      }).catch(() => {})
    },
    formatSize (size) {
      const s = Number(size || 0)
      if (s < 1024) return s + ' B'
      if (s < 1024 * 1024) return (s / 1024).toFixed(1) + ' KB'
      return (s / 1024 / 1024).toFixed(2) + ' MB'
    },
    onArrivalChange (id) {
      const a = this.arrivalOptions.find(x => x.id === id)
      if (!a) return
      this.form.supplier_id = a.supplier_id
      this.form.supplier_name = a.supplier_name || ''
      this.form.order_id = a.order_id
      this.form.order_no = a.order_no
      this.form.arrival_no = a.arrival_no
      this.items = (a.items || []).map(it => ({
        arrival_item_id: it.arrival_item_id, material_id: it.material_id,
        material_code: it.material_code, material_name: it.material_name, spec: it.spec, unit: it.unit,
        arrival_quantity: it.arrival_quantity, qualified_quantity: it.qualified_quantity,
        can_in_quantity: it.can_in_quantity, in_quantity: it.in_quantity, in_price: it.in_price,
        location_id: it.location_id || 0, batch_no: '', produce_date: '', expire_date: '', remark: ''
      }))
    },
    async loadLocations () {
      if (!this.form.warehouse_id) { this.locationOptions = []; return }
      try {
        const r = await getLocationOptions(this.form.warehouse_id)
        this.locationOptions = (r.code === 0 && r.data) ? r.data : []
      } catch (e) { this.locationOptions = [] }
    },
    onQtyChange (idx, v) {
      const it = this.items[idx]
      if (it && Number(v) > Number(it.can_in_quantity)) {
        it.in_quantity = Number(it.can_in_quantity)
        this.$message.warning('入库数量不能大于可入库数量')
      }
    },
    handleSave () {
      if (!this.form.arrival_id) { this.$message.warning('请选择来源采购到货单'); return }
      if (!this.form.warehouse_id) { this.$message.warning('请选择入库仓库'); return }
      if (!this.form.in_date) { this.$message.warning('请选择入库日期'); return }
      if (!this.items.length) { this.$message.warning('请至少添加一条入库明细'); return }
      if (this.items.some(it => Number(it.in_quantity) <= 0)) { this.$message.warning('入库数量必须大于0'); return }
      if (this.items.some(it => !it.location_id)) { this.$message.warning('请为明细选择存放货位'); return }
      this.saving = true
      try {
        const payload = {
          id: this.id || null,
          arrival_id: this.form.arrival_id, in_date: this.form.in_date,
          warehouse_id: this.form.warehouse_id, receiver_id: this.form.receiver_id,
          remark: this.form.remark,
          items: this.items.map(it => ({
            arrival_item_id: it.arrival_item_id, material_id: it.material_id,
            material_code: it.material_code, material_name: it.material_name, spec: it.spec, unit: it.unit,
            in_quantity: it.in_quantity, in_price: it.in_price, location_id: it.location_id,
            location_name: (this.locationOptions.find(l => l.id === it.location_id) || {}).label || '',
            batch_no: it.batch_no, produce_date: it.produce_date, expire_date: it.expire_date, remark: it.remark
          }))
        }
        savePurchaseIn(payload).then(r => {
          if (r.code === 0) { this.$message.success('保存成功'); this.$router.push('/warehouse/parts/purchase-in/list') } else this.$message.error(r.msg || '保存失败')
        }).catch(() => {}).finally(() => { this.saving = false })
      } catch (e) { this.saving = false }
    },
    handleCancel () {
      if (this.items.length || this.form.supplier_name || this.form.remark) {
        this.$confirm('确认离开吗？未保存的内容将丢失', '提示', { type: 'warning' }).then(() => this.$router.push('/warehouse/parts/purchase-in/list')).catch(() => {})
      } else {
        this.$router.push('/warehouse/parts/purchase-in/list')
      }
    }
  }
}
</script>

<style scoped>
.wh-page { padding: 16px; }
.breadcrumb { margin-bottom: 12px; }
.page-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 14px; }
.page-title { font-size: 18px; font-weight: 700; color: #303133; }
.arrival-tip { margin-bottom: 12px; }
.info-card { margin-bottom: 14px; }
.card-head { font-size: 15px; font-weight: 600; }
.in-form { max-width: 900px; }
.summary { margin-top: 10px; font-size: 13px; color: #606266; }
.danger { color: #F56C6C; }
</style>
