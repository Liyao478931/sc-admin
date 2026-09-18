<template>
  <el-dialog :title="title" :visible.sync="dialogVisible" width="800px" @open="loadList">
    <div class="src-search">
      <el-input v-model="keyword" size="small" placeholder="输入关键词搜索" clearable prefix-icon="el-icon-search" style="width:240px" @keyup.enter.native="loadList" />
      <el-button size="small" type="primary" icon="el-icon-search" @click="loadList">搜索</el-button>
    </div>
    <el-table :data="list" size="small" border stripe style="width:100%;margin-top:10px" highlight-current-row @row-dblclick="row => select(row)">
      <template v-if="sourceType === 'inspection'">
        <el-table-column prop="record_code" label="巡检编号" width="160" />
        <el-table-column prop="device_name" label="设备名称" min-width="140" />
        <el-table-column prop="device_code" label="设备编码" width="140" />
        <el-table-column prop="plan_execute_date" label="执行日期" width="110" />
        <el-table-column label="状态" width="80"><template slot-scope="{ row }"><el-tag size="mini" type="success">已完成</el-tag></template></el-table-column>
      </template>
      <template v-else-if="sourceType === 'safety_check'">
        <el-table-column prop="check_code" label="检查编号" width="160" />
        <el-table-column prop="location" label="检查地点" min-width="140" />
        <el-table-column prop="check_by_name" label="检查人" width="100" />
        <el-table-column prop="check_time" label="检查时间" width="160" />
      </template>
      <template v-else-if="sourceType === 'repair'">
        <el-table-column prop="repair_code" label="工单编号" width="160" />
        <el-table-column prop="device_name" label="设备名称" min-width="140" />
        <el-table-column prop="device_code" label="设备编码" width="140" />
        <el-table-column prop="repair_type" label="维修类型" width="100" />
      </template>
      <el-table-column label="操作" width="80" align="center">
        <template slot-scope="{ row }"><el-button size="mini" type="text" @click="select(row)">选择</el-button></template>
      </el-table-column>
    </el-table>
    <el-empty v-if="!list.length" :image-size="50" />
  </el-dialog>
</template>

<script>
import { getAvailableInspections, getAvailableSafetyChecks, getAvailableRepairs } from '@/api/safetyHazard'

export default {
  name: 'SourceSelectDialog',
  props: { visible: Boolean, sourceType: { type: String, default: 'inspection' } },
  data() {
    return { dialogVisible: this.visible, keyword: '', list: [] }
  },
  watch: { visible(val) { this.dialogVisible = val } },
  computed: {
    title() { return { inspection: '选择巡检记录', safety_check: '选择安全检查记录', repair: '选择维修工单' }[this.sourceType] || '选择来源记录' }
  },
  methods: {
    async loadList() {
      try {
        let res
        if (this.sourceType === 'inspection') res = await getAvailableInspections(this.keyword)
        else if (this.sourceType === 'safety_check') res = await getAvailableSafetyChecks(this.keyword)
        else res = await getAvailableRepairs(this.keyword)
        this.list = res.code === 0 ? (res.data || []) : []
      } catch (e) { this.list = [] }
    },
    select(row) {
      this.$emit('select', { sourceType: this.sourceType, sourceId: row.id, row })
      this.dialogVisible = false
    }
  }
}
</script>

<style scoped>
.src-search { display: flex; gap: 8px; }
</style>
