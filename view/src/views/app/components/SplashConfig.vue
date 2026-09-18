<template>
  <div class="splash-config">
    <div class="splash-left">
      <el-form label-width="100px" size="small">
        <div class="card-box">
          <h4>内容配置</h4>
          <el-form-item label="启动页类型">
            <el-select v-model="form.type" style="width:100%"><el-option v-for="d in dictSplashType" :key="d.value" :label="d.label" :value="Number(d.value)" /></el-select>
          </el-form-item>
          <el-form-item v-if="form.type===1||form.type===3" label="图片">
            <el-upload action="" :show-file-list="false" :http-request="(o)=>uploadFile(o,'image')" accept="image/*">
              <img v-if="form.image" :src="form.image" style="width:120px;height:200px;object-fit:cover;border-radius:6px;border:1px solid #EBEEF5" />
              <el-button v-else size="small">选择图片</el-button>
            </el-upload>
            <div style="margin-top:6px">
              <el-button size="mini" type="primary" plain icon="el-icon-folder-opened" @click="driveVisible = true">从企业网盘选择</el-button>
            </div>
            <div style="font-size:12px;color:#909399;margin-top:4px">建议尺寸 375x667px</div>
            <drive-file-picker :visible="driveVisible" mode="image" :multiple="false" @update:visible="driveVisible = $event" @confirm="onDrivePick" />
          </el-form-item>
          <el-form-item v-if="form.type===2||form.type===3" label="视频">
            <el-upload action="" :show-file-list="false" :http-request="(o)=>uploadFile(o,'video')" accept="video/*">
              <el-button size="small">选择视频</el-button>
            </el-upload>
            <div style="margin-top:6px">
              <el-button size="mini" type="primary" plain icon="el-icon-folder-opened" @click="driveVideoVisible = true">从企业网盘选择</el-button>
            </div>
            <drive-file-picker :visible="driveVideoVisible" mode="file" :multiple="false" @update:visible="driveVideoVisible = $event" @confirm="onDriveVideoPick" />
            <div v-if="form.video" style="font-size:12px;color:#909399;margin-top:4px">{{ form.video.split('/').pop() }}</div>
          </el-form-item>
          <el-form-item label="背景色">
            <el-color-picker v-model="form.background_color" />
            <span style="margin-left:8px;font-size:12px;color:#999;font-family:monospace">{{ form.background_color }}</span>
          </el-form-item>
        </div>
        <div class="card-box">
          <h4>行为配置</h4>
          <el-form-item label="显示时长">
            <el-slider v-model="form.duration" :min="splashMinDuration" :max="splashMaxDuration" show-input style="width:200px" /> 秒
          </el-form-item>
          <el-form-item label="可跳过">
            <el-switch v-model="form.skip_enabled" :active-value="1" :inactive-value="0" />
          </el-form-item>
          <template v-if="form.skip_enabled===1">
            <el-form-item label="跳过按钮样式">
              <el-select v-model="form.skip_style" style="width:100%"><el-option v-for="d in dictSkipStyle" :key="d.value" :label="d.label" :value="Number(d.value)" /></el-select>
            </el-form-item>
            <template v-if="form.skip_style!==3">
              <el-form-item label="按钮文字"><el-input v-model="form.skip_text" maxlength="10" style="width:160px" /></el-form-item>
              <el-form-item label="按钮颜色"><el-color-picker v-model="form.skip_color" /></el-form-item>
            </template>
            <el-form-item label="按钮位置">
              <el-select v-model="form.skip_position" style="width:100%"><el-option v-for="d in dictSkipPos" :key="d.value" :label="d.label" :value="Number(d.value)" /></el-select>
            </el-form-item>
          </template>
        </div>
        <div class="card-box">
          <h4>文字配置</h4>
          <el-form-item label="显示文字"><el-switch v-model="form.show_text" :active-value="1" :inactive-value="0" /></el-form-item>
          <template v-if="form.show_text===1">
            <el-form-item label="文字内容"><el-input v-model="form.text_content" type="textarea" :rows="3" /></el-form-item>
            <el-form-item label="文字颜色"><el-color-picker v-model="form.text_color" /></el-form-item>
            <el-form-item label="文字位置">
              <el-select v-model="form.text_position" style="width:100%"><el-option v-for="d in dictTextPos" :key="d.value" :label="d.label" :value="Number(d.value)" /></el-select>
            </el-form-item>
            <el-form-item label="文字大小">
              <el-slider v-model="form.text_size" :min="16" :max="48" show-input style="width:200px" /> px
            </el-form-item>
          </template>
        </div>
        <div class="card-box">
          <h4>启用控制</h4>
          <el-form-item label="启用启动页"><el-switch v-model="form.enabled" :active-value="1" :inactive-value="0" /></el-form-item>
        </div>
      </el-form>
    </div>
    <div class="splash-right">
      <div class="splash-right-header">
        <span style="font-size:15px;font-weight:600">预览</span>
        <el-button type="primary" :loading="saving" @click="handleSave">保存配置</el-button>
      </div>
      <div class="phone-frame">
        <div class="phone-notch"></div>
        <div class="phone-screen" :style="{ background: form.background_color || '#ffffff' }">
          <img v-if="form.image" :src="form.image" class="splash-img" />
          <div v-if="form.show_text===1" class="splash-text" :style="{ color: form.text_color, fontSize: form.text_size+'px', textAlign: 'center', position:'absolute', [['','center','bottom','top'][form.text_position]]:'40px',left:0,right:0 }">
            {{ form.text_content }}
          </div>
          <div v-if="form.skip_enabled===1 && form.skip_style!==3" class="skip-btn"
               :style="{
                 position:'absolute',
                 [['','right','right','left'][form.skip_position]]:'16px',
                 [['','top','top','bottom'][form.skip_position]]:['','40px','40px','40px'][form.skip_position],
                 color:form.skip_color,
                 background:'rgba(0,0,0,0.3)',
                 padding:'6px 16px',
                 borderRadius:'20px',
                 fontSize:'14px',
                 cursor:'pointer',
                 zIndex:10
               }">
            {{ form.skip_style===2 ? '✕' : (form.skip_text||'跳过') }}
          </div>
          <div class="phone-bar">{{ form.duration||3 }}s</div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { getSplashConfig, saveSplashConfig, uploadSplashFile } from '@/api/app'
import { getDictionary } from '@/utils/dict'
import { getSettingValue } from '@/api/settings'

export default {
  name: 'SplashConfig',
  data() {
    return {
      driveVisible: false,
      driveVideoVisible: false,
      saving: false,
      dictSplashType: [], dictSkipStyle: [], dictSkipPos: [], dictTextPos: [],
      splashMaxDuration: 10, splashMinDuration: 1, splashDefDuration: 3,
      form: { type:1, image:'', video:'', background_color:'#060b18', duration:3, skip_enabled:1, skip_style:1, skip_text:'跳过', skip_color:'rgba(255,255,255,0.6)', skip_position:1, show_text:0, text_content:'', text_color:'#ffffff', text_position:1, text_size:24, enabled:1 }
    }
  },
  created() { this.init() },
  methods: {
    async init() {
      this.dictSplashType=await getDictionary('splash_type')||[]; this.dictSkipStyle=await getDictionary('skip_style')||[]; this.dictSkipPos=await getDictionary('skip_position')||[]; this.dictTextPos=await getDictionary('text_position')||[];
      try{const r=await getSettingValue('splash_max_duration');this.splashMaxDuration=parseInt(r.data?.value)||10}catch(e){}
      try{const r=await getSettingValue('splash_min_duration');this.splashMinDuration=parseInt(r.data?.value)||1}catch(e){}
      try{const r=await getSettingValue('splash_default_duration');this.splashDefDuration=parseInt(r.data?.value)||3}catch(e){}
      this.load()
    },
    async load() { try{ const r=await getSplashConfig(); if(r.code===0&&r.data) Object.assign(this.form,r.data) }catch(e){} },
    async handleSave() {
      this.saving=true
      try{ const r=await saveSplashConfig(this.form); if(r.code===0) this.$message.success('保存成功'); else this.$message.error(r.msg||'保存失败') }catch(e){ this.$message.error('保存失败') }
      this.saving=false
    },
    onDrivePick(list) { if (list.length) { this.form.image = list[0].url; this.$message.success('已选择：' + list[0].name) } },
    onDriveVideoPick(list) { if (list.length) { this.form.video = list[0].url; this.$message.success('已选择：' + list[0].name) } },
    async uploadFile({file,onSuccess},type) {
      const fd=new FormData(); fd.append('file',file); fd.append('type',type)
      try{ const r=await uploadSplashFile(fd); if(r.code===0&&r.data?.url){ if(type==='image') this.form.image=r.data.url; else this.form.video=r.data.url; onSuccess(); this.$message.success('上传成功') }else{ this.$message.error(r.msg||'上传失败') } }catch(e){ this.$message.error('上传失败') }
    }
  }
}
</script>

<style scoped>
.splash-config { display:flex;gap:24px;min-height:600px; }
.splash-left { width:45%;overflow-y:auto; }
.splash-right { flex:1;display:flex;flex-direction:column;align-items:center;padding-top:20px;position:sticky;top:0; }
.splash-right-header { width:375px;display:flex;justify-content:space-between;align-items:center;margin-bottom:12px; }
.card-box { background:#f9fafb;border:1px solid #EBEEF5;border-radius:8px;padding:16px 20px;margin-bottom:16px; }
.card-box h4 { font-size:14px;font-weight:600;color:#409EFF;margin:0 0 12px;padding-bottom:8px;border-bottom:1px solid #EBEEF5; }
.phone-frame { width:375px;height:675px;background:#1a1a2e;border-radius:40px;padding:12px;box-shadow:0 8px 40px rgba(0,0,0,0.15),0 0 0 1px rgba(255,255,255,0.1);position:relative; }
.phone-notch { position:absolute;top:0;left:50%;transform:translateX(-50%);width:150px;height:28px;background:#1a1a2e;border-radius:0 0 16px 16px;z-index:5; }
.phone-screen { width:351px;height:651px;border-radius:30px;overflow:hidden;position:relative;display:flex;align-items:center;justify-content:center; }
.splash-img { width:100%;height:100%;object-fit:cover;position:absolute;top:0;left:0; }
.splash-text { font-weight:600;z-index:2;text-shadow:0 2px 8px rgba(0,0,0,0.3);padding:0 20px; }
.skip-btn { z-index:10;backdrop-filter:blur(4px); }
.phone-bar { position:absolute;bottom:16px;left:50%;transform:translateX(-50%);color:rgba(255,255,255,0.4);font-size:12px;z-index:3;background:rgba(0,0,0,0.2);padding:2px 12px;border-radius:10px; }
</style>
