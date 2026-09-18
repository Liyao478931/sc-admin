<!--
  文件：admin/src/views/settings/company.vue
  功能：系统设置 → 公司信息管理
    左侧分类导航（基础工商/联系方式/资质证照/品牌形象/社交平台/网站备案/公司简介/地理位置/客户合作方）
    顶部：保存草稿 / 预览效果 / 发布上线；右侧：信息同步；底部：操作日志
-->
<template>
  <div class="company-page">
    <!-- 顶部 -->
    <div class="page-head">
      <div>
        <h2>公司信息管理</h2>
        <div class="update-tip">最后更新：{{ lastUpdateText }}<el-tag v-if="status" size="mini" :type="status === 'published' ? 'success' : 'warning'" style="margin-left:8px">{{ status === 'published' ? '已发布' : '草稿' }}</el-tag></div>
      </div>
      <div class="head-actions">
        <el-button size="small" :disabled="!editable" :loading="saving" @click="saveDraft">保存草稿</el-button>
        <el-button size="small" @click="showPreview">预览效果</el-button>
        <el-button v-if="canPublish" size="small" type="primary" :loading="publishing" @click="doPublish">发布上线</el-button>
      </div>
    </div>

    <div class="main-body">
      <!-- 左侧分类导航 -->
      <div class="side-nav">
        <div v-for="nav in navs" :key="nav.key" class="nav-item" :class="{ active: activeNav === nav.key }" @click="activeNav = nav.key">{{ nav.label }}</div>
      </div>

      <!-- 内容区 -->
      <div class="content-area" v-loading="loading">
        <!-- 1 基础工商信息 -->
        <div v-if="activeNav === 'basic'">
          <div class="sec-title">基础工商信息</div>
          <div class="sec-sub">请填写营业执照登记的准确信息</div>
          <el-form :model="company" label-width="130px" size="small">
            <el-row :gutter="20">
              <el-col :span="12"><el-form-item label="公司全称" required><el-input v-model="company.company_name" :disabled="!editable" maxlength="200" /></el-form-item></el-col>
              <el-col :span="12"><el-form-item label="公司简称" required><el-input v-model="company.company_short_name" :disabled="!editable" maxlength="50" /></el-form-item></el-col>
              <el-col :span="12"><el-form-item label="英文名称"><el-input v-model="company.company_en_name" :disabled="!editable" maxlength="200" /></el-form-item></el-col>
              <el-col :span="12"><el-form-item label="法定代表人" required><el-input v-model="company.legal_person" :disabled="!editable" maxlength="50" /></el-form-item></el-col>
              <el-col :span="12"><el-form-item label="统一社会信用代码" required><el-input v-model="company.credit_code" :disabled="!editable" maxlength="18" placeholder="18位" /></el-form-item></el-col>
              <el-col :span="12"><el-form-item label="注册资本" required><el-input v-model="company.registered_capital" :disabled="!editable" maxlength="50" /></el-form-item></el-col>
              <el-col :span="12"><el-form-item label="成立日期"><el-date-picker v-model="company.establish_date" type="date" value-format="yyyy-MM-dd" :disabled="!editable" style="width:100%" /></el-form-item></el-col>
              <el-col :span="12"><el-form-item label="公司类型"><el-select v-model="company.company_type" :disabled="!editable" clearable style="width:100%"><el-option v-for="o in dicts.company_type" :key="o.value" :label="o.label" :value="o.value" /></el-select></el-form-item></el-col>
              <el-col :span="12"><el-form-item label="营业期限起始"><el-date-picker v-model="company.business_term_start" type="date" value-format="yyyy-MM-dd" :disabled="!editable" style="width:100%" /></el-form-item></el-col>
              <el-col :span="12"><el-form-item label="营业期限截止"><el-date-picker v-model="company.business_term_end" type="date" value-format="yyyy-MM-dd" :disabled="!editable" style="width:100%" /></el-form-item></el-col>
              <el-col :span="12"><el-form-item label="经营状态"><el-select v-model="company.business_status" :disabled="!editable" style="width:100%"><el-option v-for="o in dicts.company_business_status" :key="o.value" :label="o.label" :value="Number(o.value)" /></el-select></el-form-item></el-col>
              <el-col :span="12"><el-form-item label="所属行业"><el-input v-model="company.industry" :disabled="!editable" maxlength="100" /></el-form-item></el-col>
              <el-col :span="24"><el-form-item label="经营范围"><el-input v-model="company.business_scope" :disabled="!editable" type="textarea" :rows="3" /></el-form-item></el-col>
            </el-row>
          </el-form>
        </div>

        <!-- 2 联系方式 -->
        <div v-else-if="activeNav === 'contact'">
          <div class="sec-title">联系方式</div>
          <div class="sec-sub">请填写准确的联系方式用于对外展示</div>
          <el-form :model="company" label-width="130px" size="small">
            <el-row :gutter="20">
              <el-col :span="12"><el-form-item label="联系电话" required><el-input v-model="company.phone" :disabled="!editable" maxlength="50" /></el-form-item></el-col>
              <el-col :span="12"><el-form-item label="客服热线"><el-input v-model="company.hotline" :disabled="!editable" maxlength="50" /></el-form-item></el-col>
              <el-col :span="12"><el-form-item label="传真号码"><el-input v-model="company.fax" :disabled="!editable" maxlength="50" /></el-form-item></el-col>
              <el-col :span="12"><el-form-item label="电子邮箱" required><el-input v-model="company.email" :disabled="!editable" maxlength="100" /></el-form-item></el-col>
              <el-col :span="12"><el-form-item label="企业官网"><el-input v-model="company.website" :disabled="!editable" maxlength="200" placeholder="https://" /></el-form-item></el-col>
              <el-col :span="12"><el-form-item label="邮政编码"><el-input v-model="company.zipcode" :disabled="!editable" maxlength="20" /></el-form-item></el-col>
              <el-col :span="24"><el-form-item label="公司地址" required><el-input v-model="company.address" :disabled="!editable" type="textarea" :rows="2" /></el-form-item></el-col>
            </el-row>
          </el-form>
        </div>

        <!-- 3 资质证照 -->
        <div v-else-if="activeNav === 'cert'">
          <div class="sec-title">资质证照</div>
          <div class="sec-sub">上传企业资质证书图片，支持jpg、png格式</div>
          <el-form :model="company" label-width="130px" size="small">
            <el-row :gutter="16">
              <el-col :span="6" v-for="c in certItems" :key="c.key"><el-form-item :label="c.label"><ImageUpload v-model="company[c.key]" :limit="1" :disabled="!editable" /></el-form-item></el-col>
            </el-row>
            <div class="tip">支持jpg、png、gif格式，单个文件不超过2MB</div>
          </el-form>
        </div>

        <!-- 4 品牌形象 -->
        <div v-else-if="activeNav === 'brand'">
          <div class="sec-title">品牌形象</div>
          <div class="sec-sub">上传公司品牌形象素材</div>
          <el-form :model="company" label-width="130px" size="small">
            <el-row :gutter="20">
              <el-col :span="8"><el-form-item label="公司Logo"><ImageUpload v-model="company.logo" :limit="1" :disabled="!editable" /></el-form-item></el-col>
              <el-col :span="8"><el-form-item label="网站Favicon"><ImageUpload v-model="company.favicon" :limit="1" :disabled="!editable" /></el-form-item></el-col>
              <el-col :span="8"><el-form-item label="品牌标语"><el-input v-model="company.brand_slogan" :disabled="!editable" maxlength="200" /></el-form-item></el-col>
              <el-col :span="12"><el-form-item label="品牌色"><el-input v-model="company.brand_color" :disabled="!editable" maxlength="100" placeholder="主色 / 辅色" /></el-form-item></el-col>
              <el-col :span="12"><el-form-item label="公司宣传片"><el-input v-model="company.promo_video" :disabled="!editable" maxlength="500" placeholder="视频链接（mp4/mov，≤100MB）" /></el-form-item></el-col>
            </el-row>
          </el-form>
        </div>

        <!-- 5 社交平台 -->
        <div v-else-if="activeNav === 'social'">
          <div class="sec-title">社交平台</div>
          <div class="sec-sub">配置公司社交媒体账号信息</div>
          <el-form :model="company" label-width="130px" size="small">
            <el-row :gutter="20">
              <el-col :span="12"><el-form-item label="微信公众号"><el-input v-model="company.wechat_name" :disabled="!editable" maxlength="100" /></el-form-item></el-col>
              <el-col :span="12"><el-form-item label="微信AppID"><el-input v-model="company.wechat_appid" :disabled="!editable" maxlength="100" /></el-form-item></el-col>
              <el-col :span="12"><el-form-item label="微博链接"><el-input v-model="company.weibo_url" :disabled="!editable" maxlength="300" /></el-form-item></el-col>
              <el-col :span="12"><el-form-item label="抖音链接"><el-input v-model="company.douyin_url" :disabled="!editable" maxlength="300" /></el-form-item></el-col>
              <el-col :span="12"><el-form-item label="企业微信"><el-switch v-model="company.wecom_enabled" :active-value="1" :inactive-value="0" :disabled="!editable" active-text="已开通" inactive-text="未开通" /></el-form-item></el-col>
              <el-col :span="12" v-if="company.wecom_enabled"><el-form-item label="企业微信ID"><el-input v-model="company.wecom_id" :disabled="!editable" maxlength="100" /></el-form-item></el-col>
              <el-col :span="12" v-if="company.wecom_enabled"><el-form-item label="企业微信Secret"><el-input v-model="company.wecom_secret" :disabled="!editable" type="password" show-password maxlength="200" /></el-form-item></el-col>
            </el-row>
          </el-form>
        </div>

        <!-- 6 网站备案 -->
        <div v-else-if="activeNav === 'beian'">
          <div class="sec-title">网站备案</div>
          <div class="sec-sub">填写网站备案相关信息</div>
          <el-form :model="company" label-width="130px" size="small">
            <el-row :gutter="20">
              <el-col :span="12"><el-form-item label="ICP备案号" required><el-input v-model="company.icp_no" :disabled="!editable" maxlength="100" /></el-form-item></el-col>
              <el-col :span="12"><el-form-item label="公安备案号"><el-input v-model="company.police_record_no" :disabled="!editable" maxlength="100" /></el-form-item></el-col>
              <el-col :span="24"><el-form-item label="版权信息"><el-input v-model="company.copyright" :disabled="!editable" maxlength="300" /></el-form-item></el-col>
              <el-col :span="12"><el-form-item label="备案主体名称"><el-input v-model="company.filing_subject" :disabled="!editable" maxlength="200" /></el-form-item></el-col>
              <el-col :span="12"><el-form-item label="备案主体性质"><el-select v-model="company.filing_subject_type" :disabled="!editable" clearable style="width:100%"><el-option label="企业" value="enterprise" /><el-option label="个人" value="personal" /><el-option label="事业单位" value="institution" /><el-option label="社会团体" value="organization" /></el-select></el-form-item></el-col>
            </el-row>
          </el-form>
        </div>

        <!-- 7 公司简介 -->
        <div v-else-if="activeNav === 'intro'">
          <div class="sec-title">公司简介</div>
          <div class="sec-sub">编写公司介绍，将展示在对外宣传页面</div>
          <el-form :model="company" label-width="130px" size="small">
            <el-form-item label="公司简介"><el-input v-model="company.intro" :disabled="!editable" type="textarea" :rows="12" placeholder="支持 HTML（富文本）" /></el-form-item>
            <div class="tip">当前字数：{{ (company.intro || '').replace(/<[^>]+>/g, '').length }} 字</div>
          </el-form>
        </div>

        <!-- 8 地理位置 -->
        <div v-else-if="activeNav === 'geo'">
          <div class="sec-title">地理位置</div>
          <div class="sec-sub">配置公司位置信息</div>
          <el-form :model="company" label-width="130px" size="small">
            <el-row :gutter="20">
              <el-col :span="12"><el-form-item label="经度"><el-input v-model="company.geo_lng" :disabled="!editable" maxlength="30" placeholder="如 38.4167"><template slot="append">°E</template></el-input></el-form-item></el-col>
              <el-col :span="12"><el-form-item label="纬度"><el-input v-model="company.geo_lat" :disabled="!editable" maxlength="30" placeholder="如 112.7333"><template slot="append">°N</template></el-input></el-form-item></el-col>
              <el-col :span="24"><el-form-item label="地图位置"><el-input v-model="company.map_location" :disabled="!editable" maxlength="255" /></el-form-item></el-col>
              <el-col :span="24"><el-form-item label="交通指引"><el-input v-model="company.traffic_guide" :disabled="!editable" type="textarea" :rows="2" /></el-form-item></el-col>
            </el-row>
          </el-form>
        </div>

        <!-- 9 签约与银行信息 -->
        <div v-else-if="activeNav === 'bank'">
          <div class="sec-title">签约与银行信息</div>
          <div class="sec-sub">用于合同模板签署栏（我司开户银行 / 委托代理人）</div>
          <el-form :model="company" label-width="130px" size="small">
            <el-row :gutter="20">
              <el-col :span="12"><el-form-item label="委托代理人"><el-input v-model="company.agent" :disabled="!editable" maxlength="50" /></el-form-item></el-col>
              <el-col :span="12"><el-form-item label="账户类型"><el-select v-model="company.account_type" :disabled="!editable" clearable style="width:100%"><el-option v-for="o in dicts.account_type" :key="o.value" :label="o.label" :value="o.value" /></el-select></el-form-item></el-col>
              <el-col :span="12"><el-form-item label="开户银行"><el-input v-model="company.bank_name" :disabled="!editable" maxlength="100" /></el-form-item></el-col>
              <el-col :span="12"><el-form-item label="银行账号"><el-input v-model="company.bank_account" :disabled="!editable" maxlength="50" /></el-form-item></el-col>
              <el-col :span="12"><el-form-item label="开户行联行号"><el-input v-model="company.bank_branch_code" :disabled="!editable" maxlength="100" /></el-form-item></el-col>
            </el-row>
          </el-form>
        </div>

        <!-- 10 客户/合作方默认信息 -->
        <div v-else-if="activeNav === 'partner'">
          <div class="sec-title">客户/合作方默认信息</div>
          <el-tabs v-model="ptab">
            <!-- 甲方基本信息 -->
            <el-tab-pane label="甲方基本信息" name="p1">
              <el-form :model="partner" label-width="130px" size="small">
                <el-row :gutter="20">
                  <el-col :span="12"><el-form-item label="甲方名称"><el-input v-model="partner.party_name" :disabled="!editable" maxlength="200" /></el-form-item></el-col>
                  <el-col :span="12"><el-form-item label="甲方地址"><el-input v-model="partner.party_address" :disabled="!editable" maxlength="255" /></el-form-item></el-col>
                  <el-col :span="12"><el-form-item label="法定代表人"><el-input v-model="partner.party_legal_person" :disabled="!editable" maxlength="50" /></el-form-item></el-col>
                  <el-col :span="12"><el-form-item label="委托代理人"><el-input v-model="partner.party_agent" :disabled="!editable" maxlength="50" /></el-form-item></el-col>
                  <el-col :span="12"><el-form-item label="联系电话"><el-input v-model="partner.party_phone" :disabled="!editable" maxlength="50" /></el-form-item></el-col>
                  <el-col :span="12"><el-form-item label="传真号码"><el-input v-model="partner.party_fax" :disabled="!editable" maxlength="50" /></el-form-item></el-col>
                </el-row>
              </el-form>
            </el-tab-pane>
            <!-- 银行账户 -->
            <el-tab-pane label="银行账户信息" name="p2">
              <el-form :model="partner" label-width="130px" size="small">
                <el-row :gutter="20">
                  <el-col :span="12"><el-form-item label="开户银行"><el-input v-model="partner.bank_name" :disabled="!editable" maxlength="100" /></el-form-item></el-col>
                  <el-col :span="12"><el-form-item label="银行账号"><el-input v-model="partner.bank_account" :disabled="!editable" maxlength="50" /></el-form-item></el-col>
                  <el-col :span="12"><el-form-item label="账户类型"><el-select v-model="partner.account_type" :disabled="!editable" clearable style="width:100%"><el-option v-for="o in dicts.account_type" :key="o.value" :label="o.label" :value="o.value" /></el-select></el-form-item></el-col>
                  <el-col :span="12"><el-form-item label="开户行联行号"><el-input v-model="partner.bank_branch_code" :disabled="!editable" maxlength="100" /></el-form-item></el-col>
                </el-row>
              </el-form>
            </el-tab-pane>
            <!-- 财务税务 -->
            <el-tab-pane label="财务税务信息" name="p3">
              <el-form :model="partner" label-width="130px" size="small">
                <el-row :gutter="20">
                  <el-col :span="12"><el-form-item label="税号"><el-input v-model="partner.tax_no" :disabled="!editable" maxlength="50" /></el-form-item></el-col>
                  <el-col :span="12"><el-form-item label="纳税人类型"><el-select v-model="partner.vat_type" :disabled="!editable" clearable style="width:100%"><el-option v-for="o in dicts.vat_type" :key="o.value" :label="o.label" :value="o.value" /></el-select></el-form-item></el-col>
                  <el-col :span="12"><el-form-item label="增值税税率"><el-select v-model="partner.vat_rate" :disabled="!editable" clearable style="width:100%"><el-option v-for="o in dicts.vat_rate" :key="o.value" :label="o.label" :value="o.value" /></el-select></el-form-item></el-col>
                  <el-col :span="12"><el-form-item label="发票类型"><el-select v-model="invoiceTypes" :disabled="!editable" multiple collapse-tags style="width:100%"><el-option v-for="o in dicts.invoice_type" :key="o.value" :label="o.label" :value="o.value" /></el-select></el-form-item></el-col>
                  <el-col :span="24"><el-form-item label="发票邮寄地址"><el-input v-model="partner.invoice_address" :disabled="!editable" type="textarea" :rows="2" /></el-form-item></el-col>
                  <el-col :span="12"><el-form-item label="财务联系人"><el-input v-model="partner.finance_contact" :disabled="!editable" maxlength="50" /></el-form-item></el-col>
                  <el-col :span="12"><el-form-item label="财务联系电话"><el-input v-model="partner.finance_phone" :disabled="!editable" maxlength="50" /></el-form-item></el-col>
                  <el-col :span="24"><el-form-item label="财务邮箱"><el-input v-model="partner.finance_email" :disabled="!editable" maxlength="100" /></el-form-item></el-col>
                </el-row>
              </el-form>
            </el-tab-pane>
            <!-- 印章 -->
            <el-tab-pane label="印章管理" name="p4">
              <el-form :model="partner" label-width="130px" size="small">
                <el-row :gutter="16">
                  <el-col :span="6" v-for="s in sealItems" :key="s.key"><el-form-item :label="s.label"><ImageUpload v-model="partner[s.key]" :limit="1" :disabled="!editable" /></el-form-item></el-col>
                </el-row>
                <div class="tip">支持png格式，透明背景，不超过2MB</div>
              </el-form>
            </el-tab-pane>
            <!-- 合同模板 -->
            <el-tab-pane label="合同模板" name="p5">
              <el-form :model="partner" label-width="130px" size="small">
                <el-form-item label="默认合同模板"><el-input v-model="partner.default_contract_template" :disabled="!editable" maxlength="300" placeholder="如 标准采购合同_v2.docx" /></el-form-item>
                <el-row :gutter="20">
                  <el-col :span="12"><el-form-item label="付款方式"><el-select v-model="paymentMethods" :disabled="!editable" multiple collapse-tags style="width:100%"><el-option v-for="o in dicts.payment_method" :key="o.value" :label="o.label" :value="o.value" /></el-select></el-form-item></el-col>
                  <el-col :span="12"><el-form-item label="质保期"><el-input v-model="partner.warranty_months" :disabled="!editable" maxlength="50" /></el-form-item></el-col>
                  <el-col :span="24"><el-form-item label="付款条件"><el-input v-model="partner.payment_conditions" :disabled="!editable" type="textarea" :rows="3" /></el-form-item></el-col>
                  <el-col :span="12"><el-form-item label="交货方式"><el-select v-model="deliveryMethods" :disabled="!editable" multiple collapse-tags style="width:100%"><el-option v-for="o in dicts.delivery_method" :key="o.value" :label="o.label" :value="o.value" /></el-select></el-form-item></el-col>
                </el-row>
              </el-form>
            </el-tab-pane>
            <!-- 联系人 -->
            <el-tab-pane label="联系人信息" name="p6">
              <el-form :model="partner" label-width="130px" size="small">
                <el-divider content-position="left">主要联系人</el-divider>
                <el-row :gutter="20">
                  <el-col :span="12"><el-form-item label="姓名"><el-input v-model="partner.primary_contact" :disabled="!editable" maxlength="50" /></el-form-item></el-col>
                  <el-col :span="12"><el-form-item label="职务"><el-input v-model="partner.primary_contact_title" :disabled="!editable" maxlength="50" /></el-form-item></el-col>
                  <el-col :span="12"><el-form-item label="手机号码"><el-input v-model="partner.primary_contact_phone" :disabled="!editable" maxlength="50" /></el-form-item></el-col>
                  <el-col :span="12"><el-form-item label="邮箱"><el-input v-model="partner.primary_contact_email" :disabled="!editable" maxlength="100" /></el-form-item></el-col>
                  <el-col :span="12"><el-form-item label="微信号"><el-input v-model="partner.primary_contact_wechat" :disabled="!editable" maxlength="100" /></el-form-item></el-col>
                  <el-col :span="12"><el-form-item label="企业微信"><el-input v-model="partner.primary_contact_wecom" :disabled="!editable" maxlength="100" /></el-form-item></el-col>
                </el-row>
                <el-divider content-position="left">备用联系人</el-divider>
                <el-row :gutter="20">
                  <el-col :span="12"><el-form-item label="姓名"><el-input v-model="partner.backup_contact" :disabled="!editable" maxlength="50" /></el-form-item></el-col>
                  <el-col :span="12"><el-form-item label="职务"><el-input v-model="partner.backup_contact_title" :disabled="!editable" maxlength="50" /></el-form-item></el-col>
                  <el-col :span="12"><el-form-item label="手机号码"><el-input v-model="partner.backup_contact_phone" :disabled="!editable" maxlength="50" /></el-form-item></el-col>
                  <el-col :span="12"><el-form-item label="邮箱"><el-input v-model="partner.backup_contact_email" :disabled="!editable" maxlength="100" /></el-form-item></el-col>
                </el-row>
              </el-form>
            </el-tab-pane>
            <!-- 信用评价 -->
            <el-tab-pane label="信用评价" name="p7">
              <el-form :model="partner" label-width="130px" size="small">
                <el-row :gutter="20">
                  <el-col :span="12"><el-form-item label="信用等级"><el-select v-model="partner.credit_level" :disabled="!editable" clearable style="width:100%"><el-option v-for="o in dicts.credit_level" :key="o.value" :label="o.label" :value="o.value" /></el-select></el-form-item></el-col>
                  <el-col :span="12"><el-form-item label="授信额度"><el-input v-model="partner.credit_limit" :disabled="!editable" maxlength="50" placeholder="如 100万元" /></el-form-item></el-col>
                  <el-col :span="12"><el-form-item label="信用期限"><el-select v-model="partner.credit_term" :disabled="!editable" clearable style="width:100%"><el-option v-for="t in ['30天','60天','90天','120天','180天']" :key="t" :label="t" :value="t" /></el-select></el-form-item></el-col>
                  <el-col :span="12"><el-form-item label="合作年限"><el-input v-model="partner.cooperation_years" :disabled="!editable" maxlength="20" placeholder="如 5年" /></el-form-item></el-col>
                  <el-col :span="24"><el-form-item label="历史合作评价"><el-input v-model="partner.cooperation_comment" :disabled="!editable" type="textarea" :rows="2" /></el-form-item></el-col>
                </el-row>
              </el-form>
            </el-tab-pane>
            <!-- 历史交易记录 -->
            <el-tab-pane label="历史交易记录" name="p8">
              <el-row :gutter="12" class="stat-row">
                <el-col :span="6" v-for="s in tradeStats" :key="s.label"><el-card shadow="never" class="stat-card"><div class="stat-num">{{ s.value }}</div><div class="stat-label">{{ s.label }}</div></el-card></el-col>
              </el-row>
              <el-table :data="tradeList" size="mini" border>
                <el-table-column prop="seq" label="序号" width="60" />
                <el-table-column prop="contract_no" label="订单编号" width="170" />
                <el-table-column prop="trade_date" label="交易日期" width="110" />
                <el-table-column prop="amount" label="交易金额" width="120" />
                <el-table-column prop="type" label="交易类型" width="110" />
                <el-table-column prop="status" label="状态" width="100" />
                <el-table-column label="操作"><el-button size="mini" type="text" @click="$message.info('请到合同列表查看详情')">查看详情</el-button></el-table-column>
              </el-table>
              <div class="tip">交易记录由合同数据动态生成</div>
            </el-tab-pane>
          </el-tabs>
        </div>
      </div>

      <!-- 右侧：信息同步 -->
      <div class="side-panel">
        <div class="panel-title">信息同步</div>
        <el-checkbox-group v-model="syncChannels">
          <el-checkbox label="website" style="display:block">同步到官网</el-checkbox>
          <el-checkbox label="wechat" style="display:block">同步到公众号</el-checkbox>
          <el-checkbox label="miniapp" style="display:block">同步到小程序</el-checkbox>
        </el-checkbox-group>
        <el-button size="small" type="primary" style="width:100%;margin-top:10px" :loading="syncing" :disabled="!canSync" @click="doSync">立即同步</el-button>
      </div>
    </div>

    <!-- 操作日志 -->
    <div class="log-area">
      <div class="log-title">操作日志<span class="log-refresh" @click="loadLogs">刷新</span></div>
      <el-table :data="logs" size="mini" border>
        <el-table-column prop="operator" label="操作人" width="120" />
        <el-table-column prop="log_time" label="操作时间" width="170" />
        <el-table-column prop="action" label="操作类型" width="110" />
        <el-table-column prop="content" label="变更内容" min-width="200" show-overflow-tooltip />
      </el-table>
    </div>

    <!-- 预览弹窗 -->
    <el-dialog title="公司信息预览" :visible.sync="previewVisible" width="760px" top="5vh">
      <div v-if="previewData" class="preview-body">
        <div class="pv-logo" v-if="previewData.logo && previewData.logo.length"><img :src="previewData.logo[0]" style="max-width:120px;max-height:120px" /></div>
        <h2 style="text-align:center">{{ previewData.company_name }}</h2>
        <p v-if="previewData.brand_slogan" style="text-align:center;color:#909399">{{ previewData.brand_slogan }}</p>
        <el-descriptions :column="1" border size="small">
          <el-descriptions-item label="公司地址">{{ previewData.address || '-' }}</el-descriptions-item>
          <el-descriptions-item label="联系电话">{{ previewData.phone || '-' }}</el-descriptions-item>
          <el-descriptions-item label="电子邮箱">{{ previewData.email || '-' }}</el-descriptions-item>
          <el-descriptions-item label="企业官网">{{ previewData.website || '-' }}</el-descriptions-item>
          <el-descriptions-item label="ICP备案号">{{ previewData.icp_no || '-' }}</el-descriptions-item>
          <el-descriptions-item label="公安备案号">{{ previewData.police_record_no || '-' }}</el-descriptions-item>
        </el-descriptions>
        <div v-if="previewData.intro" class="pv-intro" v-html="previewData.intro"></div>
        <div v-if="previewData.copyright" class="pv-copy">{{ previewData.copyright }}</div>
      </div>
      <span slot="footer"><el-button size="small" @click="previewVisible = false">关闭预览</el-button></span>
    </el-dialog>
  </div>
</template>

<script>
import { getCompanyConfig, saveCompanyConfig, publishCompany, previewCompany, getCompanyLogs, syncCompany, getTradeRecords } from '../../api/company'
import { getDictByCode } from '../../api/dictionary'
import ImageUpload from './components/ImageUpload.vue'

const C_EMPTY = {
  company_name: '', company_short_name: '', company_en_name: '', legal_person: '', credit_code: '',
  registered_capital: '', establish_date: '', business_term_start: '', business_term_end: '',
  business_status: 1, company_type: '', industry: '', business_scope: '',
  phone: '', hotline: '', fax: '', email: '', website: '', zipcode: '', address: '',
  bank_name: '', bank_account: '', account_type: '', bank_branch_code: '', agent: '',
  business_license: [], org_code_cert: [], tax_cert: [], account_permit: [], safety_production_cert: [],
  iso9001_cert: [], iso14001_cert: [], ohsas_cert: [], other_certs: [],
  logo: [], favicon: [], brand_slogan: '', brand_color: '', promo_video: '',
  wechat_name: '', wechat_appid: '', weibo_url: '', douyin_url: '', wecom_enabled: 0, wecom_id: '', wecom_secret: '',
  icp_no: '', police_record_no: '', copyright: '', filing_subject: '', filing_subject_type: '',
  intro: '', geo_lng: '', geo_lat: '', map_location: '', traffic_guide: ''
}
const P_EMPTY = {
  party_name: '', party_address: '', party_legal_person: '', party_agent: '', party_phone: '', party_fax: '',
  bank_name: '', bank_account: '', account_type: '', bank_branch_code: '',
  tax_no: '', vat_type: '', vat_rate: '', invoice_types: '', invoice_address: '',
  finance_contact: '', finance_phone: '', finance_email: '',
  seal_company: [], seal_contract: [], seal_finance: [], seal_invoice: [], seal_legal: [],
  default_contract_template: '', payment_methods: '', payment_conditions: '', warranty_months: '', delivery_methods: '',
  primary_contact: '', primary_contact_title: '', primary_contact_phone: '', primary_contact_email: '', primary_contact_wechat: '', primary_contact_wecom: '',
  backup_contact: '', backup_contact_title: '', backup_contact_phone: '', backup_contact_email: '',
  credit_level: '', credit_limit: '', credit_term: '', cooperation_years: '', cooperation_comment: '',
  first_coop_date: '', last_trade_date: '', total_amount: '', total_orders: ''
}
const C_IMG = ['business_license', 'org_code_cert', 'tax_cert', 'account_permit', 'safety_production_cert', 'iso9001_cert', 'iso14001_cert', 'ohsas_cert', 'other_certs', 'logo', 'favicon']
const P_IMG = ['seal_company', 'seal_contract', 'seal_finance', 'seal_invoice', 'seal_legal']

export default {
  name: 'CompanySettings',
  components: { ImageUpload },
  data() {
    return {
      loading: false, saving: false, publishing: false, syncing: false,
      activeNav: 'basic', ptab: 'p1',
      company: { ...C_EMPTY }, partner: { ...P_EMPTY },
      status: 'draft', lastUpdateText: '-', isSuper: false, canEdit: false, canPublish: false, canSync: false,
      dicts: {}, syncChannels: [], logs: [], tradeStats: [], tradeList: [],
      previewVisible: false, previewData: null,
      navs: [
        { key: 'basic', label: '基础工商信息' }, { key: 'contact', label: '联系方式' },
        { key: 'cert', label: '资质证照' }, { key: 'brand', label: '品牌形象' },
        { key: 'social', label: '社交平台' }, { key: 'beian', label: '网站备案' },
        { key: 'intro', label: '公司简介' }, { key: 'geo', label: '地理位置' },
        { key: 'bank', label: '签约与银行' },
        { key: 'partner', label: '客户合作方信息' }
      ],
      certItems: [
        { key: 'business_license', label: '营业执照' }, { key: 'org_code_cert', label: '组织机构代码证' },
        { key: 'tax_cert', label: '税务登记证' }, { key: 'account_permit', label: '开户许可证' },
        { key: 'safety_production_cert', label: '安全生产许可证' }, { key: 'iso9001_cert', label: '质量体系认证' },
        { key: 'iso14001_cert', label: '环境体系认证' }, { key: 'ohsas_cert', label: '职业健康认证' },
        { key: 'other_certs', label: '其他资质证书' }
      ],
      sealItems: [
        { key: 'seal_company', label: '公章' }, { key: 'seal_contract', label: '合同专用章' },
        { key: 'seal_finance', label: '财务专用章' }, { key: 'seal_invoice', label: '发票专用章' },
        { key: 'seal_legal', label: '法定代表人章' }
      ]
    }
  },
  computed: {
    editable() { return this.canEdit },
    invoiceTypes: {
      get() { return (this.partner.invoice_types || '').split(',').filter(Boolean) },
      set(v) { this.partner.invoice_types = v.join(',') }
    },
    paymentMethods: {
      get() { return (this.partner.payment_methods || '').split(',').filter(Boolean) },
      set(v) { this.partner.payment_methods = v.join(',') }
    },
    deliveryMethods: {
      get() { return (this.partner.delivery_methods || '').split(',').filter(Boolean) },
      set(v) { this.partner.delivery_methods = v.join(',') }
    }
  },
  created() { this.load() },
  methods: {
    normList(v) { if (Array.isArray(v)) return v; if (typeof v === 'string' && v) return [v]; return [] },
    async load() {
      this.loading = true
      try {
        const r = await getCompanyConfig()
        if (r.code === 0 && r.data) {
          const d = r.data
          this.company = { ...C_EMPTY, ...(d.company || {}) }
          this.partner = { ...P_EMPTY, ...(d.partner || {}) }
          C_IMG.forEach(k => { this.company[k] = this.normList(this.company[k]) })
          P_IMG.forEach(k => { this.partner[k] = this.normList(this.partner[k]) })
          this.status = d.status || 'draft'
          this.lastUpdateText = d.updated_at ? this.fmtTime(d.updated_at) : '-'
          this.isSuper = !!d.is_super_admin
          this.canEdit = !!d.can_edit
          this.canPublish = !!d.can_publish
          this.canSync = !!d.can_sync
        }
      } catch (e) {}
      this.loadDicts()
      this.loadLogs()
      this.loadTrade()
      this.loading = false
    },
    fmtTime(t) { return t ? String(t).replace('T', ' ').slice(0, 16) : '-' },
    async loadDicts() {
      const codes = ['company_business_status', 'company_type', 'vat_type', 'vat_rate', 'invoice_type', 'credit_level', 'account_type', 'payment_method', 'delivery_method']
      const res = {}
      await Promise.all(codes.map(async c => {
        try { const r = await getDictByCode(c); if (r.code === 0) res[c] = r.data || [] } catch (e) { res[c] = [] }
      }))
      this.dicts = res
    },
    async loadLogs() { try { const r = await getCompanyLogs(); if (r.code === 0) this.logs = r.data.list || [] } catch (e) {} },
    async loadTrade() { try { const r = await getTradeRecords(); if (r.code === 0) { this.tradeStats = r.data.stats || []; this.tradeList = r.data.list || [] } } catch (e) {} },
    validateDraft() {
      if (!this.company.company_name) { this.$message.warning('请填写公司全称'); return false }
      return true
    },
    validatePublish() {
      if (!this.company.company_name) { this.$message.warning('请填写公司全称'); return false }
      if (!this.company.credit_code || String(this.company.credit_code).length !== 18) { this.$message.warning('统一社会信用代码必须为18位'); return false }
      if (this.company.business_term_start && this.company.business_term_end && this.company.business_term_end < this.company.business_term_start) { this.$message.warning('营业期限截止日期必须晚于起始日期'); return false }
      if (this.company.email && !/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(this.company.email)) { this.$message.warning('电子邮箱格式不正确'); return false }
      if (this.company.website && !/^https?:\/\//i.test(this.company.website)) { this.$message.warning('企业官网必须以 http/https 开头'); return false }
      if (this.company.zipcode && !/^\d{6}$/.test(this.company.zipcode)) { this.$message.warning('邮政编码必须为6位数字'); return false }
      return true
    },
    async saveDraft() {
      if (!this.validateDraft()) return
      this.saving = true
      try {
        const r = await saveCompanyConfig({ company: this.company, partner: this.partner })
        if (r.code === 0) { this.$message.success('保存成功'); this.load() } else { this.$message.error(r.msg || '保存失败') }
      } catch (e) {}
      this.saving = false
    },
    async doPublish() {
      if (!this.validatePublish()) return
      this.$confirm('确认发布公司信息？发布后所有对外展示页面将同步更新', '发布上线', { type: 'warning' }).then(async () => {
        this.publishing = true
        try {
          const r = await publishCompany()
          if (r.code === 0) { this.$message.success(r.msg || '发布成功'); this.load() } else { this.$message.error(r.msg || '发布失败') }
        } catch (e) {}
        this.publishing = false
      }).catch(() => {})
    },
    async showPreview() {
      try {
        const r = await previewCompany()
        if (r.code === 0) { this.previewData = r.data || {}; this.previewVisible = true }
      } catch (e) {}
    },
    async doSync() {
      if (!this.syncChannels.length) { this.$message.warning('请选择同步渠道'); return }
      this.syncing = true
      try {
        const r = await syncCompany(this.syncChannels)
        if (r.code === 0) { this.$message.success(r.msg || '同步任务已发起') } else { this.$message.error(r.msg || '同步失败') }
      } catch (e) {}
      this.syncing = false
    }
  }
}
</script>

<style scoped>
.company-page { padding: 14px; background: #f0f2f5; min-height: 100%; }
.page-head { display: flex; align-items: center; justify-content: space-between; background: #fff; border-radius: 8px; padding: 14px 18px; margin-bottom: 14px; }
.page-head h2 { margin: 0; font-size: 18px; color: #303133; }
.update-tip { font-size: 12px; color: #909399; margin-top: 4px; }
.main-body { display: flex; gap: 14px; }
.side-nav { width: 200px; background: #fff; border-radius: 8px; padding: 8px; flex-shrink: 0; }
.nav-item { padding: 10px 14px; border-radius: 6px; cursor: pointer; font-size: 13px; color: #606266; margin-bottom: 2px; }
.nav-item:hover { background: #f5f7fa; }
.nav-item.active { background: #ecf5ff; color: #409eff; font-weight: 600; }
.content-area { flex: 1; background: #fff; border-radius: 8px; padding: 18px; min-height: 70vh; }
.side-panel { width: 170px; background: #fff; border-radius: 8px; padding: 14px; flex-shrink: 0; align-self: flex-start; }
.panel-title { font-size: 14px; font-weight: 600; color: #303133; margin-bottom: 12px; }
.sec-title { font-size: 16px; font-weight: 600; color: #303133; margin-bottom: 4px; }
.sec-sub { font-size: 12px; color: #909399; margin-bottom: 14px; }
.tip { font-size: 12px; color: #909399; margin-top: 6px; }
.log-area { background: #fff; border-radius: 8px; padding: 14px 18px; margin-top: 14px; }
.log-title { font-size: 14px; font-weight: 600; color: #303133; margin-bottom: 10px; }
.log-refresh { font-size: 12px; color: #409eff; cursor: pointer; margin-left: 10px; font-weight: normal; }
.stat-row { margin-bottom: 12px; }
.stat-card { text-align: center; }
.stat-num { font-size: 18px; font-weight: 700; color: #303133; }
.stat-label { font-size: 12px; color: #909399; margin-top: 4px; }
.preview-body { padding: 8px 4px; }
.pv-logo { text-align: center; margin-bottom: 8px; }
.pv-intro { margin-top: 14px; font-size: 13px; color: #606266; line-height: 1.8; }
.pv-copy { margin-top: 14px; font-size: 12px; color: #909399; text-align: center; }
</style>
