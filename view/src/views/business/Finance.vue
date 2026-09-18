<template>
  <!-- 财务管理：应收款 / 应付款 / 费用报销 / 看板 -->
  <div class="finance-page">
    <!-- 看板 -->
    <div class="ov-cards">
      <div class="ov-card">
        <div class="ov-num">¥{{ ov.ar_total.toLocaleString() }}</div>
        <div class="ov-label">应收总额</div>
      </div>
      <div class="ov-card">
        <div class="ov-num ok">¥{{ ov.ar_received.toLocaleString() }}</div>
        <div class="ov-label">已收</div>
      </div>
      <div class="ov-card">
        <div class="ov-num warn">¥{{ ov.ar_balance.toLocaleString() }}</div>
        <div class="ov-label">未收</div>
      </div>
      <div class="ov-card">
        <div class="ov-num danger">{{ ov.ar_due }}</div>
        <div class="ov-label">应收逾期</div>
      </div>
      <div class="ov-card">
        <div class="ov-num">¥{{ ov.ap_total.toLocaleString() }}</div>
        <div class="ov-label">应付总额</div>
      </div>
      <div class="ov-card">
        <div class="ov-num ok">¥{{ ov.ap_paid.toLocaleString() }}</div>
        <div class="ov-label">已付</div>
      </div>
      <div class="ov-card">
        <div class="ov-num warn">¥{{ ov.ap_balance.toLocaleString() }}</div>
        <div class="ov-label">未付</div>
      </div>
      <div class="ov-card">
        <div class="ov-num danger">{{ ov.ap_due }}</div>
        <div class="ov-label">应付逾期</div>
      </div>
      <div class="ov-card">
        <div class="ov-num">{{ ov.exp_pending }}</div>
        <div class="ov-label">待审报销</div>
      </div>
    </div>

    <el-card shadow="never">
      <el-tabs v-model="tab" @tab-click="onTabClick">
        <!-- ============ 应收款 ============ -->
        <el-tab-pane label="应收款" name="ar">
          <div class="toolbar">
            <el-button size="small" type="primary" icon="el-icon-plus" @click="openArDialog()">登记应收</el-button>
            <el-input v-model="arKeyword" size="small" placeholder="客户/单据号" style="width:180px" clearable @keyup.enter="loadAr" />
            <el-select v-model="arStatus" size="small" clearable placeholder="全部状态" style="width:110px" @change="loadAr">
              <el-option label="未收完" :value="0" />
              <el-option label="已收完" :value="1" />
            </el-select>
            <el-button size="small" icon="el-icon-refresh" @click="loadAr">刷新</el-button>
          </div>
          <el-table :data="arList" v-loading="loading" size="small" border stripe>
            <el-table-column prop="customer" label="客户" width="140" show-overflow-tooltip />
            <el-table-column label="单据" width="110">
              <template slot-scope="{ row }">{{ row.bill_no || '-' }}</template>
            </el-table-column>
            <el-table-column label="金额" width="110">
              <template slot-scope="{ row }">¥{{ Number(row.amount).toLocaleString() }}</template>
            </el-table-column>
            <el-table-column label="已收" width="110">
              <template slot-scope="{ row }">¥{{ Number(row.received).toLocaleString() }}</template>
            </el-table-column>
            <el-table-column label="未收" width="110">
              <template slot-scope="{ row }">
                <span :style="{ color: row.balance > 0 ? '#F56C6C' : '' }">¥{{ Number(row.balance).toLocaleString() }}</span>
              </template>
            </el-table-column>
            <el-table-column prop="due_date" label="到期日" width="110">
              <template slot-scope="{ row }">{{ row.due_date || '-' }}</template>
            </el-table-column>
            <el-table-column label="状态" width="90">
              <template slot-scope="{ row }">
                <el-tag :type="row.status === 1 ? 'success' : 'warning'" size="mini">{{ row.status === 1 ? '已收完' : '未收完' }}</el-tag>
              </template>
            </el-table-column>
            <el-table-column prop="remark" label="备注" min-width="100" show-overflow-tooltip />
            <el-table-column label="操作" width="130" fixed="right">
              <template slot-scope="{ row }">
                <el-button v-if="row.status === 0" type="success" size="mini" @click="openReceiptDialog(row)">收款</el-button>
                <el-button type="text" size="mini" style="color:#F56C6C" @click="delAr(row)">删除</el-button>
              </template>
            </el-table-column>
          </el-table>
        </el-tab-pane>

        <!-- ============ 应付款 ============ -->
        <el-tab-pane label="应付款" name="ap">
          <div class="toolbar">
            <el-button size="small" type="primary" icon="el-icon-plus" @click="openApDialog()">登记应付</el-button>
            <el-input v-model="apKeyword" size="small" placeholder="供应商/单据号" style="width:180px" clearable @keyup.enter="loadAp" />
            <el-select v-model="apStatus" size="small" clearable placeholder="全部状态" style="width:110px" @change="loadAp">
              <el-option label="未付完" :value="0" />
              <el-option label="已付完" :value="1" />
            </el-select>
            <el-button size="small" icon="el-icon-refresh" @click="loadAp">刷新</el-button>
          </div>
          <el-table :data="apList" v-loading="loading" size="small" border stripe>
            <el-table-column prop="supplier" label="供应商/往来方" width="140" show-overflow-tooltip />
            <el-table-column label="单据" width="110">
              <template slot-scope="{ row }">{{ row.bill_no || '-' }}</template>
            </el-table-column>
            <el-table-column label="金额" width="110">
              <template slot-scope="{ row }">¥{{ Number(row.amount).toLocaleString() }}</template>
            </el-table-column>
            <el-table-column label="已付" width="110">
              <template slot-scope="{ row }">¥{{ Number(row.paid).toLocaleString() }}</template>
            </el-table-column>
            <el-table-column label="未付" width="110">
              <template slot-scope="{ row }">
                <span :style="{ color: row.balance > 0 ? '#F56C6C' : '' }">¥{{ Number(row.balance).toLocaleString() }}</span>
              </template>
            </el-table-column>
            <el-table-column prop="due_date" label="到期日" width="110">
              <template slot-scope="{ row }">{{ row.due_date || '-' }}</template>
            </el-table-column>
            <el-table-column label="状态" width="90">
              <template slot-scope="{ row }">
                <el-tag :type="row.status === 1 ? 'success' : 'warning'" size="mini">{{ row.status === 1 ? '已付完' : '未付完' }}</el-tag>
              </template>
            </el-table-column>
            <el-table-column label="操作" width="130" fixed="right">
              <template slot-scope="{ row }">
                <el-button v-if="row.status === 0" type="success" size="mini" @click="openPaymentDialog(row)">付款</el-button>
                <el-button type="text" size="mini" style="color:#F56C6C" @click="delAp(row)">删除</el-button>
              </template>
            </el-table-column>
          </el-table>
        </el-tab-pane>

        <!-- ============ 费用报销 ============ -->
        <el-tab-pane label="费用报销" name="exp">
          <div class="toolbar">
            <el-button size="small" type="primary" icon="el-icon-plus" @click="openExpDialog()">申请报销</el-button>
            <el-select v-model="expStatus" size="small" clearable placeholder="全部状态" style="width:130px" @change="loadExp">
              <el-option label="草稿" :value="0" />
              <el-option label="待审批" :value="1" />
              <el-option label="已通过" :value="2" />
              <el-option label="已驳回" :value="3" />
            </el-select>
            <el-button size="small" icon="el-icon-refresh" @click="loadExp">刷新</el-button>
          </div>
          <el-table :data="expList" v-loading="loading" size="small" border stripe>
            <el-table-column prop="applicant_name" label="申请人" width="90" />
            <el-table-column prop="department_name" label="部门" width="110" />
            <el-table-column prop="category" label="科目" width="90" />
            <el-table-column label="金额" width="100">
              <template slot-scope="{ row }">¥{{ Number(row.amount).toLocaleString() }}</template>
            </el-table-column>
            <el-table-column prop="purpose" label="事由" min-width="160" show-overflow-tooltip />
            <el-table-column label="状态" width="90">
              <template slot-scope="{ row }">
                <el-tag :type="statusTag(row.status)" size="mini">{{ row.status_text }}</el-tag>
              </template>
            </el-table-column>
            <el-table-column prop="approver_name" label="审批人" width="90">
              <template slot-scope="{ row }">{{ row.approver_name || '-' }}</template>
            </el-table-column>
            <el-table-column label="打款状态" width="90">
              <template slot-scope="{ row }">
                <el-tag v-if="row.pay_status === 1" type="success" size="mini">已打款</el-tag>
                <el-tag v-else type="info" size="mini">未打款</el-tag>
              </template>
            </el-table-column>
            <el-table-column prop="created_at" label="申请时间" width="160" />
            <el-table-column label="操作" width="140" fixed="right">
              <template slot-scope="{ row }">
                <el-button v-if="row.status === 2 && row.pay_status === 0" type="warning" size="mini" @click="openPayDialog(row)">打款</el-button>
                <el-button v-if="row.status === 1" type="success" size="mini" @click="approveExp(row, 'approve')">通过</el-button>
                <el-button v-if="row.status === 1" type="danger" size="mini" @click="approveExp(row, 'reject')">驳回</el-button>
                <el-button v-if="row.status === 0 || row.status === 3" type="text" size="mini" style="color:#F56C6C" @click="delExp(row)">删除</el-button>
              </template>
            </el-table-column>
          </el-table>
        </el-tab-pane>

        <!-- ============ 付款计划 ============ -->
        <el-tab-pane label="付款计划" name="plan">
          <div class="toolbar">
            <el-button size="small" type="primary" icon="el-icon-plus" @click="openPlanDialog()">新增计划</el-button>
            <el-input v-model="planKeyword" size="small" placeholder="供应商/计划号" style="width:180px" clearable @keyup.enter="loadPayPlan" />
            <el-select v-model="planStatus" size="small" clearable placeholder="全部状态" style="width:120px" @change="loadPayPlan">
              <el-option label="未到期" :value="0" />
              <el-option label="待付款" :value="1" />
              <el-option label="已付款" :value="2" />
              <el-option label="已逾期" :value="4" />
              <el-option label="已取消" :value="5" />
            </el-select>
            <el-button size="small" icon="el-icon-refresh" @click="loadPayPlan">刷新</el-button>
          </div>
          <el-table :data="payPlanList" v-loading="planLoading" size="small" border stripe>
            <el-table-column prop="plan_no" label="计划号" width="140" />
            <el-table-column prop="supplier" label="供应商" width="160" show-overflow-tooltip />
            <el-table-column label="金额" width="120">
              <template slot-scope="{ row }">¥{{ Number(row.amount).toLocaleString() }}</template>
            </el-table-column>
            <el-table-column prop="plan_date" label="计划日期" width="110" />
            <el-table-column label="付款方式" width="90">
              <template slot-scope="{ row }">{{ methodLabel(row.method) }}</template>
            </el-table-column>
            <el-table-column label="状态" width="90">
              <template slot-scope="{ row }">
                <el-tag :type="planStatusTag(row.status)" size="mini">{{ row.status_text }}</el-tag>
              </template>
            </el-table-column>
            <el-table-column prop="remark" label="备注" min-width="120" show-overflow-tooltip />
            <el-table-column label="操作" width="150" fixed="right">
              <template slot-scope="{ row }">
                <el-button v-if="row.status !== 2 && row.status !== 5" type="success" size="mini" @click="donePayPlan(row)">付款</el-button>
                <el-button v-if="row.status !== 2 && row.status !== 5" type="text" size="mini" style="color:#F56C6C" @click="delPayPlan(row)">取消</el-button>
              </template>
            </el-table-column>
          </el-table>
        </el-tab-pane>

        <!-- ============ 采购对账 ============ -->
        <el-tab-pane label="采购对账" name="reconcil">
          <div class="toolbar">
            <el-button size="small" icon="el-icon-refresh" @click="loadReconcil">刷新</el-button>
            <span class="toolbar-label">按采购订单核对应付与已付</span>
          </div>
          <div class="ov-cards">
            <div class="ov-card">
              <div class="ov-num">¥{{ reconcilTotal.amount.toLocaleString() }}</div>
              <div class="ov-label">订单应付总额</div>
            </div>
            <div class="ov-card">
              <div class="ov-num ok">¥{{ reconcilTotal.paid.toLocaleString() }}</div>
              <div class="ov-label">已付</div>
            </div>
            <div class="ov-card">
              <div class="ov-num warn">¥{{ reconcilTotal.balance.toLocaleString() }}</div>
              <div class="ov-label">未付余额</div>
            </div>
          </div>
          <el-table :data="reconcilList" v-loading="reconcilLoading" size="small" border stripe max-height="480">
            <el-table-column prop="bill_no" label="采购单号" width="150" />
            <el-table-column prop="supplier" label="供应商" width="180" show-overflow-tooltip />
            <el-table-column label="订单金额" width="120">
              <template slot-scope="{ row }">¥{{ Number(row.amount).toLocaleString() }}</template>
            </el-table-column>
            <el-table-column label="已付" width="120">
              <template slot-scope="{ row }">¥{{ Number(row.paid).toLocaleString() }}</template>
            </el-table-column>
            <el-table-column label="未付余额" width="120">
              <template slot-scope="{ row }">
                <span :style="{ color: row.balance > 0 ? '#F56C6C' : '#67C23A' }">¥{{ Number(row.balance).toLocaleString() }}</span>
              </template>
            </el-table-column>
            <el-table-column label="对账状态" width="100">
              <template slot-scope="{ row }">
                <el-tag :type="row.balance <= 0 ? 'success' : (row.paid > 0 ? 'warning' : 'danger')" size="mini">{{ row.status_text }}</el-tag>
              </template>
            </el-table-column>
          </el-table>
        </el-tab-pane>

        <!-- ============ 账龄分析 ============ -->
        <el-tab-pane label="账龄分析" name="aging">
          <div class="toolbar">
            <el-radio-group v-model="agingType" size="small" @change="loadAging">
              <el-radio-button label="ar">应收账龄</el-radio-button>
              <el-radio-button label="ap">应付账龄</el-radio-button>
            </el-radio-group>
            <span class="toolbar-label">基准日</span>
            <el-date-picker v-model="agingAsOf" type="date" value-format="yyyy-MM-dd" size="small" style="width:140px" @change="loadAging" />
            <el-button size="small" icon="el-icon-refresh" @click="loadAging">刷新</el-button>
          </div>
          <div class="ov-cards">
            <div class="ov-card">
              <div class="ov-num">¥{{ aging.total.amount.toLocaleString() }}</div>
              <div class="ov-label">{{ agingType==='ar'?'应收':'应付' }}余额总额</div>
            </div>
            <div class="ov-card">
              <div class="ov-num warn">¥{{ aging.total.overdue.toLocaleString() }}</div>
              <div class="ov-label">已逾期</div>
            </div>
            <div class="ov-card">
              <div class="ov-num danger">{{ aging.total.overdue_count }}</div>
              <div class="ov-label">逾期笔数</div>
            </div>
            <div class="ov-card" v-for="b in aging.buckets" :key="b.key">
              <div class="ov-num" :class="b.key==='current' ? '' : 'warn'">¥{{ b.amount.toLocaleString() }}</div>
              <div class="ov-label">{{ b.label }}（{{ b.count }} 笔）</div>
            </div>
          </div>
          <el-table :data="aging.list" v-loading="agingLoading" size="small" border stripe>
            <el-table-column prop="party" :label="agingType==='ar'?'客户':'供应商/往来方'" width="160" show-overflow-tooltip />
            <el-table-column label="单据" width="120">
              <template slot-scope="{ row }">{{ row.bill_no || '-' }}</template>
            </el-table-column>
            <el-table-column label="余额" width="120">
              <template slot-scope="{ row }">¥{{ Number(row.balance).toLocaleString() }}</template>
            </el-table-column>
            <el-table-column prop="due_date" label="到期日" width="110">
              <template slot-scope="{ row }">{{ row.due_date || '-' }}</template>
            </el-table-column>
            <el-table-column label="逾期天数" width="100">
              <template slot-scope="{ row }">
                <span :style="{ color: row.overdue_days > 0 ? '#F56C6C' : '' }">{{ row.overdue_days }}</span>
              </template>
            </el-table-column>
            <el-table-column label="账龄区间" width="130">
              <template slot-scope="{ row }">
                <el-tag :type="row.bucket==='current'?'success':'warning'" size="mini">{{ bucketLabel(row.bucket) }}</el-tag>
              </template>
            </el-table-column>
            <el-table-column prop="remark" label="备注" min-width="120" show-overflow-tooltip />
          </el-table>
        </el-tab-pane>

        <!-- ============ 资金流水 ============ -->
        <el-tab-pane label="资金流水" name="flow">
          <div class="toolbar">
            <el-radio-group v-model="flowType" size="small" @change="loadFlow">
              <el-radio-button label="receipt">收款流水</el-radio-button>
              <el-radio-button label="payment">付款流水</el-radio-button>
            </el-radio-group>
            <el-date-picker v-model="flowRange" type="daterange" value-format="yyyy-MM-dd" size="small" range-separator="至" start-placeholder="开始日期" end-placeholder="结束日期" style="width:240px" @change="loadFlow" />
            <el-select v-model="flowMethod" size="small" clearable placeholder="全部方式" style="width:120px" @change="loadFlow">
              <el-option label="银行转账" value="bank" />
              <el-option label="现金" value="cash" />
              <el-option label="微信" value="wechat" />
              <el-option label="支付宝" value="alipay" />
            </el-select>
            <el-button size="small" icon="el-icon-refresh" @click="loadFlow">刷新</el-button>
          </div>
          <div class="ov-cards">
            <div class="ov-card">
              <div class="ov-num">¥{{ flow.total.amount.toLocaleString() }}</div>
              <div class="ov-label">期间{{ flowType==='receipt'?'收款':'付款' }}总额</div>
            </div>
            <div class="ov-card">
              <div class="ov-num">{{ flow.total.count }}</div>
              <div class="ov-label">笔数</div>
            </div>
          </div>
          <el-row :gutter="14">
            <el-col :span="10">
              <div class="sub-title">按日汇总</div>
              <el-table :data="flow.daily" v-loading="flowLoading" size="mini" border stripe max-height="320">
                <el-table-column prop="date" label="日期" width="110" />
                <el-table-column label="金额" width="120">
                  <template slot-scope="{ row }">¥{{ Number(row.amount).toLocaleString() }}</template>
                </el-table-column>
                <el-table-column prop="count" label="笔数" />
              </el-table>
            </el-col>
            <el-col :span="14">
              <div class="sub-title">流水明细</div>
              <el-table :data="flow.list" v-loading="flowLoading" size="mini" border stripe max-height="320">
                <el-table-column prop="biz_date" label="日期" width="100" />
                <el-table-column prop="party" label="往来方" width="140" show-overflow-tooltip />
                <el-table-column label="金额" width="110">
                  <template slot-scope="{ row }">¥{{ Number(row.amount).toLocaleString() }}</template>
                </el-table-column>
                <el-table-column label="方式" width="80">
                  <template slot-scope="{ row }">{{ methodLabel(row.method) }}</template>
                </el-table-column>
                <el-table-column prop="operator" label="操作人" width="90">
                  <template slot-scope="{ row }">{{ row.operator || '-' }}</template>
                </el-table-column>
                <el-table-column prop="remark" label="备注" min-width="100" show-overflow-tooltip />
              </el-table>
            </el-col>
          </el-row>
        </el-tab-pane>

        <!-- ============ 月度收支汇总 ============ -->
        <el-tab-pane label="收支汇总" name="summary">
          <div class="toolbar">
            <el-date-picker v-model="summaryMonth" type="month" value-format="yyyy-MM" size="small" style="width:140px" @change="loadSummary" />
            <el-button size="small" icon="el-icon-refresh" @click="loadSummary">刷新</el-button>
          </div>
          <div class="ov-cards">
            <div class="ov-card">
              <div class="ov-num ok">¥{{ summary.receipt_total.toLocaleString() }}</div>
              <div class="ov-label">当月收款</div>
            </div>
            <div class="ov-card">
              <div class="ov-num danger">¥{{ summary.payment_total.toLocaleString() }}</div>
              <div class="ov-label">当月付款</div>
            </div>
            <div class="ov-card">
              <div class="ov-num warn">¥{{ summary.expense_total.toLocaleString() }}</div>
              <div class="ov-label">通过报销</div>
            </div>
            <div class="ov-card">
              <div class="ov-num">¥{{ summary.net.toLocaleString() }}</div>
              <div class="ov-label">净流入</div>
            </div>
          </div>
          <el-table :data="summary.daily" v-loading="summaryLoading" size="small" border stripe max-height="420">
            <el-table-column prop="date" label="日期" width="120" />
            <el-table-column label="收款" width="140">
              <template slot-scope="{ row }">¥{{ Number(row.receipt).toLocaleString() }}</template>
            </el-table-column>
            <el-table-column label="付款" width="140">
              <template slot-scope="{ row }">¥{{ Number(row.payment).toLocaleString() }}</template>
            </el-table-column>
            <el-table-column label="当日净额">
              <template slot-scope="{ row }">
                <span :style="{ color: Number(row.receipt)-Number(row.payment) >= 0 ? '#67C23A' : '#F56C6C' }">¥{{ (Number(row.receipt)-Number(row.payment)).toLocaleString() }}</span>
              </template>
            </el-table-column>
          </el-table>
        </el-tab-pane>
      </el-tabs>
    </el-card>

    <!-- 登记应收弹窗 -->
    <el-dialog title="登记应收款" :visible.sync="arDialog" width="480px">
      <el-form label-width="90px" size="small">
        <el-form-item label="客户"><el-input v-model="arForm.customer" placeholder="客户名称" /></el-form-item>
        <el-form-item label="单据类型">
          <el-select v-model="arForm.bill_type" style="width:100%"><el-option label="销售订单" value="order" /><el-option label="合同" value="contract" /><el-option label="其他" value="other" /></el-select>
        </el-form-item>
        <el-form-item label="单据号"><el-input v-model="arForm.bill_no" placeholder="如 SO-2026-001" /></el-form-item>
        <el-form-item label="应收金额"><el-input-number v-model="arForm.amount" :min="0.01" :precision="2" style="width:100%" /></el-form-item>
        <el-form-item label="到期日"><el-date-picker v-model="arForm.due_date" type="date" value-format="yyyy-MM-dd" style="width:100%" /></el-form-item>
        <el-form-item label="备注"><el-input v-model="arForm.remark" /></el-form-item>
      </el-form>
      <template #footer>
        <el-button size="small" @click="arDialog = false">取消</el-button>
        <el-button size="small" type="primary" @click="saveAr">保存</el-button>
      </template>
    </el-dialog>

    <!-- 登记应付弹窗 -->
    <el-dialog title="登记应付款" :visible.sync="apDialog" width="480px">
      <el-form label-width="90px" size="small">
        <el-form-item label="供应商"><el-input v-model="apForm.supplier" placeholder="供应商/往来方" /></el-form-item>
        <el-form-item label="单据类型">
          <el-select v-model="apForm.bill_type" style="width:100%"><el-option label="采购订单" value="purchase" /><el-option label="费用" value="expense" /><el-option label="其他" value="other" /></el-select>
        </el-form-item>
        <el-form-item label="单据号"><el-input v-model="apForm.bill_no" placeholder="如 PO-2026-001" /></el-form-item>
        <el-form-item label="应付金额"><el-input-number v-model="apForm.amount" :min="0.01" :precision="2" style="width:100%" /></el-form-item>
        <el-form-item label="到期日"><el-date-picker v-model="apForm.due_date" type="date" value-format="yyyy-MM-dd" style="width:100%" /></el-form-item>
        <el-form-item label="备注"><el-input v-model="apForm.remark" /></el-form-item>
      </el-form>
      <template #footer>
        <el-button size="small" @click="apDialog = false">取消</el-button>
        <el-button size="small" type="primary" @click="saveAp">保存</el-button>
      </template>
    </el-dialog>

    <!-- 收款/付款弹窗（复用）-->
    <el-dialog :title="moneyDialogTitle" :visible.sync="moneyDialog" width="400px">
      <el-form label-width="90px" size="small">
        <el-form-item label="金额"><el-input-number v-model="moneyForm.amount" :min="0.01" :precision="2" style="width:100%" /></el-form-item>
        <el-form-item label="方式">
          <el-select v-model="moneyForm.method" style="width:100%"><el-option label="银行转账" value="bank" /><el-option label="现金" value="cash" /><el-option label="微信" value="wechat" /><el-option label="支付宝" value="alipay" /></el-select>
        </el-form-item>
        <el-form-item label="日期"><el-date-picker v-model="moneyForm.money_date" type="date" value-format="yyyy-MM-dd" style="width:100%" /></el-form-item>
        <el-form-item label="备注"><el-input v-model="moneyForm.remark" /></el-form-item>
      </el-form>
      <template #footer>
        <el-button size="small" @click="moneyDialog = false">取消</el-button>
        <el-button size="small" type="primary" @click="saveMoney">保存</el-button>
      </template>
    </el-dialog>

    <!-- 报销申请弹窗 -->
    <el-dialog title="申请费用报销" :visible.sync="expDialog" width="480px">
      <el-form label-width="90px" size="small">
        <el-form-item label="科目"><el-input v-model="expForm.category" placeholder="如：差旅费、办公费" /></el-form-item>
        <el-form-item label="报销金额"><el-input-number v-model="expForm.amount" :min="0.01" :precision="2" style="width:100%" /></el-form-item>
        <el-form-item label="事由"><el-input v-model="expForm.purpose" type="textarea" :rows="3" placeholder="报销内容说明" /></el-form-item>
      </el-form>
      <template #footer>
        <el-button size="small" @click="expDialog = false">取消</el-button>
        <el-button size="small" @click="saveExp(false)">存草稿</el-button>
        <el-button size="small" type="primary" @click="saveExp(true)">提交审批</el-button>
      </template>
    </el-dialog>

    <!-- 报销打款登记弹窗 -->
    <el-dialog title="报销打款登记" :visible.sync="payDialog" width="420px">
      <el-form label-width="90px" size="small">
        <el-form-item label="报销单">
          <span>{{ payForm.applicant_name }} · {{ payForm.category }} ¥{{ Number(payForm.amount).toLocaleString() }}</span>
        </el-form-item>
        <el-form-item label="打款方式">
          <el-select v-model="payForm.method" style="width:100%"><el-option label="银行转账" value="bank" /><el-option label="现金" value="cash" /><el-option label="微信" value="wechat" /><el-option label="支付宝" value="alipay" /></el-select>
        </el-form-item>
        <el-form-item label="打款单号"><el-input v-model="payForm.pay_no" placeholder="如银行流水号" /></el-form-item>
        <el-form-item label="备注"><el-input v-model="payForm.remark" /></el-form-item>
      </el-form>
      <template #footer>
        <el-button size="small" @click="payDialog = false">取消</el-button>
        <el-button size="small" type="primary" @click="saveExpPay">确认打款</el-button>
      </template>
    </el-dialog>

    <!-- 付款计划弹窗 -->
    <el-dialog title="新增付款计划" :visible.sync="planDialog" width="460px">
      <el-form label-width="100px" size="small">
        <el-form-item label="供应商"><el-input v-model="planForm.supplier" placeholder="供应商/往来方" /></el-form-item>
        <el-form-item label="关联应付ID"><el-input v-model="planForm.payable_id" placeholder="选填，关联应付款记录ID" /></el-form-item>
        <el-form-item label="计划金额"><el-input-number v-model="planForm.amount" :min="0.01" :precision="2" style="width:100%" /></el-form-item>
        <el-form-item label="计划付款日"><el-date-picker v-model="planForm.plan_date" type="date" value-format="yyyy-MM-dd" style="width:100%" /></el-form-item>
        <el-form-item label="付款方式">
          <el-select v-model="planForm.method" style="width:100%"><el-option label="银行转账" value="bank" /><el-option label="现金" value="cash" /><el-option label="微信" value="wechat" /><el-option label="支付宝" value="alipay" /></el-select>
        </el-form-item>
        <el-form-item label="备注"><el-input v-model="planForm.remark" /></el-form-item>
      </el-form>
      <template #footer>
        <el-button size="small" @click="planDialog = false">取消</el-button>
        <el-button size="small" type="primary" @click="savePayPlan">保存</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script>
import request from '@/api/request'
import axios from 'axios'
import { getToken } from '@/utils/auth'

// 报表接口走主应用路由（/index.php/finance-report/*），独立实例避免 /api 前缀
const reportRequest = axios.create({ baseURL: '', timeout: 15000 })
reportRequest.interceptors.request.use(config => {
  const token = getToken()
  if (token) config.headers.Authorization = `Bearer ${token}`
  return config
})

export default {
  name: 'Finance',
  data() {
    return {
      tab: 'ar',
      loading: false,
      ov: { ar_total: 0, ar_received: 0, ar_balance: 0, ar_due: 0, ap_total: 0, ap_paid: 0, ap_balance: 0, ap_due: 0, exp_pending: 0 },
      arList: [], apList: [], expList: [],
      arKeyword: '', arStatus: '',
      apKeyword: '', apStatus: '',
      expStatus: '',
      arDialog: false, apDialog: false, moneyDialog: false, expDialog: false,
      arForm: { id: 0, bill_type: 'order', bill_no: '', customer: '', amount: 0, due_date: '', remark: '' },
      apForm: { id: 0, bill_type: 'purchase', bill_no: '', supplier: '', amount: 0, due_date: '', remark: '' },
      moneyForm: { id: 0, amount: 0, method: 'bank', money_date: '', remark: '' },
      moneyMode: 'receipt',
      expForm: { id: 0, category: '', amount: 0, purpose: '' },
      // 报销打款登记
      payDialog: false,
      payForm: { id: 0, applicant_name: '', category: '', amount: 0, method: 'bank', pay_no: '', remark: '' },
      // 付款计划
      planLoading: false,
      payPlanList: [],
      planKeyword: '', planStatus: '',
      planDialog: false,
      planForm: { id: 0, payable_id: 0, supplier: '', amount: 0, plan_date: '', method: 'bank', remark: '' },
      // 采购对账
      reconcilLoading: false,
      reconcilList: [],
      reconcilTotal: { amount: 0, paid: 0, balance: 0 },
      // 账龄分析
      agingType: 'ar',
      agingAsOf: new Date().toISOString().slice(0, 10),
      aging: { buckets: [], total: { amount: 0, overdue: 0, overdue_count: 0 }, list: [] },
      agingLoading: false,
      // 资金流水
      flowType: 'receipt',
      flowRange: [new Date(Date.now() - 29 * 86400000).toISOString().slice(0, 10), new Date().toISOString().slice(0, 10)],
      flowMethod: '',
      flow: { total: { amount: 0, count: 0 }, daily: [], list: [] },
      flowLoading: false,
      // 月度收支汇总
      summaryMonth: new Date().toISOString().slice(0, 7),
      summary: { receipt_total: 0, payment_total: 0, expense_total: 0, net: 0, daily: [] },
      summaryLoading: false,
    }
  },
  computed: {
    moneyDialogTitle() { return this.moneyMode === 'receipt' ? '登记收款' : '登记付款' },
  },
  created() { this.loadAll(); this.loadAging(); this.loadFlow(); this.loadSummary() },
  methods: {
    onTabClick(tab) {
      if (tab.name === 'plan') this.loadPayPlan()
      if (tab.name === 'reconcil') this.loadReconcil()
    },
    loadAll() {
      this.loadAr(); this.loadAp(); this.loadExp(); this.loadOverview()
    },
    async loadAr() {
      try {
        const params = {}
        if (this.arKeyword) params.keyword = this.arKeyword
        if (this.arStatus !== '') params.status = this.arStatus
        const r = await request({ url: '/finance/receivables', method: 'get', params })
        if (r.code === 0) this.arList = (r.data.list || []).map(x => ({ ...x, amount: Number(x.amount), received: Number(x.received), balance: Number(x.balance) }))
      } catch (e) {}
    },
    async loadAp() {
      try {
        const params = {}
        if (this.apKeyword) params.keyword = this.apKeyword
        if (this.apStatus !== '') params.status = this.apStatus
        const r = await request({ url: '/finance/payables', method: 'get', params })
        if (r.code === 0) this.apList = (r.data.list || []).map(x => ({ ...x, amount: Number(x.amount), paid: Number(x.paid), balance: Number(x.balance) }))
      } catch (e) {}
    },
    async loadExp() {
      try {
        const params = {}
        if (this.expStatus !== '') params.status = this.expStatus
        const r = await request({ url: '/finance/expenses', method: 'get', params })
        if (r.code === 0) this.expList = (r.data.list || []).map(x => ({ ...x, amount: Number(x.amount) }))
      } catch (e) {}
    },
    async loadOverview() {
      try {
        const r = await request({ url: '/finance/overview', method: 'get' })
        if (r.code === 0) this.ov = r.data || this.ov
      } catch (e) {}
    },
    openArDialog() {
      this.arForm = { id: 0, bill_type: 'order', bill_no: '', customer: '', amount: 0, due_date: '', remark: '' }
      this.arDialog = true
    },
    async saveAr() {
      if (!this.arForm.customer || this.arForm.amount <= 0) { this.$message.warning('请填写客户和金额'); return }
      const r = await request({ url: '/finance/receivable-save', method: 'post', data: this.arForm })
      if (r.code === 0) { this.$message.success('应收款已登记'); this.arDialog = false; this.loadAr(); this.loadOverview() }
    },
    async delAr(row) {
      await this.$confirm('确认删除该应收款及相关收款记录？', '提示', { type: 'warning' })
      const r = await request({ url: '/finance/receivable-delete', method: 'post', data: { id: row.id } })
      if (r.code === 0) { this.$message.success('已删除'); this.loadAr(); this.loadOverview() }
    },
    openReceiptDialog(row) {
      this.moneyMode = 'receipt'
      this.moneyForm = { id: row.id, amount: Number(row.balance), method: 'bank', money_date: '', remark: '' }
      this.moneyDialog = true
    },
    openApDialog() {
      this.apForm = { id: 0, bill_type: 'purchase', bill_no: '', supplier: '', amount: 0, due_date: '', remark: '' }
      this.apDialog = true
    },
    async saveAp() {
      if (!this.apForm.supplier || this.apForm.amount <= 0) { this.$message.warning('请填写供应商和金额'); return }
      const r = await request({ url: '/finance/payable-save', method: 'post', data: this.apForm })
      if (r.code === 0) { this.$message.success('应付款已登记'); this.apDialog = false; this.loadAp(); this.loadOverview() }
    },
    async delAp(row) {
      await this.$confirm('确认删除该应付款及相关付款记录？', '提示', { type: 'warning' })
      const r = await request({ url: '/finance/payable-delete', method: 'post', data: { id: row.id } })
      if (r.code === 0) { this.$message.success('已删除'); this.loadAp(); this.loadOverview() }
    },
    openPaymentDialog(row) {
      this.moneyMode = 'payment'
      this.moneyForm = { id: row.id, amount: Number(row.balance), method: 'bank', money_date: '', remark: '' }
      this.moneyDialog = true
    },
    async saveMoney() {
      if (this.moneyForm.id <= 0 || this.moneyForm.amount <= 0) return
      const url = this.moneyMode === 'receipt' ? '/finance/receipt-save' : '/finance/payment-save'
      const data = { amount: this.moneyForm.amount, method: this.moneyForm.method, remark: this.moneyForm.remark }
      if (this.moneyMode === 'receipt') { data.receivable_id = this.moneyForm.id; if (this.moneyForm.money_date) data.receipt_at = this.moneyForm.money_date } else { data.payable_id = this.moneyForm.id; if (this.moneyForm.money_date) data.paid_at = this.moneyForm.money_date }
      const r = await request({ url, method: 'post', data })
      if (r.code === 0) { this.$message.success(this.moneyMode === 'receipt' ? '收款已登记' : '付款已登记'); this.moneyDialog = false; this.loadAr(); this.loadAp(); this.loadOverview() }
    },
    openExpDialog() {
      this.expForm = { id: 0, category: '', amount: 0, purpose: '' }
      this.expDialog = true
    },
    async saveExp(submit) {
      if (!this.expForm.category || !this.expForm.purpose || this.expForm.amount <= 0) { this.$message.warning('请填写科目、事由和金额'); return }
      const r = await request({ url: '/finance/expense-save', method: 'post', data: { ...this.expForm, submit: submit ? 1 : 0 } })
      if (r.code === 0) { this.$message.success(submit ? '已提交审批' : '已保存草稿'); this.expDialog = false; this.loadExp(); this.loadOverview() }
    },
    async approveExp(row, action) {
      let remark = ''
      if (action === 'reject') {
        try { remark = (await this.$prompt('请输入驳回原因', '驳回', { inputType: 'textarea' })).value } catch (e) { return }
      }
      const r = await request({ url: '/finance/expense-approve', method: 'post', data: { id: row.id, action, remark } })
      if (r.code === 0) { this.$message.success(action === 'approve' ? '已通过' : '已驳回'); this.loadExp(); this.loadOverview() }
    },
    async delExp(row) {
      await this.$confirm('确认删除该报销申请？', '提示', { type: 'warning' })
      const r = await request({ url: '/finance/expense-delete', method: 'post', data: { id: row.id } })
      if (r.code === 0) { this.$message.success('已删除'); this.loadExp() }
    },
    // ============ 报销打款登记 ============
    openPayDialog(row) {
      this.payForm = { id: row.id, applicant_name: row.applicant_name, category: row.category, amount: row.amount, method: 'bank', pay_no: '', remark: '' }
      this.payDialog = true
    },
    async saveExpPay() {
      if (this.payForm.id <= 0) return
      const r = await request({ url: '/finance/expense-pay', method: 'post', data: { id: this.payForm.id, method: this.payForm.method, pay_no: this.payForm.pay_no, remark: this.payForm.remark } })
      if (r.code === 0) { this.$message.success('打款登记成功'); this.payDialog = false; this.loadExp(); this.loadOverview() }
    },
    // ============ 付款计划 ============
    async loadPayPlan() {
      this.planLoading = true
      try {
        const params = {}
        if (this.planKeyword) params.keyword = this.planKeyword
        if (this.planStatus !== '') params.status = this.planStatus
        const r = await request({ url: '/finance/payable-plan-list', method: 'get', params })
        if (r.code === 0) this.payPlanList = (r.data.list || []).map(x => ({ ...x, amount: Number(x.amount) }))
      } catch (e) {} finally { this.planLoading = false }
    },
    openPlanDialog() {
      this.planForm = { id: 0, payable_id: 0, supplier: '', amount: 0, plan_date: '', method: 'bank', remark: '' }
      this.planDialog = true
    },
    async savePayPlan() {
      if (!this.planForm.supplier || this.planForm.amount <= 0 || !this.planForm.plan_date) { this.$message.warning('请填写供应商、金额和计划付款日期'); return }
      const r = await request({ url: '/finance/payable-plan-save', method: 'post', data: this.planForm })
      if (r.code === 0) { this.$message.success('付款计划已保存'); this.planDialog = false; this.loadPayPlan() }
    },
    async donePayPlan(row) {
      await this.$confirm('确认标记该计划为已付款？将同步登记一笔付款流水。', '提示', { type: 'warning' })
      const r = await request({ url: '/finance/payable-plan-done', method: 'post', data: { id: row.id } })
      if (r.code === 0) { this.$message.success('已标记付款'); this.loadPayPlan(); this.loadAp() }
    },
    async delPayPlan(row) {
      await this.$confirm('确认取消该付款计划？', '提示', { type: 'warning' })
      const r = await request({ url: '/finance/payable-plan-delete', method: 'post', data: { id: row.id } })
      if (r.code === 0) { this.$message.success('已取消'); this.loadPayPlan() }
    },
    // ============ 采购对账 ============
    async loadReconcil() {
      this.reconcilLoading = true
      try {
        const r = await request({ url: '/finance/payable-reconcil', method: 'get' })
        if (r.code === 0) { this.reconcilList = r.data.list || []; this.reconcilTotal = r.data.total || { amount: 0, paid: 0, balance: 0 } }
      } catch (e) {} finally { this.reconcilLoading = false }
    },
    planStatusTag(s) { return { 0: 'info', 1: 'warning', 2: 'success', 4: 'danger', 5: 'info' }[s] || 'info' },
    statusTag(s) { return { 0: 'info', 1: 'warning', 2: 'success', 3: 'danger' }[s] || 'info' },
    // ============ 报表 ============
    async loadAging() {
      this.agingLoading = true
      try {
        const r = await reportRequest({ url: '/index.php/finance-report/aging', method: 'get', params: { type: this.agingType, as_of: this.agingAsOf } })
        if (r.data && r.data.code === 0) this.aging = r.data.data || this.aging
      } catch (e) {} finally { this.agingLoading = false }
    },
    async loadFlow() {
      this.flowLoading = true
      try {
        const params = { type: this.flowType, start_date: this.flowRange[0], end_date: this.flowRange[1] }
        if (this.flowMethod) params.method = this.flowMethod
        const r = await reportRequest({ url: '/index.php/finance-report/flow', method: 'get', params })
        if (r.data && r.data.code === 0) this.flow = r.data.data || this.flow
      } catch (e) {} finally { this.flowLoading = false }
    },
    async loadSummary() {
      this.summaryLoading = true
      try {
        const [y, m] = this.summaryMonth.split('-')
        const r = await reportRequest({ url: '/index.php/finance-report/summary', method: 'get', params: { year: y, month: m } })
        if (r.data && r.data.code === 0) this.summary = r.data.data || this.summary
      } catch (e) {} finally { this.summaryLoading = false }
    },
    bucketLabel(key) {
      return { current: '未到期', d1_30: '逾期1-30天', d31_60: '逾期31-60天', d61_90: '逾期61-90天', d90: '逾期90天以上' }[key] || key
    },
    methodLabel(m) {
      return { bank: '银行转账', cash: '现金', wechat: '微信', alipay: '支付宝' }[m] || m || '-'
    },
  },
}
</script>

<style scoped>
.toolbar { display: flex; gap: 10px; margin-bottom: 14px; align-items: center; }
.toolbar-label { color: #909399; font-size: 13px; }
.sub-title { font-size: 13px; color: #606266; margin: 4px 0 8px; font-weight: 600; }
.ov-cards { display: flex; gap: 14px; margin-bottom: 16px; flex-wrap: wrap; }
.ov-card { flex: 1; min-width: 120px; background: #fff; border-radius: 8px; padding: 14px; text-align: center; box-shadow: 0 1px 4px rgba(0,0,0,.05); }
.ov-num { font-size: 20px; font-weight: 700; color: #409EFF; }
.ov-num.ok { color: #67C23A; }
.ov-num.warn { color: #E6A23C; }
.ov-num.danger { color: #F56C6C; }
.ov-label { color: #909399; font-size: 12px; margin-top: 4px; }
</style>
