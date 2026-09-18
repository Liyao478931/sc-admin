<!--
  文件：admin/src/views/finance/Voucher.vue
  功能：财务总账/凭证（凭证管理 / 总账查询 / 会计科目）
  权限：finance:voucher:view/add/edit/delete/post + finance:subject:manage
-->
<template>
  <div class="voucher-page">
    <el-breadcrumb separator="/" class="breadcrumb">
      <el-breadcrumb-item>财务管理</el-breadcrumb-item>
      <el-breadcrumb-item>财务总账</el-breadcrumb-item>
    </el-breadcrumb>

    <el-tabs v-model="activeTab" @tab-click="onTabClick">
      <!-- ============ 凭证管理 ============ -->
      <el-tab-pane label="凭证管理" name="voucher">
        <el-card shadow="never" class="filter-card">
          <el-form inline size="small" label-width="80px" @submit.native.prevent>
            <el-form-item label="关键词">
              <el-input v-model="q.keyword" placeholder="凭证号/摘要" clearable style="width:180px" @keyup.enter.native="search" />
            </el-form-item>
            <el-form-item label="记账日期">
              <el-date-picker v-model="q.voucher_date" type="date" value-format="yyyy-MM-dd" placeholder="选择日期" clearable style="width:150px" @change="search" />
            </el-form-item>
            <el-form-item label="状态">
              <el-select v-model="q.status" placeholder="全部" clearable style="width:110px" @change="search">
                <el-option label="草稿" value="0" />
                <el-option label="已过账" value="1" />
                <el-option label="已作废" value="2" />
              </el-select>
            </el-form-item>
            <el-form-item>
              <el-button type="primary" icon="el-icon-search" @click="search">查询</el-button>
              <el-button icon="el-icon-refresh-left" @click="reset">重置</el-button>
            </el-form-item>
          </el-form>
        </el-card>

        <el-card shadow="never">
          <div class="toolbar">
            <el-button v-permission="'finance:voucher:add'" type="primary" size="small" icon="el-icon-plus" @click="openForm()">新增凭证</el-button>
            <el-button v-permission="'finance:voucher:add'" type="warning" size="small" icon="el-icon-finished" :loading="closing" @click="doClose">期末结转</el-button>
            <el-button size="small" icon="el-icon-refresh" @click="getList">刷新</el-button>
            <span class="flex-1"></span>
            <span class="total-tip">共 {{ total }} 张</span>
          </div>

          <el-table :data="list" v-loading="loading" size="small" stripe border>
            <el-table-column type="index" label="序号" width="55" align="center" />
            <el-table-column prop="voucher_no" label="凭证字号" width="160" align="center" />
            <el-table-column prop="voucher_date" label="记账日期" width="110" align="center" />
            <el-table-column prop="summary" label="摘要" min-width="160" show-overflow-tooltip />
            <el-table-column prop="total_debit" label="借方合计" width="120" align="right">
              <template slot-scope="s"><b class="blue">{{ s.row.total_debit }}</b></template>
            </el-table-column>
            <el-table-column prop="total_credit" label="贷方合计" width="120" align="right">
              <template slot-scope="s"><b class="green">{{ s.row.total_credit }}</b></template>
            </el-table-column>
            <el-table-column label="状态" width="85" align="center">
              <template slot-scope="s">
                <el-tag size="mini" :type="s.row.status === 1 ? 'success' : (s.row.status === 2 ? 'info' : 'warning')">{{ s.row.status_text }}</el-tag>
              </template>
            </el-table-column>
            <el-table-column label="来源" width="90" align="center">
              <template slot-scope="s">
                <span v-if="s.row.source_type === 'manual'">手工录入</span>
                <span v-else-if="s.row.source_type === 'expense'">费用报销</span>
                <span v-else-if="s.row.source_type === 'receivable'">应收单</span>
                <span v-else-if="s.row.source_type === 'payable'">应付单</span>
                <span v-else>{{ s.row.source_type }}</span>
              </template>
            </el-table-column>
            <el-table-column prop="create_by" label="制单人" width="90" align="center" />
            <el-table-column prop="created_at" label="制单时间" width="155" align="center" />
            <el-table-column label="操作" width="170" align="center" fixed="right">
              <template slot-scope="s">
                <el-button type="text" size="mini" @click="viewDetail(s.row.id)">详情</el-button>
                <el-button v-if="s.row.status === 0" v-permission="'finance:voucher:post'" type="text" size="mini" class="green" @click="doPost(s.row.id)">过账</el-button>
                <el-button v-if="s.row.status === 0" v-permission="'finance:voucher:edit'" type="text" size="mini" @click="openForm(s.row)">编辑</el-button>
                <el-button v-if="s.row.status === 1 && s.row.reversed !== 1" v-permission="'finance:voucher:add'" type="text" size="mini" class="danger" @click="doRedFlush(s.row.id)">红冲</el-button>
                <el-button v-if="s.row.status === 0" v-permission="'finance:voucher:delete'" type="text" size="mini" class="danger" @click="doDelete(s.row.id)">删除</el-button>
                <el-button v-if="s.row.status === 0" v-permission="'finance:voucher:delete'" type="text" size="mini" class="danger" @click="doCancel(s.row.id)">作废</el-button>
              </template>
            </el-table-column>
          </el-table>

          <el-pagination class="pager" background layout="total, prev, pager, next" :total="total"
            :page-size="q.pageSize" :current-page="q.page" @current-change="p => { q.page = p; getList() }" />
        </el-card>
      </el-tab-pane>

      <!-- ============ 总账查询 ============ -->
      <el-tab-pane label="总账查询" name="ledger-detail">
        <el-card shadow="never" class="filter-card">
          <el-form inline size="small" label-width="80px">
            <el-form-item label="核算期间">
              <el-date-picker v-model="ldPeriod" type="month" value-format="yyyy-MM" placeholder="选择月份" style="width:130px" @change="getLedgerDetail" />
            </el-form-item>
            <el-form-item label="科目">
              <el-select v-model="ldSubject" filterable clearable placeholder="全部科目" style="width:200px" @change="getLedgerDetail">
                <el-option v-for="s in subjects" :key="s.subject_code" :label="s.subject_code + ' ' + s.subject_name" :value="s.subject_code" />
              </el-select>
            </el-form-item>
            <el-form-item>
              <el-button type="primary" icon="el-icon-search" @click="getLedgerDetail">查询</el-button>
              <span class="ledger-tip">期间已过账凭证 {{ ld.voucher_count }} 张，借方合计 <b class="blue">{{ ld.total_debit }}</b>，贷方合计 <b class="green">{{ ld.total_credit }}</b></span>
            </el-form-item>
          </el-form>
        </el-card>
        <el-card shadow="never">
          <el-table :data="ld.items" v-loading="ldLoading" size="small" stripe border>
            <el-table-column type="index" label="序号" width="55" align="center" />
            <el-table-column prop="subject_code" label="科目编码" width="130" align="center" />
            <el-table-column prop="subject_name" label="科目名称" min-width="160" show-overflow-tooltip />
            <el-table-column label="科目类型" width="90" align="center">
              <template slot-scope="s">
                <el-tag size="mini" :type="['', '', '', '', 'warning', 'success'][s.row.subject_type]">{{ ['', '资产', '负债', '权益', '成本', '损益'][s.row.subject_type] }}</el-tag>
              </template>
            </el-table-column>
            <el-table-column label="余额方向" width="85" align="center">
              <template slot-scope="s">{{ s.row.direction === 1 ? '借' : '贷' }}</template>
            </el-table-column>
            <el-table-column prop="debit" label="本期借方" width="130" align="right">
              <template slot-scope="s"><b class="blue">{{ s.row.debit }}</b></template>
            </el-table-column>
            <el-table-column prop="credit" label="本期贷方" width="130" align="right">
              <template slot-scope="s"><b class="green">{{ s.row.credit }}</b></template>
            </el-table-column>
            <el-table-column label="本期净额" width="130" align="right">
              <template slot-scope="s">
                <b :class="s.row.balance >= 0 ? 'blue' : 'red'">{{ s.row.balance }}</b>
              </template>
            </el-table-column>
          </el-table>
          <el-empty v-if="!ldLoading && !ld.items.length" description="该期间暂无过账凭证，或所选科目无发生额" :image-size="80" />
        </el-card>
      </el-tab-pane>

      <!-- ============ 科目余额表 ============ -->
      <el-tab-pane label="科目余额表" name="ledger">
        <el-card shadow="never" class="filter-card">
          <el-form inline size="small" label-width="80px">
            <el-form-item label="核算期间">
              <el-input v-model="ledgerPeriod" placeholder="如 2026-09" style="width:110px" />
            </el-form-item>
            <el-form-item>
              <el-button type="primary" icon="el-icon-search" @click="getLedger">查询</el-button>
              <el-button v-permission="'finance:subject:manage'" icon="el-icon-edit-outline" @click="openOpening">设置期初余额</el-button>
            </el-form-item>
          </el-form>
        </el-card>

        <el-card shadow="never">
          <el-table :data="ledger.items" v-loading="ledgerLoading" size="small" stripe border>
            <el-table-column type="index" label="序号" width="55" align="center" />
            <el-table-column prop="subject_code" label="科目编码" width="120" align="center" />
            <el-table-column prop="subject_name" label="科目名称" width="150" />
            <el-table-column label="科目类型" width="90" align="center">
              <template slot-scope="s">
                <el-tag size="mini" :type="['', '', '', '', 'warning', 'success'][s.row.subject_type]">{{ ['', '资产', '负债', '权益', '成本', '损益'][s.row.subject_type] }}</el-tag>
              </template>
            </el-table-column>
            <el-table-column label="余额方向" width="85" align="center">
              <template slot-scope="s">{{ s.row.direction === 1 ? '借' : '贷' }}</template>
            </el-table-column>
            <el-table-column prop="opening" label="期初余额" width="120" align="right">
              <template slot-scope="s"><span>{{ s.row.opening }}</span></template>
            </el-table-column>
            <el-table-column prop="debit" label="本期借方" width="120" align="right">
              <template slot-scope="s"><b class="blue">{{ s.row.debit }}</b></template>
            </el-table-column>
            <el-table-column prop="credit" label="本期贷方" width="120" align="right">
              <template slot-scope="s"><b class="green">{{ s.row.credit }}</b></template>
            </el-table-column>
            <el-table-column label="期末余额" width="130" align="right">
              <template slot-scope="s">
                <b :class="s.row.ending >= 0 ? 'blue' : 'red'">{{ s.row.ending }}</b>
              </template>
            </el-table-column>
          </el-table>
          <el-empty v-if="!ledgerLoading && !ledger.items.length" description="该期间暂无科目余额数据（含期初或发生额）" :image-size="80" />
        </el-card>
      </el-tab-pane>

      <!-- ============ 会计科目 ============ -->
      <el-tab-pane label="会计科目" name="subject">
        <el-card shadow="never">
          <div class="toolbar">
            <el-button v-permission="'finance:subject:manage'" type="primary" size="small" icon="el-icon-plus" @click="openSubject()">新增科目</el-button>
            <el-button size="small" icon="el-icon-refresh" @click="getSubjects">刷新</el-button>
            <span class="flex-1"></span>
            <span class="total-tip">共 {{ subjects.length }} 个科目</span>
          </div>
          <el-table :data="subjects" v-loading="subLoading" size="small" stripe border>
            <el-table-column prop="subject_code" label="科目编码" width="120" align="center" />
            <el-table-column prop="subject_name" label="科目名称" min-width="150" />
            <el-table-column label="科目类型" width="100" align="center">
              <template slot-scope="s">
                <el-tag size="mini" :type="['', '', '', '', 'warning', 'success'][s.row.subject_type]">{{ ['', '资产', '负债', '权益', '成本', '损益'][s.row.subject_type] }}</el-tag>
              </template>
            </el-table-column>
            <el-table-column label="余额方向" width="90" align="center">
              <template slot-scope="s">{{ s.row.direction === 1 ? '借' : '贷' }}</template>
            </el-table-column>
            <el-table-column label="现金银行类" width="100" align="center">
              <template slot-scope="s">{{ s.row.is_cash === 1 ? '是' : '否' }}</template>
            </el-table-column>
            <el-table-column label="状态" width="80" align="center">
              <template slot-scope="s"><el-tag size="mini" :type="s.row.status === 1 ? 'success' : 'info'">{{ s.row.status === 1 ? '启用' : '停用' }}</el-tag></template>
            </el-table-column>
            <el-table-column label="操作" width="90" align="center">
              <template slot-scope="s">
                <el-button v-permission="'finance:subject:manage'" type="text" size="mini" @click="openSubject(s.row)">编辑</el-button>
              </template>
            </el-table-column>
          </el-table>
        </el-card>
      </el-tab-pane>
    </el-tabs>

    <!-- 凭证编辑弹窗 -->
    <el-dialog :title="form.id ? '编辑凭证' : '新增凭证'" :visible.sync="formVisible" width="760px" top="6vh">
      <el-form label-width="80px" size="small">
        <el-form-item label="记账日期" required>
          <el-date-picker v-model="form.voucher_date" type="date" value-format="yyyy-MM-dd" placeholder="选择日期" style="width:160px" />
        </el-form-item>
        <el-form-item label="摘要" required>
          <el-input v-model="form.summary" placeholder="凭证摘要，如：销售收入确认" />
        </el-form-item>
        <el-form-item label="分录明细">
          <div class="items-wrap">
            <div class="items-head">
              <span class="w-code">科目</span><span class="w-name">摘要</span><span class="w-amt">借方金额</span><span class="w-amt">贷方金额</span><span class="w-ops"></span>
            </div>
            <div v-for="(it, idx) in form.items" :key="idx" class="items-row">
              <el-select v-model="it.subject_code" filterable placeholder="选择科目" size="mini" class="w-code" @change="c => pickSubject(it, c)">
                <el-option v-for="s in subjects" :key="s.subject_code" :label="s.subject_code + ' ' + s.subject_name" :value="s.subject_code" />
              </el-select>
              <el-input v-model="it.summary" placeholder="分录摘要" size="mini" class="w-name" />
              <el-input-number v-model="it.debit" :min="0" :precision="2" :controls="false" size="mini" class="w-amt" placeholder="借方" />
              <el-input-number v-model="it.credit" :min="0" :precision="2" :controls="false" size="mini" class="w-amt" placeholder="贷方" />
              <el-button type="text" size="mini" class="danger" icon="el-icon-delete" @click="removeItem(idx)" />
            </div>
            <el-button type="text" size="small" icon="el-icon-plus" @click="addItem">添加分录</el-button>
          </div>
        </el-form-item>
        <el-form-item label="借贷平衡">
          <b :class="isBalanced ? 'green' : 'red'">借 {{ totalDebit }} / 贷 {{ totalCredit }}</b>
          <span v-if="!isBalanced" class="tip-warn">借贷不平衡，无法保存</span>
        </el-form-item>
      </el-form>
      <div slot="footer">
        <el-button size="small" @click="formVisible = false">取消</el-button>
        <el-button type="primary" size="small" :loading="saving" @click="saveForm">保存凭证</el-button>
      </div>
    </el-dialog>

    <!-- 凭证详情弹窗 -->
    <el-dialog title="凭证详情" :visible.sync="detailVisible" width="720px">
      <div v-if="detail.voucher" class="voucher-doc">
        <div class="doc-head">
          <div class="doc-no">记账凭证</div>
          <div class="doc-meta">
            <span>凭证字号：{{ detail.voucher.voucher_no }}</span>
            <span>日期：{{ detail.voucher.voucher_date }}</span>
            <el-tag size="mini" :type="detail.voucher.status === 1 ? 'success' : 'warning'" class="doc-status">{{ detail.voucher.status_text }}</el-tag>
          </div>
        </div>
        <div class="doc-summary">摘要：{{ detail.voucher.summary }}</div>
        <table class="doc-table">
          <thead><tr><th style="width:40px">#</th><th>科目</th><th>摘要</th><th>借方金额</th><th>贷方金额</th></tr></thead>
          <tbody>
            <tr v-for="(it, i) in detail.items" :key="i">
              <td>{{ i + 1 }}</td>
              <td>{{ it.subject_code }} {{ it.subject_name }}</td>
              <td>{{ it.summary }}</td>
              <td class="right">{{ Number(it.debit) > 0 ? it.debit : '' }}</td>
              <td class="right">{{ Number(it.credit) > 0 ? it.credit : '' }}</td>
            </tr>
            <tr class="doc-total">
              <td colspan="3" class="right">合计</td>
              <td class="right blue">{{ detail.voucher.total_debit }}</td>
              <td class="right green">{{ detail.voucher.total_credit }}</td>
            </tr>
          </tbody>
        </table>
        <div class="doc-foot">
          <span>制单：{{ detail.voucher.create_by }}</span>
          <span v-if="detail.voucher.audit_by">审核：{{ detail.voucher.audit_by }} {{ detail.voucher.audit_time }}</span>
          <span v-if="detail.voucher.source_type !== 'manual'">来源：{{ detail.voucher.source_type }}</span>
        </div>
      </div>
    </el-dialog>

    <!-- 科目编辑弹窗 -->
    <el-dialog :title="subjectForm.id ? '编辑科目' : '新增科目'" :visible.sync="subjectVisible" width="440px">
      <el-form label-width="100px" size="small">
        <el-form-item label="科目编码" required>
          <el-input v-model="subjectForm.subject_code" placeholder="如 1001" :disabled="!!subjectForm.id" />
        </el-form-item>
        <el-form-item label="科目名称" required>
          <el-input v-model="subjectForm.subject_name" placeholder="如 银行存款" />
        </el-form-item>
        <el-form-item label="科目类型">
          <el-select v-model="subjectForm.subject_type" style="width:200px">
            <el-option :label="t" :value="v" v-for="(t, v) in ['', '资产', '负债', '权益', '成本', '损益']" :key="v" :disabled="!v" />
          </el-select>
        </el-form-item>
        <el-form-item label="余额方向">
          <el-radio-group v-model="subjectForm.direction">
            <el-radio :label="1">借方</el-radio>
            <el-radio :label="2">贷方</el-radio>
          </el-radio-group>
        </el-form-item>
        <el-form-item label="现金银行类">
          <el-switch v-model="subjectForm.is_cash" :active-value="1" :inactive-value="0" />
        </el-form-item>
        <el-form-item label="状态">
          <el-switch v-model="subjectForm.status" :active-value="1" :inactive-value="0" active-text="启用" inactive-text="停用" />
        </el-form-item>
      </el-form>
      <div slot="footer">
        <el-button size="small" @click="subjectVisible = false">取消</el-button>
        <el-button type="primary" size="small" :loading="saving" @click="saveSubject">保存</el-button>
      </div>
    </el-dialog>

    <!-- 设置期初余额 -->
    <el-dialog title="设置科目期初余额" :visible.sync="openingVisible" width="560px" top="6vh" custom-class="fin-dialog">
      <div style="margin-bottom:10px;color:#909399;font-size:12px;">仅填写有期初余额的科目，未填写的科目期初为 0。余额方向：借方科目填正数，贷方科目填负数。</div>
      <el-table :data="openingItems" v-loading="openingLoading" size="small" max-height="420" stripe border>
        <el-table-column type="index" label="#" width="45" align="center" />
        <el-table-column prop="subject_code" label="科目编码" width="100" align="center" />
        <el-table-column prop="subject_name" label="科目名称" width="150" show-overflow-tooltip />
        <el-table-column label="方向" width="60" align="center">
          <template slot-scope="s">{{ s.row.direction === 1 ? '借' : '贷' }}</template>
        </el-table-column>
        <el-table-column label="期初余额" width="160">
          <template slot-scope="s">
            <el-input-number v-model="s.row.opening_balance" :controls="false" :precision="2" size="mini" style="width:100%" placeholder="0.00" />
          </template>
        </el-table-column>
      </el-table>
      <div slot="footer" class="dialog-footer">
        <el-button size="small" @click="openingVisible = false">取消</el-button>
        <el-button type="primary" size="small" :loading="openingLoading" @click="saveOpening">保存期初余额</el-button>
      </div>
    </el-dialog>
  </div>
</template>

<script>
import request from '@/api/request'

export default {
  name: 'FinanceVoucher',
  data() {
    return {
      activeTab: 'voucher',
      loading: false, saving: false, subLoading: false,
      list: [], total: 0,
      q: { page: 1, pageSize: 10, keyword: '', voucher_date: '', status: '' },
      ledger: { items: [], total_debit: 0, total_credit: 0, voucher_count: 0 },
      ledgerLoading: false, ledgerPeriod: new Date().toISOString().slice(0, 7), ledgerSubject: '',
      ld: { items: [], total_debit: 0, total_credit: 0, voucher_count: 0 },
      ldLoading: false, ldPeriod: new Date().toISOString().slice(0, 7), ldSubject: '',
      closing: false,
      openingVisible: false, openingLoading: false, openingItems: [],
      subjects: [],
      formVisible: false, form: { id: 0, voucher_date: '', summary: '', items: [] },
      detailVisible: false, detail: { voucher: null, items: [] },
      subjectVisible: false, subjectForm: { id: 0, subject_code: '', subject_name: '', subject_type: 1, direction: 1, is_cash: 0, status: 1 }
    }
  },
  computed: {
    totalDebit() { return this.form.items.reduce((s, x) => s + (Number(x.debit) || 0), 0).toFixed(2) },
    totalCredit() { return this.form.items.reduce((s, x) => s + (Number(x.credit) || 0), 0).toFixed(2) },
    isBalanced() { return Math.abs(parseFloat(this.totalDebit) - parseFloat(this.totalCredit)) < 0.01 && parseFloat(this.totalDebit) > 0 }
  },
  created() {
    const t = this.$route.meta && this.$route.meta.initialTab
    if (t === 'subject' || t === 'ledger-detail') this.activeTab = t
    this.getList(); this.getSubjects()
    if (this.activeTab === 'ledger-detail') this.getLedgerDetail()
  },
  watch: {
    '$route'() {
      const t = this.$route.meta && this.$route.meta.initialTab
      if (t === 'subject' || t === 'ledger-detail') {
        this.activeTab = t
        if (t === 'ledger-detail') this.getLedgerDetail()
      }
    }
  },
  methods: {
    async req(url, method, data, params) {
      try { return await request({ url, method, data, params }) } catch (e) { this.$message.error('请求失败'); return null }
    },
    async getList() {
      this.loading = true
      const r = await this.req('/finance/voucher/list', 'get', null, this.q)
      if (r && r.code === 0) { this.list = r.data.list || []; this.total = r.data.total || 0 }
      this.loading = false
    },
    async getSubjects() {
      const r = await this.req('/finance/voucher/subjects', 'get')
      if (r && r.code === 0) this.subjects = r.data.list || []
    },
    async getLedger() {
      this.ledgerLoading = true
      const r = await this.req('/finance/voucher/subject-balance', 'get', null, { period: this.ledgerPeriod })
      if (r && r.code === 0) this.ledger = r.data
      this.ledgerLoading = false
    },
    async getLedgerDetail() {
      this.ldLoading = true
      const r = await this.req('/finance/voucher/ledger', 'get', null, { period: this.ldPeriod, subject: this.ldSubject })
      if (r && r.code === 0) this.ld = r.data
      this.ldLoading = false
    },
    async doRedFlush(id) {
      const c = await this.$confirm('红冲将生成一张红字凭证并自动过账（借贷相反），原凭证标记已红冲。确认继续？', '红冲确认', { type: 'warning' }).catch(() => null)
      if (!c) return
      const r = await this.req(`/finance/voucher/red-flush/${id}`, 'post')
      if (r && r.code === 0) { this.$message.success(r.msg); this.getList() }
    },
    async doClose() {
      const c = await this.$confirm('期末结转将把核算期间内损益类科目净发生额结转到"本年利润"，生成结转凭证。确认执行？', '期末结转', { type: 'warning' }).catch(() => null)
      if (!c) return
      this.closing = true
      const r = await this.req('/finance/voucher/period-close', 'post', { period: this.ledgerPeriod })
      this.closing = false
      if (r && r.code === 0) { this.$message.success(r.msg); this.getList() }
    },
    async openOpening() {
      this.openingVisible = true; this.openingLoading = true
      const r = await this.req('/finance/voucher/subjects', 'get')
      if (r && r.code === 0) this.openingItems = (r.data.subjects || r.data.list || []).map(s => ({ subject_code: s.subject_code, subject_name: s.subject_name, direction: s.direction, opening_balance: Number(s.opening_balance) || 0 }))
      this.openingLoading = false
    },
    async saveOpening() {
      const items = this.openingItems.filter(x => x.opening_balance !== 0 && x.opening_balance !== '' && x.opening_balance !== null)
      if (!items.length) { this.$message.warning('请至少填写一个科目的期初余额'); return }
      const r = await this.req('/finance/voucher/opening-save', 'post', { items })
      if (r && r.code === 0) { this.$message.success(r.msg); this.openingVisible = false; this.getLedger() }
    },
    search() { this.q.page = 1; this.getList() },
    onTabClick(tab) {
      if (tab.name === 'ledger-detail' && !this.ld.items.length) this.getLedgerDetail()
    },
    reset() { this.q = { page: 1, pageSize: 10, keyword: '', voucher_date: '', status: '' }; this.search() },
    openForm(row) {
      if (row) {
        this.form = { id: row.id, voucher_date: row.voucher_date, summary: row.summary, items: [] }
        this.req(`/finance/voucher/detail/${row.id}`, 'get').then(r => {
          if (r && r.code === 0) this.form.items = (r.data.items || []).map(x => ({ subject_code: x.subject_code, subject_name: x.subject_name, summary: x.summary, debit: Number(x.debit), credit: Number(x.credit) }))
        })
      } else {
        this.form = { id: 0, voucher_date: new Date().toISOString().slice(0, 10), summary: '', items: [{ subject_code: '', summary: '', debit: 0, credit: 0 }] }
      }
      this.formVisible = true
    },
    addItem() { this.form.items.push({ subject_code: '', summary: '', debit: 0, credit: 0 }) },
    removeItem(i) { this.form.items.splice(i, 1) },
    pickSubject(it, code) {
      const s = this.subjects.find(x => x.subject_code === code)
      if (s) it.subject_name = s.subject_name
    },
    async saveForm() {
      if (!this.form.voucher_date || !this.form.summary) { this.$message.warning('请填写日期和摘要'); return }
      if (!this.isBalanced) { this.$message.warning('借贷不平衡，无法保存'); return }
      this.saving = true
      const r = await this.req('/finance/voucher/save', 'post', this.form)
      if (r && r.code === 0) { this.$message.success('保存成功'); this.formVisible = false; this.getList() }
      else if (r) this.$message.error(r.msg || '保存失败')
      this.saving = false
    },
    async viewDetail(id) {
      const r = await this.req(`/finance/voucher/detail/${id}`, 'get')
      if (r && r.code === 0) { this.detail = r.data; this.detailVisible = true }
    },
    doPost(id) {
      this.$confirm('确认过账该凭证？过账后不可修改。', '过账确认', { type: 'warning' }).then(async () => {
        const r = await this.req(`/finance/voucher/post/${id}`, 'post')
        if (r && r.code === 0) { this.$message.success('已过账'); this.getList() }
        else if (r) this.$message.error(r.msg || '过账失败')
      }).catch(() => {})
    },
    doDelete(id) {
      this.$confirm('确认删除该草稿凭证？', '删除确认', { type: 'warning' }).then(async () => {
        const r = await this.req(`/finance/voucher/delete/${id}`, 'post')
        if (r && r.code === 0) { this.$message.success('已删除'); this.getList() }
        else if (r) this.$message.error(r.msg || '删除失败')
      }).catch(() => {})
    },
    doCancel(id) {
      this.$confirm('确认作废该凭证？', '作废确认', { type: 'warning' }).then(async () => {
        const r = await this.req(`/finance/voucher/cancel/${id}`, 'post')
        if (r && r.code === 0) { this.$message.success('已作废'); this.getList() }
        else if (r) this.$message.error(r.msg || '操作失败')
      }).catch(() => {})
    },
    openSubject(row) {
      this.subjectForm = row ? { ...row } : { id: 0, subject_code: '', subject_name: '', subject_type: 1, direction: 1, is_cash: 0, status: 1 }
      this.subjectVisible = true
    },
    async saveSubject() {
      if (!this.subjectForm.subject_code || !this.subjectForm.subject_name) { this.$message.warning('请填写编码和名称'); return }
      this.saving = true
      const r = await this.req('/finance/voucher/subjectSave', 'post', this.subjectForm)
      if (r && r.code === 0) { this.$message.success('保存成功'); this.subjectVisible = false; this.getSubjects() }
      else if (r) this.$message.error(r.msg || '保存失败')
      this.saving = false
    }
  }
}
</script>

<style scoped>
.breadcrumb { margin-bottom: 12px; }
.filter-card { margin-bottom: 12px; }
.toolbar { display: flex; align-items: center; margin-bottom: 12px; }
.flex-1 { flex: 1; }
.total-tip { color: #909399; font-size: 13px; }
.pager { margin-top: 12px; text-align: right; }
.blue { color: #409EFF; }
.green { color: #67C23A; }
.red { color: #F56C6C; }
.danger { color: #F56C6C; }
.summary-card { margin-bottom: 12px; }
.sum-item { padding: 8px 4px; }
.sum-label { color: #909399; font-size: 12px; margin-bottom: 4px; }
.sum-value { font-size: 15px; font-weight: 600; color: #303133; }
.items-wrap { width: 100%; border: 1px solid #EBEEF5; border-radius: 6px; padding: 10px; }
.items-head { display: flex; color: #909399; font-size: 12px; margin-bottom: 6px; }
.items-row { display: flex; align-items: center; margin-bottom: 6px; gap: 6px; }
.w-code { width: 200px; }
.w-name { flex: 1; }
.w-amt { width: 130px; }
.w-ops { width: 36px; }
.tip-warn { color: #E6A23C; font-size: 12px; margin-left: 10px; }
.voucher-doc { border: 1px solid #DCDFE6; border-radius: 8px; padding: 16px; }
.doc-head { display: flex; align-items: center; justify-content: space-between; margin-bottom: 10px; }
.doc-no { font-size: 18px; font-weight: 700; color: #303133; }
.doc-meta { display: flex; align-items: center; gap: 14px; color: #606266; font-size: 13px; }
.doc-summary { color: #606266; font-size: 13px; margin-bottom: 10px; }
.doc-table { width: 100%; border-collapse: collapse; font-size: 13px; }
.doc-table th, .doc-table td { border: 1px solid #EBEEF5; padding: 7px 10px; text-align: left; }
.doc-table .right { text-align: right; }
.doc-total { font-weight: 600; background: #F5F7FA; }
.doc-foot { display: flex; gap: 24px; margin-top: 12px; color: #909399; font-size: 12px; }
</style>
