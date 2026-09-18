<template>
  <div class="service-page">
    <el-card shadow="never">
      <div slot="header">
        <span>基础服务</span>
        <div style="float:right;">
          <el-button size="small" @click="refreshAll">{{ loadingAll ? '加载中...' : '刷新状态' }}</el-button>
        </div>
      </div>
      <!-- 服务异常告警横幅 -->
      <el-alert
        v-if="alertBanner.show"
        :title="alertBanner.message"
        type="warning"
        closable
        show-icon
        style="margin-bottom:16px;"
      />
      <el-tabs v-model="activeTab" @tab-click="onTabClick">
        <!-- ═══════ 存储服务 Tab ═══════ -->
        <el-tab-pane label="存储服务" name="storage">
          <!-- 当前生效引擎 -->
          <el-alert v-if="activeEngine" :title="'当前生效引擎：' + activeEngine.name + '（' + activeEngine.engine + '）'" type="info" :closable="false" show-icon style="margin-bottom:16px;" />
          <!-- 引擎卡片（支持拖拽排序） -->
          <el-row :gutter="16">
            <el-col :span="12"
              v-for="(eng, idx) in storageEngines"
              :key="eng.id"
              draggable="true"
              @dragstart="onDragStart('storage', idx, $event)"
              @dragover.prevent="onDragOver($event)"
              @drop="onDrop('storage', idx, $event)"
              :class="{'drag-over': dragOverIndex === idx}"
            >
              <el-card shadow="hover" class="engine-card" :class="'status-' + eng.statusClass">
                <div class="engine-header">
                  <span class="engine-name">
                    {{ eng.name }}
                    <el-tooltip v-if="eng.statusTooltip" :content="eng.statusTooltip" placement="top">
                      <el-tag :type="eng.statusTag" size="mini" style="cursor:help;">{{ eng.statusLabel }}</el-tag>
                    </el-tooltip>
                    <el-tag v-else :type="eng.statusTag" size="mini">{{ eng.statusLabel }}</el-tag>
                  </span>
                </div>
                <div class="engine-icon">
                  <i :class="eng.icon" style="font-size:48px;color:#409eff;"></i>
                </div>
                <div class="engine-footer">
                  <span class="engine-summary">{{ eng.summary }}</span>
                  <div class="engine-actions">
                    <el-button v-if="hasPerm('service:saveConfig')" size="small" @click="openStorageConfig(eng.id)">配置</el-button>
                    <el-button v-if="hasPerm('service:testConnection')" size="small" type="primary" plain @click="testStorage(eng.id)">测试连接</el-button>
                  </div>
                </div>
              </el-card>
            </el-col>
          </el-row>
          <!-- 存储统计（仅COS启用时显示） -->
          <el-row :gutter="16" style="margin-top:16px;" v-if="showStorageStats && cosStorageForm.cos_enabled">
            <el-col :span="6" v-for="s in storageStatsData" :key="s.label">
              <el-card shadow="hover"><div class="stat-val">{{ s.value }}</div><div class="stat-lbl">{{ s.label }}</div></el-card>
            </el-col>
          </el-row>
        </el-tab-pane>

        <!-- ═══════ 短信服务 Tab ═══════ -->
        <el-tab-pane label="短信服务" name="sms">
          <!-- 默认服务商 -->
          <el-alert v-if="smsDefaultProvider" :title="'默认服务商：' + (smsDefaultProvider==='tencent'?'腾讯云短信':'阿里云短信')" type="info" :closable="false" show-icon style="margin-bottom:16px;">
            <div style="display:inline-block;margin-left:12px;">
              <el-select v-model="smsDefaultProvider" size="small" style="width:160px;" @change="changeDefaultProvider">
                <el-option label="腾讯云短信" value="tencent" />
                <el-option label="阿里云短信" value="aliyun" />
              </el-select>
            </div>
          </el-alert>
          <!-- 服务商卡片 -->
          <el-row :gutter="16">
            <el-col :span="12" v-for="(sp, spi) in smsProviders" :key="sp.id">
              <el-card shadow="hover" class="engine-card" :class="'status-' + sp.statusClass">
                <div class="engine-header">
                  <span class="engine-name">{{ sp.name }}
                    <el-tooltip v-if="sp.statusTooltip" :content="sp.statusTooltip" placement="top">
                      <el-tag :type="sp.statusTag" size="mini" style="cursor:help;">{{ sp.statusLabel }}</el-tag>
                    </el-tooltip>
                    <el-tag v-else :type="sp.statusTag" size="mini">{{ sp.statusLabel }}</el-tag>
                  </span>
                </div>
                <div class="engine-icon"><i :class="sp.icon" :style="'font-size:48px;color:'+sp.color"></i></div>
                <div class="engine-footer">
                  <span class="engine-summary">{{ sp.summary }}</span>
                  <div class="engine-actions">
                    <el-button v-if="hasPerm('service:saveConfig')" size="small" @click="openSmsConfig(sp.id)">配置</el-button>
                    <el-button v-if="hasPerm('service:smsTestSend')" size="small" type="primary" plain @click="openSmsTest(sp.id)">测试发送</el-button>
                  </div>
                </div>
              </el-card>
            </el-col>
          </el-row>
          <!-- 短信发送统计 -->
          <el-row :gutter="16" style="margin-top:16px;">
            <el-col :span="6" v-for="s in smsStatsData" :key="s.label">
              <el-card shadow="hover"><div class="stat-val">{{ s.value }}</div><div class="stat-lbl">{{ s.label }}</div></el-card>
            </el-col>
          </el-row>
          <div style="margin-top:8px;text-align:right;">
            <el-select v-model="smsStatsProvider" size="mini" style="width:140px;" @change="loadSmsStats">
              <el-option label="全部服务商" value="" />
              <el-option label="腾讯云" value="tencent" />
              <el-option label="阿里云" value="aliyun" />
            </el-select>
          </div>
        </el-tab-pane>

        <!-- ═══════ 邮件服务 Tab ═══════ -->
        <el-tab-pane label="邮件服务" name="email">
          <el-form :model="emailForm" label-width="150px" size="small" style="max-width:800px;">
            <el-form-item label="是否启用邮件服务">
              <el-switch v-model="emailForm.enabled" />
            </el-form-item>
            <el-divider content-position="left">SMTP 配置</el-divider>
            <el-row :gutter="16">
              <el-col :span="12"><el-form-item label="SMTP 服务器地址"><el-input v-model="emailForm.smtp_host" placeholder="如 smtp.qq.com" /></el-form-item></el-col>
              <el-col :span="12"><el-form-item label="SMTP 端口"><el-input-number v-model="emailForm.smtp_port" :min="1" :max="65535" style="width:100%;" /></el-form-item></el-col>
              <el-col :span="12"><el-form-item label="加密方式">
                <el-select v-model="emailForm.smtp_encryption" style="width:100%;">
                  <el-option label="无加密" value="" />
                  <el-option label="SSL" value="ssl" />
                  <el-option label="TLS" value="tls" />
                </el-select>
              </el-form-item></el-col>
              <el-col :span="12"><el-form-item label="发件人邮箱"><el-input v-model="emailForm.from_email" placeholder="noreply@yourdomain.com" /></el-form-item></el-col>
              <el-col :span="12"><el-form-item label="发件人名称"><el-input v-model="emailForm.from_name" placeholder="选填" /></el-form-item></el-col>
              <el-col :span="12"><el-form-item label="SMTP 用户名"><el-input v-model="emailForm.smtp_user" /></el-form-item></el-col>
              <el-col :span="12"><el-form-item label="SMTP 密码">
                <el-input v-model="emailForm.smtp_pass" :type="showEmailPwd?'text':'password'" show-password>
                  <i slot="suffix" class="el-icon-view" style="cursor:pointer;" @click="showEmailPwd=!showEmailPwd" />
                </el-input>
              </el-form-item></el-col>
            </el-row>
            <el-divider content-position="left">发送限制</el-divider>
            <el-row :gutter="16">
              <el-col :span="12"><el-form-item label="发送频率限制（条/分钟）"><el-input-number v-model="emailForm.rate_per_minute" :min="1" :max="1000" style="width:100%;" /></el-form-item></el-col>
              <el-col :span="12"><el-form-item label="每日发送上限"><el-input-number v-model="emailForm.rate_per_day" :min="1" :max="100000" style="width:100%;" /></el-form-item></el-col>
            </el-row>
            <el-form-item>
              <el-button v-if="hasPerm('service:saveConfig')" type="primary" :loading="emailSaving" @click="saveEmailConfig">保存配置</el-button>
              <el-button v-if="hasPerm('service:resetConfig')" @click="resetService('email')">恢复默认值</el-button>
            </el-form-item>
          </el-form>
          <el-divider content-position="left">测试发送</el-divider>
          <el-form :model="emailTest" label-width="150px" size="small" style="max-width:800px;">
            <el-form-item label="收件人邮箱"><el-input v-model="emailTest.to" placeholder="test@example.com" /></el-form-item>
            <el-form-item label="测试邮件主题"><el-input v-model="emailTest.subject" placeholder="系统邮件服务测试" /></el-form-item>
            <el-form-item label="测试邮件内容"><el-input v-model="emailTest.content" type="textarea" :rows="3" /></el-form-item>
            <el-form-item>
              <el-button v-if="hasPerm('service:emailTestSend')" type="success" :loading="emailTesting" @click="sendEmailTest">发送测试邮件</el-button>
            </el-form-item>
          </el-form>
          <el-row :gutter="16" style="margin-top:16px;" v-if="emailStatsData.length">
            <el-col :span="6" v-for="s in emailStatsData" :key="s.label">
              <el-card shadow="hover"><div class="stat-val">{{ s.value }}</div><div class="stat-lbl">{{ s.label }}</div></el-card>
            </el-col>
          </el-row>
        </el-tab-pane>

        <!-- ═══════ 微信服务 Tab ═══════ -->
        <el-tab-pane label="微信服务" name="wechat">
          <h4>微信公众号</h4>
          <el-form :model="wechatForm" label-width="150px" size="small" style="max-width:800px;">
            <el-form-item label="是否启用公众号服务"><el-switch v-model="wechatForm.oa_enabled" /></el-form-item>
            <el-row :gutter="16">
              <el-col :span="12"><el-form-item label="AppId"><el-input v-model="wechatForm.oa_app_id" /></el-form-item></el-col>
              <el-col :span="12"><el-form-item label="AppSecret">
                <el-input v-model="wechatForm.oa_app_secret" :type="showOaSecret?'text':'password'" show-password>
                  <i slot="suffix" class="el-icon-view" style="cursor:pointer;" @click="showOaSecret=!showOaSecret" />
                </el-input>
              </el-form-item></el-col>
              <el-col :span="12"><el-form-item label="Token"><el-input v-model="wechatForm.oa_token" /></el-form-item></el-col>
              <el-col :span="12"><el-form-item label="EncodingAESKey"><el-input v-model="wechatForm.oa_encoding_aes_key" /></el-form-item></el-col>
            </el-row>
            <el-form-item label="消息推送 URL">
              <el-input :value="oaCallbackUrl" readonly>
                <el-button slot="append" @click="copyText(oaCallbackUrl)">复制</el-button>
              </el-input>
            </el-form-item>
            <el-row :gutter="16">
              <el-col :span="12"><el-form-item label="启用 JS SDK"><el-switch v-model="wechatForm.oa_js_sdk_enabled" /></el-form-item></el-col>
              <el-col :span="12"><el-form-item label="启用网页授权"><el-switch v-model="wechatForm.oa_oauth_enabled" /></el-form-item></el-col>
            </el-row>
            <el-form-item>
              <el-button v-if="hasPerm('service:saveConfig')" type="primary" :loading="wechatSaving" @click="saveWechatConfig">保存配置</el-button>
              <el-button v-if="hasPerm('service:wechatTestOa')" @click="testWechatOa" :loading="wechatTestingOa">发送测试消息</el-button>
            </el-form-item>
          </el-form>
          <el-divider />
          <h4>微信小程序</h4>
          <el-form :model="wechatForm" label-width="150px" size="small" style="max-width:800px;">
            <el-form-item label="是否启用小程序服务"><el-switch v-model="wechatForm.mini_enabled" /></el-form-item>
            <el-row :gutter="16">
              <el-col :span="12"><el-form-item label="AppId"><el-input v-model="wechatForm.mini_app_id" /></el-form-item></el-col>
              <el-col :span="12"><el-form-item label="AppSecret">
                <el-input v-model="wechatForm.mini_app_secret" :type="showMiniSecret?'text':'password'" show-password>
                  <i slot="suffix" class="el-icon-view" style="cursor:pointer;" @click="showMiniSecret=!showMiniSecret" />
                </el-input>
              </el-form-item></el-col>
              <el-col :span="12"><el-form-item label="小程序原始ID"><el-input v-model="wechatForm.mini_original_id" placeholder="以 gh_ 开头" /></el-form-item></el-col>
            </el-row>
            <el-form-item label="页面路径映射">
              <el-row :gutter="16">
                <el-col :span="12"><el-form-item label="登录页路径" label-width="100px"><el-input v-model="wechatForm.mini_page_login" placeholder="pages/login/index" /></el-form-item></el-col>
                <el-col :span="12"><el-form-item label="工单详情页路径" label-width="110px"><el-input v-model="wechatForm.mini_page_order" placeholder="pages/order/detail" /></el-form-item></el-col>
              </el-row>
            </el-form-item>
            <el-row :gutter="16">
              <el-col :span="12"><el-form-item label="启用手机号授权"><el-switch v-model="wechatForm.mini_phone_enabled" /></el-form-item></el-col>
              <el-col :span="12"><el-form-item label="启用订阅消息"><el-switch v-model="wechatForm.mini_subscribe_enabled" /></el-form-item></el-col>
            </el-row>
            <el-form-item>
              <el-button v-if="hasPerm('service:saveConfig')" type="primary" :loading="wechatSaving" @click="saveWechatConfig">保存配置</el-button>
              <el-button v-if="hasPerm('service:wechatTestMini')" @click="testWechatMini" :loading="wechatTestingMini">生成测试二维码</el-button>
            </el-form-item>
          </el-form>
          <el-row :gutter="16" style="margin-top:16px;" v-if="wechatStatsData.length">
            <el-col :span="6" v-for="s in wechatStatsData" :key="s.label">
              <el-card shadow="hover"><div class="stat-val">{{ s.value }}</div><div class="stat-lbl">{{ s.label }}</div></el-card>
            </el-col>
          </el-row>
        </el-tab-pane>

        <!-- ═══════ 地图服务 Tab ═══════ -->
        <el-tab-pane label="地图服务" name="map">
          <el-form :model="mapForm" label-width="150px" size="small" style="max-width:800px;">
            <el-form-item label="是否启用地图服务"><el-switch v-model="mapForm.enabled" /></el-form-item>
            <el-form-item label="服务商">
              <el-select v-model="mapForm.provider" style="width:100%;">
                <el-option label="高德地图" value="gaode" />
                <el-option label="腾讯地图" value="tencent" />
              </el-select>
            </el-form-item>
            <el-form-item label="Key"><el-input v-model="mapForm.key" placeholder="地图 Web 服务 Key" /></el-form-item>
            <el-form-item v-if="mapForm.provider === 'tencent'" label="SecretKey"><el-input v-model="mapForm.secret_key" show-password placeholder="腾讯地图可选" /></el-form-item>
            <el-form-item>
              <el-button v-if="hasPerm('service:saveConfig')" type="primary" :loading="mapSaving" @click="saveMapConfig">保存配置</el-button>
              <el-button v-if="hasPerm('service:testConnection')" :loading="mapTesting" @click="testMap">测试连接</el-button>
            </el-form-item>
            <div style="color:#909399;font-size:13px;line-height:1.8">说明：用于培训扫码签到地点的地址反向解析（经纬度 → 地址）。前往 <a href="https://console.amap.com/" target="_blank">高德开放平台</a> 或 <a href="https://lbs.qq.com/" target="_blank">腾讯位置服务</a> 申请 Web 服务 Key。</div>
          </el-form>
        </el-tab-pane>
      </el-tabs>
    </el-card>

    <!-- ═══════ 存储配置弹窗 ═══════ -->
    <el-dialog :title="storageDialogTitle" :visible.sync="storageDialogVisible" :width="storageEngineEditing==='cos'?'560px':'520px'">
      <!-- 本地存储 -->
      <template v-if="storageEngineEditing==='local'">
        <el-form :model="localStorageForm" label-width="140px" size="small">
          <el-form-item label="存储根目录"><el-input v-model="localStorageForm.local_root" placeholder="storage/uploads" /></el-form-item>
          <el-form-item label="访问 URL 前缀"><el-input v-model="localStorageForm.local_url_prefix" placeholder="/uploads" /></el-form-item>
          <el-form-item label="启用 Web 直接访问"><el-switch v-model="localStorageForm.local_web_access" /></el-form-item>
          <el-form-item label="是否启用"><el-switch v-model="localStorageForm.local_enabled" /></el-form-item>
        </el-form>
      </template>
      <!-- 腾讯云COS -->
      <template v-if="storageEngineEditing==='cos'">
        <el-form :model="cosStorageForm" label-width="140px" size="small">
          <el-form-item label="所属地域">
            <el-select v-model="cosStorageForm.cos_region" style="width:100%;">
              <el-option label="北京 (ap-beijing)" value="ap-beijing" />
              <el-option label="上海 (ap-shanghai)" value="ap-shanghai" />
              <el-option label="广州 (ap-guangzhou)" value="ap-guangzhou" />
              <el-option label="成都 (ap-chengdu)" value="ap-chengdu" />
              <el-option label="南京 (ap-nanjing)" value="ap-nanjing" />
              <el-option label="香港 (ap-hongkong)" value="ap-hongkong" />
              <el-option label="新加坡 (ap-singapore)" value="ap-singapore" />
              <el-option label="东京 (ap-tokyo)" value="ap-tokyo" />
              <el-option label="多伦多 (na-toronto)" value="na-toronto" />
              <el-option label="法兰克福 (eu-frankfurt)" value="eu-frankfurt" />
            </el-select>
          </el-form-item>
          <el-form-item label="存储桶名称"><el-input v-model="cosStorageForm.cos_bucket" placeholder="my-bucket-1234567890" /></el-form-item>
          <el-form-item label="SecretId">
            <el-input v-model="cosStorageForm.cos_secret_id" :type="showCosSecretId?'text':'password'" show-password>
              <i slot="suffix" class="el-icon-view" style="cursor:pointer;" @click="showCosSecretId=!showCosSecretId" />
            </el-input>
          </el-form-item>
          <el-form-item label="SecretKey">
            <el-input v-model="cosStorageForm.cos_secret_key" :type="showCosSecretKey?'text':'password'" show-password>
              <i slot="suffix" class="el-icon-view" style="cursor:pointer;" @click="showCosSecretKey=!showCosSecretKey" />
            </el-input>
          </el-form-item>
          <el-form-item label="CDN 加速域名"><el-input v-model="cosStorageForm.cos_cdn_domain" placeholder="https://cdn.yourdomain.com" /></el-form-item>
          <el-form-item label="存储路径前缀"><el-input v-model="cosStorageForm.cos_path_prefix" placeholder="uploads" /></el-form-item>
          <el-form-item label="是否启用"><el-switch v-model="cosStorageForm.cos_enabled" /></el-form-item>
        </el-form>
      </template>
      <span slot="footer">
        <el-button @click="storageDialogVisible=false">取消</el-button>
        <el-button v-if="hasPerm('service:testConnection')" type="primary" :loading="storageTesting" @click="testStorage(storageEngineEditing)">测试连接</el-button>
        <el-button v-if="hasPerm('service:saveConfig')" type="primary" :loading="storageSaving" @click="saveStorageConfig">确定</el-button>
      </span>
    </el-dialog>

    <!-- ═══════ 腾讯云短信配置弹窗 ═══════ -->
    <el-dialog title="腾讯云短信配置" :visible.sync="smsTencentVisible" width="560px">
      <el-form :model="smsTencentForm" label-width="140px" size="small">
        <el-form-item label="SecretId">
          <el-input v-model="smsTencentForm.secret_id" :type="showSmsSecretId?'text':'password'" show-password>
            <i slot="suffix" class="el-icon-view" style="cursor:pointer;" @click="showSmsSecretId=!showSmsSecretId" />
          </el-input>
        </el-form-item>
        <el-form-item label="SecretKey">
          <el-input v-model="smsTencentForm.secret_key" :type="showSmsSecretKey?'text':'password'" show-password>
            <i slot="suffix" class="el-icon-view" style="cursor:pointer;" @click="showSmsSecretKey=!showSmsSecretKey" />
          </el-input>
        </el-form-item>
        <el-form-item label="短信应用 ID"><el-input v-model="smsTencentForm.app_id" /></el-form-item>
        <el-form-item label="短信签名"><el-input v-model="smsTencentForm.sign" /></el-form-item>
        <el-divider content-position="left">模板 ID 映射</el-divider>
        <el-form-item label="登录验证码"><el-input v-model="smsTencentForm.templates.login_template" /></el-form-item>
        <el-form-item label="重置密码验证码"><el-input v-model="smsTencentForm.templates.reset_pwd_template" /></el-form-item>
        <el-form-item label="安全告警通知"><el-input v-model="smsTencentForm.templates.security_template" /></el-form-item>
        <el-form-item label="工单状态变更通知"><el-input v-model="smsTencentForm.templates.work_order_template" /></el-form-item>
        <el-form-item label="消息通知"><el-input v-model="smsTencentForm.templates.notification_template" placeholder="消息通知中心发送短信所用模板ID" /></el-form-item>
        <el-form-item label="是否启用"><el-switch v-model="smsTencentForm.tencent_enabled" /></el-form-item>
      </el-form>
      <span slot="footer">
        <el-button @click="smsTencentVisible=false">取消</el-button>
        <el-button type="primary" :loading="smsSaving" @click="saveSmsConfig('tencent')">确定</el-button>
      </span>
    </el-dialog>

    <!-- ═══════ 阿里云短信配置弹窗 ═══════ -->
    <el-dialog title="阿里云短信配置" :visible.sync="smsAliyunVisible" width="560px">
      <el-form :model="smsAliyunForm" label-width="140px" size="small">
        <el-form-item label="AccessKeyId">
          <el-input v-model="smsAliyunForm.aliyun_access_key_id" :type="showAliKey?'text':'password'" show-password>
            <i slot="suffix" class="el-icon-view" style="cursor:pointer;" @click="showAliKey=!showAliKey" />
          </el-input>
        </el-form-item>
        <el-form-item label="AccessKeySecret">
          <el-input v-model="smsAliyunForm.aliyun_access_key_secret" :type="showAliSecret?'text':'password'" show-password>
            <i slot="suffix" class="el-icon-view" style="cursor:pointer;" @click="showAliSecret=!showAliSecret" />
          </el-input>
        </el-form-item>
        <el-form-item label="短信签名"><el-input v-model="smsAliyunForm.aliyun_sign" /></el-form-item>
        <el-divider content-position="left">模板 Code 映射</el-divider>
        <el-form-item label="登录验证码"><el-input v-model="smsAliyunForm.aliyun_templates.login_template" /></el-form-item>
        <el-form-item label="重置密码验证码"><el-input v-model="smsAliyunForm.aliyun_templates.reset_pwd_template" /></el-form-item>
        <el-form-item label="安全告警通知"><el-input v-model="smsAliyunForm.aliyun_templates.security_template" /></el-form-item>
        <el-form-item label="工单状态变更通知"><el-input v-model="smsAliyunForm.aliyun_templates.work_order_template" /></el-form-item>
        <el-form-item label="消息通知"><el-input v-model="smsAliyunForm.aliyun_templates.notification_template" placeholder="消息通知中心发送短信所用模板Code" /></el-form-item>
        <el-form-item label="是否启用"><el-switch v-model="smsAliyunForm.aliyun_enabled" /></el-form-item>
      </el-form>
      <span slot="footer">
        <el-button @click="smsAliyunVisible=false">取消</el-button>
        <el-button type="primary" :loading="smsSaving" @click="saveSmsConfig('aliyun')">确定</el-button>
      </span>
    </el-dialog>

    <!-- ═══════ 短信测试弹窗 ═══════ -->
    <el-dialog title="短信发送测试" :visible.sync="smsTestVisible" width="480px">
      <el-form :model="smsTestForm" label-width="100px" size="small">
        <el-form-item label="手机号"><el-input v-model="smsTestForm.phone" placeholder="11位手机号" maxlength="11" /></el-form-item>
        <el-form-item label="测试场景">
          <el-select v-model="smsTestForm.scene" style="width:100%;">
            <el-option label="登录验证码" value="login" />
            <el-option label="重置密码验证码" value="reset_pwd" />
            <el-option label="安全告警通知" value="security" />
            <el-option label="工单状态变更通知" value="work_order" />
          </el-select>
        </el-form-item>
        <el-form-item label="测试服务商">
          <el-tag :type="smsTestProvider==='tencent'?'primary':'success'">{{ smsTestProvider==='tencent'?'腾讯云':'阿里云' }}</el-tag>
        </el-form-item>
      </el-form>
      <span slot="footer">
        <el-button @click="smsTestVisible=false">取消</el-button>
        <el-button v-if="hasPerm('service:smsTestSend')" type="primary" :loading="smsTesting" @click="doSmsTest">发送测试</el-button>
      </span>
    </el-dialog>
  </div>
</template>

<script>
import {
  getAllServiceConfig, saveServiceConfig, testServiceConnection, resetServiceConfig,
  getServiceStatus, getHealthStatus,
  getStorageStats, getStorageActive, getSmsStats, smsTestSend, getSmsProviders,
  getEmailStats, emailTestSend, getWechatStats, wechatTestOa, wechatTestMini
} from '@/api/service'

export default {
  name: 'ServiceIndex',
  data() {
    return {
      activeTab: 'storage',
      loadingAll: false,
      // 存储
      storageEngines: [
        { id: 'local', name: '本地存储', icon: 'el-icon-folder-opened', summary: '-', statusClass: 'gray', statusTag: 'info', statusLabel: '未配置' },
        { id: 'cos', name: '腾讯云 COS', icon: 'el-icon-cloudy', summary: '-', statusClass: 'gray', statusTag: 'info', statusLabel: '未配置' }
      ],
      activeEngine: null,
      storageDialogVisible: false, storageEngineEditing: 'local',
      localStorageForm: { local_root: 'storage/uploads', local_url_prefix: '/uploads', local_web_access: true, local_enabled: true },
      cosStorageForm: { cos_region: 'ap-guangzhou', cos_bucket: '', cos_secret_id: '', cos_secret_key: '', cos_cdn_domain: '', cos_path_prefix: 'uploads', cos_enabled: true },
      storageSaving: false, storageTesting: false, showCosSecretId: false, showCosSecretKey: false,
      showStorageStats: false, storageStatsData: [],
      // 短信
      smsProviders: [
        { id: 'tencent', name: '腾讯云短信', icon: 'el-icon-message', color: '#67c23a', summary: '-', statusClass: 'gray', statusTag: 'info', statusLabel: '未配置' },
        { id: 'aliyun', name: '阿里云短信', icon: 'el-icon-message', color: '#ff6a00', summary: '-', statusClass: 'gray', statusTag: 'info', statusLabel: '未配置' }
      ],
      smsDefaultProvider: 'tencent',
      smsTencentVisible: false, smsAliyunVisible: false, smsSaving: false,
      smsTencentForm: { secret_id: '', secret_key: '', app_id: '', sign: '', templates: { login_template: '', reset_pwd_template: '', security_template: '', work_order_template: '', notification_template: '' }, tencent_enabled: true },
      smsAliyunForm: { aliyun_access_key_id: '', aliyun_access_key_secret: '', aliyun_sign: '', aliyun_templates: { login_template: '', reset_pwd_template: '', security_template: '', work_order_template: '', notification_template: '' }, aliyun_enabled: true },
      showSmsSecretId: false, showSmsSecretKey: false, showAliKey: false, showAliSecret: false,
      smsTestVisible: false, smsTesting: false, smsTestProvider: 'tencent',
      smsTestForm: { phone: '', scene: 'login' },
      smsStatsData: [], smsStatsProvider: '',
      // 邮件
      emailForm: { enabled: false, smtp_host: '', smtp_port: 465, smtp_encryption: 'ssl', from_email: '', from_name: '', smtp_user: '', smtp_pass: '', rate_per_minute: 60, rate_per_day: 1000 },
      showEmailPwd: false, emailSaving: false,
      emailTest: { to: '', subject: '系统邮件服务测试', content: '这是一封测试邮件，说明您的系统邮件服务配置正确。' },
      emailTesting: false, emailStatsData: [],
      // 微信
      wechatForm: {
        oa_enabled: false, oa_app_id: '', oa_app_secret: '', oa_token: '', oa_encoding_aes_key: '', oa_js_sdk_enabled: true, oa_oauth_enabled: true,
        mini_enabled: false, mini_app_id: '', mini_app_secret: '', mini_original_id: '', mini_page_login: 'pages/login/index', mini_page_order: 'pages/order/detail',
        mini_phone_enabled: true, mini_subscribe_enabled: true
      },
      showOaSecret: false, showMiniSecret: false, wechatSaving: false, wechatTestingOa: false, wechatTestingMini: false,
      wechatStatsData: [],
      // 地图
      mapForm: { enabled: false, provider: 'gaode', key: '', secret_key: '' },
      mapSaving: false, mapTesting: false,
      // 告警横幅
      alertBanner: { show: false, message: '' },
      // 拖拽排序
      dragOverIndex: -1,
      dragSource: null,
    }
  },
  computed: {
    storageDialogTitle() {
      return this.storageEngineEditing === 'cos' ? '腾讯云 COS 配置' : '本地存储配置'
    },
    oaCallbackUrl() {
      return window.location.origin + '/api/wechat/callback'
    }
  },
  created() {
    this.loadAll()
    // 支持从菜单 /services?tab=xxx 定位到对应 Tab（存储/短信/邮件/微信/地图）
    const t = this.$route.query.tab
    if (t && ['storage', 'sms', 'email', 'wechat', 'map'].includes(t)) this.activeTab = t
  },
  methods: {
    // 权限判断：按钮权限控制
    hasPerm(code) { const p = this.$store.state.user && this.$store.state.user.permissions ? this.$store.state.user.permissions : []; return p.indexOf(code) > -1 },
    async loadAll() {
      this.loadingAll = true
      try {
        const [configRes, statusRes, healthRes] = await Promise.all([
          getAllServiceConfig(), getServiceStatus(), getHealthStatus()
        ])
        this.applyConfig(configRes.data)
        this.applyStatus(statusRes.data)
        this.applyHealth(healthRes.data)
        this.loadStorageStats()
        this.loadSmsStats()
        this.loadEmailStats()
        this.loadWechatStats()
        const activeRes = await getStorageActive()
        this.activeEngine = activeRes.data
      } catch (e) { /* */ }
      this.loadingAll = false
    },
    refreshAll() { this.loadAll() },
    onTabClick(tab) {
      if (tab.name === 'storage') this.loadStorageStats()
      if (tab.name === 'sms') this.loadSmsStats()
      if (tab.name === 'email') this.loadEmailStats()
      if (tab.name === 'wechat') this.loadWechatStats()
    },
    applyConfig(configs) {
      if (!configs) return
      const sc = configs.storage || {}
      this.localStorageForm = { local_root: sc.local_root || 'storage/uploads', local_url_prefix: sc.local_url_prefix || '/uploads', local_web_access: sc.local_web_access !== false, local_enabled: sc.local_enabled !== false }
      this.cosStorageForm = { cos_region: sc.cos_region || 'ap-guangzhou', cos_bucket: sc.cos_bucket || '', cos_secret_id: sc.cos_secret_id || '', cos_secret_key: sc.cos_secret_key || '', cos_cdn_domain: sc.cos_cdn_domain || '', cos_path_prefix: sc.cos_path_prefix || 'uploads', cos_enabled: sc.cos_enabled !== false }
      const sm = configs.sms || {}
      this.smsDefaultProvider = sm.default_provider || 'tencent'
      this.smsTencentForm = { secret_id: sm.secret_id || '', secret_key: sm.secret_key || '', app_id: sm.app_id || '', sign: sm.sign || '', templates: { login_template: sm.templates?.login_template || '', reset_pwd_template: sm.templates?.reset_pwd_template || '', security_template: sm.templates?.security_template || '', work_order_template: sm.templates?.work_order_template || '', notification_template: sm.templates?.notification_template || '' }, tencent_enabled: sm.tencent_enabled !== false }
      this.smsAliyunForm = { aliyun_access_key_id: sm.aliyun_access_key_id || '', aliyun_access_key_secret: sm.aliyun_access_key_secret || '', aliyun_sign: sm.aliyun_sign || '', aliyun_templates: { login_template: sm.aliyun_templates?.login_template || '', reset_pwd_template: sm.aliyun_templates?.reset_pwd_template || '', security_template: sm.aliyun_templates?.security_template || '', work_order_template: sm.aliyun_templates?.work_order_template || '', notification_template: sm.aliyun_templates?.notification_template || '' }, aliyun_enabled: sm.aliyun_enabled !== false }
      const em = configs.email || {}
      this.emailForm = { enabled: !!em.enabled, smtp_host: em.smtp_host || '', smtp_port: em.smtp_port || 465, smtp_encryption: em.smtp_encryption || 'ssl', from_email: em.from_email || '', from_name: em.from_name || '', smtp_user: em.smtp_user || '', smtp_pass: em.smtp_pass || '', rate_per_minute: em.rate_per_minute || 60, rate_per_day: em.rate_per_day || 1000 }
      const wc = configs.wechat || {}
      this.wechatForm = { oa_enabled: !!wc.oa_enabled, oa_app_id: wc.oa_app_id || '', oa_app_secret: wc.oa_app_secret || '', oa_token: wc.oa_token || '', oa_encoding_aes_key: wc.oa_encoding_aes_key || '', oa_js_sdk_enabled: wc.oa_js_sdk_enabled !== false, oa_oauth_enabled: wc.oa_oauth_enabled !== false, mini_enabled: !!wc.mini_enabled, mini_app_id: wc.mini_app_id || '', mini_app_secret: wc.mini_app_secret || '', mini_original_id: wc.mini_original_id || '', mini_page_login: wc.mini_page_login || 'pages/login/index', mini_page_order: wc.mini_page_order || 'pages/order/detail', mini_phone_enabled: wc.mini_phone_enabled !== false, mini_subscribe_enabled: wc.mini_subscribe_enabled !== false }
      const mp = configs.map || {}
      this.mapForm = { enabled: !!mp.enabled, provider: mp.provider || 'gaode', key: mp.key || '', secret_key: mp.secret_key || '' }
    },
    applyStatus(statuses) {
      if (!statuses) return
      const ss = statuses.storage || {}
      this.storageEngines = this.storageEngines.map(e => {
        const enabled = e.id === 'local' ? this.localStorageForm.local_enabled : this.cosStorageForm.cos_enabled
        const configured = e.id === 'local' ? !!this.localStorageForm.local_root : !!(this.cosStorageForm.cos_bucket && this.cosStorageForm.cos_secret_id)
        if (enabled && configured) return { ...e, statusClass: 'green', statusTag: 'success', statusLabel: '已启用' }
        else if (enabled && !configured) return { ...e, statusClass: 'orange', statusTag: 'warning', statusLabel: '未配置' }
        else return { ...e, statusClass: 'gray', statusTag: 'info', statusLabel: '未启用' }
      })
      const sm = statuses.sms || {}
      const providers = sm.providers || {}
      const defaultProv = sm.default_provider || 'tencent'
      this.smsDefaultProvider = defaultProv
      this.smsProviders = this.smsProviders.map(p => {
        const ps = providers[p.id] || {}
        const enabled = !!ps.enabled
        const configured = !!ps.configured
        const signText = ps.sign || '-'
        if (enabled && configured) return { ...p, statusClass: 'green', statusTag: 'success', statusLabel: '已启用', summary: '签名: ' + signText }
        else if (enabled && !configured) return { ...p, statusClass: 'orange', statusTag: 'warning', statusLabel: '未配置', summary: '-' }
        else return { ...p, statusClass: 'gray', statusTag: 'info', statusLabel: '未启用', summary: '-' }
      })
    },
    applyHealth(health) {
      if (!health) return
      const now = new Date().toLocaleString()
      let alerts = []
      for (const [serviceId, h] of Object.entries(health)) {
        if (serviceId === 'storage') {
          this.storageEngines = this.storageEngines.map(e => {
            const enabled = e.id === 'local' ? this.localStorageForm.local_enabled : this.cosStorageForm.cos_enabled
            const tooltip = '最后检查: ' + (h.checked_at || now) + '\n' + (h.message || '')
            if (enabled && h.health === false) {
              alerts.push('存储服务连接异常')
              return { ...e, statusClass: 'red', statusTag: 'danger', statusLabel: '连接异常', summary: h.message || '', statusTooltip: tooltip }
            }
            if (enabled && h.health) return { ...e, statusTooltip: tooltip }
            return e
          })
          this.storageEngines = this.storageEngines.map(e => {
            if (e.id === 'local') return { ...e, summary: this.localStorageForm.local_root || '-' }
            if (e.id === 'cos') return { ...e, summary: this.cosStorageForm.cos_bucket || '-' }
            return e
          })
        }
        if (serviceId === 'sms') {
          const smsProviders = h.providers || {}
          for (const [pid, ps] of Object.entries(smsProviders)) {
            const pLabel = pid === 'tencent' ? '腾讯云' : '阿里云'
            if (ps.enabled && !ps.configured) alerts.push(pLabel + '配置不完整')
          }
          const checkedAt = h.checked_at || now
          this.smsProviders = this.smsProviders.map(p => {
            const ps = smsProviders[p.id] || {}
            if (ps.enabled && ps.configured) {
              return { ...p, statusTooltip: '最后检查: ' + checkedAt + '\n正常' }
            }
            return p
          })
        }
        if (serviceId === 'email') {
          if (h.health === false && this.emailForm.enabled) {
            alerts.push('邮件服务异常')
          }
        }
        if (serviceId === 'wechat') {
          if (h.health === false && (this.wechatForm.oa_enabled || this.wechatForm.mini_enabled)) {
            alerts.push('微信服务异常')
          }
        }
      }
      // 更新告警横幅
      if (alerts.length) {
        this.alertBanner = { show: true, message: '⚠️ 服务异常告警: ' + alerts.join('；') + '，请及时处理' }
      } else {
        this.alertBanner = { show: false, message: '' }
      }
    },
    // ---- 存储 ----
    openStorageConfig(engine) { this.storageEngineEditing = engine; this.storageDialogVisible = true },
    async testStorage(engine) {
      this.storageTesting = true
      try {
        if (this.storageDialogVisible) await this.saveStorageConfig(true)
        const r = await testServiceConnection('storage')
        this.$message.success(r.msg || '连接测试成功')
        this.loadAll()
      } catch (e) { /* */ }
      this.storageTesting = false
    },
    async saveStorageConfig(silent) {
      if (!silent) this.storageSaving = true
      try {
        const data = { ...this.localStorageForm, ...this.cosStorageForm }
        await saveServiceConfig('storage', data)
        if (!silent) { this.$message.success('配置保存成功'); this.storageDialogVisible = false; this.loadAll() }
      } catch (e) { /* */ }
      if (!silent) this.storageSaving = false
    },
    async loadStorageStats() {
      try {
        const r = await getStorageStats(); const s = r.data || {}
        this.storageStatsData = [
          { label: '总存储量', value: this.formatSize(s.total_size || 0) },
          { label: '文件总数', value: (s.total_files || 0).toLocaleString() },
          { label: '本月上传量', value: this.formatSize(s.month_upload?.size || 0) + ' / ' + (s.month_upload?.count || 0) + '个' },
          { label: '本月下载量', value: this.formatSize(s.month_download || 0) || '0' }
        ]
        this.showStorageStats = true
      } catch (e) { /* */ }
    },
    // ---- 短信 ----
    openSmsConfig(provider) {
      if (provider === 'aliyun') { this.smsAliyunVisible = true } else { this.smsTencentVisible = true }
    },
    async saveSmsConfig(provider) {
      this.smsSaving = true
      try {
        const data = provider === 'aliyun' ? { ...this.smsAliyunForm, default_provider: this.smsDefaultProvider } : { ...this.smsTencentForm, default_provider: this.smsDefaultProvider }
        await saveServiceConfig('sms', data)
        this.$message.success('配置保存成功')
        if (provider === 'aliyun') { this.smsAliyunVisible = false } else { this.smsTencentVisible = false }
        this.loadAll()
      } catch (e) { /* */ }
      this.smsSaving = false
    },
    async changeDefaultProvider(val) {
      try { await saveServiceConfig('sms', { default_provider: val }) } catch (e) { /* */ }
    },
    openSmsTest(provider) {
      this.smsTestProvider = provider || 'tencent'
      this.smsTestVisible = true
      this.smsTestForm = { phone: '', scene: 'login' }
    },
    async doSmsTest() {
      if (!/^1[3-9]\d{9}$/.test(this.smsTestForm.phone)) { this.$message.error('请输入正确的手机号'); return }
      this.smsTesting = true
      try {
        const data = { ...this.smsTestForm, provider: this.smsTestProvider }
        const r = await smsTestSend(data)
        this.$message.success(r.msg || '发送成功，请查收手机短信')
        this.smsTestVisible = false
      } catch (e) { /* */ }
      this.smsTesting = false
    },
    async loadSmsStats() {
      try {
        const r = await getSmsStats(this.smsStatsProvider)
        const s = r.data || {}
        this.smsStatsData = [
          { label: '本月发送总数', value: (s.month_total || 0).toLocaleString() },
          { label: '本月发送成功', value: (s.month_success || 0).toLocaleString() },
          { label: '本月发送失败', value: (s.month_fail || 0).toLocaleString() },
          { label: '今日发送数', value: (s.today_sent || 0).toLocaleString() }
        ]
      } catch (e) { /* */ }
    },
    // ---- 邮件 ----
    async saveEmailConfig() {
      this.emailSaving = true
      try { await saveServiceConfig('email', this.emailForm); this.$message.success('配置保存成功'); this.loadAll() } catch (e) { /* */ }
      this.emailSaving = false
    },
    async sendEmailTest() {
      if (!this.emailTest.to || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(this.emailTest.to)) { this.$message.error('请输入正确的邮箱地址'); return }
      this.emailTesting = true
      try { const r = await emailTestSend(this.emailTest); this.$message.success(r.msg || '发送成功，请查收邮箱') } catch (e) { /* */ }
      this.emailTesting = false
    },
    async loadEmailStats() {
      try { const r = await getEmailStats(); const s = r.data || {}; this.emailStatsData = [{ label:'本月发送总数',value:(s.month_total||0).toLocaleString() },{ label:'本月发送成功',value:(s.month_success||0).toLocaleString() },{ label:'本月发送失败',value:(s.month_fail||0).toLocaleString() },{ label:'今日发送数',value:(s.today_sent||0).toLocaleString() }] } catch (e) { /* */ }
    },
    // ---- 微信 ----
    async saveWechatConfig() {
      this.wechatSaving = true
      try { await saveServiceConfig('wechat', this.wechatForm); this.$message.success('配置保存成功'); this.loadAll() } catch (e) { /* */ }
      this.wechatSaving = false
    },
    // ---- 地图服务 ----
    async saveMapConfig() {
      this.mapSaving = true
      try { await saveServiceConfig('map', this.mapForm); this.$message.success('配置保存成功'); this.loadAll() } catch (e) { /* */ }
      this.mapSaving = false
    },
    async testMap() {
      this.mapTesting = true
      try {
        // 先获取当前实际位置，用于测试反向编码
        let coords = {}
        if (navigator.geolocation) {
          coords = await new Promise((resolve) => {
            navigator.geolocation.getCurrentPosition(
              (pos) => resolve({ lat: pos.coords.latitude, lng: pos.coords.longitude }),
              () => resolve({}),
              { enableHighAccuracy: true, timeout: 5000 }
            )
          })
        }
        const r = await testServiceConnection('map', coords)
        this.$message.success(r.msg || '地图服务连接成功')
      } catch (e) { /* */ }
      this.mapTesting = false
    },
    async testWechatOa() {
      this.wechatTestingOa = true
      try { const r = await wechatTestOa(); this.$message.success(r.msg || '测试消息发送成功') } catch (e) { /* */ }
      this.wechatTestingOa = false
    },
    async testWechatMini() {
      this.wechatTestingMini = true
      try {
        const r = await wechatTestMini()
        if (r.data?.qrcode_url) {
          this.$alert('<p style="text-align:center;"><img src="' + r.data.qrcode_url + '" style="width:200px;height:200px;" /></p><p style="text-align:center;">请使用微信扫码测试</p>', '测试二维码', { dangerouslyUseHTMLString: true })
        } else { this.$message.success(r.msg || '测试成功') }
      } catch (e) { /* */ }
      this.wechatTestingMini = false
    },
    async loadWechatStats() {
      try { const r = await getWechatStats(); const s = r.data || {}; this.wechatStatsData = [{ label:'公众号关注用户',value:(s.oa_followers||0).toLocaleString() },{ label:'小程序累计用户',value:(s.mini_users||0).toLocaleString() },{ label:'本月消息发送数',value:(s.month_messages||0).toLocaleString() },{ label:'本月登录次数',value:(s.month_logins||0).toLocaleString() }] } catch (e) { /* */ }
    },
    // ---- 通用 ----
    async resetService(service) {
      const labels = { storage:'存储', sms:'短信', email:'邮件', wechat:'微信' }
      await this.$confirm('确认将' + (labels[service] || service) + '服务的配置恢复为默认值？', '提示', { type: 'warning' })
      try { await resetServiceConfig(service); this.$message.success('配置已恢复默认'); this.loadAll() } catch (e) { /* */ }
    },
    copyText(text) {
      const ta = document.createElement('textarea'); ta.value = text; document.body.appendChild(ta); ta.select(); document.execCommand('copy'); document.body.removeChild(ta)
      this.$message.success('已复制')
    },
    formatSize(bytes) {
      if (!bytes || bytes === 0) return '0 B'
      const units = ['B', 'KB', 'MB', 'GB', 'TB']
      let i = 0; let size = bytes
      while (size >= 1024 && i < units.length - 1) { size /= 1024; i++ }
      return size.toFixed(1) + ' ' + units[i]
    },
    // ---- 拖拽排序 ----
    onDragStart(type, idx, e) {
      this.dragSource = { type, idx }
      e.dataTransfer.effectAllowed = 'move'
      e.dataTransfer.setData('text/plain', idx)
    },
    onDragOver(e) {
      e.dataTransfer.dropEffect = 'move'
    },
    onDrop(type, idx, e) {
      if (!this.dragSource || this.dragSource.type !== type) return
      const fromIdx = this.dragSource.idx
      if (fromIdx === idx) return
      // 重新排序
      const arr = this.storageEngines
      const item = arr.splice(fromIdx, 1)[0]
      arr.splice(idx, 0, item)
      // 更新数据触发重渲染
      this.storageEngines = [...arr]
      this.dragOverIndex = -1
      this.dragSource = null
      // 保存排序到服务器
      this.saveEngineOrder()
    },
    async saveEngineOrder() {
      const order = this.storageEngines.map(e => e.id)
      try {
        await saveServiceConfig('storage', { engines_order: order })
      } catch (e) { /* */ }
    },
  }
}
</script>

<style scoped>
.service-page { padding: 0; }
.engine-card { position: relative; margin-bottom: 16px; cursor: default; }
.engine-card.status-green { border-left: 3px solid #67c23a; }
.engine-card.status-red { border-left: 3px solid #f56c6c; }
.engine-card.status-gray { border-left: 3px solid #909399; }
.engine-card.status-orange { border-left: 3px solid #e6a23c; }
.engine-header { display: flex; align-items: center; justify-content: space-between; margin-bottom: 12px; }
.engine-name { font-size: 16px; font-weight: bold; }
.engine-icon { text-align: center; padding: 20px 0; }
.engine-footer { border-top: 1px solid #f0f0f0; padding-top: 12px; }
.engine-summary { font-size: 12px; color: #999; display: block; margin-bottom: 8px; }
.engine-actions { display: flex; gap: 8px; }
.drag-over >>> .el-card { border: 2px dashed #409eff !important; }
.stat-val { font-size: 28px; font-weight: bold; color: #409eff; text-align: center; }
.stat-lbl { font-size: 13px; color: #999; text-align: center; margin-top: 4px; }
h4 { margin: 16px 0 12px; color: #666; border-bottom: 1px solid #f0f0f0; padding-bottom: 6px; }
</style>
