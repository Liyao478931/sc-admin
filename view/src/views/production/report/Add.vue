<!--
  文件：admin/src/views/production/report/Add.vue
  功能：新增/编辑报工（个人报工/团队协作 + 工分分配）
  权限：production:report:add / edit
-->
<template>
  <div class="wh-page">
    <el-breadcrumb separator="/" class="breadcrumb">
      <el-breadcrumb-item>生产管理</el-breadcrumb-item>
      <el-breadcrumb-item>生产执行</el-breadcrumb-item>
      <el-breadcrumb-item>生产报工</el-breadcrumb-item>
      <el-breadcrumb-item>{{ isEdit ? '编辑报工' : '新增报工' }}</el-breadcrumb-item>
    </el-breadcrumb>

    <div class="page-header">
      <span class="page-title">{{ isEdit ? '编辑报工' : '新增报工' }}</span>
      <div class="header-actions">
        <el-button size="small" @click="$router.push('/production/report/list')">取消</el-button>
        <el-button size="small" type="primary" :loading="saving" @click="handleSave">保存</el-button>
      </div>
    </div>

    <el-card shadow="never" class="form-card">
      <el-form ref="form" :model="form" :rules="rules" label-width="120px" size="small">
        <el-row :gutter="20">
          <el-col :span="12">
            <el-form-item label="报工模式" prop="report_type">
              <el-select v-model="form.report_type" style="width:100%">
                <el-option :value="1" label="个人报工" />
                <el-option :value="2" label="团队协作" />
              </el-select>
            </el-form-item>
            <el-form-item label="关联工单" prop="work_order_id">
              <el-select v-model="form.work_order_id" filterable placeholder="请选择进行中的工单" style="width:100%" @change="onOrderChange">
                <el-option v-for="o in orderOptions" :key="o.id" :label="`${o.order_no} - ${o.product_name}（${o.product_spec || ''}）`" :value="o.id" />
              </el-select>
              <div v-if="isEdit && form.work_order_no" class="qty-tip">工单：{{ form.work_order_no }}</div>
            </el-form-item>
            <el-form-item label="关联工位">
              <el-select v-model="form.workstation_id" filterable clearable placeholder="选择工位（联动可做工序）" style="width:100%" @change="onWorkstationChange">
                <el-option v-for="w in workstationOptions" :key="w.id" :label="`${w.workstation_name}（可做${w.process_count || 0}道工序）`" :value="w.id" />
              </el-select>
            </el-form-item>
            <el-form-item label="关联工序">
              <el-select v-model="form.process_id" filterable clearable placeholder="选择工序（自动带出工分定额）" style="width:100%" :disabled="!form.workstation_id" @change="onProcessChange">
                <el-option-group v-for="g in processGroups" :key="g" :label="g">
                  <el-option v-for="p in availableProcesses.filter(x => x.process_group === g)" :key="p.process_id" :label="`${p.process_name}（${Number(p.standard_score)}分）`" :value="p.process_id" />
                </el-option-group>
              </el-select>
              <div v-if="form.workstation_id && !availableProcesses.length" class="qty-tip" style="color:#E6A23C">该工位暂未配置可做工序，请先到工位管理中配置工序</div>
            </el-form-item>
            <el-form-item label="关联设备" prop="device_id">
              <el-select v-model="form.device_id" filterable clearable placeholder="选择设备" style="width:100%" :disabled="!form.workstation_id || !deviceOptions.length" @change="onDeviceChange">
                <el-option v-for="d in deviceOptions" :key="d.id" :label="`${d.device_name}（${d.device_code}）`" :value="d.id" />
              </el-select>
              <div v-if="form.workstation_id && !deviceOptions.length" class="qty-tip" style="color:#E6A23C">该工位未关联设备，请先到工位管理中配置设备</div>
            </el-form-item>
            <el-form-item label="任务类型" prop="task_type">
              <el-select v-model="form.task_type" style="width:100%">
                <el-option v-for="(t, v) in taskOptions" :key="v" :label="t" :value="Number(v)" />
              </el-select>
            </el-form-item>
            <el-form-item label="任务描述" prop="task_description">
              <el-input v-model="form.task_description" type="textarea" :rows="3" placeholder="请描述本次完成的工作内容" />
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="完成数量" prop="quantity">
              <el-input-number v-model="form.quantity" :min="1" :precision="0" style="width:100%" @change="onQuantityChange" />
            </el-form-item>
            <el-form-item label="设备时长(小时)" prop="duration">
              <el-input-number v-model="form.duration" :min="0.5" :precision="1" :step="0.5" style="width:100%" />
            </el-form-item>
            <el-form-item label="获取工分" prop="total_score">
              <el-input-number v-model="form.total_score" :min="0.01" :precision="2" style="width:100%" />
              <div class="qty-tip">{{ scoreFormula || '选择工序后自动计算（定额 × 数量）' }}</div>
            </el-form-item>
            <el-form-item label="报工日期" prop="report_date">
              <el-date-picker v-model="form.report_date" type="date" value-format="yyyy-MM-dd" style="width:100%" />
            </el-form-item>
            <el-form-item label="备注">
              <el-input v-model="form.remark" type="textarea" :rows="4" placeholder="备注（可选）" />
            </el-form-item>
          </el-col>
        </el-row>

        <!-- 团队协作：工分分配 -->
        <div v-if="form.report_type === 2">
          <div class="sub-title">工分分配</div>
          <el-button size="small" icon="el-icon-plus" @click="memberVisible = true">添加成员</el-button>
          <el-table :data="form.items" size="small" border style="margin-top:10px">
            <el-table-column type="index" label="#" width="55" align="center" />
            <el-table-column prop="worker_name" label="员工姓名" min-width="160" />
            <el-table-column label="分配工分数" width="200">
              <template slot-scope="s"><el-input-number v-model="s.row.allocated_score" :min="0.01" :precision="2" size="mini" style="width:100%" /></template>
            </el-table-column>
            <el-table-column label="操作" width="80" align="center">
              <template slot-scope="s"><el-button type="text" size="mini" class="danger-text" @click="removeMember(s.$index)">删除</el-button></template>
            </el-table-column>
          </el-table>
          <div class="alloc-stat">
            已分配：<b>{{ allocatedSum }}</b> 分 / 总工分：<b>{{ form.total_score }}</b> 分
            <span v-if="balanceTip" class="balance-warn">{{ balanceTip }}</span>
          </div>
        </div>

        <!-- 材料配件使用 -->
        <div class="sub-title">材料配件使用</div>
        <el-button size="small" icon="el-icon-plus" @click="materialDialogVisible = true">添加材料</el-button>
        <el-table :data="form.materials" size="small" border style="margin-top:10px">
          <el-table-column prop="material_code" label="物料编码" width="120" />
          <el-table-column prop="material_name" label="物料名称" min-width="140" />
          <el-table-column prop="specification" label="规格型号" width="120" show-overflow-tooltip />
          <el-table-column prop="unit" label="单位" width="60" align="center" />
          <el-table-column label="使用数量" width="100" align="right"><template slot-scope="s">{{ s.row.quantity }}</template></el-table-column>
          <el-table-column label="操作" width="70" align="center">
            <template slot-scope="s"><el-button type="text" size="mini" class="danger-text" @click="removeMaterial(s.$index)">删除</el-button></template>
          </el-table-column>
        </el-table>

        <!-- 作业照片 -->
        <div class="sub-title">作业照片</div>
        <el-upload :show-file-list="false" :http-request="handlePhotoUpload" accept="image/*" multiple>
          <el-button size="small" icon="el-icon-camera">上传照片（jpg/png/gif/webp，≤5MB）</el-button>
        </el-upload>
        <div style="margin-top:6px">
          <el-button size="mini" type="primary" plain icon="el-icon-folder-opened" @click="driveVisible = true">从企业网盘选择</el-button>
        </div>
        <drive-file-picker :visible="driveVisible" mode="image" :multiple="true" @update:visible="driveVisible = $event" @confirm="onDrivePick" />
        <div class="photo-grid">
          <div v-for="(u, idx) in form.photos" :key="idx" class="photo-item">
            <el-image :src="u" fit="cover" class="photo-img" :preview-src-list="form.photos" :initial-index="idx" />
            <el-button type="text" size="mini" class="danger-text" @click="handlePhotoRemove(u)">删除</el-button>
          </div>
        </div>
      </el-form>
    </el-card>

    <!-- 添加成员对话框 -->
    <el-dialog title="选择成员" :visible.sync="memberVisible" width="480px" append-to-body>
      <el-select v-model="selectedMembers" multiple filterable placeholder="搜索选择成员（可多选）" style="width:100%">
        <el-option v-for="u in userOptions" :key="u.id" :label="u.real_name || u.username" :value="u.id" />
      </el-select>
      <div slot="footer">
        <el-button size="small" @click="memberVisible = false">取消</el-button>
        <el-button size="small" type="primary" @click="confirmAddMembers">添加</el-button>
      </div>
    </el-dialog>

    <!-- 添加材料对话框 -->
    <el-dialog title="添加材料（我的资产配件）" :visible.sync="materialDialogVisible" width="520px" append-to-body>
      <el-form label-width="100px" size="small">
        <el-form-item label="选择配件">
          <el-select v-model="materialForm.personal_asset_id" filterable placeholder="搜索我的资产配件" style="width:100%" @change="onMaterialSelect">
            <el-option v-for="m in materialOptions" :key="m.id" :label="`${m.asset_name}（${m.specification || '-'}）— 可用：${m.quantity} ${m.unit}`" :value="m.id" />
          </el-select>
        </el-form-item>
        <el-form-item v-if="materialForm.personal_asset_id" label="可用数量">
          <span style="color:#409EFF;font-weight:700">{{ materialForm.available_qty }}</span> {{ materialForm.unit }}
          <span v-if="materialForm.location" style="color:#909399;margin-left:10px">📍 {{ materialForm.location }}</span>
        </el-form-item>
        <el-form-item label="使用数量">
          <el-input-number v-model="materialForm.quantity" :min="0.01" :max="materialForm.available_qty || 99999" :precision="materialForm.available_qty >= 1 ? 0 : 4" style="width:100%" />
        </el-form-item>
      </el-form>
      <div slot="footer">
        <el-button size="small" @click="materialDialogVisible = false">取消</el-button>
        <el-button size="small" type="primary" :disabled="!materialForm.personal_asset_id" @click="confirmAddMaterial">添加</el-button>
      </div>
    </el-dialog>
  </div>
</template>

<script>
import { getReportableOrders, getReportDetail, saveReport, getOrderUsers, getWorkstationList, getWsAvailableProcesses, getWsDevices, getOrderMaterials, uploadReportPhoto } from '@/api/production'
import { getMyMaterials } from '@/api/personalAssets'

export default {
  name: 'ProductionReportAdd',
  data () {
    return {
      isEdit: false,
      taskOptions: { 1: '拆解', 2: '焊接', 3: '维修', 4: '组装', 5: '喷漆', 6: '质检', 7: '其他' },
      orderOptions: [], userOptions: [], workstationOptions: [], availableProcesses: [], deviceOptions: [], materialOptions: [],
      selectedMembers: [], memberVisible: false, pendingMaterialId: null, materialDialogVisible: false, materialForm: { personal_asset_id: null, quantity: 1, available_qty: 0, unit: '', location: '' },
      form: {
        report_type: 1, work_order_id: null, work_order_no: '', task_type: 1, task_description: '',
        process_id: 0, process_name: '', workstation_id: 0, workstation_name: '',
        device_id: 0, device_name: '', device_code: '',
        quantity: 1, duration: 1.0, photos: [], calculated_score: 0,
        total_score: 0, report_date: this.today(), remark: '', materials: [], items: []
      },
      rules: {
        report_type: [{ required: true, message: '请选择报工模式' }],
        work_order_id: [{ required: true, message: '请选择关联工单' }],
        task_type: [{ required: true, message: '请选择任务类型' }],
        task_description: [{ required: true, message: '请填写任务描述' }],
        total_score: [{ required: true, message: '请输入总工分' }],
        report_date: [{ required: true, message: '请选择报工日期' }]
      },
      driveVisible: false,
      saving: false
    }
  },
  computed: {
    scoreFormula () {
      const p = this.availableProcesses.find(x => x.process_id === this.form.process_id)
      if (!p) return ''
      return `${Number(p.standard_score)} 分 × ${Number(this.form.quantity || 1)} 件 = ${this.form.calculated_score} 分`
    },
    processGroups () {
      const seen = []
      this.availableProcesses.forEach(p => { if (p.process_group && !seen.includes(p.process_group)) seen.push(p.process_group) })
      return seen
    },
    allocatedSum () { return this.form.items.reduce((s, i) => s + Number(i.allocated_score || 0), 0) },
    balanceTip () {
      if (this.form.report_type !== 2) return ''
      const sum = this.allocatedSum
      if (Math.abs(sum - Number(this.form.total_score)) > 0.001) return `分配工分合计（${sum}）与总工分（${this.form.total_score}）不一致，请调整`
      return ''
    }
  },
  created () {
    this.loadOrders()
    this.loadUsers()
    this.loadWorkstations()
    this.loadMaterials()
    const id = this.$route.params.id
    if (id) { this.isEdit = true; this.loadDetail(id) }
  },
  methods: {
    today () { const d = new Date(); return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}` },
    async loadMaterials () { try { const r = await getMyMaterials({ limit: 50 }); if (r.code === 0) this.materialOptions = r.data.list || [] } catch (e) { this.materialOptions = [] } },
    async loadOrders () {
      try { const r = await getReportableOrders(); if (r.code === 0) this.orderOptions = r.data.list || [] } catch (e) { this.orderOptions = [] }
    },
    async loadUsers () {
      try { const r = await getOrderUsers(); if (r.code === 0) this.userOptions = r.data.list || [] } catch (e) { this.userOptions = [] }
    },
    async loadWorkstations () {
      try { const r = await getWorkstationList({ page: 1, pageSize: 200, status: 1 }); if (r.code === 0) this.workstationOptions = r.data.list || [] } catch (e) { this.workstationOptions = [] }
    },
    // 工位 → 工序/设备联动
    async onWorkstationChange (id) {
      this.form.process_id = 0
      this.form.process_name = ''
      this.form.device_id = 0
      this.form.device_name = ''
      this.form.device_code = ''
      this.availableProcesses = []
      this.deviceOptions = []
      if (!id) { this.form.workstation_name = ''; return }
      const ws = this.workstationOptions.find(x => x.id === id)
      if (ws) this.form.workstation_name = ws.workstation_name
      try {
        const [r, rd] = await Promise.all([getWsAvailableProcesses(id), getWsDevices(id)])
        if (r.code === 0) {
          this.availableProcesses = r.data.list || []
          if (this.availableProcesses.length === 1) {
            const p = this.availableProcesses[0]
            this.form.process_id = p.process_id
            this.form.process_name = p.process_name
            this.recalcScore()
          } else if (!this.availableProcesses.length) {
            this.$message.warning('该工位暂未配置可做工序，请先到工位管理中配置工序')
          }
        }
        if (rd.code === 0) {
          this.deviceOptions = rd.data.list || []
          if (!this.deviceOptions.length) this.$message.warning('该工位未关联设备，请先到工位管理中配置设备')
        }
      } catch (e) {}
    },
    onProcessChange (id) {
      const p = this.availableProcesses.find(x => x.process_id === id)
      if (p) this.form.process_name = p.process_name
      this.recalcScore()
    },
    onQuantityChange () { this.recalcScore() },
    onDeviceChange (id) {
      const d = this.deviceOptions.find(x => x.id === id)
      if (d) { this.form.device_name = d.device_name; this.form.device_code = d.device_code }
    },
    // 工分自动计算：定额 × 数量
    recalcScore () {
      const p = this.availableProcesses.find(x => x.process_id === this.form.process_id)
      const score = p ? Number(p.standard_score) : 0
      this.form.calculated_score = Number((score * Number(this.form.quantity || 1)).toFixed(2))
      this.form.total_score = this.form.calculated_score
    },
    onDrivePick(list) { list.forEach(f => { this.form.photos.push(f.url) }); this.$message.success('已添加 ' + list.length + ' 张照片') },
    async handlePhotoUpload (options) {
      const file = options.file
      if (file.size > 5 * 1024 * 1024) { this.$message.warning('图片不能超过 5MB'); options.onError(); return }
      const ext = (file.name.split('.').pop() || '').toLowerCase()
      if (!['jpg', 'jpeg', 'png', 'gif', 'webp'].includes(ext)) { this.$message.warning('仅支持 jpg/jpeg/png/gif/webp'); options.onError(); return }
      const fd = new FormData()
      fd.append('file', file)
      try {
        const r = await uploadReportPhoto(fd)
        if (r.code === 0 && r.data.url) { this.form.photos.push(r.data.url); options.onSuccess(r.data) } else { this.$message.error(r.msg || '上传失败'); options.onError() }
      } catch (e) { options.onError() }
    },
    handlePhotoRemove (url) {
      this.form.photos = this.form.photos.filter(u => u !== url)
    },
    addMaterial () {
      this.$prompt('请输入使用数量', '添加材料', { inputValue: '1', inputPattern: /^\d+(\.\d+)?$/, inputErrorMessage: '数量格式不正确' }).then(async ({ value }) => {
        if (!this.pendingMaterialId) { this.$message.warning('请先选择材料'); return }
        const m = this.materialOptions.find(x => x.id === this.pendingMaterialId)
        if (!m) return
        this.form.materials.push({ material_id: m.id, material_code: m.material_code, material_name: m.material_name, specification: m.specification || '', unit: m.unit || '', quantity: Number(value) })
        this.pendingMaterialId = null
      }).catch(() => {})
    },
    onMaterialSelect (id) {
      const m = this.materialOptions.find(x => x.id === id)
      if (m) {
        this.materialForm.available_qty = Number(m.quantity) || 0
        this.materialForm.unit = m.unit || ''
        this.materialForm.location = m.location || ''
      }
    },
    removeMaterial (idx) { this.form.materials.splice(idx, 1) },
    confirmAddMaterial () {
      if (!this.materialForm.personal_asset_id) { this.$message.warning('请选择配件'); return }
      if (!this.materialForm.quantity || this.materialForm.quantity <= 0) { this.$message.warning('请输入使用数量'); return }
      if (this.materialForm.quantity > this.materialForm.available_qty) { this.$message.warning('使用数量不能超过可用数量（' + this.materialForm.available_qty + '）'); return }
      const m = this.materialOptions.find(x => x.id === this.materialForm.personal_asset_id)
      if (!m) return
      this.form.materials.push({
        personal_asset_id: m.id,
        material_id: m.id,
        material_code: m.asset_code || '',
        material_name: m.asset_name,
        specification: m.specification || '',
        unit: m.unit || '',
        quantity: this.materialForm.quantity
      })
      this.materialForm = { personal_asset_id: null, quantity: 1, available_qty: 0, unit: '', location: '' }
      this.materialDialogVisible = false
    },
    async loadDetail (id) {
      try {
        const r = await getReportDetail(id)
        if (r.code === 0 && r.data) {
          const d = r.data
          this.form = {
            report_type: d.report_type, work_order_id: d.work_order_id, work_order_no: d.work_order_no,
            task_type: d.task_type, task_description: d.task_description || '',
            process_id: d.process_id || 0, process_name: d.process_name || '',
            workstation_id: d.workstation_id || 0, workstation_name: d.workstation_name || '',
            device_id: d.device_id || 0, device_name: d.device_name || '', device_code: d.device_code || '',
            quantity: d.quantity || 1, duration: d.duration || 1.0,
            photos: d.photos || [], calculated_score: d.calculated_score || 0,
            total_score: Number(d.total_score), report_date: d.report_date || this.today(),
            remark: d.remark || '', materials: d.materials || [], items: (d.items || []).map(i => ({ worker_id: i.worker_id, worker_name: i.worker_name, allocated_score: Number(i.allocated_score), remark: i.remark || '' }))
          }
          // 编辑时回填工位可用工序
          if (this.form.workstation_id) {
            try {
              const r2 = await getWsAvailableProcesses(this.form.workstation_id)
              if (r2.code === 0) this.availableProcesses = r2.data.list || []
            } catch (e) {}
          }
        }
      } catch (e) {}
    },
    onOrderChange (id) {
      const o = this.orderOptions.find(x => x.id === id)
      if (o) this.form.work_order_no = o.order_no
    },
    confirmAddMembers () {
      if (!this.selectedMembers.length) { this.$message.warning('请选择成员'); return }
      const existing = this.form.items.map(i => i.worker_id)
      const added = []
      this.selectedMembers.forEach(uid => {
        if (existing.includes(uid)) return
        const u = this.userOptions.find(x => x.id === uid)
        if (u) { this.form.items.push({ worker_id: uid, worker_name: u.real_name || u.username, allocated_score: 0, remark: '' }); added.push(uid) }
      })
      this.selectedMembers = []
      this.memberVisible = false
      if (!added.length) this.$message.warning('所选成员已在列表中')
    },
    removeMember (idx) { this.form.items.splice(idx, 1) },
    async handleSave () {
      if (!this.form.work_order_id) { this.$message.warning('请选择关联工单'); return }
      if (!this.form.workstation_id) { this.$message.warning('请选择关联工位'); return }
      if (!this.form.device_id) { this.$message.warning('请选择关联设备'); return }
      if (!this.form.process_id) { this.$message.warning('请选择关联工序'); return }
      if (!this.form.task_description) { this.$message.warning('请填写任务描述'); return }
      if (!this.form.quantity || this.form.quantity <= 0) { this.$message.warning('完成数量必须大于0'); return }
      if (!this.form.duration || this.form.duration <= 0) { this.$message.warning('设备使用时长必须大于0'); return }
      if (!this.form.total_score || this.form.total_score <= 0) { this.$message.warning('请输入总工分'); return }
      if (this.form.report_type === 2) {
        if (!this.form.items.length) { this.$message.warning('团队协作请至少添加一名成员'); return }
        if (this.balanceTip) { this.$message.warning(this.balanceTip); return }
      }
      this.saving = true
      try {
        const data = { ...this.form }
        if (this.isEdit) data.id = this.$route.params.id
        const r = await saveReport(data)
        if (r.code === 0) { this.$message.success('保存成功'); this.$router.replace('/production/report/list') } else this.$message.error(r.msg || '保存失败')
      } catch (e) {} finally { this.saving = false }
    }
  }
}
</script>

<style scoped>
.wh-page { padding: 16px; }
.breadcrumb { margin-bottom: 12px; }
.page-header { display: flex; justify-content: space-between; align-items: center; background: #fff; padding: 14px 20px; border-radius: 8px 8px 0 0; border-bottom: 1px solid #ebeef5; }
.page-title { font-size: 18px; font-weight: 700; }
.header-actions { display: flex; gap: 10px; }
.form-card { margin-top: 12px; border-radius: 8px; }
.sub-title { font-size: 14px; font-weight: 600; margin: 8px 0 12px; }
.qty-tip { font-size: 12px; color: #909399; line-height: 20px; }
.alloc-stat { margin-top: 10px; font-size: 13px; color: #606266; }
.balance-warn { color: #F56C6C; margin-left: 8px; }
.danger-text { color: #F56C6C; }
.photo-grid { display: flex; flex-wrap: wrap; gap: 10px; margin-top: 10px; }
.photo-item { display: flex; flex-direction: column; align-items: center; width: 100px; }
.photo-img { width: 100px; height: 100px; border-radius: 4px; border: 1px solid #ebeef5; }
</style>
