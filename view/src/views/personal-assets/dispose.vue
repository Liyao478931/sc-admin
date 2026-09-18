<!--
  文件：admin/src/views/personal-assets/dispose.vue
  功能：资产处置（报废 / 出售 / 捐赠 / 其他）
  权限：asset:dispose:view
-->
<template>
  <div class="dispose-page">
    <el-breadcrumb separator="/" class="breadcrumb">
      <el-breadcrumb-item>资产管理</el-breadcrumb-item>
      <el-breadcrumb-item>固定资产管理</el-breadcrumb-item>
      <el-breadcrumb-item>资产处置</el-breadcrumb-item>
    </el-breadcrumb>

    <!-- 统计卡片 -->
    <div class="dp-stats">
      <div class="dp-stat">
        <div class="dp-num">{{ list.length }}</div>
        <div class="dp-label">处置记录</div>
      </div>
      <div class="dp-stat">
        <div class="dp-num" style="color:#F56C6C">{{ scrapCount }}</div>
        <div class="dp-label">报废</div>
      </div>
      <div class="dp-stat">
        <div class="dp-num" style="color:#E6A23C">{{ sellCount }}</div>
        <div class="dp-label">出售</div>
      </div>
      <div class="dp-stat">
        <div class="dp-num" style="color:#67C23A">{{ sumValue }}</div>
        <div class="dp-label">处置收入（元）</div>
      </div>
    </div>

    <!-- 操作栏 -->
    <div class="dp-toolbar">
      <el-button type="primary" size="small" icon="el-icon-plus" @click="openForm()">登记处置</el-button>
      <el-button size="small" icon="el-icon-refresh" :loading="loading" @click="getList">刷新</el-button>
      <span class="dp-total">共 {{ list.length }} 条</span>
    </div>

    <!-- 筛选 -->
    <el-card shadow="never" class="dp-filter">
      <el-form inline size="small" @submit.native.prevent>
        <el-form-item label="关键词">
          <el-input v-model="q.keyword" placeholder="处置单号/资产名称" clearable style="width:180px" @keyup.enter.native="getList" />
        </el-form-item>
        <el-form-item label="处置类型">
          <el-select v-model="q.type" clearable placeholder="全部" style="width:120px" @change="getList">
            <el-option label="报废" value="scrap" />
            <el-option label="出售" value="sell" />
            <el-option label="捐赠" value="donate" />
            <el-option label="其他" value="other" />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-button type="primary" icon="el-icon-search" @click="getList">搜索</el-button>
          <el-button icon="el-icon-refresh-left" @click="reset">重置</el-button>
        </el-form-item>
      </el-form>
    </el-card>

    <!-- 列表 -->
    <el-card shadow="never">
      <el-table :data="filtered" v-loading="loading" size="small" border stripe empty-text="暂无处置记录">
        <el-table-column type="index" label="序号" width="55" align="center" />
        <el-table-column prop="dispose_no" label="处置单号" width="150" align="center" />
        <el-table-column prop="asset_no" label="资产编号" width="120" />
        <el-table-column prop="asset_name" label="资产名称" min-width="140" show-overflow-tooltip />
        <el-table-column label="处置类型" width="90" align="center">
          <template slot-scope="s"><el-tag :type="typeTag(s.row.dispose_type)" size="mini">{{ s.row.dispose_type_text }}</el-tag></template>
        </el-table-column>
        <el-table-column prop="dispose_date" label="处置日期" width="110" align="center" />
        <el-table-column label="处置收入（元）" width="130" align="right">
          <template slot-scope="s"><b>{{ fmt(s.row.dispose_value) }}</b></template>
        </el-table-column>
        <el-table-column prop="receiver" label="接收方" width="120" show-overflow-tooltip />
        <el-table-column prop="create_by" label="经办人" width="90" />
        <el-table-column prop="created_at" label="登记时间" width="160" align="center" />
        <el-table-column label="操作" width="90" align="center" fixed="right">
          <template slot-scope="s">
            <el-popconfirm title="删除后将还原资产状态，确认？" @onConfirm="doDelete(s.row)">
              <el-button slot="reference" type="danger" size="mini" icon="el-icon-delete" plain>删除</el-button>
            </el-popconfirm>
          </template>
        </el-table-column>
      </el-table>
    </el-card>

    <!-- 登记弹窗 -->
    <el-dialog title="登记资产处置" :visible.sync="formVisible" width="520px" :close-on-click-modal="false">
      <el-form ref="form" :model="form" :rules="rules" label-width="90px" size="small">
        <el-form-item label="处置资产" prop="asset_id">
          <el-select v-model="form.asset_id" filterable remote :remote-method="searchAssets" placeholder="输入资产名称/编号搜索" style="width:100%" :loading="assetLoading">
            <el-option v-for="a in assets" :key="a.id" :label="a.asset_no + ' - ' + a.asset_name" :value="a.id" />
          </el-select>
        </el-form-item>
        <el-form-item label="处置类型" prop="dispose_type">
          <el-radio-group v-model="form.dispose_type">
            <el-radio label="scrap">报废</el-radio>
            <el-radio label="sell">出售</el-radio>
            <el-radio label="donate">捐赠</el-radio>
            <el-radio label="other">其他</el-radio>
          </el-radio-group>
        </el-form-item>
        <el-form-item label="处置日期" prop="dispose_date">
          <el-date-picker v-model="form.dispose_date" type="date" value-format="yyyy-MM-dd" style="width:100%" />
        </el-form-item>
        <el-form-item label="处置收入" prop="dispose_value">
          <el-input-number v-model="form.dispose_value" :min="0" :precision="2" :step="100" style="width:100%" />
        </el-form-item>
        <el-form-item label="接收方">
          <el-input v-model="form.receiver" placeholder="接收方（如废品回收站/买方）" maxlength="50" />
        </el-form-item>
        <el-form-item label="备注">
          <el-input v-model="form.remark" type="textarea" :rows="2" maxlength="200" />
        </el-form-item>
      </el-form>
      <div slot="footer">
        <el-button size="small" @click="formVisible = false">取消</el-button>
        <el-button size="small" type="primary" :loading="saving" @click="submit">确认处置</el-button>
      </div>
    </el-dialog>
  </div>
</template>

<script>
import request from '@/api/request'

export default {
  name: 'AssetDispose',
  data() {
    return {
      loading: false, saving: false, assetLoading: false,
      list: [],
      q: { keyword: '', type: '' },
      formVisible: false,
      form: { id: 0, asset_id: '', dispose_type: 'scrap', dispose_date: new Date().toISOString().slice(0, 10), dispose_value: 0, receiver: '', remark: '' },
      rules: {
        asset_id: [{ required: true, message: '请选择处置资产', trigger: 'change' }],
        dispose_type: [{ required: true, message: '请选择处置类型', trigger: 'change' }],
        dispose_date: [{ required: true, message: '请选择处置日期', trigger: 'change' }]
      },
      assets: []
    }
  },
  computed: {
    filtered() {
      let rows = this.list
      if (this.q.keyword) {
        rows = rows.filter(r => (r.dispose_no || '').indexOf(this.q.keyword) > -1 || (r.asset_name || '').indexOf(this.q.keyword) > -1)
      }
      if (this.q.type) {
        rows = rows.filter(r => r.dispose_type === this.q.type)
      }
      return rows
    },
    scrapCount() { return this.list.filter(r => r.dispose_type === 'scrap').length },
    sellCount() { return this.list.filter(r => r.dispose_type === 'sell').length },
    sumValue() { return this.list.reduce((s, r) => s + (Number(r.dispose_value) || 0), 0) }
  },
  created() {
    this.getList()
  },
  methods: {
    fmt(v) {
      return (Number(v) || 0).toLocaleString('zh-CN', { minimumFractionDigits: 2, maximumFractionDigits: 2 })
    },
    typeTag(t) {
      return { scrap: 'danger', sell: 'warning', donate: 'success', other: 'info' }[t] || 'info'
    },
    async getList() {
      this.loading = true
      try {
        const res = await request({ url: '/finance/asset-dispose/list', method: 'get', params: { keyword: this.q.keyword } })
        if (res.code === 0) {
          this.list = res.data.list
        } else {
          this.$message.error(res.msg || '加载失败')
        }
      } finally {
        this.loading = false
      }
    },
    reset() {
      this.q.keyword = ''
      this.q.type = ''
      this.getList()
    },
    async searchAssets(kw) {
      this.assetLoading = true
      try {
        const res = await request({ url: '/personal-assets/asset-archive/list', method: 'get', params: { keyword: kw || '', status: '1', page: 1, limit: 50 } })
        if (res.code === 0) {
          this.assets = (res.data.list || []).filter(a => Number(a.asset_status || a.status) !== 5)
        }
      } finally {
        this.assetLoading = false
      }
    },
    openForm() {
      this.form = { id: 0, asset_id: '', dispose_type: 'scrap', dispose_date: new Date().toISOString().slice(0, 10), dispose_value: 0, receiver: '', remark: '' }
      this.assets = []
      this.formVisible = true
      this.searchAssets('')
    },
    submit() {
      if (this.saving) return
      this.$refs.form.validate(async valid => {
        if (!valid) return
        this.saving = true
        try {
          const res = await request({ url: '/finance/asset-dispose/save', method: 'post', data: { ...this.form } })
          if (res.code === 0) {
            this.$message.success('处置登记成功')
            this.formVisible = false
            this.getList()
          }
        } finally {
          this.saving = false
        }
      })
    },
    async doDelete(row) {
      const res = await request({ url: '/finance/asset-dispose/delete', method: 'post', data: { id: row.id } })
      if (res.code === 0) {
        this.$message.success('已删除并还原资产')
        this.getList()
      }
    }
  }
}
</script>

<style scoped>
.dispose-page { padding: 4px; }
.breadcrumb { margin-bottom: 12px; }
.dp-stats { display: flex; gap: 10px; flex-wrap: wrap; margin-bottom: 12px; }
.dp-stat {
  flex: 1 1 150px; min-width: 0; padding: 14px; border-radius: 10px;
  background: linear-gradient(135deg, #f5f7fa, #fff); border: 1px solid #ebeef5; text-align: center;
}
.dp-num { font-size: 22px; font-weight: 700; color: #303133; }
.dp-label { font-size: 12px; color: #909399; margin-top: 4px; }
.dp-toolbar { display: flex; align-items: center; margin-bottom: 10px; gap: 8px; }
.dp-total { color: #909399; font-size: 12px; }
.dp-filter { margin-bottom: 12px; }
</style>
