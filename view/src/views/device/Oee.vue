<template>
  <div class="page-container">
    <el-card shadow="never" class="filter-card">
      <el-form inline size="small" @submit.native.prevent>
        <el-form-item label="关键词"><el-input v-model="filter.keyword" placeholder="设备名称" clearable style="width:180px" @keyup.enter.native="load" /></el-form-item>
        <el-form-item label="统计日期">
          <el-date-picker v-model="filter.stat_date" type="daterange" value-format="YYYY-MM-DD" range-separator="至" start-placeholder="开始" end-placeholder="结束" style="width:230px" />
        </el-form-item>
        <el-form-item><el-button type="primary" icon="el-icon-search" @click="load">查询</el-button><el-button icon="el-icon-refresh-left" @click="reset">重置</el-button></el-form-item>
      </el-form>
    </el-card>
    <div class="toolbar">
      <el-button v-permission="'device:oee:add'" type="primary" size="small" icon="el-icon-plus" @click="openForm()">新增OEE记录</el-button>
    </div>
    <el-card shadow="never">
      <el-table :data="list" v-loading="loading" border stripe size="small">
        <el-table-column prop="device_name" label="设备" min-width="130" />
        <el-table-column prop="stat_date" label="统计日期" width="105" />
        <el-table-column prop="plan_time" label="计划时间(h)" width="100" />
        <el-table-column prop="run_time" label="运行时间(h)" width="100" />
        <el-table-column prop="avail_rate" label="可用率%" width="90"><template #default="{row}">{{ row.avail_rate }}%</template></el-table-column>
        <el-table-column prop="perf_rate" label="性能率%" width="90"><template #default="{row}">{{ row.perf_rate }}%</template></el-table-column>
        <el-table-column prop="quality_rate" label="良品率%" width="90"><template #default="{row}">{{ row.quality_rate }}%</template></el-table-column>
        <el-table-column prop="oee" label="OEE" width="90">
          <template #default="{row}"><el-tag :type="(row.oee || 0) >= 85 ? 'success' : (row.oee || 0) >= 70 ? 'warning' : 'danger'" size="mini">{{ row.oee }}%</el-tag></template>
        </el-table-column>
        <el-table-column label="操作" width="140" fixed="right">
          <template #default="{row}">
            <el-button type="text" size="small" @click="openForm(row)">编辑</el-button>
            <el-button type="text" size="small" class="danger" @click="del(row)">删除</el-button>
          </template>
        </el-table-column>
      </el-table>
      <el-pagination class="pager" background layout="total, prev, pager, next, sizes" :total="total" :current-page="page" :page-size="pageSize" :page-sizes="[10,20,50,100]" @current-change="p => { page = p; load() }" @size-change="s => { pageSize = s; page = 1; load() }" />
    </el-card>
    <el-dialog :title="form.id ? '编辑OEE记录' : '新增OEE记录'" :visible.sync="formVisible" width="620px">
      <el-form :model="form" label-width="115px" size="small">
        <el-row :gutter="12">
          <el-col :span="12"><el-form-item label="设备"><el-select v-model="form.device_id" filterable clearable style="width:100%" @change="onDeviceChange">
            <el-option v-for="o in deviceOptions" :key="o.id" :label="o.name" :value="o.id" />
          </el-select></el-form-item></el-col>
          <el-col :span="12"><el-form-item label="统计日期"><el-date-picker v-model="form.stat_date" type="date" value-format="YYYY-MM-DD" style="width:100%" /></el-form-item></el-col>
          <el-col :span="12"><el-form-item label="计划时间(h)"><el-input-number v-model="form.plan_time" :min="0" :precision="2" style="width:100%" /></el-form-item></el-col>
          <el-col :span="12"><el-form-item label="运行时间(h)"><el-input-number v-model="form.run_time" :min="0" :precision="2" style="width:100%" /></el-form-item></el-col>
          <el-col :span="8"><el-form-item label="可用率%"><el-input-number v-model="form.avail_rate" :min="0" :max="100" :precision="2" style="width:100%" /></el-form-item></el-col>
          <el-col :span="8"><el-form-item label="性能率%"><el-input-number v-model="form.perf_rate" :min="0" :max="100" :precision="2" style="width:100%" /></el-form-item></el-col>
          <el-col :span="8"><el-form-item label="良品率%"><el-input-number v-model="form.quality_rate" :min="0" :max="100" :precision="2" style="width:100%" /></el-form-item></el-col>
          <el-col :span="12"><el-form-item label="总产量"><el-input-number v-model="form.total_qty" :min="0" style="width:100%" /></el-form-item></el-col>
          <el-col :span="12"><el-form-item label="良品数量"><el-input-number v-model="form.good_qty" :min="0" style="width:100%" /></el-form-item></el-col>
          <el-col :span="24"><el-form-item label="备注"><el-input v-model="form.remark" type="textarea" :rows="2" /></el-form-item></el-col>
        </el-row>
      </el-form>
      <template #footer>
        <el-button size="small" @click="formVisible = false">取消</el-button>
        <el-button size="small" type="primary" :loading="saving" @click="save">保存</el-button>
      </template>
    </el-dialog>
  </div>
</template>
<script>
import request from '@/api/request'
export default {
  name: 'DeviceOee',
  data() {
    return {
      loading: false, saving: false, list: [], total: 0, page: 1, pageSize: 20,
      filter: { keyword: '', stat_date: [] }, deviceOptions: [], formVisible: false,
      form: { id: 0, device_id: 0, device_name: '', stat_date: '', plan_time: 8, run_time: 6, avail_rate: 75, perf_rate: 80, quality_rate: 95, oee: 0, total_qty: 0, good_qty: 0, remark: '' }
    }
  },
  created() { this.load(); this.loadOptions() },
  methods: {
    async load() {
      this.loading = true
      try {
        const params = { page: this.page, pageSize: this.pageSize, keyword: this.filter.keyword }
        if (this.filter.stat_date && this.filter.stat_date.length === 2) { params.start_date = this.filter.stat_date[0]; params.end_date = this.filter.stat_date[1] }
        const res = await request({ url: '/oee/list', method: 'get', params })
        if (res.code === 0) { this.list = res.data.list || []; this.total = res.data.total || 0 }
      } catch (e) { this.$message.error('加载失败') }
      this.loading = false
    },
    async loadOptions() {
      try {
        const res = await request({ url: '/oee/options', method: 'get' })
        if (res.code === 0) this.deviceOptions = res.data || []
      } catch (e) {}
    },
    onDeviceChange(id) {
      const o = this.deviceOptions.find(x => x.id === id)
      if (o) this.form.device_name = o.name
    },
    reset() { this.filter = { keyword: '', stat_date: [] }; this.page = 1; this.load() },
    openForm(row) {
      this.form = row ? { ...row } : { id: 0, device_id: 0, device_name: '', stat_date: '', plan_time: 8, run_time: 6, avail_rate: 75, perf_rate: 80, quality_rate: 95, oee: 0, total_qty: 0, good_qty: 0, remark: '' }
      this.formVisible = true
    },
    async save() {
      if (!this.form.device_name) return this.$message.warning('请选择设备')
      this.form.oee = Number(((this.form.avail_rate / 100) * (this.form.perf_rate / 100) * (this.form.quality_rate / 100) * 100).toFixed(2))
      this.saving = true
      try {
        const res = await request({ url: '/oee/save', method: 'post', data: this.form })
        if (res.code === 0) { this.$message.success('保存成功'); this.formVisible = false; this.load() }
        else this.$message.error(res.msg || '保存失败')
      } catch (e) { this.$message.error('保存失败') }
      this.saving = false
    },
    del(row) {
      this.$confirm('确认删除 ' + row.device_name + ' 的 OEE 记录？', '提示', { type: 'warning' }).then(async () => {
        const res = await request({ url: '/oee/delete', method: 'post', data: { id: row.id } })
        if (res.code === 0) { this.$message.success('已删除'); this.load() }
      }).catch(() => {})
    }
  }
}
</script>
<style scoped>
.page-container { padding: 4px; }
.filter-card { margin-bottom: 10px; }
.toolbar { margin-bottom: 10px; }
.pager { margin-top: 12px; text-align: right; }
</style>
