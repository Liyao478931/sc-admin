<template>
  <el-dialog title="测试数据源连接" :visible.sync="visible" width="560px" append-to-body>
    <el-form :model="form" label-width="110px" size="small">
      <el-form-item label="数据源类型">
        <el-select v-model="form.ds_type" style="width: 100%;" @change="onTypeChange">
          <el-option v-for="(v, k) in typeMap" :key="k" :label="v" :value="k" />
        </el-select>
      </el-form-item>

      <!-- 数据库配置 -->
      <template v-if="form.ds_type === 'database'">
        <el-form-item label="数据库类型">
          <el-select v-model="form.config.db_type" style="width: 100%;">
            <el-option label="MySQL" value="mysql" /><el-option label="PostgreSQL" value="pgsql" />
            <el-option label="SQL Server" value="sqlsrv" /><el-option label="Oracle" value="oracle" />
            <el-option label="SQLite" value="sqlite" />
          </el-select>
        </el-form-item>
        <el-row :gutter="10">
          <el-col :span="14"><el-form-item label="主机地址"><el-input v-model="form.config.host" placeholder="如 127.0.0.1" /></el-form-item></el-col>
          <el-col :span="10"><el-form-item label="端口"><el-input-number v-model="form.config.port" :min="1" :max="65535" style="width: 100%;" /></el-form-item></el-col>
        </el-row>
        <el-form-item label="数据库名"><el-input v-model="form.config.database" placeholder="数据库名" /></el-form-item>
        <el-row :gutter="10">
          <el-col :span="12"><el-form-item label="用户名"><el-input v-model="form.config.username" /></el-form-item></el-col>
          <el-col :span="12"><el-form-item label="密码"><el-input v-model="form.config.password" type="password" show-password /></el-form-item></el-col>
        </el-row>
      </template>

      <!-- API 配置 -->
      <template v-else-if="form.ds_type === 'api'">
        <el-form-item label="API地址"><el-input v-model="form.config.url" placeholder="https://api.example.com/v1/users" /></el-form-item>
        <el-form-item label="请求方法">
          <el-radio-group v-model="form.config.method"><el-radio label="GET">GET</el-radio><el-radio label="POST">POST</el-radio></el-radio-group>
        </el-form-item>
        <el-form-item label="认证方式">
          <el-select v-model="form.config.auth_type" style="width: 100%;" @change="onAuthChange">
            <el-option label="无" value="none" /><el-option label="API Key" value="api_key" />
            <el-option label="Bearer Token" value="bearer" /><el-option label="Basic Auth" value="basic" />
          </el-select>
        </el-form-item>
        <el-form-item v-if="form.config.auth_type === 'api_key'" label="API Key"><el-input v-model="form.config.api_key" /></el-form-item>
        <el-form-item v-if="form.config.auth_type === 'bearer'" label="Token"><el-input v-model="form.config.token" /></el-form-item>
        <template v-if="form.config.auth_type === 'basic'">
          <el-row :gutter="10">
            <el-col :span="12"><el-form-item label="用户名"><el-input v-model="form.config.username" /></el-form-item></el-col>
            <el-col :span="12"><el-form-item label="密码"><el-input v-model="form.config.password" type="password" show-password /></el-form-item></el-col>
          </el-row>
        </template>
      </template>

      <!-- 网页配置 -->
      <template v-else-if="form.ds_type === 'webpage'">
        <el-form-item label="网页URL"><el-input v-model="form.config.url" placeholder="https://example.com/article" /></el-form-item>
        <el-form-item label="渲染方式">
          <el-radio-group v-model="form.config.render"><el-radio label="static">静态</el-radio><el-radio label="dynamic">动态(JS)</el-radio></el-radio-group>
        </el-form-item>
      </template>

      <!-- 文件系统配置 -->
      <template v-else-if="form.ds_type === 'filesystem'">
        <el-form-item label="存储类型">
          <el-select v-model="form.config.storage_type" style="width: 100%;">
            <el-option label="本地" value="local" /><el-option label="FTP" value="ftp" /><el-option label="SFTP" value="sftp" />
            <el-option label="OSS" value="oss" /><el-option label="COS" value="cos" /><el-option label="S3" value="s3" />
          </el-select>
        </el-form-item>
        <el-form-item label="目录路径"><el-input v-model="form.config.path" placeholder="如 /data/docs" /></el-form-item>
      </template>

      <!-- 文件配置 -->
      <template v-else-if="form.ds_type === 'file'">
        <el-form-item label="文件URL"><el-input v-model="form.config.file_url" placeholder="https://example.com/data.csv" /></el-form-item>
        <el-form-item label="文件格式">
          <el-radio-group v-model="form.config.file_format"><el-radio label="csv">CSV</el-radio><el-radio label="excel">Excel</el-radio></el-radio-group>
        </el-form-item>
      </template>

      <!-- 测试结果 -->
      <el-form-item v-if="result" label="测试结果">
        <el-alert :title="result.message" :type="result.ok ? 'success' : 'error'" :closable="false" show-icon />
        <div v-if="result.elapsed" class="elapsed">响应时间：{{ result.elapsed }}ms</div>
      </el-form-item>
    </el-form>
    <div slot="footer">
      <el-button size="small" @click="visible = false">关闭</el-button>
      <el-button size="small" type="primary" :loading="testing" @click="doTest">测试连接</el-button>
    </div>
  </el-dialog>
</template>

<script>
import { testDatasource } from '../../../../api/aiDatasource'

export default {
  name: 'DatasourceTestDialog',
  data() {
    return {
      visible: false,
      testing: false,
      result: null,
      typeMap: { database: '数据库', api: 'API', webpage: '网页', filesystem: '文件系统', message_queue: '消息队列', file: '文件' },
      form: this.emptyForm()
    }
  },
  methods: {
    emptyForm() {
      return {
        ds_type: 'database',
        config: { db_type: 'mysql', host: '', port: 3306, database: '', username: '', password: '', url: '', method: 'GET', auth_type: 'none', api_key: '', token: '', render: 'static', storage_type: 'local', path: '', file_url: '', file_format: 'csv' }
      }
    },
    open(row) {
      this.result = null
      if (row) {
        // 从列表"测试"进入：预填该数据源的类型与配置
        const cfg = (row.config && typeof row.config === 'object') ? row.config : {}
        this.form = {
          ds_type: row.ds_type,
          config: Object.assign({}, this.emptyForm().config, cfg)
        }
      }
      this.visible = true
    },
    onTypeChange() {
      this.form.config = this.emptyForm().config
      this.result = null
    },
    onAuthChange() {
      this.form.config.api_key = ''
      this.form.config.token = ''
      this.form.config.username = ''
      this.form.config.password = ''
    },
    async doTest() {
      this.testing = true
      this.result = null
      try {
        const res = await testDatasource({ ds_type: this.form.ds_type, config: this.form.config })
        this.result = res.data || { ok: false, message: res.msg || '测试失败' }
      } catch (e) {
        this.result = { ok: false, message: '请求失败' }
      }
      this.testing = false
    }
  }
}
</script>

<style scoped>
.elapsed { color: #909399; font-size: 12px; margin-top: 4px; }
</style>
