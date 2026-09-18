<template>
  <div class="pa-page">
    <el-breadcrumb separator="/" class="pa-breadcrumb">
      <el-breadcrumb-item>个人资产</el-breadcrumb-item>
      <el-breadcrumb-item>资产详情</el-breadcrumb-item>
      <el-breadcrumb-item>我的资产</el-breadcrumb-item>
    </el-breadcrumb>

    <!-- 提示横幅 -->
    <div v-if="showBanner" class="pa-banner">
      <i class="el-icon-info pa-banner-icon"></i>
      <span class="pa-banner-text">个人资产：公司所有、记在个人名下、由个人负责保管的物资。如有疑问请联系资产管理员。</span>
      <i class="el-icon-close pa-banner-close" @click="closeBanner"></i>
    </div>

    <!-- 统计卡片 -->
    <div class="pa-stats">
      <div class="pa-stat-card">
        <div class="pa-stat-info">
          <div class="pa-stat-num">{{ stats.total_quantity }}</div>
          <div class="pa-stat-label">总数量</div>
        </div>
        <div class="pa-stat-icon" style="background:#ecf5ff"><i class="el-icon-box" style="color:#409EFF"></i></div>
      </div>
      <div class="pa-stat-card">
        <div class="pa-stat-info">
          <div class="pa-stat-num">{{ stats.total_types }}</div>
          <div class="pa-stat-label">总种类</div>
        </div>
        <div class="pa-stat-icon" style="background:#f0f9eb"><i class="el-icon-document" style="color:#67C23A"></i></div>
      </div>
      <div class="pa-stat-card">
        <div class="pa-stat-info">
          <div class="pa-stat-num">{{ stats.part_count }}</div>
          <div class="pa-stat-label">配件</div>
        </div>
        <div class="pa-stat-icon" style="background:#fdf6ec"><i class="el-icon-s-tools" style="color:#E6A23C"></i></div>
      </div>
      <div class="pa-stat-card">
        <div class="pa-stat-info">
          <div class="pa-stat-num">{{ stats.asset_count }}</div>
          <div class="pa-stat-label">固定资产</div>
        </div>
        <div class="pa-stat-icon" style="background:#f5f0fa"><i class="el-icon-monitor" style="color:#9B59B6"></i></div>
      </div>
    </div>

    <!-- 搜索筛选 -->
    <div class="pa-filter">
      <el-form inline size="small" @submit.native.prevent>
        <el-form-item label="资产名称">
          <el-input v-model="query.keyword" placeholder="请输入资产名称" clearable style="width:180px" @keyup.enter.native="handleSearch" />
        </el-form-item>
        <el-form-item label="资产类型">
          <el-select v-model="query.asset_type" clearable placeholder="全部类型" style="width:130px" @change="handleSearch">
            <el-option label="物料/配件" :value="1" />
            <el-option label="固定资产" :value="2" />
            <el-option label="工具" :value="3" />
          </el-select>
        </el-form-item>
        <el-form-item label="资产状态">
          <el-select v-model="query.asset_status" clearable placeholder="全部状态" style="width:130px" @change="handleSearch">
            <el-option label="正常" :value="1" />
            <el-option label="维修中" :value="2" />
            <el-option label="闲置" :value="3" />
            <el-option label="待报废" :value="4" />
          </el-select>
        </el-form-item>
        <el-form-item label="来源类型">
          <el-select v-model="query.source_type" clearable placeholder="全部来源" style="width:140px" @change="handleSearch">
            <el-option label="总仓领料" :value="1" />
            <el-option label="资产领用" :value="2" />
            <el-option label="调拨转入" :value="3" />
            <el-option label="盘点入库" :value="4" />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-button type="primary" icon="el-icon-search" @click="handleSearch">搜索</el-button>
          <el-button icon="el-icon-refresh-left" @click="handleReset">重置</el-button>
        </el-form-item>
      </el-form>
    </div>

    <!-- 操作栏 -->
    <div class="pa-toolbar">
      <el-button size="small" icon="el-icon-refresh" :loading="loading" @click="getList">刷新</el-button>
      <span class="pa-total">共 {{ total }} 条</span>
    </div>

    <!-- 资产卡片列表 -->
    <div v-loading="loading" class="pa-card-list">
      <template v-if="list.length">
        <div v-for="item in list" :key="item.id" class="pa-card" @click="openDetail(item)">
          <div class="pa-card-left">
            <div class="pa-card-name-row">
              <span class="pa-type-tag" :class="'type-' + item.asset_type">{{ item.asset_type_label }}</span>
              <span class="pa-card-name">{{ item.asset_name }}</span>
              <span v-if="item.specification" class="pa-card-spec">{{ item.specification }}</span>
            </div>
            <div class="pa-card-code">编码：{{ item.asset_code || '-' }}</div>
            <div class="pa-card-qty">
              <span class="pa-qty-num">{{ item.quantity }}</span> {{ item.unit }}
            </div>
            <div class="pa-card-location">
              <i class="el-icon-location-outline pa-location-icon"></i>
              <span v-if="item.location" class="pa-location-text">{{ item.location }}</span>
              <span v-else class="pa-location-empty">未设置位置</span>
              <el-button type="text" size="mini" class="pa-location-edit" @click.stop="handleEditLocation(item)">✏️</el-button>
            </div>
            <div class="pa-card-source">来源：{{ item.source_type_label }} / {{ item.source_no || '-' }}</div>
            <div v-if="item.supplier_name || item.purchase_order_no" class="pa-card-purchase">
              <span class="pa-purchase-label">采购信息：</span>
              <template v-if="item.supplier_name"><span class="pa-purchase-val">{{ item.supplier_name }}</span>　</template>
              <template v-if="item.purchase_order_no"><span class="pa-purchase-val">{{ item.purchase_order_no }}</span></template>
              <span v-if="item.warranty_end_date" class="pa-purchase-warranty">保修至{{ item.warranty_end_date }}</span>
            </div>
            <div class="pa-card-time">入库：{{ formatDate(item.created_at) }}</div>
          </div>
          <div class="pa-card-right">
            <span class="pa-status-tag" :class="'status-' + item.asset_status">{{ item.asset_status_label }}</span>
            <div class="pa-card-actions" @click.stop>
              <el-button v-if="item.can_transfer" type="text" size="mini" @click="handleTransfer(item)">调拨</el-button>
              <el-button v-if="item.can_return" type="text" size="mini" @click="goReturn(item)">退还</el-button>
            </div>
          </div>
        </div>
      </template>

      <!-- 空状态 -->
      <div v-else class="pa-empty">
        <i class="el-icon-box pa-empty-icon"></i>
        <div class="pa-empty-title">{{ isFiltered ? '未找到匹配资产' : '暂无资产' }}</div>
        <div class="pa-empty-desc">{{ isFiltered ? '请调整搜索条件后重试。' : '您名下暂无资产，请从总仓领用或申请资产领用。' }}</div>
        <el-button v-if="isFiltered" type="primary" @click="handleReset">重置筛选</el-button>
        <el-button v-else type="primary" @click="goApply">去领用</el-button>
      </div>
    </div>

    <!-- 分页 -->
    <div class="pa-pagination">
      <el-pagination background layout="total, sizes, prev, pager, next, jumper"
        :total="total" :current-page="page" :page-size="limit" :page-sizes="[10, 20, 50, 100]"
        @current-change="handlePageChange" @size-change="handleSizeChange" />
    </div>

    <!-- 资产详情弹窗 -->
    <el-dialog :title="'资产详情 - ' + (detail.asset_name || '')" :visible.sync="detailVisible" width="600px">
      <div v-loading="detailLoading" class="pa-detail-body">
        <template v-if="detail.id">
          <div class="pa-detail-section">
            <div class="pa-detail-title">基本信息</div>
            <div class="pa-detail-grid">
              <div class="pa-detail-item"><span class="pa-detail-lb">资产名称</span>{{ detail.asset_name || '-' }}</div>
              <div class="pa-detail-item"><span class="pa-detail-lb">规格型号</span>{{ detail.specification || '-' }}</div>
              <div class="pa-detail-item"><span class="pa-detail-lb">资产编码</span>{{ detail.asset_code || '-' }}</div>
              <div class="pa-detail-item">
                <span class="pa-detail-lb">类型</span>
                <span class="pa-type-tag" :class="'type-' + detail.asset_type">{{ detail.asset_type_label }}</span>
              </div>
              <div class="pa-detail-item">
                <span class="pa-detail-lb">状态</span>
                <span class="pa-status-tag" :class="'status-' + detail.asset_status">{{ detail.asset_status_label }}</span>
              </div>
              <div class="pa-detail-item"><span class="pa-detail-lb">品牌</span>{{ detail.brand || '-' }}</div>
              <div class="pa-detail-item"><span class="pa-detail-lb">存放位置</span>{{ detail.location || '未设置' }}</div>
            </div>
          </div>
          <div v-if="detail.supplier_name || detail.purchase_order_no || detail.warehouse_in_no" class="pa-detail-section">
            <div class="pa-detail-title">📦 采购信息</div>
            <div class="pa-detail-grid">
              <div class="pa-detail-item"><span class="pa-detail-lb">供应商</span>{{ detail.supplier_name || '-' }}</div>
              <div class="pa-detail-item"><span class="pa-detail-lb">采购单号</span>{{ detail.purchase_order_no || '-' }}</div>
              <div class="pa-detail-item"><span class="pa-detail-lb">采购日期</span>{{ detail.purchase_date || '-' }}</div>
              <div class="pa-detail-item"><span class="pa-detail-lb">保修期</span>{{ detail.warranty_period ? detail.warranty_period + '个月' : '-' }}</div>
              <div class="pa-detail-item"><span class="pa-detail-lb">保修截止</span>{{ detail.warranty_end_date || '-' }}</div>
              <div class="pa-detail-item"><span class="pa-detail-lb">入库单号</span>{{ detail.warehouse_in_no || '-' }}</div>
            </div>
          </div>
          <div v-if="detail.production_order_no || detail.project_name" class="pa-detail-section">
            <div class="pa-detail-title">🔗 关联单据</div>
            <div class="pa-detail-grid">
              <div class="pa-detail-item"><span class="pa-detail-lb">关联工单</span>{{ detail.production_order_no || '-' }}</div>
              <div class="pa-detail-item"><span class="pa-detail-lb">关联项目</span>{{ detail.project_name || detail.project_no || '-' }}</div>
            </div>
          </div>
          <div class="pa-detail-section">
            <div class="pa-detail-title">数量信息</div>
            <div class="pa-detail-grid">
              <div class="pa-detail-item"><span class="pa-detail-lb">当前数量</span>{{ detail.quantity }} {{ detail.unit }}</div>
              <div class="pa-detail-item"><span class="pa-detail-lb">单位</span>{{ detail.unit || '-' }}</div>
              <div class="pa-detail-item"><span class="pa-detail-lb">初始数量</span>{{ detail.initial_quantity }}</div>
            </div>
          </div>
          <div class="pa-detail-section">
            <div class="pa-detail-title">来源信息</div>
            <div class="pa-detail-grid">
              <div class="pa-detail-item"><span class="pa-detail-lb">来源类型</span>{{ detail.source_type_label }}</div>
              <div class="pa-detail-item"><span class="pa-detail-lb">来源单号</span>{{ detail.source_no || '-' }}</div>
              <div class="pa-detail-item"><span class="pa-detail-lb">来源日期</span>{{ formatDate(detail.created_at) }}</div>
            </div>
          </div>
          <div v-if="detail.asset_type === 2" class="pa-detail-section">
            <div class="pa-detail-title">资产信息</div>
            <div class="pa-detail-grid">
              <div class="pa-detail-item"><span class="pa-detail-lb">原值</span>{{ detail.original_value != null ? '¥ ' + detail.original_value : '-' }}</div>
            </div>
          </div>
          <div v-if="detail.remark" class="pa-detail-section">
            <div class="pa-detail-title">备注</div>
            <div class="pa-detail-remark">{{ detail.remark }}</div>
          </div>
        </template>
      </div>
      <div slot="footer">
        <el-button v-if="detail.can_transfer" size="small" type="primary" plain @click="handleTransfer(detail)">调拨</el-button>
        <el-button v-if="detail.can_return" size="small" @click="goReturn(detail)">退还</el-button>
        <el-button size="small" @click="detailVisible = false">关闭</el-button>
      </div>
    </el-dialog>

    <!-- 调拨弹窗 -->
    <el-dialog title="调拨资产" :visible.sync="transferVisible" width="460px">
      <el-form label-width="90px" size="small">
        <el-form-item label="资产名称"><span>{{ currentAsset.asset_name }}（{{ currentAsset.asset_code }}）</span></el-form-item>
        <el-form-item label="当前数量"><span>{{ currentAsset.quantity }} {{ currentAsset.unit }}</span></el-form-item>
        <el-form-item label="调拨对象" required>
          <el-select v-model="transferForm.to_user_id" filterable remote :remote-method="searchEmployees" :loading="empLoading" placeholder="搜索员工姓名/工号" style="width:100%">
            <el-option v-for="e in employeeOptions" :key="e.user_id" :label="e.name + '（' + (e.employee_id || '-') + '）'" :value="e.user_id" />
          </el-select>
        </el-form-item>
        <el-form-item label="调拨数量" required>
          <el-input-number v-model="transferForm.quantity" :min="0.5" :step="0.5" :max="Number(currentAsset.quantity)" :precision="1" style="width:180px" />
        </el-form-item>
        <el-form-item label="备注">
          <el-input v-model="transferForm.remark" type="textarea" :rows="2" placeholder="请输入备注" />
        </el-form-item>
      </el-form>
      <div slot="footer">
        <el-button size="small" @click="transferVisible = false">取消</el-button>
        <el-button size="small" type="primary" :loading="submitting" @click="submitTransfer">确定</el-button>
      </div>
    </el-dialog>

    <!-- 位置编辑弹窗 -->
    <el-dialog :title="(locationForm.id ? '修改' : '设置') + '存放位置'" :visible.sync="locationVisible" width="400px">
      <el-form label-width="80px" size="small">
        <el-form-item label="资产名称"><span>{{ locationForm.asset_name }}{{ locationForm.asset_code ? '（' + locationForm.asset_code + '）' : '' }}</span></el-form-item>
        <el-form-item label="存放位置">
          <el-input v-model="locationForm.location" placeholder="请输入存放位置，如：机加二车间工具柜" maxlength="100" show-word-limit />
        </el-form-item>
      </el-form>
      <div slot="footer">
        <el-button size="small" @click="locationVisible = false">取消</el-button>
        <el-button size="small" type="primary" :loading="locationSaving" @click="submitLocation">保存</el-button>
      </div>
    </el-dialog>
  </div>
</template>

<script>
import { getMyAssetList, getMyAssetDetail, getAssetEmployeeOptions, transferAsset, updateAssetLocation } from '../../api/personalAssets'

export default {
  name: 'PersonalAssetsMyList',
  data () {
    return {
      showBanner: localStorage.getItem('pa_banner_closed') !== '1',
      stats: { total_quantity: 0, total_types: 0, part_count: 0, asset_count: 0 },
      list: [], total: 0, page: 1, limit: 20, loading: false,
      query: { keyword: '', asset_type: '', asset_status: '', source_type: '' },
      detailVisible: false, detailLoading: false, detail: {},
      isFiltered: false,
      // 操作弹窗
      transferVisible: false,
      currentAsset: {}, submitting: false,
      transferForm: { to_user_id: '', quantity: 1, remark: '' },
      employeeOptions: [], empLoading: false,
      // 位置编辑
      locationVisible: false, locationSaving: false,
      locationForm: { id: 0, asset_name: '', asset_code: '', location: '' }
    }
  },
  created () { this.getList() },
  methods: {
    closeBanner () {
      this.showBanner = false
      localStorage.setItem('pa_banner_closed', '1')
    },
    formatDate (t) { return t ? String(t).slice(0, 10) : '-' },
    buildParams () {
      const p = { page: this.page, limit: this.limit }
      if (this.query.keyword) p.keyword = this.query.keyword
      if (this.query.asset_type !== '' && this.query.asset_type != null) p.asset_type = this.query.asset_type
      if (this.query.asset_status !== '' && this.query.asset_status != null) p.asset_status = this.query.asset_status
      if (this.query.source_type !== '' && this.query.source_type != null) p.source_type = this.query.source_type
      return p
    },
    async getList () {
      this.loading = true
      try {
        const r = await getMyAssetList(this.buildParams())
        if (r.code === 0) {
          this.list = r.data.list || []
          this.total = r.data.total || 0
          this.stats = r.data.statistics || { total_quantity: 0, total_types: 0, part_count: 0, asset_count: 0 }
          this.isFiltered = !!(this.query.keyword || this.query.asset_type || this.query.asset_status || this.query.source_type)
        }
      } catch (e) {}
      this.loading = false
    },
    handleSearch () { this.page = 1; this.getList() },
    handleReset () {
      this.query = { keyword: '', asset_type: '', asset_status: '', source_type: '' }
      this.page = 1
      this.getList()
    },
    handlePageChange (p) { this.page = p; this.getList() },
    handleSizeChange (s) { this.limit = s; this.page = 1; this.getList() },
    async openDetail (item) {
      this.detailVisible = true
      this.detail = {}
      this.detailLoading = true
      try {
        const r = await getMyAssetDetail(item.id)
        if (r.code === 0) this.detail = r.data
      } catch (e) {}
      this.detailLoading = false
    },
    handleTransfer (item) {
      this.currentAsset = item
      this.transferForm = { to_user_id: '', quantity: 1, remark: '' }
      this.employeeOptions = []
      this.transferVisible = true
    },
    async searchEmployees (kw) {
      this.empLoading = true
      try {
        const r = await getAssetEmployeeOptions(kw || '')
        if (r.code === 0) this.employeeOptions = r.data || []
      } catch (e) {}
      this.empLoading = false
    },
    async submitTransfer () {
      if (!this.transferForm.to_user_id) { this.$message.warning('请选择调拨对象'); return }
      if (!this.transferForm.quantity || this.transferForm.quantity <= 0) { this.$message.warning('请输入调拨数量'); return }
      this.submitting = true
      try {
        const r = await transferAsset({ asset_id: this.currentAsset.id, to_user_id: this.transferForm.to_user_id, quantity: this.transferForm.quantity, remark: this.transferForm.remark })
        if (r.code === 0) { this.$message.success('调拨成功'); this.transferVisible = false; this.getList() }
      } catch (e) {}
      this.submitting = false
    },
    goReturn (item) {
      this.$router.push('/personal-assets/return-apply?asset_id=' + item.id)
    },
    handleEditLocation (item) {
      this.locationForm = { id: item.id, asset_name: item.asset_name, asset_code: item.asset_code || '', location: item.location || '' }
      this.locationVisible = true
    },
    async submitLocation () {
      this.locationSaving = true
      try {
        const r = await updateAssetLocation({ asset_id: this.locationForm.id, location: this.locationForm.location })
        if (r.code === 0) { this.$message.success(r.msg || '位置更新成功'); this.locationVisible = false; this.getList() }
      } catch (e) {}
      this.locationSaving = false
    },
    goApply () { this.$router.push('/personal-assets/asset-apply/create') }
  }
}
</script>

<style scoped>
.pa-page { padding: 16px; background: #f0f2f5; min-height: 100vh; }
.pa-breadcrumb { margin-bottom: 12px; }

/* 提示横幅 */
.pa-banner { display: flex; align-items: center; background: #ecf5ff; border: 1px solid #d9ecff; border-radius: 4px; padding: 12px 16px; margin-bottom: 16px; }
.pa-banner-icon { color: #409EFF; font-size: 16px; margin-right: 8px; }
.pa-banner-text { flex: 1; font-size: 14px; color: #5a6b7f; }
.pa-banner-close { color: #909399; cursor: pointer; font-size: 14px; }

/* 统计卡片 */
.pa-stats { display: grid; grid-template-columns: repeat(4, 1fr); gap: 16px; margin-bottom: 16px; }
.pa-stat-card { background: #fff; border-radius: 8px; padding: 18px 20px; border: 1px solid #ebeef5; box-shadow: 0 2px 8px rgba(31,45,61,.04); display: flex; align-items: center; justify-content: space-between; }
.pa-stat-num { font-size: 22px; font-weight: 700; color: #1f2d3d; }
.pa-stat-label { font-size: 13px; color: #909399; margin-top: 2px; }
.pa-stat-icon { width: 36px; height: 36px; border-radius: 50%; display: flex; align-items: center; justify-content: center; font-size: 18px; }

/* 筛选 */
.pa-filter { background: #fff; border-radius: 8px; padding: 16px 16px 0; margin-bottom: 12px; }
.pa-filter .el-form-item { margin-bottom: 16px; margin-right: 16px; }
.pa-filter .el-form-item__label { color: #606266; font-size: 13px; width: 70px; }

/* 操作栏 */
.pa-toolbar { display: flex; align-items: center; margin-bottom: 12px; }
.pa-total { margin-left: 12px; color: #909399; font-size: 13px; }

/* 卡片列表 */
.pa-card-list { display: grid; grid-template-columns: 1fr 1fr; gap: 16px; min-height: 120px; }
.pa-card { background: #fff; border-radius: 12px; padding: 16px 18px; border: 1px solid #ebeef5; box-shadow: 0 2px 8px rgba(31,45,61,.04); display: flex; justify-content: space-between; cursor: pointer; transition: box-shadow .2s; }
.pa-card:hover { box-shadow: 0 6px 20px rgba(31,45,61,.1); }
.pa-card-left { flex: 0 0 70%; min-width: 0; }
.pa-card-right { flex: 0 0 30%; display: flex; flex-direction: column; align-items: flex-end; justify-content: space-between; }

.pa-card-name-row { display: flex; align-items: center; gap: 8px; }
.pa-card-name { font-size: 16px; font-weight: 700; color: #1f2d3d; }
.pa-card-spec { font-size: 13px; color: #909399; }

.pa-type-tag { display: inline-flex; align-items: center; padding: 2px 8px; border-radius: 4px; font-size: 11px; font-weight: 600; flex-shrink: 0; }
.pa-type-tag.type-1 { background: #FFF3E0; color: #E65100; }
.pa-type-tag.type-2 { background: #E3F2FD; color: #0D47A1; }
.pa-type-tag.type-3 { background: #F3E5F5; color: #6A1B9A; }

.pa-status-tag { display: inline-flex; align-items: center; padding: 2px 10px; border-radius: 999px; font-size: 11px; font-weight: 600; }
.pa-status-tag.status-1 { background: #E8F5E9; color: #2E7D32; }
.pa-status-tag.status-2 { background: #FFF3E0; color: #E65100; }
.pa-status-tag.status-3 { background: #F3E5F5; color: #6A1B9A; }
.pa-status-tag.status-4 { background: #FFEBEE; color: #C62828; }

.pa-card-code { font-size: 13px; color: #909399; margin-top: 6px; }
.pa-card-qty { font-size: 14px; margin-top: 6px; }
.pa-qty-num { font-size: 16px; font-weight: 700; color: #409EFF; }
.pa-card-location { font-size: 13px; margin-top: 6px; display: flex; align-items: center; }
.pa-location-icon { color: #909399; font-size: 13px; margin-right: 4px; }
.pa-location-text { color: #4b5a6c; }
.pa-location-empty { color: #c0c4cc; font-style: italic; }
.pa-location-edit { margin-left: 4px; padding: 0; font-size: 13px; }
.pa-card-purchase { font-size: 12px; color: #909399; margin-top: 4px; display: flex; align-items: center; flex-wrap: wrap; }
.pa-purchase-label { color: #909399; flex-shrink: 0; }
.pa-purchase-val { color: #4b5a6c; }
.pa-purchase-warranty { color: #E6A23C; margin-left: 4px; }
.pa-card-source { font-size: 12px; color: #909399; margin-top: 6px; }
.pa-card-time { font-size: 12px; color: #909399; margin-top: 2px; }
.pa-card-actions { display: flex; flex-direction: column; align-items: flex-end; gap: 2px; }

/* 空状态 */
.pa-empty { grid-column: 1 / -1; text-align: center; padding: 60px 0; }
.pa-empty-icon { font-size: 48px; color: #dcdfe6; }
.pa-empty-title { font-size: 16px; color: #606266; font-weight: 600; margin-top: 12px; }
.pa-empty-desc { font-size: 13px; color: #909399; margin: 8px 0 16px; }

/* 分页 */
.pa-pagination { display: flex; justify-content: flex-end; margin-top: 20px; }

/* 详情 */
.pa-detail-body { min-height: 200px; }
.pa-detail-section { margin-bottom: 16px; }
.pa-detail-title { font-size: 14px; font-weight: 600; color: #1f2d3d; margin-bottom: 10px; padding-bottom: 6px; border-bottom: 1px solid #f0f2f5; }
.pa-detail-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 8px 16px; }
.pa-detail-item { font-size: 13px; color: #303133; display: flex; align-items: center; }
.pa-detail-lb { color: #909399; width: 70px; flex-shrink: 0; }
.pa-detail-remark { font-size: 13px; color: #4b5a6c; line-height: 1.7; }

@media (max-width: 768px) {
  .pa-stats { grid-template-columns: repeat(2, 1fr); }
  .pa-card-list { grid-template-columns: 1fr; }
  .pa-card { flex-direction: column; }
  .pa-card-left { flex: none; }
  .pa-card-right { flex: none; flex-direction: row; align-items: center; margin-top: 10px; }
  .pa-card-actions { flex-direction: row; }
}
</style>