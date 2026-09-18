<template>
  <div class="login-settings-page">
    <el-card shadow="never" class="page-card">
      <div slot="header" class="card-header">
        <span><i class="el-icon-edit-outline"></i> 登录页面配置</span>
        <el-button v-if="hasPerm('loginsettings:resetConfig')" type="danger" size="small" icon="el-icon-delete" @click="handleReset" style="float:right">恢复默认</el-button>
      </div>

      <el-form label-width="140px" label-position="left" size="small">
        <!-- 品牌信息 -->
        <h3 class="section-title">品牌信息</h3>
        <el-form-item label="系统标题">
          <el-input v-model="form.title" placeholder="登录页显示的系统名称" />
        </el-form-item>
        <el-form-item label="系统标语">
          <el-input v-model="form.slogan" placeholder="显示在标题下方的标语" />
        </el-form-item>
        <el-form-item label="版权信息">
          <el-input v-model="form.copyright" placeholder="登录页底部版权文字" />
        </el-form-item>
        <el-form-item label="登录按钮文字">
          <el-input v-model="form.btn_text" placeholder="登录按钮显示文字" style="width:200px" />
        </el-form-item>
        <el-form-item label="主色调">
          <el-color-picker v-model="form.primary_color" />
          <span class="el-form-item__content__tip">{{ form.primary_color }}</span>
        </el-form-item>

        <!-- Logo 设置 -->
        <h3 class="section-title">Logo 设置</h3>
        <el-form-item label="Logo 图片">
          <div class="logo-upload">
            <el-upload :action="uploadUrl" :data="{type:'logo'}" :headers="uploadHeaders" :show-file-list="false" :on-success="handleLogoSuccess" accept="image/*">
              <img v-if="form.logo_url" :src="form.logo_url" class="avatar" />
              <i v-else class="el-icon-plus avatar-uploader" />
            </el-upload>
            <el-button size="mini" type="primary" plain icon="el-icon-folder-opened" @click="driveVisible = true; driveTarget = 'logo'" style="margin-left:6px">从企业网盘选择</el-button>
            <el-button v-if="form.logo_url" type="danger" plain size="small" icon="el-icon-delete" @click="removeLogo">删除Logo</el-button>
          </div>
        </el-form-item>
        <el-form-item v-if="form.logo_url" label="Logo 宽度">
          <el-slider v-model="form.logo_width" :min="60" :max="200" show-input style="width:300px" />
        </el-form-item>
        <el-form-item v-if="form.logo_url" label="Logo 样式">
          <el-radio-group v-model="form.logo_mode">
            <el-radio label="normal">方形</el-radio>
            <el-radio label="circle">圆形</el-radio>
          </el-radio-group>
        </el-form-item>

        <!-- 背景设置 -->
        <h3 class="section-title">背景设置</h3>
        <el-form-item label="背景模式">
          <el-select v-model="form.bg_mode" style="width:200px">
            <el-option label="纯色" value="solid" />
            <el-option label="静态渐变" value="gradient_static" />
            <el-option label="动态渐变" value="gradient_animated" />
            <el-option label="图片" value="image" />
            <el-option label="粒子" value="particle" />
          </el-select>
        </el-form-item>

        <template v-if="form.bg_mode === 'solid'">
          <el-form-item label="背景颜色">
            <el-color-picker v-model="form.bg_solid_color" />
            <span class="el-form-item__content__tip">{{ form.bg_solid_color }}</span>
          </el-form-item>
        </template>

        <template v-if="form.bg_mode === 'gradient_static'">
          <el-form-item label="渐变方向">
            <el-select v-model="form.bg_gradient_direction" style="width:200px">
              <el-option label="从上到下" value="to bottom" />
              <el-option label="从左到右" value="to right" />
              <el-option label="对角" value="to bottom right" />
              <el-option label="径向" value="radial" />
            </el-select>
          </el-form-item>
          <el-form-item label="起始颜色">
            <el-color-picker v-model="form.bg_gradient_start" />
            <span class="el-form-item__content__tip">{{ form.bg_gradient_start }}</span>
          </el-form-item>
          <el-form-item label="结束颜色">
            <el-color-picker v-model="form.bg_gradient_end" />
            <span class="el-form-item__content__tip">{{ form.bg_gradient_end }}</span>
          </el-form-item>
        </template>

        <template v-if="form.bg_mode === 'gradient_animated'">
          <el-form-item label="动画方向">
            <el-select v-model="form.bg_animated_direction" style="width:200px">
              <el-option label="从左到右" value="to left" />
              <el-option label="从右到左" value="to right" />
              <el-option label="从上到下" value="to bottom" />
              <el-option label="从下到上" value="to top" />
            </el-select>
          </el-form-item>
          <el-form-item label="起始颜色">
            <el-color-picker v-model="form.bg_animated_start" />
            <span class="el-form-item__content__tip">{{ form.bg_animated_start }}</span>
          </el-form-item>
          <el-form-item label="结束颜色">
            <el-color-picker v-model="form.bg_animated_end" />
            <span class="el-form-item__content__tip">{{ form.bg_animated_end }}</span>
          </el-form-item>
          <el-form-item label="动画速度(秒)">
            <el-slider v-model="form.bg_animated_speed" :min="1" :max="10" show-input style="width:300px" />
          </el-form-item>
        </template>

        <template v-if="form.bg_mode === 'image'">
          <el-form-item label="背景图片">
            <el-upload :action="uploadUrl" :data="{type:'bg'}" :headers="uploadHeaders" :show-file-list="false" :on-success="handleBgSuccess" accept="image/*">
              <el-button size="small" type="primary">选择图片</el-button>
            </el-upload>
            <el-button size="mini" type="primary" plain icon="el-icon-folder-opened" @click="driveVisible = true; driveTarget = 'bg'" style="margin-left:6px">从企业网盘选择</el-button>
            <img v-if="form.bg_image_url" :src="form.bg_image_url" class="bg-preview" />
          </el-form-item>
          <el-form-item label="填充方式">
            <el-select v-model="form.bg_image_fit" style="width:200px">
              <el-option label="覆盖" value="cover" />
              <el-option label="包含" value="contain" />
              <el-option label="拉伸" value="100% 100%" />
            </el-select>
          </el-form-item>
        </template>

        <template v-if="form.bg_mode === 'particle'">
          <el-form-item label="粒子颜色">
            <el-color-picker v-model="form.bg_particle_color" />
            <span class="el-form-item__content__tip">{{ form.bg_particle_color }}</span>
          </el-form-item>
          <el-form-item label="粒子数量">
            <el-slider v-model="form.bg_particle_count" :min="30" :max="300" show-input style="width:300px" />
          </el-form-item>
          <el-form-item label="粒子距离">
            <el-slider v-model="form.bg_particle_distance" :min="50" :max="300" show-input style="width:300px" />
          </el-form-item>
          <el-form-item label="粒子速度">
            <el-slider v-model="form.bg_particle_speed" :min="1" :max="10" show-input style="width:300px" />
          </el-form-item>
        </template>

        <!-- 遮罩层 -->
        <h3 class="section-title">遮罩层</h3>
        <el-form-item label="启用遮罩">
          <el-switch v-model="form.bg_overlay_enabled" />
        </el-form-item>
        <template v-if="form.bg_overlay_enabled">
          <el-form-item label="遮罩颜色">
            <el-color-picker v-model="form.bg_overlay_color" />
            <span class="el-form-item__content__tip">{{ form.bg_overlay_color }}</span>
          </el-form-item>
          <el-form-item label="遮罩透明度">
            <el-slider v-model="form.bg_overlay_opacity" :min="0" :max="100" show-input style="width:300px" />
          </el-form-item>
        </template>

        <!-- 登录卡片 -->
        <h3 class="section-title">登录卡片</h3>
        <el-form-item label="卡片位置">
          <el-select v-model="form.card_position" style="width:200px">
            <el-option label="居中" value="center" />
            <el-option label="靠左" value="left" />
            <el-option label="靠右" value="right" />
          </el-select>
        </el-form-item>
        <el-form-item label="模糊强度">
          <el-slider v-model="form.card_blur" :min="0" :max="30" show-input style="width:300px" />
        </el-form-item>
        <el-form-item label="圆角">
          <el-slider v-model="form.card_radius" :min="0" :max="40" show-input style="width:300px" />
        </el-form-item>
        <el-form-item label="阴影">
          <el-select v-model="form.card_shadow" style="width:200px">
            <el-option label="无" value="none" />
            <el-option label="浅" value="light" />
            <el-option label="中" value="medium" />
            <el-option label="重" value="heavy" />
          </el-select>
        </el-form-item>

        <!-- 功能开关 -->
        <h3 class="section-title">功能开关</h3>
        <el-form-item label="短信登录">
          <el-switch v-model="form.sms_enabled" />
        </el-form-item>
        <el-form-item label="注册功能">
          <el-switch v-model="form.register_enabled" />
        </el-form-item>
        <el-form-item label="记住密码">
          <el-switch v-model="form.remember_enabled" />
        </el-form-item>

        <el-form-item>
          <el-button v-if="hasPerm('loginsettings:saveConfig')" type="primary" :loading="saving" @click="handleSave">保存配置</el-button>
        </el-form-item>
      </el-form>
    </el-card>
    <drive-file-picker :visible="driveVisible" mode="image" :multiple="false" @update:visible="driveVisible = $event" @confirm="onDrivePick" />
  </div>
</template>

<script>
import { getLoginSettings, saveLoginSettings, resetLoginSettings } from '@/api/settings'
import { getToken } from '@/utils/auth'

export default {
  name: 'LoginConfig',
  data() {
    return {
      driveVisible: false, driveTarget: 'logo',
      saving: false,
      form: {
        title: '数智管控平台 管理后台',
        slogan: '',
        copyright: '',
        btn_text: '登录',
        primary_color: '#409EFF',
        bg_mode: 'gradient_animated',
        bg_solid_color: '#1a2a6c',
        bg_gradient_direction: 'to bottom',
        bg_gradient_start: '#667eea',
        bg_gradient_end: '#764ba2',
        bg_animated_direction: 'to left',
        bg_animated_start: '#1a2a6c',
        bg_animated_end: '#b21f1f',
        bg_animated_speed: 3,
        bg_image_url: '',
        bg_image_fit: 'cover',
        bg_particle_color: '#409EFF',
        bg_particle_count: 150,
        bg_particle_distance: 100,
        bg_particle_speed: 2,
        bg_overlay_enabled: true,
        bg_overlay_color: '#000000',
        bg_overlay_opacity: 40,
        logo_url: '',
        logo_width: 120,
        logo_mode: 'normal',
        card_position: 'center',
        card_blur: 10,
        card_radius: 16,
        card_shadow: 'medium',
        register_enabled: true,
        sms_enabled: true,
        remember_enabled: true,
      }
    }
  },
  computed: {
    uploadUrl() { return '/api/settings/login/upload' },
    uploadHeaders() { return { Authorization: 'Bearer ' + getToken() } },
  },
  created() { this.loadConfig() },
  methods: {
    // 权限判断：按钮权限控制
    hasPerm(code) { const p = this.$store.state.user && this.$store.state.user.permissions ? this.$store.state.user.permissions : []; return p.indexOf(code) > -1 },
    async loadConfig() {
      try {
        const r = await getLoginSettings()
        if (r.code === 0 && r.data) {
          Object.assign(this.form, r.data)
        }
      } catch (e) {
        this.$message.warning('加载配置失败')
      }
    },
    async handleSave() {
      this.saving = true
      try {
        const r = await saveLoginSettings(this.form)
        if (r.code === 0) {
          this.$message.success('配置已保存')
        } else {
          this.$message.error(r.msg || '保存失败')
        }
      } catch (e) {
        this.$message.error('保存失败')
      }
      this.saving = false
    },
    handleReset() {
      this.$confirm('确定恢复默认配置？', '提示', { type: 'warning' }).then(async () => {
        try {
          const r = await resetLoginSettings()
          if (r.code === 0) {
            this.$message.success('已恢复默认')
            this.loadConfig()
          }
        } catch (e) {
          this.$message.error('重置失败')
        }
      }).catch(() => {})
    },
    onDrivePick(list) {
      if (!list.length) return
      const url = list[0].url
      if (this.driveTarget === 'logo') this.form.logo_url = url
      else this.form.bg_image_url = url
      this.$message.success('已选择：' + list[0].name)
    },
    handleLogoSuccess(res) {
      if (res.code === 0 && res.data?.url) {
        this.form.logo_url = res.data.url
        this.$message.success('Logo 上传成功')
      }
    },
    // 删除 Logo：清空配置（保存后生效；upload 目录中历史文件不物理删除，避免误删被复用资源）
    removeLogo() {
      this.form.logo_url = ''
      this.$message.success('Logo 已清除，请点击保存生效')
    },
    handleBgSuccess(res) {
      if (res.code === 0 && res.data?.url) {
        this.form.bg_image_url = res.data.url
        this.$message.success('背景图片上传成功')
      }
    },
  }
}
</script>

<style scoped>
.login-settings-page { padding: 20px; max-width: 800px; margin: 0 auto; }
.page-card { min-height: 400px; }
.card-header { font-size: 16px; font-weight: 600; }
.section-title { font-size: 14px; font-weight: 600; color: #409EFF; margin: 24px 0 16px; padding-bottom: 8px; border-bottom: 1px solid #ebeef5; }
.section-title:first-of-type { margin-top: 0; }
.avatar { width: 80px; height: 80px; object-fit: contain; border: 1px dashed #d9d9d9; border-radius: 6px; padding: 4px; }
.avatar-uploader { font-size: 28px; color: #8c939d; width: 80px; height: 80px; line-height: 80px; text-align: center; border: 1px dashed #d9d9d9; border-radius: 6px; cursor: pointer; display: inline-block; }
.avatar-uploader:hover { border-color: #409EFF; }
.logo-upload { display: flex; align-items: flex-start; gap: 12px; }
.logo-upload .el-button { margin-top: 28px; }
.bg-preview { max-width: 200px; max-height: 100px; margin-top: 8px; border-radius: 4px; display: block; }
.el-form-item__content__tip { margin-left: 10px; font-size: 12px; color: #999; font-family: monospace; }
</style>
