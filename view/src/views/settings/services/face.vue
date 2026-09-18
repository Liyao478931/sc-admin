<template>
  <div class="face-page">
    <!-- 一、服务基本信息 -->
    <el-card shadow="never" class="sec-card">
      <div slot="header" class="sec-head"><span class="sec-title">服务基本信息</span><span class="sec-desc">腾讯云人脸识别（Iai）API 接入配置，供打卡/门禁/签到等业务调用</span></div>
      <el-form :model="form" label-width="140px" size="small">
        <el-row :gutter="24">
          <el-col :span="12">
            <el-form-item label="服务名称"><el-input v-model="form.service_name" disabled /></el-form-item>
            <el-form-item label="服务地域">
              <el-select v-model="form.region" style="width:100%">
                <el-option v-for="(label, val) in REGIONS" :key="val" :label="`${label}（${val}）`" :value="val" />
              </el-select>
            </el-form-item>
            <el-form-item label="SecretId" required><el-input v-model="form.secret_id" placeholder="腾讯云API密钥ID（必填）" maxlength="100" /></el-form-item>
            <el-form-item label="人员库ID (GroupId)" required><el-input v-model="form.group_id" placeholder="腾讯云人脸识别控制台创建的人员库ID（必填）" maxlength="100" /></el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="服务状态">
              <el-switch v-model="form.status" :active-value="1" :inactive-value="0" active-text="启用" inactive-text="停用" />
            </el-form-item>
            <el-form-item label="SecretKey" required>
              <el-input v-model="form.secret_key" type="password" show-password placeholder="腾讯云API密钥（必填，加密存储；掩码 ****** 表示已保存）" maxlength="200" />
            </el-form-item>
            <el-form-item label="相似度阈值">
              <el-input-number v-model="form.similarity_threshold" :min="0" :max="100" :step="1" style="width:180px;" />
              <span class="unit">分（默认80）</span>
            </el-form-item>
          </el-col>
        </el-row>
        <el-form-item><el-button type="primary" size="small" :loading="saving" @click="saveConfig">保存配置</el-button></el-form-item>
      </el-form>
    </el-card>

    <!-- 二、匹配参数 -->
    <el-card shadow="never" class="sec-card">
      <div slot="header" class="sec-head"><span class="sec-title">匹配参数</span><span class="sec-desc">1:N 搜索时的默认参数</span></div>
      <el-form :model="form" label-width="140px" size="small">
        <el-row :gutter="24">
          <el-col :span="12">
            <el-form-item label="最多人脸数"><el-input-number v-model="form.max_face_num" :min="1" :max="10" style="width:180px;" /></el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="最多返回人数"><el-input-number v-model="form.max_person_num" :min="1" :max="10" style="width:180px;" /></el-form-item>
          </el-col>
        </el-row>
        <el-form-item><el-button type="primary" size="small" :loading="saving" @click="saveConfig">保存配置</el-button></el-form-item>
      </el-form>
    </el-card>

    <!-- 三、连接测试 -->
    <el-card shadow="never" class="sec-card">
      <div slot="header" class="sec-head"><span class="sec-title">连接测试</span><span class="sec-desc">通过 SecretId/SecretKey/GroupId 探测人员库，验证鉴权与配置</span></div>
      <el-button size="small" type="primary" :loading="testing" @click="testConnection">测试连接</el-button>
      <div v-if="testResult" class="test-result" :class="testResult.success ? 'ok' : 'err'">
        {{ testResult.message }}（{{ testResult.response_time }}）｜人员库鉴权：{{ testResult.group_ok ? '正常' : '失败' }}
      </div>
    </el-card>

    <!-- 四、接口调试工具 -->
    <el-card shadow="never" class="sec-card">
      <div slot="header" class="sec-head"><span class="sec-title">接口调试工具</span><span class="sec-desc">辅助验证人脸接口连通性（真实调用腾讯云）</span></div>
      <el-tabs v-model="activeTab">
        <!-- 人脸检测 -->
        <el-tab-pane label="人脸检测" name="detect">
          <el-form label-width="120px" size="small">
            <el-form-item label="人脸图片">
              <el-input v-model="detectImage" type="textarea" :rows="3" placeholder="粘贴 Base64 图片数据（可含 data:image 前缀）" />
            </el-form-item>
            <el-form-item>
              <el-button size="small" type="primary" :loading="detecting" @click="doDetect">检测</el-button>
            </el-form-item>
          </el-form>
          <el-alert v-if="detectResult" :title="detectResult" type="success" show-icon :closable="false" />
        </el-tab-pane>

        <!-- 人脸录入 -->
        <el-tab-pane label="人脸录入" name="create">
          <el-form label-width="120px" size="small">
            <el-form-item label="人员ID" required><el-input v-model="createForm.person_id" placeholder="建议使用本地用户ID" maxlength="64" /></el-form-item>
            <el-form-item label="人员名称" required><el-input v-model="createForm.person_name" placeholder="员工姓名" maxlength="64" /></el-form-item>
            <el-form-item label="性别">
              <el-select v-model="createForm.gender" style="width:200px;">
                <el-option label="未填写" :value="0" />
                <el-option label="男性" :value="1" />
                <el-option label="女性" :value="2" />
              </el-select>
            </el-form-item>
            <el-form-item label="人脸图片" required>
              <el-input v-model="createForm.image" type="textarea" :rows="3" placeholder="粘贴 Base64 图片数据（可含 data:image 前缀）" />
            </el-form-item>
            <el-form-item>
              <el-button size="small" type="primary" :loading="creating" @click="doCreate">录入</el-button>
            </el-form-item>
          </el-form>
          <el-alert v-if="createResult" :title="createResult" type="success" show-icon :closable="false" />
        </el-tab-pane>

        <!-- 人脸搜索 -->
        <el-tab-pane label="人脸搜索(1:N)" name="search">
          <el-form label-width="120px" size="small">
            <el-form-item label="人脸图片" required>
              <el-input v-model="searchImage" type="textarea" :rows="3" placeholder="粘贴 Base64 图片数据（可含 data:image 前缀）" />
            </el-form-item>
            <el-form-item>
              <el-button size="small" type="primary" :loading="searching" @click="doSearch">搜索</el-button>
            </el-form-item>
          </el-form>
          <el-alert v-if="searchResult" :title="searchResult.title" :type="searchResult.type" show-icon :closable="false" />
        </el-tab-pane>

        <!-- 人员信息 -->
        <el-tab-pane label="人员信息" name="info">
          <el-form :inline="true" size="small">
            <el-form-item label="人员ID" required><el-input v-model="infoPersonId" placeholder="person_id" style="width:240px;" /></el-form-item>
            <el-form-item><el-button size="small" type="primary" :loading="loadingInfo" @click="doInfo">查询</el-button></el-form-item>
          </el-form>
          <el-alert v-if="infoResult" :title="infoResult" type="success" show-icon :closable="false" />
        </el-tab-pane>

        <!-- 删除人员 -->
        <el-tab-pane label="删除人员" name="delete">
          <el-form :inline="true" size="small">
            <el-form-item label="人员ID" required><el-input v-model="deletePersonId" placeholder="person_id" style="width:240px;" /></el-form-item>
            <el-form-item><el-button size="small" type="danger" :loading="deleting" @click="doDelete">删除</el-button></el-form-item>
          </el-form>
          <el-alert v-if="deleteResult" :title="deleteResult" :type="deleteResultType" show-icon :closable="false" />
        </el-tab-pane>
      </el-tabs>
    </el-card>

    <!-- 五、服务状态 -->
    <el-card shadow="never" class="sec-card">
      <div slot="header" class="sec-head"><span class="sec-title">服务状态</span></div>
      <el-row :gutter="16">
        <el-col :span="6"><div class="state-item">服务状态：<el-tag size="mini" :type="status.enabled ? 'success' : 'info'">{{ status.enabled ? '启用' : '停用' }}</el-tag></div></el-col>
        <el-col :span="6"><div class="state-item">配置完备：<el-tag size="mini" :type="status.configured ? 'success' : 'danger'">{{ status.configured ? '已配置' : '未配置' }}</el-tag></div></el-col>
        <el-col :span="6"><div class="state-item">相似度阈值：{{ status.similarity_threshold || 80 }} 分</div></el-col>
        <el-col :span="6"><div class="state-item">最后测试：{{ status.last_test_time || '-' }} <el-tag v-if="status.test_status" size="mini" :type="status.test_status === 'success' ? 'success' : 'danger'" style="margin-left:4px;">{{ status.test_status === 'success' ? '通过' : '失败' }}</el-tag></div></el-col>
      </el-row>
    </el-card>
  </div>
</template>

<script>
import { getFaceConfig, saveFaceConfig, testFace, getFaceStatus, faceCreate, faceSearch, faceDelete, faceInfo, faceDetect } from '@/api/serviceFace'

const REGIONS = {
  'ap-guangzhou': '广州', 'ap-beijing': '北京', 'ap-shanghai': '上海',
  'ap-hongkong': '香港', 'ap-singapore': '新加坡'
}

export default {
  name: 'ServiceFace',
  data () {
    return {
      REGIONS,
      form: {
        service_name: '腾讯云人脸识别服务', status: 1, region: 'ap-guangzhou',
        secret_id: '', secret_key: '', group_id: '',
        similarity_threshold: 80, max_face_num: 1, max_person_num: 1
      },
      saving: false, testing: false, testResult: null,
      status: { enabled: false, configured: false, similarity_threshold: 80, last_test_time: null, test_status: null },
      activeTab: 'detect',
      detectImage: '', detectResult: '', detecting: false,
      createForm: { person_id: '', person_name: '', gender: 0, image: '' }, createResult: '', creating: false,
      searchImage: '', searchResult: null, searching: false,
      infoPersonId: '', infoResult: '', loadingInfo: false,
      deletePersonId: '', deleteResult: '', deleteResultType: 'success', deleting: false
    }
  },
  created () { this.loadConfig(); this.loadStatus() },
  methods: {
    async loadConfig () {
      try {
        const r = await getFaceConfig()
        if (r.code === 0) {
          const d = r.data || {}
          this.form = {
            service_name: d.service_name || '腾讯云人脸识别服务', status: d.status === 0 ? 0 : 1, region: d.region || 'ap-guangzhou',
            secret_id: d.secret_id || '', secret_key: d.secret_key ? '******' : '', group_id: d.group_id || '',
            similarity_threshold: Number(d.similarity_threshold ?? 80), max_face_num: Number(d.max_face_num ?? 1), max_person_num: Number(d.max_person_num ?? 1)
          }
        }
      } catch (e) {}
    },
    async loadStatus () {
      try {
        const r = await getFaceStatus()
        if (r.code === 0) this.status = r.data || {}
      } catch (e) {}
    },
    async saveConfig () {
      if (!this.form.secret_id) { this.$message.warning('SecretId 必填'); return }
      if (!this.form.group_id) { this.$message.warning('人员库ID (GroupId) 必填'); return }
      if (!this.form.secret_key) { this.$message.warning('SecretKey 必填'); return }
      this.saving = true
      try {
        const r = await saveFaceConfig({ ...this.form })
        if (r.code === 0) { this.$message.success(r.msg || '配置已保存'); this.loadConfig(); this.loadStatus() }
      } catch (e) {} finally { this.saving = false }
    },
    async testConnection () {
      this.testing = true; this.testResult = null
      try {
        const r = await testFace()
        if (r.code === 0 && r.data) this.testResult = r.data
      } catch (e) {} finally { this.testing = false }
    },
    // ---- 接口调试 ----
    async doDetect () {
      if (!this.detectImage) { this.$message.warning('请粘贴人脸图片'); return }
      this.detecting = true; this.detectResult = ''
      try {
        const r = await faceDetect({ image: this.detectImage })
        if (r.code === 0) {
          const d = r.data || {}
          this.detectResult = `${r.msg}（检测到 ${d.face_count || 0} 张人脸）`
        } else { this.detectResult = r.msg || '检测失败'; this.$message.error(r.msg || '检测失败') }
      } catch (e) { this.detectResult = '请求失败' } finally { this.detecting = false }
    },
    async doCreate () {
      if (!this.createForm.person_id) { this.$message.warning('人员ID 必填'); return }
      if (!this.createForm.person_name) { this.$message.warning('人员名称 必填'); return }
      if (!this.createForm.image) { this.$message.warning('请粘贴人脸图片'); return }
      this.creating = true; this.createResult = ''
      try {
        const r = await faceCreate({ ...this.createForm })
        if (r.code === 0) {
          const d = r.data || {}
          this.createResult = `${r.msg}｜face_id: ${d.face_id || '-'}`
          this.$message.success(r.msg || '录入成功')
        } else { this.createResult = r.msg || '录入失败'; this.$message.error(r.msg || '录入失败') }
      } catch (e) { this.createResult = '请求失败' } finally { this.creating = false }
    },
    async doSearch () {
      if (!this.searchImage) { this.$message.warning('请粘贴人脸图片'); return }
      this.searching = true; this.searchResult = null
      try {
        const r = await faceSearch({ image: this.searchImage })
        if (r.code === 0) {
          const d = r.data || {}
          const matched = d.is_match ? `匹配成功：${d.person_name}（${d.person_id}）score=${d.score}` : `未匹配（最高分 ${d.score || 0} / 阈值 ${d.threshold || 80}）`
          this.searchResult = { title: matched, type: d.is_match ? 'success' : 'warning' }
        } else { this.searchResult = { title: r.msg || '搜索失败', type: 'error' } }
      } catch (e) { this.searchResult = { title: '请求失败', type: 'error' } } finally { this.searching = false }
    },
    async doInfo () {
      if (!this.infoPersonId) { this.$message.warning('人员ID 必填'); return }
      this.loadingInfo = true; this.infoResult = ''
      try {
        const r = await faceInfo(this.infoPersonId)
        if (r.code === 0) {
          const d = r.data || {}
          this.infoResult = `${r.msg}｜姓名: ${d.person_name || '-'}，人脸数: ${(d.face_ids || []).length}`
        } else { this.infoResult = r.msg || '查询失败'; this.$message.error(r.msg || '查询失败') }
      } catch (e) { this.infoResult = '请求失败' } finally { this.loadingInfo = false }
    },
    async doDelete () {
      if (!this.deletePersonId) { this.$message.warning('人员ID 必填'); return }
      this.$confirm(`确认从人员库删除 ${this.deletePersonId}？该操作不可恢复。`, '删除人员', { type: 'warning' }).then(async () => {
        this.deleting = true; this.deleteResult = ''
        try {
          const r = await faceDelete({ person_id: this.deletePersonId })
          if (r.code === 0) { this.deleteResult = r.msg || '删除成功'; this.deleteResultType = 'success'; this.$message.success(r.msg || '删除成功') }
          else { this.deleteResult = r.msg || '删除失败'; this.deleteResultType = 'error'; this.$message.error(r.msg || '删除失败') }
        } catch (e) { this.deleteResult = '请求失败'; this.deleteResultType = 'error' } finally { this.deleting = false }
      }).catch(() => {})
    }
  }
}
</script>

<style scoped>
.face-page { padding: 16px; background: #f0f2f5; min-height: 100%; }
.sec-card { margin-bottom: 16px; }
.sec-head { display: flex; align-items: baseline; gap: 12px; }
.sec-title { font-size: 15px; font-weight: 600; color: #303133; }
.sec-desc { font-size: 12px; color: #909399; }
.unit { margin-left: 8px; font-size: 12px; color: #909399; }
.test-result { margin-top: 12px; font-size: 13px; }
.test-result.ok { color: #67C23A; }
.test-result.err { color: #F56C6C; }
.state-item { font-size: 13px; color: #606266; }
</style>
