<!--
  文件：admin/src/views/purchase/Inquiry.vue
  功能：询比价管理（列表/统计/新建编辑/发布关闭/删除/供应商报价/定标/转采购申请）
  权限：purchase:inquiry:view/add/edit/quote/win
-->
<template>
  <div class="inquiry-page">
    <el-breadcrumb separator="/" class="breadcrumb">
      <el-breadcrumb-item>经营管理</el-breadcrumb-item>
      <el-breadcrumb-item>采购管理</el-breadcrumb-item>
      <el-breadcrumb-item>询比价管理</el-breadcrumb-item>
    </el-breadcrumb>

    <!-- 统计卡 -->
    <el-row :gutter="12" class="stat-row">
      <el-col :xs="12" :sm="6">
        <div class="stat-card stat-total">
          <div class="stat-num">{{ stats.total }}</div>
          <div class="stat-label">询价单总数</div>
        </div>
      </el-col>
      <el-col :xs="12" :sm="6">
        <div class="stat-card stat-draft">
          <div class="stat-num">{{ stats.draft }}</div>
          <div class="stat-label">草稿</div>
        </div>
      </el-col>
      <el-col :xs="12" :sm="6">
        <div class="stat-card stat-active">
          <div class="stat-num">{{ stats.active }}</div>
          <div class="stat-label">询价中</div>
        </div>
      </el-col>
      <el-col :xs="12" :sm="6">
        <div class="stat-card stat-win">
          <div class="stat-num">{{ stats.win }}</div>
          <div class="stat-label">已定标</div>
        </div>
      </el-col>
    </el-row>

    <!-- 搜索 + 列表 -->
    <el-card shadow="never">
      <el-form inline size="small" label-width="60px" @submit.native.prevent>
        <el-form-item label="关键词">
          <el-input v-model="q.keyword" placeholder="单号/标题" clearable style="width:170px" @keyup.enter.native="handleSearch" />
        </el-form-item>
        <el-form-item label="状态">
          <el-select v-model="q.status" placeholder="全部" clearable style="width:110px" @change="handleSearch">
            <el-option label="全部" value="" />
            <el-option label="草稿" value="0" />
            <el-option label="询价中" value="1" />
            <el-option label="已定标" value="2" />
            <el-option label="已关闭" value="3" />
          </el-select>
        </el-form-item>
        <div class="filter-btns">
          <el-button type="primary" icon="el-icon-search" @click="handleSearch">搜索</el-button>
          <el-button icon="el-icon-refresh-left" @click="handleReset">重置</el-button>
        </div>
      </el-form>

      <div class="toolbar">
        <el-button v-permission="'purchase:inquiry:add'" type="primary" size="small" icon="el-icon-plus" @click="openEdit(null)">新建询价单</el-button>
        <el-button size="small" icon="el-icon-refresh" @click="getList">刷新</el-button>
        <span class="flex-1"></span>
        <span class="total-tip">共 {{ total }} 条</span>
      </div>

      <el-table :data="list" v-loading="loading" size="small" stripe border empty-text="暂无询价单数据">
        <el-table-column type="index" label="序号" width="50" align="center" />
        <el-table-column prop="inquiry_no" label="询价单号" width="150" show-overflow-tooltip>
          <template slot-scope="s"><span class="link-text" @click="viewDetail(s.row.id)">{{ s.row.inquiry_no }}</span></template>
        </el-table-column>
        <el-table-column prop="title" label="询价标题" min-width="160" show-overflow-tooltip>
          <template slot-scope="s"><span class="link-text" @click="viewDetail(s.row.id)">{{ s.row.title }}</span></template>
        </el-table-column>
        <el-table-column label="状态" width="90" align="center">
          <template slot-scope="s"><el-tag size="mini" :type="statusTag(s.row.status)">{{ s.row.status_text }}</el-tag></template>
        </el-table-column>
        <el-table-column prop="item_count" label="明细" width="60" align="center" />
        <el-table-column prop="quote_count" label="报价" width="60" align="center" />
        <el-table-column label="中标金额" width="110" align="right">
          <template slot-scope="s">
            <span v-if="s.row.status === 2" class="amount-win">¥ {{ s.row.amount_text }}</span>
            <span v-else class="amount-muted">-</span>
          </template>
        </el-table-column>
        <el-table-column prop="win_supplier_name" label="中标供应商" min-width="120" show-overflow-tooltip>
          <template slot-scope="s">{{ s.row.win_supplier_name || '-' }}</template>
        </el-table-column>
        <el-table-column prop="deadline" label="报价截止" width="100" align="center">
          <template slot-scope="s">
            <span v-if="s.row.deadline" :class="{ 'date-overdue': s.row.status === 1 && s.row.deadline < today }">{{ s.row.deadline }}</span>
            <span v-else>-</span>
          </template>
        </el-table-column>
        <el-table-column prop="create_by_name" label="创建人" width="80" align="center" />
        <el-table-column prop="created_at" label="创建时间" width="150" align="center" />
        <el-table-column label="操作" width="230" align="center" fixed="right">
          <template slot-scope="s">
            <el-button type="text" size="mini" @click="viewDetail(s.row.id)">详情</el-button>
            <el-button v-if="s.row.status === 0" v-permission="'purchase:inquiry:add'" type="text" size="mini" @click="openEdit(s.row)">编辑</el-button>
            <el-button v-if="s.row.status === 0" v-permission="'purchase:inquiry:edit'" type="text" size="mini" @click="changeStatus(s.row, 1)">发布</el-button>
            <el-button v-if="s.row.status === 1" v-permission="'purchase:inquiry:quote'" type="text" size="mini" @click="openQuote(s.row.id)">报价</el-button>
            <el-button v-if="s.row.status === 1" v-permission="'purchase:inquiry:edit'" type="text" size="mini" @click="changeStatus(s.row, 3)">关闭</el-button>
            <el-button v-if="s.row.status === 0" v-permission="'purchase:inquiry:edit'" type="text" size="mini" class="danger" @click="handleDelete(s.row)">删除</el-button>
            <el-button v-if="s.row.status === 2" v-permission="'purchase:inquiry:win'" type="text" size="mini" @click="toRequest(s.row)">转采购申请</el-button>
          </template>
        </el-table-column>
      </el-table>

      <el-pagination class="pager" background layout="total, sizes, prev, pager, next, jumper" :total="total" :page-sizes="[10, 20, 50, 100]" :page-size="q.pageSize" :current-page="q.page" @current-change="handlePageChange" @size-change="handleSizeChange" />
    </el-card>

    <!-- 新建/编辑弹窗 -->
    <el-dialog :title="editForm.id ? '编辑询价单' : '新建询价单'" :visible="editVisible" width="860px" :close-on-click-modal="false" @close="editVisible = false">
      <el-form ref="editForm" :model="editForm" :rules="editRules" label-width="90px" size="small">
        <el-row :gutter="16">
          <el-col :span="12">
            <el-form-item label="询价标题" prop="title">
              <el-input v-model="editForm.title" placeholder="如：2026年9月密封件采购询价" maxlength="100" />
            </el-form-item>
          </el-col>
          <el-col :span="6">
            <el-form-item label="报价截止">
              <el-date-picker v-model="editForm.deadline" type="date" value-format="yyyy-MM-dd" placeholder="选择截止日期" style="width:100%" />
            </el-form-item>
          </el-col>
          <el-col :span="6">
            <el-form-item label="备注">
              <el-input v-model="editForm.remark" placeholder="备注" maxlength="200" />
            </el-form-item>
          </el-col>
        </el-row>
        <el-form-item label="询价明细" required>
          <div class="items-editor">
            <div v-for="(it, i) in editForm.items" :key="i" class="item-row">
              <el-select v-model="it.material_id" filterable placeholder="选择物料" style="width:200px" @change="v => onMaterialChange(i, v)">
                <el-option v-for="m in materialOptions" :key="m.id" :label="m.material_name + (m.specification ? ' / ' + m.specification : '')" :value="m.id">
                  <span>{{ m.material_code }} {{ m.material_name }}</span>
                  <span v-if="m.specification" class="opt-spec">{{ m.specification }}</span>
                </el-option>
              </el-select>
              <span v-if="it.material_code" class="item-code">{{ it.material_code }}</span>
              <el-input-number v-model="it.quantity" :min="0.01" :precision="2" :step="1" controls-position="right" style="width:120px" placeholder="数量" />
              <span class="unit-text">{{ it.unit }}</span>
              <el-input v-model="it.remark" placeholder="明细备注（选填）" style="width:180px" />
              <el-button type="text" class="danger" icon="el-icon-delete" @click="removeItem(i)" />
            </div>
            <el-button type="dashed" icon="el-icon-plus" size="small" @click="addItem">添加明细</el-button>
          </div>
        </el-form-item>
      </el-form>
      <div slot="footer">
        <el-button size="small" @click="editVisible = false">取消</el-button>
        <el-button type="primary" size="small" :loading="saving" @click="handleSave">保存询价单</el-button>
      </div>
    </el-dialog>

    <!-- 详情抽屉 -->
    <el-drawer title="询价单详情" :visible="detailVisible" size="720px" :close-on-click-modal="false" @close="detailVisible = false">
      <div v-if="detail" class="detail-body">
        <div class="detail-head">
          <div class="detail-title">{{ detail.inquiry_no }}</div>
          <el-tag size="small" :type="statusTag(detail.status)">{{ detail.status_text }}</el-tag>
        </div>
        <div class="detail-meta">
          <div><label>标题：</label>{{ detail.title }}</div>
          <div><label>报价截止：</label>{{ detail.deadline || '-' }}</div>
          <div><label>创建人：</label>{{ detail.create_by_name }} <span class="muted">（{{ detail.created_at }}）</span></div>
          <div v-if="detail.win_supplier_name"><label>中标供应商：</label><span class="win-text">{{ detail.win_supplier_name }}</span></div>
          <div v-if="detail.remark"><label>备注：</label>{{ detail.remark }}</div>
        </div>

        <h4 class="section-title">询价明细</h4>
        <el-table :data="detail.items" size="small" border>
          <el-table-column type="index" label="#" width="40" align="center" />
          <el-table-column prop="material_code" label="物料编码" width="110" />
          <el-table-column prop="material_name" label="物料名称" min-width="110" />
          <el-table-column prop="specification" label="规格型号" min-width="100" />
          <el-table-column prop="unit" label="单位" width="60" align="center" />
          <el-table-column prop="quantity" label="数量" width="80" align="right" />
          <el-table-column prop="remark" label="备注" min-width="100" show-overflow-tooltip />
        </el-table>

        <div class="section-head">
          <h4 class="section-title">供应商报价</h4>
          <el-button v-if="detail.status === 1" v-permission="'purchase:inquiry:quote'" type="primary" size="mini" icon="el-icon-plus" @click="openQuote(detail.id)">新增报价</el-button>
        </div>
        <el-table :data="detail.quotes" size="small" border empty-text="暂无报价">
          <el-table-column type="index" label="#" width="40" align="center" />
          <el-table-column prop="supplier_name" label="供应商" min-width="130" />
          <el-table-column prop="quote_no" label="报价单号" width="150" show-overflow-tooltip />
          <el-table-column label="报价金额" width="110" align="right">
            <template slot-scope="s">
              <span :class="{ 'win-text': s.row.is_win === 1 }">¥ {{ Number(s.row.total_amount).toLocaleString() }}</span>
            </template>
          </el-table-column>
          <el-table-column prop="delivery_days" label="交期(天)" width="70" align="center" />
          <el-table-column prop="quote_time" label="报价时间" width="140" align="center" />
          <el-table-column prop="remark" label="备注" min-width="80" show-overflow-tooltip />
          <el-table-column label="操作" width="90" align="center">
            <template slot-scope="s">
              <el-button v-if="detail.status === 1" v-permission="'purchase:inquiry:win'" type="text" size="mini" class="win-btn" @click="handleSelect(detail.id, s.row)">定标</el-button>
              <el-tag v-if="s.row.is_win === 1" size="mini" type="success">中标</el-tag>
            </template>
          </el-table-column>
        </el-table>

        <div v-if="detail.status === 2" class="detail-foot">
          <el-button type="primary" v-permission="'purchase:inquiry:win'" icon="el-icon-s-order" :loading="converting" @click="toRequest({ id: detail.id, inquiry_no: detail.inquiry_no })">生成采购申请</el-button>
        </div>
      </div>
    </el-drawer>

    <!-- 报价弹窗 -->
    <el-dialog title="提交供应商报价" :visible="quoteVisible" width="480px" :close-on-click-modal="false" @close="quoteVisible = false">
      <el-form ref="quoteForm" :model="quoteForm" :rules="quoteRules" label-width="100px" size="small">
        <el-form-item label="供应商" prop="supplier_id">
          <el-select v-model="quoteForm.supplier_id" filterable placeholder="选择供应商" style="width:100%">
            <el-option v-for="s in detailSuppliers" :key="s.id" :label="s.supplier_name" :value="s.id" />
          </el-select>
        </el-form-item>
        <el-form-item label="报价金额" prop="total_amount">
          <el-input-number v-model="quoteForm.total_amount" :min="0.01" :precision="2" :step="100" controls-position="right" style="width:100%" placeholder="报价总金额" />
        </el-form-item>
        <el-form-item label="交付周期">
          <el-input-number v-model="quoteForm.delivery_days" :min="0" :step="1" controls-position="right" style="width:100%" />
        </el-form-item>
        <el-form-item label="备注">
          <el-input v-model="quoteForm.remark" type="textarea" :rows="2" placeholder="付款方式、质保等（选填）" maxlength="200" />
        </el-form-item>
      </el-form>
      <div slot="footer">
        <el-button size="small" @click="quoteVisible = false">取消</el-button>
        <el-button type="primary" size="small" :loading="quoting" @click="handleQuote">提交报价</el-button>
      </div>
    </el-dialog>
  </div>
</template>

<script>
import request from '../../api/request'

const STATUS_TEXT = ['草稿', '询价中', '已定标', '已关闭']

export default {
  name: 'PurchaseInquiry',
  data() {
    return {
      loading: false,
      saving: false,
      quoting: false,
      converting: false,
      list: [],
      total: 0,
      stats: { total: 0, draft: 0, active: 0, win: 0 },
      today: new Date().toISOString().slice(0, 10),
      q: { page: 1, pageSize: 10, keyword: '', status: '' },
      editVisible: false,
      editForm: { id: 0, title: '', deadline: '', remark: '', items: [] },
      editRules: {
        title: [{ required: true, message: '请输入询价标题', trigger: 'blur' }]
      },
      materialOptions: [],
      detailVisible: false,
      detail: null,
      detailSuppliers: [],
      quoteVisible: false,
      quoteForm: { inquiry_id: 0, supplier_id: null, total_amount: 0, delivery_days: 7, remark: '' },
      quoteRules: {
        supplier_id: [{ required: true, message: '请选择供应商', trigger: 'change' }],
        total_amount: [{ required: true, message: '请输入报价金额', trigger: 'blur' }]
      }
    }
  },
  created() {
    this.getList()
  },
  methods: {
    statusTag(s) {
      return ['info', 'warning', 'success', 'danger'][s] || 'info'
    },
    getList() {
      this.loading = true
      request({ url: '/inquiry/list', method: 'get', params: { page: this.q.page, limit: this.q.pageSize, keyword: this.q.keyword, status: this.q.status } })
        .then(res => {
          this.list = res.data.list || []
          this.total = res.data.total || 0
          this.stats = res.data.stats || { total: 0, draft: 0, active: 0, win: 0 }
        })
        .finally(() => { this.loading = false })
    },
    handleSearch() { this.q.page = 1; this.getList() },
    handleReset() { this.q = { page: 1, pageSize: 10, keyword: '', status: '' }; this.getList() },
    handlePageChange(p) { this.q.page = p; this.getList() },
    handleSizeChange(s) { this.q.pageSize = s; this.q.page = 1; this.getList() },
    openEdit(row) {
      if (row && row.id) {
        this.editForm = { id: row.id, title: row.title, deadline: row.deadline || '', remark: row.remark || '', items: [] }
        request({ url: `/inquiry/detail/${row.id}`, method: 'get' }).then(res => {
          this.materialOptions = res.data.materials || []
          this.editForm.items = (res.data.items || []).map(x => ({
            material_id: x.material_id, quantity: Number(x.quantity), remark: x.remark || '', material_code: x.material_code, unit: x.unit
          }))
          this.editVisible = true
        })
      } else {
        this.editForm = { id: 0, title: '', deadline: '', remark: '', items: [{ material_id: null, quantity: 1, remark: '' }] }
        if (!this.materialOptions.length) {
          this.loadMaterials()
        }
        this.editVisible = true
      }
    },
    loadMaterials() {
      request({ url: '/inquiry/materials', method: 'get' }).then(res => {
        if (res && res.data && res.data.list) {
          this.materialOptions = res.data.list
        }
      }).catch(() => {})
    },
    addItem() { this.editForm.items.push({ material_id: null, quantity: 1, remark: '' }) },
    removeItem(i) { this.editForm.items.splice(i, 1) },
    onMaterialChange(i, v) {
      const m = this.materialOptions.find(x => x.id === v)
      if (m) {
        this.editForm.items[i].material_code = m.material_code
        this.editForm.items[i].unit = m.unit
      }
    },
    handleSave() {
      this.$refs.editForm.validate(ok => {
        if (!ok) return
        const validItems = this.editForm.items.filter(x => x.material_id && Number(x.quantity) > 0)
        if (!validItems.length) { this.$message.warning('请至少添加一条有效的询价明细'); return }
        this.saving = true
        request({ url: '/inquiry/save', method: 'post', data: { id: this.editForm.id, title: this.editForm.title, deadline: this.editForm.deadline, remark: this.editForm.remark, items: validItems } })
          .then(() => {
            this.$message.success(this.editForm.id ? '询价单已更新' : '询价单已创建')
            this.editVisible = false
            this.getList()
          })
          .finally(() => { this.saving = false })
      })
    },
    changeStatus(row, status) {
      const act = status === 1 ? '发布' : '关闭'
      this.$confirm(`确定${act}询价单「${row.inquiry_no}」？`, '提示', { type: 'warning' }).then(() => {
        request({ url: '/inquiry/status', method: 'post', data: { id: row.id, status } })
          .then(() => { this.$message.success(`询价单已${STATUS_TEXT[status]}`); this.getList() })
      }).catch(() => {})
    },
    handleDelete(row) {
      this.$confirm(`确定删除草稿询价单「${row.inquiry_no}」？删除后不可恢复。`, '提示', { type: 'warning' }).then(() => {
        request({ url: `/inquiry/delete/${row.id}`, method: 'post' })
          .then(() => { this.$message.success('询价单已删除'); this.getList() })
      }).catch(() => {})
    },
    viewDetail(id) {
      request({ url: `/inquiry/detail/${id}`, method: 'get' }).then(res => {
        this.detail = res.data.inquiry
        this.detail.items = res.data.items || []
        this.detail.quotes = res.data.quotes || []
        this.detailSuppliers = res.data.suppliers || []
        this.materialOptions = res.data.materials || []
        this.detailVisible = true
      })
    },
    openQuote(inquiryId) {
      this.quoteForm = { inquiry_id: inquiryId, supplier_id: null, total_amount: 0, delivery_days: 7, remark: '' }
      this.quoteVisible = true
      if (!this.detailSuppliers.length) {
        request({ url: '/inquiry/suppliers', method: 'get' }).then(res => {
          if (res && res.data && res.data.list) this.detailSuppliers = res.data.list
        }).catch(() => {})
      }
    },
    handleQuote() {
      this.$refs.quoteForm.validate(ok => {
        if (!ok) return
        if (Number(this.quoteForm.total_amount) <= 0) { this.$message.warning('报价金额必须大于 0'); return }
        this.quoting = true
        request({ url: '/inquiry/quote', method: 'post', data: { ...this.quoteForm } })
          .then(() => {
            this.$message.success('报价提交成功')
            this.quoteVisible = false
            this.viewDetail(this.quoteForm.inquiry_id)
          })
          .finally(() => { this.quoting = false })
      })
    },
    handleSelect(inquiryId, quote) {
      this.$confirm(`确定选定「${quote.supplier_name}」为中标供应商？`, '定标确认', { type: 'warning' }).then(() => {
        request({ url: '/inquiry/select', method: 'post', data: { inquiry_id: inquiryId, quote_id: quote.id } })
          .then(() => { this.$message.success('定标成功'); this.viewDetail(inquiryId); this.getList() })
      }).catch(() => {})
    },
    toRequest(row) {
      this.$confirm(`确定将询价单「${row.inquiry_no}」转为采购申请？`, '提示', { type: 'warning' }).then(() => {
        this.converting = true
        request({ url: '/inquiry/to-request', method: 'post', data: { inquiry_id: row.id } })
          .then(res => {
            this.$message.success(res.msg || '采购申请已生成')
            this.detailVisible = false
            this.getList()
          })
          .finally(() => { this.converting = false })
      }).catch(() => {})
    }
  }
}
</script>

<style scoped>
.breadcrumb { margin-bottom: 12px; }
.stat-row { margin-bottom: 12px; }
.stat-card { border-radius: 10px; padding: 16px 18px; color: #fff; background: linear-gradient(135deg, #3a7afe, #5a9cff); }
.stat-num { font-size: 26px; font-weight: 700; line-height: 1.2; }
.stat-label { font-size: 12px; opacity: .9; margin-top: 4px; }
.stat-draft { background: linear-gradient(135deg, #909399, #b1b3b8); }
.stat-active { background: linear-gradient(135deg, #e6a23c, #f0b453); }
.stat-win { background: linear-gradient(135deg, #52c41a, #74d84a); }
.toolbar { display: flex; align-items: center; margin-bottom: 12px; }
.flex-1 { flex: 1; }
.total-tip { color: #909399; font-size: 12px; }
.filter-btns { display: inline-block; }
.pager { margin-top: 12px; text-align: right; }
.link-text { color: #3a7afe; cursor: pointer; }
.link-text:hover { text-decoration: underline; }
.amount-win { color: #52c41a; font-weight: 600; }
.amount-muted { color: #c0c4cc; }
.date-overdue { color: #f56c6c; font-weight: 600; }
.danger { color: #f56c6c !important; }
.items-editor { width: 100%; }
.item-row { display: flex; align-items: center; gap: 8px; margin-bottom: 8px; }
.opt-spec { float: right; color: #909399; font-size: 12px; margin-left: 12px; }
.item-code { color: #909399; font-size: 12px; width: 90px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.unit-text { color: #909399; font-size: 12px; width: 28px; }
.detail-body { padding: 4px 8px; }
.detail-head { display: flex; align-items: center; gap: 10px; margin-bottom: 12px; }
.detail-title { font-size: 18px; font-weight: 700; }
.detail-meta { background: #f7f8fa; border-radius: 8px; padding: 10px 14px; font-size: 13px; color: #303133; margin-bottom: 8px; }
.detail-meta div { margin: 4px 0; }
.detail-meta label { color: #909399; }
.muted { color: #c0c4cc; }
.win-text { color: #52c41a; font-weight: 700; }
.section-title { margin: 14px 0 8px; font-size: 14px; color: #303133; }
.section-head { display: flex; align-items: center; justify-content: space-between; }
.win-btn { color: #e6a23c; }
.detail-foot { margin-top: 16px; text-align: right; }
</style>
