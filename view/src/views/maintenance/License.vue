<template>
  <!-- 系统授权管理页：展示授权信息 + 绑定/购买授权 + 我的订单 -->
  <div class="license-page">
    <el-card shadow="never" v-loading="loading">
      <div slot="header" class="card-header">系统授权信息</div>
      <el-descriptions :column="2" border>
        <el-descriptions-item label="授权状态">
          <el-tag :type="statusTag">{{ statusText }}</el-tag>
          <span v-if="!info.valid && info.msg" class="invalid-msg">{{ info.msg }}</span>
        </el-descriptions-item>
        <el-descriptions-item label="项目名称">{{ info.project_name || '-' }}</el-descriptions-item>
        <el-descriptions-item label="激活码">{{ info.license_key || '未激活' }}</el-descriptions-item>
        <el-descriptions-item label="绑定域名">{{ info.domain || '-' }}</el-descriptions-item>
        <el-descriptions-item label="授权版本">{{ info.version || '-' }}</el-descriptions-item>
        <el-descriptions-item label="到期时间">{{ info.expire_date || '-' }}</el-descriptions-item>
      </el-descriptions>
    </el-card>

    <el-card shadow="never" class="action-card">
      <div slot="header" class="card-header">绑定授权</div>
      <el-button type="primary" :loading="saving" @click="bindVisible = true">绑定授权码</el-button>
      <el-button type="success" @click="goPurchase">购买授权</el-button>
      <div class="tip">绑定授权码到域名后，系统将按绑定域名校验授权（实际访问域名必须一致）；未绑定时为 30 天试用。</div>
    </el-card>

    <!-- 我的购买订单 -->
    <el-card shadow="never" class="action-card">
      <div slot="header" class="card-header">
        我的购买订单
        <el-button size="mini" style="float:right" type="text" icon="el-icon-refresh" @click="loadOrders">刷新</el-button>
      </div>
      <el-table :data="orders" v-loading="ordersLoading" size="small" stripe>
        <el-table-column prop="order_no" label="订单号" width="210" />
        <el-table-column prop="plan_name" label="套餐" width="100" />
        <el-table-column prop="amount" label="金额" width="90">
          <template slot-scope="s">¥{{ s.row.amount }}</template>
        </el-table-column>
        <el-table-column prop="domain" label="绑定域名" min-width="140" />
        <el-table-column prop="expire_days" label="授权天数" width="90">
          <template slot-scope="s">{{ s.row.expire_days }} 天</template>
        </el-table-column>
        <el-table-column prop="license_key" label="授权码" min-width="150">
          <template slot-scope="s">{{ s.row.license_key || '-' }}</template>
        </el-table-column>
        <el-table-column label="状态" width="90">
          <template slot-scope="s">
            <el-tag :type="orderStatusTag(s.row.status)" size="mini">{{ orderStatusText(s.row.status) }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column label="创建时间" width="165">
          <template slot-scope="s">{{ s.row.created_at }}</template>
        </el-table-column>
        <el-table-column label="操作" width="170" fixed="right">
          <template slot-scope="s">
            <el-button v-if="s.row.status === 0" size="mini" type="warning" :loading="payingNo === s.row.order_no" @click="doPay(s.row, true)">去支付</el-button>
            <el-button v-if="s.row.status === 1" size="mini" type="warning" :loading="payingNo === s.row.order_no" @click="doPay(s.row, true)">确认支付</el-button>
            <el-button v-if="s.row.license_key" size="mini" type="primary" @click="bindFromOrder(s.row)">绑定授权</el-button>
          </template>
        </el-table-column>
      </el-table>
      <el-pagination v-if="ordersTotal > 0" small background layout="prev, pager, next" :total="ordersTotal" :page-size="20" :current-page.sync="ordersPage" @current-change="loadOrders" style="margin-top:10px;text-align:right" />
    </el-card>

    <!-- 绑定弹窗：授权码 + 域名 + 密码 -->
    <el-dialog title="绑定授权码到域名" :visible.sync="bindVisible" width="480px">
      <el-form label-width="90px">
        <el-form-item label="授权码">
          <el-input v-model="bindForm.license_key" placeholder="输入授权平台签发的激活码，如 CLIENT_A-XXXX" />
        </el-form-item>
        <el-form-item label="绑定域名">
          <el-input v-model="bindForm.domain" placeholder="输入你部署的真实域名或 IP，如 client.com / 192.168.1.10" />
        </el-form-item>
        <el-form-item label="登录密码">
          <el-input v-model="bindForm.password" type="password" show-password placeholder="输入当前登录密码确认操作" />
        </el-form-item>
      </el-form>
      <div class="tip">绑定为敏感操作，需输入当前登录密码确认。</div>
      <template #footer>
        <el-button @click="bindVisible = false">取消</el-button>
        <el-button type="primary" :loading="saving" @click="handleBind">绑定</el-button>
      </template>
    </el-dialog>

    <!-- 购买授权弹窗 -->
    <el-dialog title="购买授权" :visible.sync="purchaseVisible" width="560px" :close-on-click-modal="false">
      <template v-if="!purchaseDone">
        <div class="purchase-plan-row">
          <div v-for="p in purchasePlans" :key="p.code" class="purchase-plan" :class="{ active: purchaseForm.plan_code === p.code }" @click="purchaseForm.plan_code = p.code">
            <div class="pp-name">{{ p.name }}</div>
            <div class="pp-price">¥{{ p.amount }}</div>
            <div class="pp-days">{{ p.days }} 天</div>
          </div>
        </div>
        <el-form label-width="90px" size="small" style="margin-top:16px">
          <el-form-item label="项目代码"><el-input v-model="purchaseForm.project_code" /></el-form-item>
          <el-form-item label="绑定域名"><el-input v-model="purchaseForm.domain" /></el-form-item>
          <el-form-item label="购买方"><el-input v-model="purchaseForm.client_name" placeholder="公司/个人名称" /></el-form-item>
          <el-form-item label="联系方式"><el-input v-model="purchaseForm.contact" placeholder="手机号或邮箱" /></el-form-item>
        </el-form>
        <div class="purchase-tip">提交订单后点击"去支付"完成付款，支付成功自动生成授权码。</div>
        <div slot="footer" class="dialog-footer">
          <el-button size="small" @click="purchaseVisible = false">取消</el-button>
          <el-button size="small" type="primary" :loading="purchaseSubmitting" @click="submitPurchase">提交订单</el-button>
        </div>
      </template>
      <template v-else>
        <el-result icon="success" title="订单已提交" :sub-title="'订单号：' + (purchaseOrder.order_no || '')">
          <template #extra>
            <div class="purchase-order-info">
              <p>套餐：{{ purchaseOrder.plan_name }}（{{ purchaseOrder.expire_days }} 天）</p>
              <p>金额：¥{{ purchaseOrder.amount }}</p>
              <p>绑定域名：{{ purchaseOrder.domain }}</p>
              <template v-if="purchaseOrder.license_key">
                <p style="color:#409EFF">授权码：{{ purchaseOrder.license_key }}</p>
                <el-button size="small" type="primary" @click="bindFromOrder(purchaseOrder)">绑定授权码到本系统</el-button>
              </template>
              <template v-else>
                <div v-if="purchaseOrder.collect_qr" class="pay-qr-box">
                  <p class="pay-qr-price">请使用微信扫一扫支付 ¥{{ purchaseOrder.amount }}</p>
                  <img :src="purchaseOrder.collect_qr" class="pay-qr-img" alt="微信收款码" />
                  <p class="pay-qr-tip">支付完成后请联系管理员确认收款，确认后授权码将在此显示。</p>
                </div>
                <el-button v-else size="small" type="warning" :loading="payingNo === purchaseOrder.order_no" @click="doPay(purchaseOrder)">去支付</el-button>
              </template>
            </div>
          </template>
        </el-result>
        <div slot="footer" class="dialog-footer">
          <el-button size="small" @click="purchaseVisible = false; purchaseDone = false">关闭</el-button>
        </div>
      </template>
    </el-dialog>

    <!-- 扫码支付弹窗：微信收款码 + 轮询确认 -->
    <el-dialog title="扫码支付" :visible.sync="payVisible" width="420px" :close-on-click-modal="false" @closed="stopPayPoll">
      <div v-if="payOrder.collect_qr" class="pay-qr-box" style="text-align:center">
        <p class="pay-qr-price">请使用微信扫一扫支付 ¥{{ payOrder.amount }}</p>
        <img :src="payOrder.collect_qr" class="pay-qr-img" alt="微信收款码" />
        <p class="pay-qr-tip">支付完成后请联系管理员确认收款，确认后授权码将自动开通。</p>
        <template v-if="payOrder.license_key">
          <p style="color:#409EFF;margin-top:8px">授权码：{{ payOrder.license_key }}</p>
          <el-button size="small" type="primary" @click="bindFromOrder(payOrder); payVisible = false">绑定授权码到本系统</el-button>
        </template>
      </div>
      <div slot="footer" class="dialog-footer">
        <el-button size="small" @click="payVisible = false">关闭</el-button>
      </div>
    </el-dialog>
  </div>
</template>

<script>
// 系统授权管理：查询授权信息 / 绑定授权码 / 购买授权（下单-支付-绑定闭环）
import request from '@/api/request'

export default {
  name: 'SystemLicense',
  data() {
    return {
      loading: false,
      saving: false,
      info: {},       // 授权信息
      bindVisible: false,   // 绑定弹窗
      // 购买
      purchaseVisible: false,
      purchasePlans: [],
      purchaseSubmitting: false,
      purchaseDone: false,
      purchaseOrder: {},
      purchaseForm: { plan_code: '', project_code: '', domain: '', client_name: '', contact: '' },
      // 订单
      orders: [],
      ordersLoading: false,
      ordersTotal: 0,
      ordersPage: 1,
      payingNo: '',
      payVisible: false,   // 扫码支付弹窗
      payOrder: {},        // 当前支付订单（含 collect_qr）
      payTimer: null,      // 支付状态轮询定时器
      bindForm: { license_key: '', domain: '', password: '' },  // 绑定表单：授权码 + 域名 + 登录密码
    }
  },
  created() {
    this.loadInfo()
    this.loadOrders()
  },
  computed: {
    statusTag() {
      if (this.info.status === 'licensed') return 'success'
      if (this.info.status === 'trial') return 'warning'
      return 'danger'
    },
    statusText() {
      if (this.info.status === 'licensed') return '正式授权'
      if (this.info.status === 'trial') return `试用期（剩余 ${this.info.trial_days_left || 0} 天）`
      return '已失效'
    },
  },
  beforeDestroy() {
    this.stopPayPoll()
  },
  methods: {
    async loadInfo() {
      this.loading = true
      try {
        const res = await request({ url: '/system/license/info', method: 'get' })
        this.info = res.data || {}
      } catch (e) {} finally {
        this.loading = false
      }
    },
    async loadOrders() {
      this.ordersLoading = true
      try {
        const r = await request({ url: '/purchase/my-orders', method: 'get', params: { page: this.ordersPage, limit: 20 } })
        if (r.code === 0) {
          this.orders = (r.data && r.data.list) || []
          this.ordersTotal = (r.data && r.data.total) || 0
        }
      } catch (e) {} finally {
        this.ordersLoading = false
      }
    },
    orderStatusTag(s) {
      if (s === 0) return 'warning'
      if (s === 1) return 'primary'
      if (s === 2) return 'success'
      return 'info'
    },
    orderStatusText(s) {
      if (s === 0) return '待付款'
      if (s === 1) return '已付款'
      if (s === 2) return '已开通'
      return '已取消'
    },
    async handleBind() {
      if (!this.bindForm.license_key || !this.bindForm.license_key.trim()) { this.$message.warning('请输入授权码'); return }
      if (!this.bindForm.domain || !this.bindForm.domain.trim()) { this.$message.warning('请输入绑定域名'); return }
      if (!this.bindForm.password) { this.$message.warning('请输入当前登录密码确认操作'); return }
      this.saving = true
      try {
        const res = await request({
          url: '/system/license/update',
          method: 'post',
          data: { license_key: this.bindForm.license_key.trim(), domain: this.bindForm.domain.trim(), password: this.bindForm.password },
        })
        this.$message.success(res.msg || '绑定成功')
        this.bindVisible = false
        this.loadInfo()
      } catch (e) {} finally {
        this.saving = false
      }
    },
    async goPurchase() {
      this.purchaseVisible = true
      this.purchaseDone = false
      this.purchaseForm.project_code = (this.info && this.info.project_code) || 'SC_ADMIN'
      this.purchaseForm.domain = (this.info && this.info.domain) || window.location.hostname || ''
      try {
        const r = await request({ url: '/purchase/plans', method: 'get' })
        if (r.code === 0) this.purchasePlans = (r.data && r.data.list) || []
      } catch (e) {}
    },
    async submitPurchase() {
      if (!this.purchaseForm.plan_code || !this.purchaseForm.project_code || !this.purchaseForm.domain) {
        this.$message.warning('请填写项目代码、绑定域名并选择套餐')
        return
      }
      this.purchaseSubmitting = true
      try {
        const r = await request({ url: '/purchase/create', method: 'post', data: this.purchaseForm })
        if (r.code === 0) {
          this.purchaseOrder = r.data || {}
          this.purchaseDone = true
          this.loadOrders()
        }
      } catch (e) {} finally {
        this.purchaseSubmitting = false
      }
    },
    async doPay(row, fromList) {
      const orderNo = row.order_no
      if (!orderNo) { this.$message.warning('订单号缺失'); return }
      this.payingNo = orderNo
      try {
        const r = await request({ url: '/purchase/pay', method: 'post', data: { order_no: orderNo } })
        if (r.code === 0) {
          if (r.data && r.data.license_key) {
            this.purchaseOrder = Object.assign({}, this.purchaseOrder, r.data)
            this.$message.success('支付成功，授权码：' + r.data.license_key)
            this.loadOrders()
            this.loadInfo()
          } else if (r.data && r.data.collect && r.data.collect_qr) {
            // 微信收款码支付：展示二维码并轮询等待管理员确认
            const merged = Object.assign({}, row, r.data)
            if (fromList) {
              // 列表入口：打开独立扫码支付弹窗，不触碰购买弹窗状态
              this.payOrder = merged
              this.payVisible = true
            } else {
              // 购买弹窗入口：更新 purchaseOrder，在订单已提交视图内直接显示收款码
              this.purchaseOrder = Object.assign({}, this.purchaseOrder, merged)
            }
            // 两种入口都轮询，管理员确认后自动更新授权码
            this.startPayPoll(orderNo)
            this.loadOrders()
          } else {
            this.$message.success('支付请求已发起，请完成扫码付款')
            this.loadOrders()
          }
        }
      } catch (e) {} finally {
        this.payingNo = ''
      }
    },
    startPayPoll(orderNo) {
      this.stopPayPoll()
      this.payTimer = setInterval(async () => {
        try {
          const r = await request({ url: '/purchase/order', method: 'get', params: { order_no: orderNo } })
          if (r.code === 0 && r.data) {
            const paid = (r.data.status === 2 || r.data.status === 3) || !!r.data.license_key
            if (paid) {
              this.stopPayPoll()
              this.payOrder = Object.assign({}, this.payOrder, r.data)
              this.purchaseOrder = Object.assign({}, this.purchaseOrder, r.data)
              this.$message.success('支付成功，授权码：' + (r.data.license_key || ''))
              this.loadOrders()
              this.loadInfo()
            }
          }
        } catch (e) {}
      }, 5000)
    },
    stopPayPoll() {
      if (this.payTimer) { clearInterval(this.payTimer); this.payTimer = null }
    },
    bindFromOrder(row) {
      this.bindForm.license_key = row.license_key || ''
      this.bindForm.domain = row.domain || window.location.hostname || ''
      this.bindForm.password = ''
      this.bindVisible = true
    },
  },
}
</script>

<style scoped>
.license-page { padding: 16px; }
.card-header { font-weight: 600; }
.action-card { margin-top: 16px; }
.invalid-msg { margin-left: 8px; color: #f56c6c; font-size: 13px; }
.tip { color: #909399; font-size: 12px; margin-top: 4px; }
.purchase-plan-row { display: flex; gap: 10px; }
.purchase-plan { flex: 1; border: 1px solid #DCDFE6; border-radius: 8px; padding: 12px; text-align: center; cursor: pointer; }
.purchase-plan.active { border-color: #409EFF; box-shadow: 0 0 0 2px rgba(64,158,255,.2); }
.pp-name { font-size: 14px; font-weight: 600; }
.pp-price { font-size: 20px; color: #F56C6C; font-weight: 700; margin: 4px 0; }
.pp-days { color: #909399; font-size: 12px; }
.purchase-tip { color: #E6A23C; font-size: 12px; margin-top: 8px; }
.purchase-order-info p { margin: 6px 0; color: #606266; }
.pay-qr-box { text-align: center; padding: 8px 0; }
.pay-qr-price { color: #E6A23C; font-size: 14px; font-weight: 600; margin-bottom: 10px; }
.pay-qr-img { width: 240px; height: 240px; border: 1px solid #EBEEF5; border-radius: 8px; }
.pay-qr-tip { color: #909399; font-size: 12px; margin-top: 10px; }
</style>
