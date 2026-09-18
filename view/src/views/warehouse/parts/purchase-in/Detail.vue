<!--
  文件：admin/src/views/warehouse/parts/purchase-in/Detail.vue
  功能：采购入库单详情（信息/明细/库存流水）
  权限：warehouse:purchase:in:view/edit/confirm
-->
<template>
  <div class="detail-page">
    <el-breadcrumb separator="/" class="breadcrumb">
      <el-breadcrumb-item>仓储管理</el-breadcrumb-item>
      <el-breadcrumb-item>配件出入库</el-breadcrumb-item>
      <el-breadcrumb-item>采购入库</el-breadcrumb-item>
      <el-breadcrumb-item>入库单详情</el-breadcrumb-item>
    </el-breadcrumb>

    <div class="detail-header">
      <span class="detail-title">采购入库单详情 - {{ detail.in_no || '...' }}</span>
      <div>
        <el-button size="small" icon="el-icon-back" @click="$router.push('/warehouse/parts/purchase-in/list')">返回列表</el-button>
        <el-button v-if="detail.status === 0" v-permission="'warehouse:purchase:in:edit'" size="small" type="primary" icon="el-icon-edit" @click="$router.push('/warehouse/parts/purchase-in/edit/' + id)">编辑</el-button>
        <el-button v-if="detail.status === 0" v-permission="'warehouse:purchase:in:confirm'" size="small" type="primary" icon="el-icon-check" :loading="confirming" @click="handleConfirm">确认入库</el-button>
        <el-button v-if="detail.status === 1" v-permission="'warehouse:purchase:in:attachment:upload'" size="small" icon="el-icon-upload2" @click="uploadVisible = true">上传附件</el-button>
        <el-button v-if="detail.status === 1" v-permission="'warehouse:purchase:in:reverse'" size="small" type="danger" plain icon="el-icon-refresh-left" @click="openReverse">冲销入库</el-button>
        <el-button size="small" icon="el-icon-printer" @click="handlePrint">打印</el-button>
      </div>
    </div>

    <!-- 入库单信息 -->
    <el-card shadow="never" class="info-card">
      <div slot="header" class="card-head">
        <span>入库单信息</span>
        <el-tag :type="detail.status_tag" size="mini" style="margin-left:10px">{{ detail.status_label }}</el-tag>
      </div>
      <el-descriptions v-if="detail.in_no" :column="2" border size="small">
        <el-descriptions-item label="入库单编号">{{ detail.in_no }}</el-descriptions-item>
        <el-descriptions-item label="关联采购到货单"><span class="link" @click="goArrival">{{ detail.arrival_no || '-' }}</span></el-descriptions-item>
        <el-descriptions-item label="关联采购订单">{{ detail.order_no || '-' }}</el-descriptions-item>
        <el-descriptions-item label="供应商">{{ detail.supplier_name || '-' }}</el-descriptions-item>
        <el-descriptions-item label="入库仓库">{{ detail.warehouse_name || '-' }}</el-descriptions-item>
        <el-descriptions-item label="入库日期">{{ detail.in_date || '-' }}</el-descriptions-item>
        <el-descriptions-item label="入库人">{{ detail.in_user_name || '-' }}</el-descriptions-item>
        <el-descriptions-item label="入库状态"><el-tag :type="detail.status_tag" size="mini">{{ detail.status_label }}</el-tag></el-descriptions-item>
        <el-descriptions-item label="入库类型">{{ detail.in_type === 2 ? '退货入库' : (detail.in_type === 3 ? '盘盈入库' : '采购入库') }}</el-descriptions-item>
        <el-descriptions-item label="创建人">{{ detail.created_by_name || '-' }}</el-descriptions-item>
        <el-descriptions-item label="创建时间">{{ detail.create_time || '-' }}</el-descriptions-item>
        <el-descriptions-item label="更新时间">{{ detail.update_time || '-' }}</el-descriptions-item>
        <el-descriptions-item label="备注" :span="2">{{ detail.remark || '-' }}</el-descriptions-item>
      </el-descriptions>
    </el-card>

    <!-- 入库明细 -->
    <el-card shadow="never" class="info-card">
      <div slot="header" class="card-head"><span>入库物料明细</span></div>
      <el-table :data="items" size="small" border empty-text="暂无明细">
        <el-table-column type="index" label="#" width="45" align="center" />
        <el-table-column prop="material_code" label="物料编码" width="110" />
        <el-table-column prop="material_name" label="物料名称" min-width="120" show-overflow-tooltip />
        <el-table-column prop="spec" label="规格型号" width="110" show-overflow-tooltip />
        <el-table-column prop="unit" label="单位" width="55" align="center" />
        <el-table-column label="到货数量" width="80" align="right"><template slot-scope="s">{{ Number(s.row.arrival_quantity || 0).toLocaleString() }}</template></el-table-column>
        <el-table-column label="合格数量" width="80" align="right"><template slot-scope="s">{{ Number(s.row.qualified_quantity || 0).toLocaleString() }}</template></el-table-column>
        <el-table-column label="入库数量" width="90" align="right"><template slot-scope="s">{{ Number(s.row.in_quantity || 0).toLocaleString() }}</template></el-table-column>
        <el-table-column label="入库单价" width="100" align="right"><template slot-scope="s">¥ {{ Number(s.row.in_price || 0).toFixed(4) }}</template></el-table-column>
        <el-table-column label="入库总价" width="110" align="right"><template slot-scope="s">¥ {{ Number(s.row.in_total || 0).toFixed(2) }}</template></el-table-column>
        <el-table-column label="加权平均单价" width="110" align="right">
          <template slot-scope="s">{{ detail.status === 1 ? '¥ ' + Number(s.row.avg_price || 0).toFixed(4) : '-' }}</template>
        </el-table-column>
        <el-table-column prop="location_name" label="存放货位" width="130" show-overflow-tooltip />
        <el-table-column prop="batch_no" label="生产批次" width="100" show-overflow-tooltip />
        <el-table-column prop="produce_date" label="生产日期" width="100" />
        <el-table-column prop="expire_date" label="有效期至" width="100" />
      </el-table>
    </el-card>

    <!-- 附件 -->
    <el-card shadow="never" class="info-card">
      <div slot="header" class="card-head"><span>附件</span></div>
      <el-table :data="attachments" size="small" border empty-text="暂无附件">
        <el-table-column prop="file_name" label="文件名" min-width="200" show-overflow-tooltip />
        <el-table-column label="文件大小" width="100" align="right"><template slot-scope="s">{{ formatSize(s.row.file_size) }}</template></el-table-column>
        <el-table-column prop="uploader_name" label="上传人" width="100" />
        <el-table-column prop="upload_time" label="上传时间" width="160" />
        <el-table-column label="操作" width="140" align="center">
          <template slot-scope="s">
            <el-button type="text" size="mini" @click="previewAtt(s.row)">预览</el-button>
            <el-button type="text" size="mini" @click="downloadAtt(s.row)">下载</el-button>
            <el-button v-permission="'warehouse:purchase:in:attachment:delete'" type="text" size="mini" class="danger" @click="handleDeleteAtt(s.row)">删除</el-button>
          </template>
        </el-table-column>
      </el-table>
    </el-card>

    <!-- 库存流水（已入库） -->
    <el-card v-if="detail.status === 1" shadow="never" class="info-card">
      <div slot="header" class="card-head"><span>库存流水</span></div>
      <el-table :data="flows" size="small" border empty-text="暂无流水">
        <el-table-column prop="material_name" label="物料名称" min-width="130" show-overflow-tooltip />
        <el-table-column label="变动类型" width="100"><template slot-scope="s">采购入库</template></el-table-column>
        <el-table-column label="变动数量" width="90" align="right"><template slot-scope="s">+{{ Number(s.row.flow_quantity || 0).toLocaleString() }}</template></el-table-column>
        <el-table-column label="成本单价" width="100" align="right"><template slot-scope="s">¥ {{ Number(s.row.cost_price || 0).toFixed(4) }}</template></el-table-column>
        <el-table-column label="成本总价" width="110" align="right"><template slot-scope="s">¥ {{ Number(s.row.cost_total || 0).toFixed(2) }}</template></el-table-column>
        <el-table-column label="变动前库存" width="100" align="right"><template slot-scope="s">{{ Number(s.row.before_stock || 0).toLocaleString() }}</template></el-table-column>
        <el-table-column label="变动后库存" width="100" align="right"><template slot-scope="s">{{ Number(s.row.after_stock || 0).toLocaleString() }}</template></el-table-column>
        <el-table-column label="变动前均价" width="100" align="right"><template slot-scope="s">¥ {{ Number(s.row.before_avg_price || 0).toFixed(4) }}</template></el-table-column>
        <el-table-column label="变动后均价" width="100" align="right"><template slot-scope="s">¥ {{ Number(s.row.after_avg_price || 0).toFixed(4) }}</template></el-table-column>
        <el-table-column prop="operator_name" label="操作人" width="90" />
        <el-table-column prop="flow_time" label="变动时间" width="160" />
      </el-table>
    </el-card>

    <!-- 上传附件弹窗 -->
    <el-dialog title="上传附件" :visible="uploadVisible" @update:visible="v => uploadVisible = v" width="460px" top="8vh">
      <el-upload drag :auto-upload="false" :limit="1" accept=".jpg,.jpeg,.png,.gif,.pdf,.xlsx,.docx" :on-change="onUploadFileChange" :file-list="uploadFileList">
        <i class="el-icon-upload"></i>
        <div class="el-upload__text">将文件拖到此处，或<em>点击上传</em></div>
        <div class="el-upload__tip" slot="tip">支持 jpg/png/gif/pdf/xlsx/docx，大小不超过 10MB</div>
      </el-upload>
      <span slot="footer">
        <el-button size="small" @click="uploadVisible = false">取消</el-button>
        <el-button size="small" type="primary" :loading="uploading" :disabled="!uploadFile" @click="handleUpload">上传</el-button>
      </span>
    </el-dialog>

    <!-- 冲销入库弹窗 -->
    <el-dialog title="冲销入库" :visible="reverseVisible" @update:visible="v => reverseVisible = v" width="460px" top="8vh">
      <el-alert type="warning" :closable="false" show-icon title="冲销后将恢复库存并删除流水记录，此操作不可逆" style="margin-bottom:12px" />
      <el-input v-model="reverseReason" type="textarea" :rows="3" placeholder="请填写冲销原因（必填）" />
      <span slot="footer">
        <el-button size="small" @click="reverseVisible = false">取消</el-button>
        <el-button size="small" type="primary" :loading="reversing" @click="handleReverse">确认冲销</el-button>
      </span>
    </el-dialog>
  </div>
</template>

<script>
import { getPurchaseInDetail, confirmPurchaseIn, reversePurchaseIn, uploadInAttachment, getInAttachments, deleteInAttachment, downloadInAttachment } from '../../../../api/warehouse'

export default {
  name: 'WarehousePurchaseInDetail',
  data () {
    return {
      id: Number(this.$route.params.id) || 0,
      detail: {}, items: [], flows: [], confirming: false,
      attachments: [], uploadVisible: false, uploadFile: null, uploadFileList: [], uploading: false,
      reverseVisible: false, reverseReason: '', reversing: false
    }
  },
  created () { this.load() },
  mounted () { if (this.$route.query.print === '1') setTimeout(() => window.print(), 600) },
  methods: {
    async load () {
      try {
        const r = await getPurchaseInDetail(this.id)
        if (r.code === 0 && r.data) {
          this.detail = r.data.in || {}
          this.items = r.data.items || []
          this.flows = r.data.flows || []
        } else this.$message.error(r.msg || '加载失败')
      } catch (e) {}
      this.loadAttachments()
    },
    async loadAttachments () {
      try {
        const r = await getInAttachments(this.id)
        this.attachments = (r.code === 0 && r.data) ? (r.data.list || []) : []
      } catch (e) { this.attachments = [] }
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
    async previewAtt (row) {
      if (['jpg', 'jpeg', 'png', 'gif', 'pdf'].includes(row.file_type)) {
        try {
          const resp = await downloadInAttachment(row.id)
          const url = window.URL.createObjectURL(new Blob([resp.data]))
          window.open(url, '_blank')
          setTimeout(() => window.URL.revokeObjectURL(url), 30000)
        } catch (e) { this.$message.error('预览失败') }
      } else {
        this.downloadAtt(row)
      }
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
    openReverse () {
      this.reverseReason = ''
      this.reverseVisible = true
    },
    async handleReverse () {
      if (!this.reverseReason.trim()) { this.$message.warning('请填写冲销原因'); return }
      this.reversing = true
      try {
        const r = await reversePurchaseIn(this.id, this.reverseReason)
        if (r.code === 0) { this.$message.success('冲销成功'); this.reverseVisible = false; this.load() } else this.$message.error(r.msg || '冲销失败')
      } catch (e) {} finally { this.reversing = false }
    },
    goArrival () { if (this.detail.arrival_id) this.$router.push('/business/purchase/arrival/detail/' + this.detail.arrival_id) },
    handleConfirm () {
      this.$confirm('确认入库将执行库存增加、流水记录与成本核算，确认继续吗？', '确认入库', { type: 'warning' }).then(() => this.doConfirm()).catch(() => {})
    },
    async doConfirm () {
      this.$message({ message: '正在处理入库，请稍候...', type: 'info', duration: 0 })
      this.confirming = true
      try {
        const r = await confirmPurchaseIn(this.id)
        this.$message.closeAll()
        if (r.code === 0) { this.$message.success(r.msg || '入库成功'); this.load() } else this.$message.error(r.msg || '入库失败')
      } catch (e) { this.$message.closeAll() } finally { this.confirming = false }
    },
    handlePrint () { window.print() }
  }
}
</script>

<style scoped>
.detail-page { padding: 16px; }
.breadcrumb { margin-bottom: 12px; }
.detail-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 14px; }
.detail-title { font-size: 18px; font-weight: 700; color: #303133; }
.info-card { margin-bottom: 14px; }
.card-head { font-size: 15px; font-weight: 600; }
.link { color: #409EFF; cursor: pointer; }
</style>
